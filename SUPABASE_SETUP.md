# Supabase setup for Lucent

Lucent analyzes conversations in the browser by default. The optional cloud vault stores a transcript on a Supabase-hosted PostgreSQL database only after the user signs in, reviews the findings, and checks the cloud-save consent box. This changes the data boundary: the full transcript is sent to the configured Supabase project over HTTPS.

## 1. Create and configure a Supabase project

1. Create a project in your Supabase account and keep control of its dashboard.
2. In the Supabase SQL Editor, run [`supabase/schema.sql`](./supabase/schema.sql). This creates the conversation table and enables per-user row-level security (RLS).
3. In **Project Settings → API**, copy the project URL and the **publishable key** (or legacy `anon` key).
4. Edit `supabase-config.js`:

   ```js
   window.LUCENT_SUPABASE_CONFIG = {
     url: "https://YOUR_PROJECT_REF.supabase.co",
     anonKey: "YOUR_PUBLISHABLE_KEY"
   };
   ```

   The publishable/anon key is intended to be visible to a browser. **Never put a service-role key, database password, or other secret in this file or in client-side code.** The key is not user authorization: RLS and authenticated sessions protect each row.
5. In **Authentication → URL Configuration**, set the production site URL and add the exact app origin (and any local development origin) to the redirect URL allow-list so email confirmation can return to Lucent.
6. Serve Lucent from an HTTPS site or `localhost`. A `file://` browser tab may not be allowed to make cross-origin Supabase requests. For GitHub Pages, enable it under **Repository Settings → Pages → Deploy from a branch**, select `main` and `/ (root)`, then use `https://sameekshab2324-ship-it.github.io/ProtocolX-hackathon/`. Add that deployed app URL to Supabase's site URL and redirect allow-list. GitHub Pages makes the static app files public; the publishable key is designed for public clients, but the service-role key must never be published.

## 2. Try the cloud vault

1. Open Lucent from the configured HTTPS or localhost origin.
2. Create an account and complete email confirmation if the Supabase project requires it.
3. Sign in. The current browser session is kept in memory only; refreshing the page signs you out.
4. Analyze a transcript, select **Review & save**, check the findings, then select **Save reviewed copy to cloud**.
5. Read and check the separate consent box. The full transcript and included findings are uploaded. Use **Your server conversations** to open or delete saved items.

Local IndexedDB saving remains separate from cloud saving. Deleting a cloud conversation removes its row from this project; account deletion and backup-retention behavior are managed through the Supabase project.

## Data and security boundaries

- Rule-based analysis, edits, follow-through state, and the optional browser-provided AI run in the browser. Lucent does not send chat content to a hosted AI model.
- Supabase handles email/password authentication and PostgreSQL storage. Supabase's REST API is called directly by the browser; this prototype does not include a separate application server.
- The SQL enables RLS and restricts select/insert/update/delete to `auth.uid() = user_id`. Each row is associated with the authenticated account.
- Supabase receives the full transcript only on an explicit, acknowledged cloud save. Treat the selected Supabase project as a third-party data processor and check its privacy, region, backup, retention, and account settings before using real or sensitive conversations.
- Cloud rows are not end-to-end encrypted by Lucent. Supabase project administrators and the provider's systems handle stored data under the project's access and service policies.
- The small client-side pattern scan for emails, phone-like numbers, and credential-like strings is only a warning aid. It is not comprehensive detection, redaction, or a substitute for manual review.
- The access token and refresh token are held in JavaScript memory, not local storage. They are cleared when the tab reloads or the user signs out.
- The cloud vault loads up to the most recent 200 rows for display/search. The **Delete all** control deletes all rows for the signed-in account, including any beyond that display limit.

## Verification checklist before real use

- Confirm both `anon` and `authenticated` users cannot read another account's rows. Test with two separate accounts.
- Confirm an unsigned request cannot list or modify conversation rows.
- Confirm save requires the explicit cloud acknowledgement and deletion is scoped to the signed-in account.
- Keep the project URL and publishable key in the client config; keep all service-role keys and database credentials only in trusted server-side secret storage.
- Do not use a public demo project with real personal, work, medical, or otherwise sensitive conversations.
