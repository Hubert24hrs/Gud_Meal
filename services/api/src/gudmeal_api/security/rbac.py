"""Roles, permissions and the authenticated principal. Deny by default."""

from __future__ import annotations

from collections.abc import Mapping
from dataclasses import dataclass, field
from enum import StrEnum

from ..errors import PermissionDenied


class Role(StrEnum):
    CUSTOMER = "customer"
    RESTAURANT_OWNER = "restaurant_owner"
    RESTAURANT_MANAGER = "restaurant_manager"
    RESTAURANT_STAFF = "restaurant_staff"
    RIDER = "rider"
    SUPPORT_AGENT = "support_agent"
    OPERATIONS_MANAGER = "operations_manager"
    FINANCE_MANAGER = "finance_manager"
    MARKETING_MANAGER = "marketing_manager"
    SUPER_ADMIN = "super_admin"


STAFF_ROLES = frozenset(
    {
        Role.SUPPORT_AGENT,
        Role.OPERATIONS_MANAGER,
        Role.FINANCE_MANAGER,
        Role.MARKETING_MANAGER,
        Role.SUPER_ADMIN,
    }
)
RESTAURANT_ROLE_NAMES = ("owner", "manager", "staff")


class Permission(StrEnum):
    ORDERS_READ_ALL = "orders:read_all"
    ORDERS_INTERVENE = "orders:intervene"
    DISPATCH_MANUAL = "dispatch:manual"
    REFUNDS_REQUEST = "refunds:request"
    REFUNDS_APPROVE = "refunds:approve"
    PAYOUTS_APPROVE = "payouts:approve"
    PAYMENTS_READ = "payments:read"
    LEDGER_READ = "ledger:read"
    SETTLEMENTS_MANAGE = "settlements:manage"
    CONFIG_READ = "config:read"
    CONFIG_WRITE = "config:write"
    FLAGS_WRITE = "flags:write"
    APPLICATIONS_REVIEW = "applications:review"
    RESTAURANTS_MANAGE = "restaurants:manage"
    RIDERS_MANAGE = "riders:manage"
    USERS_READ = "users:read"
    USERS_MANAGE_ROLES = "users:manage_roles"
    SUPPORT_MANAGE = "support:manage"
    PROMOTIONS_MANAGE = "promotions:manage"
    AUDIT_READ = "audit:read"
    ANALYTICS_READ = "analytics:read"
    AI_MONITOR = "ai:monitor"


P = Permission
ROLE_PERMISSIONS: dict[Role, frozenset[Permission]] = {
    Role.SUPPORT_AGENT: frozenset({P.ORDERS_READ_ALL, P.REFUNDS_REQUEST, P.SUPPORT_MANAGE, P.USERS_READ}),
    Role.OPERATIONS_MANAGER: frozenset(
        {
            P.ORDERS_READ_ALL,
            P.ORDERS_INTERVENE,
            P.DISPATCH_MANUAL,
            P.REFUNDS_REQUEST,
            P.APPLICATIONS_REVIEW,
            P.RESTAURANTS_MANAGE,
            P.RIDERS_MANAGE,
            P.USERS_READ,
            P.SUPPORT_MANAGE,
            P.ANALYTICS_READ,
            P.AUDIT_READ,
            P.CONFIG_READ,
            P.AI_MONITOR,
        }
    ),
    Role.FINANCE_MANAGER: frozenset(
        {
            P.ORDERS_READ_ALL,
            P.REFUNDS_REQUEST,
            P.REFUNDS_APPROVE,
            P.PAYOUTS_APPROVE,
            P.PAYMENTS_READ,
            P.LEDGER_READ,
            P.SETTLEMENTS_MANAGE,
            P.ANALYTICS_READ,
            P.AUDIT_READ,
            P.CONFIG_READ,
        }
    ),
    Role.MARKETING_MANAGER: frozenset({P.PROMOTIONS_MANAGE, P.ANALYTICS_READ, P.CONFIG_READ}),
    Role.SUPER_ADMIN: frozenset(Permission),
}

RESTAURANT_ABILITIES: dict[str, frozenset[str]] = {
    "owner": frozenset({"orders", "menu", "settings", "finance", "analytics"}),
    "manager": frozenset({"orders", "menu", "settings", "analytics"}),
    "staff": frozenset({"orders", "menu_availability"}),
}


@dataclass(frozen=True)
class Principal:
    uid: str
    roles: frozenset[str] = field(default_factory=frozenset)
    restaurant_roles: Mapping[str, str] = field(default_factory=dict)
    email: str | None = None
    phone: str | None = None
    name: str | None = None
    email_verified: bool = False
    token: str | None = field(default=None, repr=False, compare=False)

    def has_role(self, *roles: str) -> bool:
        return any(r in self.roles for r in roles)

    @property
    def is_staff(self) -> bool:
        return bool(self.roles & {r.value for r in STAFF_ROLES})

    @property
    def is_rider(self) -> bool:
        return Role.RIDER.value in self.roles

    def permissions(self) -> frozenset[Permission]:
        perms: set[Permission] = set()
        for role in self.roles:
            try:
                perms |= ROLE_PERMISSIONS.get(Role(role), frozenset())
            except ValueError:
                continue
        return frozenset(perms)

    def can(self, permission: Permission) -> bool:
        return permission in self.permissions()

    def restaurant_role(self, restaurant_id: str) -> str | None:
        role = self.restaurant_roles.get(restaurant_id)
        return role if role in RESTAURANT_ROLE_NAMES else None

    def can_on_restaurant(self, restaurant_id: str, ability: str) -> bool:
        role = self.restaurant_role(restaurant_id)
        return role is not None and ability in RESTAURANT_ABILITIES[role]

    def audit_roles(self) -> list[str]:
        return sorted(self.roles)


SYSTEM_PRINCIPAL = Principal(uid="system", roles=frozenset({"system"}))


def require(principal: Principal, permission: Permission) -> None:
    if not principal.can(permission):
        raise PermissionDenied(
            "You do not have permission to perform this action", details={"permission": permission.value}
        )


def require_restaurant(principal: Principal, restaurant_id: str, ability: str = "orders") -> None:
    if principal.can_on_restaurant(restaurant_id, ability):
        return
    if principal.can(Permission.RESTAURANTS_MANAGE) or principal.can(Permission.ORDERS_INTERVENE):
        return
    raise PermissionDenied(
        "You do not have access to this restaurant", details={"restaurant_id": restaurant_id}
    )


def require_rider(principal: Principal) -> None:
    if not principal.is_rider:
        raise PermissionDenied("Rider account required")
