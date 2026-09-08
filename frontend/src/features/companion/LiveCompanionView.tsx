import React from 'react';
import { useAppStore } from '../../stores/useAppStore';
import { httpAdapter } from '../../adapters/httpAdapter';
import { CompanionMessage } from '../../types/contracts';
import { Sparkles, Mic, Send, Umbrella, Utensils, MapPin, Clock, ArrowRight } from 'lucide-react';

export const LiveCompanionView: React.FC = () => {
  const { currentBooking, navigateTo, regenerateDay } = useAppStore();
  const [inputText, setInputText] = React.useState('');
  const [isListening, setIsListening] = React.useState(false);
  const [messages, setMessages] = React.useState<CompanionMessage[]>([
    {
      id: 'msg-init-1',
      sender: 'AI_COMPANION',
      text: 'Namaskaram, Sreerag! 🌴 I am your live KeraLink Companion. You are currently on **Day 2 (Munnar)**. How can I assist you right now?',
      timestamp: new Date().toISOString(),
      suggestedQuickReplies: [
        "What's near me?",
        "It's raining, what can we do?",
        'Find a good restaurant',
        'Change today plan',
      ],
    },
  ]);

  const messagesEndRef = React.useRef<HTMLDivElement>(null);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  React.useEffect(() => {
    scrollToBottom();
  }, [messages]);

  const handleSendMessage = async (textToSend?: string) => {
    const query = textToSend || inputText;
    if (!query.trim()) return;

    const userMsg: CompanionMessage = {
      id: 'usr-' + Date.now(),
      sender: 'USER',
      text: query,
      timestamp: new Date().toISOString(),
    };

    setMessages((prev) => [...prev, userMsg]);
    setInputText('');

    // Query backend companion assistant via live HTTP API
    const reply = await httpAdapter.sendCompanionMessage(query, 'munnar', 2);
    setMessages((prev) => [...prev, reply]);
  };

  const toggleMic = () => {
    if (!isListening) {
      setIsListening(true);
      setTimeout(() => {
        setIsListening(false);
        handleSendMessage("It's raining in Munnar, what can we do indoors?");
      }, 2000);
    } else {
      setIsListening(false);
    }
  };

  return (
    <div className="flex flex-col h-full bg-[#F7F3E8] text-[#1C231E]">
      {/* Top Companion Header */}
      <div className="p-4 bg-[#0F2823] text-[#F7F3E8] border-b border-[#D4AF37]/30 flex items-center justify-between z-10 shadow-md">
        <div className="flex items-center gap-2.5">
          <div className="w-9 h-9 rounded-full bg-gradient-to-tr from-[#144032] to-[#1A5340] border border-[#D4AF37]/40 flex items-center justify-center text-[#D4AF37] shadow-gold">
            <Sparkles className="w-4 h-4" />
          </div>
          <div>
            <h2 className="font-serif text-base font-bold flex items-center gap-1.5">
              <span>Trip Assistant</span>
              <span className="w-2 h-2 rounded-full bg-emerald-400 animate-pulse" />
            </h2>
            <p className="text-[10px] text-[#C5D8CD]">Live Context: Munnar Hills · 21°C</p>
          </div>
        </div>

        <button
          onClick={() => navigateTo('SAFETY')}
          className="px-2.5 py-1 rounded-xl bg-rose-900/60 border border-rose-500/40 text-rose-200 text-[10px] font-bold"
        >
          SOS / Safety
        </button>
      </div>

      {/* Messages Chat Stream */}
      <div className="flex-1 overflow-y-auto p-4 space-y-3">
        {messages.map((msg) => {
          const isUser = msg.sender === 'USER';
          return (
            <div
              key={msg.id}
              className={`flex flex-col ${isUser ? 'items-end' : 'items-start'} animate-in fade-in`}
            >
              <div
                className={`max-w-[85%] p-3.5 rounded-3xl text-xs leading-relaxed shadow-sm ${
                  isUser
                    ? 'bg-[#144032] text-white rounded-br-xs'
                    : 'bg-white text-gray-800 border border-[#E2D3B8] rounded-bl-xs'
                }`}
              >
                <div
                  dangerouslySetInnerHTML={{
                    __html: msg.text
                      .replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>')
                      .replace(/\n/g, '<br/>'),
                  }}
                />

                {/* Interactive Action Card Embedded in Response */}
                {msg.actionCard && (
                  <div className="mt-3 p-3 rounded-2xl bg-[#FAF5EA] border border-[#D4AF37]/40 shadow-sm text-left space-y-1.5">
                    <div className="flex items-center gap-1.5 text-[10px] font-bold text-[#144032] uppercase">
                      {msg.actionCard.type === 'RAIN_ALTERNATIVE' && <Umbrella className="w-3.5 h-3.5 text-blue-600" />}
                      {msg.actionCard.type === 'RESTAURANT_SUGGESTION' && <Utensils className="w-3.5 h-3.5 text-amber-600" />}
                      <span>{msg.actionCard.title}</span>
                    </div>
                    <p className="text-[11px] text-gray-600 font-medium">{msg.actionCard.description}</p>
                    <button
                      onClick={() => {
                        if (msg.actionCard?.type === 'RAIN_ALTERNATIVE') {
                          regenerateDay(2, 'RAIN_FRIENDLY');
                          navigateTo('ITINERARY');
                        } else {
                          navigateTo('ITINERARY');
                        }
                      }}
                      className="w-full mt-1 py-2 rounded-xl bg-[#144032] text-[#F7F3E8] text-[10px] font-bold shadow-sm flex items-center justify-center gap-1 hover:bg-[#10352A]"
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
                      className="px-2.5 py-1 rounded-full bg-white border border-[#E2D3B8] text-[10px] font-medium text-[#144032] hover:bg-[#144032] hover:text-[#D4AF37] hover:border-[#144032] transition-all shadow-xs"
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

      {/* Bottom Message Input Bar with Voice Simulation */}
      <div className="p-3 bg-white border-t border-[#E2D3B8] flex items-center gap-2">
        <button
          onClick={toggleMic}
          className={`w-10 h-10 rounded-2xl flex items-center justify-center transition-all ${
            isListening
              ? 'bg-rose-500 text-white animate-pulse'
              : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
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
          placeholder={isListening ? 'Listening to voice...' : 'Ask your Kerala AI Companion...'}
          className="flex-1 py-2.5 px-4 rounded-2xl bg-gray-50 border border-gray-200 text-xs focus:outline-none focus:ring-2 focus:ring-[#144032]"
        />

        <button
          onClick={() => handleSendMessage()}
          disabled={!inputText.trim()}
          className="w-10 h-10 rounded-2xl bg-[#144032] text-white flex items-center justify-center shadow-md disabled:opacity-40 hover:bg-[#10352A] transition-all"
        >
          <Send className="w-4 h-4" />
        </button>
      </div>
    </div>
  );
};
