import SwiftUI

@available(iOS 13.0, OSX 10.15, *)
public struct EmptyView: View {
    private let text: String

    public init(text: String) {
        self.text = text
    }

    public var body: some View {
        VStack() {
            Spacer()
            HStack {
                Spacer()
                Text(text)
                Spacer()
            }
            Spacer()
            Spacer()
        }
    }
}
