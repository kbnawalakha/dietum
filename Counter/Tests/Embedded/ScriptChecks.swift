import Foundation
import JavaScriptCore

@main
struct ScriptChecks {
    static func main() {
        let context = JSContext()!
        context.exceptionHandler = { _, error in fatalError(error?.toString() ?? "Script error") }
        context.evaluateScript(#"""
        let messages = [], callbacks = {}, nextTick = null, permitsTracking = true, tainted = false;
        let pixelValue = 153;
        globalThis.addEventListener = (name, callback) => callbacks[name] = callback;
        globalThis.setTimeout = callback => { nextTick = callback; return 1; };
        globalThis.clearTimeout = () => { nextTick = null; };
        globalThis.performance = {now: () => 10000};
        globalThis.getComputedStyle = () => ({display:'block', visibility:'visible'});
        globalThis.webkit = {messageHandlers:{counterMotion:{postMessage: payload => {
          messages.push(payload); return {enabled:permitsTracking};
        }}}};
        const video = {currentTime:0, paused:false, ended:false, seeking:false, readyState:4,
          clientWidth:320, clientHeight:180, isConnected:true, mediaKeys:null,
          getBoundingClientRect:() => ({width:320,height:180})};
        globalThis.document = {
          querySelectorAll: name => name === 'video' ? [video] : [],
          createElement: () => ({getContext: () => ({drawImage:()=>{},getImageData:()=>{
            if (tainted) throw new Error('SecurityError');
            return {data:Array.from({length:1024}, (_,i)=>i%4===3?255:pixelValue)};
          }})})
        };
        function step() { const callback=nextTick; nextTick=null; if (callback) callback(); }
        function lastKind() { return messages[messages.length-1].kind; }
        """#)
        context.evaluateScript(EmbeddedVideoScript.source)
        func check(_ expression: String) { precondition(context.evaluateScript(expression)!.toBool(), expression) }
        check("lastKind() === 'idle'")
        context.evaluateScript("step()")
        check("lastKind() === 'frame' && messages[messages.length-1].grid.length === 256")
        check("Math.abs(messages[messages.length-1].grid[0] - 0.6) < 0.0001")
        context.evaluateScript("video.paused=true; step()")
        check("lastKind() === 'paused'")
        context.evaluateScript("video.paused=false; video.seeking=true; step()")
        check("lastKind() === 'seeking'")
        context.evaluateScript("video.seeking=false; tainted=true; step()")
        check("lastKind() === 'blocked'")
        context.evaluateScript("tainted=false; video.mediaKeys={}; step()")
        check("lastKind() === 'blocked'")
        context.evaluateScript("video.mediaKeys=null; permitsTracking=false; step()")
        context.evaluateScript("step()")
        check("lastKind() === 'idle'")
        context.evaluateScript("callbacks.pagehide()")
        check("nextTick === null")
        print("Embedded script checks passed: frame sampling, numeric grid, pause, seek, CORS/DRM blocking, disable, page cleanup")
    }
}
