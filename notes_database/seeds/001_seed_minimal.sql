-- Seed: 001_seed_minimal
-- Purpose: Minimal baseline data for local/dev usage.
-- Idempotent: uses ON CONFLICT/WHERE NOT EXISTS patterns.

BEGIN;

-- Seed tags
INSERT INTO tags (name)
VALUES ('inbox')
ON CONFLICT (name) DO NOTHING;

INSERT INTO tags (name)
VALUES ('work')
ON CONFLICT (name) DO NOTHING;

INSERT INTO tags (name)
VALUES ('personal')
ON CONFLICT (name) DO NOTHING;

INSERT INTO tags (name)
VALUES ('ideas')
ON CONFLICT (name) DO NOTHING;

-- Seed notes (only if table is empty)
INSERT INTO notes (title, content, pinned)
SELECT 'Welcome to NoteMaster', 'Create notes, pin important ones, and organize with tags.', TRUE
WHERE NOT EXISTS (SELECT 1 FROM notes);

INSERT INTO notes (title, content, pinned)
SELECT 'Search tips', 'Try searching by words in the title or content. Trigram indexes help speed up partial matches.', FALSE
WHERE NOT EXISTS (SELECT 1 FROM notes WHERE title = 'Search tips');

-- Attach default tags to the welcome note if it exists and relation not present
WITH welcome_note AS (
    SELECT id FROM notes WHERE title = 'Welcome to NoteMaster' ORDER BY id ASC LIMIT 1
),
inbox_tag AS (
    SELECT id FROM tags WHERE name = 'inbox' LIMIT 1
)
INSERT INTO note_tags (note_id, tag_id)
SELECT welcome_note.id, inbox_tag.id
FROM welcome_note, inbox_tag
ON CONFLICT DO NOTHING;

COMMIT;
