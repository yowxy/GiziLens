"""SQLAlchemy ORM models for the v1 GiziLens PostgreSQL schema.

Mirrors ``app/database/migrations/alembic/versions/sql/0001..0004``:

0001 organizations, organization_members, sppg_school_links, batches, akg_targets
0002 plans, subscriptions, quota_buckets, payments
0003 scans, scan_images, inspections, inspection_items
0004 ai_usage_logs

Firebase owns authentication; PostgreSQL owns operational data only.
"""
from __future__ import annotations

import uuid
from datetime import date, datetime
from decimal import Decimal
from typing import Any

from sqlalchemy import (
    BigInteger,
    Boolean,
    CheckConstraint,
    Date,
    DateTime,
    ForeignKey,
    Integer,
    Numeric,
    Text,
    Uuid,
    func,
    text,
)
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database.base import Base


class Organization(Base):
    __tablename__ = "organizations"

    id: Mapped[uuid.UUID] = mapped_column(Uuid, primary_key=True, default=uuid.uuid4)
    name: Mapped[str] = mapped_column(Text, nullable=False)
    type: Mapped[str] = mapped_column(Text, nullable=False)
    registration_code: Mapped[str | None] = mapped_column(Text)
    province: Mapped[str | None] = mapped_column(Text)
    city: Mapped[str | None] = mapped_column(Text)
    district: Mapped[str | None] = mapped_column(Text)
    address: Mapped[str | None] = mapped_column(Text)
    status: Mapped[str] = mapped_column(Text, nullable=False, server_default="PENDING")
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now()
    )

    members: Mapped[list[OrganizationMember]] = relationship(
        back_populates="organization", cascade="all, delete-orphan"
    )


class OrganizationMember(Base):
    __tablename__ = "organization_members"

    id: Mapped[uuid.UUID] = mapped_column(Uuid, primary_key=True, default=uuid.uuid4)
    organization_id: Mapped[uuid.UUID] = mapped_column(
        Uuid, ForeignKey("organizations.id"), nullable=False
    )
    firebase_uid: Mapped[str] = mapped_column(Text, nullable=False)
    membership_role: Mapped[str] = mapped_column(Text, nullable=False)
    status: Mapped[str] = mapped_column(Text, nullable=False, server_default="INVITED")
    joined_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now()
    )

    organization: Mapped[Organization] = relationship(back_populates="members")


class SppgSchoolLink(Base):
    __tablename__ = "sppg_school_links"

    id: Mapped[uuid.UUID] = mapped_column(Uuid, primary_key=True, default=uuid.uuid4)
    sppg_id: Mapped[uuid.UUID] = mapped_column(Uuid, ForeignKey("organizations.id"))
    school_id: Mapped[uuid.UUID] = mapped_column(Uuid, ForeignKey("organizations.id"))
    status: Mapped[str] = mapped_column(Text, nullable=False, server_default="PENDING")
    started_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    ended_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now()
    )


class Batch(Base):
    __tablename__ = "batches"

    id: Mapped[uuid.UUID] = mapped_column(Uuid, primary_key=True, default=uuid.uuid4)
    sppg_id: Mapped[uuid.UUID] = mapped_column(Uuid, ForeignKey("organizations.id"))
    school_id: Mapped[uuid.UUID | None] = mapped_column(Uuid, ForeignKey("organizations.id"))
    batch_code: Mapped[str] = mapped_column(Text, nullable=False)
    production_date: Mapped[date] = mapped_column(Date, nullable=False)
    created_by_uid: Mapped[str] = mapped_column(Text, nullable=False)
    notes: Mapped[str | None] = mapped_column(Text)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now()
    )

    sppg: Mapped[Organization] = relationship(foreign_keys=[sppg_id])
    school: Mapped[Organization | None] = relationship(foreign_keys=[school_id])


