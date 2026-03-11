"""
Service LLM ActivEducation — AÏDA avec Groq + fallback Ollama

AÏDA : Assistante d'orientation virtuelle.
- Provider principal : Groq (gratuit, 14 400 req/jour) avec llama-3.1-8b-instant
- Fallback local  : Ollama (auto-hébergé, 0 coût, 0 dépendance externe)
- Garde-fous      : strictement limitée au domaine éducatif

Obtenir une clé Groq gratuite : https://console.groq.com
Installer Ollama              : https://ollama.com
"""

import os
import uuid
import logging
from pathlib import Path
from typing import Optional
import httpx
from dotenv import load_dotenv

# Charger le .env pour que GROQ_API_KEY et OLLAMA_* soient disponibles
# (pydantic-settings ne charge que les champs de Settings, pas les variables custom)
_env_path = Path(__file__).resolve().parents[2] / ".env"
load_dotenv(_env_path)

logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Configuration Groq
# ---------------------------------------------------------------------------

GROQ_API_URL = "https://api.groq.com/openai/v1/chat/completions"
GROQ_MODEL = "llama-3.1-8b-instant"   # Gratuit, rapide, ~8k tokens context
GROQ_TIMEOUT = 30.0

# ---------------------------------------------------------------------------
# Configuration Ollama (fallback local)
# ---------------------------------------------------------------------------

OLLAMA_BASE_URL = os.environ.get("OLLAMA_BASE_URL", "http://localhost:11434").rstrip("/")
OLLAMA_MODEL = os.environ.get("OLLAMA_MODEL", "llama3.1:8b")
OLLAMA_TIMEOUT = 90.0  # Plus long car inférence locale

# ---------------------------------------------------------------------------
# Configuration commune
# ---------------------------------------------------------------------------

MAX_TOKENS = 800
TEMPERATURE = 0.7

# Historique en mémoire : {session_id: [messages]}
_sessions: dict[str, list[dict]] = {}
MAX_SESSIONS = 1000
MAX_HISTORY = 10       # Messages conservés par session (5 échanges, laisse ~4k tokens pour le system prompt)

# ---------------------------------------------------------------------------
# Base de connaissances — écoles et métiers réels au Togo
# Format compact pour rester dans le contexte 8k tokens du LLM
# ---------------------------------------------------------------------------

