import React from 'react';

export type ButtonVariant = 'primary' | 'secondary' | 'gamification';
export type ButtonSize = 'sm' | 'md' | 'lg';

export interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: ButtonVariant;
  size?: ButtonSize;
  children: React.ReactNode;
}

export const Button = React.forwardRef<HTMLButtonElement, ButtonProps>(
  ({ variant = 'primary', size = 'md', className = '', children, ...props }, ref) => {
    
    // Base styles (flat, easeOutCubic, 150ms)
    const baseStyles = 'inline-flex items-center justify-center font-medium rounded-md transition-all duration-150 ease-[cubic-bezier(0.33,1,0.68,1)] outline-none focus-visible:ring-2 focus-visible:ring-primary/50 focus-visible:ring-offset-2 disabled:opacity-50 disabled:pointer-events-none whitespace-nowrap';
    
    // Sizes (36px, 44px, 52px)
    const sizes = {
      sm: 'h-[36px] px-4 text-[13px]',
      md: 'h-[44px] px-5 text-[14px]',
      lg: 'h-[52px] px-6 text-[15px]',
    };

    // Variants (flat design, shadow only on hover)
    const variants = {
      primary: 'bg-primary text-white hover:bg-primary-hover hover:shadow-hover hover:-translate-y-[1px]',
      secondary: 'bg-transparent border border-border-soft text-text-primary hover:border-primary/50 hover:bg-canvas',
      gamification: 'bg-gold text-white hover:brightness-110 hover:shadow-hover hover:-translate-y-[1px]',
    };

    return (
      <button
        ref={ref}
        className={`${baseStyles} ${sizes[size]} ${variants[variant]} ${className}`}
        {...props}
      >
        {children}
      </button>
    );
  }
);

Button.displayName = 'Button';
