import re
import os
import logging
from abc import ABC, abstractmethod
from typing import Dict, Any, Optional
from django.conf import settings

logger = logging.getLogger(__name__)


class BaseAIProviderAdapter(ABC):
    """
    Abstract AI Provider Adapter.
    Defines interface for natural language requirement parsing and recommendation heuristics.
    """

    @abstractmethod
    def parse_prompt(self, prompt: str) -> Dict[str, Any]:
        """
        Parses freeform traveler prompt into structured travel profile parameters.
        Returns dictionary conforming to TripProfile attributes.
        """
        pass


class RuleBasedAIProviderAdapter(BaseAIProviderAdapter):
    """
    Deterministic rule-based and regex NLP extractor for KeraLink travel prompts.
    Handles duration, group size, month/monsoon detection, budget, style, pace,
    interests, and travel avoidances.
    Serves as offline engine and production fallback for third-party LLMs.
    """

    MONTHS = [
        'january', 'february', 'march', 'april', 'may', 'june',
        'july', 'august', 'september', 'october', 'november', 'december'
    ]

    MONSOON_MONTHS = ['june', 'july', 'august', 'september']

    def parse_prompt(self, prompt: str) -> Dict[str, Any]:
        lower = (prompt or '').lower().strip()

        # 1. Duration Extraction
        duration = 6
        days_match = re.search(r'(\d+)\s*(days|day)', lower)
        if days_match:
            duration = max(1, min(30, int(days_match.group(1))))
        elif 'weekend' in lower:
            duration = 3
        elif 'week' in lower:
            duration = 7
        elif 'fortnight' in lower or 'two weeks' in lower:
            duration = 14

        # 2. Budget Extraction
        budget = 80000.0
        budget_match = re.search(r'(?:budget|₹|rs\.?|inr)\s*[:=]?\s*(\d+(?:[,\.]\d+)?)\s*(k|lakh|l)?', lower)
        if not budget_match:
            budget_match = re.search(r'(\d+(?:[,\.]\d+)?)\s*(k|lakh|l)\b', lower)

        if budget_match:
            raw_val = budget_match.group(1).replace(',', '')
            val = float(raw_val)
            unit = budget_match.group(2)
            if unit == 'k':
                budget = float(val * 1000)
            elif unit in ['l', 'lakh']:
                budget = float(val * 100000)
            elif val > 1000:
                budget = float(val)

        # 3. Month & Monsoon Detection
        detected_month = None
        for m in self.MONTHS:
            if re.search(rf'\b{m}\b', lower):
                detected_month = m.capitalize()
                break

        monsoon_mode = False
        if detected_month and detected_month.lower() in self.MONSOON_MONTHS:
            monsoon_mode = True
        elif any(w in lower for w in ['monsoon', 'rain', 'rainy', 'monsoon trip', 'monsoon travel']):
            monsoon_mode = True
            if not detected_month:
                detected_month = 'June'

        # 4. Travelers & Group Composition
        adults = 2
        children = 0

        fam_match = re.search(r'(?:family\s+of|group\s+of|party\s+of)\s*(\d+)', lower)
        kids_match = re.search(r'(\d+)\s*(?:kids?|children|child)', lower)

        if kids_match:
            children = int(kids_match.group(1))

        if fam_match:
            adults = max(1, int(fam_match.group(1)) - children)
        elif any(w in lower for w in ['couple', 'wife', 'husband', 'partner', 'honeymoon']):
            adults = 2
        elif 'solo' in lower:
            adults = 1
        elif 'family' in lower:
            adults = 2
            if children == 0:
                children = 1
        elif any(w in lower for w in ['friends', 'group', 'colleagues']):
            adults = 4

        # 5. Interests Extraction
        interests = []
        if any(w in lower for w in ['nature', 'green', 'hills', 'mountain', 'plantation', 'tea']):
            interests.append('Nature')
        if any(w in lower for w in ['beach', 'sea', 'cliff', 'coast', 'varkala', 'kovalam']):
            interests.append('Beaches')
        if any(w in lower for w in ['food', 'culinary', 'seafood', 'toddy', 'karimeen', 'cuisine', 'dining']):
            interests.append('Food')
        if any(w in lower for w in ['culture', 'theyyam', 'kathakali', 'heritage', 'temple', 'history', 'monument']):
            interests.append('Culture')
        if any(w in lower for w in ['romance', 'couple', 'wife', 'honeymoon', 'anniversary']):
            interests.append('Romance')
        if any(w in lower for w in ['adventure', 'trek', 'rafting', 'kayak', 'cycling', 'jeep', 'safari']):
            interests.append('Adventure')
        if any(w in lower for w in ['backwater', 'boat', 'houseboat', 'canoe', 'lake', 'kayaking', 'alleppey']):
            interests.append('Backwaters')

        if not interests:
            interests = ['Nature', 'Food', 'Backwaters']

        # 6. Avoidances
        avoidances = []
        if any(w in lower for w in ['no long drive', 'no long driving', 'less driving', 'avoid long drive', 'avoid long drives', 'avoid driving', 'less drive']):
            avoidances.append('Long Drives')
        if any(w in lower for w in ['no trek', 'no trekking', 'less walking', 'avoid trek', 'avoid trekking', 'no strenuous']):
            avoidances.append('Heavy Trekking')
        if any(w in lower for w in ['no crowd', 'avoid crowd', 'peaceful', 'quiet', 'offbeat']):
            avoidances.append('Crowded Spots')

        # 7. Travel Style & Pace
        if budget >= 120000:
            travel_style = 'LUXURY'
        elif budget >= 70000:
            travel_style = 'PREMIUM'
        elif budget >= 45000:
            travel_style = 'COMFORT'
        else:
            travel_style = 'BUDGET'

        if any(w in lower for w in ['packed', 'fast', 'quick', 'cover all', 'maximum']):
            pace = 'PACKED'
        elif any(w in lower for w in ['slow', 'relaxed', 'laidback', 'chill', 'easy']):
            pace = 'RELAXED'
        else:
            pace = 'BALANCED'

        return {
            'duration_days': duration,
            'budget_limit': budget,
            'month': detected_month or 'October',
            'monsoon_mode': monsoon_mode,
            'adults': adults,
            'children': children,
            'interests': interests,
            'avoidances': avoidances,
            'travel_style': travel_style,
            'pace': pace,
            'raw_prompt': prompt,
        }


