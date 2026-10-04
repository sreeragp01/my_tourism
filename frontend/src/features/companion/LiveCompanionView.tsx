import React from 'react';
import { useAppStore } from '../../stores/useAppStore';
import { httpAdapter } from '../../adapters/httpAdapter';
import { CompanionMessage } from '../../types/contracts';
import { Sparkles, Mic, Send, Umbrella, Utensils, MapPin, ArrowRight, ShieldAlert, Calendar, CheckCircle2 } from 'lucide-react';

const KERALA_DESTINATIONS: Record<string, { slug: string; name: string; temp: string; condition: string }> = {
  'kochi': { slug: 'kochi', name: 'Fort Kochi', temp: '30°C', condition: 'Coastal Breeze' },
  'fort kochi': { slug: 'kochi', name: 'Fort Kochi', temp: '30°C', condition: 'Coastal Breeze' },
  'cochin': { slug: 'kochi', name: 'Fort Kochi', temp: '30°C', condition: 'Coastal Breeze' },
  'munnar': { slug: 'munnar', name: 'Munnar Hills', temp: '19°C', condition: 'Mist Showers' },
  'thekkady': { slug: 'thekkady', name: 'Thekkady', temp: '23°C', condition: 'Crisp Mountain' },
  'periyar': { slug: 'thekkady', name: 'Thekkady', temp: '23°C', condition: 'Crisp Mountain' },
  'alappuzha': { slug: 'alappuzha', name: 'Alappuzha', temp: '28°C', condition: 'Backwater Breeze' },
  'alleppey': { slug: 'alappuzha', name: 'Alappuzha', temp: '28°C', condition: 'Backwater Breeze' },
  'kumarakom': { slug: 'kumarakom', name: 'Kumarakom', temp: '28°C', condition: 'Lakeside Sun' },
  'wayanad': { slug: 'wayanad', name: 'Wayanad', temp: '22°C', condition: 'Forest Mist' },
  'varkala': { slug: 'varkala', name: 'Varkala Cliff', temp: '29°C', condition: 'Sunny Ocean' },
  'kovalam': { slug: 'kovalam', name: 'Kovalam Beach', temp: '30°C', condition: 'Coastal Waves' },
  'athirappilly': { slug: 'athirappilly', name: 'Athirappilly', temp: '27°C', condition: 'Waterfall Mist' },
};

