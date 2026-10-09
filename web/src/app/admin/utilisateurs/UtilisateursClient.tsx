"use client";

import React, { useState } from "react";
import { Card } from "@/components/ui/Card";
import { Users, Search, Shield, GraduationCap, Medal } from "lucide-react";

export default function UtilisateursClient({ initialUsers }: { initialUsers: any[] }) {
  const [searchTerm, setSearchTerm] = useState("");

  // Filter users by email or fullName
  const filteredUsers = initialUsers.filter(user => 
    (user.email && user.email.toLowerCase().includes(searchTerm.toLowerCase())) ||
    (user.fullName && user.fullName.toLowerCase().includes(searchTerm.toLowerCase()))
  );

  return (
    <div className="flex flex-col gap-6 animate-fade-in relative">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-display font-bold text-text-primary mb-2">Utilisateurs</h1>
          <p className="text-text-secondary">Gérez les comptes des étudiants et administrateurs ({initialUsers.length} au total).</p>
        </div>
      </div>

      <div className="flex items-center gap-2 bg-surface p-2 rounded-xl border border-border-soft w-full md:w-96">
        <Search className="w-5 h-5 text-text-tertiary ml-2" />
        <input 
          type="text" 
          placeholder="Rechercher par email ou nom..." 
          className="bg-transparent border-none outline-none text-sm w-full p-2 text-text-primary placeholder:text-text-tertiary"
          value={searchTerm}
          onChange={(e) => setSearchTerm(e.target.value)}
        />
      </div>

      <Card variant="standard" className="p-0 overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-surface-alt border-b border-border-soft">
                <th className="p-4 font-bold text-sm text-text-secondary">Utilisateur</th>
                <th className="p-4 font-bold text-sm text-text-secondary">Rôle</th>
                <th className="p-4 font-bold text-sm text-text-secondary">Progression (Niv / XP)</th>
                <th className="p-4 font-bold text-sm text-text-secondary">Date d'inscription</th>
              </tr>
            </thead>
            <tbody>
              {filteredUsers.length > 0 ? filteredUsers.map(user => (
                <tr key={user.id} className="border-b border-border-soft hover:bg-surface-alt/50 transition-colors">
                  <td className="p-4 flex items-center gap-3">
                    <div className="w-10 h-10 rounded-full bg-primary/10 flex items-center justify-center text-primary font-bold uppercase overflow-hidden shrink-0">
                      {user.avatarUrl ? (
                        <img src={user.avatarUrl} alt="Avatar" className="w-full h-full object-cover" />
                      ) : (
                        user.email ? user.email.charAt(0) : "?"
                      )}
                    </div>
                    <div>
                      <p className="font-bold text-sm text-text-primary">{user.fullName || "Étudiant sans nom"}</p>
                      <p className="text-xs text-text-secondary">{user.email}</p>
                    </div>
                  </td>
                  <td className="p-4">
                    {user.role === 'admin' || user.role === 'ADMIN' ? (
                      <span className="flex items-center gap-1 text-xs font-bold px-2 py-1 bg-error/10 text-error rounded-md w-fit">
                        <Shield className="w-3 h-3" /> Admin
                      </span>
                    ) : (
                      <span className="flex items-center gap-1 text-xs font-medium px-2 py-1 bg-surface border border-border-soft text-text-secondary rounded-md w-fit">
                        <GraduationCap className="w-3 h-3" /> Étudiant
                      </span>
                    )}
                  </td>
                  <td className="p-4">
                    <div className="flex items-center gap-2">
                      <div className="flex items-center justify-center w-6 h-6 rounded bg-gold/20 text-gold-dark font-bold text-xs">
                        {user.level || 1}
                      </div>
                      <span className="text-xs text-text-secondary flex items-center gap-1">
                        <Medal className="w-3 h-3" /> {user.xpPoints || 0} XP
                      </span>
                    </div>
                  </td>
                  <td className="p-4 text-sm text-text-secondary">
                    {user.createdAt ? new Date(user.createdAt).toLocaleDateString("fr-FR") : "-"}
                  </td>
                </tr>
              )) : (
                <tr>
                  <td colSpan={4} className="p-8 text-center text-text-secondary">
                    Aucun utilisateur trouvé.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </Card>
    </div>
  );
}
