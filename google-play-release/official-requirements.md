# Official requirements research

Retrieved 2026-10-11 through official HTTPS pages. Recheck immediately before submission; this is a research snapshot, not policy certification.

- **Target API:** https://developer.android.com/google/play/requirements/target-sdk — official page states new apps/updates must target Android 16 (API 36) or higher starting August 31, 2026. Project targets 36. Phone/tablet game; Wear/TV/XR exceptions are irrelevant.
- **Memory pages:** https://developer.android.com/guide/practices/page-sizes — fetched page discusses Play 16-KiB support and an update enforcement date of February 1, 2027. Do not rely on an old deadline or a date exemption; validate native alignment and actual 16-KiB device startup regardless. Matching official Godot 4.6.3 templates are used, but no Android runtime validation is claimed.
- **New personal accounts:** https://support.google.com/googleplay/android-developer/answer/14151465 — personal accounts created after November 13, 2023 must run a closed test with at least 12 testers opted in continuously for at least 14 days, then apply for production access. Account type/creation date is unknown; owner must determine applicability. Do not fabricate test participation.
- **Consent:** https://developers.google.com/admob/android/privacy — use UMP to update consent information, present required forms, and provide privacy options as required before advertising. Wrapper source is implemented; regions and device behavior remain to be tested. AdMob messages/account setup need owner action.
- **Data safety:** https://support.google.com/googleplay/android-developer/answer/10787469 — owner must check current form guidance and SDK collection. No declarations submitted.
- **App Signing:** https://support.google.com/googleplay/android-developer/answer/9842756 — owner must confirm enrollment/identity and manage upload key. No signing credentials created.

Play Console can impose additional account verification, device verification, payments profile, testing and policy obligations based on the owner's account. Identity, fees and legal acceptance remain personal actions. No public release/upload is authorized by these documents.
