# EUBC Transport App — Setup Guide

This guide walks you through getting the transport app live. No coding knowledge needed — just follow the steps in order. The whole process takes about 15 minutes.

---

## Step 1 — Create a free Supabase project

1. Go to [supabase.com](https://supabase.com) and sign up or log in.
2. Click **New project**, choose a name (e.g. `eubc-transport`), pick the closest region (Ireland — `eu-west-1` is fine), set a strong database password, and click **Create new project**.
3. Wait about a minute for the project to spin up.
4. Find your credentials: go to **Project Settings** (gear icon, bottom-left) → **API**.
   - Copy the **Project URL** — it looks like `https://xxxxxxxxxxxx.supabase.co`
   - Copy the **anon public** key — a long string starting with `eyJ…`

Keep these two values handy; you'll need them in Step 4.

---

## Step 2 — Run the database setup script

1. In the left sidebar, click **SQL Editor** → **New query**.
2. Open the file `supabase_setup.sql` (in this repo) in any text editor, select all, and paste it into the SQL Editor.
3. Click **Run** (or press Cmd/Ctrl + Enter).
4. You should see "Success. No rows returned." at the bottom. If there are any red errors, copy them and ask for help — but running the script a second time is always safe.

---

## Step 3 — Create the two login users

The app uses two shared accounts: one for the whole squad, one for the secretary / admin.

1. In the left sidebar, click **Authentication** → **Users** → **Add user** → **Create new user**.
2. Create the **members account**:
   - Email: `members@eubc.local`
   - Password: choose a password and share it with the squad (e.g. via your group chat)
   - **Tick "Auto Confirm User"** — this skips the email-verification step, which would fail because `@eubc.local` is not a real email domain.
   - Click **Create user**.
3. Create the **admin account**:
   - Email: `admin@eubc.local`
   - Password: choose a strong password and keep it private (secretary / treasurer only)
   - **Tick "Auto Confirm User"** again.
   - Click **Create user**.

> **How roles work:** The database trigger you ran in Step 2 automatically gives `admin@eubc.local` the admin role and every other account the member role. You do not need to configure this manually.

---

## Step 4 — Add your Supabase credentials to the app

Open the file `app/config.js` in this repo. It looks like this:

```js
// app/config.js
const SUPABASE_URL  = 'YOUR_PROJECT_URL';
const SUPABASE_ANON_KEY = 'YOUR_ANON_KEY';
```

Replace `YOUR_PROJECT_URL` with the Project URL you copied in Step 1, and `YOUR_ANON_KEY` with the anon public key. Save the file.

---

## Step 5 — Publish with GitHub Pages

1. Commit and push your changes to the `main` branch on GitHub.
2. On GitHub, go to your repository → **Settings** → **Pages**.
3. Under **Source**, select **Deploy from a branch**, choose `main`, folder `/` (root), and click **Save**.
4. After a minute or two, GitHub will show you the live URL (e.g. `https://yourusername.github.io/eubc-transport/`).

Key pages:
- **Members view** (transport plans): `…/members.html`
- **Admin / secretary view**: `…/admin.html` — keep this URL private; it is not linked from the main site.

---

## Step 6 — Updating the roster each season

Log in at `admin.html` using the admin password. Open the **Roster** tab to:

- **Deactivate** members who have left (they disappear from plans but their history is kept).
- **Add** new members individually, or use the **bulk import** option to paste a list.
- **Edit** any member's full name, squad, or pickup location.

No SQL knowledge required — everything is managed through the admin interface.

---

## Security note

The anon key pasted into `app/config.js` is intentionally public — it is the same key Supabase puts in every client app, and it only allows access according to the Row-Level Security rules you set up in Step 2. Specifically:

- Members logging in can only see **published** transport plans and their own profile. They cannot see student numbers or other members' details.
- Only the admin account can create or edit plans, manage the roster, or change settings.
- To change a password at any time: Supabase dashboard → **Authentication** → **Users** → click the user → **Send password recovery** (or set a new password directly from the dashboard).
