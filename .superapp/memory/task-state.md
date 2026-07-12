# Task State

## Current goal

FixSnap: AI-assisted repair diagnosis app (SG + LK only). First screen (home) built per product spec; full backend/Bolt integration, capture flow, and result screen are still placeholders/mockups per the "first screen only" scope rule.

## Recently changed

- FixSnap/Theme.swift — FSColor palette (ink/teal/flame), FSBadge, FSCard
- FixSnap/Views/HomeView.swift — hero, how-it-works, features grid, Telegram network explainer, footer
- FixSnap/Views/CaptureFlowView.swift, FixSnap/Views/ResultPreview.swift — placeholder secondary-flow previews (sheet-based, not full implementations)
- FixSnap/Models/SampleData.swift — sample DetectedPart/Technician/SampleFaultReport data
- App icon generated (teal/flame wrench glyph on ink background)

## Open issues

- No Bolt Database (Supabase) SDK integration yet — no real analyze-fault/send-contact calls, no camera/location/MapKit wiring.
- Capture flow and result screen are mockups only (per scope: build only first screen unless asked for more).

## Next step

If the user wants the real capture → AI diagnosis → result flow, next steps: add supabase-swift package, wire AVFoundation camera + CoreLocation region gate, call analyze-fault edge function, build the full result screen (parts overlay, technicians list, MapKit shops, contact form).
