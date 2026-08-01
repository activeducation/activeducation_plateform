'use client';
import { useState, useEffect } from 'react';
import { useAuth } from '@/lib/auth';
import { api } from '@/lib/api';
import { useRouter } from 'next/navigation';
import {
  ArrowLeft, User, Mail, Phone, Briefcase, Calendar, Link2,
  FileText, Heart, Send, CheckCircle, GraduationCap, Loader2,
  BookOpen, Plus, X, Globe, Code, Languages, Award,
  Building2, ChevronDown, ChevronUp,
} from 'lucide-react';
import { useTheme } from '@/lib/theme';

export default function BecomeMentorPage() {
  const { user, loading: authLoading } = useAuth();
  const router = useRouter();
  const { t } = useTheme();
  const [submitting, setSubmitting] = useState(false);
  const [success, setSuccess] = useState(false);
  const [errorMsg, setErrorMsg] = useState('');

  const [fullName, setFullName] = useState('');
  const [email, setEmail] = useState('');
  const [phone, setPhone] = useState('');
  const [specialty, setSpecialty] = useState('');
  const [yearsExp, setYearsExp] = useState('');
  const [linkedin, setLinkedin] = useState('');
  const [bio, setBio] = useState('');
  const [motivation, setMotivation] = useState('');
  const [portfolioOpen, setPortfolioOpen] = useState(false);

  interface Formation { ecole: string; diplome: string; domaine: string; annee_debut: string; annee_fin: string }
  interface Experience { poste: string; entreprise: string; debut: string; fin: string; en_cours: boolean; description: string }
  interface Certif { nom: string; organisme: string; annee: string; lien: string }
  interface Projet { nom: string; description: string; lien: string; technologies: string }
  interface Langue { langue: string; niveau: string }
  interface Lien { type: string; url: string }

  const [formations, setFormations] = useState<Formation[]>([{ ecole: '', diplome: '', domaine: '', annee_debut: '', annee_fin: '' }]);
  const [experiences, setExperiences] = useState<Experience[]>([{ poste: '', entreprise: '', debut: '', fin: '', en_cours: false, description: '' }]);
  const [certifications, setCertifications] = useState<Certif[]>([]);
  const [projets, setProjets] = useState<Projet[]>([]);
  const [langues, setLangues] = useState<Langue[]>([]);
  const [liens, setLiens] = useState<Lien[]>([]);

  useEffect(() => {
    if (user) {
      setFullName(`${user.first_name || ''} ${user.last_name || ''}`.trim());
      setEmail(user.email);
    }
  }, [user]);

  if (authLoading) return <div className="min-h-[80vh] flex items-center justify-center"><div className="animate-spin w-8 h-8 border-2 border-brand-primary border-t-transparent rounded-full" /></div>;
  if (!user) return null;

  if (success) {
    return (
      <div className="min-h-[80vh] flex flex-col items-center justify-center px-6 animate-fade-in">
        <div className="w-20 h-20 rounded-[28px] bg-gradient-to-br from-brand-primary to-brand-primary-light flex items-center justify-center mb-6 shadow-lg">
          <CheckCircle size={48} className="text-white" />
        </div>
        <h1 className="text-2xl font-extrabold text-brand-text-primary text-center">{t('Candidature envoyée !')}</h1>
        <p className="text-brand-text-secondary text-sm text-center mt-3 max-w-sm leading-relaxed">
          {t('Merci ! Notre équipe examinera votre candidature et reviendra vers vous par email.')}
        </p>
        <button onClick={() => router.push('/mentors')}
          className="mt-8 px-8 py-3.5 rounded-full bg-brand-primary text-white font-bold text-base">
          {t('Retour')}
        </button>
      </div>
    );
  }

  const safeInt = (v: string) => { const n = parseInt(v); return isNaN(n) ? undefined : n; };

  const normalizeUrl = (url: string) => {
    if (!url) return undefined;
    if (!url.startsWith('http://') && !url.startsWith('https://') && !url.startsWith('//')) return `https://${url}`;
    return url;
  };

  const buildPortfolio = () => {
    const clean = <T,>(arr: T[], hasData: (item: T) => boolean) => arr.filter(hasData);
    return {
      formations: clean(formations, f => !!(f.ecole && f.diplome)).map(f => ({
        ecole: f.ecole, diplome: f.diplome, domaine: f.domaine || undefined,
        annee_debut: safeInt(f.annee_debut),
        annee_fin: safeInt(f.annee_fin),
      })),
      experiences: clean(experiences, e => !!(e.poste && e.entreprise)).map(e => ({
        poste: e.poste, entreprise: e.entreprise,
        debut: e.debut, fin: e.en_cours ? undefined : (e.fin || undefined),
        en_cours: e.en_cours, description: e.description || undefined,
      })),
      certifications: clean(certifications, c => !!(c.nom && c.organisme)).map(c => ({
        nom: c.nom, organisme: c.organisme,
        annee: safeInt(c.annee),
        lien: normalizeUrl(c.lien),
      })),
      projets: clean(projets, p => !!p.nom).map(p => ({
        nom: p.nom, description: p.description || undefined,
        lien: normalizeUrl(p.lien),
        technologies: p.technologies ? p.technologies.split(',').map(s => s.trim()).filter(Boolean) : undefined,
      })),
      langues: clean(langues, l => !!(l.langue && l.niveau)),
      liens: clean(liens, l => !!l.url).map(l => ({ type: l.type || 'website', url: normalizeUrl(l.url) })),
    };
  };

  const handleSubmit = async () => {
    if (!fullName || !email || !specialty) return;
    setErrorMsg('');
    setSubmitting(true);
    try {
      const portfolio = buildPortfolio();
      await api.post('/mentors/apply', {
        full_name: fullName,
        email,
        phone: phone || undefined,
        specialty,
        years_experience: yearsExp ? parseInt(yearsExp) : undefined,
        linkedin_url: normalizeUrl(linkedin),
        bio: bio || undefined,
        motivation: motivation || undefined,
        portfolio: Object.values(portfolio).some((v: any) => v.length > 0) ? portfolio : undefined,
      });
      setSuccess(true);
    } catch (e: any) {
      const msg = e?.message || e?.toString() || '';
      setErrorMsg(msg.includes('422') || msg.includes('validation') ? t('Vérifiez les champs obligatoires (nom, email, spécialité)') : msg);
    }
    setSubmitting(false);
  };

  const fields = [
    { label: t('Nom complet *'), icon: User, value: fullName, set: setFullName, type: 'text' },
    { label: t('Email *'), icon: Mail, value: email, set: setEmail, type: 'email' },
    { label: t('Téléphone'), icon: Phone, value: phone, set: setPhone, type: 'tel' },
    { label: t('Spécialité * (ex: Ingénierie, Droit...)'), icon: Briefcase, value: specialty, set: setSpecialty, type: 'text' },
    { label: t("Années d'expérience"), icon: Calendar, value: yearsExp, set: setYearsExp, type: 'number' },
    { label: t('Profil LinkedIn (URL)'), icon: Link2, value: linkedin, set: setLinkedin, type: 'url' },
  ];

  return (
    <div className="min-h-screen bg-brand-background animate-fade-in">
      <button onClick={() => router.back()} className="flex items-center gap-1 text-brand-text-secondary text-sm px-6 pt-6 pb-2">
        <ArrowLeft size={18} /> {t('Retour')}
      </button>

      {/* Hero */}
      <div className="mx-6 mb-6 rounded-2xl bg-gradient-to-br from-brand-primary via-brand-primary to-[#1060CF] p-6">
        <div className="w-12 h-12 rounded-xl bg-white/15 flex items-center justify-center border border-white/20 mb-3">
          <GraduationCap size={24} className="text-white" />
        </div>
        <h1 className="text-white font-extrabold text-xl">{t('Partagez votre expérience')}</h1>
        <p className="text-white/70 text-sm mt-1 leading-relaxed">
          {t('Accompagnez des jeunes dans leur orientation. Remplissez le formulaire pour rejoindre nos mentors.')}
        </p>
      </div>

      <div className="px-6 pb-8 space-y-4">
        {fields.map((f) => (
          <div key={f.label}>
            <label className="text-xs font-semibold text-brand-text-primary mb-1.5 block">{f.label}</label>
            <div className="relative">
              <div className="absolute left-3.5 top-1/2 -translate-y-1/2">
                <f.icon size={16} className="text-brand-text-tertiary" />
              </div>
              <input type={f.type} value={f.value} onChange={e => f.set(e.target.value)}
                className="w-full h-12 pl-10 pr-4 bg-white rounded-xl border border-brand-border text-sm text-brand-text-primary placeholder:text-brand-text-tertiary/50 focus:outline-none focus:border-brand-primary/40 transition-all" />
            </div>
          </div>
        ))}

        {/* Bio */}
        <div>
          <label className="text-xs font-semibold text-brand-text-primary mb-1.5 block">{t('Bio (présentez-vous)')}</label>
          <div className="relative">
            <div className="absolute left-3.5 top-3.5">
              <FileText size={16} className="text-brand-text-tertiary" />
            </div>
            <textarea value={bio} onChange={e => setBio(e.target.value)} rows={4}
              className="w-full pl-10 pr-4 pt-3 bg-white rounded-xl border border-brand-border text-sm text-brand-text-primary placeholder:text-brand-text-tertiary/50 focus:outline-none focus:border-brand-primary/40 transition-all resize-none" />
          </div>
        </div>

        {/* Motivation */}
        <div>
          <label className="text-xs font-semibold text-brand-text-primary mb-1.5 block">{t('Pourquoi devenir mentor ?')}</label>
          <div className="relative">
            <div className="absolute left-3.5 top-3.5">
              <Heart size={16} className="text-brand-text-tertiary" />
            </div>
            <textarea value={motivation} onChange={e => setMotivation(e.target.value)} rows={4}
              className="w-full pl-10 pr-4 pt-3 bg-white rounded-xl border border-brand-border text-sm text-brand-text-primary placeholder:text-brand-text-tertiary/50 focus:outline-none focus:border-brand-primary/40 transition-all resize-none" />
          </div>
        </div>

        {/* Portfolio */}
        <div className="bg-white rounded-2xl border border-brand-border overflow-hidden">
          <button onClick={() => setPortfolioOpen(!portfolioOpen)}
            className="w-full flex items-center justify-between p-4 text-left">
            <div className="flex items-center gap-2">
              <BookOpen size={16} className="text-brand-primary" />
              <span className="font-bold text-sm text-brand-text-primary">{t('Portfolio (optionnel)')}</span>
            </div>
            {portfolioOpen ? <ChevronUp size={18} className="text-brand-text-tertiary" /> : <ChevronDown size={18} className="text-brand-text-tertiary" />}
          </button>

          {portfolioOpen && (
            <div className="px-4 pb-4 space-y-5 border-t border-brand-border pt-4">

              {/* ── Formations ── */}
              <section>
                <div className="flex items-center gap-2 mb-2">
                  <GraduationCap size={14} className="text-brand-primary" />
                  <h3 className="font-bold text-xs uppercase tracking-wider text-brand-text-primary">{t('Formations')}</h3>
                </div>
                <div className="space-y-3">
                  {formations.map((f, i) => (
                    <div key={i} className="flex gap-2 items-start">
                      <div className="flex-1 space-y-2">
                        <input placeholder={t('École / Université')} value={f.ecole} onChange={e => { const a = [...formations]; a[i].ecole = e.target.value; setFormations(a); }}
                          className="w-full h-10 px-3 bg-brand-surface rounded-xl border border-brand-border text-xs outline-none focus:border-brand-primary/40" />
                        <div className="flex gap-2">
                          <input placeholder={t('Diplôme')} value={f.diplome} onChange={e => { const a = [...formations]; a[i].diplome = e.target.value; setFormations(a); }}
                            className="flex-1 h-10 px-3 bg-brand-surface rounded-xl border border-brand-border text-xs outline-none focus:border-brand-primary/40" />
                          <input placeholder={t('Domaine')} value={f.domaine} onChange={e => { const a = [...formations]; a[i].domaine = e.target.value; setFormations(a); }}
                            className="flex-1 h-10 px-3 bg-brand-surface rounded-xl border border-brand-border text-xs outline-none focus:border-brand-primary/40" />
                        </div>
                        <div className="flex gap-2">
                          <input placeholder={t('Année début')} type="number" value={f.annee_debut} onChange={e => { const a = [...formations]; a[i].annee_debut = e.target.value; setFormations(a); }}
                            className="w-28 h-10 px-3 bg-brand-surface rounded-xl border border-brand-border text-xs outline-none focus:border-brand-primary/40" />
                          <input placeholder={t('Année fin')} type="number" value={f.annee_fin} onChange={e => { const a = [...formations]; a[i].annee_fin = e.target.value; setFormations(a); }}
                            className="w-28 h-10 px-3 bg-brand-surface rounded-xl border border-brand-border text-xs outline-none focus:border-brand-primary/40" />
                        </div>
                      </div>
                      <button onClick={() => setFormations(formations.filter((_, j) => j !== i))}
                        className="w-8 h-8 rounded-full bg-brand-error/10 grid place-items-center mt-1 flex-shrink-0">
                        <X size={14} className="text-brand-error" />
                      </button>
                    </div>
                  ))}
                  <button onClick={() => setFormations([...formations, { ecole: '', diplome: '', domaine: '', annee_debut: '', annee_fin: '' }])}
                    className="w-full h-9 rounded-xl border border-dashed border-brand-border text-xs font-semibold text-brand-primary flex items-center justify-center gap-1 hover:bg-brand-primary-surface/30">
                    <Plus size={14} /> {t('Ajouter une formation')}
                  </button>
                </div>
              </section>

              {/* ── Expériences ── */}
              <section>
                <div className="flex items-center gap-2 mb-2">
                  <Building2 size={14} className="text-brand-primary" />
                  <h3 className="font-bold text-xs uppercase tracking-wider text-brand-text-primary">{t('Expériences')}</h3>
                </div>
                <div className="space-y-3">
                  {experiences.map((e, i) => (
                    <div key={i} className="flex gap-2 items-start">
                      <div className="flex-1 space-y-2">
                        <div className="flex gap-2">
                          <input placeholder={t('Poste')} value={e.poste} onChange={ev => { const a = [...experiences]; a[i].poste = ev.target.value; setExperiences(a); }}
                            className="flex-1 h-10 px-3 bg-brand-surface rounded-xl border border-brand-border text-xs outline-none focus:border-brand-primary/40" />
                          <input placeholder={t('Entreprise')} value={e.entreprise} onChange={ev => { const a = [...experiences]; a[i].entreprise = ev.target.value; setExperiences(a); }}
                            className="flex-1 h-10 px-3 bg-brand-surface rounded-xl border border-brand-border text-xs outline-none focus:border-brand-primary/40" />
                        </div>
                        <div className="flex gap-2 items-center">
                          <input placeholder={t('Début (MM-AAAA)')} value={e.debut} onChange={ev => { const a = [...experiences]; a[i].debut = ev.target.value; setExperiences(a); }}
                            className="w-32 h-10 px-3 bg-brand-surface rounded-xl border border-brand-border text-xs outline-none focus:border-brand-primary/40" />
                          {!e.en_cours && (
                            <input placeholder={t('Fin (MM-AAAA)')} value={e.fin} onChange={ev => { const a = [...experiences]; a[i].fin = ev.target.value; setExperiences(a); }}
                              className="w-32 h-10 px-3 bg-brand-surface rounded-xl border border-brand-border text-xs outline-none focus:border-brand-primary/40" />
                          )}
                          <label className="flex items-center gap-1.5 text-[10px] text-brand-text-secondary cursor-pointer whitespace-nowrap">
                            <input type="checkbox" checked={e.en_cours} onChange={ev => { const a = [...experiences]; a[i].en_cours = ev.target.checked; if (ev.target.checked) a[i].fin = ''; setExperiences(a); }}
                              className="w-3.5 h-3.5 rounded border-brand-border accent-brand-primary" />
                            {t('En cours')}
                          </label>
                        </div>
                        <textarea placeholder={t('Description (optionnelle)')} value={e.description} onChange={ev => { const a = [...experiences]; a[i].description = ev.target.value; setExperiences(a); }} rows={2}
                          className="w-full px-3 py-2 bg-brand-surface rounded-xl border border-brand-border text-xs outline-none focus:border-brand-primary/40 resize-none" />
                      </div>
                      <button onClick={() => setExperiences(experiences.filter((_, j) => j !== i))}
                        className="w-8 h-8 rounded-full bg-brand-error/10 grid place-items-center mt-1 flex-shrink-0">
                        <X size={14} className="text-brand-error" />
                      </button>
                    </div>
                  ))}
                  <button onClick={() => setExperiences([...experiences, { poste: '', entreprise: '', debut: '', fin: '', en_cours: false, description: '' }])}
                    className="w-full h-9 rounded-xl border border-dashed border-brand-border text-xs font-semibold text-brand-primary flex items-center justify-center gap-1 hover:bg-brand-primary-surface/30">
                    <Plus size={14} /> {t('Ajouter une expérience')}
                  </button>
                </div>
              </section>

              {/* ── Certifications ── */}
              <section>
                <div className="flex items-center gap-2 mb-2">
                  <Award size={14} className="text-brand-primary" />
                  <h3 className="font-bold text-xs uppercase tracking-wider text-brand-text-primary">{t('Certifications')}</h3>
                </div>
                <div className="space-y-3">
                  {certifications.map((c, i) => (
                    <div key={i} className="flex gap-2 items-start">
                      <div className="flex-1 space-y-2">
                        <div className="flex gap-2">
                          <input placeholder={t('Nom')} value={c.nom} onChange={ev => { const a = [...certifications]; a[i].nom = ev.target.value; setCertifications(a); }}
                            className="flex-1 h-10 px-3 bg-brand-surface rounded-xl border border-brand-border text-xs outline-none focus:border-brand-primary/40" />
                          <input placeholder={t('Organisme')} value={c.organisme} onChange={ev => { const a = [...certifications]; a[i].organisme = ev.target.value; setCertifications(a); }}
                            className="flex-1 h-10 px-3 bg-brand-surface rounded-xl border border-brand-border text-xs outline-none focus:border-brand-primary/40" />
                        </div>
                        <div className="flex gap-2">
                          <input placeholder={t('Année')} type="number" value={c.annee} onChange={ev => { const a = [...certifications]; a[i].annee = ev.target.value; setCertifications(a); }}
                            className="w-24 h-10 px-3 bg-brand-surface rounded-xl border border-brand-border text-xs outline-none focus:border-brand-primary/40" />
                          <input placeholder={t('Lien (optionnel)')} value={c.lien} onChange={ev => { const a = [...certifications]; a[i].lien = ev.target.value; setCertifications(a); }}
                            className="flex-1 h-10 px-3 bg-brand-surface rounded-xl border border-brand-border text-xs outline-none focus:border-brand-primary/40" />
                        </div>
                      </div>
                      <button onClick={() => setCertifications(certifications.filter((_, j) => j !== i))}
                        className="w-8 h-8 rounded-full bg-brand-error/10 grid place-items-center mt-1 flex-shrink-0">
                        <X size={14} className="text-brand-error" />
                      </button>
                    </div>
                  ))}
                  <button onClick={() => setCertifications([...certifications, { nom: '', organisme: '', annee: '', lien: '' }])}
                    className="w-full h-9 rounded-xl border border-dashed border-brand-border text-xs font-semibold text-brand-primary flex items-center justify-center gap-1 hover:bg-brand-primary-surface/30">
                    <Plus size={14} /> {t('Ajouter une certification')}
                  </button>
                </div>
              </section>

              {/* ── Projets ── */}
              <section>
                <div className="flex items-center gap-2 mb-2">
                  <Code size={14} className="text-brand-primary" />
                  <h3 className="font-bold text-xs uppercase tracking-wider text-brand-text-primary">{t('Projets')}</h3>
                </div>
                <div className="space-y-3">
                  {projets.map((p, i) => (
                    <div key={i} className="flex gap-2 items-start">
                      <div className="flex-1 space-y-2">
                        <input placeholder={t('Nom du projet')} value={p.nom} onChange={ev => { const a = [...projets]; a[i].nom = ev.target.value; setProjets(a); }}
                          className="w-full h-10 px-3 bg-brand-surface rounded-xl border border-brand-border text-xs outline-none focus:border-brand-primary/40" />
                        <textarea placeholder={t('Description')} value={p.description} onChange={ev => { const a = [...projets]; a[i].description = ev.target.value; setProjets(a); }} rows={2}
                          className="w-full px-3 py-2 bg-brand-surface rounded-xl border border-brand-border text-xs outline-none focus:border-brand-primary/40 resize-none" />
                        <div className="flex gap-2">
                          <input placeholder={t('Lien')} value={p.lien} onChange={ev => { const a = [...projets]; a[i].lien = ev.target.value; setProjets(a); }}
                            className="flex-1 h-10 px-3 bg-brand-surface rounded-xl border border-brand-border text-xs outline-none focus:border-brand-primary/40" />
                          <input placeholder={t('Technologies (ex: Flutter, Python)')} value={p.technologies} onChange={ev => { const a = [...projets]; a[i].technologies = ev.target.value; setProjets(a); }}
                            className="flex-1 h-10 px-3 bg-brand-surface rounded-xl border border-brand-border text-xs outline-none focus:border-brand-primary/40" />
                        </div>
                      </div>
                      <button onClick={() => setProjets(projets.filter((_, j) => j !== i))}
                        className="w-8 h-8 rounded-full bg-brand-error/10 grid place-items-center mt-1 flex-shrink-0">
                        <X size={14} className="text-brand-error" />
                      </button>
                    </div>
                  ))}
                  <button onClick={() => setProjets([...projets, { nom: '', description: '', lien: '', technologies: '' }])}
                    className="w-full h-9 rounded-xl border border-dashed border-brand-border text-xs font-semibold text-brand-primary flex items-center justify-center gap-1 hover:bg-brand-primary-surface/30">
                    <Plus size={14} /> {t('Ajouter un projet')}
                  </button>
                </div>
              </section>

              {/* ── Langues ── */}
              <section>
                <div className="flex items-center gap-2 mb-2">
                  <Languages size={14} className="text-brand-primary" />
                  <h3 className="font-bold text-xs uppercase tracking-wider text-brand-text-primary">{t('Langues')}</h3>
                </div>
                <div className="space-y-2">
                  {langues.map((l, i) => (
                    <div key={i} className="flex gap-2 items-start">
                      <div className="flex-1 flex gap-2">
                        <input placeholder={t('Langue')} value={l.langue} onChange={ev => { const a = [...langues]; a[i].langue = ev.target.value; setLangues(a); }}
                          className="flex-1 h-10 px-3 bg-brand-surface rounded-xl border border-brand-border text-xs outline-none focus:border-brand-primary/40" />
                        <select value={l.niveau} onChange={ev => { const a = [...langues]; a[i].niveau = ev.target.value; setLangues(a); }}
                          className="flex-1 h-10 px-3 bg-brand-surface rounded-xl border border-brand-border text-xs outline-none focus:border-brand-primary/40">
                          <option value="">{t('Niveau')}</option>
                          <option value="Débutant">{t('Débutant')}</option>
                          <option value="Intermédiaire">{t('Intermédiaire')}</option>
                          <option value="Avancé">{t('Avancé')}</option>
                          <option value="Courant">{t('Courant')}</option>
                          <option value="Natif">{t('Natif')}</option>
                        </select>
                      </div>
                      <button onClick={() => setLangues(langues.filter((_, j) => j !== i))}
                        className="w-8 h-8 rounded-full bg-brand-error/10 grid place-items-center mt-1 flex-shrink-0">
                        <X size={14} className="text-brand-error" />
                      </button>
                    </div>
                  ))}
                  <button onClick={() => setLangues([...langues, { langue: '', niveau: '' }])}
                    className="w-full h-9 rounded-xl border border-dashed border-brand-border text-xs font-semibold text-brand-primary flex items-center justify-center gap-1 hover:bg-brand-primary-surface/30">
                    <Plus size={14} /> {t('Ajouter une langue')}
                  </button>
                </div>
              </section>

              {/* ── Liens ── */}
              <section>
                <div className="flex items-center gap-2 mb-2">
                  <Globe size={14} className="text-brand-primary" />
                  <h3 className="font-bold text-xs uppercase tracking-wider text-brand-text-primary">{t('Liens')}</h3>
                </div>
                <div className="space-y-2">
                  {liens.map((l, i) => (
                    <div key={i} className="flex gap-2 items-start">
                      <div className="flex-1 flex gap-2">
                        <select value={l.type} onChange={ev => { const a = [...liens]; a[i].type = ev.target.value; setLiens(a); }}
                          className="w-28 h-10 px-3 bg-brand-surface rounded-xl border border-brand-border text-xs outline-none focus:border-brand-primary/40">
                          <option value="website">{t('Site web')}</option>
                          <option value="github">GitHub</option>
                          <option value="twitter">Twitter</option>
                          <option value="linkedin">LinkedIn</option>
                          <option value="other">{t('Autre')}</option>
                        </select>
                        <input placeholder={t('URL')} value={l.url} onChange={ev => { const a = [...liens]; a[i].url = ev.target.value; setLiens(a); }}
                          className="flex-1 h-10 px-3 bg-brand-surface rounded-xl border border-brand-border text-xs outline-none focus:border-brand-primary/40" />
                      </div>
                      <button onClick={() => setLiens(liens.filter((_, j) => j !== i))}
                        className="w-8 h-8 rounded-full bg-brand-error/10 grid place-items-center mt-1 flex-shrink-0">
                        <X size={14} className="text-brand-error" />
                      </button>
                    </div>
                  ))}
                  <button onClick={() => setLiens([...liens, { type: 'website', url: '' }])}
                    className="w-full h-9 rounded-xl border border-dashed border-brand-border text-xs font-semibold text-brand-primary flex items-center justify-center gap-1 hover:bg-brand-primary-surface/30">
                    <Plus size={14} /> {t('Ajouter un lien')}
                  </button>
                </div>
              </section>

            </div>
          )}
        </div>

        {/* Error */}
        {errorMsg && (
          <div className="bg-brand-error/10 border border-brand-error/20 rounded-xl p-3 text-xs text-brand-error-dark font-semibold">
            {errorMsg}
          </div>
        )}

        {/* Submit */}
        <button onClick={handleSubmit} disabled={submitting || !fullName || !email || !specialty}
          className={`w-full h-14 rounded-full font-bold text-base flex items-center justify-center gap-2 transition-all ${
            submitting || !fullName || !email || !specialty
              ? 'bg-brand-border text-brand-text-tertiary cursor-not-allowed'
              : 'bg-brand-primary text-white shadow-glow hover:bg-brand-primary-light'
          }`}>
          {submitting ? (
            <><Loader2 size={18} className="animate-spin" /> {t('Envoi...')}</>
          ) : (
            <><Send size={18} /> {t('Envoyer ma candidature')}</>
          )}
        </button>
      </div>
    </div>
  );
}
