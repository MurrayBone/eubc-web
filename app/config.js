// =============================================================================
// EUBC Transport App — configuration
// =============================================================================
// Fill in your Supabase project values below (see Transport Page/SETUP.md).
//
//   SUPABASE_URL     → Supabase dashboard → Project Settings → Data API → Project URL
//   SUPABASE_ANON_KEY→ Supabase dashboard → Project Settings → API Keys → Publishable key
//                      (or the legacy "anon public" key — either works)
//
// MEMBER_EMAIL and ADMIN_EMAIL are internal identifiers — club members only
// ever type a password; the email is fixed here and never shown to users.
// =============================================================================

window.EUBC_CONFIG = {
  SUPABASE_URL:     'https://YOUR-PROJECT.supabase.co', // Project Settings → Data API → Project URL
  SUPABASE_ANON_KEY:'YOUR-PUBLIC-KEY',                 // Project Settings → API Keys → Publishable (or legacy anon) key
  MEMBER_EMAIL:     'members@eubc.local',               // internal — members only type the password
  ADMIN_EMAIL:      'admin@eubc.local'                  // internal — secretary only types the password
};
