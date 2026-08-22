import SwiftUI

// MARK: - Material

public extension View {
    /// Real Liquid Glass on iOS 26, a blur material before it.
    ///
    /// `interactive` lets the system react to touch on the glass itself — the
    /// subtle lensing under a finger — which is why the tab bar bubble feels
    /// attached to the pill rather than drawn on top of it.
    @ViewBuilder
    func liquidGlass(in shape: some Shape, interactive: Bool = false) -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(interactive ? .regular.interactive() : .regular, in: shape)
        } else {
            self
                .background(.ultraThinMaterial, in: shape)
                .overlay(shape.stroke(Color.primary.opacity(0.08), lineWidth: 0.5))
        }
    }

    /// Groups sibling glass elements so the system can blend them together
    /// instead of stacking two separate blurs. No-op before iOS 26.
    @ViewBuilder
    func liquidGlassGroup(spacing: CGFloat = 12) -> some View {
        if #available(iOS 26.0, *) {
            GlassEffectContainer(spacing: spacing) { self }
        } else {
            self
        }
    }
}

// MARK: - Buttons

/// Circular glass button — the top-bar and toolbar control.
public struct GlassCircleButtonStyle: ButtonStyle {
    private let diameter: CGFloat

    public init(diameter: CGFloat = 40) {
        self.diameter = diameter
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: diameter * 0.42, weight: .medium))
            .foregroundStyle(Color.accentColor)
            .frame(width: diameter, height: diameter)
            .liquidGlass(in: .circle, interactive: true)
            .opacity(configuration.isPressed ? 0.6 : 1)
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.easeOut(duration: 0.16), value: configuration.isPressed)
    }
}

/// Pill glass button — "Edit", "Cancel", "Done".
public struct GlassPillButtonStyle: ButtonStyle {
    private let isProminent: Bool

    public init(isProminent: Bool = false) {
        self.isProminent = isProminent
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(isProminent ? .semibold : .regular))
            .foregroundStyle(Color.accentColor)
            .padding(.horizontal, 16)
            .frame(height: 40)
            .liquidGlass(in: .capsule, interactive: true)
            .opacity(configuration.isPressed ? 0.6 : 1)
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.easeOut(duration: 0.16), value: configuration.isPressed)
    }
}

/// Dismiss control for sheets. Uses a bare glyph rather than a filled circle so
/// it reads as a control on glass, not as a badge.
public struct CloseButton: View {
    private let action: () -> Void

    public init(action: @escaping () -> Void) {
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
        }
        .buttonStyle(GlassCircleButtonStyle(diameter: 36))
        .accessibilityLabel("Close")
    }
}

#Preview {
    ZStack {
        LinearGradient(colors: [.purple, .blue, .teal], startPoint: .top, endPoint: .bottom)

        VStack(spacing: 24) {
            HStack(spacing: 12) {
                Button("Edit") {}
                    .buttonStyle(GlassPillButtonStyle())
                Button("Done") {}
                    .buttonStyle(GlassPillButtonStyle(isProminent: true))
            }

            HStack(spacing: 12) {
                Button { } label: { Image(systemName: "square.and.pencil") }
                    .buttonStyle(GlassCircleButtonStyle())
                Button { } label: { Image(systemName: "magnifyingglass") }
                    .buttonStyle(GlassCircleButtonStyle())
                CloseButton {}
            }
        }
    }
    .ignoresSafeArea()
}
