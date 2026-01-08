-- Admin permissions table to store hashed secrets instead of hardcoding them in the app
-- Hash recommendation: SHA-256 over "<salt>::<password>"
-- Example to generate hash in psql:
--   select encode(digest('yoursalt::ZAD2442_language', 'sha256'), 'hex');

create table if not exists public.admin_permissions (
  operation text primary key,
  secret_hash text not null,
  salt text not null,
  algorithm text not null default 'sha256',
  updated_at timestamptz not null default now()
);

comment on table public.admin_permissions is 'Holds hashed admin passwords keyed by operation';
comment on column public.admin_permissions.operation is 'One of: language, path, category, subcategory, article, item';
comment on column public.admin_permissions.secret_hash is 'Hex-encoded hash of <salt>::password';
comment on column public.admin_permissions.salt is 'Per-operation salt for hashing';
