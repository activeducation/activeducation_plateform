"""
Script de seed — Base de connaissances AÏDA vers Supabase.

Usage :
    cd backend
    python scripts/seed_knowledge_base.py

Prérequis :
    - .env configuré avec SUPABASE_URL et SUPABASE_SERVICE_ROLE_KEY
    - Table knowledge_base créée dans Supabase (voir migration ci-dessous)

Schéma SQL à créer d'abord dans Supabase :
    CREATE TABLE IF NOT EXISTS knowledge_base (
        id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        category TEXT NOT NULL,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        embedding VECTOR(1536),  -- Optionnel, pour la recherche sémantique
        created_at TIMESTAMPTZ DEFAULT NOW(),
        updated_at TIMESTAMPTZ DEFAULT NOW()
    );
    CREATE INDEX IF NOT EXISTS idx_kb_category ON knowledge_base(category);
"""

import os
import sys
from pathlib import Path

# Ajouter le dossier backend au PYTHONPATH
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from dotenv import load_dotenv
load_dotenv(Path(__file__).resolve().parents[1] / ".env")

from supabase import create_client


KNOWLEDGE_BASE_ENTRIES = [
    # =========================================================================
    # ÉCOLES
    # =========================================================================
    {
        "category": "ecoles",
        "title": "Université de Lomé",
        "content": (
            "Public | Lomé | Fondée 1970 | 65 000 étudiants | 50-150K FCFA/an | CAMES, REESAO. "
            "Filières : Sciences, Médecine, Droit, Lettres, Économie, Génie Civil, Informatique. "
            "Programmes : Génie Logiciel et IA (Licence 3 ans), Droit des Affaires (Master 2 ans), "
            "Médecine (Doctorat 7 ans), Économie et Gestion (Licence 3 ans)."
        ),
    },
    {
        "category": "ecoles",
        "title": "Université de Kara",
        "content": (
            "Public | Kara | Fondée 2004 | 15 000 étudiants | 50-120K FCFA/an | CAMES, REESAO. "
            "Filières : Agronomie, Droit, Lettres, Sciences, Économie."
        ),
    },
    {
        "category": "ecoles",
        "title": "UCAO-UUT (Université Catholique de l'Afrique de l'Ouest)",
        "content": (
            "Privé | Lomé | Fondée 1999 | 4 500 étudiants | 500K-1,2M FCFA/an | CAMES, HCERES. "
            "Filières : Droit, Économie, Gestion, Informatique, Communication."
        ),
    },
    {
        "category": "ecoles",
        "title": "ESA - École Supérieure des Affaires",
        "content": (
            "Privé | Lomé | Fondée 2002 | 2 000 étudiants | 600K-1,5M FCFA/an | CAMES. "
            "Filières : Management, Finance, Marketing, Comptabilité, Entrepreneuriat."
        ),
    },
    {
        "category": "ecoles",
        "title": "ESIBA Business School",
        "content": (
            "Privé | Lomé | Fondée 2010 | 1 200 étudiants | 450-900K FCFA/an | CAMES. "
            "Filières : Marketing Digital, Commerce International, Management, RH."
        ),
    },
    {
        "category": "ecoles",
        "title": "IPNET Institute",
        "content": (
            "Privé | Lomé | Fondée 2008 | 800 étudiants | 300-800K FCFA/an | Cisco Academy, Microsoft Partner. "
            "Filières : Réseaux, Cybersécurité, Cloud Computing, Développement Web/Mobile."
        ),
    },
    {
        "category": "ecoles",
        "title": "IAEC Togo",
        "content": (
            "Privé | Lomé | Fondée 1995 | 1 500 étudiants | 350-700K FCFA/an | CAMES. "
            "Filières : Comptabilité, Gestion Commerciale, Banque Finance, Transit Douane."
        ),
    },
    {
        "category": "ecoles",
        "title": "ESGIS",
        "content": (
            "Privé | Lomé | Fondée 2002 | 3 500 étudiants | 500K-1,1M FCFA/an | CAMES, HCERES. "
            "Filières : Informatique, Gestion, Droit, Sciences de la Santé, Génie Civil."
        ),
    },
    {
        "category": "ecoles",
        "title": "FORMATEC",
        "content": (
            "Privé | Lomé | Fondée 2000 | 600 étudiants | 200-500K FCFA/an | MEPT. "
            "Filières : Électricité, Mécanique, BTP, Froid et Climatisation, Maintenance Industrielle."
        ),
    },
    # =========================================================================
    # MÉTIERS — TECHNOLOGIE
    # =========================================================================
    {
        "category": "metiers_technologie",
        "title": "Développeur Logiciel",
        "content": "BAC+3 | 150-800K FCFA/mois | UL, ESIBA, IAI-TOGO, ESGIS | Tendance : Forte ↑",
    },
    {
        "category": "metiers_technologie",
        "title": "Analyste de Données",
        "content": "BAC+3 | 200-700K FCFA/mois | ENSEA, UL | Tendance : Forte ↑",
    },
    {
        "category": "metiers_technologie",
        "title": "Admin Systèmes & Réseaux",
        "content": "BAC+2 | 150-600K FCFA/mois | IAI-TOGO, ESIBA, UL-IUT | Tendance : Forte ↑",
    },
    {
        "category": "metiers_technologie",
        "title": "Chef de Projet IT",
        "content": "BAC+3 | 250-900K FCFA/mois | ESGIS, ESAG-NDE, UL | Tendance : Forte ↑",
    },
    # =========================================================================
    # MÉTIERS — SANTÉ
    # =========================================================================
    {
        "category": "metiers_sante",
        "title": "Médecin Généraliste",
        "content": "BAC+7 | 300K-1,5M FCFA/mois | Fac Santé UL | Tendance : Forte →",
    },
    {
        "category": "metiers_sante",
        "title": "Infirmier(e)",
        "content": "BAC+3 | 120-400K FCFA/mois | ENAM, ESTBA-UL | Tendance : Forte ↑",
    },
    {
        "category": "metiers_sante",
        "title": "Pharmacien",
        "content": "BAC+6 | 300K-1M FCFA/mois | Fac Santé UL | Tendance : Moyenne →",
    },
    # =========================================================================
    # EMPLOYEURS
    # =========================================================================
    {
        "category": "employeurs",
        "title": "Principaux employeurs au Togo",
        "content": (
            "Télécoms : TOGOCOM, Moov Africa. "
            "Finance : Ecobank, ORABANK, BTCI, UTB, Coris Bank, BCEAO. "
            "Tech/Startup : Gozem, Semoa, Woelab, CUBE. "
            "Énergie : CEET, OTP. "
            "Santé : CHU Sylvanus Olympio. "
            "Assurance : NSIA. "
            "Logistique : Port Autonome de Lomé."
        ),
    },
]


def seed_knowledge_base() -> None:
    url = os.environ.get("SUPABASE_URL")
    key = os.environ.get("SUPABASE_SERVICE_ROLE_KEY") or os.environ.get("SUPABASE_KEY")

    if not url or not key:
        print("ERREUR: SUPABASE_URL et SUPABASE_SERVICE_ROLE_KEY requis dans .env")
        sys.exit(1)

    client = create_client(url, key)

    print(f"Insertion de {len(KNOWLEDGE_BASE_ENTRIES)} entrées dans knowledge_base...")

    # Upsert par (category, title) pour éviter les doublons
    for entry in KNOWLEDGE_BASE_ENTRIES:
        result = (
            client.table("knowledge_base")
            .upsert(entry, on_conflict="category,title")
            .execute()
        )
        print(f"  OK: [{entry['category']}] {entry['title']}")

    print(f"\nSeed terminé : {len(KNOWLEDGE_BASE_ENTRIES)} entrées insérées/mises à jour.")
    print("Pensez à créer un index UNIQUE sur (category, title) dans Supabase :")
    print("  CREATE UNIQUE INDEX IF NOT EXISTS idx_kb_category_title")
    print("  ON knowledge_base(category, title);")


if __name__ == "__main__":
    seed_knowledge_base()
