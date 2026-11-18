# Active Handoff

## Date

2026-11-17

## Assigned Issue

Fix meal saving and add date-grouped meal photo history

## Branch

codex/repo-foundation

## Work Completed

- Meal saves now persist selected photo image data and no longer require manual review toggles before saving a valid estimate.
- Today's saved meal photos remain visible on the meal page after a successful save.
- Added Settings -> History -> Meal Photos with date-grouped daily calories, protein, carbohydrates, and fat totals.
- Added drill-down views showing every saved meal photo for a selected date.
- Added trailing swipe actions with confirmation before deleting a complete progress-photo day or meal-photo history day.
- Added a regression test covering photo persistence and today's saved-meal refresh.
- Replaced fixed meal servings with per-100 g food nutrition, editable gram portions, and saved item quantities.
- Replaced the mock meal detector with Apple Vision classification plus USDA FoodData Central search; analysis now returns a typed configuration/data error instead of fabricated calories when the API key or nutrition match is unavailable.
- Hardened meal analysis to continue with a user-provided description when Vision cannot classify a photo, and changed the meal-save regression to inject a deterministic analyzer rather than depend on a live USDA key.
- Added a "What changed" comparison section for progress photos that compares overall and regional saved body-fat estimates between the selected earlier and later photos.

- Added `BodyFatEstimateBreakdown` for chest, arms, legs, back, and visceral estimates.
- Persisted the optional breakdown through the SwiftData progress-photo model.
- Added automatic regional estimate cards and general-range suggestions after body analysis; regional values are no longer manually editable.
- Changed valid-image analysis fallback so Vision pose-detection misses no longer block estimates or make the Analyze button appear broken.
- Grouped saved progress-photo rows by capture date.
- Added destructive date-level deletion that removes every saved angle and associated analysis for the selected day.

## Files Changed

- `Dietum/Features/Meals/MealLoggingViewModel.swift`
- `Dietum/Features/Meals/MealLoggingView.swift`
- `Dietum/App/AppRoute.swift`
- `Dietum/App/AppContainer.swift`
- `Dietum/App/RootView.swift`
- `Dietum/DietumTests/NutritionAdjustmentRecommendationServiceTests.swift`
- `Dietum/Features/Meals/MockMealFoodDetectionService.swift` (legacy filename; production implementation is `FoodDataCentralMealAnalysisService`)
- `Dietum/Info.plist`

- `Dietum/Domain/Models/DomainModelPlaceholder.swift`
- `Dietum/Data/SwiftData/Models/StoredProgressPhotoMetadata.swift`
- `Dietum/Features/ProgressPhotos/ProgressPhotosViewModel.swift`
- `Dietum/Features/ProgressPhotos/ProgressPhotosView.swift`
- `Dietum/DietumTests/NutritionAdjustmentRecommendationServiceTests.swift`
- `PROJECT_STATUS.md`
- `HANDOFF.md`

## Verification

- `xcodebuild build-for-testing -project Dietum.xcodeproj -scheme Dietum -destination 'generic/platform=iOS Simulator' -derivedDataPath /private/tmp/dietum-meal-history-tests CODE_SIGNING_ALLOWED=NO` succeeded with `TEST BUILD SUCCEEDED`.
- The simulator test runner was not invoked because this verification used the generic simulator destination; the new regression is compiled into the test bundle.

- Feature build: `xcodebuild build -project Dietum.xcodeproj -scheme Dietum -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' -derivedDataPath /private/tmp/dietum-body-fat-build` succeeded.
- Final: `xcodebuild test -project Dietum.xcodeproj -scheme Dietum -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath /private/tmp/dietum-body-fat-tests` passed with 17 tests and 0 failures.
- Sleep-signal update: `xcodebuild build -project Dietum.xcodeproj -scheme Dietum -destination 'generic/platform=iOS' -derivedDataPath /private/tmp/dietum-sleep-signals-device CODE_SIGNING_ALLOWED=NO` succeeded.
- The refreshed simulator test command was attempted but could not start because CoreSimulatorService was unavailable and no simulator destination was discoverable in this environment.
- `git diff --check` passed.
- `xcodebuild build-for-testing -project Dietum.xcodeproj -scheme Dietum -destination 'generic/platform=iOS Simulator' -derivedDataPath /private/tmp/dietum-real-meal-analysis-tests CODE_SIGNING_ALLOWED=NO`
- `xcodebuild build-for-testing -project Dietum.xcodeproj -scheme Dietum -destination 'generic/platform=iOS Simulator' -derivedDataPath /private/tmp/dietum-meal-tracker-fix CODE_SIGNING_ALLOWED=NO` succeeded with `TEST BUILD SUCCEEDED`.
- `xcodebuild build-for-testing -project Dietum.xcodeproj -scheme Dietum -destination 'generic/platform=iOS Simulator' -derivedDataPath /private/tmp/dietum-progress-comparison-tests CODE_SIGNING_ALLOWED=NO` succeeded with `TEST BUILD SUCCEEDED`.
- `xcodebuild build -project Dietum.xcodeproj -scheme Dietum -destination 'generic/platform=iOS Simulator' -derivedDataPath /private/tmp/dietum-progress-delete-build CODE_SIGNING_ALLOWED=NO` reached the existing SwiftData macro-plugin malformed-response failure after the new progress-photo source compiled.

