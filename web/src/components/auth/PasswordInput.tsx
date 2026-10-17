"use client";

import React, { useState, useId } from "react";
import { Eye, EyeOff, Check, X, ShieldCheck } from "lucide-react";

export interface PasswordInputProps extends Omit<React.InputHTMLAttributes<HTMLInputElement>, "type"> {
  label?: string;
  error?: string;
  showStrength?: boolean;
}

export function getPasswordStrength(password: string) {
  const checks = {
    length: password.length >= 8,
    hasUpper: /[A-Z]/.test(password),
    hasLower: /[a-z]/.test(password),
    hasNumber: /[0-9]/.test(password),
    hasSpecial: /[^A-Za-z0-9]/.test(password),
  };

  if (!password) {
    return {
      score: 0,
      label: "",
      colorText: "text-text-tertiary",
      colorBg: "bg-border-soft",
      checks,
    };
  }

  let passed = 0;
  if (checks.length) passed++;
  if (checks.hasUpper && checks.hasLower) passed++;
  if (checks.hasNumber) passed++;
  if (checks.hasSpecial) passed++;

  if (password.length < 6) {
    return {
      score: 1,
      label: "Trop court",
      colorText: "text-error",
      colorBg: "bg-error",
      checks,
    };
  }

  if (passed <= 2) {
    return {
      score: 2,
      label: "Faible",
      colorText: "text-error",
      colorBg: "bg-error",
      checks,
    };
  }

  if (passed === 3) {
    return {
      score: 3,
      label: "Moyen",
      colorText: "text-[#FAA100]",
      colorBg: "bg-[#FAA100]",
      checks,
    };
  }

  return {
    score: 4,
    label: "Fort",
    colorText: "text-[#00C853]",
    colorBg: "bg-[#00C853]",
    checks,
  };
}

export const PasswordInput = React.forwardRef<HTMLInputElement, PasswordInputProps>(
  ({ label, error, showStrength = false, value = "", onChange, className = "", id, ...props }, ref) => {
    const generatedId = useId();
    const inputId = id || generatedId;
    const [showPassword, setShowPassword] = useState(false);

    const stringValue = typeof value === "string" ? value : "";
    const strength = getPasswordStrength(stringValue);
    const isError = Boolean(error);

    return (
      <div className="flex flex-col gap-2 w-full text-left">
        {label && (
          <label htmlFor={inputId} className="text-[13px] font-semibold text-text-primary">
            {label}
          </label>
        )}

        <div className="relative flex items-center w-full">
          <input
            id={inputId}
            ref={ref}
            type={showPassword ? "text" : "password"}
            value={value}
            onChange={onChange}
            className={`
              bg-surface h-[44px] w-full rounded-sm px-4 pr-11 text-text-primary text-[14px] outline-none transition-all duration-150
              placeholder:text-text-tertiary
              border 
              ${isError 
                ? "border-error focus:ring-2 focus:ring-error/20" 
                : "border-border-soft focus:border-primary focus:ring-2 focus:ring-primary/10 hover:border-text-tertiary"
              }
              ${className}
            `}
            {...props}
          />

          <button
            type="button"
            onClick={() => setShowPassword((prev) => !prev)}
            aria-label={showPassword ? "Masquer le mot de passe" : "Afficher le mot de passe"}
            className="absolute right-3 p-1.5 rounded text-text-secondary hover:text-text-primary hover:bg-surface-alt transition-colors focus:outline-none focus:ring-1 focus:ring-primary"
            tabIndex={-1}
          >
            {showPassword ? (
              <EyeOff className="w-4 h-4 text-text-secondary" />
            ) : (
              <Eye className="w-4 h-4 text-text-secondary" />
            )}
          </button>
        </div>

        {isError && (
          <span className="text-error text-[13px]">
            {error}
          </span>
        )}

        {/* Strength Indicator */}
        {showStrength && stringValue.length > 0 && (
          <div className="flex flex-col gap-2 pt-1 text-xs">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-1.5 text-text-secondary">
                <ShieldCheck className="w-3.5 h-3.5" />
                <span>Sécurité du mot de passe :</span>
              </div>
              <span className={`font-semibold ${strength.colorText}`}>
                {strength.label}
              </span>
            </div>

            {/* 4-bar Gauge */}
            <div className="grid grid-cols-4 gap-1.5 h-1.5 w-full">
              {[1, 2, 3, 4].map((step) => {
                const isActive = strength.score >= step;
                return (
                  <div
                    key={step}
                    className={`h-full rounded-full transition-all duration-200 ${
                      isActive ? strength.colorBg : "bg-border-soft"
                    }`}
                  />
                );
              })}
            </div>

            {/* Micro requirements checklist */}
            <div className="grid grid-cols-1 sm:grid-cols-3 gap-1.5 pt-1 text-[11px] text-text-secondary">
              <div className={`flex items-center gap-1 transition-colors ${strength.checks.length ? "text-[#00C853] font-medium" : "text-text-tertiary"}`}>
                {strength.checks.length ? <Check className="w-3 h-3" /> : <X className="w-3 h-3" />}
                <span>8 caractères min.</span>
              </div>
              <div className={`flex items-center gap-1 transition-colors ${strength.checks.hasUpper && strength.checks.hasLower ? "text-[#00C853] font-medium" : "text-text-tertiary"}`}>
                {strength.checks.hasUpper && strength.checks.hasLower ? <Check className="w-3 h-3" /> : <X className="w-3 h-3" />}
                <span>Majuscule & minuscule</span>
              </div>
              <div className={`flex items-center gap-1 transition-colors ${strength.checks.hasNumber || strength.checks.hasSpecial ? "text-[#00C853] font-medium" : "text-text-tertiary"}`}>
                {strength.checks.hasNumber || strength.checks.hasSpecial ? <Check className="w-3 h-3" /> : <X className="w-3 h-3" />}
                <span>Chiffre ou symbole</span>
              </div>
            </div>
          </div>
        )}
      </div>
    );
  }
);

PasswordInput.displayName = "PasswordInput";
