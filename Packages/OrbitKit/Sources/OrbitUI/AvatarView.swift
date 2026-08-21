import OrbitCore
import SwiftUI

public struct AvatarView: View {
    private let peer: Peer
    private let size: CGFloat
    private let showsPresence: Bool

    public init(peer: Peer, size: CGFloat = Metrics.avatarSize, showsPresence: Bool = true) {
        self.peer = peer
        self.size = size
        self.showsPresence = showsPresence
    }

    public var body: some View {
        Circle()
            .fill(Theme.avatarGradient(for: peer.colorIndex))
            .frame(width: size, height: size)
            .overlay {
                Text(peer.initials)
                    .font(.system(size: size * 0.38, weight: .medium, design: .rounded))
                    .foregroundStyle(.white)
            }
            .overlay(alignment: .bottomTrailing) {
                if showsPresence, peer.kind == .user, peer.presence != .offline {
                    PresenceDot(presence: peer.presence, diameter: size * 0.26)
                }
            }
            .accessibilityHidden(true)
    }
}

public struct PresenceDot: View {
    private let presence: Presence
    private let diameter: CGFloat

    public init(presence: Presence, diameter: CGFloat) {
        self.presence = presence
        self.diameter = diameter
    }

    public var body: some View {
        Circle()
            .fill(presence.isOnline ? Theme.online : Theme.away)
            .frame(width: diameter, height: diameter)
            // Punches the dot out of whatever it sits on, rather than drawing
            // a border in a colour we would have to guess.
            .overlay(Circle().stroke(Theme.background, lineWidth: diameter * 0.16))
    }
}

#Preview {
    HStack(spacing: 16) {
        AvatarView(peer: PreviewData.chats[0].peer)
        AvatarView(peer: PreviewData.chats[1].peer)
        AvatarView(peer: PreviewData.chats[2].peer, size: Metrics.smallAvatarSize)
    }
    .padding()
}
