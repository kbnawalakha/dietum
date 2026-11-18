import SwiftUI
import WebKit

struct WebsitePlayer: UIViewRepresentable {
    let url: URL
    @Binding var loading: Bool
    @Binding var error: String?
    let trackingEnabled: Bool
    let onVideo: (EmbeddedVideoEvent) -> Void
    let onNavigation: () -> Void
    private static let world = WKContentWorld.world(name: "CounterVideoAnalysis")

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        configuration.websiteDataStore = .nonPersistent()
        configuration.userContentController.addScriptMessageHandler(context.coordinator, contentWorld: Self.world, name: "counterMotion")
        configuration.userContentController.addUserScript(WKUserScript(source: EmbeddedVideoScript.source,
            injectionTime: .atDocumentEnd, forMainFrameOnly: false, in: Self.world))
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) { context.coordinator.parent = self }

    static func dismantleUIView(_ uiView: WKWebView, coordinator: Coordinator) {
        coordinator.active = false
        uiView.configuration.userContentController.removeScriptMessageHandler(forName: "counterMotion", contentWorld: Self.world)
        uiView.configuration.userContentController.removeAllUserScripts()
        uiView.stopLoading()
        uiView.loadHTMLString("", baseURL: nil)
        uiView.navigationDelegate = nil
        uiView.uiDelegate = nil
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandlerWithReply {
        var active = true
        var parent: WebsitePlayer
        init(parent: WebsitePlayer) { self.parent = parent }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage,
                                   replyHandler: @escaping (Any?, String?) -> Void) {
            let enabled = active && parent.trackingEnabled
            replyHandler(["enabled": enabled], nil)
            guard enabled, let event = EmbeddedVideoEvent(body: message.body) else { return }
            parent.onVideo(event)
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            parent.onNavigation()
            parent.loading = true
            parent.error = nil
        }
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) { parent.loading = false }
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) { failed(error) }
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) { failed(error) }
        private func failed(_ error: Error) {
            guard (error as NSError).code != NSURLErrorCancelled else { return }
            parent.loading = false
            parent.error = (error as NSError).code == NSURLErrorNotConnectedToInternet
                ? "You’re offline. Connect to the internet and tap Reload."
                : "This website couldn’t load. Check the link and tap Reload."
        }
        func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
            parent.onNavigation()
            parent.loading = false
            parent.error = "The website player stopped. Tap Reload to try again."
        }
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            let scheme = navigationAction.request.url?.scheme?.lowercased()
            decisionHandler(["https", "http", "about"].contains(scheme ?? "") ? .allow : .cancel)
        }
        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration,
                     for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            if navigationAction.targetFrame == nil,
               let scheme = navigationAction.request.url?.scheme?.lowercased(),
               ["http", "https"].contains(scheme) { webView.load(navigationAction.request) }
            return nil
        }
    }
}
