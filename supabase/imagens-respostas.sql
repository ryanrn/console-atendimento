-- Executar uma vez no SQL Editor do Supabase.
-- Imagens ilustrativas: não enviar dados pessoais, exames ou prontuários.
alter table public.console_respostas
  add column if not exists imagem_path text;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('console-respostas', 'console-respostas', false, 1048576, array['image/webp'])
on conflict (id) do update
set public = false,
    file_size_limit = 1048576,
    allowed_mime_types = array['image/webp'];

-- Somente usuários ativos do Console podem ler imagens.
create policy "console imagens leitura por membros ativos"
on storage.objects for select to authenticated
using (
  bucket_id = 'console-respostas'
  and exists (
    select 1 from public.console_membros m
    where m.user_id = (select auth.uid()) and m.ativo = true
  )
);

-- Gravação, substituição e remoção reservadas a administradores ativos.
create policy "console imagens upload admin"
on storage.objects for insert to authenticated
with check (
  bucket_id = 'console-respostas'
  and exists (
    select 1 from public.console_membros m
    where m.user_id = (select auth.uid()) and m.ativo = true and m.papel = 'admin'
  )
);
create policy "console imagens atualizar admin"
on storage.objects for update to authenticated
using (
  bucket_id = 'console-respostas'
  and exists (
    select 1 from public.console_membros m
    where m.user_id = (select auth.uid()) and m.ativo = true and m.papel = 'admin'
  )
)
with check (
  bucket_id = 'console-respostas'
  and exists (
    select 1 from public.console_membros m
    where m.user_id = (select auth.uid()) and m.ativo = true and m.papel = 'admin'
  )
);
create policy "console imagens excluir admin"
on storage.objects for delete to authenticated
using (
  bucket_id = 'console-respostas'
  and exists (
    select 1 from public.console_membros m
    where m.user_id = (select auth.uid()) and m.ativo = true and m.papel = 'admin'
  )
);
-- IMPORTANTE: A coluna imagem_path é atualizada pelo cliente.
-- Revise as políticas UPDATE/INSERT já existentes de console_respostas
-- para garantir que apenas administradores possam alterar qualquer coluna.