## Work Remaining

- Run the new meal-save regression and the full XCTest suite on an available booted simulator when CoreSimulatorService is available.

- Body-fat regional values are estimates and should be replaced or edited with measured data when available.
- Vision pose detection remains best-effort; valid images with inconclusive framing use an editable general-range fallback.
- Actual Screen Time totals are not yet available because the project does not have a Device Activity report extension.
- The default device build uses the existing HealthKit-only profile; Screen Time authorization remains unavailable until Family Controls is enabled in Apple Developer and Xcode.
- Dashboard sleep signals now have a visible refresh action and a direct Sleep Setup route; phone usage remains clearly marked as unavailable until the Screen Time capability and report extension exist.
- Meal and body-photo uploads now trigger analysis automatically; detected foods, macros, body-fat ranges, and regional values remain editable before saving.
- Real meal analysis requires `USDA_FOOD_DATA_CENTRAL_API_KEY` in Xcode Build Settings. Vision provides likely food labels and USDA provides per-100 g nutrition; exact grams, oils, and hidden ingredients still require user review.
- Without the USDA key, live analysis intentionally fails with a configuration message; no mock calories are generated.
- Progress-photo comparison is limited to saved estimate metadata; missing estimates show a visual-only comparison message rather than guessed numeric changes.
- Progress-photo picker selection now retains its pose through PhotosUI dismissal and awaits staging plus analysis before clearing the selection.
- Progress-photo history now shows capture dates as the primary records; use the trash action on a date to remove its full photo set and analysis.
- Removed meal-reminder navigation and dashboard entry points per product direction; legacy reminder model/export types remain only for local compatibility.
- Removed local-export navigation and dashboard entry points; retained snapshot services because the optional Drive backup uses them internally.
- Profile onboarding is now a first-launch flow; the dashboard Quick Start and crowded toolbar were replaced by an ellipsis Settings hub, with meal tracking kept as a direct dashboard action.
- Recent progress photos are presented as capture-date groups; each date can delete all saved angles and associated body-fat analysis together.

## Known Problems

- Unrelated pre-existing Xcode scheme/project edits, `build/`, and `pass` / `pass.pub` remain uncommitted and were not staged.
- The latest device compile was blocked by the local SwiftData macro plugin returning malformed responses; the simulator service was also unavailable for XCTest execution.
- Added a regression test for staging a photo and generating automatic estimates before save.
- The reminder-removal device compile was attempted but stopped at the existing SwiftData macro-plugin malformed-response failure before a complete app build.
- The export-removal device compile was attempted and hit the same existing SwiftData macro-plugin malformed-response failure before a complete app build.
- Nutrition insights now receive the live SwiftData target repository and provide explicit refresh and log-meal actions.
- Nutrition-insights device compile was attempted but stopped at the existing SwiftData macro-plugin malformed-response failure.
- Settings-shell device compile was attempted but stopped at the existing SwiftData macro-plugin malformed-response failure.
- The progress-photo day deletion regression test was added but could not execute because CoreSimulatorService exposed no matching simulator destination.
- Google OAuth configuration now validates the explicit callback scheme against the redirect URI and reports placeholder/mismatch settings; real Google Cloud OAuth values are still required for a device sign-in.
- Fixed the build failure caused by `SwiftDataNutritionTargetRepository` conforming to `NutritionTargetRepository` without implementing `saveNutritionTarget(_:)`.
- Elevated `xcodebuild build` and `xcodebuild build-for-testing` completed successfully after the nutrition-target repository fix; existing Swift concurrency warnings remain.

