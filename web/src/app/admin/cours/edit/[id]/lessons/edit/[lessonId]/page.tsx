"use client";

import React, { useState, useEffect } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import { Button } from "@/components/ui/Button";
import { Card } from "@/components/ui/Card";
import { Input } from "@/components/ui/Input";
import { ArrowLeft, Save, Plus, Trash2, Video, FileText, HelpCircle } from "lucide-react";

export default function AdminEditLessonPage({ params }: { params: Promise<{ id: string, lessonId: string }> }) {
  const unwrappedParams = React.use(params);
  const router = useRouter();
  const [loading, setLoading] = useState(false);
  const [initialLoad, setInitialLoad] = useState(true);
  
  const [title, setTitle] = useState("");
  const [description, setDescription] = useState("");
  const [rewardXp, setRewardXp] = useState(50);
  const [contentBlocks, setContentBlocks] = useState<any[]>([]);

  useEffect(() => {
    fetch(`/api/admin/courses/${unwrappedParams.id}/lessons/${unwrappedParams.lessonId}`)
      .then(res => res.json())
      .then(data => {
        if (data && !data.error) {
          setTitle(data.title || "");
          setDescription(data.description || "");
          setRewardXp(data.rewardXp || 50);
          
          // Inject an ID to blocks if they don't have one (for React keys)
          const blocks = Array.isArray(data.content) ? data.content.map((b: any, i: number) => ({
            ...b,
            id: b.id || `${Date.now()}-${i}`
          })) : [];
          setContentBlocks(blocks);
        }
        setInitialLoad(false);
      })
      .catch(err => {
        console.error(err);
        setInitialLoad(false);
      });
  }, [unwrappedParams.id, unwrappedParams.lessonId]);

  const addBlock = (type: string) => {
    let newBlock: any = { id: Date.now().toString(), type, title: "" };
    if (type === "theory") newBlock.content = "";
    if (type === "video") newBlock.url = "";
    if (type === "quiz") {
      newBlock.content = "";
      newBlock.options = ["", ""];
      newBlock.correctOptionIndex = 0;
    }
    setContentBlocks([...contentBlocks, newBlock]);
  };

  const removeBlock = (id: string) => {
    setContentBlocks(contentBlocks.filter(b => b.id !== id));
  };

  const updateBlock = (id: string, field: string, value: any) => {
    setContentBlocks(contentBlocks.map(b => b.id === id ? { ...b, [field]: value } : b));
  };

  const updateQuizOption = (blockId: string, index: number, value: string) => {
    setContentBlocks(contentBlocks.map(b => {
      if (b.id === blockId) {
        const newOptions = [...b.options];
        newOptions[index] = value;
        return { ...b, options: newOptions };
      }
      return b;
    }));
  };

  const addQuizOption = (blockId: string) => {
    setContentBlocks(contentBlocks.map(b => {
      if (b.id === blockId) {
        return { ...b, options: [...b.options, ""] };
      }
      return b;
    }));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    
    // Clean up IDs before saving
    const cleanBlocks = contentBlocks.map(b => {
      const { id, ...rest } = b;
      return rest;
    });

    try {
      const res = await fetch(`/api/admin/courses/${unwrappedParams.id}/lessons/${unwrappedParams.lessonId}`, {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          title,
          description,
          rewardXp,
          content: cleanBlocks
        })
      });
      
      if (res.ok) {
        router.push(`/admin/cours/edit/${unwrappedParams.id}`);
      } else {
        alert("Erreur lors de la modification");
      }
    } catch (err) {
      console.error(err);
      alert("Erreur réseau");
    } finally {
      setLoading(false);
    }
  };

  if (initialLoad) return <div className="p-8 text-center text-text-secondary">Chargement...</div>;

  return (
    <div className="flex flex-col gap-6 max-w-4xl mx-auto animate-fade-in pb-20">
      <div className="flex items-center gap-4 mb-4">
        <Link href={`/admin/cours/edit/${unwrappedParams.id}`} className="p-2 bg-surface border border-border-soft rounded-full hover:bg-surface-alt transition-colors">
          <ArrowLeft className="w-5 h-5 text-text-secondary" />
        </Link>
        <div>
          <h1 className="text-2xl font-display font-bold text-text-primary">Modifier la Leçon</h1>
          <p className="text-sm text-text-secondary">Gérez le contenu de cette étape d'apprentissage.</p>
        </div>
      </div>

      <form onSubmit={handleSubmit} className="flex flex-col gap-6">
        <Card variant="standard" className="p-6 flex flex-col gap-5">
          <h2 className="text-lg font-bold text-text-primary border-b border-border-soft pb-2">Informations Générales</h2>
          <div className="flex flex-col gap-2">
            <label className="text-sm font-bold text-text-primary">Titre de la leçon</label>
            <Input value={title} onChange={(e) => setTitle(e.target.value)} required placeholder="Ex: Les bases de la communication" />
          </div>
          <div className="flex flex-col gap-2">
            <label className="text-sm font-bold text-text-primary">Description (Optionnelle)</label>
            <Input value={description} onChange={(e) => setDescription(e.target.value)} placeholder="Bref résumé de la leçon" />
          </div>
          <div className="flex flex-col gap-2">
            <label className="text-sm font-bold text-text-primary">Récompense en XP</label>
            <Input type="number" value={rewardXp} onChange={(e) => setRewardXp(parseInt(e.target.value) || 0)} required />
          </div>
        </Card>

        <div className="flex flex-col gap-4">
          <div className="flex items-center justify-between">
            <h2 className="text-lg font-bold text-text-primary">Contenu de la leçon</h2>
            <div className="flex items-center gap-2">
              <Button type="button" variant="outline" onClick={() => addBlock("theory")} className="flex items-center gap-2 text-xs py-1 px-3">
                <FileText className="w-3.5 h-3.5" /> Théorie
              </Button>
              <Button type="button" variant="outline" onClick={() => addBlock("video")} className="flex items-center gap-2 text-xs py-1 px-3">
                <Video className="w-3.5 h-3.5" /> Vidéo
              </Button>
              <Button type="button" variant="outline" onClick={() => addBlock("quiz")} className="flex items-center gap-2 text-xs py-1 px-3">
                <HelpCircle className="w-3.5 h-3.5" /> Quiz
              </Button>
            </div>
          </div>

          {contentBlocks.length === 0 ? (
            <div className="p-10 text-center bg-surface-alt border border-dashed border-border-strong rounded-xl text-text-secondary">
              Commencez par ajouter un bloc de contenu ci-dessus.
            </div>
          ) : (
            <div className="flex flex-col gap-6">
              {contentBlocks.map((block, index) => (
                <Card key={block.id} variant="standard" className="p-5 border-l-4 border-l-primary relative">
                  <button 
                    type="button" 
                    onClick={() => removeBlock(block.id)}
                    className="absolute top-4 right-4 text-text-tertiary hover:text-error transition-colors"
                  >
                    <Trash2 className="w-5 h-5" />
                  </button>
                  
                  <div className="flex items-center gap-2 mb-4 text-primary font-bold">
                    {block.type === "theory" && <FileText className="w-5 h-5" />}
                    {block.type === "video" && <Video className="w-5 h-5" />}
                    {block.type === "quiz" && <HelpCircle className="w-5 h-5" />}
                    <span>Bloc {index + 1} : {block.type === "theory" ? "Texte" : block.type === "video" ? "Vidéo" : "Question Quiz"}</span>
                  </div>

                  <div className="flex flex-col gap-4">
                    <div className="flex flex-col gap-2">
                      <label className="text-xs font-bold text-text-secondary">Titre du bloc</label>
                      <Input value={block.title || ""} onChange={(e) => updateBlock(block.id, "title", e.target.value)} placeholder="Ex: Définition de la communication" />
                    </div>

                    {block.type === "theory" && (
                      <div className="flex flex-col gap-2">
                        <label className="text-xs font-bold text-text-secondary">Contenu texte (Markdown supporté)</label>
                        <textarea 
                          value={block.content || ""} 
                          onChange={(e) => updateBlock(block.id, "content", e.target.value)}
                          rows={5}
                          className="w-full px-4 py-3 bg-surface border border-border-soft rounded-xl text-text-primary focus:outline-none focus:border-primary transition-colors resize-y"
                        />
                      </div>
                    )}

                    {block.type === "video" && (
                      <div className="flex flex-col gap-2">
                        <label className="text-xs font-bold text-text-secondary">URL de la vidéo (YouTube, etc.)</label>
                        <Input value={block.url || ""} onChange={(e) => updateBlock(block.id, "url", e.target.value)} placeholder="https://www.youtube.com/watch?v=..." />
                      </div>
                    )}

                    {block.type === "quiz" && (
                      <div className="flex flex-col gap-4 p-4 bg-surface-alt rounded-xl border border-border-soft">
                        <div className="flex flex-col gap-2">
                          <label className="text-xs font-bold text-text-secondary">Question</label>
                          <Input value={block.content || ""} onChange={(e) => updateBlock(block.id, "content", e.target.value)} placeholder="Quelle est la capitale du Togo ?" />
                        </div>
                        
                        <div className="flex flex-col gap-2">
                          <label className="text-xs font-bold text-text-secondary">Options de réponse</label>
                          {(block.options || []).map((opt: string, optIdx: number) => (
                            <div key={optIdx} className="flex items-center gap-3">
                              <input 
                                type="radio" 
                                name={`correct-${block.id}`} 
                                checked={block.correctOptionIndex === optIdx}
                                onChange={() => updateBlock(block.id, "correctOptionIndex", optIdx)}
                                className="w-4 h-4 text-primary focus:ring-primary"
                                title="Cocher si c'est la bonne réponse"
                              />
                              <Input 
                                value={opt} 
                                onChange={(e) => updateQuizOption(block.id, optIdx, e.target.value)} 
                                placeholder={`Option ${optIdx + 1}`} 
                              />
                            </div>
                          ))}
                          <Button type="button" variant="outline" onClick={() => addQuizOption(block.id)} className="w-fit mt-2 text-xs py-1">
                            + Ajouter une option
                          </Button>
                        </div>
                      </div>
                    )}
                  </div>
                </Card>
              ))}
            </div>
          )}
        </div>

        <div className="flex justify-end gap-4 mt-8">
          <Link href={`/admin/cours/edit/${unwrappedParams.id}`}>
            <Button variant="secondary" type="button">Annuler</Button>
          </Link>
          <Button type="submit" disabled={loading} className="flex items-center gap-2">
            <Save className="w-4 h-4" /> {loading ? "Enregistrement..." : "Enregistrer la leçon"}
          </Button>
        </div>
      </form>
    </div>
  );
}
