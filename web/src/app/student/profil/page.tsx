"use client";
import { useEffect, useState } from 'react';
import { Button } from '@/components/ui/Button';
import { Card } from '@/components/ui/Card';
import { Input } from '@/components/ui/Input';
import { createClient } from '@/utils/supabase/client';

export default function ProfilPage() {
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [message, setMessage] = useState('');
  const [error, setError] = useState('');
  useEffect(() => {
    let cancelled = false;
    fetch('/api/user').then(async response => {
      if (!response.ok) throw new Error('Le profil n’a pas pu être chargé.');
      const user = await response.json();
      if (!cancelled) { setName(user.fullName || ''); setEmail(user.email); }
    }).catch(error => { if (!cancelled) setError(error.message); })
      .finally(() => { if (!cancelled) setLoading(false); });
    return () => { cancelled = true; };
  }, []);
  return <div className="max-w-3xl mx-auto space-y-6">
    <h1 className="font-display text-3xl font-bold">Mon profil</h1>
    <Card className="p-6">
      <form className="space-y-4" onSubmit={async event => {
        event.preventDefault(); setSaving(true); setMessage(''); setError('');
        try {
          const response = await fetch('/api/user', { method: 'PATCH', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ fullName: name }) });
          const data = await response.json();
          if (!response.ok) throw new Error(data.error || 'La sauvegarde a échoué.');
          setName(data.fullName); setMessage('Profil enregistré.');
        } catch (error) { setError(error instanceof Error ? error.message : 'La sauvegarde a échoué.'); }
        finally { setSaving(false); }
      }}>
        <Input label="Nom complet" value={name} onChange={event => setName(event.target.value)} minLength={2} maxLength={255} required disabled={loading || saving || !email} />
        <Input label="Adresse email" type="email" value={email} disabled />
        <Button type="submit" disabled={loading || saving || !email}>{saving ? 'Enregistrement…' : 'Enregistrer'}</Button>
        {message && <p role="status" className="text-success">{message}</p>}
        {error && <p role="alert" className="text-error">{error}</p>}
      </form>
    </Card>
    <Card className="p-6 space-y-3"><h2 className="font-display font-bold">Documents et préférences</h2><p>Le dépôt de CV, la personnalisation de l’avatar et les notifications ne sont pas encore disponibles.</p></Card>
    <Button onClick={async () => {
      const { error } = await createClient().auth.signOut();
      if (error) { setError('La déconnexion a échoué. Réessayez.'); return; }
      for (const key of ['aida_chat_history', 'activ_avatar', 'activ_orientation_results']) localStorage.removeItem(key);
      window.location.assign('/auth/login');
    }}>Se déconnecter</Button>
  </div>;
}
