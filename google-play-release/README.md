# Google Play release package — 0.1.0 development candidate

**Not ready for Google Play submission.** The complete offline game, tests, Android bundle automation and native test-ad integration are prepared. The final full Android workflow, including API 35 emulator gameplay and clean screenshot capture, passed. Unsigned AABs were successfully generated and validated in GitHub Actions. Release signing stopped at credential preparation. Real-device/ad-consent QA and owner policy/identity requirements remain.

Prepared deliverables:
- `app-icon-512.png`: original opaque 512×512 RGBA32 Play icon.
- `feature-graphic-1024x500.png`: original RGB24 feature artwork.
- `screenshots/android-emulator-api35.png`: actual running Android gameplay, API 35 x86_64 emulator, 1920×1080. Its adjacent QA JSON records executed checks. **Not a physical-phone capture.**
- Other `screenshots/` images: actual desktop Godot gameplay renders.
- `store-listing.md`, `release-notes.md`: accurate offline features and owner contact placeholders.
- `privacy-policy.md`, `compliance.md`: drafts/worksheets, **not submitted declarations**.
- `signing.md`, `advertising.md`, `official-requirements.md`, `testing-checklist.md`, `publishing-checklist.md`.
- `third-party-notices.md`, complete notices in `licenses/`.
- `validation.md`: exact executed results and downloadable artifact links.

[Download the complete final release package](https://github.com/Popfan999552/hexboundkingdoms/actions/runs/38188219362/artifacts/11720586284). The artifact contains `google-play-release.zip`; extract it to obtain `google-play-release/hexbound-unsigned.aab`, the final clean capture, all current store/compliance materials, license notices, manifest audits and bundle provenance. Bundles are deliberately not committed to Git. The optional [native test-ad artifact](https://github.com/Popfan999552/hexboundkingdoms/actions/runs/38187464887/artifacts/11719469277) uses Google demo IDs only. Artifacts expire after 14 days. The final clean emulator screenshot is retained here in Git; older artifacts can contain an earlier capture.

Owner actions still required:
1. Configure/verify the three upload-key Actions secrets documented in `signing.md`, then run a signed build and verify its certificate. No release/upload key was generated or committed by this task.
2. Confirm package ID, publisher/support identity, public reviewed privacy-policy URL, accurate Play Console declarations and any applicable account/closed-testing requirements.
3. Arrange actual device, accessibility/balance, audio, lifecycle and 16-KiB runtime QA. If releasing with ads, configure owned AdMob/UMP messages, explicitly authorize live IDs and verify real consent/load/show/reward behavior and SDK data processing. No purchases/ad-removal entitlement are implemented or offered.
4. Review IP/name/presentation and third-party/SDK obligations, and explicitly approve public publication. Nothing was uploaded or published to Google Play; no accounts or purchases were made.

The reusable cloud install/start/configuration draft is saved separately. Review/save/publish it in environment settings to retain the prepared development environment. Draft saving is not publication or proof of restoration in a new task.
