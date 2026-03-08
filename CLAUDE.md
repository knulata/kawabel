# CLAUDE.md

## Project Overview

Kawan Belajar is an AI-powered tutoring tablet app for Indonesian students (SD & SMP). Students photograph homework/textbooks and get guided help from "Budi" — an AI owl tutor. Features Chinese dictation with TTS + handwriting recognition, test prep with mock tests, and gamified learning across all school subjects.

## Tech Stack

- **App**: Flutter (Dart) — cross-platform iPad + Android tablets
- **Backend**: Supabase (Auth, PostgreSQL, Edge Functions, Storage)
- **AI**: Claude API (Anthropic) — reasoning + vision for photo understanding
- **Speech**: Google Cloud TTS/STT — Chinese dictation audio
- **Handwriting**: Google ML Kit — character recognition
- **Admin**: Next.js web dashboard for tuition center management

## Project Structure

- `lib/features/` — Feature modules (auth, home, camera, chat, dictation, test_prep, progress, settings)
- `lib/core/` — Shared services (ai, speech, handwriting, storage, models)
- `lib/shared/` — Reusable widgets, Budi character, utilities
- `supabase/` — Database migrations and edge functions
- `admin-dashboard/` — Next.js admin panel for tuition centers

## Key Conventions

- Feature-first folder structure
- Budi (the owl) is the AI persona — always guides, never gives direct answers
- All AI prompts must be age-appropriate and filtered
- Support offline mode for core features
- Indonesian (Bahasa) is the primary UI language
