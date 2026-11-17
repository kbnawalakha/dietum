# Counter

Standalone iPhone-only video-link player, built with SwiftUI, AVKit and WebKit. Requires iOS 17 or later.

## Run on your iPhone

1. Open `Counter.xcodeproj` in Xcode.
2. Select the Counter target, then Signing & Capabilities. Choose your development team and a unique bundle identifier if needed.
3. Connect your iPhone, enable Developer Mode if required, select it as the destination, and run.
4. Paste a video or website link and tap Open video.

Direct MP4, M4V, MOV and HLS (.m3u8) links use the native player. Website links open in the embedded browser, where you may need to tap the site's play button. Use Try native player for direct streams without a filename extension, or Try website player when native playback fails. Native player controls support fullscreen playback.

HTTP and HTTPS are accepted. Cleartext HTTP is permitted for compatibility with older media hosts; prefer HTTPS links. Browser data uses an ephemeral WebKit store. No link history, accounts, analytics, downloading, or cloud services are implemented. Website-provided sign-in pages may appear, but compatibility is site-dependent.

Some websites prohibit embedded playback, require DRM or external apps, or use formats iOS cannot play. Counter does not bypass those restrictions or extract protected streams. No universal website compatibility is claimed.

## Verify

```sh
xcodebuild build -project Counter.xcodeproj -scheme Counter -destination 'generic/platform=iOS' -derivedDataPath /private/tmp/counter-build CODE_SIGNING_ALLOWED=NO
swiftc -module-cache-path /private/tmp/counter-swift-cache Counter/LinkResolver.swift Tests/main.swift -o /private/tmp/counter-link-tests
/private/tmp/counter-link-tests
```

Before distributing, test live direct MP4, live HLS, website playback, fullscreen rotation, bad links, and offline retry on a physical iPhone. Device signing and live playback testing remain outstanding. Nothing has been pushed to GitHub.

## Rhythm overlay

The inline video/website player includes a manual metronome in its upper-right corner. Tap Start for visual beats; open Tempo settings to adjust 30–240 BPM, see the four-beat count, or enable audible clicks. Changing tempo restarts the count at beat one. Click sound defaults off. The metronome stops when the player closes or the app leaves the foreground. It runs independently of video pause/seek and does not detect or synchronize to the video's rhythm.

The overlay belongs to Counter's inline player; iOS/website-provided fullscreen playback and Picture in Picture do not carry this overlay. Physical-device checks for audio mixing, pulse timing, and controls over real websites remain required.
