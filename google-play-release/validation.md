# Executed validation

Godot **4.6.3**, real Codex cloud commands and real GitHub Actions runs. Current game code: commit `b097811` (later changes only import captures/documentation/diagnostic reporting).

| Check | Actual result |
|---|---|
| Headless project import | Passed with strict log checking |
| Gameplay suite | **77,795 assertions passed, 0 failed** |
| Entire AI matches | **45/45** reached a winner across all three difficulties and 2–4 kingdoms |
| UI/layout suite | **43 checks passed, 0 failures**: real controls, hit testing, tutorial, trades, save/resume, AI cancellation, zoom/pinch/recenter, desktop/portrait layouts and mobile typography/targets |
| Game startup smoke | Passed |
| Linux x86_64 release export | Generated and startup smoke passed |
| Store image metadata | 512×512 RGBA32 icon and 1024×500 RGB24 feature graphic passed checks |
| GitHub workflows | actionlint 1.7.12 passed; workflows actually executed |
| Shell/Python tools | bash syntax and Python compilation passed |
| Signing-log redaction | Synthetic-value test passed; sensitive value removed while normal diagnostics remained |
| Official engine/templates and native plugin archives | Pinned official SHA-256 checks passed |
| Offline Android AAB | **Passed**, final mobile UI, bundletool, SDK/package/permission/backup/debuggable manifest audit and 16-KiB ELF alignment |
| Native AdMob/UMP test AAB | **Passed**, actual native plugin metadata, Google test app ID, networking, signature-protected receiver, allowed WorkManager permissions, **phone-state permission removed**, bundletool and 16-KiB ELF alignment |
| Android API 35 x86_64 emulator | **Passed**: install, launch, functional dice/turn transition, native plugin registration, no checked app runtime errors, actual landscape gameplay capture |
| Release signing attempt | **Blocked** at upload-key preparation; no signed release AAB produced |
| Real devices, actual ad load/show/reward/consent behavior, 16-KiB device runtime, Play pre-launch/closed testing | **Unrun**; do not treat emulator or packaging checks as these tests |

Verified Actions runs:
- [Final offline build, all required jobs passed](https://github.com/Popfan999552/hexboundkingdoms/actions/runs/38187464840).
- [Final native test-ad build and full Android emulator workflow, all three jobs passed](https://github.com/Popfan999552/hexboundkingdoms/actions/runs/38187464887).
- [Release signing attempt, stopped at credential preparation](https://github.com/Popfan999552/hexboundkingdoms/actions/runs/38187728448). Required repository Actions secret group: `ANDROID_UPLOAD_KEY_BASE64`, `ANDROID_UPLOAD_KEY_ALIAS`, `ANDROID_UPLOAD_KEY_PASSWORD`. The owner must configure/verify valid values securely; no values were requested in chat or exposed. Direct secret metadata access was denied by the integration, so individual secret availability is not claimed.

Downloadable bundles (unsigned; artifact retention 14 days):
- [Offline release package — android-bundle-22](https://github.com/Popfan999552/hexboundkingdoms/actions/runs/38187464840/artifacts/11719968452), file `google-play-release/hexbound-unsigned.aab` (also under `build/` in the artifact).
- [Native test-ad package — android-bundle-23](https://github.com/Popfan999552/hexboundkingdoms/actions/runs/38187464887/artifacts/11719469277).
- [Actual Android emulator QA evidence — android-emulator-qa-23](https://github.com/Popfan999552/hexboundkingdoms/actions/runs/38187464887/artifacts/11719319874).

Earlier failures were investigated and resolved: bank selector treated bank as player zero; a wrapped hint displaced the board; editor overrides initially omitted native ad libraries; SDK added optional phone-state permission; a deprecated SwiftShader backend hit shader limits; CI lacked ripgrep; the first screenshot included Android's fullscreen hint. The final workflow uses supported ANGLE software rendering, portable Python log checks and clean OS-hint dismissal. None of those earlier failed checks was counted as a pass.

Tests use separate application-data directories and cannot overwrite a developer's local save. Normal editor-lifecycle configuration replaced a shutdown-error-prone custom loop. Local Android SDK installation remains unavailable because its terms were left unaccepted; GitHub used its existing provisioned SDK without accepting new agreements. This does not block the generated unsigned artifacts.

Final deliverable assembly passed in [Actions run 38188219362](https://github.com/Popfan999552/hexboundkingdoms/actions/runs/38188219362). [Complete release package artifact](https://github.com/Popfan999552/hexboundkingdoms/actions/runs/38188219362/artifacts/11720586284): `google-play-release.zip` contains the validated offline unsigned AAB, current clean Android capture, descriptions, privacy/compliance drafts, licenses, manifest audits and SHA-256 bundle provenance. This is the current package to review; signing and owner submission gates remain.
