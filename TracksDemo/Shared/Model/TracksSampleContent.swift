import Foundation
import AutomatticTracks

struct TracksSampleContent: LogSampleContentProvider {
    var sampleContent: [URL] = [
        Bundle.main.url(forResource: "Alice in Wonderland", withExtension: "txt"),
        Bundle.main.url(forResource: "Frankenstein", withExtension: "txt"),
        Bundle.main.url(forResource: "Price and Prejudice", withExtension: "txt"),
        Bundle.main.url(forResource: "The Scarlet Letter", withExtension: "txt"),
        Bundle.main.url(forResource: "The Strange Case of Dr. Jekyll and Mr. Hyde", withExtension: "txt"),
    ].compactMap { $0 }
}
