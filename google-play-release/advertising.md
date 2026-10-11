# Advertising integration and QA

Poing Studios Godot AdMob v5.1.0, Godot 4.6.3 native package, MIT. Only ads/UMP binaries are installed; no mediation adapters. Pinned archive SHA-256: `f7fdf644d50c0e231d8f02ae044057e489d0bcafcf50e908a4858477e7ee05ee`. The AAR declares Google Next-Gen SDK `com.google.android.libraries.ads.mobile.sdk:ads-mobile-sdk:1.4.0`; verify resolved graph, UMP and SDK disclosures during Android build.

Default build is offline; ad libraries disabled. Optional test ad variant is built with `HEXBOUND_TEST_ADS=1` or workflow `test_ads=true`. Native settings exposes a functional enable-test-ads switch only if native ads/consent plugins exist. Runtime starts with ads disabled on every launch, and only Google demo IDs are used. The user opts in, consent information is updated, a required form is shown, obtained/not-required status is checked, then SDK initialization and ad requests begin. Consent failure remains ad-free. Turning off ads discards preloaded ads; generation checks reject late loads. Privacy options are available when UMP requires them; refresh Settings after consent finishes to see them.

Rewarded ads are voluntary and only available on the completed-match screen after a real ad load, granting saved cosmetic beacon glow only from the earned-reward callback. Interstitials are shown at most every third completed match when moving to menu. Neither grants resources, extra actions or competitive advantage. Load/show errors do not block play. No active-turn, app-open, banner or forced rewarded ads.

## Native tests outstanding

- Build and install ad variant; verify test labels and all native singleton bindings.
- Consent required/not-required/error paths, regional/debug geography, unavailable network, form cancellation, privacy options changing consent, app restart.
- Real SDK callbacks: successful/failed loads, show/dismiss, reward once, interruption before reward, suspend/resume during ad, disable while load pending, expiry.
- No mid-game interstitial after pause/menu; interstitial cadence and result-menu callback; no stuck screen or unwanted click targets.
- Verify merged manifest, SDK startup before consent, traffic and complete data-safety disclosures. Never assume test IDs or an off switch imply zero SDK collection.
- Verify under-age/child-directed settings match the owner's audience choice before any live build.

These are **unrun**, not passing. Desktop tests validate only fail-closed behavior and placement guards. Live ad IDs require explicit authorization and an owner-created AdMob account/consent setup; none was requested or created.

## Future ad removal

No purchase button or fake entitlement is exposed. Before offering ad removal: add maintained Google Play Billing integration, products, acknowledgement, pending handling, restore/query purchases, refund/revocation handling, verified entitlement storage/backend where appropriate, Play license testers, and disclosure updates. A local boolean alone is not a purchase implementation. Ad-removal should suppress interstitials without automatically hiding user-requested optional rewards unless clearly disclosed.
