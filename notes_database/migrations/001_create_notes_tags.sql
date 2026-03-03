-- Migration: 001_create_notes_tags
-- Purpose: Core schema for notes, tags, and note<->tag relations.
-- This migration is designed to be idempotent (safe to run multiple times).

BEGIN;

-- Enable useful extensions for text search/trigram matching (optional but helpful).
-- pg_trgm allows fast ILIKE/substring search; keep it optional but safe.
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- NOTES
CREATE TABLE IF NOT EXISTS notes (
    id BIGSERIAL PRIMARY KEY,
    title TEXT NOT NULL DEFAULT '',
    content TEXT NOT NULL DEFAULT '',
    pinned BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- TAGS (unique by normalized name)
CREATE TABLE IF NOT EXISTS tags (
    id BIGSERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT tags_name_unique UNIQUE (name)
);

-- NOTE <-> TAG join table
CREATE TABLE IF NOT EXISTS note_tags (
    note_id BIGINT NOT NULL,
    tag_id BIGINT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (note_id, tag_id),
    CONSTRAINT note_tags_note_fk FOREIGN KEY (note_id) REFERENCES notes(id) ON DELETE CASCADE,
    CONSTRAINT note_tags_tag_fk FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE
);

-- Helpful indexes
CREATE INDEX IF NOT EXISTS idx_notes_pinned_created_at ON notes (pinned DESC, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notes_updated_at ON notes (updated_at DESC);

-- Basic text search support: trigram indexes for ILIKE searches on title/content.
CREATE INDEX IF NOT EXISTS idx_notes_title_trgm ON notes USING gin (title gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_notes_content_trgm ON notes USING gin (content gin_trgm_ops);

CREATE INDEX IF NOT EXISTS idx_tags_name ON tags (name);
CREATE INDEX IF NOT EXISTS idx_note_tags_tag_id ON note_tags (tag_id);

COMMIT;
