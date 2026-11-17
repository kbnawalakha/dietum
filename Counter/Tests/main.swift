import Foundation

let resolver = LinkResolver()
func resolved(_ input: String) -> URL { try! resolver.resolve(input) }
func expectInvalid(_ value: String) {
    do { _ = try resolver.resolve(value); fatalError("Accepted invalid input") }
    catch is LinkError { }
    catch { fatalError("Unexpected error") }
}
for input in ["", "   ", "javascript:alert(1)", "file:///tmp/movie.mp4", "ftp://example.com/a", "https://", "https://user:secret@example.com/a", "not a link"] {
    expectInvalid(input)
}
assert(resolved(" example.com/watch?v=123 \n").absoluteString == "https://example.com/watch?v=123")
assert(resolved("http://example.com/movie.mp4").scheme == "http")
assert(resolver.isDirectVideo(resolved("https://example.com/VIDEO.MP4?token=123")))
assert(resolver.isDirectVideo(resolved("https://example.com/live.m3u8")))
assert(!resolver.isDirectVideo(resolved("https://example.com/watch?v=movie.mp4")))
print("13 link validation and routing checks passed")
