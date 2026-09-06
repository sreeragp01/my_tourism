# KeraLink 🌴 — AI Experiential Tourism & Live Companion Platform

KeraLink is a next-generation experiential tourism and live trip companion platform purpose-built for Kerala (*"God's Own Country"*). It connects travelers, local verified experience providers, and ground operators through an explainable AI travel architect, authoritative booking lifecycle engine, monsoon-adaptive live companion, and multi-tenant management portals.

---

## 🏗️ Architecture Overview

```
tourism/
├── backend/            # Django 5 & DRF REST API, PostGIS, Redis & Celery
│   ├── apps/
│   │   ├── accounts/   # JWT auth, session management & token rotation
│   │   ├── ai/         # NLP parser, route optimization & explainable AI
│   │   ├── bookings/   # Formal 12-state booking transition engine
│   │   ├── companion/  # Live companion orchestrator & tool registry
│   │   ├── payments/   # Idempotent Razorpay capture & webhook processor
│   │   ├── events/     # Transactional Outbox pattern with dead-letter queue
│   │   └── destinations, experiences, accommodations, inventory, pricing...
│   └── tests/          # 31 comprehensive E2E, unit & security tests
│
├── frontend/           # React 18, Vite 8, TypeScript, Tailwind CSS, Zustand
│   ├── src/
│   │   ├── features/   # Discovery, AI Planner, Itinerary, Checkout, Safety, Trips
│   │   ├── components/ # DeviceFrame simulator, interactive modals, navigation
│   │   └── stores/     # Zustand global state & offline persistence
│
├── mobile/             # Cross-Platform Flutter App (Android & iOS)
│   └── lib/
│       ├── core/       # API client & endpoint constants
│       └── features/   # Discover, AI Planner, Live Companion, My Trips & Safety Hub
│
└── infrastructure/     # Production Docker Compose orchestration
    └── docker/         # PostGIS 16, Redis 7, Django Gunicorn & Celery workers
```

---

## 🚀 Quick Start

### 1. Backend (Django REST Framework)
```bash
cd backend
python -m venv .venv
source .venv/bin/activate   # Or .venv\Scripts\activate on Windows
pip install -r requirements/base.txt
python manage.py migrate
python manage.py test tests
python manage.py runserver
```

### 2. Frontend (React + Vite)
```bash
cd frontend
npm install
npm run dev
```

### 3. Mobile (Flutter for Android & iOS)
```bash
cd mobile
flutter pub get
flutter run
```

### 4. Docker Compose (Full Stack)
```bash
cd infrastructure/docker
docker-compose up -d --build
```

---

## 🔒 Security & Reliability
- **Deterministic AI Guardrails**: AI recommendations are decoupled from authoritative mathematical pricing engines and inventory hold tables.
- **Idempotent Webhooks**: Strict deduplication via `ProcessedWebhookEvent` preventing duplicate charges.
- **Token Family Replay Defense**: Invalidates all family refresh sessions upon detection of token reuse.
- **Multi-Tenant RBAC**: Strict query isolation preventing cross-organization data leakage.
- **Transactional Outbox**: Guarantees atomic domain event publishing with exponential retries and dead-letter routing.

---

## 📄 License
Proprietary & Confidential © 2026 KeraLink. All rights reserved.
