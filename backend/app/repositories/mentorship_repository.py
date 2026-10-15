"""Repository de l'espace mentorat : relations eleve/mentor et seances.

Utilise le client service_role : `mentor_relationships` et `mentor_sessions`
ont RLS actif sans politique (donnees personnelles), et le backend ne transmet
jamais le JWT de l'eleve a Supabase — c'est donc lui la frontiere de securite,
d'ou les verifications d'appartenance explicites dans les endpoints.
"""

from __future__ import annotations

import re
import unicodedata
from datetime import datetime, timezone
from typing import Any, Optional
from uuid import UUID

from app.core.logging import get_logger
from app.db.supabase_client import SupabaseClient, get_admin_supabase_client

logger = get_logger("repositories.mentorship")

# Une demande en attente immobilise une place chez le mentor. On borne le
# nombre de demandes simultanees d'un eleve pour que quelques comptes ne
# saturent pas les rares mentors disponibles.
MAX_PENDING_PER_MENTEE = 3

# Mots trop courants pour porter un sens dans un rapprochement de specialites.
STOPWORDS = {
    "de", "des", "du", "la", "le", "les", "et", "en", "un", "une", "au", "aux",
    "pour", "dans", "sur", "par", "avec", "sciences", "science", "metier",
    "metiers", "domaine", "etudes", "travail", "secteur",
}


def _now() -> str:
    return datetime.now(timezone.utc).isoformat()


def _terms(text: str) -> set[str]:
    """Mots significatifs, sans accents ni casse, pour comparer des libelles."""
    flat = unicodedata.normalize("NFKD", text or "")
    flat = "".join(c for c in flat if not unicodedata.combining(c)).lower()
    return {w for w in re.findall(r"[a-z0-9]{3,}", flat) if w not in STOPWORDS}


