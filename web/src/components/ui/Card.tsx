import React from 'react';

export type CardVariant = 'standard' | 'gamification' | 'dark' | 'interactive';

export interface CardProps extends React.HTMLAttributes<HTMLDivElement> {
  variant?: CardVariant;
  interactive?: boolean;
}

export const Card = React.forwardRef<HTMLDivElement, CardProps>(
  ({ variant = 'standard', interactive = false, className = '', children, ...props }, ref) => {
    
    const variantStyles: Record<CardVariant, string> = {
      standard: 'bg-surface border border-border-soft text-text-primary',
      gamification: 'bg-surface border border-gold/30 text-text-primary',
      dark: 'bg-[#111827] border border-gray-800 text-white', interactive: 'bg-surface border border-border-soft text-text-primary hover:-translate-y-[2px] hover:shadow-hover hover:border-primary/20 cursor-pointer',
    };

    const baseStyles = 'rounded-lg overflow-hidden transition-all duration-150 ease-[cubic-bezier(0.33,1,0.68,1)]';
    
    const interactiveStyles = interactive 
      ? 'hover:-translate-y-[2px] hover:shadow-hover hover:border-primary/20 cursor-pointer' 
      : '';

    return (
      <div
        ref={ref}
        className={`${baseStyles} ${variantStyles[variant]} ${interactiveStyles} ${className}`}
        {...props}
      >
        {children}
      </div>
    );
  }
);

Card.displayName = 'Card';
