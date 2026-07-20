'use client';
import { useState, useRef, useEffect } from 'react';
import { useAuth } from '@/lib/auth';
import { api } from '@/lib/api';
import type { AIDAMessage } from '@/lib/types';
import { Sparkles, Send, Bot, User, Loader2 } from 'lucide-react';
import { useTheme } from '@/lib/theme';

export default function AIDAPage() {
  const { user, loading: authLoading } = useAuth();
  const { t } = useTheme();
  const [messages, setMessages] = useState<AIDAMessage[]>([
    { id: 'intro', role: 'assistant', content: t('Bonjour ! Je suis AÏDA, ton assistante d\'orientation. Pose-moi toutes tes questions sur les métiers, les études ou ton parcours scolaire !') }
  ]);
  const [input, setInput] = useState('');
  const [sending, setSending] = useState(false);
  const [conversationId, setConversationId] = useState<string | null>(null);
  const bottomRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

  const send = async () => {
    const text = input.trim();
    if (!text || sending) return;
    setInput('');

    const userMsg: AIDAMessage = { id: Date.now().toString(), role: 'user', content: text };
    setMessages(prev => [...prev, userMsg]);
    setSending(true);

    try {
      const res = await api.post<{ reply: string; session_id?: string }>('/chat/message', {
        message: text,
        session_id: conversationId,
      });
      setConversationId(res.session_id ?? null);
      const botMsg: AIDAMessage = { id: (Date.now() + 1).toString(), role: 'assistant', content: res.reply };
      setMessages(prev => [...prev, botMsg]);
    } catch {
      setMessages(prev => [...prev, {
        id: (Date.now() + 1).toString(), role: 'assistant',
        content: t('Désolée, je n\'ai pas pu répondre. Réessaie !')
      }]);
    }
    setSending(false);
  };

  const suggestions = [
    t('Quels métiers sont faits pour moi ?'),
    t('Comment choisir ma filière ?'),
    t('Quelles sont les écoles d\'informatique ?'),
    t('Faut-il faire un BAC général ou technologique ?'),
  ];

  if (authLoading) return <div className="min-h-[80vh] flex items-center justify-center"><div className="animate-spin w-8 h-8 border-2 border-brand-primary border-t-transparent rounded-full" /></div>;
  if (!user) return (
    <div className="animate-fade-in min-h-[80vh] flex flex-col items-center justify-center px-6 text-center">
      <div className="w-20 h-20 rounded-2xl bg-gradient-to-br from-brand-secondary to-purple-500 flex items-center justify-center mb-6 shadow-lg">
        <Bot size={40} className="text-white" />
      </div>
      <h1 className="text-2xl font-bold text-brand-text-primary mb-3">{t('Connecte-toi pour discuter avec AÏDA')}</h1>
      <p className="text-brand-text-secondary text-sm max-w-sm mb-8">{t('Connecte-toi pour bénéficier des conseils personnalisés de ton assistante IA')}</p>
      <div className="flex flex-col sm:flex-row gap-3 w-full max-w-xs">
        <a href="/login" className="flex-1 px-6 py-3 rounded-xl bg-gradient-primary text-white font-semibold text-sm text-center hover:opacity-90 transition-opacity shadow-md">{t('Se connecter')}</a>
        <a href="/register" className="flex-1 px-6 py-3 rounded-xl border border-brand-border text-brand-text-primary font-semibold text-sm text-center hover:border-brand-primary hover:text-brand-primary transition-all">{t('Créer un compte')}</a>
      </div>
    </div>
  );

  return (
    <div className="animate-fade-in flex flex-col h-[calc(100vh-8rem)] pb-4">
      {/* Header */}
      <div className="relative overflow-hidden rounded-2xl bg-gradient-to-br from-brand-secondary via-brand-secondary to-[#9333EA] p-4 mb-4 flex-shrink-0">
        <div className="absolute -top-6 -right-6 w-36 h-36 rounded-full bg-white/5" />
        <div className="relative z-10 flex items-center gap-3">
          <div className="w-10 h-10 rounded-xl bg-white/15 flex items-center justify-center border border-white/20">
            <Sparkles size={18} className="text-white" />
          </div>
          <div>
            <h1 className="text-white font-bold text-lg">{t('AÏDA')}</h1>
            <p className="text-white/60 text-xs">{t("Ton assistante d'orientation IA")}</p>
          </div>
        </div>
      </div>

      {/* Chat area */}
      <div className="flex-1 overflow-y-auto space-y-3 pr-1 scroll-smooth" style={{ scrollBehavior: 'smooth' }}>
        {messages.map(msg => (
          <div key={msg.id} className={`flex gap-2.5 ${msg.role === 'user' ? 'justify-end' : ''}`}>
            {msg.role === 'assistant' && (
              <div className="w-8 h-8 rounded-lg bg-gradient-to-br from-brand-secondary to-purple-500 flex items-center justify-center flex-shrink-0 mt-0.5">
                <Sparkles size={14} className="text-white" />
              </div>
            )}
            <div className={`max-w-[85%] p-3 rounded-2xl text-sm leading-relaxed ${
              msg.role === 'user'
                ? 'bg-brand-primary text-white rounded-tr-md'
                : 'bg-white border border-brand-border text-brand-text-primary rounded-tl-md shadow-sm'
            }`}>
              {msg.content}
            </div>
            {msg.role === 'user' && (
              <div className="w-8 h-8 rounded-lg bg-brand-primary/10 flex items-center justify-center flex-shrink-0 mt-0.5">
                <User size={14} className="text-brand-primary" />
              </div>
            )}
          </div>
        ))}

        {sending && (
          <div className="flex gap-2.5">
            <div className="w-8 h-8 rounded-lg bg-gradient-to-br from-brand-secondary to-purple-500 flex items-center justify-center flex-shrink-0">
              <Bot size={14} className="text-white" />
            </div>
            <div className="bg-white border border-brand-border rounded-2xl rounded-tl-md p-3 shadow-sm">
              <div className="flex gap-1">
                <div className="w-2 h-2 rounded-full bg-brand-primary animate-bounce" style={{ animationDelay: '0ms' }} />
                <div className="w-2 h-2 rounded-full bg-brand-primary animate-bounce" style={{ animationDelay: '150ms' }} />
                <div className="w-2 h-2 rounded-full bg-brand-primary animate-bounce" style={{ animationDelay: '300ms' }} />
              </div>
            </div>
          </div>
        )}
        <div ref={bottomRef} />
      </div>

      {/* Suggestions (only when no history) */}
      {messages.length === 1 && !sending && (
        <div className="flex-shrink-0 mb-3">
          <p className="text-[10px] font-semibold text-brand-text-tertiary uppercase tracking-wide mb-2">{t('Suggestions')}</p>
          <div className="flex flex-wrap gap-2">
            {suggestions.map(s => (
              <button key={s} onClick={() => { setInput(s); }}
                className="px-3 py-1.5 rounded-full bg-white border border-brand-border text-xs font-medium text-brand-text-secondary hover:border-brand-primary hover:text-brand-primary transition-all whitespace-nowrap">
                {s}
              </button>
            ))}
          </div>
        </div>
      )}

      {/* Input */}
      <div className="flex-shrink-0 flex items-center gap-2 mt-2 bg-white rounded-2xl border border-brand-border p-2 shadow-card">
        <input type="text" placeholder={t('Pose ta question...')}
          value={input} onChange={e => setInput(e.target.value)}
          onKeyDown={e => e.key === 'Enter' && send()}
          className="flex-1 bg-transparent outline-none text-sm px-2 text-brand-text-primary placeholder:text-brand-text-tertiary" />
        <button onClick={send} disabled={!input.trim() || sending}
          className="w-9 h-9 rounded-xl bg-gradient-primary flex items-center justify-center disabled:opacity-40 transition-opacity shadow-sm">
          {sending ? <Loader2 size={16} className="animate-spin text-white" /> : <Send size={15} className="text-white" />}
        </button>
      </div>
    </div>
  );
}
