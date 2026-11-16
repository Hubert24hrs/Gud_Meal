"""Create demo users with roles in the **Firebase Auth emulator** (never a real project).

Usage (from services/api):
    set FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099
    uv run python scripts/seed_auth_emulator.py

Each demo user gets the password from DEMO_USER_PASSWORD (default only valid for the emulator).
"""

from __future__ import annotations

import os
import sys

import firebase_admin
from firebase_admin import auth

if not os.environ.get("FIREBASE_AUTH_EMULATOR_HOST"):
    sys.exit(
        "Refusing to run: FIREBASE_AUTH_EMULATOR_HOST is not set (this script only targets the emulator)."
    )

PROJECT = os.environ.get("FIREBASE_PROJECT_ID", "demo-gudmeal")
PASSWORD = os.environ.get("DEMO_USER_PASSWORD", "gudmeal-demo-123")

USERS = [
    ("demo-customer-1", "customer@gudmeal.test", "Ada Customer", [], {}),
    ("demo-customer-2", "friend@gudmeal.test", "Bayo Friend", [], {}),  # group orders need two people
    (
        "demo-owner-1",
        "owner@gudmeal.test",
        "Jollof Junction Owner",
        ["restaurant_owner"],
        {"r-jollof-junction": "owner"},
    ),
    (
        "demo-kitchen-1",
        "kitchen@gudmeal.test",
        "Jollof Junction Kitchen",
        ["restaurant_staff"],
        {"r-jollof-junction": "staff"},
    ),
    ("demo-rider-1", "rider@gudmeal.test", "Chidi Okafor", ["rider"], {}),
    ("demo-support-1", "support@gudmeal.test", "Support Agent", ["support_agent"], {}),
    ("demo-finance-1", "finance@gudmeal.test", "Finance Manager", ["finance_manager"], {}),
    ("demo-hub-1", "hub@gudmeal.test", "Hub Agent", ["hub_agent"], {}),
    ("demo-admin-1", "admin@gudmeal.test", "Super Admin", ["super_admin"], {}),
]


def main() -> None:
    firebase_admin.initialize_app(options={"projectId": PROJECT})
    for uid, email, name, roles, restaurant_roles in USERS:
        try:
            auth.get_user(uid)
            auth.update_user(uid, email=email, password=PASSWORD, display_name=name, email_verified=True)
        except auth.UserNotFoundError:
            auth.create_user(uid=uid, email=email, password=PASSWORD, display_name=name, email_verified=True)
        auth.set_custom_user_claims(uid, {"roles": roles, "restaurant_roles": restaurant_roles})
        print(f"  {email:<26} roles={roles or ['customer']}")
    print(f"Seeded {len(USERS)} emulator users (password from DEMO_USER_PASSWORD).")


if __name__ == "__main__":
    main()
