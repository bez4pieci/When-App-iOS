import SwiftUI

struct NoStation: View {
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    let onSelectStation: () -> Void

    private var headerHeight = 240.0
    private var cornerRadius = AppConfig.cornerRadius

    init(onSelectStation: @escaping () -> Void) {
        self.onSelectStation = onSelectStation
    }

    var body: some View {
        VStack(alignment: .leading) {
            Color.clear
                .frame(height: headerHeight + 20)

            Button(action: onSelectStation) {
                Text("Select a station")
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                    .foregroundColor(.black)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.dBackground)
                    .clipShape(
                        .rect(
                            cornerSize: .init(
                                width: cornerRadius, height: cornerRadius),
                            style: .continuous)
                    )
            }

            Spacer()
        }
        .frame(maxHeight: .infinity)
        .padding(.horizontal, 16)
        .padding(.bottom, 60 + safeAreaInsets.bottom)
    }
}