class AkgTarget(Base):
    __tablename__ = "akg_targets"

    id: Mapped[uuid.UUID] = mapped_column(Uuid, primary_key=True, default=uuid.uuid4)
    group_code: Mapped[str] = mapped_column(Text, nullable=False)
    group_name: Mapped[str] = mapped_column(Text, nullable=False)
    standard_version: Mapped[str] = mapped_column(Text, nullable=False)
    calories: Mapped[Decimal] = mapped_column(Numeric(12, 4), nullable=False)
    protein: Mapped[Decimal] = mapped_column(Numeric(12, 4), nullable=False)
    fat: Mapped[Decimal] = mapped_column(Numeric(12, 4), nullable=False)
    carbohydrate: Mapped[Decimal] = mapped_column(Numeric(12, 4), nullable=False)
    fiber: Mapped[Decimal] = mapped_column(Numeric(12, 4), nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default="false")
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now()
    )


class Plan(Base):
    __tablename__ = "plans"

    id: Mapped[uuid.UUID] = mapped_column(Uuid, primary_key=True, default=uuid.uuid4)
    code: Mapped[str] = mapped_column(Text, nullable=False, unique=True)
    name: Mapped[str] = mapped_column(Text, nullable=False)
    description: Mapped[str | None] = mapped_column(Text)
    price: Mapped[int] = mapped_column(BigInteger, nullable=False)
    billing_cycle: Mapped[str] = mapped_column(Text, nullable=False)
    quota_cycle: Mapped[str] = mapped_column(Text, nullable=False, server_default="MONTHLY")
    scan_quota: Mapped[int | None] = mapped_column(Integer)
    max_members: Mapped[int | None] = mapped_column(Integer)
    history_retention_days: Mapped[int | None] = mapped_column(Integer)
    features: Mapped[list[Any]] = mapped_column(
        JSONB, nullable=False, server_default=text("'[]'::jsonb")
    )
    is_active: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default="false")
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now()
    )


class Subscription(Base):
    __tablename__ = "subscriptions"

    id: Mapped[uuid.UUID] = mapped_column(Uuid, primary_key=True, default=uuid.uuid4)
    organization_id: Mapped[uuid.UUID] = mapped_column(Uuid, ForeignKey("organizations.id"))
    plan_id: Mapped[uuid.UUID] = mapped_column(Uuid, ForeignKey("plans.id"))
    status: Mapped[str] = mapped_column(Text, nullable=False, server_default="PENDING")
    starts_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    price_snapshot: Mapped[int] = mapped_column(BigInteger, nullable=False)
    entitlement_snapshot: Mapped[dict[str, Any]] = mapped_column(JSONB, nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now()
    )

    plan: Mapped[Plan] = relationship()
    organization: Mapped[Organization] = relationship()


class QuotaBucket(Base):
    __tablename__ = "quota_buckets"

    id: Mapped[uuid.UUID] = mapped_column(Uuid, primary_key=True, default=uuid.uuid4)
    organization_id: Mapped[uuid.UUID] = mapped_column(Uuid, ForeignKey("organizations.id"))
    subscription_id: Mapped[uuid.UUID | None] = mapped_column(Uuid)
    quota_type: Mapped[str] = mapped_column(Text, nullable=False)
    scan_limit: Mapped[int] = mapped_column(Integer, nullable=False)
    used_scans: Mapped[int] = mapped_column(Integer, nullable=False, server_default="0")
    reserved_scans: Mapped[int] = mapped_column(Integer, nullable=False, server_default="0")
    period_start: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now()
    )
    period_end: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now()
    )


