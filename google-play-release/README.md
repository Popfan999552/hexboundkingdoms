# Release package — development build 0.1.0

**Not ready for Google Play submission.** Gameplay and desktop validation are available; Android export is blocked locally by unaccepted SDK licenses; GitHub’s preprovisioned SDK successfully built the unsigned bundle without accepting new terms. Unsigned offline AABs have been generated and validated in Actions, including the updated touch-control build. Final artifact links and any emulator result are recorded in validation.md. Native ad packaging and its revised permission audit passed in Actions run 38183634200; emulator testing is still in progress. No AAB was generated locally in this cloud instance. Native ads, signing, Android install/resume behavior, real touchscreen ergonomics, and physical-device performance have not been validated. The offline bundle passed bundletool, merged manifest and native alignment audits in Actions. This README must be updated after a successful CI/device run; a configured workflow is not evidence of a successful workflow run.

Prepared files:
- `app-icon-512.png`: original 512 × 512 opaque Play icon.
- `feature-graphic-1024x500.png`: original store feature artwork.
- `screenshots/`: actual Godot gameplay captures; desktop viewport renders, **not captures from physical Android phones**. Retake on Android before submission if device-specific presentation differs.
- `store-listing.md`: accurate offline feature descriptions, contact placeholders.
- `privacy-policy.md`: offline draft plus separate advertising variant caveats; not a published policy.
- `compliance.md`: data safety, audience, ads, rating, access and permission worksheets; owner answers required.
- `signing.md`: secure upload key/Play App Signing preparation.
- `advertising.md`: test-only consent/ad QA and future purchase requirements.
- `testing-checklist.md`, `publishing-checklist.md`, `release-notes.md`, `third-party-notices.md`, `official-requirements.md`, `validation.md`.

A successful Android CI run uploads `hexbound-unsigned.aab` or `hexbound-signed.aab` in the `android-bundle-<run number>` artifact and copies it into this folder within that artifact. Bundles are intentionally ignored by Git. An unsigned bundle cannot be submitted. A signed bundle is not by itself a release certification.

Required owner actions: accept/provision Android SDK licensing; securely provide an upload key if signing is wanted; confirm package ID and store identity; provide a support contact and host a reviewed privacy policy; decide audience/distribution/monetization and verify SDK disclosures; complete Play Console identity/account/payment/testing requirements; approve publication explicitly. Physical Android QA and final IP/privacy review remain necessary. No purchase or account creation has been performed.
