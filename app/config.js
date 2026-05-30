// =============================================================================
// EUBC Transport App — configuration
// =============================================================================
// Fill in your Supabase project values below (see Transport Page/SETUP.md).
//
//   SUPABASE_URL     → Supabase dashboard → Project Settings → API → Project URL
//   SUPABASE_ANON_KEY→ Supabase dashboard → Project Settings → API → anon public key
//
// MEMBER_EMAIL and ADMIN_EMAIL are internal identifiers — club members only
// ever type a password; the email is fixed here and never shown to users.
// =============================================================================

window.EUBC_CONFIG = {
  SUPABASE_URL:     'https://kvwvjawzkrdjfbvtunaj.supabase.co', // Project Settings → API → Project URL
  SUPABASE_ANON_KEY:'sb_publishable_1rkqag-1qJU3Spiv-6oFVg_My8Pcpe7',                   // Project Settings → API → anon public key
  MEMBER_EMAIL:     'members@eubc.local',               // internal — members only type the password
  ADMIN_EMAIL:      'admin@eubc.local'                  // internal — secretary only types the password
};
