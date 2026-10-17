"use client";
import { useEffect, useMemo, useRef, useState } from 'react';
import { useChat } from '@ai-sdk/react';
import { DefaultChatTransport } from 'ai';
import { Bot, X, Send, Trash2 } from 'lucide-react';
import { Button } from '@/components/ui/Button';
import { Input } from '@/components/ui/Input';
import { createClient } from '@/utils/supabase/client';

export function AidaChatWidget() {
  const [isOpen, setIsOpen] = useState(false);
  const [input, setInput] = useState('');
  const transport = useMemo(() => new DefaultChatTransport({ api: '/api/chat' }), []);
  const { messages, sendMessage, setMessages, status, error, stop, clearError } = useChat({ transport });
  const identity = useRef<string | null>(null);
  const busy = status === 'streaming' || status === 'submitted';
  useEffect(() => {
    // Histories are held only in memory and discarded on identity changes.
    for (const key of ['aida_chat_history', 'activ_avatar', 'activ_orientation_results']) localStorage.removeItem(key);
    const { data: { subscription } } = createClient().auth.onAuthStateChange((_event, session) => {
      const next = session?.user.id ?? null;
      if (identity.current !== next) { void stop(); setMessages([]); setInput(''); clearError(); }
      identity.current = next;
    });
    return () => subscription.unsubscribe();
  }, [stop, setMessages, clearError]);

  useEffect(() => {
    const handleOpenChat = (event: Event) => {
      const customEvent = event as CustomEvent<{ prompt?: string }>;
      setIsOpen(true);
      if (customEvent.detail?.prompt) {
        clearError();
        void sendMessage({ text: customEvent.detail.prompt });
      }
    };

    window.addEventListener('open-aida-chat', handleOpenChat);
    return () => window.removeEventListener('open-aida-chat', handleOpenChat);
  }, [sendMessage, clearError]);
  return <>
    <Button aria-label="Ouvrir AÏDA" onClick={() => setIsOpen(true)} className="fixed bottom-6 right-6 z-50"><Bot /></Button>
    {isOpen && <section aria-label="Conversation avec AÏDA" className="fixed bottom-0 right-0 md:bottom-6 md:right-6 z-50 flex flex-col w-full md:w-96 h-[70vh] bg-surface border border-border-strong rounded-md">
      <header className="p-4 flex items-center justify-between border-b border-border-soft">
        <h2 className="font-display font-bold">AÏDA</h2>
        <div className="flex gap-2">
          <Button aria-label="Effacer la conversation" disabled={busy} onClick={() => { setMessages([]); clearError(); }}><Trash2 size={18} /></Button>
          <Button aria-label="Fermer AÏDA" onClick={() => setIsOpen(false)}><X size={18} /></Button>
        </div>
      </header>
      <div aria-live="polite" className="flex-1 overflow-y-auto p-4 space-y-4">
        {!messages.length && <p>Bonjour ! Comment puis-je vous aider dans votre orientation ?</p>}
        {messages.map(message => <div key={message.id} className="border-b border-border-soft pb-3">
          <p className="text-xs font-bold">{message.role === 'user' ? 'Vous' : 'AÏDA'}</p>
          {message.parts.map((part, index) => part.type === 'text' ? <p key={index} className="whitespace-pre-wrap">{part.text}</p> : null)}
        </div>)}
        {busy && <p role="status">AÏDA prépare sa réponse…</p>}
        {error && <p role="alert" className="text-error">La réponse n’a pas pu être obtenue. Vérifiez votre connexion ou réessayez plus tard.</p>}
      </div>
      <form className="p-4 border-t border-border-soft flex gap-2" onSubmit={event => {
        event.preventDefault();
        if (!input.trim() || busy) return;
        clearError(); void sendMessage({ text: input.trim() }); setInput('');
      }}>
        <Input aria-label="Votre message" value={input} maxLength={6000} onChange={event => setInput(event.target.value)} disabled={busy} />
        <Button type="submit" aria-label="Envoyer" disabled={busy || !input.trim()}><Send size={18} /></Button>
      </form>
      <p className="px-4 pb-3 text-xs text-text-secondary">AÏDA peut se tromper. Vérifiez les informations importantes.</p>
    </section>}
  </>;
}
