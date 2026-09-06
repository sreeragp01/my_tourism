from .models import AuditLog

class AuditLoggingMiddleware:
    """
    Middleware that records mutating requests (POST, PUT, PATCH, DELETE)
    into the immutable AuditLog table for compliance and security forensics.
    """
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        response = self.get_response(request)

        # Log sensitive mutations
        if request.method in ['POST', 'PUT', 'PATCH', 'DELETE'] and request.path.startswith('/api/'):
            user = request.user if getattr(request, 'user', None) and request.user.is_authenticated else None
            role = getattr(user, 'role', 'ANONYMOUS') if user else 'ANONYMOUS'
            ip = request.META.get('HTTP_X_FORWARDED_FOR', request.META.get('REMOTE_ADDR', ''))
            ua = request.META.get('HTTP_USER_AGENT', '')

            try:
                AuditLog.objects.create(
                    actor=user,
                    actor_role=role,
                    action=f"{request.method} {request.path}",
                    resource_type="API_ENDPOINT",
                    resource_id=request.path,
                    ip_address=ip.split(',')[0].strip() if ip else None,
                    user_agent=ua[:255] if ua else None,
                )
            except Exception:
                # Do not block request if audit log write encounters error
                pass

        return response
