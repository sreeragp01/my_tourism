import urllib.parse
from django.db.models import Q
from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import AllowAny

from .models import TourPackage, PackageInquiry
from .serializers import (
    TourPackageListSerializer,
    TourPackageDetailSerializer,
    PackageInquirySerializer,
)

class TourPackageViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = TourPackage.objects.filter(is_active=True)
    permission_classes = [AllowAny]
    lookup_field = 'slug'

    def get_serializer_class(self):
        if self.action == 'retrieve':
            return TourPackageDetailSerializer
        return TourPackageListSerializer

    def get_queryset(self):
        qs = super().get_queryset()
        
        # Category filter
        category = self.request.query_params.get('category')
        if category and category.upper() != 'ALL':
            qs = qs.filter(category=category.upper())

        # Destination filter
        destination = self.request.query_params.get('destination')
        if destination:
            qs = qs.filter(
                Q(destinations_covered__icontains=destination) |
                Q(title__icontains=destination) |
                Q(tagline__icontains=destination)
            )

        # Max duration filter
        max_days = self.request.query_params.get('max_days')
        if max_days:
            try:
                qs = qs.filter(duration_days__lte=int(max_days))
            except ValueError:
                pass

        # Price range filter
        max_price = self.request.query_params.get('max_price')
        if max_price:
            try:
                qs = qs.filter(price_per_person__lte=float(max_price))
            except ValueError:
                pass

        # Search query
        q = self.request.query_params.get('q')
        if q:
            qs = qs.filter(
                Q(title__icontains=q) |
                Q(tagline__icontains=q) |
                Q(description__icontains=q) |
                Q(operator_name__icontains=q) |
                Q(destinations_covered__icontains=q)
            )

        return qs

    @action(detail=False, methods=['get'])
    def featured(self, request):
        featured_packages = self.get_queryset().filter(is_featured=True)[:6]
        serializer = TourPackageListSerializer(featured_packages, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'])
    def categories(self, request):
        categories_data = [
            {'key': 'ALL', 'label': 'All Packages', 'icon': 'explore'},
            {'key': 'HILL_STATION', 'label': 'Hill Stations & Tea Trails', 'icon': 'landscape'},
            {'key': 'BACKWATERS', 'label': 'Houseboats & Backwaters', 'icon': 'directions_boat'},
            {'key': 'HONEYMOON', 'label': 'Honeymoon Escapes', 'icon': 'favorite'},
            {'key': 'ADVENTURE', 'label': 'Wildlife & Trekking', 'icon': 'hiking'},
            {'key': 'AYURVEDA', 'label': 'Ayurvedic Wellness', 'icon': 'spa'},
            {'key': 'CULTURE', 'label': 'Heritage & Arts', 'icon': 'theater_comedy'},
            {'key': 'FAMILY', 'label': 'Family Circuits', 'icon': 'groups'},
        ]
        return Response(categories_data)

    @action(detail=True, methods=['post'])
    def inquire(self, request, slug=None):
        package = self.get_object()
        serializer = PackageInquirySerializer(data=request.data)
        if serializer.is_valid():
            inquiry = serializer.save(package=package)

            # Build WhatsApp redirect message
            phone_clean = package.operator_whatsapp.replace('+', '').replace('-', '').replace(' ', '')
            msg_text = (
                f"Hello {package.operator_name}, I found your package '{package.title}' on KeraLink! "
                f"I would like to inquire for {inquiry.guests_count} guests starting {inquiry.travel_date or 'soon'}. "
                f"My name is {inquiry.traveler_name}."
            )
            whatsapp_url = f"https://wa.me/{phone_clean}?text={urllib.parse.quote(msg_text)}"

            return Response({
                'success': True,
                'inquiry_id': str(inquiry.id),
                'operator_name': package.operator_name,
                'operator_phone': package.operator_phone,
                'whatsapp_url': whatsapp_url,
                'message': 'Inquiry submitted successfully. Connecting you to the tour operator.'
            }, status=status.HTTP_201_CREATED)

        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    @action(detail=True, methods=['post'])
    def whatsapp_click(self, request, slug=None):
        package = self.get_object()
        phone_clean = package.operator_whatsapp.replace('+', '').replace('-', '').replace(' ', '')
        guests = request.data.get('guests_count', 2)
        date = request.data.get('travel_date', '')
        
        msg_text = (
            f"Hello {package.operator_name}, I am browsing your package '{package.title}' on KeraLink "
            f"({package.duration_days}D/{package.duration_nights}N - Rs.{int(package.price_per_person)}/person). "
            f"Please share availability and customized quote for {guests} travelers."
        )
        whatsapp_url = f"https://wa.me/{phone_clean}?text={urllib.parse.quote(msg_text)}"

        # Record lead click
        PackageInquiry.objects.create(
            package=package,
            traveler_name=request.data.get('traveler_name', 'App Traveler'),
            traveler_phone=request.data.get('traveler_phone', ''),
            guests_count=guests,
            travel_date=date,
            channel='WHATSAPP',
            message='Direct WhatsApp lead click'
        )

        return Response({
            'whatsapp_url': whatsapp_url,
            'operator_name': package.operator_name,
            'operator_phone': package.operator_phone,
        })
