# Test matrix

Automated evidence is in `validation.md`; do not mark unrun items as passed.

- [x] Godot project import and actual startup smoke.
- [x] Seeded map validity, 2–4 players and separated homes.
- [x] Roads, settlements, cities, beacons; placement/network/action/resource rules.
- [x] Dice, season production, blocked production, inventory, trade conservation.
- [x] Turn progression, storm resolution, prestige/diversity and terminal victory.
- [x] Atomic save/load, corrupt/missing saves and RNG continuation.
- [x] 45 AI-vs-AI matches across three difficulties and player counts.
- [x] UI button/tile hit-testing, actual tutorial progression, save/resume and stale AI cancellation.
- [x] Layout assertions at 1280×720, 1920×1080, 2400×1080 and 800×1280.
- [x] Actual desktop OpenGL/Mesa gameplay screenshots; desktop export startup.
- [x] No-native-ad fail-closed desktop behavior.
- [ ] Android AAB generation and bundletool validation.
- [ ] Release signature verification on actual signed AAB.
- [ ] Merged manifest/permission/native dependency audit.
- [ ] Real phones: API 26 baseline, API 36 current, narrow/ultrawide/tablet, cutouts/system bars, orientation changes and 16-KiB device.
- [ ] Touch accuracy/readability, screen-reader/accessibility/contrast and device performance/battery/heat.
- [ ] Suspend, force stop, restart, storage full, upgrade save compatibility, uninstall deletion, backup behavior.
- [ ] Real-device audio output and preference persistence.
- [ ] Native AdMob/UMP test matrix in `advertising.md`.
- [ ] Balance/playtesting with human testers; no commercial-polish certification from automated tests.
- [ ] Google Play pre-launch report, closed test if applicable and owner review.