## Exact Next Step

- Add the USDA API key to the app build configuration and run meal analysis on a physical device or simulator with network access, then run the full simulator XCTest suite when CoreSimulatorService is available.

## Counter — Separate Local App (2026-11-17)

User requested an independent iPhone-only video-link player called Counter and no GitHub publication. Added `Counter/Counter.xcodeproj/project.pbxproj`, `Counter/Counter/{CounterApp.swift,LinkResolver.swift,WebsitePlayer.swift,Info.plist}`, `Counter/Tests/main.swift`, and `Counter/README.md`; updated `PROJECT_STATUS.md` and this handoff. Existing Dietum changes and unrelated untracked files were left untouched.

Validation: unsigned generic iOS build succeeded, and 13 standalone URL-validation/routing checks passed. No existing Counter baseline was available. Simulator discovery failed because CoreSimulatorService was inaccessible. Initial project-generation Python failed due to f-string quoting; corrected. First project build failed because a dictionary was used as a build-setting value; moved ATS settings into Info.plist. Initial test compile failed because throwing expressions were inside assert autoclosures; corrected and reran successfully.

Remaining: choose signing team/bundle ID in Xcode, install on the user's iPhone, and verify direct MP4/HLS, website controls, fullscreen rotation, and offline retry. Website/DRM restrictions prevent guaranteed universal playback. No GitHub push, per user request. Next step: open `Counter/Counter.xcodeproj`, configure signing, and run on iPhone.

### Counter manual metronome overlay (2026-11-17)

Assigned request: add a manual BPM metronome overlay to Counter. Changed `Counter/Counter/CounterApp.swift`, added `Counter/Counter/MetronomeOverlay.swift`, registered it in `Counter/Counter.xcodeproj/project.pbxproj`, and updated `Counter/README.md`, `PROJECT_STATUS.md`, and this handoff. Added tempo settings (30–240), visual pulse and four-beat count, start/stop, optional in-memory synthesized click audio, and lifecycle cancellation. No GitHub push requested or performed.

Baseline: unsigned iPhone build and 13 existing link checks passed before edits. Initial overlay build failed because the sandbox prevented the SwiftUI State macro plugin from returning a valid response; retried with Xcode plugin access. Device checks still needed: sound/video mixing, timing under load, tempo interaction, website controls, and background/close cancellation. The overlay is inline only and does not follow system fullscreen or Picture in Picture. Next step: run Counter on the user's iPhone and test the manual rhythm overlay with actual video playback.

Final overlay verification: elevated unsigned generic iPhone build succeeded; 13 link checks and `git diff --check` passed. Existing unrelated Dietum source/scheme edits were not included. Local Git metadata requires elevated access to create the commit; no remote push will be made.

### Counter no saved historical links (2026-11-17)

Assigned request: do not save historical links. Inspected all Counter sources: current URL is memory-only, WebKit uses a nonpersistent data store, and there is no history persistence or URL logging. Changed `Counter/Counter/CounterApp.swift` to clear input on player close and show a no-history notice; updated `Counter/README.md`, `PROJECT_STATUS.md`, and this handoff. Baseline iPhone build and 13 URL checks passed. No unrelated Dietum changes were included; no push requested.

Remaining: test close/relaunch and WebKit storage on an actual phone. The user's separate video-synchronization request remains unimplemented pending selection of audio beat, visible motion, or timeline cues. Website/network-provider records are outside Counter's control.

Final no-history verification: unsigned generic iPhone build succeeded with Xcode plugin access; 13 existing link checks and `git diff --check` passed. The first post-change build failed due to the existing sandboxed SwiftUI macro malformed-response error; elevated retry passed.

### Counter direct-video audio/movement guide (2026-11-17)

Assigned request: synchronize cues to audio beats and visible movement; user approved starting with direct video links. Added `Counter/Counter/{RhythmTimeline.swift,VideoRhythmAnalyzer.swift,RhythmGuide.swift}`, registered them in `Counter/Counter.xcodeproj/project.pbxproj`, updated `Counter/Counter/CounterApp.swift`, extended `Counter/Tests/main.swift`, added `Counter/Tests/Media/MediaChecks.swift`, and updated `Counter/README.md`, `PROJECT_STATUS.md`, and this handoff.

