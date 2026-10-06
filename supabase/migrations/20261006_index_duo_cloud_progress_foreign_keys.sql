-- Cover foreign keys used by cascades and joins for cloud level state.

create index if not exists duo_level_progress_game_id_idx
  on public.duo_level_progress(game_id);

create index if not exists duo_level_progress_level_id_idx
  on public.duo_level_progress(level_id);

create index if not exists duo_active_sessions_game_id_idx
  on public.duo_active_sessions(game_id);

create index if not exists duo_active_sessions_level_id_idx
  on public.duo_active_sessions(level_id);
