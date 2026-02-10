#!/usr/bin/env bash
set -euo pipefail
# Generates an importable SQL file from database/courses.sql
# - removes psql meta-commands (lines starting with backslash)
# - drops existing table/sequence
# - includes schema and data (unchanged)

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$REPO_ROOT/database/courses.sql"
OUT="$REPO_ROOT/database/courses_import.sql"
TMP_CLEAN="/tmp/courses_clean.$$"
TMP_SCHEMA="/tmp/courses_schema.$$"
TMP_DATA="/tmp/courses_data.$$"

if [ ! -f "$SRC" ]; then
  echo "ERROR: source file not found: $SRC" >&2
  exit 1
fi

echo "Creating cleaned dump (removing psql backslash meta-commands)"
grep -v '^\\' "$SRC" > "$TMP_CLEAN"

echo "Extracting CREATE TABLE public.courses block"
# Use sed range to capture from CREATE TABLE line to the closing ');' line
sed -n '/^CREATE TABLE public\.courses/,/);/p' "$TMP_CLEAN" > "$TMP_SCHEMA" || true

echo "Extracting CREATE SEQUENCE public.courses_course_id_seq block"
sed -n '/^CREATE SEQUENCE public\.courses_course_id_seq/,/;$/p' "$TMP_CLEAN" > "$TMP_SCHEMA.seq" || true

echo "Collecting ALTER statements related to courses"
grep -nE "ALTER (TABLE|SEQUENCE).*courses|ALTER SEQUENCE .*courses_course_id_seq|ALTER TABLE ONLY public.courses ALTER COLUMN" "$TMP_CLEAN" || true > "$TMP_SCHEMA.alter"

echo "Collecting INSERT INTO public.courses lines"
grep -n "INSERT INTO public.courses" "$TMP_CLEAN" | cut -d: -f2- > "$TMP_DATA" || true

echo "Writing importable SQL to $OUT"
cat > "$OUT" <<'SQL'
-- Auto-generated import file
-- Drops existing courses table and sequence, recreates schema and loads data
BEGIN;
DROP TABLE IF EXISTS public.courses CASCADE;
DROP SEQUENCE IF EXISTS public.courses_course_id_seq CASCADE;
COMMIT;
-- Applying schema
SQL

if [ -s "$TMP_SCHEMA" ]; then
  cat "$TMP_SCHEMA" >> "$OUT"
else
  echo "-- WARNING: CREATE TABLE block not found" >> "$OUT"
fi

if [ -s "$TMP_SCHEMA.seq" ]; then
  echo "" >> "$OUT"
  cat "$TMP_SCHEMA.seq" >> "$OUT"
fi

if [ -s "$TMP_SCHEMA.alter" ]; then
  echo "" >> "$OUT"
  cat "$TMP_SCHEMA.alter" >> "$OUT"
fi

cat >> "$OUT" <<'SQL'

-- Applying data (INSERTs)
BEGIN;
-- Data follows
SQL

if [ -s "$TMP_DATA" ]; then
  cat "$TMP_DATA" >> "$OUT"
else
  echo "-- WARNING: no INSERT INTO public.courses lines found" >> "$OUT"
fi

cat >> "$OUT" <<'SQL'
COMMIT;

-- Fix sequence to max(course_id)+1
SELECT pg_catalog.setval('public.courses_course_id_seq', COALESCE((SELECT MAX(course_id) + 1 FROM public.courses), 1), false);

-- End of generated import
SQL

rm -f "$TMP_CLEAN" "$TMP_SCHEMA" "$TMP_SCHEMA.seq" "$TMP_SCHEMA.alter" "$TMP_DATA"
echo "Wrote $OUT"

exit 0
