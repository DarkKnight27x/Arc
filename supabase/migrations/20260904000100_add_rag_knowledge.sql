-- Arc RAG knowledge layer.
-- This is intentionally separate from user plans and health records:
-- structured data stays in the existing relational tables; this layer stores
-- versioned, searchable guidance only.

create extension if not exists vector;

create type public.knowledge_document_status as enum ('draft', 'published', 'retired');

create table public.knowledge_documents (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  knowledge_type text not null check (knowledge_type in (
    'workout_guidance',
    'nutrition_guidance',
    'safety_guidance',
    'rehab_guidance',
    'general_coaching'
  )),
  source text not null,
  source_uri text,
  version text not null default '1',
  content_hash text unique,
  status public.knowledge_document_status not null default 'draft',
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.knowledge_chunks (
  id uuid primary key default gen_random_uuid(),
  document_id uuid not null references public.knowledge_documents(id) on delete cascade,
  chunk_index integer not null check (chunk_index >= 0),
  content text not null,
  metadata jsonb not null default '{}'::jsonb,
  embedding vector,
  embedding_model text,
  embedding_dimensions smallint check (embedding_dimensions > 0),
  created_at timestamptz not null default now(),
  unique (document_id, chunk_index),
  check (
    (embedding is null and embedding_model is null and embedding_dimensions is null)
    or (embedding is not null and embedding_model is not null and embedding_dimensions is not null)
  )
);

create trigger knowledge_documents_updated_at
  before update on public.knowledge_documents
  for each row execute procedure public.set_updated_at();

create index knowledge_documents_published_type_idx
  on public.knowledge_documents (knowledge_type)
  where status = 'published';
create index knowledge_chunks_document_idx on public.knowledge_chunks (document_id);
create index knowledge_chunks_metadata_idx on public.knowledge_chunks using gin (metadata);

alter table public.knowledge_documents enable row level security;
alter table public.knowledge_chunks enable row level security;

-- There are deliberately no client-facing RLS policies. Only the trusted
-- FastAPI backend using its service-role key can ingest or retrieve RAG data.

create or replace function public.match_knowledge_chunks(
  query_embedding vector,
  query_embedding_model text,
  match_count integer default 8,
  metadata_filter jsonb default '{}'::jsonb
)
returns table (
  chunk_id uuid,
  document_id uuid,
  content text,
  metadata jsonb,
  similarity double precision
)
language sql
stable
set search_path = public
as $$
  select
    kc.id as chunk_id,
    kc.document_id,
    kc.content,
    kc.metadata,
    1 - (kc.embedding <=> query_embedding) as similarity
  from public.knowledge_chunks kc
  join public.knowledge_documents kd on kd.id = kc.document_id
  where kd.status = 'published'
    and kc.embedding is not null
    and kc.embedding_model = query_embedding_model
    and kc.metadata @> metadata_filter
  order by kc.embedding <=> query_embedding
  limit greatest(1, least(match_count, 20));
$$;

revoke all on function public.match_knowledge_chunks(vector, text, integer, jsonb) from public, anon, authenticated;

-- IMPORTANT: do not add an HNSW index until the LLM/RAG owner chooses one
-- embedding model and confirms its dimensions. For example, if the team picks
-- text-embedding-3-small (1536 dimensions), first ensure every embedding is
-- that model/dimension, then run a separate migration containing:
--
--   alter table public.knowledge_chunks
--     alter column embedding type vector(1536) using embedding::vector(1536);
--   create index knowledge_chunks_embedding_hnsw_idx
--     on public.knowledge_chunks using hnsw (embedding vector_cosine_ops)
--     where embedding is not null;
