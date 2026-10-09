"use client";

import React, { useState, useRef, useEffect } from "react";
import { useChat } from "@ai-sdk/react";
import { type UIMessage as Message } from "ai";
import { Bot, X, Send, User as UserIcon, Loader2, Sparkles, Trash2 } from "lucide-react";
import { usePathname } from "next/navigation";

export function AidaChatWidget() {
  const pathname = usePathname();
  const [isOpen, setIsOpen] = useState(false);
  const [isLoaded, setIsLoaded] = useState(false);
  const [initialMsgs, setInitialMsgs] = useState<any[]>([]);
  const messagesEndRef = useRef<HTMLDivElement>(null);

  // Charger l'historique au montage
  useEffect(() => {
    const saved = localStorage.getItem('aida_chat_history');
    if (saved) {
      try {
        setInitialMsgs(JSON.parse(saved));
      } catch (e) {}
    } else {
      setInitialMsgs([{
        id: "welcome-message",
        role: "assistant",
        content: "Salut Kossi ! Je suis AÏDA, ton assistante d'orientation. Je vois que tu as bien avancé aujourd'hui ! Comment puis-je t'aider ?"
      }]);
    }
    setIsLoaded(true);
  }, []);
  
  // Gestion de l'input local car supprimé dans la v7
  const [input, setInput] = useState("");
  
  const { messages, setMessages, sendMessage, status } = useChat({ /* @ts-ignore */
    api: "/api/chat",
    initialMessages: initialMsgs,
    body: {
      userContext: {
        name: "Kossi Agbeko",
        school: "ESIG Global Success",
        level: "Master 1 - Informatique",
        currentRoute: pathname, // AÏDA sait exactement sur quelle page est l'étudiant !
        stats: "Niveau 4, 1250 Cristaux XP",
        achievements: "Leçon 'L'art de l'écoute active' terminée avec succès."
      }
    }
  });

  const isLoading = status === "streaming" || status === "submitted";

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!input.trim()) return;
    sendMessage({ role: "user", content: input } as any);
    setInput("");
  };

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setInput(e.target.value);
  };

  // Sauvegarder l'historique à chaque changement de message
  useEffect(() => {
    if (isLoaded && messages.length > 0) {
      localStorage.setItem('aida_chat_history', JSON.stringify(messages));
    }
  }, [messages, isLoaded]);

  // Vider la mémoire
  const clearMemory = () => {
    if (window.confirm("Voulez-vous effacer la mémoire d'AÏDA ?")) {
      localStorage.removeItem('aida_chat_history');
      // @ts-ignore
      setMessages([{
        id: "welcome-message",
        role: "assistant",
        content: "Mémoire effacée ! Repartons à zéro. Comment puis-je t'aider ?"
      }]);
    }
  };

  // Auto-scroll to bottom
  useEffect(() => {
    if (messagesEndRef.current) {
      messagesEndRef.current.scrollIntoView({ behavior: "smooth" });
    }
  }, [messages, isOpen]);

  if (!isLoaded) return null; // Ne pas afficher tant que l'historique n'est pas chargé

  return (
    <>
      {/* FLOATING BUTTON */}
      <button
        onClick={() => setIsOpen(true)}
        className={`fixed bottom-6 right-6 md:bottom-8 md:right-8 z-50 w-14 h-14 bg-primary text-white rounded-full shadow-xl flex items-center justify-center hover:scale-110 transition-transform ${isOpen ? "hidden" : "flex"}`}
      >
        <Sparkles className="w-6 h-6" />
      </button>

      {/* CHAT WINDOW */}
      {isOpen && (
        <div className="fixed bottom-0 right-0 md:bottom-8 md:right-8 z-50 w-full md:w-[400px] h-[80vh] md:h-[600px] bg-surface md:rounded-3xl shadow-2xl flex flex-col border border-border-soft overflow-hidden animate-fade-in sm:max-h-[90vh]">
          
          {/* HEADER */}
          <div className="bg-gradient-to-r from-primary to-blue-500 p-4 flex items-center justify-between text-white shrink-0">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 bg-white/20 rounded-full flex items-center justify-center backdrop-blur-sm">
                <Bot className="w-6 h-6" />
              </div>
              <div>
                <h3 className="font-display font-bold">AÏDA</h3>
                <p className="text-xs text-white/80">Ton IA d'orientation</p>
              </div>
            </div>
            <div className="flex items-center gap-2">
              <button onClick={clearMemory} title="Effacer la mémoire" className="p-2 hover:bg-white/20 rounded-full transition-colors">
                <Trash2 className="w-4 h-4" />
              </button>
              <button onClick={() => setIsOpen(false)} className="p-2 hover:bg-white/20 rounded-full transition-colors">
                <X className="w-5 h-5" />
              </button>
            </div>
          </div>

          {/* MESSAGES AREA */}
          <div className="flex-1 overflow-y-auto p-4 flex flex-col gap-4 bg-canvas">
            {messages.map((m) => (
              <div key={m.id} className={`flex gap-3 ${m.role === 'user' ? 'flex-row-reverse' : ''}`}>
                <div className={`w-8 h-8 rounded-full flex items-center justify-center shrink-0 ${m.role === 'user' ? 'bg-primary/10 text-primary' : 'bg-gold/20 text-gold-dark'}`}>
                  {m.role === 'user' ? <UserIcon className="w-4 h-4" /> : <Bot className="w-4 h-4" />}
                </div>
                <div className={`px-4 py-3 rounded-2xl text-sm max-w-[80%] ${m.role === 'user' ? 'bg-primary text-white rounded-tr-sm' : 'bg-surface border border-border-soft text-text-primary rounded-tl-sm'}`}>
                  <p className="whitespace-pre-wrap leading-relaxed">{(m as any).content}</p>
                </div>
              </div>
            ))}
            
            {isLoading && messages[messages.length - 1]?.role === 'user' && (
              <div className="flex gap-3">
                <div className="w-8 h-8 rounded-full bg-gold/20 text-gold-dark flex items-center justify-center shrink-0">
                  <Bot className="w-4 h-4" />
                </div>
                <div className="px-4 py-3 rounded-2xl text-sm bg-surface border border-border-soft rounded-tl-sm flex items-center gap-2">
                  <Loader2 className="w-4 h-4 animate-spin text-text-tertiary" />
                  <span className="text-text-secondary">AÏDA réfléchit...</span>
                </div>
              </div>
            )}
            <div ref={messagesEndRef} />
          </div>

          {/* INPUT AREA */}
          <div className="p-4 bg-surface border-t border-border-soft shrink-0 pb-safe">
            <form onSubmit={handleSubmit} className="relative flex items-center">
              <input
                value={input || ""}
                onChange={handleInputChange}
                placeholder="Pose-moi une question..."
                className="w-full bg-canvas border border-border-strong rounded-full pl-4 pr-12 py-3 text-sm focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary transition-all"
                disabled={isLoading}
              />
              <button 
                type="submit" 
                disabled={isLoading || !input?.trim()}
                className="absolute right-2 w-8 h-8 bg-primary text-white rounded-full flex items-center justify-center hover:bg-primary-dark transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
              >
                <Send className="w-4 h-4 ml-0.5" />
              </button>
            </form>
            <p className="text-[10px] text-center text-text-tertiary mt-2">AÏDA peut faire des erreurs. Vérifiez les informations importantes.</p>
          </div>
        </div>
      )}
    </>
  );
}
