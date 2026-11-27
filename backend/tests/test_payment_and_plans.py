"""Unit tests for single Premium plan and Midtrans payment helpers."""
import hashlib
import unittest

from app.routers.payment import (
    ENABLED_PAYMENTS_MAP,
    _map_midtrans_status,
    _verify_midtrans_signature,
)
from app.routers.plans import DEFAULT_PREMIUM_PLAN


class PaymentAndPlansTest(unittest.TestCase):
    def test_single_default_premium_plan(self):
        self.assertEqual(DEFAULT_PREMIUM_PLAN.id, "plan_premium")
        self.assertEqual(DEFAULT_PREMIUM_PLAN.name, "GiziLens Premium")
        self.assertGreater(DEFAULT_PREMIUM_PLAN.billed_price, 0)

    def test_enabled_payments_mapping(self):
        self.assertEqual(ENABLED_PAYMENTS_MAP["qris"], ["gopay", "shopeepay", "other_qris"])
        self.assertEqual(ENABLED_PAYMENTS_MAP["bca_va"], ["bca_va"])
        self.assertEqual(ENABLED_PAYMENTS_MAP["mandiri_va"], ["echannel"])
        self.assertEqual(ENABLED_PAYMENTS_MAP["bri_va"], ["bri_va"])
        self.assertEqual(ENABLED_PAYMENTS_MAP["bni_va"], ["bni_va"])
        self.assertEqual(ENABLED_PAYMENTS_MAP["credit_card"], ["credit_card"])

    def test_midtrans_signature_verification(self):
        order_id = "GIZI-12345678"
        status_code = "200"
        gross_amount = "109890.00"
        server_key = "SB-Mid-server-TestKey123"
        expected = hashlib.sha512(
            f"{order_id}{status_code}{gross_amount}{server_key}".encode("utf-8")
        ).hexdigest()

        self.assertTrue(
            _verify_midtrans_signature(
                order_id=order_id,
                status_code=status_code,
                gross_amount=gross_amount,
                signature_key=expected,
                server_key=server_key,
            )
        )
        self.assertFalse(
            _verify_midtrans_signature(
                order_id=order_id,
                status_code=status_code,
                gross_amount=gross_amount,
                signature_key="deadbeef",
                server_key=server_key,
            )
        )

    def test_midtrans_status_mapping(self):
        self.assertEqual(_map_midtrans_status("settlement"), "PAID")
        self.assertEqual(_map_midtrans_status("capture", "accept"), "PAID")
        self.assertEqual(_map_midtrans_status("capture", "challenge"), "PENDING")
        self.assertEqual(_map_midtrans_status("expire"), "EXPIRED")
        self.assertEqual(_map_midtrans_status("cancel"), "CANCELLED")
        self.assertEqual(_map_midtrans_status("deny"), "FAILED")
        self.assertEqual(_map_midtrans_status("pending"), "PENDING")


if __name__ == "__main__":
    unittest.main()
