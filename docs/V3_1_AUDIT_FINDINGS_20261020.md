# V3-1 audit follow-up

Live Supabase read-only checks, 2026-10-20:

- 9,727 select/assist/listenTap questions: zero missing or empty answer and choice arrays.
- 3,061 duplicate-looking groups, or 6,716 rows above one per group, grouped by challenge type, session, prompt, and choices. These are candidates only; answers, audio, and instructional intent can differ. Do not delete automatically.
- Zero challenge-to-session orphan records and zero example-to-word orphan records.

All checks are structural, not proof of accurate Mandarin or Vietnamese translations. Next step is bilingual content review, especially Unit sec_1_unit_1. No production content was modified. Python/Flutter runtime tests have not been run in this session.
