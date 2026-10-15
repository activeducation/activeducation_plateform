import os
from dotenv import load_dotenv
from supabase import create_client, Client
import json

load_dotenv()

url: str = os.environ.get("SUPABASE_URL")
key: str = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")

if not url or not key:
    print("SUPABASE_URL ou SUPABASE_SERVICE_ROLE_KEY manquant.")
    exit(1)

supabase: Client = create_client(url, key)

print("Insertion des Cours...")
courses = [
    {
        "id": "a1000000-0000-0000-0000-000000000001",
        "title": "Introduction aux Métiers du Numérique",
        "description": "Plongez au cœur de la révolution numérique africaine ! Découvrez les métiers clés de demain : développeur full-stack, UX/UI designer, data scientist ou expert en cybersécurité. Explorez leurs réalités quotidiennes, les compétences incontournables à acquérir, et les immenses perspectives de carrière sur le continent.",
        "category": "Informatique",
        "difficulty": "debutant",
        "duration_minutes": 45,
        "points_reward": 100,
        "is_published": True,
        "display_order": 1
    }
]
supabase.table("elearning_courses").upsert(courses).execute()

print("Insertion des Modules...")
modules = [
    {
        "id": "b1000000-0000-0000-0000-000000000001",
        "course_id": "a1000000-0000-0000-0000-000000000001",
        "title": "Module 1 — Le paysage numérique",
        "description": "Une immersion totale dans l'écosystème tech en Afrique, ses enjeux et ses opportunités.",
        "display_order": 1,
        "is_locked": False
    },
    {
        "id": "b1000000-0000-0000-0000-000000000002",
        "course_id": "a1000000-0000-0000-0000-000000000001",
        "title": "Module 2 — Choisir sa spécialité",
        "description": "Front-end, back-end, data, design... Découvrez la voie qui correspond à votre passion !",
        "display_order": 2,
        "is_locked": True
    }
]
supabase.table("elearning_modules").upsert(modules).execute()

print("Insertion des Leçons...")
lessons = [
    {
        "id": "c1000000-0000-0000-0000-000000000001",
        "module_id": "b1000000-0000-0000-0000-000000000001",
        "title": "Le numérique en Afrique aujourd'hui",
        "lesson_type": "article",
        "duration_minutes": 8,
        "points_reward": 10,
        "display_order": 1,
        "is_free": True
    },
    {
        "id": "c1000000-0000-0000-0000-000000000002",
        "module_id": "b1000000-0000-0000-0000-000000000001",
        "title": "Présentation des métiers tech",
        "lesson_type": "video",
        "duration_minutes": 12,
        "points_reward": 15,
        "display_order": 2,
        "is_free": False
    },
    {
        "id": "c1000000-0000-0000-0000-000000000003",
        "module_id": "b1000000-0000-0000-0000-000000000002",
        "title": "Quiz : Quel profil tech es-tu ?",
        "lesson_type": "quiz",
        "duration_minutes": 10,
        "points_reward": 20,
        "display_order": 1,
        "is_free": False
    }
]
supabase.table("elearning_lessons").upsert(lessons).execute()

print("Insertion des Contenus...")
contents = [
    {
        "id": "d1000000-0000-0000-0000-000000000001",
        "lesson_id": "c1000000-0000-0000-0000-000000000001",
        "content_data": {
            "html_content": "<div class=\"premium-article\"><h1>Le numérique en Afrique : Une révolution en marche</h1><p>L'Afrique ne se contente plus de consommer la technologie, elle la crée. En l'espace de cinq ans, le nombre d'internautes africains a explosé, créant un terreau fertile pour l'innovation locale.</p><h2>🌟 Pourquoi c'est le moment idéal ?</h2><p>Le continent connaît une véritable effervescence :</p><ul><li><strong>Startups en hypercroissance :</strong> Les levées de fonds se multiplient dans la FinTech, l'AgriTech et l'EdTech.</li><li><strong>Pénurie de talents :</strong> La demande pour les développeurs, data scientists et product managers surpasse l'offre, garantissant d'excellentes perspectives d'emploi.</li><li><strong>Démocratisation de la formation :</strong> Apprendre à coder n'a jamais été aussi accessible.</li></ul><h2>🚀 Le cas du Togo</h2><p>Au Togo, l'écosystème se structure rapidement. Des initiatives comme <strong>Digital Africa</strong> et le <strong>Lomé Tech Hub</strong> propulsent de jeunes talents sur la scène internationale, transformant Lomé en un véritable carrefour technologique.</p></div>",
            "read_time_minutes": 8
        }
    },
    {
        "id": "d1000000-0000-0000-0000-000000000002",
        "lesson_id": "c1000000-0000-0000-0000-000000000002",
        "content_data": {
            "youtube_id": "dQw4w9WgXcQ",
            "video_url": "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
            "transcript": "Bienvenue dans cette immersion exclusive au cœur de la tech ! Avez-vous déjà rêvé de construire l'application que des millions de personnes utiliseront demain ? Aujourd'hui, nous allons déconstruire les mythes autour du numérique et explorer les rôles clés qui font tourner le web. Du Développeur Front-End qui sculpte l'expérience visuelle de l'utilisateur, au Développeur Back-End qui bâtit l'infrastructure invisible et robuste, sans oublier le Data Scientist qui transforme les données en or. Préparez-vous, car l'un de ces métiers pourrait bien être votre future vocation. Plongeons ensemble dans l'univers fascinant du code !"
        }
    },
    {
        "id": "d1000000-0000-0000-0000-000000000003",
        "lesson_id": "c1000000-0000-0000-0000-000000000003",
        "content_data": {
            "pass_score_pct": 50,
            "questions": [
            {
                "id": "q1",
                "text": "Imaginez qu'on vous donne pour mission de créer une nouvelle application révolutionnaire. Quelle serait votre première approche ?",
                "options": [
                {"id": "q1a", "text": "Je dessine des maquettes pour m'assurer que l'application est belle et intuitive (UX/UI)."},
                {"id": "q1b", "text": "Je conçois l'architecture de la base de données et les algorithmes de sécurité (Back-End)."},
                {"id": "q1c", "text": "Je fais un peu des deux, j'aime avoir une vue d'ensemble sur tout le produit (Full-Stack)."}
                ],
                "correct_option_id": "q1c"
            }
            ]
        }
    }
]
supabase.table("elearning_lesson_content").upsert(contents).execute()

print("Injection réussie !")
