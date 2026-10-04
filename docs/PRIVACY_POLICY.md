# Privacy & Data Retention Policy — KeraLink Tourism Platform

**Effective Date:** October 2026  
**Applicable Legal Frameworks:**  
- **Digital Personal Data Protection (DPDP) Act, 2023** (India)  
- **Central Goods and Services Tax (CGST) Act, 2017** (§ 36)  
- **Income Tax Act, 1961** (§ 44AB)  
- **Information Technology Act, 2000** & Intermediary Guidelines  

---

## 1. Overview and Core Commitment
KeraLink Experiential Tourism Platform ("KeraLink", "we", "us", or "our") provides curated, sustainable travel experiences across Kerala. We respect user privacy and are fully committed to protecting personal data in adherence with the Digital Personal Data Protection (DPDP) Act, 2023 and applicable statutory fiscal laws.

---

## 2. Personal Data Collected & Lawful Processing
We collect only the minimum personal data necessary for delivering booking and safety services:
- **Identity & Contact Information:** Name, email, mobile number, emergency contact details.
- **Trip & Itinerary Information:** Booking details, hotel stays, curated tours, transport arrangements.
- **Safety & Health Preferences (Optional):** Blood group, medical notes (e.g., allergies, asthma), dietary preferences, and explicit emergency location-sharing consents.
- **Financial & Transactional Data:** Payment references, transaction amounts, tax line-items, invoices, and gateway verification tokens. *Note: We never store card numbers, CVVs, or bank netbanking passwords.*

---

## 3. Right to Erasure & Account Deletion (DPDP Act)
Under the DPDP Act, every user has the right to withdraw consent and request the deletion of their personal data.

### When an account is deleted via `/api/v1/auth/delete-account/`:
1. **Immediate PII Scrubbing:**
   - Account is immediately deactivated, and passwords are permanently revoked.
   - User identity fields (`first_name`, `last_name`, `phone`, `email`) are overwritten with irreversible pseudonyms (e.g., `Deleted User`, `deleted_<anon_id>@<anon_id>.invalid`).
   - Profile health and emergency contact data (`medical_notes`, `emergency_contact_phone`, etc.) are wiped immediately.
   - All active authentication sessions, JWT tokens, OTPs, and public trip share links are permanently revoked.
2. **Guest Traveler Details on Bookings:**
   - Guest names and personal contact information on existing booking records are replaced with `"Deleted Traveler"`.

---

## 4. Statutory Financial & Tax Record Retention
While personal identifiers and sensitive profile data are scrubbed immediately upon account deletion, **financial ledgers and invoice records cannot be instantly purged from our database due to mandatory statutory obligations under Indian tax laws**:

### Applicable Statutory Retention Requirements:
1. **Section 36 of the CGST Act, 2017:**
   Registered businesses are legally required to retain books of accounts, tax invoices, credit notes, and transaction records for a minimum period of **72 months (6 years)** following the due date of furnishing the annual return for the relevant financial year (in practice, **up to 8 years**).
2. **Section 44AB of the Income Tax Act, 1961:**
   Auditable financial transaction records, gross receipts, and merchant ledger entries must be preserved for tax assessment proceedings.
3. **Prevention of Money Laundering Act (PMLA) & RBI Guidelines:**
   Payment gateway references and chargeback/refund trail data must remain auditable for anti-fraud reconciliation.

### Data Retained During the Statutory Period:
- Booking reference code (e.g., `KL-2026-ABC123`)
- Financial breakdown: Subtotal, CGST/SGST amounts, platform fee, total amount, and currency
- Confirmation timestamp and completion status
- Payment gateway reference (`gateway_payment_id`, `gateway_order_id`, and status)

*The primary guest name is anonymized to `"Deleted Traveler"` immediately upon user deletion, and no personal profile, emergency contact, or medical notes are retained.*

---

## 5. Automated Post-Retention Purge
Each anonymized booking is tagged with a `retention_until` deadline (configured by default to 8 years / 2,920 days):
- A daily automated job (`purge_expired_retention_data`) inspects the database for records exceeding `retention_until`.
- Once the statutory retention period has elapsed, all residual metadata, digital pass tokens, and QR URLs are permanently expunged.
- An immutable audit trail entry is recorded in the platform audit log to demonstrate compliance.

---

## 6. Data Portability (Export Rights)
Users may export a complete, machine-readable JSON copy of their personal data at any time via `/api/v1/auth/export-data/` prior to requesting account erasure. This export package includes identity, profile preferences, sessions, past bookings, payments, and system activity logs without exposing internal credentials.

---

## 7. Contact Data Protection Officer (DPO)
For any questions regarding DPDP compliance or data retention, contact:
- **Designation:** Data Protection Officer / Grievance Officer
- **Email:** `privacy@keralink.travel`
- **Location:** Kochi, Kerala, India
