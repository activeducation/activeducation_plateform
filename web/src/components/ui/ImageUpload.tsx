"use client";

import React, { useState, useRef } from "react";
import { Upload, X, Loader2, Image as ImageIcon, Link as LinkIcon, Check } from "lucide-react";
import { Button } from "./Button";

interface ImageUploadProps {
  label?: string;
  value?: string;
  onChange: (url: string) => void;
  bucket?: string;
  disabled?: boolean;
  placeholder?: string;
}

export function ImageUpload({
  label = "Image d'illustration",
  value = "",
  onChange,
  bucket = "explorer",
  disabled = false,
  placeholder = "Glissez une image ou cliquez pour parcourir",
}: ImageUploadProps) {
  const [isUploading, setIsUploading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [mode, setMode] = useState<"file" | "url">(value && value.startsWith("http") && !value.includes("supabase.co") ? "url" : "file");
  const [manualUrl, setManualUrl] = useState(value || "");
  const fileInputRef = useRef<HTMLInputElement>(null);

  const handleFileChange = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    // Validate size (max 8MB)
    if (file.size > 8 * 1024 * 1024) {
      setError("Le fichier dépasse la taille maximale autorisée de 8 Mo.");
      return;
    }

    // Validate type
    if (!file.type.startsWith("image/")) {
      setError("Veuillez sélectionner un fichier image valide (JPG, PNG, WEBP, SVG, GIF).");
      return;
    }

    setError(null);
    setIsUploading(true);

    try {
      const formData = new FormData();
      formData.append("file", file);
      formData.append("bucket", bucket);

      const response = await fetch("/api/admin/upload", {
        method: "POST",
        body: formData,
      });

      if (!response.ok) {
        const errorData = await response.json().catch(() => ({}));
        throw new Error(errorData.error || "Échec du téléversement.");
      }

      const result = await response.json();
      onChange(result.url);
      setManualUrl(result.url);
    } catch (err: any) {
      setError(err.message || "Une erreur est survenue lors du téléversement.");
    } finally {
      setIsUploading(false);
      if (fileInputRef.current) {
        fileInputRef.current.value = "";
      }
    }
  };

  const handleRemove = () => {
    onChange("");
    setManualUrl("");
    if (fileInputRef.current) {
      fileInputRef.current.value = "";
    }
  };

  const handleManualUrlSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    onChange(manualUrl.trim());
  };

  return (
    <div className="flex flex-col gap-1.5 w-full">
      <div className="flex items-center justify-between">
        <label className="text-sm font-bold text-text-primary">{label}</label>
        <button
          type="button"
          onClick={() => setMode(mode === "file" ? "url" : "file")}
          className="text-xs text-primary hover:underline font-medium flex items-center gap-1 transition-colors"
        >
          {mode === "file" ? (
            <>
              <LinkIcon className="w-3 h-3" /> Saisir une URL
            </>
          ) : (
            <>
              <Upload className="w-3 h-3" /> Téléverser depuis l'ordinateur
            </>
          )}
        </button>
      </div>

      {mode === "file" ? (
        <div className="flex flex-col gap-2">
          {value ? (
            <div className="relative group border border-border-soft rounded-xl overflow-hidden bg-surface p-2 flex items-center gap-4">
              <div className="w-20 h-16 rounded-lg bg-surface-alt border border-border-soft overflow-hidden shrink-0 relative flex items-center justify-center">
                <img 
                  src={value} 
                  alt="Aperçu" 
                  className="w-full h-full object-cover"
                  onError={(e) => {
                    (e.target as HTMLElement).style.display = 'none';
                  }}
                />
              </div>

              <div className="flex-1 min-w-0 pr-2">
                <p className="text-xs font-semibold text-text-primary truncate">Image sélectionnée</p>
                <p className="text-[11px] text-text-secondary truncate mt-0.5">{value}</p>
                <span className="inline-flex items-center gap-1 text-[10px] font-bold text-success mt-1">
                  <Check className="w-3 h-3" /> Prête
                </span>
              </div>

              <button
                type="button"
                onClick={handleRemove}
                disabled={disabled || isUploading}
                title="Supprimer l'image"
                className="p-2 rounded-lg text-text-secondary hover:text-error hover:bg-error/10 border border-border-soft transition-colors shrink-0 mr-1"
              >
                <X className="w-4 h-4" />
              </button>
            </div>
          ) : (
            <div
              onClick={() => !disabled && !isUploading && fileInputRef.current?.click()}
              className={`border-2 border-dashed rounded-xl p-5 flex flex-col items-center justify-center gap-2 cursor-pointer transition-all ${
                isUploading
                  ? "border-primary/50 bg-primary/5 cursor-wait"
                  : "border-border-soft hover:border-primary/50 hover:bg-surface-alt bg-surface"
              } ${disabled ? "opacity-50 pointer-events-none" : ""}`}
            >
              <input
                ref={fileInputRef}
                type="file"
                accept="image/png,image/jpeg,image/webp,image/svg+xml,image/gif"
                onChange={handleFileChange}
                className="hidden"
                disabled={disabled || isUploading}
              />

              {isUploading ? (
                <div className="flex flex-col items-center gap-2 py-2">
                  <Loader2 className="w-6 h-6 text-primary animate-spin" />
                  <p className="text-xs font-semibold text-primary">Téléversement en cours depuis votre appareil...</p>
                </div>
              ) : (
                <div className="flex flex-col items-center gap-1.5 text-center">
                  <div className="w-10 h-10 rounded-xl bg-primary/10 text-primary flex items-center justify-center">
                    <Upload className="w-5 h-5" />
                  </div>
                  <p className="text-sm font-semibold text-text-primary">
                    Cliquez pour choisir une image sur votre ordinateur
                  </p>
                  <p className="text-xs text-text-secondary">
                    PNG, JPG, WEBP, SVG jusqu'à 8 Mo
                  </p>
                </div>
              )}
            </div>
          )}
        </div>
      ) : (
        <div className="flex gap-2">
          <input
            type="text"
            value={manualUrl}
            onChange={(e) => {
              setManualUrl(e.target.value);
              onChange(e.target.value.trim());
            }}
            placeholder="https://images.unsplash.com/... ou https://..."
            disabled={disabled}
            className="flex-1 h-12 rounded-xl border border-border-soft bg-canvas px-4 focus:outline-none focus:ring-2 focus:ring-primary/50 text-sm text-text-primary placeholder:text-text-secondary"
          />
          {manualUrl && (
            <Button
              type="button"
              variant="outline"
              size="sm"
              onClick={handleRemove}
              className="h-12 px-3 text-text-secondary hover:text-error"
            >
              <X className="w-4 h-4" />
            </Button>
          )}
        </div>
      )}

      {error && (
        <p className="text-xs font-medium text-error mt-1">{error}</p>
      )}
    </div>
  );
}
