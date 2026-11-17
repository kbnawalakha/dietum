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
swiftc -module-cache-path /private/tmp/counter-swift-cache Counter/LinkResolver.swift Counter/RhythmTimeline.swift Tests/main.swift -o /private/tmp/counter-link-tests
/private/tmp/counter-link-tests
```

Before distributing, test live direct MP4, live HLS, website playback, fullscreen rotation, bad links, and offline retry on a physical iPhone. Device signing and live playback testing remain outstanding. Nothing has been pushed to GitHub.

## Rhythm overlay

The inline video/website player includes a manual metronome in its upper-right corner. Tap Start for visual beats; open Tempo settings to adjust 30–240 BPM, see the four-beat count, or enable audible clicks. Changing tempo restarts the count at beat one. Click sound defaults off. The metronome stops when the player closes or the app leaves the foreground. It runs independently of video pause/seek and does not detect or synchronize to the video's rhythm.

The overlay belongs to Counter's inline player; iOS/website-provided fullscreen playback and Picture in Picture do not carry this overlay. Physical-device checks for audio mixing, pulse timing, and controls over real websites remain required.

## No link history

Counter keeps the current URL only in memory. It does not write video links to files, databases, preferences, analytics, or app logs, and does not restore links after relaunch. Closing the player clears both its URL and the link field. Each website player uses a nonpersistent WebKit data store; browsing data is not saved as an app history. This does not control records kept by the websites or network providers.

## Video-synchronized rhythm guide

Open a direct MP4, M4V, or MOV link in the native player, then tap **Analyze video rhythm**. When analysis completes, choose **Audio**, **Movement**, or **Both**. The inline overlay flashes “Move” at detected peaks, shows the time until the next cue, and estimates local BPM when enough recent cues exist. Switch off Video-synchronized guide to return to the manual metronome.

Audio uses local RMS energy peaks; movement uses sampled frame differences. These are timing estimates rather than semantic action/stroke recognition or a measurement of the user's actions. Music, camera motion, cuts, lighting changes, and compression can cause missed or false cues. A fixed four-beat pattern is not assumed in automatic mode, and silent gaps are not filled with invented beats.

Cues use native media time, so pause, buffering, seeking, and playback speed are reflected in their timing. Leaving the foreground disables the guide; enable it again to resume. Closing/reloading/switching players cancels analysis and clears its results. The overlay remains inline only.

Analysis uses an ephemeral network session and temporarily downloads the media (150 MiB maximum, 10-minute maximum duration). Downloads have a 180-second resource timeout and can be canceled. The temporary file uses a random name with a media extension and is removed after completion/error/cancellation; abandoned analysis media is cleared at app launch; source URLs and cue results are not saved as history. HLS, protected media, websites, and files without supported extensions are not analyzed. Existing stream/website playback remains available with manual tempo.

Generated-media and loopback HTTP integration checks can run on macOS with Apple's media services and `/usr/bin/python3` available:

```sh
swiftc -parse-as-library -module-cache-path /private/tmp/counter-swift-cache Counter/RhythmTimeline.swift Counter/VideoRhythmAnalyzer.swift Tests/Media/MediaChecks.swift -o /private/tmp/counter-media-tests
/private/tmp/counter-media-tests
```

Verification covers synthetic 120 BPM audio, generated movement, missing audio/video tracks, cancellation, HLS rejection, silence, cue merging, tempo estimation, and playback-position/seek behavior. Local HTTP checks also cover downloading/decoding, cleanup, declared size limits, HTTP errors, and in-flight cancellation. External-host downloading, iPhone audio/video decoding, perception of cue alignment, and real-world detection accuracy still require physical-device testing.
