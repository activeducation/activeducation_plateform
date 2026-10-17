"use client";

import React, { useState, useRef, useId } from "react";
import { Upload, X, Loader2, Link as LinkIcon, Check, RefreshCw, AlertCircle, ImageIcon } from "lucide-react";
import { Button } from "./Button";

interface ImageUploadProps {
  label?: string;
  value?: string;
  onChange: (url: string) => void;
  bucket?: string;
  disabled?: boolean;
}

export function ImageUpload({
  label = "Image d'illustration",
  value = "",
  onChange,
  bucket = "explorer",
  disabled = false,
}: ImageUploadProps) {
  const inputId = useId();
  const fileInputRef = useRef<HTMLInputElement>(null);
  const [isUploading, setIsUploading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [showUrlInput, setShowUrlInput] = useState(false);
  const [isDragging, setIsDragging] = useState(false);

  const uploadFile = async (file: File) => {
    if (!file) return;

    if (file.size > 8 * 1024 * 1024) {
      setError("Le fichier dépasse la taille maximale autorisée de 8 Mo.");
      return;
    }

    if (!file.type.startsWith("image/")) {
      setError("Veuillez sélectionner un format d'image valide (JPG, PNG, WEBP, SVG, GIF).");
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
        throw new Error(errorData.error || "Échec du téléversement vers le serveur.");
      }

      const result = await response.json();
      onChange(result.url);
    } catch (err: any) {
      setError(err.message || "Une erreur est survenue lors du téléversement.");
    } finally {
      setIsUploading(false);
      if (fileInputRef.current) {
        fileInputRef.current.value = "";
      }
    }
  };

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      uploadFile(file);
    }
  };

  const handleDrop = (e: React.DragEvent<HTMLLabelElement>) => {
    e.preventDefault();
    e.stopPropagation();
    setIsDragging(false);
    if (disabled || isUploading) return;

    const file = e.dataTransfer.files?.[0];
    if (file) {
      uploadFile(file);
    }
  };

  const handleDragOver = (e: React.DragEvent<HTMLLabelElement>) => {
    e.preventDefault();
    e.stopPropagation();
    if (!disabled && !isUploading) {
      setIsDragging(true);
    }
  };

  const handleDragLeave = (e: React.DragEvent<HTMLLabelElement>) => {
    e.preventDefault();
    e.stopPropagation();
    setIsDragging(false);
  };

  const handleRemove = (e: React.MouseEvent) => {
    e.preventDefault();
    e.stopPropagation();
    onChange("");
    if (fileInputRef.current) {
      fileInputRef.current.value = "";
    }
  };

  return (
    <div className="flex flex-col gap-2 w-full">
      <div className="flex items-center justify-between">
        <label className="text-sm font-bold text-text-primary">{label}</label>
        <button
          type="button"
          onClick={() => setShowUrlInput(!showUrlInput)}
          className="text-xs text-primary hover:underline font-medium flex items-center gap-1 transition-colors cursor-pointer"
        >
          <LinkIcon className="w-3 h-3" />
          {showUrlInput ? "Masquer le champ URL" : "Coller une URL web"}
        </button>
      </div>

      {/* Accessible native file input connected via htmlFor to label elements */}
      <input
        id={inputId}
        ref={fileInputRef}
        type="file"
        accept="image/png,image/jpeg,image/webp,image/svg+xml,image/gif"
        onChange={handleFileChange}
        className="sr-only"
        disabled={disabled || isUploading}
      />

      {/* Main Container */}
      <div className="border border-border-soft rounded-xl bg-surface p-4 flex flex-col gap-3">
        {value ? (
          /* Preview state when an image is present */
          <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
            <div className="flex items-center gap-3 min-w-0 flex-1">
              <div className="w-20 h-16 rounded-lg bg-surface-alt border border-border-soft overflow-hidden shrink-0 relative flex items-center justify-center">
                <img
                  src={value}
                  alt="Aperçu"
                  className="w-full h-full object-cover"
                  onError={(e) => {
                    (e.target as HTMLElement).style.display = "none";
                  }}
                />
              </div>

              <div className="min-w-0 flex-1">
                <span className="inline-flex items-center gap-1 text-[11px] font-bold text-success mb-0.5">
                  <Check className="w-3.5 h-3.5" /> Image enregistrée
                </span>
                <p className="text-xs text-text-secondary truncate max-w-md font-mono" title={value}>
                  {value}
                </p>
              </div>
            </div>

            <div className="flex items-center gap-2 shrink-0 self-end sm:self-center">
              {/* Native label styled as button to guarantee OS file picker invocation */}
              <label
                htmlFor={inputId}
                className={`inline-flex items-center gap-2 text-xs font-bold h-10 px-4 rounded-xl text-white bg-primary hover:bg-primary-dark transition-all cursor-pointer shadow-sm select-none ${
                  disabled || isUploading ? "opacity-60 pointer-events-none" : ""
                }`}
              >
                {isUploading ? (
                  <>
                    <Loader2 className="w-3.5 h-3.5 animate-spin" /> Téléversement...
                  </>
                ) : (
                  <>
                    <RefreshCw className="w-3.5 h-3.5" /> Remplacer depuis mon appareil
                  </>
                )}
              </label>

              <button
                type="button"
                onClick={handleRemove}
                disabled={disabled || isUploading}
                title="Supprimer cette image"
                className="h-10 px-3 rounded-xl border border-border-soft text-text-secondary hover:text-error hover:border-error/30 bg-surface hover:bg-error/5 transition-all flex items-center justify-center cursor-pointer"
              >
                <X className="w-4 h-4" />
              </button>
            </div>
          </div>
        ) : (
          /* Empty state: full clickable dropzone that immediately opens file browser */
          <label
            htmlFor={inputId}
            onDrop={handleDrop}
            onDragOver={handleDragOver}
            onDragLeave={handleDragLeave}
            className={`flex flex-col sm:flex-row items-center justify-between gap-4 p-5 border-2 border-dashed rounded-xl transition-all cursor-pointer select-none ${
              isDragging
                ? "border-primary bg-primary/10 scale-[1.01]"
                : "border-border-soft hover:border-primary/60 hover:bg-surface-alt/70"
            } ${disabled || isUploading ? "opacity-60 pointer-events-none" : ""}`}
          >
            <div className="flex items-center gap-3 text-center sm:text-left">
              <div className="w-12 h-12 rounded-xl bg-primary/10 text-primary flex items-center justify-center shrink-0">
                <Upload className="w-6 h-6" />
              </div>
              <div>
                <p className="text-sm font-bold text-text-primary">
                  {isDragging ? "Déposez votre image ici" : "Téléverser depuis votre ordinateur"}
                </p>
                <p className="text-xs text-text-secondary">
                  Glissez-déposez ou cliquez pour parcourir (JPG, PNG, WEBP, SVG max 8 Mo)
                </p>
              </div>
            </div>

            <div className="inline-flex items-center justify-center gap-2 w-full sm:w-auto h-11 px-5 text-sm font-bold rounded-xl text-white bg-primary hover:bg-primary-dark transition-all shrink-0">
              {isUploading ? (
                <>
                  <Loader2 className="w-4 h-4 animate-spin" /> Téléversement en cours...
                </>
              ) : (
                <>
                  <Upload className="w-4 h-4" /> Choisir sur mon ordinateur
                </>
              )}
            </div>
          </label>
        )}

        {/* Optional manual URL input if the user explicitly prefers an external URL */}
        {showUrlInput && (
          <div className="pt-3 border-t border-border-soft flex flex-col gap-1.5 animate-fade-in">
            <label className="text-xs font-semibold text-text-secondary">
              Ou collez directement une URL d'image web :
            </label>
            <div className="flex gap-2">
              <input
                type="text"
                value={value}
                onChange={(e) => onChange(e.target.value.trim())}
                placeholder="https://..."
                disabled={disabled || isUploading}
                className="flex-1 h-10 rounded-lg border border-border-soft bg-canvas px-3 text-xs text-text-primary focus:outline-none focus:ring-2 focus:ring-primary/50"
              />
              {value && (
                <button
                  type="button"
                  onClick={handleRemove}
                  className="h-10 px-3 rounded-lg border border-border-soft text-text-secondary hover:text-error hover:bg-error/5 text-xs transition-colors flex items-center justify-center"
                >
                  <X className="w-3.5 h-3.5" />
                </button>
              )}
            </div>
          </div>
        )}
      </div>

      {error && (
        <div className="flex items-center gap-1.5 text-xs font-medium text-error mt-0.5">
          <AlertCircle className="w-3.5 h-3.5 shrink-0" />
          <span>{error}</span>
        </div>
      )}
    </div>
  );
}