The analyzer protocol isolates AVFoundation processing from UI. Ephemeral bounded downloads feed on-device RMS/audio and sampled frame-difference peak detection. Source-selectable cue timelines drive an inline Move/Wait overlay from AVPlayer media time, including playback status observation and cancellation on close/reload/player switches. Local BPM is estimated from recent intervals. No source URLs or results are persisted; temporary media is removed after analysis. HLS/website and semantic action/stroke recognition are not implemented; this is an estimated peak-based guide.

Baseline: unsigned generic iPhone build and 13 existing link checks passed. Signal verification: 13 link checks plus 18 rhythm/tempo/playback-position checks passed. Generated WAV and moving-bar MOV checks passed with Apple media-service access, validating 120 BPM intervals, movement detection, missing tracks, unsupported HLS, and cancellation. The sandboxed feature build hit the existing SwiftUI macro malformed-response failure; elevated build passed before the final small BPM/refactoring change. The first generated-media run failed with unreadable media under the sandbox; elevated media-service run passed. Old AVAssetReader/Writer APIs produce deprecation warnings on the new macOS SDK but support the iOS 17 deployment target.

Remaining: real iPhone external-host downloads, offline network behavior, resource usage, real-world detector accuracy, and visible pause/seek alignment still need device testing. Local HTTP downloading, size-limit rejection, error handling, cleanup, and cancellation have been tested. Specific action patterns are not recognized. Next step: run Counter on iPhone, load a short unprotected direct video, tap Analyze video rhythm, and compare Audio, Movement, and Both through pauses/seeks. No GitHub push.

Additional regression checks caught and fixed two issues: AVFoundation rejected generic `.tmp` media names (now random names preserve only the media extension), and async URLSession download delegation did not reliably enforce the declared size bound (replaced with an explicit download delegate and cancellation-safe continuation). The local loopback HTTP suite now passes downloaded-media decoding, temp cleanup, 150 MiB size rejection, HTTP errors, and in-flight cancellation. Interrupted-session media is cleared at launch. No source-link history is written.

Final synchronization verification: unsigned generic iPhone build succeeded after all media/download fixes. All 13 link checks, 18 signal/tempo/playback-position checks, generated-media and local HTTP checks, and `git diff --check` passed. Changes are saved locally only; Dietum source and unrelated working-tree files remain untouched.

### Counter whole-video movement bar (2026-11-17)

Assigned request: bar meter with complete up/down beats, five named levels, full-video classification, levels held over 10 seconds, and movement favored over audio. Added `Counter/Counter/RhythmMeter.swift`, registered it in `Counter/Counter.xcodeproj/project.pbxproj`, and changed `Counter/Counter/{RhythmTimeline.swift,VideoRhythmAnalyzer.swift,RhythmGuide.swift,MetronomeOverlay.swift,CounterApp.swift}`, `Counter/Tests/main.swift`, `Counter/README.md`, `PROJECT_STATUS.md`, and this handoff.

Movement samples now reach the pure whole-video section classifier. Movement/audio weighting is 85/15; audio cannot activate still sections. Equal analysis windows are at least 11 seconds except a single complete 10–11 second video; matching neighbors merge, guaranteeing strictly over 10 seconds for every final section. Videos <=10 seconds explain why automatic mode is unavailable. All supported video content is analyzed; no truncation. Full cycles are fitted to each section at approximately 40/80/120/180 BPM. Bar phase comes from media time, so pausing freezes it and seeking recomputes it. Manual speed settings moved to a sheet to preserve player space.

Baseline: 13 link checks and 18 rhythm checks plus unsigned iPhone build passed. Initial new signal-test compilation hit Swift expression type-checking time limits; simplified expressions and reran successfully. Initial sandboxed feature build hit the known SwiftUI macro malformed-response error; elevated build passed before the final manual-sheet change. Tests now cover the five levels, minimum holds, complete cycles, monotonic rates, full coverage, static movement despite audio, short videos, and final-tail merging.

Remaining: physical-iPhone visual and timing checks plus real-world movement classification accuracy. No semantic action recognition or system-fullscreen overlay. No saved links and no GitHub push. Next step: load a supported video over 10 seconds on iPhone, analyze it, inspect the full section preview, and test bar cycles while pausing/seeking.

