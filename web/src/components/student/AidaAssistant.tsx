"use client";

import React, { useState } from "react";
import { Sparkles, ArrowRight, RotateCcw, X } from "lucide-react";

interface AidaAssistantProps {
  title?: string;
  message: string;
  actionLabel?: string;
  actionHref?: string;
  actionPrompt?: string;
  onAction?: () => void;
  secondaryActionLabel?: string;
  secondaryActionHref?: string;
  onSecondaryAction?: () => void;
  variant?: "inline" | "floating" | "compact";
  dismissible?: boolean;
  onDismiss?: () => void;
}

export function AidaAssistant({ 
  title = "AÏDA vous conseille", 
  message, 
  actionLabel, 
  actionHref,
  actionPrompt,
  onAction,
  secondaryActionLabel,
  secondaryActionHref,
  onSecondaryAction,
  variant = "inline",
  dismissible = false,
  onDismiss
}: AidaAssistantProps) {
  const [isDismissed, setIsDismissed] = useState(false);

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

  const handleSecondaryAction = (e: React.MouseEvent) => {
    if (onSecondaryAction) {
      e.preventDefault();
      onSecondaryAction();
    }
  };

  const handleDismiss = () => {
    setIsDismissed(true);
    if (onDismiss) {
      onDismiss();
    }
  };

  if (isDismissed) {
    return null;
  }

  // Format compact / bandeau discret
  if (variant === "compact") {
    return (
      <div className="relative overflow-hidden rounded-xl bg-primary/5 border border-primary/20 px-3.5 py-2.5 shadow-xs transition-all flex flex-col md:flex-row md:items-center justify-between gap-3">
        <div className="flex items-center gap-2.5 min-w-0">
          <div className="flex-shrink-0 w-7 h-7 rounded-lg bg-primary text-white flex items-center justify-center shadow-xs">
            <Sparkles className="w-3.5 h-3.5" />
          </div>
          <div className="text-xs md:text-sm text-text-secondary leading-normal">
            {title && <span className="font-bold text-primary mr-1.5">{title} :</span>}
            <span>{message}</span>
          </div>
        </div>

        <div className="flex items-center gap-2 shrink-0 self-end md:self-auto">
          {actionLabel && (
            actionHref && actionHref !== '#' ? (
              <a 
                href={actionHref} 
                className="inline-flex items-center gap-1.5 text-xs font-bold text-white bg-primary hover:bg-primary-dark px-3 py-1.5 rounded-lg transition-colors whitespace-nowrap shadow-xs"
              >
                {actionLabel} <ArrowRight className="w-3.5 h-3.5" />
              </a>
            ) : (
              <button 
                type="button"
                onClick={handleAction}
                className="inline-flex items-center gap-1.5 text-xs font-bold text-white bg-primary hover:bg-primary-dark px-3 py-1.5 rounded-lg transition-colors cursor-pointer whitespace-nowrap shadow-xs active:scale-95"
              >
                {actionLabel} <ArrowRight className="w-3.5 h-3.5" />
              </button>
            )
          )}

          {secondaryActionLabel && (
            secondaryActionHref && secondaryActionHref !== '#' ? (
              <a 
                href={secondaryActionHref} 
                className="inline-flex items-center gap-1 text-xs font-bold text-text-secondary hover:text-text-primary bg-surface border border-border-soft hover:border-primary/30 px-2.5 py-1.5 rounded-lg transition-colors shadow-xs"
              >
                <RotateCcw className="w-3 h-3 text-text-tertiary" />
                {secondaryActionLabel}
              </a>
            ) : (
              <button 
                type="button"
                onClick={handleSecondaryAction}
                className="inline-flex items-center gap-1 text-xs font-bold text-text-secondary hover:text-text-primary bg-surface border border-border-soft hover:border-primary/30 px-2.5 py-1.5 rounded-lg transition-colors cursor-pointer shadow-xs active:scale-95"
              >
                <RotateCcw className="w-3 h-3 text-text-tertiary" />
                {secondaryActionLabel}
              </button>
            )
          )}

          {dismissible && (
            <button
              type="button"
              onClick={handleDismiss}
              className="text-text-tertiary hover:text-text-primary p-1 rounded-md hover:bg-black/5 transition-colors cursor-pointer"
              title="Fermer ce conseil"
              aria-label="Fermer"
            >
              <X className="w-4 h-4" />
            </button>
          )}
        </div>
      </div>
    );
  }

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
          
          <div className="flex flex-wrap items-center gap-3 mt-4">
            {actionLabel && (
              actionHref && actionHref !== '#' ? (
                <a 
                  href={actionHref} 
                  className="inline-flex items-center gap-2 text-xs font-bold text-white bg-primary px-4 py-2.5 rounded-lg hover:bg-primary/90 transition-all shadow-sm"
                >
                  {actionLabel} <ArrowRight className="w-4 h-4" />
                </a>
              ) : (
                <button 
                  type="button"
                  onClick={handleAction}
                  className="inline-flex items-center gap-2 text-xs font-bold text-white bg-primary px-4 py-2.5 rounded-lg hover:bg-primary/90 transition-all cursor-pointer shadow-sm active:scale-95"
                >
                  {actionLabel} <ArrowRight className="w-4 h-4" />
                </button>
              )
            )}

            {secondaryActionLabel && (
              secondaryActionHref && secondaryActionHref !== '#' ? (
                <a 
                  href={secondaryActionHref} 
                  className="inline-flex items-center gap-1.5 text-xs font-bold text-text-secondary hover:text-text-primary bg-surface border border-border-soft hover:border-primary/30 px-3.5 py-2.5 rounded-lg transition-all shadow-xs"
                >
                  <RotateCcw className="w-3.5 h-3.5 text-text-tertiary" />
                  {secondaryActionLabel}
                </a>
              ) : (
                <button 
                  type="button"
                  onClick={handleSecondaryAction}
                  className="inline-flex items-center gap-1.5 text-xs font-bold text-text-secondary hover:text-text-primary bg-surface border border-border-soft hover:border-primary/30 px-3.5 py-2.5 rounded-lg transition-all cursor-pointer shadow-xs active:scale-95"
                >
                  <RotateCcw className="w-3.5 h-3.5 text-text-tertiary" />
                  {secondaryActionLabel}
                </button>
              )
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