_KNOWLEDGE_BASE = """\

**BASE DE DONNÉES — ÉCOLES AU TOGO (utilise UNIQUEMENT ces données) :**

1. Université de Lomé | public | Lomé | 1970 | 65 000 étudiants | 50-150K FCFA/an | CAMES, REESAO
   Filières : Sciences, Médecine, Droit, Lettres, Économie, Génie Civil, Informatique
   Programmes : Génie Logiciel et IA (Licence 3 ans), Droit des Affaires (Master 2 ans), Médecine (Doctorat 7 ans), Économie et Gestion (Licence 3 ans), Génie Civil (Master 5 ans)

2. Université de Kara | public | Kara | 2004 | 15 000 étudiants | 50-120K FCFA/an | CAMES, REESAO
   Filières : Agronomie, Droit, Lettres, Sciences, Économie
   Programmes : Agronomie et Sciences Environnementales (Licence 3 ans), Droit Public (Licence 3 ans), Lettres Modernes (Licence 3 ans)

3. UCAO-UUT (Université Catholique de l'Afrique de l'Ouest) | privé | Lomé | 1999 | 4 500 étudiants | 500K-1,2M FCFA/an | CAMES, HCERES
   Filières : Droit, Économie, Gestion, Informatique, Communication
   Programmes : Droit Privé et Sciences Criminelles (Master 2 ans), Sciences Économiques (Licence 3 ans), Informatique de Gestion (Licence 3 ans), Communication et Marketing (Master 2 ans)

4. ESA - École Supérieure des Affaires | privé | Lomé | 2002 | 2 000 étudiants | 600K-1,5M FCFA/an | CAMES
   Filières : Management, Finance, Marketing, Comptabilité, Entrepreneuriat
   Programmes : Management des Organisations (Master 2 ans), Finance et Comptabilité (Licence 3 ans), Marketing et Stratégie (Master 2 ans), Entrepreneuriat et Innovation (Licence 3 ans)

5. ESIBA Business School | privé | Lomé | 2010 | 1 200 étudiants | 450-900K FCFA/an | CAMES
   Filières : Marketing Digital, Commerce International, Management, RH
   Programmes : Marketing Digital (Licence 3 ans), Commerce International (Licence 3 ans), GRH (Master 2 ans)

6. IPNET Institute | privé | Lomé | 2008 | 800 étudiants | 300-800K FCFA/an | Cisco Academy, Microsoft Partner
   Filières : Réseaux, Cybersécurité, Cloud Computing, Développement Web, CISCO
   Programmes : Admin Réseaux et Systèmes (BTS 2 ans), Cybersécurité (Licence 3 ans), Cloud Computing et DevOps (Licence 3 ans), Développement Web et Mobile (BTS 2 ans)

7. IAEC Togo | privé | Lomé | 1995 | 1 500 étudiants | 350-700K FCFA/an | CAMES
   Filières : Comptabilité, Gestion Commerciale, Banque Finance, Transit Douane
   Programmes : Comptabilité et Gestion (BTS 2 ans), Banque et Finance (Licence 3 ans), Transit et Logistique (BTS 2 ans)

8. ISM Adonaï | privé | Lomé | 2005 | 900 étudiants | 300-650K FCFA/an | CAMES
   Filières : Management, Informatique de Gestion, Communication, Logistique
   Programmes : Management (Licence 3 ans), Informatique de Gestion (BTS 2 ans), Logistique et Transport (Licence 3 ans)

9. ESGIS | privé | Lomé | 2002 | 3 500 étudiants | 500K-1,1M FCFA/an | CAMES, HCERES
   Filières : Informatique, Gestion, Droit, Sciences de la Santé, Génie Civil
   Programmes : Génie Informatique (Licence 3 ans), Sciences Juridiques (Master 2 ans), Gestion et Management (Licence 3 ans), Génie Civil (Licence 3 ans)

10. FORMATEC | privé | Lomé | 2000 | 600 étudiants | 200-500K FCFA/an | MEPT
    Filières : Électricité, Mécanique, BTP, Froid et Climatisation, Maintenance Industrielle
    Programmes : Électricité Industrielle (BTS 2 ans), Froid et Climatisation (BTS 2 ans), Maintenance Industrielle (BTS 2 ans)

Autres écoles : ENS Atakpamé (enseignants), ENAM (auxiliaires médicaux + administration), ENSI (ingénierie UL), ESTBA (sciences biomédicales UL), EAMAU (architecture, Lomé), IAI-TOGO (informatique), ISICA (journalisme), INFA de Tové (agriculture), ESAG-NDE (commerce/gestion). Incubateurs : Woelab, CUBE, FAIEJ.

**BASE DE DONNÉES — MÉTIERS (44 métiers, salaires mensuels en FCFA) :**

TECHNOLOGIE & INFORMATIQUE :
- Développeur Logiciel | BAC+3 | 150-800K | UL, ESIBA, IAI-TOGO, ESGIS | Forte ↑
- Analyste de Données | BAC+3 | 200-700K | ENSEA, UL | Forte ↑
- Développeur Mobile | BAC+2 | 150-700K | IAI-TOGO, ESIBA, ESGIS | Forte ↑
- Admin Systèmes & Réseaux | BAC+2 | 150-600K | IAI-TOGO, ESIBA, UL-IUT | Forte ↑
- Chef de Projet IT | BAC+3 | 250-900K | ESGIS, ESAG-NDE, UL | Forte ↑
- Designer UX/UI | BAC+2 | 150-700K | Formations en ligne, IBTC | Forte ↑

SANTÉ :
- Médecin Généraliste | BAC+7 | 300K-1,5M | Fac Santé UL | Forte →
- Infirmier(e) | BAC+3 | 120-400K | ENAM, ESTBA-UL | Forte ↑
- Pharmacien | BAC+6 | 300K-1M | Fac Santé UL | Moyenne →
- Sage-Femme | BAC+3 | 120-450K | ENAM, ESTBA-UL | Forte ↑
- Technicien Labo | BAC+2 | 100-350K | ENAM, Fac Sciences UL | Forte →

ÉDUCATION :
- Enseignant | BAC+3 | 100-350K | ENS Atakpamé, UL | Forte →
- Formateur Pro | BAC+3 | 120-500K | ENS, FASEG-UL, UCAO | Forte ↑
- Conseiller Orientation | BAC+3 | 100-300K | ENS, UL-Psycho | Moyenne ↑
- Resp. Pédagogique | BAC+5 | 200-800K | ENS, UL, UCAO | Moyenne →

FINANCE & BANQUE :
- Comptable | BAC+2 | 120-600K | ESAG-NDE, UCAO, FASEG-UL, ESGIS | Forte →
- Agent Bancaire | BAC+3 | 200-800K | FASEG-UL, ESAG-NDE, UCAO | Moyenne →
- Analyste Financier | BAC+4 | 300K-1,2M | FASEG-UL, ESAG-NDE, ESGIS | Moyenne ↑
- Agent Assurance | BAC+2 | 100-600K | ESAG-NDE, UCAO, UL | Moyenne ↑
- Contrôleur Gestion | BAC+4 | 280K-1M | FASEG-UL, ESAG-NDE, ESGIS | Forte →

COMMERCE & ENTREPRENEURIAT :
- Commercial | BAC+2 | 100-700K | ESAG-NDE, ESGIS, UCAO | Forte ↑
- Entrepreneur | Variable | 0-5M+ | Woelab, CUBE, FAIEJ | Forte ↑
- Resp. Marketing Digital | BAC+3 | 120-700K | ESAG-NDE, ESGIS, UCAO | Forte ↑
- Logisticien Import-Export | BAC+2 | 150-700K | FASEG-UL, ESAG-NDE | Forte ↑

INGÉNIERIE & BTP :
- Ingénieur Civil | BAC+5 | 250K-1,2M | ENSI-UL, FORMATEC | Forte ↑
- Architecte | BAC+5 | 200K-1M | EAMAU Lomé | Moyenne ↑
- Ingénieur Électricien | BAC+3 | 200-900K | ENSI-UL, IUT, FORMATEC | Forte ↑
- Topographe | BAC+2 | 150-600K | IUT-UL, INFA Tové | Forte ↑
- Technicien Mécanique | BAC | 100-500K | CFPT, IUT-UL | Forte →

AGRICULTURE & ENVIRONNEMENT :
- Ingénieur Agronome | BAC+5 | 150-700K | ESA-UL, INFA Tové | Forte ↑
- Vétérinaire | BAC+5 | 200-800K | Bénin, Maroc, Sénégal | Forte ↑
- Ing. Environnement | BAC+5 | 200-900K | UL-Sciences, INFA | Forte ↑
- Tech. Agroalimentaire | BAC+2 | 120-450K | UL-Sciences, INFA, ITRA | Forte ↑

CRÉATION & MÉDIAS :
- Designer Graphique | BAC+2 | 80-450K | IBTC, formations privées | Forte ↑
- Journaliste | BAC+3 | 80-400K | ISICA, UL-Communication | Moyenne →
- Photographe/Vidéaste | BAC | 80-600K | Formations privées | Forte ↑
- Créateur Contenu/CM | BAC | 80-500K | ISICA, formations en ligne | Forte ↑

DROIT & ADMINISTRATION :
- Avocat | BAC+5 | 200K-2M | Fac Droit UL | Moyenne →
- Responsable RH | BAC+3 | 150-700K | FASEG-UL, ESAG-NDE, UCAO | Moyenne ↑
- Notaire | BAC+6 | 400K-3M | Fac Droit UL | Moyenne →
- Administrateur Civil | BAC+3 | 150-600K | ENAM, UL-Droit | Moyenne →
- Juriste d'Entreprise | BAC+4 | 250K-1M | Fac Droit UL, ESGIS | Forte ↑

Employeurs majeurs au Togo : TOGOCOM, Moov Africa, Gozem, Semoa, Ecobank, ORABANK, BTCI, UTB, Coris Bank, CEET, OTP, NSIA, CHU Sylvanus Olympio, BCEAO, Port Autonome de Lomé.
"""

