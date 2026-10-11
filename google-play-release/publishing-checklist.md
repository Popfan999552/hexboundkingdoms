# Publication gate — do not publish automatically

1. Owner accepts/provisions licensed Android SDK and confirms unique package ID. Obtain successful Android artifact and inspect CI failures; never treat workflow configuration as build success.
2. Configure protected signing secrets; generate verified upload-signed AAB and enroll in Play App Signing. Review pinned third-party dependencies and final manifest. No unrelated permissions.
3. Perform full device matrix and optional ad-consent tests; resolve critical defects. Run bundletool validation, ELF alignment checks and 16-KiB native-device startup. Retake phone screenshots on final Android candidate.
4. Owner supplies actual developer/support identity, account verification/payment and hosted reviewed privacy URL. Finalize accurate data safety, audience, advertising, IARC and app-access forms based on shipped build.
5. Review game/app name and overall intellectual-property presentation. Confirm all third-party license notices are included. Finalize listing and release notes without unverified claims.
6. If shipping ads: owner authorizes live credentials, configures AdMob/UMP, verifies audience and SDK data processing, completes native QA and updates all declarations. Otherwise release the offline no-native-ad candidate. No purchase features may be claimed.
7. Owner runs internal and, if required, closed testing; for applicable new personal accounts, 12 continuously opted-in testers for 14 days and production-access application. Record genuine test evidence and pre-launch report.
8. Owner reviews final bundle, metadata, policies, country availability, pricing, version code and staged rollout decision.
9. **Public publication requires explicit owner approval.** No workflow in this repository submits or publishes to Play.
