import logging
from django.core.management.base import BaseCommand
from django.utils import timezone
from apps.bookings.models import Booking
from apps.audit.models import AuditLog

logger = logging.getLogger('keralink.compliance')

class Command(BaseCommand):
    help = (
        "Purges residual data and revokes all auxiliary passes/tokens for bookings whose "
        "statutory financial and tax retention period (retention_until) has expired."
    )

    def add_arguments(self, parser):
        parser.add_argument(
            '--dry-run',
            action='store_true',
            help='Simulate the purge process without committing changes to the database.',
        )

    def handle(self, *args, **options):
        dry_run = options['dry_run']
        now = timezone.now()

        expired_bookings = Booking.objects.filter(
            retention_until__isnull=False,
            retention_until__lte=now,
        )
        count = expired_bookings.count()

        if dry_run:
            self.stdout.write(self.style.WARNING(
                f"[DRY RUN] Found {count} booking(s) whose statutory retention period expired before {now.isoformat()}."
            ))
            return

        purged_references = []
        for booking in expired_bookings:
            ref = booking.booking_reference
            # Invalidate digital pass and clear QR references
            booking.digital_pass_token = None
            booking.qr_code_url = None
            booking.trip_title = "Archived Expired Booking"
            booking.save(update_fields=['digital_pass_token', 'qr_code_url', 'trip_title', 'updated_at'])

            # Revoke linked trip share tokens
            try:
                from apps.safety.models import TripShareToken
                TripShareToken.objects.filter(booking=booking).update(is_revoked=True)
            except Exception:
                pass

            # Record audit entry
            try:
                AuditLog.objects.create(
                    actor=None,
                    actor_role="SYSTEM_CRON",
                    action="STATUTORY_RETENTION_EXPIRED_PURGE",
                    resource_type="BOOKING",
                    resource_id=str(booking.id),
                    after_state={
                        'booking_reference': ref,
                        'retention_until': booking.retention_until.isoformat() if booking.retention_until else None,
                        'purged_at': now.isoformat(),
                    }
                )
            except Exception as e:
                logger.error(f"Failed to record audit log for purged booking {ref}: {e}")

            purged_references.append(ref)

        self.stdout.write(self.style.SUCCESS(
            f"Successfully executed retention purge for {len(purged_references)} booking(s)."
        ))
