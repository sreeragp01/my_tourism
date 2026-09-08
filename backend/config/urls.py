from django.contrib import admin
from django.urls import path, include

urlpatterns = [
    path('admin/', admin.site.urls),

    # API v1 Group
    path('api/v1/auth/', include('apps.accounts.urls')),
    path('api/v1/destinations/', include('apps.destinations.urls')),
    path('api/v1/experiences/', include('apps.experiences.urls')),
    path('api/v1/accommodations/', include('apps.accommodations.urls')),
    path('api/v1/inventory/', include('apps.inventory.urls')),
    path('api/v1/pricing/', include('apps.pricing.urls')),
    path('api/v1/ai/', include('apps.ai.urls')),
    path('api/v1/companion/', include('apps.companion.urls')),
    path('api/v1/bookings/', include('apps.bookings.urls')),
    path('api/v1/trips/', include('apps.bookings.trip_urls')),
    path('api/v1/payments/', include('apps.payments.urls')),
    path('api/v1/provider/', include('apps.organizations.urls')),
    path('api/v1/audit/', include('apps.audit.urls')),
    path('api/v1/search/', include('apps.search.urls')),

    # Wave D: Live Trip Experience Engine
    path('api/v1/location/', include('apps.location.urls')),
    path('api/v1/maps/', include('apps.maps.urls')),
    path('api/v1/weather/', include('apps.weather.urls')),
    path('api/v1/safety/', include('apps.safety.urls')),
    path('api/v1/notifications/', include('apps.notifications.urls')),
]

# Optional OpenAPI Spectacular docs if installed
try:
    from drf_spectacular.views import SpectacularAPIView, SpectacularSwaggerView
    urlpatterns = [
        path('api/schema/', SpectacularAPIView.as_view(), name='schema'),
        path('api/docs/', SpectacularSwaggerView.as_view(url_name='schema'), name='swagger-ui'),
    ] + urlpatterns
except ImportError:
    pass