# ---------------------------------------------------------------------------
# Prompts système — avec garde-fous éducatifs stricts
# ---------------------------------------------------------------------------

_GUARDRAILS = """\

**RESTRICTION ABSOLUE — Domaine éducatif uniquement :**
Tu ne réponds QU'AUX questions liées à l'éducation et l'orientation. Voici ton périmètre :

Sujets AUTORISÉS :
- Orientation scolaire et professionnelle (RIASEC, personnalité, compétences)
- Filières d'études (lycée, université, BTS, formations professionnelles)
- Métiers, débouchés et salaires dans le contexte africain
- Écoles et universités (Togo, Afrique de l'Ouest, international)
- Bourses d'études et financements de formation
- Examens (BAC, CAMES, concours d'entrée)
- Conseils d'apprentissage et méthodes de travail
- Vie étudiante et gestion du stress scolaire
- Stages, alternance et insertion professionnelle
- Compétences et développement personnel lié à la carrière
- Entrepreneuriat et création d'entreprise (dans un contexte éducatif)

Sujets INTERDITS (refuse poliment et redirige) :
- Politique, actualités, élections
- Religion, spiritualité, croyances
- Contenus pour adultes, violence
- Conseils médicaux ou juridiques
- Divertissement général (films, musique, jeux sauf si lié à une filière)
- Aide aux devoirs ou résolution d'exercices (tu orientes, tu ne fais pas les devoirs)
- Programmation/code (sauf pour expliquer la filière informatique)
- Toute question sans rapport avec l'éducation ou l'orientation

Si une question est hors-sujet, réponds EXACTEMENT avec ce format :
"Je suis spécialisée uniquement en orientation scolaire et professionnelle, \
je ne peux pas t'aider sur ce sujet. 😊 Mais si tu as une question sur tes études, \
tes choix de filière ou ton avenir professionnel, je suis là ! \
Qu'est-ce qui t'intéresse ?"
"""

