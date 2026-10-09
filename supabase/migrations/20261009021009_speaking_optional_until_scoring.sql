-- The current Flutter speech_to_text adapter provides recognition accuracy,
-- but no trustworthy pronunciation/tone/fluency subscores. Keep speaking on
-- the adventure map while preventing an unavailable scorer from blocking the
-- chapter Boss. Re-enable this flag when a real speech scorer is connected.
update public.duo_game_definitions
set is_required_for_boss = false
where game_code = 'speaking'
  and is_required_for_boss = true;