class Payment(Base):
    __tablename__ = "payments"

    id: Mapped[uuid.UUID] = mapped_column(Uuid, primary_key=True, default=uuid.uuid4)
    organization_id: Mapped[uuid.UUID] = mapped_column(Uuid, ForeignKey("organizations.id"))
    plan_id: Mapped[uuid.UUID] = mapped_column(Uuid, ForeignKey("plans.id"))
    subscription_id: Mapped[uuid.UUID | None] = mapped_column(Uuid)
    payer_firebase_uid: Mapped[str] = mapped_column(Text, nullable=False)
    order_id: Mapped[str] = mapped_column(Text, nullable=False, unique=True)
    gross_amount: Mapped[int] = mapped_column(BigInteger, nullable=False)
    currency: Mapped[str] = mapped_column(Text, nullable=False, server_default="IDR")
    entitlement_snapshot: Mapped[dict[str, Any]] = mapped_column(JSONB, nullable=False)
    payment_method: Mapped[str | None] = mapped_column(Text)
    payment_gateway: Mapped[str] = mapped_column(
        Text, nullable=False, server_default="MIDTRANS"
    )
    gateway_environment: Mapped[str] = mapped_column(
        Text, nullable=False, server_default="SANDBOX"
    )
    gateway_transaction_id: Mapped[str | None] = mapped_column(Text)
    status: Mapped[str] = mapped_column(Text, nullable=False, server_default="PENDING")
    refunded_amount: Mapped[int] = mapped_column(BigInteger, nullable=False, server_default="0")
    paid_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now()
    )

    plan: Mapped[Plan] = relationship()
    organization: Mapped[Organization] = relationship()


class Scan(Base):
    __tablename__ = "scans"

    id: Mapped[uuid.UUID] = mapped_column(Uuid, primary_key=True, default=uuid.uuid4)
    organization_id: Mapped[uuid.UUID] = mapped_column(Uuid, ForeignKey("organizations.id"))
    firebase_uid: Mapped[str] = mapped_column(Text, nullable=False)
    batch_id: Mapped[uuid.UUID] = mapped_column(Uuid, ForeignKey("batches.id"))
    akg_target_id: Mapped[uuid.UUID] = mapped_column(Uuid, ForeignKey("akg_targets.id"))
    quota_bucket_id: Mapped[uuid.UUID | None] = mapped_column(Uuid)
    idempotency_key: Mapped[str] = mapped_column(Text, nullable=False)
    origin: Mapped[str] = mapped_column(Text, nullable=False, server_default="LIVE")
    legacy_firestore_id: Mapped[str | None] = mapped_column(Text, unique=True)
    status: Mapped[str] = mapped_column(Text, nullable=False, server_default="PROCESSING")
    quota_status: Mapped[str] = mapped_column(Text, nullable=False, server_default="RESERVED")
    ai_model: Mapped[str | None] = mapped_column(Text)
    raw_result: Mapped[dict[str, Any] | None] = mapped_column(JSONB)
    target_snapshot: Mapped[dict[str, Any]] = mapped_column(JSONB, nullable=False)
    processing_ms: Mapped[int | None] = mapped_column(Integer)
    error_code: Mapped[str | None] = mapped_column(Text)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now()
    )
    completed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    reservation_expires_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))

    batch: Mapped[Batch] = relationship()
    akg_target: Mapped[AkgTarget] = relationship()
    organization: Mapped[Organization] = relationship()
    images: Mapped[list[ScanImage]] = relationship(back_populates="scan")
    inspection: Mapped[Inspection | None] = relationship(back_populates="scan", uselist=False)


class ScanImage(Base):
    __tablename__ = "scan_images"

    id: Mapped[uuid.UUID] = mapped_column(Uuid, primary_key=True, default=uuid.uuid4)
    scan_id: Mapped[uuid.UUID] = mapped_column(Uuid, ForeignKey("scans.id"), nullable=False)
    storage_backend: Mapped[str] = mapped_column(Text, nullable=False)
    bucket: Mapped[str] = mapped_column(Text, nullable=False)
    object_key: Mapped[str] = mapped_column(Text, nullable=False)
    image_type: Mapped[str] = mapped_column(Text, nullable=False)
    mime_type: Mapped[str] = mapped_column(Text, nullable=False)
    size_bytes: Mapped[int] = mapped_column(BigInteger, nullable=False)
    width: Mapped[int] = mapped_column(Integer, nullable=False)
    height: Mapped[int] = mapped_column(Integer, nullable=False)
    sha256: Mapped[str | None] = mapped_column(Text)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now()
    )
    deleted_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))

    scan: Mapped[Scan] = relationship(back_populates="images")


