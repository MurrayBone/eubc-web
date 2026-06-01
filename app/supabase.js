// =============================================================================
// EUBC Transport App — Supabase helper layer
// =============================================================================
// Prerequisites (must be loaded before this script):
//   1. Supabase UMD client  → exposes the global `supabase` object with createClient
//   2. app/config.js        → exposes window.EUBC_CONFIG
//
// This file builds window.EUBC, a flat object of async helper functions.
// Every function throws on error so callers can handle it with try/catch.
// =============================================================================

(function () {
  'use strict';

  // --------------------------------------------------------------------------
  // Internal: lazily-created Supabase client
  // --------------------------------------------------------------------------
  let _client = null;

  function getClient() {
    if (!_client) {
      // Strip any trailing slash/whitespace — a trailing "/" makes the client
      // build "…supabase.co//rest/v1/…", which PostgREST rejects (PGRST125).
      var url = String(EUBC_CONFIG.SUPABASE_URL || '').trim().replace(/\/+$/, '');
      var key = String(EUBC_CONFIG.SUPABASE_ANON_KEY || '').trim();
      _client = supabase.createClient(url, key);
    }
    return _client;
  }

  // Unwrap a Supabase response; throw if there is an error.
  function unwrap({ data, error }) {
    if (error) throw error;
    return data;
  }

  // --------------------------------------------------------------------------
  // Auth
  // --------------------------------------------------------------------------

  async function signIn(role, password) {
    const email =
      role === 'admin'
        ? EUBC_CONFIG.ADMIN_EMAIL
        : EUBC_CONFIG.MEMBER_EMAIL;
    return unwrap(
      await getClient().auth.signInWithPassword({ email, password })
    );
  }

  async function signOut() {
    return unwrap(await getClient().auth.signOut());
  }

  async function getSession() {
    const { data, error } = await getClient().auth.getSession();
    if (error) throw error;
    return data.session; // null when not signed in
  }

  async function getRole() {
    const session = await getSession();
    if (!session) return null;
    const { data, error } = await getClient()
      .from('profiles')
      .select('role')
      .eq('id', session.user.id) // admin can read all rows; scope to self
      .single();
    if (error) return null; // no profile row → treat as unauthenticated
    return data.role; // 'admin' | 'member'
  }

  // Redirect to redirectTo if the current user's role !== role.
  // Returns true if the role matched, false (after redirect) if not.
  async function requireRole(role, redirectTo) {
    const current = await getRole();
    if (current !== role) {
      window.location.href = redirectTo;
      return false;
    }
    return true;
  }

  // --------------------------------------------------------------------------
  // Roster — members table
  // --------------------------------------------------------------------------

  async function listMembers({ activeOnly = false } = {}) {
    let query = getClient()
      .from('members')
      .select('*')
      .order('squad', { ascending: true, nullsFirst: false })
      .order('short_name', { ascending: true });
    if (activeOnly) {
      query = query.eq('active', true);
    }
    return unwrap(await query);
  }

  async function upsertMember(member) {
    if (member.id) {
      // Update existing row
      const { id, ...fields } = member;
      return unwrap(
        await getClient()
          .from('members')
          .update(fields)
          .eq('id', id)
          .select()
          .single()
      );
    }
    // Insert new row
    return unwrap(
      await getClient()
        .from('members')
        .insert(member)
        .select()
        .single()
    );
  }

  async function setMemberActive(id, active) {
    return unwrap(
      await getClient()
        .from('members')
        .update({ active })
        .eq('id', id)
        .select()
        .single()
    );
  }

  async function setMemberCanDrive(id, can_drive) {
    return unwrap(
      await getClient()
        .from('members')
        .update({ can_drive })
        .eq('id', id)
        .select()
        .single()
    );
  }

  async function deleteMember(id) {
    return unwrap(
      await getClient()
        .from('members')
        .delete()
        .eq('id', id)
    );
  }

  // Bulk insert an array of member objects (no id fields expected).
  async function bulkImportMembers(rows) {
    return unwrap(
      await getClient()
        .from('members')
        .insert(rows)
        .select()
    );
  }

  // --------------------------------------------------------------------------
  // Reference data
  // --------------------------------------------------------------------------

  async function listPickupLocations() {
    return unwrap(
      await getClient()
        .from('pickup_locations')
        .select('*')
        .order('sort_order', { ascending: true })
    );
  }

  async function upsertPickupLocation(loc) {
    if (loc.id) {
      const { id, ...fields } = loc;
      return unwrap(
        await getClient()
          .from('pickup_locations')
          .update(fields)
          .eq('id', id)
          .select()
          .single()
      );
    }
    return unwrap(
      await getClient()
        .from('pickup_locations')
        .insert(loc)
        .select()
        .single()
    );
  }

  async function deletePickupLocation(id) {
    return unwrap(
      await getClient()
        .from('pickup_locations')
        .delete()
        .eq('id', id)
    );
  }

  async function listClubVehicles() {
    return unwrap(
      await getClient()
        .from('club_vehicles')
        .select('*')
        .order('code', { ascending: true })
    );
  }

  // --------------------------------------------------------------------------
  // Transport plans
  // --------------------------------------------------------------------------

  async function getLatestPublishedPlan() {
    const { data, error } = await getClient()
      .from('transport_plans')
      .select('*')
      .eq('published', true)
      .order('session_date', { ascending: false })
      .limit(1)
      .single();
    // PostgREST returns a PGRST116 "no rows" error when there are no results;
    // treat that as null rather than throwing.
    if (error) {
      if (error.code === 'PGRST116') return null;
      throw error;
    }
    return data;
  }

  async function getPlanByDate(date) {
    const { data, error } = await getClient()
      .from('transport_plans')
      .select('*')
      .eq('session_date', date)
      .single();
    if (error) {
      if (error.code === 'PGRST116') return null;
      throw error;
    }
    return data;
  }

  async function listPlans() {
    return unwrap(
      await getClient()
        .from('transport_plans')
        .select('*')
        .order('session_date', { ascending: false })
    );
  }

  // Upsert on session_date. Automatically stamps updated_at.
  async function savePlan({ session_date, departure_time, data, published }) {
    const obj = {
      session_date,
      departure_time,
      data,
      published: published ?? false,
      updated_at: new Date().toISOString()
    };
    return unwrap(
      await getClient()
        .from('transport_plans')
        .upsert(obj, { onConflict: 'session_date' })
        .select()
        .single()
    );
  }

  async function publishPlan(session_date) {
    return unwrap(
      await getClient()
        .from('transport_plans')
        .update({ published: true, updated_at: new Date().toISOString() })
        .eq('session_date', session_date)
        .select()
        .single()
    );
  }

  // --------------------------------------------------------------------------
  // App settings (single row with id = 1)
  // --------------------------------------------------------------------------

  async function getSettings() {
    return unwrap(
      await getClient()
        .from('settings')
        .select('*')
        .eq('id', 1)
        .single()
    );
  }

  async function updateSettings(patch) {
    return unwrap(
      await getClient()
        .from('settings')
        .update(patch)
        .eq('id', 1)
        .select()
        .single()
    );
  }

  // --------------------------------------------------------------------------
  // Expose as window.EUBC
  // --------------------------------------------------------------------------

  window.EUBC = {
    // The raw Supabase client (escape hatch for anything not covered above)
    get client() { return getClient(); },

    // Auth
    signIn,
    signOut,
    getSession,
    getRole,
    requireRole,

    // Roster
    listMembers,
    upsertMember,
    setMemberActive,
    setMemberCanDrive,
    deleteMember,
    bulkImportMembers,

    // Reference data
    listPickupLocations,
    upsertPickupLocation,
    deletePickupLocation,
    listClubVehicles,

    // Plans
    getLatestPublishedPlan,
    getPlanByDate,
    listPlans,
    savePlan,
    publishPlan,

    // Settings
    getSettings,
    updateSettings
  };
})();
