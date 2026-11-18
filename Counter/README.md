# Counter

Standalone iPhone-only video-link player, built with SwiftUI, AVKit and WebKit. Requires iOS 17 or later.

## Run on your iPhone

1. Open `Counter.xcodeproj` in Xcode.
2. Select the Counter target, then Signing & Capabilities. Choose your development team and a unique bundle identifier if needed.
3. Connect your iPhone, enable Developer Mode if required, select it as the destination, and run.
4. Choose Link for a video/page URL, or Embedded video for an embed URL or iframe/video HTML code. Paste it and tap Open video.

Direct MP4, M4V, MOV and HLS (.m3u8) links use the native player. Website links open in the embedded browser, where you may need to tap the site's play button. Use Try native player for direct streams without a filename extension, or Try website player when native playback fails. Native player controls support fullscreen playback.

HTTP and HTTPS are accepted. Cleartext HTTP is permitted for compatibility with older media hosts; prefer HTTPS links. Browser data uses an ephemeral WebKit store. No link history, accounts, analytics, permanent downloads, or cloud services are implemented. Website-provided sign-in pages may appear, but compatibility is site-dependent.

Some websites prohibit embedded playback, require DRM or external apps, or use formats iOS cannot play. Counter does not bypass those restrictions or extract protected streams. No universal website compatibility is claimed.

## Verify

```sh
xcodebuild build -project Counter.xcodeproj -scheme Counter -destination 'generic/platform=iOS' -derivedDataPath /private/tmp/counter-build CODE_SIGNING_ALLOWED=NO
swiftc -module-cache-path /private/tmp/counter-swift-cache Counter/LinkResolver.swift Counter/RhythmTimeline.swift Counter/RhythmMeter.swift Counter/EmbeddedVideoBridge.swift Tests/main.swift -o /private/tmp/counter-link-tests
/private/tmp/counter-link-tests
```

Before distributing, test live direct MP4, live HLS, website playback, fullscreen rotation, bad links, and offline retry on a physical iPhone. Signed device builds pass; real-site playback testing on iPhone remains outstanding. Nothing has been pushed to GitHub.

## Rhythm overlay

Manual rhythm is available for both native and embedded players using the Manual rhythm toggle. Its settings offer Normal or Random stage durations and sound controls. Tap Start to run the randomized stage program. Changing tempo restarts the count at beat one. Soft beat clicks default on and use the existing toggle. The metronome stops when the player closes or the app leaves the foreground. Its timing follows the manual program rather than detected movement, and it pauses when the video is not playing.

The overlay belongs to Counter's inline player; iOS/website-provided fullscreen playback and Picture in Picture do not carry this overlay. Physical-device checks for audio mixing, pulse timing, and controls over real websites remain required.

## No link history

Counter keeps the current URL only in memory. It does not write video links to files, databases, preferences, analytics, or app logs, and does not restore links after relaunch. Closing the player clears both its URL and the link field. Each website player uses a nonpersistent WebKit data store; browsing data is not saved as an app history. This does not control records kept by the websites or network providers.

## Streaming-only live rhythm bar

Open a native video stream; live tracking starts automatically. Start live rhythm can restart it after you stop it. Counter reads frames already decoded by `AVPlayerItemVideoOutput`; it does not download another copy, create a video file, read a completed asset, or save an analysis timeline. Only one small previous-frame grid, a single audio-energy reading, and up to four seconds/64 numeric observations are kept in RAM. Older observations are discarded. Stop, close, reload, and player changes detach the analyzer and clear evidence. A deletion-only launch cleanup removes media left by the superseded downloadable-analysis version.

