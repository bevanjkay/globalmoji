import Foundation
import PickerCore
import Testing

struct GiphyProviderTests {
    static let fixture = Data("""
    {"data": [
      {"id": "abc", "title": "happy cat", "images": {
        "original": {"url": "https://media.giphy.com/abc/giphy.gif", "width": "480", "height": "270"},
        "fixed_width_small": {"url": "https://media.giphy.com/abc/100w.gif", "width": "100", "height": "56"}
      }},
      {"id": "nopreview", "title": "x", "images": {
        "original": {"url": "https://media.giphy.com/x/giphy.gif", "width": "1", "height": "1"}
      }}
    ]}
    """.utf8)

    @Test func parsesRenditions() throws {
        let gifs = try GiphyProvider.parse(Self.fixture)
        #expect(gifs.count == 1)
        #expect(gifs.first?.id == "abc")
        #expect(gifs.first?.previewURL.absoluteString == "https://media.giphy.com/abc/100w.gif")
        #expect(gifs.first?.fullURL.absoluteString == "https://media.giphy.com/abc/giphy.gif")
        #expect(gifs.first?.width == 100)
    }

    @Test func rejectsGarbage() {
        #expect(throws: GIFProviderError.invalidResponse) {
            try GiphyProvider.parse(Data("nope".utf8))
        }
    }

    @Test func missingKeyFailsBeforeNetwork() async {
        await #expect(throws: GIFProviderError.missingAPIKey) {
            _ = try await GiphyProvider(apiKey: "").trending()
        }
    }
}
