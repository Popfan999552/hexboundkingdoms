# Hexbound Kingdoms

Original offline hex-territory strategy game, Godot **4.6.3**, GDScript, Android landscape with portrait/tablet fallback. This repository began empty. This is a playable development release, **not a certified commercial release**. See [release status](google-play-release/README.md).

## Play

Open `project.godot` in Godot 4.6.3 and run. Choose 2–4 kingdoms (one human with 1–3 offline AI), difficulty, or interactive tutorial. Roll, resolve a storm on seven, spend two actions, then end the turn. Click/tap territories to inspect or build. Road construction requires two adjacent selections. Green outlines identify legal city/settlement/beacon targets. Save automatically after actions and AI turns; resume from main menu. Settings persist locally. No accounts or multiplayer networking.

**Original rules:** Roads join hex centers; settlement sites occupy territories, with an empty neighboring ring. Five rotating seasons increase one biome's production and guarantee supplies. Beacons grant prestige and reward biome diversity. Storms deny production and grant salvaged Ember without theft or discards. Reach 12 prestige. Full charter and costs are accessible in-game. The familiar genre elements (hexes, dice, roads, trade) are not a copied board layout or rulebook. Obtain name/trademark and overall presentation review before commercial publication.

## Develop and test

```bash
cd /workspace/hexboundkingdoms
./tools/check.sh
./tools/godot.sh --path .
```

`tools/godot.sh` places cloud data/config/cache under `/workspace/.hexbound`, avoiding unwritable home directories. Set XDG paths yourself outside this cloud workspace. Use the existing isolated checkout; do not create a worktree unless explicitly requested. Rule model: `scripts/game.gd`; custom board renderer: `scripts/board.gd`; UI/save/tutorial: `scripts/main.gd`; consent-gated advertising: `scripts/ads.gd`.

Tests include seeded generation, placement/cost/network restrictions, all player inventories, seasonal/dice production, bank and rival trading, storm progression, prestige/victory, corrupt saves, deterministic RNG continuation, 45 entire AI matches, actual UI controls and tutorial, AI cancellation, and four layout sizes. The runner checks exit statuses and error logs, because Godot import can exit zero with script errors.

## Export

```bash
export XDG_DATA_HOME=/workspace/.hexbound/data
python3 tools/install_godot.py --cache /tmp/hexbound-downloads
# For Android: owner-provisioned licensed SDK, API 36, build-tools 36.1.0,
# platform-tools, full JDK 21. No script accepts SDK licenses.
export ANDROID_HOME=/path/to/licensed/sdk
export JAVA_HOME=/path/to/jdk21
./tools/build_android.sh
```

Godot/template downloads and Poing native plugin archives use pinned SHA-256 checks. No verification is disabled. App ID: `com.hexboundkingdoms.game` (owner must confirm uniqueness before first upload); minimum API 26; target API 36; ARM64 and x86_64; local backup disabled; offline export requests no optional permissions. AAB unsigned by default. `tools/build_android.sh` restores its preset edits and preserves existing local overrides by refusing to overwrite them. Run releases from a clean checkout. See [signing instructions](google-play-release/signing.md).

GitHub Actions runs gameplay/UI tests, desktop export, gameplay capture, then an unsigned Android bundle on branch pushes. It signs only on an explicit workflow dispatch with configured signing secrets. It does not publish, upload to Play, accept SDK agreements, or generate a real key. Artifact logs remain available when builds fail. GitHub runner SDKs must already have owner-authorized licenses; missing acceptance fails clearly.

## Advertising

Vendored Poing Studios Godot AdMob **5.1.0**, MIT; native build **4.6.3** fetched with checksums. Default export excludes native ad libraries and has Internet off. Dispatch CI with `test_ads=true` or set `HEXBOUND_TEST_ADS=1` to include ads/UMP, then enable test ads in Android Settings. Test IDs only. Consent update/form must complete before SDK initialization or ad requests; failures leave ads unavailable. Rewarded ads are voluntary on the results screen and unlock a cosmetic glow, never strategic advantages. Interstitials only between completed matches, every third match. No app-open ads, banners, analytics, or mediation. Purchases/ad-removal **are not implemented or advertised**. See [advertising QA](google-play-release/advertising.md); native behavior is unverified until tested on devices.

## Assets and rights

Original terrain/castle graphics are procedural vector art; sound effects are synthesized in code. Original launcher/feature artwork is reproducible using `python3 tools/generate_assets.py` (Pillow; system DejaVu font). Screenshots are captured from the running Godot renderer, not mocked UI. `third-party-licenses/` contains engine, bundled engine libraries, plugin, and font notices. Original project content has no public license grant; third-party components retain their listed licenses. No signing credentials, passwords, real ad IDs, or account identities are committed.