class Inspection(Base):
    __tablename__ = "inspections"

    id: Mapped[uuid.UUID] = mapped_column(Uuid, primary_key=True, default=uuid.uuid4)
    scan_id: Mapped[uuid.UUID] = mapped_column(
        Uuid, ForeignKey("scans.id"), nullable=False, unique=True
    )
    verified_by_uid: Mapped[str] = mapped_column(Text, nullable=False)
    verifier_snapshot: Mapped[dict[str, Any] | None] = mapped_column(JSONB)
    total_weight: Mapped[Decimal] = mapped_column(Numeric(10, 2), nullable=False)
    total_calories: Mapped[Decimal] = mapped_column(Numeric(12, 4), nullable=False)
    total_protein: Mapped[Decimal] = mapped_column(Numeric(12, 4), nullable=False)
    total_fat: Mapped[Decimal] = mapped_column(Numeric(12, 4), nullable=False)
    total_carbohydrate: Mapped[Decimal] = mapped_column(Numeric(12, 4), nullable=False)
    total_fiber: Mapped[Decimal] = mapped_column(Numeric(12, 4), nullable=False)
    compliance_status: Mapped[str] = mapped_column(Text, nullable=False)
    policy_version: Mapped[str] = mapped_column(Text, nullable=False)
    notes: Mapped[str | None] = mapped_column(Text)
    locked_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now()
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now()
    )

    scan: Mapped[Scan] = relationship(back_populates="inspection")
    items: Mapped[list[InspectionItem]] = relationship(
        back_populates="inspection", cascade="all, delete-orphan"
    )


class InspectionItem(Base):
    __tablename__ = "inspection_items"

    id: Mapped[uuid.UUID] = mapped_column(Uuid, primary_key=True, default=uuid.uuid4)
    inspection_id: Mapped[uuid.UUID] = mapped_column(
        Uuid, ForeignKey("inspections.id"), nullable=False
    )
    name: Mapped[str] = mapped_column(Text, nullable=False)
    category: Mapped[str] = mapped_column(Text, nullable=False)
    compartment_number: Mapped[int | None] = mapped_column(Integer)
    estimated_gram: Mapped[Decimal] = mapped_column(Numeric(10, 2), nullable=False)
    confidence: Mapped[Decimal | None] = mapped_column(Numeric(5, 4))
    calories: Mapped[Decimal] = mapped_column(Numeric(12, 4), nullable=False)
    protein: Mapped[Decimal] = mapped_column(Numeric(12, 4), nullable=False)
    fat: Mapped[Decimal] = mapped_column(Numeric(12, 4), nullable=False)
    carbohydrate: Mapped[Decimal] = mapped_column(Numeric(12, 4), nullable=False)
    fiber: Mapped[Decimal] = mapped_column(Numeric(12, 4), nullable=False)
    bounding_box: Mapped[dict[str, Any] | None] = mapped_column(JSONB)
    is_verified: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default="false")
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now()
    )

    inspection: Mapped[Inspection] = relationship(back_populates="items")


class AiUsageLog(Base):
    __tablename__ = "ai_usage_logs"

    id: Mapped[uuid.UUID] = mapped_column(Uuid, primary_key=True, default=uuid.uuid4)
    scan_id: Mapped[uuid.UUID] = mapped_column(Uuid, ForeignKey("scans.id"), nullable=False)
    attempt_number: Mapped[int] = mapped_column(Integer, nullable=False)
    gateway_request_id: Mapped[str | None] = mapped_column(Text)
    provider: Mapped[str | None] = mapped_column(Text)
    model: Mapped[str | None] = mapped_column(Text)
    input_tokens: Mapped[int | None] = mapped_column(Integer)
    output_tokens: Mapped[int | None] = mapped_column(Integer)
    estimated_cost: Mapped[Decimal | None] = mapped_column(Numeric(18, 8))
    currency: Mapped[str | None] = mapped_column(Text)
    cost_source: Mapped[str | None] = mapped_column(Text)
    latency_ms: Mapped[int | None] = mapped_column(Integer)
    status: Mapped[str] = mapped_column(Text, nullable=False)
    error_code: Mapped[str | None] = mapped_column(Text)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now()
    )
