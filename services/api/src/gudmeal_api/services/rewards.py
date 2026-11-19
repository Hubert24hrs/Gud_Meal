"""Yummy points and referrals (ADR-0016). Rewards never create money: they become personal, platform-funded
vouchers that `pricing.py` prices and the ledger settles through `expense:promotions` like any voucher.

Points live outside the ledger (they are not money) in `loyalty_accounts/{uid}` with an append-only `entries`
subcollection; deterministic entry ids make every earning, reversal and redemption count exactly once.
"""

from __future__ import annotations

import logging
import re
from datetime import UTC, datetime, timedelta
from typing import Any

from pydantic import BaseModel, Field

from ..domain.growth import (
    REFERRAL_PATTERN,
    GrowthConfig,
    PointsEntry,
    RewardsAccount,
    membership_active,
    new_code,
    normalise_code,
    points_for,
    referral_code_for,
)
from ..domain.models import Order, OrderStatus, Voucher
from ..domain.money import format_naira
from ..errors import Conflict, ValidationFailed
from ..ledger.audit import AuditLog
from ..repositories import Repositories, Transaction, to_doc
from ..security.rbac import Permission, Principal, require
from .infra import Notifier

logger = logging.getLogger(__name__)
NOT_YET_ORDERED = {OrderStatus.DRAFT, OrderStatus.PENDING_PAYMENT, OrderStatus.CANCELLED}
DONE = {OrderStatus.COMPLETED, OrderStatus.PARTIALLY_REFUNDED, OrderStatus.REFUNDED}


def utcnow() -> datetime:
    return datetime.now(UTC)


class RedeemInput(BaseModel):
    points: int = Field(gt=0, le=10_000_000)


class ReferralInput(BaseModel):
    code: str = Field(min_length=3, max_length=20)


def voucher_view(v: Voucher) -> dict[str, Any]:
    return {
        "code": v.code,
        "description": v.description,
        "value_kobo": v.value,
        "min_subtotal_kobo": v.min_subtotal_kobo,
        "ends_at": v.ends_at,
        "source": v.source,
    }