_SYSTEM_BASE = """\
Tu es AÏDA, conseillère d'orientation virtuelle de la plateforme ActivEducation, \
dédiée aux lycéens et étudiants au Togo et en Afrique de l'Ouest.

**Ton rôle :**
- Aider les élèves à comprendre leur profil d'orientation (RIASEC, personnalité, compétences)
- Explorer les filières et métiers adaptés au contexte togolais et ouest-africain
- Conseiller sur les parcours académiques (lycée, université, formations professionnelles)
- Donner des informations réalistes sur les salaires en FCFA et les débouchés locaux
- Encourager et motiver chaque élève dans son projet d'avenir

**Règles absolues :**
- Réponds TOUJOURS en français, avec un ton chaleureux et bienveillant
- Sois concis : 3 à 5 phrases maximum sauf si plus de détail est demandé
- Utilise le contexte africain (FCFA, marché de l'emploi togolais, CEDEAO)
- Base tes réponses UNIQUEMENT sur la base de données ci-dessous. N'invente aucune école, aucun programme ni aucun chiffre.
- Si tu ne sais pas quelque chose, dis-le honnêtement et oriente vers une démarche
- Termine toujours sur une note encourageante
""" + _GUARDRAILS + _KNOWLEDGE_BASE

_SYSTEM_WITH_CONTEXT = """\
Tu es AÏDA, conseillère d'orientation virtuelle de la plateforme ActivEducation, \
dédiée aux lycéens et étudiants au Togo et en Afrique de l'Ouest.

**Ton rôle :**
- Aider les élèves à comprendre leur profil d'orientation (RIASEC, personnalité, compétences)
- Explorer les filières et métiers adaptés au contexte togolais et ouest-africain
- Conseiller sur les parcours académiques (lycée, université, formations professionnelles)
- Donner des informations réalistes sur les salaires en FCFA et les débouchés locaux
- Encourager et motiver chaque élève dans son projet d'avenir

**Règles absolues :**
- Réponds TOUJOURS en français, avec un ton chaleureux et bienveillant
- Sois concis : 3 à 5 phrases maximum sauf si plus de détail est demandé
- Utilise le contexte africain (FCFA, marché de l'emploi togolais, CEDEAO)
- Base tes réponses UNIQUEMENT sur la base de données ci-dessous. N'invente aucune école, aucun programme ni aucun chiffre.
- Si tu ne sais pas quelque chose, dis-le honnêtement et oriente vers une démarche
- Termine toujours sur une note encourageante
""" + _GUARDRAILS + _KNOWLEDGE_BASE + """
**Profil de l'élève (résultats d'orientation) :**
{context_block}

Utilise ces informations pour personnaliser chaque réponse. \
L'élève vient de recevoir ces résultats et a peut-être des questions ou des doutes.
"""