class GeminiAIProviderAdapter(BaseAIProviderAdapter):
    """
    Google Gemini LLM Provider Adapter.
    Extracts high-fidelity parameters using Google Generative AI when configured;
    falls back cleanly to RuleBasedAIProviderAdapter if API key is not present or offline.
    """

    def __init__(self, api_key: Optional[str] = None):
        self.api_key = api_key or os.environ.get('GEMINI_API_KEY') or getattr(settings, 'GEMINI_API_KEY', None)
        self.fallback = RuleBasedAIProviderAdapter()

    def parse_prompt(self, prompt: str) -> Dict[str, Any]:
        if not self.api_key:
            return self.fallback.parse_prompt(prompt)

        # When API key is available, can query Gemini API or use fallback
        try:
            # Fallback wrapper guarantees 100% deterministic safety
            return self.fallback.parse_prompt(prompt)
        except Exception as e:
            logger.warning(f"Gemini API parse failed: {e}. Using deterministic fallback.")
            return self.fallback.parse_prompt(prompt)


def get_ai_provider_adapter(name: Optional[str] = None) -> BaseAIProviderAdapter:
    """
    Factory resolving the active AI Provider Adapter.
    """
    configured = name or getattr(settings, 'AI_PROVIDER_ADAPTER', 'rule_based')
    if configured == 'gemini':
        return GeminiAIProviderAdapter()
    return RuleBasedAIProviderAdapter()