Final bar verification: unsigned generic iPhone build succeeded after the manual-sheet changes. Existing link/rhythm checks, new whole-video section/cycle tests, generated-media/local HTTP regressions, and `git diff --check` passed. Saved locally only; unrelated Dietum scheme/repository changes are excluded.

### Counter streaming-only realtime analysis (2026-11-17)

Assigned request: stream and analyze in realtime without storing video. Replaced `Counter/Counter/VideoRhythmAnalyzer.swift` with a protocol-based AVPlayerItemVideoOutput service and optional MTAudioProcessingTap RMS tap; changed `Counter/Counter/{RhythmMeter.swift,RhythmGuide.swift,CounterApp.swift}`, `Counter/Tests/{main.swift,Media/MediaChecks.swift}`, `Counter/README.md`, `DECISIONS.md`, `PROJECT_STATUS.md`, and this handoff.

Removed the download/delegate/file-reader path and the future section classifier. Live evidence is a 256-point previous-frame grid, one optional RMS reading, and a rolling numeric window capped at four seconds/64 observations. No video files, link history, accumulated analysis timeline, or separate analysis network requests are created. Launch cleanup only deletes old `CounterAnalysis` media. Native streaming buffering is controlled by AVPlayer, not an app-managed store.

The five-level live bar learns for around three seconds. Movement controls activity; audio optionally refines tempo. Level changes wait at least 11 playback seconds and finish the current bar cycle; pause freezes, and seeks restart observation. Future levels cannot be computed before that footage streams. Natural stream endings/explicit seeks can truncate the visible final hold. Websites/protected streams may not expose frames or audio; manual mode remains available.

Baseline link/rhythm/whole-video checks and unsigned iPhone build passed. Initial feature build encountered the known sandbox SwiftUI macro error plus a new-SDK CoreFoundation tap type mismatch (corrected to the automatically managed tap type). Initial live test expected a direct Stop→Fast transition, but a rolling window legitimately passes through a sustained Normal level; the test now checks the required minimum holds and eventual movement/stop outcomes. In-memory frame/lifecycle and live signal checks passed. No test fixture media or loopback downloads remain in the new service test.

Remaining: real iPhone/HLS frame delivery, optional audio-tap support, protected/no-frame stream behavior, thermal/CPU behavior, and perceived bar alignment. Next step: run Counter on iPhone, open a native stream, tap Start live rhythm, then test pause, seek, close/reload, and manual fallback. No GitHub push.

Final streaming-only verification: unsigned generic iPhone build succeeded; 13 link checks, 18 signal/tempo checks, live hold/phase/memory/seek tests, in-memory frame/output lifecycle checks, and `git diff --check` passed. Runtime-source inspection found no URLSession, download task, AVAssetReader/Writer, or media-file creation path; the sole filesystem operation removes the old analysis directory. Changes saved locally only, excluding unrelated Dietum edits.

### Counter build-failure follow-up (2026-11-17)

Assigned request: resolve Counter failing to build when opening in Xcode. Baseline signed build failed with `Signing for "Counter" requires a development team`; link/live rhythm tests passed. Changed `Counter/Counter.xcodeproj/project.pbxproj` to use the existing Dietum development team in Debug and Release and the separate `com.kbnawalakha.Counter` identifier. Xcode also normalized project formatting while open; preserved that formatting and removed a transient duplicate team setting. Updated `PROJECT_STATUS.md`, this handoff, and Counter setup documentation.

Verification: `xcodebuild build -project Counter/Counter.xcodeproj -scheme Counter -destination 'generic/platform=iOS' -derivedDataPath /private/tmp/counter-user-build -allowProvisioningUpdates` succeeded with signing. Project plist lint and whitespace checks passed. A sandboxed `codesign --verify --deep --strict` could not use the certificate trust store and returned CSSMERR_TP_NOT_TRUSTED; retried with certificate-store access.

Remaining: select the connected iPhone in Xcode and press Command-R to install/launch; device runtime behavior remains unverified. No app logic changed. No GitHub push; unrelated Dietum and Xcode user-state files excluded.

Final signing verification: the normalized project passed a second signed iPhone build, and `codesign --verify --deep --strict` passed with certificate-store access. Only Counter project/setup documentation and coordination docs are committed.

### Counter meter following video instead of presets (2026-11-17)