class MentorshipRepository:
    def __init__(self) -> None:
        self._db: SupabaseClient = get_admin_supabase_client()

    # -- Relations ----------------------------------------------------------

    def get_mentor(self, mentor_id: UUID) -> Optional[dict[str, Any]]:
        res = (
            self._db.client.table("mentors")
            .select("id, full_name, specialty, avatar_url, email, "
                    "max_mentees, current_mentees, is_active, is_verified")
            .eq("id", str(mentor_id))
            .limit(1)
            .execute()
        )
        return res.data[0] if res.data else None

    def find_relationship(self, mentor_id: UUID, mentee_id: UUID) -> Optional[dict[str, Any]]:
        res = (
            self._db.client.table("mentor_relationships")
            .select("*")
            .eq("mentor_id", str(mentor_id))
            .eq("mentee_id", str(mentee_id))
            .limit(1)
            .execute()
        )
        return res.data[0] if res.data else None

    def get_relationship(self, relationship_id: UUID) -> Optional[dict[str, Any]]:
        res = (
            self._db.client.table("mentor_relationships")
            .select("*")
            .eq("id", str(relationship_id))
            .limit(1)
            .execute()
        )
        return res.data[0] if res.data else None

    def count_pending(self, mentee_id: UUID) -> int:
        res = (
            self._db.client.table("mentor_relationships")
            .select("id", count="exact")
            .eq("mentee_id", str(mentee_id))
            .eq("status", "pending")
            .execute()
        )
        return res.count if res.count is not None else len(res.data or [])

    def create_request(
        self, mentor_id: UUID, mentee_id: UUID, data: dict[str, Any]
    ) -> dict[str, Any]:
        payload = {
            **data,
            "mentor_id": str(mentor_id),
            "mentee_id": str(mentee_id),
            "status": "pending",
            "created_at": _now(),
            "updated_at": _now(),
        }
        res = self._db.client.table("mentor_relationships").insert(payload).execute()
        return res.data[0] if res.data else payload

    def decide(
        self, relationship_id: UUID, accept: bool, reason: Optional[str] = None
    ) -> Optional[dict[str, Any]]:
        changes: dict[str, Any] = {
            "status": "active" if accept else "cancelled",
            "decided_at": _now(),
            "updated_at": _now(),
        }
        if accept:
            changes["started_at"] = _now()
        else:
            changes["decline_reason"] = reason
        res = (
            self._db.client.table("mentor_relationships")
            .update(changes)
            .eq("id", str(relationship_id))
            .execute()
        )
        return res.data[0] if res.data else None

    def refresh_mentee_count(self, mentor_id: UUID) -> int:
        """Recale `current_mentees` sur le nombre reel de relations actives.

        On recompte plutot que d'incrementer : deux acceptations simultanees
        feraient diverger un compteur incremente, alors qu'un recomptage donne
        toujours la valeur vraie.
        """
        res = (
            self._db.client.table("mentor_relationships")
            .select("id", count="exact")
            .eq("mentor_id", str(mentor_id))
            .eq("status", "active")
            .execute()
        )
        actives = res.count if res.count is not None else len(res.data or [])
        try:
            (self._db.client.table("mentors")
             .update({"current_mentees": actives, "updated_at": _now()})
             .eq("id", str(mentor_id)).execute())
        except Exception:  # noqa: BLE001
            logger.warning("Mise a jour de current_mentees echouee", exc_info=True)
        return actives

    def list_for_mentee(self, mentee_id: UUID) -> list[dict[str, Any]]:
        """Relations d'un eleve, mentor resume et seances incluses.

        Trois requetes bornees plutot qu'une jointure PostgREST : `mentors` et
        `mentor_relationships` ne portent pas de cle etrangere que PostgREST
        saurait suivre (les tables viennent du schema.sql historique).
        """
        rels = (
            self._db.client.table("mentor_relationships")
            .select("*")
            .eq("mentee_id", str(mentee_id))
            .order("created_at", desc=True)
            .execute()
        ).data or []
        if not rels:
            return []

        mentor_ids = list({r["mentor_id"] for r in rels})
        mentors = (
            self._db.client.table("mentors")
            .select("id, full_name, specialty, avatar_url")
            .in_("id", mentor_ids)
            .execute()
        ).data or []
        by_mentor = {m["id"]: m for m in mentors}

        sessions = (
            self._db.client.table("mentor_sessions")
            .select("*")
            .in_("relationship_id", [r["id"] for r in rels])
            .order("scheduled_at", desc=True)
            .execute()
        ).data or []
        by_rel: dict[str, list[dict[str, Any]]] = {}
        for s in sessions:
            by_rel.setdefault(s["relationship_id"], []).append(s)

        for r in rels:
            m = by_mentor.get(r["mentor_id"], {})
            r["mentor_name"] = m.get("full_name")
            r["mentor_specialty"] = m.get("specialty")
            r["mentor_avatar_url"] = m.get("avatar_url")
            r["sessions"] = by_rel.get(r["id"], [])
        return rels

    # -- Seances ------------------------------------------------------------

    def create_session(
        self, relationship_id: UUID, data: dict[str, Any], proposed_by: str
    ) -> dict[str, Any]:
        payload = {
            **data,
            "relationship_id": str(relationship_id),
            "proposed_by": proposed_by,
            "status": "proposed",
            "created_at": _now(),
            "updated_at": _now(),
        }
        res = self._db.client.table("mentor_sessions").insert(payload).execute()
        return res.data[0] if res.data else payload

    def get_session(self, session_id: UUID) -> Optional[dict[str, Any]]:
        res = (
            self._db.client.table("mentor_sessions")
            .select("*")
            .eq("id", str(session_id))
            .limit(1)
            .execute()
        )
        return res.data[0] if res.data else None

    def update_session(
        self, session_id: UUID, changes: dict[str, Any]
    ) -> Optional[dict[str, Any]]:
        res = (
            self._db.client.table("mentor_sessions")
            .update({**changes, "updated_at": _now()})
            .eq("id", str(session_id))
            .execute()
        )
        return res.data[0] if res.data else None

    # -- Suggestions --------------------------------------------------------

    def suggest(self, profile: Optional[dict[str, Any]], limit: int) -> list[dict[str, Any]]:
        """Classe les mentors visibles selon le profil d'orientation de l'eleve.

        Le rapprochement est un recouvrement de termes entre ce que l'eleve a
        declare (interets, matieres preferees, projet professionnel) et ce que
        le mentor annonce (specialite, domaines d'expertise). Les termes
        communs sont renvoyes : un eleve doit pouvoir lire POURQUOI on lui
        propose quelqu'un, la ou les plateformes du marche affichent un score
        opaque.

        Sans profil, on retombe sur les mieux notes — jamais sur un tirage au
        sort, qui donnerait une liste differente a chaque ouverture.
        """
        mentors = (
            self._db.client.table("mentors")
            .select("id, full_name, specialty, bio, avatar_url, expertise_areas, "
                    "years_experience, rating_avg, max_mentees, current_mentees")
            .eq("is_active", True)
            .eq("is_verified", True)
            .execute()
        ).data or []

        wanted: set[str] = set()
        if profile:
            for key in ("interests", "favorite_subjects"):
                for value in profile.get(key) or []:
                    wanted |= _terms(value)
            wanted |= _terms(profile.get("career_project") or "")

        scored = []
        for m in mentors:
            haystack = " ".join(
                [m.get("specialty") or "", *(m.get("expertise_areas") or [])]
            )
            common = sorted(wanted & _terms(haystack))
            scored.append({
                **m,
                "match_score": len(common),
                "match_terms": common,
                "slots_left": max(0, (m.get("max_mentees") or 0)
                                  - (m.get("current_mentees") or 0)),
            })

        # Tri deterministe : pertinence, puis note, puis nom. Sans le dernier
        # critere, deux mentors ex aequo s'echangeraient de place a chaque appel.
        scored.sort(key=lambda m: (
            -m["match_score"],
            -float(m.get("rating_avg") or 0),
            (m.get("full_name") or ""),
        ))
        return scored[:limit]


_repository: Optional[MentorshipRepository] = None


def get_mentorship_repository() -> MentorshipRepository:
    global _repository
    if _repository is None:
        _repository = MentorshipRepository()
    return _repository
