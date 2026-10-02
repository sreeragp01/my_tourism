import logging
from django.core.mail import send_mail
from django.conf import settings

logger = logging.getLogger(__name__)

class AccountEmailService:
    @staticmethod
    def send_password_reset_otp_email(user, otp_code: str) -> bool:
        """
        Sends password reset OTP email to user's registered email address.
        """
        subject = f"Your KeraLink Password Reset Code: {otp_code}"
        message = (
            f"Hello {user.first_name or 'Traveler'},\n\n"
            f"You requested to reset your password for your KeraLink account.\n\n"
            f"Your 6-Digit Verification Code is:  {otp_code}\n\n"
            f"This code will expire in 15 minutes. If you did not make this request, please ignore this email.\n\n"
            f"Best regards,\n"
            f"KeraLink Tourism Platform\n"
            f"God's Own Country Live Travel Companion"
        )
        html_message = f"""
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 24px; border: 1px solid #e2e8f0; border-radius: 12px; background-color: #ffffff;">
            <div style="text-align: center; margin-bottom: 24px;">
                <h1 style="color: #0d9488; margin: 0; font-size: 28px;">&#127796; KeraLink</h1>
                <p style="color: #64748b; margin-top: 4px; font-size: 14px;">God's Own Country Live Travel Companion</p>
            </div>
            <div style="background-color: #f8fafc; border-radius: 8px; padding: 20px; margin-bottom: 20px;">
                <h2 style="color: #1e293b; font-size: 18px; margin-top: 0;">Password Reset Request</h2>
                <p style="color: #475569; font-size: 15px; line-height: 1.5;">
                    Hello <strong>{user.first_name or 'Traveler'}</strong>,<br/>
                    We received a request to reset your password for <strong>{user.email}</strong>. Use the 6-digit verification code below to complete the reset:
                </p>
                <div style="text-align: center; margin: 24px 0;">
                    <span style="display: inline-block; font-size: 32px; font-weight: bold; letter-spacing: 6px; color: #0d9488; background: #ccfbf1; padding: 12px 28px; border-radius: 8px; border: 1px solid #5eead4;">
                        {otp_code}
                    </span>
                </div>
                <p style="color: #64748b; font-size: 13px; text-align: center; margin: 0;">
                    &#9201; This code expires in <strong>15 minutes</strong>.
                </p>
            </div>
            <p style="color: #94a3b8; font-size: 12px; line-height: 1.4; text-align: center;">
                If you did not request a password reset, you can safely ignore this email. Your account remains secure.<br/>
                &copy; 2026 KeraLink Tourism. All rights reserved.
            </p>
        </div>
        """

        try:
            send_mail(
                subject=subject,
                message=message,
                from_email=getattr(settings, 'DEFAULT_FROM_EMAIL', 'noreply@keralink.travel'),
                recipient_list=[user.email],
                html_message=html_message,
                fail_silently=False
            )
            logger.info(f"Password reset OTP email sent successfully to {user.email}")
            return True
        except Exception as e:
            logger.warning(f"Failed to send email to {user.email} via SMTP: {e}. Outputting to console logs.")
            print(f"\n[EMAIL DISPATCH] To: {user.email} | OTP: {otp_code} | Subject: {subject}\n")
            return False

    @staticmethod
    def send_verification_otp_email(user, otp_code: str) -> bool:
        """
        Sends email verification OTP to newly registered user.
        """
        subject = f"Verify your KeraLink Account: {otp_code}"
        message = (
            f"Hello {user.first_name},\n\n"
            f"Welcome to KeraLink! Your verification code is: {otp_code}\n\n"
            f"Valid for 30 minutes.\n\n"
            f"Best regards,\nKeraLink Team"
        )
        try:
            send_mail(
                subject=subject,
                message=message,
                from_email=getattr(settings, 'DEFAULT_FROM_EMAIL', 'noreply@keralink.travel'),
                recipient_list=[user.email],
                fail_silently=False
            )
            return True
        except Exception as e:
            logger.warning(f"Failed to send verification email: {e}")
            print(f"\n[VERIFICATION EMAIL] To: {user.email} | OTP: {otp_code}\n")
            return False