Assigned request: meter appears to run independently of video. Confirmed cause: video evidence selected a named level, but `advance` used that level's preset BPM. Changed `Counter/Counter/RhythmMeter.swift` to estimate cadence from consistent movement peaks and anchor bar phase to their media timestamps. Interpolation is limited to one measured cycle; no fresh evidence means waiting, never free-running. Audio can refine descriptive labels but does not drive automatic phase. Label holds remain separate from measured timing.

Changed `Counter/Counter/{CounterApp.swift,RhythmGuide.swift,RhythmMeter.swift}`, `Counter/Tests/{main.swift,Media/MediaChecks.swift}`, `Counter/README.md`, `PROJECT_STATUS.md`, and this handoff. Native streams start live tracking automatically. Websites show Video tracking unavailable with a separate manual opt-in, avoiding a misleading automatic-looking metronome. No video storage or saved links introduced.

Baseline signal tests passed. New regressions validate measured 72 and 90 BPM rhythms under the same speed label, video timestamp phase, conflicting audio independence, constant-motion rejection, dropout after one cycle, and full measured-cycle completion. The signed generic iPhone build succeeded. In-memory frame regressions passed; a stronger generated-frame cadence check is included in the final run.

Remaining: verify perceived phase/cadence on the user's native iPhone stream. This is estimated visible-motion timing, not semantic action or subject recognition; website/protected players may not expose frames. Next step: rebuild/install with Command-R, open a native video, and check Video locked versus Waiting for rhythm. No GitHub push. Other Dietum changes are excluded.

Final video-reference verification: the in-memory generated moving-frame test measured 144 BPM (not a preset), and all signal/phase/dropout tests passed. Signed iPhone build and whitespace checks passed. No failed verification commands in this follow-up. No remote push.

### Counter embedded-video support (2026-11-17)

Assigned request: allow embedded videos with tracking. Added `Counter/Counter/EmbeddedVideoBridge.swift` and `Counter/Tests/Embedded/{ScriptChecks.swift,WebKitChecks.swift}`; changed `Counter/Counter/{WebsitePlayer.swift,RhythmGuide.swift,CounterApp.swift}`, `Counter/Counter.xcodeproj/project.pbxproj`, `Counter/Tests/main.swift`, `Counter/README.md`, `DECISIONS.md`, `PROJECT_STATUS.md`, and this handoff.

A per-frame isolated-world WebKit script discovers playing HTML video in pages/iframes/open shadow roots, samples a small canvas into numeric brightness grids, and forwards bounded state through a reply-controlled bridge. Swift validates payloads, chooses one current player, handles pause/seek/source changes, and uses the existing live movement meter. There are no video files, persisted links, audio recording, separate downloads, or stream-URL extraction. CORS/DRM failures remain explicit, and manual mode is opt-in. Embedded analysis is movement-only; native analysis retains optional audio-label refinement.

Baseline signal checks passed. Sandboxed signed builds could not access Xcode accounts/profiles; elevated signed feature build passed. Initial new tests exposed fixture timing assumptions: a cadence assertion landed exactly on an unconfirmed new peak, and two mocked async bridge steps ran without an intervening microtask turn. Adjusted fixture timing/scheduling, then all tests passed. Bridge checks cover malformed input, duplicate/iframe filtering, active-player selection, pauses, seeks, blocked access, and numeric motion cadence. JavaScriptCore checks cover sampling, pause, seek, CORS/DRM rejection, disabling and page cleanup. A real macOS WKWebView integration received generated live video frames from both the top-level document and iframe, using no media files or network fixtures.

Remaining: real external-site/iPhone compatibility, CORS/protected-player fallback, foreground/background behavior, thermal/CPU behavior, and perceived bar timing. Not all sites expose accessible video pixels; system fullscreen/Picture in Picture does not include the inline overlay. Next step: Command-R on iPhone, open a website with an embedded video, play it inline, and observe Video locked or the explicit frame-access message. No GitHub push; unrelated Dietum work is excluded.

Final embedded verification: the signed generic iPhone build passed after lifecycle changes. Existing signal/phase checks, embedded payload/routing checks, JavaScriptCore adapter checks, and real WebKit top-level/iframe frame delivery passed. Scoped Counter/documentation whitespace checks passed. An unrelated Dietum working-tree file has an EOF whitespace warning and was left untouched; other chats' shared-document edits are excluded from this commit.

Coordination note: an attempted selective shared-document staging command reported “No valid patches in input” because the other active Dietum work had already staged/committed those shared-document changes. No content was lost. Counter's commit uses explicit file paths so unrelated staged work is not included.
