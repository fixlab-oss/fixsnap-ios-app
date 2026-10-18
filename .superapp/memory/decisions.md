# Decisions

- Backend is Cloud project wlsdinfxbesdrkqxxwbz (app Info.plist BOLT_DATABASE_URL/ANON_KEY must point here, not any other project).
- Edge functions `analyze-fault` (photo base64 -> GPT-4o diagnosis, storage, DB, Telegram photo, routed fixers) and `send-contact` (callback request -> `contact_requests` + Telegram). Both verify_jwt with anon key.
- Tables (`fault_reports`, `detected_parts`, `technicians`, `contact_requests`) are deny-all RLS; only functions (service role) access them. Advisor INFO "no policy" is intentional.
- Without `OPENAI_API_KEY` secret, analyze-fault returns a generic "awaiting review" diagnosis.
- Regions SG/LK get local fixers; others route to "Global fixers".
