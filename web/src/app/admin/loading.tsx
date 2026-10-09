import React from "react";
import { Loader2 } from "lucide-react";

export default function AdminLoading() {
  return (
    <div className="flex items-center justify-center w-full h-[50vh]">
      <div className="flex flex-col items-center gap-4 text-text-tertiary">
        <Loader2 className="w-10 h-10 animate-spin text-primary" />
        <p className="font-medium animate-pulse">Chargement des données...</p>
      </div>
    </div>
  );
}