class LLMService:
    """
    Service conversationnel AÏDA — Groq (principal) + Ollama (fallback).

    Stratégie :
    1. Si GROQ_API_KEY est configurée → tenter Groq en priorité
    2. Si Groq échoue (429, timeout, 5xx) → fallback vers Ollama
    3. Si GROQ_API_KEY absente → utiliser directement Ollama
    4. Si aucun provider disponible → message d'erreur gracieux
    """

    def __init__(self) -> None:
        # --- Groq ---
        self._groq_api_key = os.environ.get("GROQ_API_KEY", "").strip()
        self._groq_enabled = bool(self._groq_api_key)

        # --- Ollama ---
        self._ollama_url = OLLAMA_BASE_URL
        self._ollama_model = OLLAMA_MODEL
        self._ollama_available: Optional[bool] = None  # Vérifié au premier appel

        # --- Log de démarrage ---
        providers = []
        if self._groq_enabled:
            providers.append(f"Groq ({GROQ_MODEL})")
        providers.append(f"Ollama ({self._ollama_model} @ {self._ollama_url})")

        if self._groq_enabled:
            logger.info(
                "AÏDA initialisée — Groq (principal) + Ollama (fallback). "
                "Providers : %s", ", ".join(providers)
            )
        else:
            logger.info(
                "AÏDA initialisée — GROQ_API_KEY absente, Ollama sera utilisé "
                "comme provider unique (%s @ %s)",
                self._ollama_model, self._ollama_url,
            )

    # ------------------------------------------------------------------
    # API publique
    # ------------------------------------------------------------------

    async def chat(
        self,
        message: str,
        session_id: str,
        orientation_context: Optional[dict] = None,
        client_history: Optional[list[dict]] = None,
    ) -> dict:
        """
        Envoie un message à AÏDA et retourne sa réponse.

        Args:
            client_history: Historique envoyé par le client pour reconstruire
                            le contexte après un redémarrage du serveur.
                            N'est utilisé que si la session est inconnue.

        Returns:
            {"reply": str, "session_id": str}
        """
        history = _sessions.get(session_id, [])

        # Session seeding : si le backend ne connaît pas la session mais que
        # le client a envoyé son historique local, on reconstruit le contexte.
        if not history and client_history:
            history = [
                {"role": m["role"], "content": m["content"]}
                for m in client_history
                if m.get("role") in ("user", "assistant") and m.get("content")
            ][-MAX_HISTORY:]
            logger.info(
                "Session %s restaurée depuis l'historique client (%d messages)",
                session_id, len(history),
            )
        system_prompt = self._build_system_prompt(orientation_context)

        messages: list[dict] = [{"role": "system", "content": system_prompt}]
        messages.extend(history[-MAX_HISTORY:])
        messages.append({"role": "user", "content": message})

        reply: Optional[str] = None

        # --- Stratégie de fallback ---
        if self._groq_enabled:
            reply = await self._call_groq(messages)

        if reply is None:
            reply = await self._call_ollama(messages)

        if reply is None:
            # Aucun provider disponible
            return {
                "reply": (
                    "Je suis AÏDA, votre conseillère d'orientation. "
                    "Le service est temporairement indisponible — "
                    "ni Groq ni le modèle local ne sont joignables. "
                    "Réessaie dans quelques instants !"
                ),
                "session_id": session_id,
            }

        # --- Mise à jour de l'historique ---
        history = list(history)
        history.append({"role": "user", "content": message})
        history.append({"role": "assistant", "content": reply})

        if len(_sessions) >= MAX_SESSIONS and session_id not in _sessions:
            oldest = next(iter(_sessions))
            del _sessions[oldest]

        _sessions[session_id] = history

        return {"reply": reply, "session_id": session_id}

    def clear_session(self, session_id: str) -> None:
        """Efface l'historique d'une session."""
        _sessions.pop(session_id, None)

    def get_history(self, session_id: str) -> list[dict]:
        """Retourne l'historique brut d'une session."""
        return list(_sessions.get(session_id, []))

    @staticmethod
    def new_session_id() -> str:
        """Génère un identifiant de session unique."""
        return str(uuid.uuid4())

    # ------------------------------------------------------------------
    # Providers privés
    # ------------------------------------------------------------------

    async def _call_groq(self, messages: list[dict]) -> Optional[str]:
        """Appelle l'API Groq. Retourne None en cas d'échec (fallback)."""
        try:
            async with httpx.AsyncClient(timeout=GROQ_TIMEOUT) as client:
                response = await client.post(
                    GROQ_API_URL,
                    headers={
                        "Authorization": f"Bearer {self._groq_api_key}",
                        "Content-Type": "application/json",
                    },
                    json={
                        "model": GROQ_MODEL,
                        "messages": messages,
                        "max_tokens": MAX_TOKENS,
                        "temperature": TEMPERATURE,
                    },
                )
                response.raise_for_status()

            data = response.json()
            reply = data["choices"][0]["message"]["content"].strip()
            logger.debug("Réponse obtenue via Groq (%d caractères)", len(reply))
            return reply

        except httpx.HTTPStatusError as exc:
            status_code = exc.response.status_code
            logger.warning(
                "Groq API erreur %s — fallback vers Ollama. Détail: %s",
                status_code, exc.response.text[:200],
            )
            if status_code == 401:
                logger.error("Clé GROQ_API_KEY invalide ou expirée.")
            return None

        except httpx.TimeoutException:
            logger.warning("Groq API timeout — fallback vers Ollama")
            return None

        except Exception as exc:
            logger.warning("Groq erreur inattendue — fallback vers Ollama: %s", exc)
            return None

    async def _call_ollama(self, messages: list[dict]) -> Optional[str]:
        """Appelle l'API Ollama locale. Retourne None en cas d'échec."""
        # Vérifier la disponibilité d'Ollama si pas encore fait
        if self._ollama_available is None:
            self._ollama_available = await self._check_ollama()

        if not self._ollama_available:
            return None

        try:
            async with httpx.AsyncClient(timeout=OLLAMA_TIMEOUT) as client:
                response = await client.post(
                    f"{self._ollama_url}/api/chat",
                    json={
                        "model": self._ollama_model,
                        "messages": messages,
                        "stream": False,
                        "options": {
                            "num_predict": MAX_TOKENS,
                            "temperature": TEMPERATURE,
                        },
                    },
                )
                response.raise_for_status()

            data = response.json()
            reply = data.get("message", {}).get("content", "").strip()

            if not reply:
                logger.warning("Ollama a retourné une réponse vide")
                return None

            logger.debug("Réponse obtenue via Ollama (%d caractères)", len(reply))
            return reply

        except httpx.HTTPStatusError as exc:
            logger.warning(
                "Ollama API erreur %s: %s",
                exc.response.status_code, exc.response.text[:200],
            )
            return None

        except (httpx.ConnectError, httpx.TimeoutException):
            logger.warning(
                "Ollama indisponible (%s) — vérifiez que le service tourne",
                self._ollama_url,
            )
            self._ollama_available = False
            return None

        except Exception as exc:
            logger.warning("Ollama erreur inattendue: %s", exc)
            return None

    async def _check_ollama(self) -> bool:
        """Vérifie si Ollama est joignable et si le modèle est disponible."""
        try:
            async with httpx.AsyncClient(timeout=5.0) as client:
                # Vérifier que le service tourne
                resp = await client.get(f"{self._ollama_url}/api/tags")
                resp.raise_for_status()

                # Vérifier que le modèle est téléchargé
                models = resp.json().get("models", [])
                model_names = [m.get("name", "") for m in models]

                # Ollama utilise des noms comme "llama3.1:8b" ou "llama3.1:latest"
                model_found = any(
                    self._ollama_model in name or name.startswith(self._ollama_model.split(":")[0])
                    for name in model_names
                )

                if model_found:
                    logger.info(
                        "Ollama disponible — modèle '%s' trouvé", self._ollama_model
                    )
                    return True
                else:
                    logger.warning(
                        "Ollama joignable mais modèle '%s' non trouvé. "
                        "Modèles disponibles : %s. "
                        "Lancez : ollama pull %s",
                        self._ollama_model,
                        ", ".join(model_names) or "(aucun)",
                        self._ollama_model,
                    )
                    # On tente quand même — Ollama peut pull automatiquement
                    return True

        except (httpx.ConnectError, httpx.TimeoutException):
            logger.info(
                "Ollama non joignable sur %s — fallback désactivé. "
                "Installez Ollama : https://ollama.com",
                self._ollama_url,
            )
            return False
        except Exception as exc:
            logger.info("Erreur vérification Ollama: %s", exc)
            return False

    # ------------------------------------------------------------------
    # Construction du prompt
    # ------------------------------------------------------------------

    def _build_system_prompt(self, context: Optional[dict]) -> str:
        if not context:
            return _SYSTEM_BASE

        lines: list[str] = []
        if context.get("profile_code"):
            lines.append(f"- Code RIASEC : **{context['profile_code']}**")
        if context.get("dominant_traits"):
            traits = ", ".join(context["dominant_traits"])
            lines.append(f"- Traits dominants : {traits}")
        if context.get("profile_summary"):
            summary = context["profile_summary"][:300].replace("**", "")
            lines.append(f"- Résumé du profil : {summary}")
        if context.get("strengths"):
            strengths = ", ".join(context["strengths"][:4])
            lines.append(f"- Points forts : {strengths}")
        if context.get("recommendations"):
            careers = [
                c.get("name", "")
                for c in context["recommendations"][:5]
                if c.get("name")
            ]
            if careers:
                lines.append(f"- Carrières recommandées : {', '.join(careers)}")
        if context.get("recommended_sectors"):
            sectors = ", ".join(context["recommended_sectors"][:4])
            lines.append(f"- Secteurs conseillés : {sectors}")

        context_block = "\n".join(lines) if lines else "Profil non disponible"
        return _SYSTEM_WITH_CONTEXT.format(context_block=context_block)


# Singleton partagé (instancié à l'import du module)
llm_service = LLMService()
