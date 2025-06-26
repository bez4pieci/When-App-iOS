import PhosphorSwift
import SwiftUI

struct NoStation: View {
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    let offset: Binding<Double>
    let onSelectStation: () -> Void

    private var headerHeight = 240.0
    private var cornerRadius = 24.0

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
                .frame(height: headerHeight)

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
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .contentShape(RoundedRectangle(cornerRadius: cornerRadius))

            Spacer()
        }
        .padding(.horizontal, 16)
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
            return geometry.contentOffset.y + geometry.contentInsets.top
        } action: { _, new in
            offset.wrappedValue = new
        }
    }
}
