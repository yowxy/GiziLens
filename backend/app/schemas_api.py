"""Pydantic schemas for the GiziLens data API.

All payloads use camelCase on the wire (matching the React dashboard and the
Flutter client). Snake_case field names are still accepted on input.
"""
from __future__ import annotations

from typing import Any, Literal

from pydantic import BaseModel, ConfigDict, Field
from pydantic.alias_generators import to_camel


class ApiModel(BaseModel):
    model_config = ConfigDict(
        alias_generator=to_camel,
        populate_by_name=True,
        from_attributes=True,
    )


# ---------------------------------------------------------------------------
# Dashboard
# ---------------------------------------------------------------------------


class KpiOut(ApiModel):
    total_users: int
    users_trend: str | None = None
    users_note: str | None = None
    registered_sppg: int
    sppg_trend: str | None = None
    sppg_note: str | None = None
    registered_schools: int
    schools_trend: str | None = None
    schools_note: str | None = None
    total_assessments: int
    assessments_trend: str | None = None
    assessments_note: str | None = None
    active_premium: int
    premium_trend: str | None = None
    premium_note: str | None = None
    total_revenue: str | None = None
    revenue_trend: str | None = None
    revenue_note: str | None = None


class ActivityPointOut(ApiModel):
    label: str
    evaluated: int
    previous: int


class ActivityOut(ApiModel):
    subtitle: str
    total: str
    trend: str
    highlight_label: str
    points: list[ActivityPointOut]


class ComplianceCategoryOut(ApiModel):
    key: str
    label: str
    subtitle: str | None = None
    percentage: float
    baki_count: int
    color_hex: str | None = None


class ComplianceOut(ApiModel):
    categories: list[ComplianceCategoryOut]
    total: int


class RegionOut(ApiModel):
    rank: int
    province: str
    sppg_units: int
    schools: int
    assessments: int
    target_pct: float


class RegionsOut(ApiModel):
    items: list[RegionOut]


# ---------------------------------------------------------------------------
# Users
# ---------------------------------------------------------------------------


class UserOut(ApiModel):
    uid: str
    name: str
    full_name: str
    email: str
    phone: str | None = None
    role: str
    institution: str
    status: Literal["Verified", "Pending Approval"]
    created_at_label: str
    created_at_ms: int | None = None
    unit: str | None = None
    region: str | None = None
    officer_id: str | None = None
    is_verified: bool
    subscription_plan: str
    is_premium: bool
    notifications_enabled: bool


class UserListOut(ApiModel):
    items: list[UserOut]
    total: int
    page: int
    page_size: int


class UserUpsert(ApiModel):
    uid: str = Field(min_length=1, max_length=128)
    full_name: str | None = None
    name: str | None = None
    email: str | None = None
    phone: str | None = None
    role: str | None = None
    unit: str | None = None
    institution: str | None = None
    region: str | None = None
    officer_id: str | None = None
    is_verified: bool | None = None
    status: Literal["Verified", "Pending Approval"] | None = None
    subscription_plan: str | None = None
    is_premium: bool | None = None
    notifications_enabled: bool | None = None


class UserStatusPatch(ApiModel):
    status: Literal["Verified", "Pending Approval"]


# ---------------------------------------------------------------------------
# Inspections
# ---------------------------------------------------------------------------


class NutritionIn(ApiModel):
    calories: float = 0
    protein: float = 0
    fat: float = 0
    carbohydrate: float = 0
    fiber: float = 0


class BoundingBoxIn(ApiModel):
    x: float = 0
    y: float = 0
    width: float = 0
    height: float = 0


class ComponentIn(ApiModel):
    id: str | None = None
    name: str
    gram: float = 0
    compartment_number: int = 0
    category: str | None = None
    confidence_percentage: float = 0
    is_verified: bool = True
    nutrition: NutritionIn = Field(default_factory=NutritionIn)
    bbox: BoundingBoxIn | None = None


class ComponentOut(ApiModel):
    id: str | None = None
    name: str
    gram: float
    compartment_number: int
    category: str | None = None
    confidence_percentage: float
    is_verified: bool
    nutrition: NutritionIn
    bbox: BoundingBoxIn | None = None


