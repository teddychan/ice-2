# Upstream PR Audit

Audited against jordanbaird/Ice open PRs on 2026-06-25, with priority on macOS 26 compatibility, security, and performance.

| PR | Decision | Notes |
| --- | --- | --- |
| [#956](https://github.com/jordanbaird/Ice/pull/956) | Fixed manually | Direct patch had a Swift compile issue; ported the safe display ID and bezel/copy crash fixes instead. |
| [#953](https://github.com/jordanbaird/Ice/pull/953) | Merged | Safe XPC Team ID guard for ad-hoc/local builds on macOS 26. |
| [#950](https://github.com/jordanbaird/Ice/pull/950) | Skipped | Duplicate of #953; #953 is the cleaner implementation. |
| [#948](https://github.com/jordanbaird/Ice/pull/948) | Skipped | Large localization/workflow PR with unrelated UI behavior and CI artifact packaging; not macOS 26 focused. |
| [#945](https://github.com/jordanbaird/Ice/pull/945) | Fixed manually | Ported the Sparkle activation fix without stale project changes. |
| [#944](https://github.com/jordanbaird/Ice/pull/944) | Merged | CompactSlider API compatibility fix. |
| [#942](https://github.com/jordanbaird/Ice/pull/942) | Fixed manually | Ported accessible limited-mode button color and asset. |
| [#940](https://github.com/jordanbaird/Ice/pull/940) | Partially merged | Used the macOS 26 baseline and selected safe fixes; skipped local signing/build-artifact changes. |
| [#933](https://github.com/jordanbaird/Ice/pull/933) | Fixed manually | Ported overlay-above-menu-bar exclusion for show-on-click. |
| [#928](https://github.com/jordanbaird/Ice/pull/928) | Merged | Improves macOS 26 permission handling and relaunch flow. |
| [#923](https://github.com/jordanbaird/Ice/pull/923) | Merged | Improves spacing application reliability across apps. |
| [#922](https://github.com/jordanbaird/Ice/pull/922) | Merged | Adds a safer display ID fallback for macOS 26.4+. |
| [#911](https://github.com/jordanbaird/Ice/pull/911) | Fixed manually | Ported the useful sourcePID cache, AX probing, and control item fallback pieces. |
| [#900](https://github.com/jordanbaird/Ice/pull/900) | Skipped | Targets the old EventManager; current HIDEventManager has different pause/resume semantics and handler guards. |
| [#893](https://github.com/jordanbaird/Ice/pull/893) | Fixed manually | Adapted to the existing context-menu setting, including control-item right-click suppression and a settings fallback. |
| [#874](https://github.com/jordanbaird/Ice/pull/874) | Skipped | Broad stale macOS 26 patch; superseded by the macOS 26 branch and targeted fixes above. |
| [#873](https://github.com/jordanbaird/Ice/pull/873) | Skipped | Localization-only and stale against current resource structure. |
| [#870](https://github.com/jordanbaird/Ice/pull/870) | Skipped | Older Sparkle dialog fix superseded by #945; also includes local signing changes. |
| [#868](https://github.com/jordanbaird/Ice/pull/868) | Partially fixed | Ported the fullscreen notchless-display guard; skipped localization-only changes for this pass. |
| [#848](https://github.com/jordanbaird/Ice/pull/848) | Skipped | Localization-only with old/wrong resource path. |
| [#820](https://github.com/jordanbaird/Ice/pull/820) | Skipped | Older Sparkle dialog fix superseded by #945/current update code. |
| [#805](https://github.com/jordanbaird/Ice/pull/805) | Skipped | Localization infrastructure PR includes a release zip and stale manager paths. |
| [#804](https://github.com/jordanbaird/Ice/pull/804) | Fixed manually | Ported stale CGImage cache pruning. |
| [#803](https://github.com/jordanbaird/Ice/pull/803) | Fixed manually | Ported overlay-panel validation before showing. |
| [#795](https://github.com/jordanbaird/Ice/pull/795) | Fixed manually | Adapted opt-in automatic Ice Bar detection to current settings models. |
| [#734](https://github.com/jordanbaird/Ice/pull/734) | Skipped | Older localization-only string catalog; not macOS 26 focused. |
| [#667](https://github.com/jordanbaird/Ice/pull/667) | Fixed manually | Ported the multi-monitor single-space guard. |
| [#612](https://github.com/jordanbaird/Ice/pull/612) | Skipped | Large stale per-display feature plus signing/workflow artifacts; high regression risk. |
| [#413](https://github.com/jordanbaird/Ice/pull/413) | Skipped | Stale auto-unhide behavior overlaps with the safer #795 Ice Bar automation. |