The vertical bar uses **Stop**, **Slow**, **Normal**, **Fast**, and **Ultrafast** as smoothed descriptive labels. Automatic bar timing uses measured video-movement intervals and peak timestamps, never those labels’ preset BPM. Preset rates belong only to explicitly selected manual mode. About three seconds of visible playback are needed for initial observation. Movement is primary; an optional pass-through audio tap contributes 15% of the tempo estimate when supported. Audio cannot activate a still scene. Some formats/OS versions do not expose audio taps, so the guide falls back to movement alone. Protected video may not expose frames. Website mode attempts live movement tracking for accessible HTML video elements, including iframe and open shadow-root players. When a site blocks frame access, Counter reports it and offers an explicit manual alternative; it never silently substitutes manual timing for video tracking.

Every descriptive level is held for at least 11 seconds of playback before changing. Bar cadence and phase follow observed video peaks independently of label smoothing. Three reasonably consistent movement peaks are required to lock timing. No clear rhythm means a stationary bar with Waiting for rhythm, even if audio beats are present. Between video samples, the bar interpolates at most one measured up/down cycle and then waits for fresh movement evidence; it never continues indefinitely at a preset tempo. The bar freezes during pause/buffering. Seeking, toggling analysis, or leaving the foreground resets observation; playback ending can naturally truncate the last hold. This is a live estimate, not semantic action recognition. Camera motion, cuts, lighting, and compression can affect it.

Live analysis cannot classify unseen future footage or preview the entire video. It replaces the earlier whole-file analysis and its future section list. There is no analysis file-size/duration cap, whole-file download, separate analysis request, or saved link history. Standard system-managed streaming buffering still occurs in AVPlayer; Counter does not provide downloads, offline copies, or app-managed video storage. Website playback uses a nonpersistent WebKit data store.

In-memory service checks on macOS (no media files or network fixtures):

```sh
swiftc -parse-as-library -module-cache-path /private/tmp/counter-swift-cache Counter/RhythmTimeline.swift Counter/RhythmMeter.swift Counter/VideoRhythmAnalyzer.swift Tests/Media/MediaChecks.swift -o /private/tmp/counter-media-tests
/private/tmp/counter-media-tests
```

Tests cover distinct observed 72/90 BPM rhythms within the same label, video-anchored phase, audio independence, missing-motion dropout, no oscillation from constant unpatterned motion, live level holds, bounded evidence, seeks, generated in-memory frames, cut rejection, output attachment/removal, and no-frame behavior. Real iPhone frame delivery, live audio-tap support, HLS/protected-stream behavior, CPU usage, and perceived alignment remain device checks.

## Signed device build

This checkout uses the development team already configured for Dietum and the distinct bundle identifier `com.kbnawalakha.Counter`. Xcode can build it with automatic provisioning. Select your connected iPhone and press Command-R to install and launch.

```sh
xcodebuild build -project Counter.xcodeproj -scheme Counter -destination 'generic/platform=iOS' -allowProvisioningUpdates
```

For a different Apple account, select your own team in Signing & Capabilities and use an available bundle identifier.

## Embedded website video tracking

Paste a website/page link, tap Open video, and start its embedded video. Counter attempts movement tracking automatically, including videos inside iframes and open shadow roots. The same motion-timed bar and minimum label holds apply. Pausing freezes the meter; seeking or changing the active player resets observation. With multiple players, the active visible player is preferred, with larger active players taking priority. Hidden/closed-component or unusual custom players may not be detected.

The WebKit adapter runs in a separate named content world and samples a 16×16 canvas only while live tracking is enabled. Its reply bridge accepts bounded numeric frames and playback state, not URLs or saved media. Swift validates the samples, selects one current source, and feeds the existing bounded movement tracker. Disabling, backgrounding, navigation, and teardown clear observations or suspend sampling. No video files, link history, network proxy, downloads, or audio recording are added. Embedded tracking uses video movement only; native playback retains optional audio-label support.

Cross-origin video without server permission, DRM-protected players, and other browser access restrictions remain respected. Playback may still work while tracking is unavailable. Counter does not change the site's CORS attributes, circumvent protection, extract stream URLs, or silence the video. Native system fullscreen/Picture in Picture still does not carry the inline overlay.

