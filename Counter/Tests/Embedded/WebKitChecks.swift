import AppKit
import WebKit

@MainActor
final class EmbeddedTestSink: NSObject, WKScriptMessageHandlerWithReply {
    var playbackOnly = false
    var playingEvents = 0
    var pausedEvents = 0
    var mainFrames = 0
    var childFrames = 0
    func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage,
                               replyHandler: @escaping (Any?, String?) -> Void) {
        replyHandler(["enabled": true, "video": !playbackOnly, "playback": playbackOnly], nil)
        guard let event = EmbeddedVideoEvent(body: message.body) else { return }
        if event.kind == .playback {
            if event.isPlaying == true { playingEvents += 1 } else { pausedEvents += 1 }
            return
        }
        guard event.kind == .frame else { return }
        if message.frameInfo.isMainFrame { mainFrames += 1 } else { childFrames += 1 }
    }
}

@main
@MainActor
struct WebKitChecks {
    static func main() {
        _ = NSApplication.shared
        NSApplication.shared.setActivationPolicy(.accessory)
        let sink = EmbeddedTestSink()
        let world = WKContentWorld.world(name: "CounterVideoAnalysis")
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .nonPersistent()
        configuration.mediaTypesRequiringUserActionForPlayback = []
        configuration.userContentController.addScriptMessageHandler(sink, contentWorld: world, name: "counterMotion")
        configuration.userContentController.addUserScript(WKUserScript(source: EmbeddedVideoScript.source,
            injectionTime: .atDocumentEnd, forMainFrameOnly: false, in: world))
        let webView = WKWebView(frame: NSRect(x: 0, y: 0, width: 640, height: 480), configuration: configuration)
        let window = NSWindow(contentRect: webView.frame, styleMask: .borderless, backing: .buffered, defer: false)
        window.contentView = webView
        let fixture = #"""
        <html><body style="margin:0"><video id="v" muted autoplay playsinline style="width:200px;height:120px"></video>
        <script>
        const canvas=document.createElement('canvas');canvas.width=160;canvas.height=90;
        const context=canvas.getContext('2d');let frame=0;
        setInterval(()=>{context.fillStyle='black';context.fillRect(0,0,160,90);
          context.fillStyle='white';context.fillRect((frame++%12)*10,10,20,60);},84);
        try { v.srcObject=canvas.captureStream(12);v.play().catch(()=>{}); }
        catch(e) { document.body.dataset.unsupported='true'; }
        </script></body></html>
        """#
        let child = fixture.replacingOccurrences(of: "&", with: "&amp;").replacingOccurrences(of: "\"", with: "&quot;")
        webView.loadHTMLString(fixture.replacingOccurrences(of: "</body>", with: "<iframe width=220 height=140 srcdoc=\"" + child + "\"></iframe></body>"), baseURL: URL(string: "https://counter.test/"))
        let end = Date().addingTimeInterval(10)
        while Date() < end && (sink.mainFrames < 3 || sink.childFrames < 3) {
            RunLoop.current.run(until: Date().addingTimeInterval(0.05))
        }
        sink.playbackOnly = true
        var deadline = Date().addingTimeInterval(3)
        while Date() < deadline && sink.playingEvents < 2 { RunLoop.current.run(until: Date().addingTimeInterval(0.05)) }
        precondition(sink.playingEvents >= 2, "Muted but playing video must open the manual gate")
        webView.evaluateJavaScript("document.querySelector('video').pause();document.querySelector('iframe').contentDocument.querySelector('video').pause();")
        deadline = Date().addingTimeInterval(3)
        while Date() < deadline && sink.pausedEvents < 2 { RunLoop.current.run(until: Date().addingTimeInterval(0.05)) }
        precondition(sink.pausedEvents >= 2, "Pausing video must close the manual gate")
        configuration.userContentController.removeScriptMessageHandler(forName: "counterMotion", contentWorld: world)
        webView.stopLoading(); webView.loadHTMLString("", baseURL: nil)
        window.contentView = nil
        precondition(sink.mainFrames >= 3, "Live HTML video frames must reach the isolated-world bridge")
        precondition(sink.childFrames >= 3, "Iframe video frames must reach the isolated-world bridge")
        print("WebKit integration passed: live canvas-stream video frames received from top-level and iframe players without media files; playback-only state handles muted play and pause")
    }
}
