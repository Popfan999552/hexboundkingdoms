# Google Play submission worksheets — not final declarations

## Data safety

| Item | Default offline candidate | Advertising test variant |
|---|---|---|
| Game progress/settings | Device-only private storage; no game server | Same, plus cosmetic preference |
| Account/authentication | None | None |
| Location | Game requests none | SDK may derive approximate location from IP; verify |
| Personal information | Game requests none | Do not assume none; review SDK documentation and consent |
| Device/other identifiers | No game collection | Advertising/device identifiers may be collected/shared |
| App activity | No developer telemetry | Ad interactions and app signals may be processed |
| Diagnostics/performance | No game telemetry | SDK diagnostics may be processed |
| Sharing | No developer transfer in offline code | Google/partners; verify purposes and disclosure classification |
| Transit encryption | Offline game has no transit | Verify all SDK networking and declarations |
| Deletion | Clear storage or uninstall for local saves | Owner must verify SDK rights, retention and support process |

Final data-safety form must be based on **the exact shipped bundle**, dependencies, merged manifest and observed runtime, including third-party SDK behavior. Test ads are not exempt from SDK data processing. No form has been submitted. Support correspondence handling depends on the owner's actual support service.

## Content rating questionnaire

Candidate facts: abstract kingdoms; no depicted combat, blood, gore, sexual material, profanity, drugs, fear/horror narrative, user-generated content, messaging, gambling purchases or real-money prizes. Dice produce resources, with no stake/payout of money. No purchase system or simulated casino presentation. Offline strategy with fantasy storm blocking.

Owner must answer the current IARC questionnaire accurately, including regional questions and advertising variant content. No age-rating result is claimed. Ad content rating is capped at PG in test code; this does not determine the app's IARC rating.

## Advertising declaration

Default offline export has native advertising disabled/excluded. Confirm absence of ad SDK libraries in final bundle before declaring "No ads". Optional AdMob variant contains rewarded and interstitial ads and requires "Contains ads" even using test/development units if submitted. Live IDs are not authorized and are absent. Interstitials are allowed only between completed matches; voluntary rewarded content grants cosmetic glow. No ad interrupts active turns. Consent UI requires regional native-device testing.

## Target audience

Undecided by owner. Strategy content is suitable for general players but this does not establish a target age group. Candidate marketing is general/adult, not specifically directed to children. Owner must choose Console age bands honestly. If targeting children or mixed audiences, revisit Families policies, age screening, eligible ad SDKs and under-age flags **before release**. Do not ship existing adult-candidate ad configuration to children.

## App access

No login, account, subscription, region restriction or reviewer credentials. Launch → Begin a new kingdom or Learn by playing. Choose 2–4 kingdoms and difficulty; roll dice, use construction and trade, end turn. All game functionality is accessible offline. Any SDK-only ad content requires network and consent but is not necessary for strategy gameplay.

## Permissions and manifest review

Default preset: no Internet, network-state, location, camera, microphone or external-storage permissions; minimum 26, target 36, ARM64 and x86_64, backup disabled. Final offline merged manifest was generated and audited in GitHub Actions: API 36/minimum 26, backup off, non-debuggable and no unexpected permissions. Local SDK remains unlicensed/uninstalled.

Ad variant: Internet/network-state required for ad and consent HTTPS. Inspected Poing AAR manifest declares `android.permission.AD_ID`, Internet/network-state and native plugin metadata; the resolved Google SDK also contributes advertising identifiers and WorkManager components. The inspected native merged manifest added `READ_BASIC_PHONE_STATE`, `FOREGROUND_SERVICE`, `WAKE_LOCK`, and a package-scoped dynamic-receiver permission. Optional basic-phone-state access is now removed with a supported manifest-merger directive. The WorkManager foreground/wake permissions are retained only for the ad variant, and the custom receiver permission is accepted only with signature protection. Verify the final revised manifest and SDK runtime; the game itself never starts a foreground service. Determine any Play foreground-service declaration from actual SDK usage, not merely its transitive manifest. **Inspect merged manifest; do not infer final permissions from this preset.** No game feature needs location, camera, microphone, contacts or storage permissions. Remove unexpected requests only after diagnosing dependencies.

## Security, IP, purchases

No keystores or credentials in Git. Upload key held in GitHub secrets/ephemeral runner and Play App Signing used after owner enrollment. Bundle must be cryptographically verified. Names, vector terrain, UI prose, seasons/supplies and beacon diversity are original; generic genre mechanics still warrant overall IP/trademark review. No copied franchise name/logo/art/rulebook is used. Third-party license notices included. Purchases and ad-removal entitlement are not implemented; do not declare/market them.
