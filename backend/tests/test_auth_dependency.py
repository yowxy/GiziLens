"""Unit tests for the API-key / admin-session dependency."""
import os
import unittest
from unittest import mock

from fastapi import HTTPException

from app.config import get_settings
from app.dependencies import verify_api_key_or_admin


class VerifyApiKeyOrAdminTest(unittest.TestCase):
    def setUp(self) -> None:
        get_settings.cache_clear()
        self._env = mock.patch.dict(
            os.environ,
            {"REQUIRE_API_KEY": "true", "API_KEYS": "sk_test_abc, sk_test_xyz"},
        )
        self._env.start()

    def tearDown(self) -> None:
        self._env.stop()
        get_settings.cache_clear()

    def test_accepts_valid_api_key(self) -> None:
        self.assertIsNone(verify_api_key_or_admin(x_api_key="sk_test_xyz"))

    def test_rejects_missing_credentials(self) -> None:
        with self.assertRaises(HTTPException) as ctx:
            verify_api_key_or_admin(x_api_key=None, authorization=None)
        self.assertEqual(ctx.exception.status_code, 401)

    def test_rejects_unknown_api_key(self) -> None:
        with self.assertRaises(HTTPException) as ctx:
            verify_api_key_or_admin(x_api_key="sk_test_nope", authorization=None)
        self.assertEqual(ctx.exception.status_code, 401)

    def test_bearer_token_is_resolved_as_admin(self) -> None:
        with mock.patch(
            "app.dependencies.get_current_user", return_value={"uid": "admin-1"}
        ), mock.patch(
            "app.dependencies.require_admin", return_value={"uid": "admin-1"}
        ) as admin:
            result = verify_api_key_or_admin(
                x_api_key=None, authorization="Bearer fake-token"
            )
        self.assertEqual(result, {"uid": "admin-1"})
        admin.assert_called_once_with(user={"uid": "admin-1"})

    def test_skips_check_when_api_key_not_required(self) -> None:
        get_settings.cache_clear()
        with mock.patch.dict(os.environ, {"REQUIRE_API_KEY": "false"}):
            get_settings.cache_clear()
            self.assertIsNone(verify_api_key_or_admin(x_api_key=None))


if __name__ == "__main__":
    unittest.main()
