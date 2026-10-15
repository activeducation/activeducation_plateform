import React from 'react';

export interface InputProps extends React.InputHTMLAttributes<HTMLInputElement> {
  label?: string;
  error?: string;
}

export const Input = React.forwardRef<HTMLInputElement, InputProps>(
  ({ label, error, className = '', ...props }, ref) => {
    
    const isError = Boolean(error);
    
    return (
      <div className="flex flex-col gap-[8px] w-full">
        {label && (
          <label className="text-[13px] font-semibold text-text-primary">
            {label}
          </label>
        )}
        <input
          ref={ref}
          className={`
            bg-surface h-[44px] rounded-sm px-4 text-text-primary text-[14px] outline-none transition-all duration-150
            placeholder:text-text-tertiary
            border 
            ${isError 
              ? 'border-error focus:ring-2 focus:ring-error/20' 
              : 'border-border-soft focus:border-primary focus:ring-2 focus:ring-primary/10 hover:border-text-tertiary'
            }
            ${className}
          `}
          {...props}
        />
        {isError && (
          <span className="text-error text-[13px]">
            {error}
          </span>
        )}
      </div>
    );
  }
);

Input.displayName = 'Input';