class InspectionCreate(ApiModel):
    id: str | None = None
    batch_code: str = ""
    school_name: str | None = None
    target_group: str | None = None
    session: str | None = None
    total_net_weight: str | None = None
    scanned_at: str | None = None
    compliance_status: str = "SESUAI"
    is_locked: bool = True
    verifier_role: str | None = None
    officer_name: str | None = None
    officer_id: str | None = None
    unit_operational: str | None = None
    detection_provider: str | None = None
    detection_model: str | None = None
    target_akg2019: dict[str, Any] | None = None
    nutrition: dict[str, Any] | None = None
    components: list[ComponentIn] = Field(default_factory=list)
    notes: str | None = None
    user_uid: str | None = None
    user_email: str | None = None
    image_base64: str | None = None


class InspectionSummaryOut(ApiModel):
    id: str
    batch_code: str
    school_name: str | None = None
    session: str | None = None
    compliance_status: str
    total_net_weight: str | None = None
    scanned_at: str | None = None
    target_group: str | None = None
    officer_name: str | None = None
    unit_operational: str | None = None
    created_at: str | None = None
    image_url: str | None = None
    image_width: int | None = None
    image_height: int | None = None


class InspectionListOut(ApiModel):
    items: list[InspectionSummaryOut]
    total: int
    page: int
    page_size: int


class InspectionDetailOut(InspectionSummaryOut):
    user_uid: str | None = None
    user_email: str | None = None
    officer_id: str | None = None
    verifier_role: str | None = None
    detection_provider: str | None = None
    detection_model: str | None = None
    is_locked: bool = False
    notes: str | None = None
    target_akg2019: dict[str, Any] = Field(default_factory=dict)
    nutrition: dict[str, Any] = Field(default_factory=dict)
    components: list[ComponentOut] = Field(default_factory=list)


class InspectionDetailListOut(ApiModel):
    items: list[InspectionDetailOut]
    total: int
    page: int
    page_size: int


class InspectionCreateOut(ApiModel):
    id: str
    created: bool


# ---------------------------------------------------------------------------
# Subscription plans & transactions
# ---------------------------------------------------------------------------


class PlanOut(ApiModel):
    id: str
    name: str
    tagline: str | None = None
    monthly_equivalent_price: int
    billed_price: int
    original_price: int | None = None
    billing_period: str | None = None
    is_popular: bool
    badge_text: str | None = None
    bundle_highlights: list[Any]
    features: list[Any]
    cta_label: str


class PlanListOut(ApiModel):
    items: list[PlanOut]


class TransactionOut(ApiModel):
    order_id: str
    user: str
    organization: str | None = None
    plan: str
    plan_icon: str
    amount: str
    status: str
    plan_id: str | None = None
    plan_price: int = 0
    total_amount: int = 0
    payment_status: str = "pending"
    created_at: str | None = None
    va_number: str | None = None


class TransactionListOut(ApiModel):
    items: list[TransactionOut]
    total: int
    page: int
    page_size: int


class TransactionCreate(ApiModel):
    order_id: str = Field(min_length=1, max_length=64)
    plan_id: str | None = None
    plan_name: str = Field(min_length=1)
    plan_price: int = 0
    admin_fee: int = 0
    tax_amount: int = 0
    total_amount: int = 0
    selected_method: dict[str, Any] = Field(default_factory=dict)
    status: Literal["pending", "settlement", "failed", "expired"] = "pending"
    officer_name: str | None = None
    sppg_unit: str | None = None
    customer_email: str | None = None
    user_uid: str | None = None


class TransactionStatusPatch(ApiModel):
    status: Literal["pending", "settlement", "failed", "expired"]


class DbHealthOut(ApiModel):
    status: str
    database: bool
    latency_ms: float | None = None


# ---------------------------------------------------------------------------
# Menu recommendations
# ---------------------------------------------------------------------------


class MenuComponentIn(ApiModel):
    name: str
    category: str = "Lainnya"
    gram: float = 0
    calories: float = 0
    protein: float = 0
    fat: float = 0
    carbohydrate: float = 0
    fiber: float = 0


class MenuRecommendationIn(ApiModel):
    target_group: str = ""
    target: dict[str, Any] = Field(default_factory=dict)
    current: dict[str, Any] = Field(default_factory=dict)
    components: list[MenuComponentIn] = Field(default_factory=list)
    notes: str | None = None


class RecommendedMenuItemOut(ApiModel):
    name: str
    category: str = "Lainnya"
    portion: str = ""
    reason: str = ""
    estimated_gram: float = 0


class MenuRecommendationOut(ApiModel):
    summary: str = ""
    items: list[RecommendedMenuItemOut] = Field(default_factory=list)
    tips: list[str] = Field(default_factory=list)
