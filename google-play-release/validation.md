# Executed validation — 2026-10-11

Executed in the Codex cloud machine using Godot 4.6.3. Outputs are not claims about physical Android devices or unexecuted GitHub Actions runs.

| Check | Actual result |
|---|---|
| Godot headless editor import | Passed; error-scanning runner, no script/import errors |
| Gameplay suite | 77,795 assertions passed, 0 failed |
| Complete AI simulations | 45/45 matches reached a winner; all difficulties and 2–4 kingdoms |
| Interactive UI suite | 30 checks passed, 0 failed; tutorial controls, hit testing, trade, saves, AI cancellation, four viewport layouts |
| Running game startup smoke | Passed |
| Linux x86_64 release export | Generated `build/hexbound-linux.x86_64` and startup smoke passed |
| Actual rendered screenshots | Captured via Xvfb + OpenGL/Mesa llvmpipe; original 1280×800 and phone-aspect 1920×1080 captures |
| GitHub workflow syntax | actionlint 1.7.12 passed after correcting invalid runner-context references |
| Shell/Python tools | `bash -n` and `python3 -m py_compile` passed |
| Official Godot templates | SHA-256 matched official GitHub release digest |
| Official template ARM64/x86_64 native ELF alignment | All LOAD segments of engine and libc++ libraries aligned at 16,384 bytes; **template-only**, not final-bundle/device verification |
| Poing native ads/UMP package | Pinned SHA-256 verified; consent singleton classes confirmed in AAR; no device/runtime ad test |
| Full JDK | `javac 21.0.12.1` verified after local package extraction |
| Android SDK installation | Prerequisites skipped because license was not accepted; no terms accepted on user's behalf |
| Android build command | Failed prerequisite check: API 36 `android.jar` absent; no AAB generated locally |
| Signed bundle / bundletool / merged manifest / device tests | Unrun, pending licensed SDK/signing/device access |

The UI suite initially exposed a bank-selector bug and portrait test setup issue; both were corrected and the suite rerun successfully. Earlier default-home cache failures were corrected with writable XDG directories. No failure has been relabeled as a pass. Advertising/purchase/publication readiness is not claimed.
