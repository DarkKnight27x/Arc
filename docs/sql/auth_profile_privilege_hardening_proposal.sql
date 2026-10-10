-- OPTIONAL REVIEW PROPOSAL ONLY. NOT EXECUTED; NOT AN AUTOMATIC MIGRATION.
-- Existing profiles grants include TRUNCATE/REFERENCES/TRIGGER. RLS does not
-- protect TRUNCATE. Keep normal profile read/write privileges and owner RLS.
-- Review dependencies and approve separately before any production execution.
begin;
revoke truncate, references, trigger on table public.profiles
  from public, anon, authenticated;
commit;
