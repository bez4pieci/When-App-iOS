import PhosphorSwift
import Refresher
import SwiftUI

public struct RefreshSpinner: View {
    @Binding var state: RefresherState
    @State private var angle: Double = 0.0
    @State private var isAnimating = false

    public static let height = 48.0

    var foreverAnimation: Animation {
        Animation.linear(duration: 1.0)
            .repeatForever(autoreverses: false)
    }

    public var body: some View {
        VStack {
            switch state.mode {
            case .notRefreshing:
                Ph.check.regular
                    .color(Color.dDefault)
                    .frame(width: 24, height: 24)
                    .padding(12)
                    .onAppear {
                        isAnimating = false
                    }
            case .pulling:
                Ph.spinner.regular
                    .color(Color.dDefault)
                    .frame(width: 24, height: 24)
                    .padding(12)
                    .rotationEffect(.degrees(360 * state.dragPosition))
            case .refreshing:
                Ph.spinner.regular
                    .color(Color.dDefault)
                    .frame(width: 24, height: 24)
                    .padding(12)
                    .rotationEffect(.degrees(self.isAnimating ? 360.0 : 0.0))
                    .onAppear {
                        withAnimation(foreverAnimation) {
                            isAnimating = true
                        }
                    }
            }

        }
        .frame(width: 48, height: 48)
        .background(Color.dBackground)
        .clipShape(Circle())
    }
}