export const LiveCompanionView: React.FC = () => {
  const { currentBooking, currentPlan, selectedDayNumber, setSelectedDayNumber, navigateTo, regenerateDay } = useAppStore();

  const itineraryDays = currentPlan?.currentVersion?.itineraryDays || [];
  const hasBooking = Boolean(currentBooking);

  // Compute active initial destination and day number
  const activeDay = itineraryDays.find((d) => d.dayNumber === selectedDayNumber) || itineraryDays[0];
  const initialDestName = activeDay?.destinationName || (hasBooking ? 'Fort Kochi' : 'Munnar');
  const initialDestSlug = (activeDay?.destinationId || (hasBooking ? 'kochi' : 'munnar')).toLowerCase();

  const [activeDestination, setActiveDestination] = React.useState<string>(initialDestName);
  const [activeSlug, setActiveSlug] = React.useState<string>(initialDestSlug);
  const [activeDayNumber, setActiveDayNumber] = React.useState<number>(activeDay?.dayNumber || 1);

  const [inputText, setInputText] = React.useState('');
  const [isListening, setIsListening] = React.useState(false);

  // Generate initial welcome message based on booking status
  const [messages, setMessages] = React.useState<CompanionMessage[]>(() => {
    if (currentBooking) {
      return [
        {
          id: 'msg-init-booking',
          sender: 'AI_COMPANION',
          text: `Namaskaram, **${currentBooking.primaryGuestName || 'Traveler'}**! 🌴 I am your live KeraLink Companion for your confirmed booking **#${currentBooking.bookingReference}** (*${currentBooking.tripTitle}*).\n\n` +
            `You are currently on **Day ${activeDay?.dayNumber || 1} (${initialDestName})**. Chauffeur Rajesh Kumar is on standby, and your 24/7 Kerala Tourist Police safety net is linked.\n\n` +
            `How can I assist your journey in ${initialDestName} today?`,
          timestamp: new Date().toISOString(),
          suggestedQuickReplies: [
            `What's the weather in ${initialDestName}?`,
            `Top local restaurants in ${initialDestName}`,
            'Contact Chauffeur Rajesh',
            'Show my Boarding Pass',
          ],
        },
      ];
    }

    if (currentPlan) {
      return [
        {
          id: 'msg-init-plan',
          sender: 'AI_COMPANION',
          text: `Namaskaram! 🌴 I am your live KeraLink Companion for your **${currentPlan.currentVersion.itineraryDays.length}-Day Kerala Itinerary**.\n\n` +
            `We are viewing **Day ${activeDay?.dayNumber || 1}: ${initialDestName}**. Tap any destination above or ask me about weather, traditional cuisine, or travel times.`,
          timestamp: new Date().toISOString(),
          suggestedQuickReplies: [
            `Weather in ${initialDestName}`,
            `What to do in ${initialDestName}?`,
            'Best Sadya restaurants',
            'Lock in this itinerary',
          ],
        },
      ];
    }

    return [
      {
        id: 'msg-init-general',
        sender: 'AI_COMPANION',
        text: `Namaskaram! 🌴 I am your live KeraLink AI Travel Companion.\n\n` +
          `Ask me anything about exploring Kerala—live monsoon weather radar across Kochi, Munnar, Thekkady, or Alappuzha, authentic dining, houseboat cruises, or chauffeur guidance. Which destination are you exploring today?`,
        timestamp: new Date().toISOString(),
        suggestedQuickReplies: [
          'Weather in Munnar vs Kochi',
          'Best houseboat in Alappuzha',
          'Periyar Safari in Thekkady',
          'Seafood spots in Fort Kochi',
        ],
      },
    ];
  });

  const messagesEndRef = React.useRef<HTMLDivElement>(null);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  React.useEffect(() => {
    scrollToBottom();
  }, [messages]);

  // Sync state when day is picked
  const handleSelectDay = (dayNum: number, destName: string, destId?: string) => {
    setActiveDayNumber(dayNum);
    setActiveDestination(destName);
    const slug = (destId || destName).toLowerCase().replace(/[^a-z0-9]/g, '');
    setActiveSlug(slug);
    setSelectedDayNumber(dayNum);

    const switchMsg: CompanionMessage = {
      id: 'switch-' + Date.now(),
      sender: 'USER',
      text: `Switched context to Day ${dayNum}: ${destName}`,
      timestamp: new Date().toISOString(),
    };

    setMessages((prev) => [...prev, switchMsg]);
    handleSendMessage(`Tell me what's special about Day ${dayNum} in ${destName}, and check the local weather.`);
  };

  const handleSendMessage = async (textToSend?: string) => {
    const query = textToSend || inputText;
    if (!query.trim()) return;

    const lowerQuery = query.toLowerCase();

    // Check if user's question mentions a specific Kerala destination
    let resolvedSlug = activeSlug;
    let resolvedName = activeDestination;
    for (const [kw, info] of Object.entries(KERALA_DESTINATIONS)) {
      if (lowerQuery.includes(kw)) {
        resolvedSlug = info.slug;
        resolvedName = info.name;
        setActiveDestination(info.name);
        setActiveSlug(info.slug);
        break;
      }
    }

    const userMsg: CompanionMessage = {
      id: 'usr-' + Date.now(),
      sender: 'USER',
      text: query,
      timestamp: new Date().toISOString(),
    };

    setMessages((prev) => [...prev, userMsg]);
    setInputText('');

    // Query backend companion with dynamic destination & active booking reference
    const reply = await httpAdapter.sendCompanionMessage(
      query,
      resolvedSlug,
      activeDayNumber,
      currentBooking?.bookingReference
    );

    setMessages((prev) => [...prev, reply]);
  };

  const toggleMic = () => {
    if (!isListening) {
      setIsListening(true);
      setTimeout(() => {
        setIsListening(false);
        handleSendMessage(`What's the live weather and rain advisory in ${activeDestination}?`);
      }, 2000);
    } else {
      setIsListening(false);
    }
  };

  const weatherMeta = KERALA_DESTINATIONS[activeSlug] || {
    temp: '26°C',
    condition: 'Pleasant',
  };

  return (
    <div className="flex flex-col h-full bg-[#0C1B24] text-[#F8FAFC]">
      {/* Top Companion Header */}
      <div className="p-4 bg-[#132836] text-[#F8FAFC] border-b border-[#26475C] flex items-center justify-between z-10 shadow-lg">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-2xl bg-gradient-to-tr from-[#14B8A6]/20 to-[#1B3547] border border-[#14B8A6]/40 flex items-center justify-center text-[#14B8A6] shadow-sm">
            <Sparkles className="w-5 h-5" />
          </div>
          <div>
            <div className="flex items-center gap-2">
              <h2 className="font-serif text-base font-bold text-[#F8FAFC]">Live Trip Companion</h2>
              <span className="w-2 h-2 rounded-full bg-[#14B8A6] animate-pulse" />
            </div>
            <p className="text-[11px] text-[#94A3B8] flex items-center gap-1.5 mt-0.5">
              <span className="inline-block w-1.5 h-1.5 rounded-full bg-[#F59E0B]" />
              <span>{activeDestination}</span>
              <span>·</span>
              <span className="text-[#14B8A6] font-semibold">{weatherMeta.temp}</span>
              <span className="text-[#64748B]">({weatherMeta.condition})</span>
              {hasBooking && (
                <>
                  <span>·</span>
                  <span className="text-[#F59E0B] font-mono text-[10px]">Pass #{currentBooking?.bookingReference}</span>
                </>
              )}
            </p>
          </div>
        </div>

        <div className="flex items-center gap-2">
          {hasBooking && (
            <button
              onClick={() => navigateTo('MY_TRIPS')}
              className="px-2.5 py-1.5 rounded-xl bg-[#1B3547] border border-[#14B8A6]/40 text-[#14B8A6] text-[10px] font-bold hover:bg-[#14B8A6] hover:text-[#0C1B24] transition-all flex items-center gap-1"
            >
              <CheckCircle2 className="w-3 h-3" />
              <span>Confirmed Pass</span>
            </button>
          )}

          <button
            onClick={() => navigateTo('SAFETY')}
            className="px-2.5 py-1.5 rounded-xl bg-[#EF4444]/20 border border-[#EF4444]/40 text-[#EF4444] text-[10px] font-bold hover:bg-[#EF4444] hover:text-white transition-all flex items-center gap-1"
          >
            <ShieldAlert className="w-3 h-3" />
            <span>SOS</span>
          </button>
        </div>
      </div>

      {/* Itinerary Day & Destination Quick Pills Bar */}
      {itineraryDays.length > 0 && (
        <div className="flex items-center gap-1.5 px-3 py-2 bg-[#10222E] border-b border-[#26475C] overflow-x-auto no-scrollbar">
          <span className="text-[10px] uppercase font-bold text-[#64748B] tracking-wider shrink-0 pl-1 pr-2">
            Trip Stops:
          </span>
          {itineraryDays.map((d) => {
            const isSelected = d.dayNumber === activeDayNumber;
            return (
              <button
                key={d.dayNumber}
                onClick={() => handleSelectDay(d.dayNumber, d.destinationName, d.destinationId)}
                className={`px-3 py-1 rounded-xl text-[11px] whitespace-nowrap transition-all font-medium flex items-center gap-1 ${
                  isSelected
                    ? 'bg-[#14B8A6] text-[#0C1B24] font-bold shadow-md'
                    : 'bg-[#1B3547] text-[#94A3B8] border border-[#26475C] hover:text-[#F8FAFC]'
                }`}
              >
                <MapPin className="w-3 h-3" />
                <span>Day {d.dayNumber}: {d.destinationName}</span>
              </button>
            );
          })}
        </div>
      )}

      {/* Quick Destination Switcher if no multi-day itinerary */}
      {itineraryDays.length === 0 && (
        <div className="flex items-center gap-1.5 px-3 py-2 bg-[#10222E] border-b border-[#26475C] overflow-x-auto no-scrollbar">
          <span className="text-[10px] uppercase font-bold text-[#64748B] tracking-wider shrink-0 pl-1 pr-1">
            Quick Ask:
          </span>
          {['Fort Kochi', 'Munnar', 'Thekkady', 'Alappuzha', 'Wayanad', 'Varkala'].map((dest) => {
            const isSelected = activeDestination.toLowerCase().includes(dest.toLowerCase().split(' ')[0]);
            return (
              <button
                key={dest}
                onClick={() => {
                  setActiveDestination(dest);
                  const slug = dest.toLowerCase().replace(/[^a-z0-9]/g, '');
                  setActiveSlug(slug);
                  handleSendMessage(`What are the must-see highlights and current weather in ${dest}?`);
                }}
                className={`px-2.5 py-1 rounded-xl text-[11px] whitespace-nowrap transition-all font-medium flex items-center gap-1 ${
                  isSelected
                    ? 'bg-[#14B8A6] text-[#0C1B24] font-bold shadow-sm'
                    : 'bg-[#1B3547] text-[#94A3B8] border border-[#26475C] hover:text-[#F8FAFC]'
                }`}
              >
                <span>{dest}</span>
              </button>
            );
          })}
        </div>
      )}

      {/* Messages Chat Stream */}
      <div className="flex-1 overflow-y-auto p-4 space-y-3">
        {messages.map((msg) => {
          const isUser = msg.sender === 'USER';
          return (
            <div
              key={msg.id}
              className={`flex flex-col ${isUser ? 'items-end' : 'items-start'} animate-in fade-in duration-200`}
            >
              <div
                className={`max-w-[85%] p-3.5 rounded-2xl text-xs leading-relaxed shadow-sm ${
                  isUser
                    ? 'bg-[#14B8A6] text-[#0C1B24] font-medium rounded-br-none'
                    : 'bg-[#132836] text-[#F8FAFC] border border-[#26475C] rounded-bl-none'
                }`}
              >
                <div
                  dangerouslySetInnerHTML={{
                    __html: msg.text
                      .replace(/\*\*(.*?)\*\*/g, '<strong class="text-[#F59E0B] font-semibold">$1</strong>')
                      .replace(/\n/g, '<br/>'),
                  }}
                />

                {/* Interactive Action Card Embedded in Response */}
                {msg.actionCard && (
                  <div className="mt-3 p-3 rounded-xl bg-[#1B3547] border border-[#F59E0B]/40 shadow-sm text-left space-y-1.5">
                    <div className="flex items-center gap-1.5 text-[10px] font-bold text-[#F59E0B] uppercase">
                      {msg.actionCard.type === 'RAIN_ALTERNATIVE' && <Umbrella className="w-3.5 h-3.5 text-[#38BDF8]" />}
                      {msg.actionCard.type === 'RESTAURANT_SUGGESTION' && <Utensils className="w-3.5 h-3.5 text-[#F59E0B]" />}
                      <span>{msg.actionCard.title}</span>
                    </div>
                    <p className="text-[11px] text-[#94A3B8] font-medium">{msg.actionCard.description}</p>
                    <button
                      onClick={() => {
                        if (msg.actionCard?.type === 'RAIN_ALTERNATIVE') {
                          regenerateDay(activeDayNumber, 'RAIN_FRIENDLY');
                          navigateTo('ITINERARY');
                        } else {
                          navigateTo('ITINERARY');
                        }
                      }}
                      className="w-full mt-1.5 py-2 rounded-xl bg-[#14B8A6] text-[#0C1B24] text-[10px] font-bold shadow-sm flex items-center justify-center gap-1 hover:brightness-110 transition-all"
                    >
                      <span>{msg.actionCard.ctaLabel}</span>
                      <ArrowRight className="w-3 h-3" />
                    </button>
                  </div>
                )}
              </div>

              {/* Quick Reply Suggestions */}
              {msg.suggestedQuickReplies && (
                <div className="flex flex-wrap gap-1.5 mt-2 max-w-[88%]">
                  {msg.suggestedQuickReplies.map((qr) => (
                    <button
                      key={qr}
                      onClick={() => handleSendMessage(qr)}
                      className="px-2.5 py-1 rounded-full bg-[#1B3547] border border-[#26475C] text-[10px] font-medium text-[#14B8A6] hover:bg-[#14B8A6] hover:text-[#0C1B24] transition-all shadow-xs"
                    >
                      {qr}
                    </button>
                  ))}
                </div>
              )}
            </div>
          );
        })}
        <div ref={messagesEndRef} />
      </div>

      {/* Bottom Message Input Bar */}
      <div className="p-3 bg-[#132836] border-t border-[#26475C] flex items-center gap-2">
        <button
          onClick={toggleMic}
          className={`w-10 h-10 rounded-xl flex items-center justify-center transition-all ${
            isListening
              ? 'bg-[#EF4444] text-white animate-pulse'
              : 'bg-[#1B3547] text-[#94A3B8] hover:text-white border border-[#26475C]'
          }`}
          title="Simulate Voice Input"
        >
          <Mic className="w-4 h-4" />
        </button>

        <input
          type="text"
          value={inputText}
          onChange={(e) => setInputText(e.target.value)}
          onKeyDown={(e) => e.key === 'Enter' && handleSendMessage()}
          placeholder={isListening ? 'Listening to voice...' : `Ask anything about ${activeDestination} or Kerala...`}
          className="flex-1 py-2.5 px-4 rounded-xl bg-[#1B3547] border border-[#26475C] text-xs text-[#F8FAFC] placeholder-[#64748B] focus:outline-none focus:border-[#14B8A6]"
        />

        <button
          onClick={() => handleSendMessage()}
          disabled={!inputText.trim()}
          className="w-10 h-10 rounded-xl bg-[#14B8A6] text-[#0C1B24] flex items-center justify-center shadow-md disabled:opacity-40 hover:brightness-110 transition-all font-bold"
        >
          <Send className="w-4 h-4" />
        </button>
      </div>
    </div>
  );
};
