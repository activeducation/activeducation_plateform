"""
Repository pour la base de connaissances AÏDA.

Charge les entrées depuis Supabase (table knowledge_base) avec cache Redis 1h.
Fallback sur la KB statique embarquée si Supabase ou Redis est indisponible.
"""

import logging
import time
from typing import Optional

logger = logging.getLogger(__name__)

# Cache mémoire local (fallback si Redis indisponible)
_memory_cache: dict = {}
_KB_CACHE_TTL = 3600  # 1 heure


class KnowledgeBaseRepository:
    """Accès à la base de connaissances AÏDA depuis Supabase."""

    TABLE = "knowledge_base"

    def __init__(self) -> None:
        self._redis: Optional[object] = None
        self._supabase: Optional[object] = None
        self._initialized = False

    def _init_clients(self) -> None:
        if self._initialized:
            return
        self._initialized = True

        try:
            import redis as redis_lib
            from app.core.config import settings
            self._redis = redis_lib.from_url(settings.REDIS_URL, decode_responses=True)
            self._redis.ping()
        except Exception as exc:
            logger.warning("Redis indisponible pour la KB — fallback mémoire: %s", exc)
            self._redis = None

        try:
            from app.db.supabase_client import get_supabase_client
            self._supabase = get_supabase_client()
        except Exception as exc:
            logger.warning("Supabase indisponible pour la KB: %s", exc)
            self._supabase = None

    def get_content(self, category: Optional[str] = None) -> str:
        """
        Retourne le contenu de la KB sous forme de texte formaté.
        Cache Redis 1h — fallback mémoire — fallback KB statique.
        """
        self._init_clients()
        cache_key = f"knowledge_base:{category or 'all'}"

        # 1. Tenter Redis
        if self._redis:
            try:
                cached = self._redis.get(cache_key)
                if cached:
                    return cached
            except Exception:
                pass

        # 2. Tenter mémoire locale
        if cache_key in _memory_cache:
            entry = _memory_cache[cache_key]
            if time.time() - entry["ts"] < _KB_CACHE_TTL:
                return entry["content"]

        # 3. Tenter Supabase
        if self._supabase:
            try:
                content = self._fetch_from_supabase(category)
                if content:
                    self._store_in_cache(cache_key, content)
                    return content
            except Exception as exc:
                logger.warning("Erreur lecture KB Supabase: %s — fallback statique", exc)

        # 4. Fallback KB statique
        logger.info("Utilisation de la KB statique (Supabase non disponible)")
        return _STATIC_KB

    def _fetch_from_supabase(self, category: Optional[str]) -> str:
        """Charge les entrées KB depuis Supabase et les formate en texte."""
        query = self._supabase.table(self.TABLE).select("category, title, content")
        if category:
            query = query.eq("category", category)
        result = query.order("category").order("title").execute()

        if not result.data:
            return ""

        lines = []
        current_category = None
        for row in result.data:
            cat = row.get("category", "")
            if cat != current_category:
                current_category = cat
                lines.append(f"\n**{cat.upper()} :**\n")
            title = row.get("title", "")
            content = row.get("content", "")
            lines.append(f"- {title} : {content}")

        return "\n".join(lines)

    def _store_in_cache(self, key: str, content: str) -> None:
        """Stocke dans Redis et dans le cache mémoire."""
        if self._redis:
            try:
                self._redis.setex(key, _KB_CACHE_TTL, content)
                return
            except Exception:
                pass
        _memory_cache[key] = {"content": content, "ts": time.time()}

    def invalidate_cache(self) -> None:
        """Invalide le cache KB (à appeler via endpoint admin)."""
        keys_to_delete = [k for k in _memory_cache if k.startswith("knowledge_base:")]
        for k in keys_to_delete:
            del _memory_cache[k]

        if self._redis:
            try:
                for key in self._redis.scan_iter("knowledge_base:*"):
                    self._redis.delete(key)
                logger.info("Cache KB Redis invalidé")
            except Exception as exc:
                logger.warning("Erreur invalidation cache Redis KB: %s", exc)


# ---------------------------------------------------------------------------
# KB statique — fallback si Supabase indisponible
# ---------------------------------------------------------------------------

_STATIC_KB = """\
**BASE DE DONNÉES — ÉCOLES AU TOGO :**

1. Université de Lomé | public | Lomé | 1970 | 65 000 étudiants | 50-150K FCFA/an
   Filières : Sciences, Médecine, Droit, Lettres, Économie, Génie Civil, Informatique

2. Université de Kara | public | Kara | 2004 | 15 000 étudiants | 50-120K FCFA/an
   Filières : Agronomie, Droit, Lettres, Sciences, Économie

3. UCAO-UUT | privé | Lomé | 1999 | 4 500 étudiants | 500K-1,2M FCFA/an
   Filières : Droit, Économie, Gestion, Informatique, Communication

4. ESA - École Supérieure des Affaires | privé | Lomé | 2002 | 500K-1,5M FCFA/an
   Filières : Management, Finance, Marketing, Comptabilité, Entrepreneuriat

5. ESIBA Business School | privé | Lomé | 2010 | 450-900K FCFA/an
   Filières : Marketing Digital, Commerce International, Management, RH

6. IPNET Institute | privé | Lomé | 2008 | 300-800K FCFA/an
   Filières : Réseaux, Cybersécurité, Cloud, DevOps, Développement Web/Mobile

7. IAEC Togo | privé | Lomé | 1995 | 350-700K FCFA/an
   Filières : Comptabilité, Gestion Commerciale, Banque Finance, Transit Douane

8. ESGIS | privé | Lomé | 2002 | 500K-1,1M FCFA/an
   Filières : Informatique, Gestion, Droit, Sciences de la Santé, Génie Civil

9. FORMATEC | privé | Lomé | 2000 | 200-500K FCFA/an
   Filières : Électricité, Mécanique, BTP, Froid et Climatisation

Autres : ENS Atakpamé, ENAM, ENSI, ESTBA, EAMAU, IAI-TOGO, ISICA, INFA de Tové, ESAG-NDE

**BASE DE DONNÉES — MÉTIERS (salaires mensuels en FCFA) :**

TECHNOLOGIE : Développeur Logiciel (150-800K), Analyste Données (200-700K),
Admin Réseaux (150-600K), Chef Projet IT (250-900K), Designer UX/UI (150-700K)

SANTÉ : Médecin (300K-1,5M), Infirmier (120-400K), Pharmacien (300K-1M),
Sage-Femme (120-450K)

ÉDUCATION : Enseignant (100-350K), Formateur Pro (120-500K),
Conseiller Orientation (100-300K)

FINANCE : Comptable (120-600K), Agent Bancaire (200-800K),
Analyste Financier (300K-1,2M)

COMMERCE : Commercial (100-700K), Entrepreneur (variable),
Resp. Marketing Digital (120-700K)

INGÉNIERIE : Ingénieur Civil (250K-1,2M), Architecte (200K-1M),
Ingénieur Électricien (200-900K)

AGRICULTURE : Ingénieur Agronome (150-700K), Ing. Environnement (200-900K)

DROIT : Avocat (200K-2M), Notaire (400K-3M), Juriste d'Entreprise (250K-1M)

Employeurs majeurs : TOGOCOM, Moov Africa, Gozem, Ecobank, ORABANK, CEET,
CHU Sylvanus Olympio, Port Autonome de Lomé.
"""


# Singleton
knowledge_base_repository = KnowledgeBaseRepository()