class RewardsService:
    def __init__(self, repos: Repositories, *, notifier: Notifier, audit: AuditLog) -> None:
        self.repos = repos
        self.notifier = notifier
        self.audit = audit

    def _account_path(self, uid: str) -> str:
        return self.repos.rewards.path(uid)

    # ------------------------------------------------------------------------------------------- reads
    async def overview(self, principal: Principal) -> dict[str, Any]:
        cfg = await self.repos.get_growth_config()
        account = await self._ensure_code(principal.uid, principal.name)
        pricing = await self.repos.get_pricing_config()
        member = membership_active(await self.repos.memberships.get(principal.uid), utcnow())
        entries = await self.repos.store.query(
            f"{self._account_path(principal.uid)}/entries", order_by=[("at", "desc")], limit=20
        )
        step = cfg.redeem_step_points
        balance = account.points
        return {
            "points": balance,
            "lifetime_points": account.lifetime_points,
            "points_value_kobo": max(0, balance) * cfg.point_value_kobo,
            "redeem": {
                "enabled": cfg.points_enabled,
                "step_points": step,
                "step_value_kobo": step * cfg.point_value_kobo,
                "redeemable_points": max(0, balance) // step * step,
                "points_to_next": 0 if balance >= step else step - max(0, balance),
                "min_subtotal_kobo": cfg.redeem_min_subtotal_kobo,
                "valid_days": cfg.redeem_valid_days,
            },
            "earn": {
                "points_per_100_naira": cfg.points_per_100_naira,
                "plus_multiplier": pricing.plus.points_multiplier,
                "member": member,
            },
            "referral": {
                "enabled": cfg.referrals_enabled,
                "code": account.referral_code,
                "friend_gets_kobo": cfg.referee_reward_kobo,
                "you_get_kobo": cfg.referrer_reward_kobo,
                "min_subtotal_kobo": cfg.referee_min_subtotal_kobo,
                "friends_rewarded": account.referrals_rewarded,
                "applied": account.referred_by is not None,
                "can_apply": cfg.referrals_enabled
                and account.referred_by is None
                and not await self._has_ordered(principal.uid),
                "share_text": (
                    f"Get {format_naira(cfg.referee_reward_kobo)} off your first Yummy Chops order with my code "
                    f"{account.referral_code}."
                ),
            },
            "vouchers": [voucher_view(v) for v in await self.my_vouchers(principal.uid)],
            "history": [PointsEntry.model_validate(e).model_dump(mode="json") for e in entries],
        }

    async def my_vouchers(self, uid: str) -> list[Voucher]:
        """Personal vouchers this customer can still use (rewards and referral gifts)."""
        now = utcnow()
        found = await self.repos.vouchers.find(where=[("customer_id", "==", uid)], limit=200)
        usable = [
            v
            for v in found
            if v.is_active
            and (v.ends_at is None or v.ends_at > now)
            and (v.usage_limit is None or v.used_count < v.usage_limit)
        ]
        return sorted(usable, key=lambda v: v.ends_at or now)

    async def _has_ordered(self, uid: str) -> bool:
        orders = await self.repos.orders.find(where=[("customer_id", "==", uid)], limit=50)
        return any(o.status not in NOT_YET_ORDERED and not o.is_leg for o in orders)

    async def _ensure_code(self, uid: str, name: str | None) -> RewardsAccount:
        """Each customer's account gets a referral code the first time they open Rewards."""
        account = await self.repos.rewards.get(uid)
        if account is not None and account.referral_code:
            return account
        for _ in range(6):
            code = referral_code_for(name)

            async def fn(tx: Transaction, code: str = code) -> RewardsAccount | None:
                doc = await tx.get(self._account_path(uid))
                current = RewardsAccount.model_validate(doc) if doc else RewardsAccount(uid=uid)
                if current.referral_code:
                    return current
                if await tx.get(f"referral_codes/{code}") is not None:
                    return None  # taken: try another code
                tx.create(f"referral_codes/{code}", {"code": code, "uid": uid, "created_at": utcnow()})
                updated = current.model_copy(update={"referral_code": code, "updated_at": utcnow()})
                tx.set(self._account_path(uid), to_doc(updated))
                return updated

            result = await self.repos.store.run_transaction(fn)
            if result is not None:
                return result
        raise Conflict("Could not create a referral code, please try again")

    # ------------------------------------------------------------------------------------------- referrals
    async def apply_referral(self, principal: Principal, raw_code: str) -> dict[str, Any]:
        cfg = await self.repos.get_growth_config()
        if not cfg.referrals_enabled:
            raise ValidationFailed("Referral rewards are not available right now")
        code = normalise_code(raw_code)
        if not re.match(REFERRAL_PATTERN, code):
            raise ValidationFailed("That doesn't look like a Yummy Chops referral code")
        owner = await self.repos.store.get(f"referral_codes/{code}")
        if owner is None:
            raise ValidationFailed("We don't recognise that referral code")
        friend = str(owner["uid"])
        if friend == principal.uid:
            raise ValidationFailed("You can't use your own referral code")
        if await self._has_ordered(principal.uid):
            raise ValidationFailed("Referral codes are for new customers, before their first order")
        now = utcnow()
        voucher = Voucher(
            code=f"YCR-{new_code(6)}",
            description="Welcome gift from a friend",
            kind="fixed",
            value=cfg.referee_reward_kobo,
            min_subtotal_kobo=cfg.referee_min_subtotal_kobo,
            funded_by="platform",
            ends_at=now + timedelta(days=cfg.referral_valid_days),
            usage_limit=1,
            per_customer_limit=1,
            customer_id=principal.uid,
            source="referral",
        )

        async def fn(tx: Transaction) -> None:
            doc = await tx.get(self._account_path(principal.uid))
            account = RewardsAccount.model_validate(doc) if doc else RewardsAccount(uid=principal.uid)
            if account.referred_by is not None:
                raise ValidationFailed("You've already used a referral code")
            tx.set(
                self._account_path(principal.uid),
                to_doc(
                    account.model_copy(update={"referred_by": friend, "referred_at": now, "updated_at": now})
                ),
            )
            if cfg.referee_reward_kobo > 0:
                tx.create(self.repos.vouchers.path(voucher.code), to_doc(voucher))

        await self.repos.store.run_transaction(fn)
        await self.notifier.notify_user(
            friend,
            "Someone used your referral code",
            f"You'll get {format_naira(cfg.referrer_reward_kobo)} off when they complete their first order.",
            {"screen": "rewards"},
        )
        return {
            "applied": True,
            "voucher": voucher_view(voucher) if cfg.referee_reward_kobo > 0 else None,
        }

    async def _reward_referrer(self, referee_uid: str, cfg: GrowthConfig) -> None:
        """The referred customer's first order completed: the friend who invited them gets a voucher."""
        now = utcnow()
        month = now.strftime("%Y-%m")
        voucher_code = f"YCF-{new_code(6)}"

        async def fn(tx: Transaction) -> tuple[str, bool] | None:
            doc = await tx.get(self._account_path(referee_uid))
            referee = RewardsAccount.model_validate(doc) if doc else None
            if referee is None or referee.referred_by is None or referee.referral_rewarded:
                return None
            friend_doc = await tx.get(self._account_path(referee.referred_by))
            friend = (
                RewardsAccount.model_validate(friend_doc)
                if friend_doc
                else RewardsAccount(uid=referee.referred_by)
            )
            month_rewards = friend.month_rewards if friend.month_key == month else 0
            rewarded = cfg.referrer_reward_kobo > 0 and month_rewards < cfg.referrer_monthly_cap
            tx.set(
                self._account_path(referee_uid),
                to_doc(referee.model_copy(update={"referral_rewarded": True, "updated_at": now})),
            )
            tx.set(
                self._account_path(friend.uid),
                to_doc(
                    friend.model_copy(
                        update={
                            "referrals_rewarded": friend.referrals_rewarded + 1,
                            "month_key": month,
                            "month_rewards": month_rewards + (1 if rewarded else 0),
                            "updated_at": now,
                        }
                    )
                ),
            )
            if rewarded:
                voucher = Voucher(
                    code=voucher_code,
                    description="Thanks for inviting a friend",
                    kind="fixed",
                    value=cfg.referrer_reward_kobo,
                    min_subtotal_kobo=cfg.referee_min_subtotal_kobo,
                    funded_by="platform",
                    ends_at=now + timedelta(days=cfg.referral_valid_days),
                    usage_limit=1,
                    per_customer_limit=1,
                    customer_id=friend.uid,
                    source="referrer",
                )
                tx.create(self.repos.vouchers.path(voucher_code), to_doc(voucher))
            return friend.uid, rewarded

        result = await self.repos.store.run_transaction(fn)
        if result is None:
            return
        friend_uid, rewarded = result
        if rewarded:
            await self.notifier.notify_user(
                friend_uid,
                "Your friend's first order is done",
                f"Here's {format_naira(cfg.referrer_reward_kobo)} off your next order. Thanks for sharing Yummy Chops!",
                {"screen": "rewards"},
            )

    # ------------------------------------------------------------------------------------------- points
    async def earn(self, uid: str, order_id: str, amount_kobo: int, *, key: str | None = None) -> int:
        """Credit points for money spent on a completed order (once per order and customer)."""
        cfg = await self.repos.get_growth_config()
        pricing = await self.repos.get_pricing_config()
        member = membership_active(await self.repos.memberships.get(uid), utcnow())
        points = points_for(amount_kobo, cfg, pricing.plus.points_multiplier if member else 1)
        if points <= 0:
            return 0
        entry = PointsEntry(
            id=key or f"order:{order_id}",
            kind="earned",
            points=points,
            order_id=order_id,
            note="Plus double points" if member and pricing.plus.points_multiplier > 1 else "",
            at=utcnow(),
        )
        added = await self._post(uid, entry)
        return points if added else 0

    async def _post(self, uid: str, entry: PointsEntry) -> bool:
        async def fn(tx: Transaction) -> bool:
            path = f"{self._account_path(uid)}/entries/{entry.id}"
            if await tx.get(path) is not None:
                return False
            doc = await tx.get(self._account_path(uid))
            account = RewardsAccount.model_validate(doc) if doc else RewardsAccount(uid=uid)
            tx.create(path, to_doc(entry))
            tx.set(
                self._account_path(uid),
                to_doc(
                    account.model_copy(
                        update={
                            "points": account.points + entry.points,
                            "lifetime_points": account.lifetime_points + max(0, entry.points)
                            if entry.kind == "earned"
                            else account.lifetime_points,
                            "updated_at": entry.at,
                        }
                    )
                ),
            )
            return True

        return await self.repos.store.run_transaction(fn)

    async def on_order_completed(self, payload: dict[str, Any]) -> None:
        order = await self.repos.orders.get(str(payload["order_id"]))
        if order is None or order.is_leg:
            return
        cfg = await self.repos.get_growth_config()
        for uid, key, amount in await self._earnings(order):
            await self.earn(uid, order.id, amount, key=key)
        if cfg.referrals_enabled:
            await self._reward_referrer(order.customer_id, cfg)

    async def on_order_refunded(self, payload: dict[str, Any]) -> None:
        """A refund after completion takes back points in proportion to the money refunded."""
        order = await self.repos.orders.get(str(payload["order_id"]))
        if order is None or order.is_leg or order.status not in DONE:
            return
        refunded = min(order.refund_total_kobo, order.breakdown.total_kobo)
        if refunded <= 0:
            return
        for uid, key, _ in await self._earnings(order):
            earned = await self.repos.store.get(f"{self._account_path(uid)}/entries/{key}")
            if earned is None:
                continue
            target = int(earned["points"]) * refunded // order.breakdown.total_kobo
            reversed_ = await self.repos.store.query(
                f"{self._account_path(uid)}/entries", where=[("order_id", "==", order.id)], limit=50
            )
            already = -sum(int(e["points"]) for e in reversed_ if e.get("kind") == "reversed")
            if target > already:
                await self._post(
                    uid,
                    PointsEntry(
                        id=f"{key}:reversed:{refunded}",
                        kind="reversed",
                        points=-(target - already),
                        order_id=order.id,
                        note="Refund",
                        at=utcnow(),
                    ),
                )

    async def _earnings(self, order: Order) -> list[tuple[str, str, int]]:
        """(customer, entry id, amount spent) on an order: the customer, or each payer of a split group order
        (a host who paid the rest earns for the shares they covered)."""
        if order.group_order_id:
            group = await self.repos.group_orders.get(order.group_order_id)
            if group is not None and group.split_mode == "each" and group.shares:
                spent: dict[str, int] = {}
                for share in group.shares:
                    payer = share.paid_by or share.uid
                    spent[payer] = spent.get(payer, 0) + share.amount_kobo
                return [(uid, f"order:{order.id}:{uid}", amount) for uid, amount in sorted(spent.items())]
        return [(order.customer_id, f"order:{order.id}", order.breakdown.total_kobo)]

    async def redeem(self, principal: Principal, points: int) -> dict[str, Any]:
        """Turn points into a personal voucher (points × point value), in steps of `redeem_step_points`."""
        cfg = await self.repos.get_growth_config()
        if not cfg.points_enabled:
            raise ValidationFailed("Yummy points are not available right now")
        if points % cfg.redeem_step_points:
            raise ValidationFailed(f"Redeem points in steps of {cfg.redeem_step_points}")
        now = utcnow()
        voucher = Voucher(
            code=f"YCP-{new_code(6)}",
            description=f"{points:,} Yummy points",
            kind="fixed",
            value=points * cfg.point_value_kobo,
            min_subtotal_kobo=cfg.redeem_min_subtotal_kobo,
            funded_by="platform",
            ends_at=now + timedelta(days=cfg.redeem_valid_days),
            usage_limit=1,
            per_customer_limit=1,
            customer_id=principal.uid,
            source="points",
        )
        entry = PointsEntry(
            id=f"redeem:{voucher.code}",
            kind="redeemed",
            points=-points,
            voucher_code=voucher.code,
            note=f"{format_naira(voucher.value)} voucher",
            at=now,
        )

        async def fn(tx: Transaction) -> int:
            doc = await tx.get(self._account_path(principal.uid))
            account = RewardsAccount.model_validate(doc) if doc else RewardsAccount(uid=principal.uid)
            if account.points < points:
                raise ValidationFailed(
                    "You don't have enough Yummy points", details={"points": account.points, "needed": points}
                )
            tx.create(f"{self._account_path(principal.uid)}/entries/{entry.id}", to_doc(entry))
            tx.create(self.repos.vouchers.path(voucher.code), to_doc(voucher))
            tx.set(
                self._account_path(principal.uid),
                to_doc(account.model_copy(update={"points": account.points - points, "updated_at": now})),
            )
            return account.points - points

        left = await self.repos.store.run_transaction(fn)
        return {"voucher": voucher_view(voucher), "points": left}

    # ------------------------------------------------------------------------------------------- staff
    async def admin_stats(self, principal: Principal) -> dict[str, Any]:
        require(principal, Permission.ANALYTICS_READ)
        cfg = await self.repos.get_growth_config()
        accounts = await self.repos.rewards.find(limit=10_000)
        outstanding = sum(max(0, a.points) for a in accounts)
        vouchers = await self.repos.vouchers.find(
            where=[("source", "in", ["points", "referral", "referrer"])], limit=10_000
        )
        by_source: dict[str, dict[str, int]] = {}
        for v in vouchers:
            row = by_source.setdefault(v.source, {"issued": 0, "used": 0, "value_issued_kobo": 0})
            row["issued"] += 1
            row["used"] += 1 if v.used_count else 0
            row["value_issued_kobo"] += v.value
        return {
            "points_outstanding": outstanding,
            "points_outstanding_value_kobo": outstanding * cfg.point_value_kobo,
            "customers_with_points": sum(1 for a in accounts if a.points > 0),
            "referred_customers": sum(1 for a in accounts if a.referred_by),
            "referrals_rewarded": sum(1 for a in accounts if a.referral_rewarded),
            "vouchers": by_source,
        }

    async def get_config(self, principal: Principal) -> GrowthConfig:
        require(principal, Permission.CONFIG_READ)
        return await self.repos.get_growth_config()

    async def save_config(self, principal: Principal, cfg: GrowthConfig) -> GrowthConfig:
        require(principal, Permission.CONFIG_WRITE)
        current = await self.repos.get_growth_config()
        saved = cfg.model_copy(update={"version": current.version + 1})
        await self.repos.save_growth_config(saved)
        await self.audit.record(
            actor_id=principal.uid,
            actor_roles=sorted(principal.roles),
            action="growth_config.saved",
            resource_type="config",
            resource_id="growth",
            details=saved.model_dump(mode="json"),
        )
        return saved


__all__ = ["RedeemInput", "ReferralInput", "RewardsService", "voucher_view"]
