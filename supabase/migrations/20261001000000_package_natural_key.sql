-- =============================================================================
-- Natural key for destination packages: a destination never offers two
-- packages with the same (English) name. Also lets `seed.sql` upsert
-- idempotently with `on conflict (destination_id, name_en)`.
--
-- Safe to run more than once, and safe on an empty or populated catalog
-- (it fails loudly only if duplicate package names already exist).
-- =============================================================================
do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'destination_packages_destination_name_key'
      and conrelid = 'public.destination_packages'::regclass
  ) then
    alter table public.destination_packages
      add constraint destination_packages_destination_name_key unique (destination_id, name_en);
  end if;
end $$;
