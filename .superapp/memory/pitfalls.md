# Pitfalls

- A pasted Supabase URL/key from another project made the app call the wrong backend; always confirm with supabase_get_project_url.
- supabase_get_edge_function may return null; redeploy full source instead of patching.
- Never keep secrets (Telegram token) in app code or chat; rotate if pasted.
