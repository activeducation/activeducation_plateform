-- Crée une fonction qui insère automatiquement le nouvel utilisateur dans notre table public.users
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
begin
  insert into public.users (id, email, full_name, role, xp_points, level)
  values (
    new.id,
    new.email,
    new.raw_user_meta_data->>'full_name',
    'STUDENT',
    0,
    1
  );
  return new;
end;
$$;

-- Crée un déclencheur (trigger) qui écoute la création de compte sur Supabase Auth
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();