Implementation references: [WebKit message bridges](https://developer.apple.com/documentation/webkit/wkusercontentcontroller), [canvas cross-origin restrictions](https://developer.mozilla.org/en-US/docs/Web/HTML/How_to/CORS_enabled_image).

Additional macOS checks:

```sh
swiftc -parse-as-library -module-cache-path /private/tmp/counter-swift-cache Counter/RhythmTimeline.swift Counter/RhythmMeter.swift Counter/EmbeddedVideoBridge.swift Tests/Embedded/ScriptChecks.swift -o /private/tmp/counter-script-tests
/private/tmp/counter-script-tests
swiftc -parse-as-library -module-cache-path /private/tmp/counter-swift-cache Counter/RhythmTimeline.swift Counter/RhythmMeter.swift Counter/EmbeddedVideoBridge.swift Tests/Embedded/WebKitChecks.swift -o /private/tmp/counter-webkit-tests
/private/tmp/counter-webkit-tests
```

The WebKit integration generates live canvas-stream videos in a top-level page and iframe entirely in memory. It verifies real isolated-world frame delivery without stored media. Script checks cover pixel sampling, pause, seek, CORS/DRM rejection, disable, and page teardown. Specific external websites and iPhone behavior remain manual checks.

## Manual stages and Bleepy

Enable **Manual rhythm**, open the meter settings, choose a stage-duration mode, then Start. The randomized program starts with a normal **15–20 minute running-time plan**, including inter-stage breaks, with **5–6 varying-length stages**. Bleepy can override this plan and its limits. There is no fixed-tempo option or base-tempo slider.

Ordinary stages start below Ultrafast and end with a closing Ultrafast segment; Bleepy may override either rule. Closing length grows monotonically from 10–15 seconds in the first stage toward 28–30 seconds in the last. Normal speed segments last 10–30 seconds and change to another speed. Breaks between stages last 15–30 seconds. There is no extra break after completion. The only running countdown shown is the current stage time, displayed as digits alone (for example `2:14`), without a Time remaining prefix. Stage labels show only the current number (`Stage 2`), never the total. Each stage independently has a 50% chance to hide it for a random 30–60 seconds of running stage time, then reveal it. The same visibility applies to the meter and settings; pauses freeze the reveal clock. A stage that ends early can finish before its countdown is revealed. Visibility randomness is separate from scheduling/outcome randomness. Beat durations/change countdowns, break countdowns, and whole-program remaining time are hidden in both the meter and settings.

Normal duration mode initially distributes stages within 2–4 minutes. Random mode varies them more, but zero-length stages are no longer used: every stage needs a non-Ultra opening, enough time to fund its Ultra ending, and a share of the complete 15–20 minute budget. Bleepy edits can change stage and overall duration without those normal bounds. The final stage completes the program automatically.

Ordinary Slow selection targets at most **20% of each stage**; Bleepy is exempt. Its eligible selection chance decreases from 50% toward a 20% floor in the final stage. Ordinary Ultrafast selection targets at most **50% of active beat time**, excluding breaks; Bleepy is exempt. The scheduler reserves budget for each mandatory closing Ultra before allowing optional Ultra segments. All timing and planned stage numbers remain in RAM; there is no saved link/video/program history.

**Playback gating:** manual bar movement and clocks run only when the native player reports playing, or an embedded HTML video reports playing and sufficiently ready. Pause, end, buffering, missing playback information, or no video pauses the program automatically. Playback resuming automatically resumes it unless manually paused. Muting the video or switching off beat clicks does **not** stop the visual program. Embedded manual mode observes playback metadata only; it does not need pixel access or audio capture. Unknown/custom players remain paused with Waiting for video playback.

The existing **Beat clicks** toggle is enabled by default. **Click volume** independently controls clicks from 0–100%, starting at 65%. The quieter non-accented beats scale with it. Changes apply immediately; zero mutes clicks without stopping the visual program. Video and Bleepy volumes are unaffected. The setting stays in memory for the current app session. There is no extra beat-sound setting. Bleepy retains its separate notification-sound toggle. Both sounds are synthesized in memory. Phone tests are still needed for audible volume, audio mixing, and real-site playback state.

**Bleepy:** after a new random interval of **60–300 seconds** from the previous trigger (and from program start for the first trigger), one of these **11 equally likely outcomes** occurs:

- −30 seconds, +30 seconds, or stage completion when revealed.
- Ultrafast for a random 15–30 seconds.
- **Super Slow for 30 seconds**, at half the ordinary Slow target (20 BPM nominal).
- +10 seconds or +20 seconds.
- −10 seconds, −20 seconds, or −40 seconds.
- A random increase of **10–40 seconds**, inclusive.

A five-second vertical prize-wheel drum appears over the player and in manual settings. All eleven outcome names scroll past a fixed center pointer for at least two complete passes, then decelerate and stop on the randomly selected outcome. The selected action is revealed and applied only after the stop. This replaces the numbered circular dial; an outcome list remains available in settings. Stage/beat/break time continues while the wheel spins, so Bleepy does not wait for any boundary. Video/manual pause freezes both the wheel and program. Stop/close/program completion cancels a pending spin. Reduced Motion uses a static reel with the same delayed reveal.

Bleepy is explicitly an unrestricted override: no queueing, cap-budget checks, closing-segment protection, 10–30 second normal segment constraint, or 15–20 minute plan clamp applies to it. The normal scheduler's rules apply between overrides, but actual percentages/durations can exceed their normal targets afterward. A later Bleepy may interrupt an earlier override.

Time edits apply directly to the currently running stage or break countdown. If a reduction exhausts it, that phase completes immediately (timers never display negative values). Completion ends the current stage immediately; during a break it completes the break and starts the next stage. Speed effects interrupt immediately, including during breaks/closing Ultra. The current phase extends if needed to play the requested speed duration. Ordinary scheduling resumes afterward. Video playback gating and user pause/stop remain effective.

Closing/reloading the video, switching back to live tracking, or leaving the foreground ends the program. Manual pause freezes running time, so wall-clock time may exceed 20 minutes if playback/manual pauses occur.

Pure scheduler and playback-gate checks:

```sh
swiftc -parse-as-library -module-cache-path /private/tmp/counter-swift-cache Counter/RhythmTimeline.swift Counter/RhythmMeter.swift Counter/ManualStageProgram.swift Counter/ManualPlaybackGate.swift Tests/Stages/StageChecks.swift -o /private/tmp/counter-stage-tests
/private/tmp/counter-stage-tests
```

The suite separately checks 200 normal-program seeds with Bleepy disabled, all 11 override outcomes, exact signed edits, random increases, immediate speed changes, intentional cap/closing/break bypass, 200 randomized override runs, and stale/paused playback evidence. Real WebKit integration tests confirm muted-but-playing videos remain playing and paused videos report stopped, without media files.

## Embed-code input

Select **Embedded video** above the input field, then paste either an embed URL (such as a provider's `/embed/...` link) or its iframe/HTML video embed code. Supported code forms include iframe/video `src` and a video element's nested source `src`. Pasting HTML with the Paste control selects Embedded video automatically; code entered in the Link tab is also recognized.

Counter extracts the first player source URL, decodes common HTML entities, validates HTTP/HTTPS, and opens the URL in the embedded player. It never renders the pasted markup or its scripts/event handlers. Protocol-relative source URLs use HTTPS. Inline `srcdoc`-only content and non-web URL schemes are rejected. Embedded mode uses WebKit even for a direct video URL; Try native player remains available.

Input and extracted URLs remain in memory and clear when the player closes. Video tracking/manual playback gating use the existing embedded support and remain subject to the provider's playback/frame-access restrictions. Real provider embed URLs still need iPhone checks.
