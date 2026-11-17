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
swiftc -module-cache-path /private/tmp/counter-swift-cache Counter/LinkResolver.swift Counter/RhythmTimeline.swift Counter/RhythmMeter.swift Tests/main.swift -o /private/tmp/counter-link-tests
/private/tmp/counter-link-tests
```

Before distributing, test live direct MP4, live HLS, website playback, fullscreen rotation, bad links, and offline retry on a physical iPhone. Device signing and live playback testing remain outstanding. Nothing has been pushed to GitHub.

## Rhythm overlay

The inline video/website player includes a manual bar metronome in its upper-right corner. Tap Start; open Tempo settings for speed presets, 30–240 BPM adjustment, or audible clicks. Changing tempo restarts the count at beat one. Click sound defaults off. The metronome stops when the player closes or the app leaves the foreground. It runs independently of video pause/seek and does not detect or synchronize to the video's rhythm.

The overlay belongs to Counter's inline player; iOS/website-provided fullscreen playback and Picture in Picture do not carry this overlay. Physical-device checks for audio mixing, pulse timing, and controls over real websites remain required.

## No link history

Counter keeps the current URL only in memory. It does not write video links to files, databases, preferences, analytics, or app logs, and does not restore links after relaunch. Closing the player clears both its URL and the link field. Each website player uses a nonpersistent WebKit data store; browsing data is not saved as an app history. This does not control records kept by the websites or network providers.

## Video-synchronized rhythm bar

Open a direct MP4, M4V, or MOV link in the native player, then tap **Analyze video rhythm**. The entire file is analyzed before displaying the movement-led bar plan. The meter uses **Stop**, **Slow**, **Normal**, **Fast**, and **Ultrafast**. It completes one full bottom-to-top-to-bottom cycle per beat and freezes at its current position while playback is paused or buffering. Seeking selects the section and bar phase at the destination time.

Movement contributes 85% of each section score and audio contributes 15%. A still section stays Stop even if its soundtrack has strong beats. Motion energy plus detected movement frequency are normalized against the full video's active sections. Audio refines the score only in moving sections. Relative scores select the four moving levels; a video with little meaningful variation keeps one Normal level. Not every video must contain every level.

The video is divided into equal windows of at least 11 seconds (or one full-length window for a video between 10 and 11 seconds). Adjacent matching levels merge. This guarantees every displayed automatic level lasts **strictly longer than 10 seconds**, including the final section. Videos of 10 seconds or less cannot use the automatic bar. Section boundaries are approximate; smoothing intentionally absorbs brief motion changes.

Nominal cycle rates are Slow 40, Normal 80, Fast 120, and Ultrafast 180 BPM; Stop is stationary. Each section's rate is adjusted slightly to fit an integer number of complete cycles, preventing a half-finished beat at a level change. A horizontal list below the player previews the full sequence of sections. Manual controls are independent and can be overridden immediately.

Analysis uses RMS audio energy and sampled frame differences. It estimates overall visible movement rather than recognizing specific actions or measuring the user's actions. Camera motion, cuts, lighting, and compression can affect the classification. This is not semantic stroke recognition. The overlay remains inline only, outside system fullscreen and Picture in Picture.

Analysis uses an ephemeral network session and temporarily downloads the media (150 MiB maximum, 10-minute maximum duration). It analyzes the whole supported video without truncation. Downloads have a 180-second timeout and can be canceled. Temporary files use random names with media extensions; they are removed after completion/error/cancellation, and abandoned analysis media is cleared at app launch. Source URLs and results are not saved as history. HLS, protected media, websites, and unsupported extensions retain manual playback/tempo only.

Generated-media and loopback HTTP integration checks can run on macOS with Apple's media services and `/usr/bin/python3` available:

```sh
swiftc -parse-as-library -module-cache-path /private/tmp/counter-swift-cache Counter/RhythmTimeline.swift Counter/VideoRhythmAnalyzer.swift Tests/Media/MediaChecks.swift -o /private/tmp/counter-media-tests
/private/tmp/counter-media-tests
```

Tests cover whole-video classification, all five levels, minimum section duration, full bar cycles, motion priority over audio, silence, tempo, cue timing, decoded generated audio/movement, downloading/cleanup, size rejection, HTTP errors, and cancellation. Real iPhone visual quality, external-host behavior, and real-world detection accuracy still require physical-device testing.
