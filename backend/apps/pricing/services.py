from decimal import Decimal
from typing import List, Dict, Any

class AuthoritativePricingEngine:
    """
    Authoritative server-side pricing engine for KeraLink.
    Computes real stay rates, vehicle tariffs, experience tickets,
    applicable GST taxes, platform fees, and seasonal discounts.
    """

    GST_TAX_RATE = Decimal('0.05')      # 5% Tourism GST
    PLATFORM_FEE_RATE = Decimal('0.02') # 2% Platform & Insurance

    @classmethod
    def calculate_itinerary_price(
        cls,
        days_count: int,
        travelers_count: int,
        stays: List[Dict[str, Any]],
        experiences: List[Dict[str, Any]],
        transport_mode: str = 'SEDAN',
        promo_code: str = None
    ) -> Dict[str, Any]:
        # 1. Stays Calculation
        stays_total = Decimal('0.00')
        for stay in stays:
            nightly_rate = Decimal(str(stay.get('base_price_per_night', 0)))
            stays_total += nightly_rate

        # 2. Transport Tariff (Sedan: ₹2,650/day, SUV: ₹3,800/day, EV: ₹3,200/day)
        tariff_per_day = {
            'SEDAN': Decimal('2650.00'),
            'SUV': Decimal('3800.00'),
            'ELECTRIC_VEHICLE': Decimal('3200.00'),
            'TEMPO_TRAVELLER': Decimal('5200.00'),
        }.get(transport_mode, Decimal('2650.00'))
        transport_total = tariff_per_day * Decimal(str(days_count))

        # 3. Experiences Calculation
        experiences_total = Decimal('0.00')
        for exp in experiences:
            unit_price = Decimal(str(exp.get('price_per_person', 0)))
            experiences_total += unit_price * Decimal(str(travelers_count))

        # 4. Meals Estimate (₹600/person/day for curated dining)
        meals_estimate = Decimal('600.00') * Decimal(str(travelers_count)) * Decimal(str(days_count))

        # Subtotal
        subtotal = stays_total + transport_total + experiences_total + meals_estimate

        # 5. Taxes & Fees
        taxes = subtotal * cls.GST_TAX_RATE
        platform_fees = subtotal * cls.PLATFORM_FEE_RATE
        taxes_and_fees = taxes + platform_fees

        # 6. Promo / Seasonal Discounts
        discount = Decimal('0.00')
        if promo_code == 'KERALINK2026':
            discount = subtotal * Decimal('0.05')
        elif days_count >= 5:
            # Long-stay bonus discount
            discount = subtotal * Decimal('0.03')

        total = subtotal + taxes_and_fees - discount

        return {
            'subtotal': float(subtotal),
            'stays_total': float(stays_total),
            'transport_total': float(transport_total),
            'experiences_total': float(experiences_total),
            'meals_estimate': float(meals_estimate),
            'gst_amount': float(taxes),
            'platform_fee': float(platform_fees),
            'taxes_and_fees': float(taxes_and_fees),
            'discount': float(discount),
            'total': float(total),
            'price_per_person': float(total / Decimal(str(travelers_count))),
        }
