# Counter

Standalone iPhone-only video-link player, built with SwiftUI, AVKit and WebKit. Requires iOS 17 or later.

## Run on your iPhone

1. Open `Counter.xcodeproj` in Xcode.
2. Select the Counter target, then Signing & Capabilities. Choose your development team and a unique bundle identifier if needed.
3. Connect your iPhone, enable Developer Mode if required, select it as the destination, and run.
4. Paste a video or website link and tap Open video.

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

A manual bar metronome is available as an explicit alternative to live tracking; website mode offers a Use manual rhythm instead toggle. Tap Start; open Tempo settings for speed presets, 30–240 BPM adjustment, or audible clicks. Changing tempo restarts the count at beat one. Click sound defaults off. The metronome stops when the player closes or the app leaves the foreground. It runs independently of video pause/seek and does not detect or synchronize to the video's rhythm.

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
