# Privacy policy draft — Hexbound Kingdoms

**DRAFT: owner review, legal identity, support contact, effective date and public hosting are required before publication.** Scope: the default offline build only. Do not use this draft unchanged for an advertising-enabled build.

Publisher: `[OWNER LEGAL/PUBLISHER NAME]`
Effective date: `[OWNER APPROVED DATE]`
Privacy contact: `[OWNER SUPPORT EMAIL]`

Hexbound Kingdoms runs without creating an account. The default offline game has no game backend, analytics SDK, advertising SDK initialization, online multiplayer, cloud synchronization or in-app purchases. Game progress and settings are stored locally in the application's private storage. These include map, inventory, turn state, sound/motion settings and optional cosmetic preferences. The game code does not send this information to the developer. The offline Android export is configured without Internet permission and with automatic Android user-data backup disabled; confirm these facts against the final merged manifest before making this policy public.

You can remove stored game progress and settings by clearing the app's storage in Android settings or uninstalling it. The application does not request camera, microphone, location, contacts or external-storage access. The Google Play store and device operating system may independently process information under their own policies. If you choose to email support, your email provider and the publisher receive the information you voluntarily include; the owner must define support retention and deletion handling.

Audience and children's policy must match the owner's final target-audience declaration. No child-audience representation or age rating has been approved by the owner. The current offline build has no chat or user content.

## Advertising variant — additional text must be completed before enabling live ads

The optional development Android advertising variant includes Google Mobile Ads Next-Gen SDK and User Messaging Platform through Poing Studios. It uses Google's test ad IDs, is off until opted into in settings, and attempts a consent update/form before SDK initialization and requests. This is not evidence that SDKs collect no data while disabled. SDK startup, manifest providers, regional consent, data sharing, identifiers, IP-derived location, diagnostics and ad interaction processing must be examined on the exact final build and checked against the SDK vendor's current disclosure documentation.

Do not make a "no collection" or "no sharing" declaration for that variant without verification. Before shipping it, explain Google's processing, purposes, retention, user controls, and policy links accurately; configure AdMob consent messages, privacy-options access and appropriate audience treatment; audit the final merged manifest and traffic; obtain appropriate review. Google: https://policies.google.com/privacy ; UMP: https://developers.google.com/admob/android/privacy . Any future purchase integration requires a new review and disclosure update.

This document does not establish legal compliance. The owner must review and publish a final policy at a publicly accessible URL linked from both the app and its Play listing where required.
