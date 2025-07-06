import PhosphorSwift
import SwiftUI

struct NoStation: View {
    @ObserveInjection var redraw

    @Environment(\.safeAreaInsets) private var safeAreaInsets
    let offset: Binding<Double>
    let onSelectStation: () -> Void

    init(
        offset: Binding<Double>,
        onSelectStation: @escaping () -> Void
    ) {
        self.offset = offset
        self.onSelectStation = onSelectStation
    }

    var body: some View {
        ScrollView {
            Color.clear
                .frame(height: AppConfig.headerHeight)

            Button(action: onSelectStation) {
                HStack(spacing: 8) {
                    Ph.plus.regular.color(Color.dDefault)
                        .frame(width: 24, height: 24)
                    Text("Select a station")
                        .font(Font.dSmall)
                        .foregroundColor(Color.dDefault)
                }
                .frame(height: 48)

            }
            .padding(.leading, 12)
            .padding(.trailing, 16)
            .buttonStyle(.plain)
            .background(Color.dBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppConfig.cornerRadius))
            .contentShape(RoundedRectangle(cornerRadius: AppConfig.cornerRadius))

            Spacer()
        }
        .padding(.horizontal, 16)
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
            return geometry.contentOffset.y + geometry.contentInsets.top
        } action: { _, new in
            offset.wrappedValue = new
        }
        .enableInjection()
    }
}
