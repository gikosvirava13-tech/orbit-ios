import TotemCore
import TotemUI
import SwiftUI

/// Theme, accent, wallpaper and text size — with a live sample at the top, so
/// every control shows its effect without leaving the screen.
struct AppearanceSettingsView: View {
    @Environment(AppSettings.self) private var settings

    private let accentColumns = [GridItem(.adaptive(minimum: 54), spacing: 14)]

    var body: some View {
        @Bindable var settings = settings

        List {
            Section {
                preview.plainCardRow()
            }

            Section {
                Picker("Theme", selection: $settings.appearance) {
                    ForEach(AppearanceMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
            } header: {
                Text("Theme")
            }

            Section {
                LazyVGrid(columns: accentColumns, spacing: 14) {
                    ForEach(AccentPalette.allCases) { palette in
                        accentSwatch(palette)
                    }
                }
                .padding(.vertical, 10)
            } header: {
                Text("Accent Colour")
            } footer: {
                Text("Used for buttons, links, the tab bar bubble and your own messages.")
            }

            Section {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Wallpaper.allCases) { paper in
                            Button {
                                settings.wallpaper = paper
                            } label: {
                                VStack(spacing: 6) {
                                    WallpaperSwatch(wallpaper: paper, isSelected: paper == settings.wallpaper)

                                    Text(paper.title)
                                        .font(.caption2)
                                        .foregroundStyle(
                                            paper == settings.wallpaper ? Color.accentColor : Theme.secondaryLabel
                                        )
                                }
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(paper.title)
                        }
                    }
                    .padding(.vertical, 10)
                    // Scrolls edge to edge, but the swatches still start where
                    // the row text would.
                    .padding(.horizontal, 16)
                }
                .listRowInsets(EdgeInsets())
            } header: {
                Text("Chat Wallpaper")
            }

            Section {
                Slider(
                    value: textSizeStep,
                    in: 0 ... Double(TextSize.allCases.count - 1),
                    step: 1
                ) {
                    Text("Text Size")
                } minimumValueLabel: {
                    Text("A").font(.footnote)
                } maximumValueLabel: {
                    Text("A").font(.title3)
                }
                .tint(Color.accentColor)

                LabeledContent("Message Text", value: settings.textSize.title)
            } header: {
                Text("Text Size")
            } footer: {
                Text("Applies to message bubbles. The rest of the app follows your system Dynamic Type setting.")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
        .animation(Motion.standard, value: settings.wallpaper)
        .animation(Motion.standard, value: settings.accent)
    }

    // MARK: Preview

    private var preview: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Today")
                .font(.caption2.weight(.medium))
                .foregroundStyle(Theme.secondaryLabel)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Theme.incomingBubble, in: Capsule())
                .frame(maxWidth: .infinity, alignment: .center)

            bubble("How does this look on your side?", isOutgoing: false)
            bubble("Cleaner. Keep it.", isOutgoing: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .dynamicTypeSize(settings.textSize.dynamicTypeSize)
        .background { WallpaperBackground(wallpaper: settings.wallpaper) }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Theme.separator, lineWidth: 0.5)
        }
    }

    private func bubble(_ text: String, isOutgoing: Bool) -> some View {
        HStack(spacing: 0) {
            if isOutgoing { Spacer(minLength: 44) }

            Text(text)
                .font(.subheadline)
                .foregroundStyle(isOutgoing ? Theme.outgoingBubbleText : Theme.incomingBubbleText)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    isOutgoing ? Theme.outgoingBubble : Theme.incomingBubble,
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                )

            if !isOutgoing { Spacer(minLength: 44) }
        }
    }

    // MARK: Controls

    private func accentSwatch(_ palette: AccentPalette) -> some View {
        let isSelected = palette == settings.accent

        return Button {
            settings.accent = palette
        } label: {
            Circle()
                .fill(palette.color)
                .frame(width: 44, height: 44)
                .overlay {
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.headline)
                            .foregroundStyle(.white)
                    }
                }
                // A ring outside the circle rather than a border on it, so the
                // colour itself is never cut into by the selection state.
                .overlay {
                    Circle()
                        .strokeBorder(isSelected ? palette.color : .clear, lineWidth: 2)
                        .padding(-4)
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(palette.title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    /// The slider works in whole steps over `TextSize.allCases`, so the value
    /// can never land between two named sizes.
    private var textSizeStep: Binding<Double> {
        Binding(
            get: { Double(settings.textSize.step) },
            set: { settings.textSize = TextSize.at(step: Int($0.rounded())) }
        )
    }
}

#Preview {
    NavigationStack {
        AppearanceSettingsView()
            .environment(AppSettings())
    }
}
