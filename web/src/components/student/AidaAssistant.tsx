"use client";

import React from "react";
import { Sparkles, ArrowRight } from "lucide-react";

interface AidaAssistantProps {
  title?: string;
  message: string;
  actionLabel?: string;
  actionHref?: string;
  actionPrompt?: string;
  onAction?: () => void;
  variant?: "inline" | "floating";
}

export function AidaAssistant({ 
  title = "AÏDA vous conseille", 
  message, 
  actionLabel, 
  actionHref,
  actionPrompt,
  onAction,
  variant = "inline"
}: AidaAssistantProps) {
  const handleAction = (e: React.MouseEvent) => {
    if (onAction) {
      e.preventDefault();
      onAction();
      return;
    }

    if (actionPrompt || !actionHref || actionHref === '#') {
      e.preventDefault();
      const promptToSend = actionPrompt || message || "Bonjour AÏDA, j'ai une question concernant cette page.";
      if (typeof window !== 'undefined') {
        window.dispatchEvent(new CustomEvent('open-aida-chat', {
          detail: { prompt: promptToSend }
        }));
      }
      return;
    }
  };

  return (
    <div className={`relative overflow-hidden rounded-2xl bg-primary/5 border border-primary/20 p-5 ${variant === 'floating' ? 'shadow-lg backdrop-blur-md' : 'shadow-sm'}`}>
      {/* Subtle background flair */}
      <div className="absolute top-0 right-0 w-32 h-32 bg-primary/10 rounded-full blur-2xl -translate-y-1/2 translate-x-1/2" />
      
      <div className="relative z-10 flex gap-4">
        <div className="flex-shrink-0 w-10 h-10 rounded-full bg-primary flex items-center justify-center text-white shadow-sm">
          <Sparkles className="w-5 h-5" />
        </div>
        <div className="flex-1">
          <h4 className="text-sm font-bold text-primary mb-1">{title}</h4>
          <p className="text-sm text-text-secondary leading-relaxed">
            {message}
          </p>
          
          {actionLabel && (
            actionHref && actionHref !== '#' ? (
              <a 
                href={actionHref} 
                className="inline-flex items-center gap-2 mt-4 text-xs font-bold text-white bg-primary px-4 py-2.5 rounded-lg hover:bg-primary-dark transition-all shadow-sm"
              >
                {actionLabel} <ArrowRight className="w-4 h-4" />
              </a>
            ) : (
              <button 
                type="button"
                onClick={handleAction}
                className="inline-flex items-center gap-2 mt-4 text-xs font-bold text-white bg-primary px-4 py-2.5 rounded-lg hover:bg-primary-dark transition-all cursor-pointer shadow-sm active:scale-95"
              >
                {actionLabel} <ArrowRight className="w-4 h-4" />
              </button>
            )
          )}
        </div>
      </div>
    </div>
  );
}
