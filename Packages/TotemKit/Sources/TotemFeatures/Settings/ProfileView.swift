import TotemCore
import TotemUI
import SwiftUI

/// Your own profile: a large avatar, the shortcuts people actually use, the
/// details others can look you up by, and a shelf for what you have posted.
///
/// The shelf is a segmented control rather than a scrolling tab strip — there
/// are three sections, and a strip that only ever holds three is a lot of
/// machinery for a picker.
public struct ProfileView: View {
    @Environment(AppSettings.self) private var settings

    @State private var isEditing = false
    @State private var isShowingCode = false
    @State private var shelf: Shelf = .media

    public init() {}

    enum Shelf: String, CaseIterable, Identifiable {
        case posts, media, files

        var id: String { rawValue }
        var title: String { rawValue.capitalized }
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                header
                actions
                detailsCard
                shelfSection
            }
            .padding(.top, 4)
            .padding(.bottom, 36)
        }
        .background(Theme.groupedBackground)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // Grouped so iOS 26 renders the pair inside a single glass
            // capsule instead of two separate blurs sitting side by side.
            ToolbarItemGroup(placement: .topBarTrailing) {
                Menu {
                    Button {
                        isShowingCode = true
                    } label: {
                        Label("Username Code", systemImage: "qrcode")
                    }

                    Button {
                        // A share sheet would open here.
                    } label: {
                        Label("Share Profile", systemImage: "square.and.arrow.up")
                    }
                } label: {
                    Label("More", systemImage: "ellipsis")
                }

                Button("Edit") { isEditing = true }
            }
        }
        .sheet(isPresented: $isEditing) { EditProfileView() }
        .sheet(isPresented: $isShowingCode) { UsernameCodeSheet() }
    }

    // MARK: Header

    private var header: some View {
        VStack(spacing: 12) {
            AvatarView(
                peer: Peer(id: "me", name: settings.displayName, kind: .user, presence: .online),
                size: 118,
                showsPresence: false
            )

            VStack(spacing: 3) {
                Text(settings.displayName)
                    .font(.title.weight(.bold))
                    .multilineTextAlignment(.center)

                HStack(spacing: 6) {
                    Circle()
                        .fill(Theme.online)
                        .frame(width: 7, height: 7)

                    Text("online")
                        .font(.subheadline)
                        .foregroundStyle(Theme.secondaryLabel)
                }
            }
        }
    }

    private var actions: some View {
        QuickActionRow {
            QuickActionButton(symbol: "square.and.pencil", title: "Edit") {
                isEditing = true
            }
            QuickActionButton(symbol: "qrcode", title: "Code") {
                isShowingCode = true
            }
            QuickActionButton(symbol: "square.and.arrow.up", title: "Share") {
                // A share sheet would open here.
            }
            QuickActionButton(symbol: "bookmark", title: "Saved") {
                // Saved messages live under Settings.
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: Details

    private var detailsCard: some View {
        SettingsCard {
            VStack(spacing: 0) {
                detailRow(label: "mobile", value: settings.phoneNumber) { EmptyView() }

                Divider().padding(.leading, 16)

                detailRow(label: "username", value: settings.username) {
                    Button {
                        isShowingCode = true
                    } label: {
                        Image(systemName: "qrcode")
                            .font(.title3)
                            .foregroundStyle(Color.accentColor)
                    }
                    .buttonStyle(.borderless)
                    .accessibilityLabel("Show username code")
                }

                if !settings.bio.isEmpty {
                    Divider().padding(.leading, 16)

                    detailRow(label: "bio", value: settings.bio, isTinted: false) { EmptyView() }
                }
            }
        }
        .padding(.horizontal, 16)
    }

    /// Generic over the trailing content rather than taking `some View` with a
    /// default — an opaque parameter type cannot carry a default argument.
    private func detailRow<Trailing: View>(
        label: String,
        value: String,
        isTinted: Bool = true,
        @ViewBuilder trailing: () -> Trailing
    ) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.subheadline)
                    .foregroundStyle(Theme.secondaryLabel)

                Text(value)
                    .font(.body)
                    .foregroundStyle(isTinted ? Color.accentColor : Theme.label)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Spacer(minLength: 8)

            trailing()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(.rect)
    }

    // MARK: Shelf

    private var shelfSection: some View {
        VStack(spacing: 16) {
            Picker("Shelf", selection: $shelf) {
                ForEach(Shelf.allCases) { item in
                    Text(item.title).tag(item)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)

            switch shelf {
            case .posts: postsShelf
            case .media: mediaShelf
            case .files: filesShelf
            }
        }
        .animation(Motion.quick, value: shelf)
    }

    private var postsShelf: some View {
        VStack(spacing: 14) {
            ContentUnavailableView {
                Label("No Posts Yet", systemImage: "photo.on.rectangle.angled")
            } description: {
                Text("Publish photos and videos to show them on your profile.")
            }

            Button {
                // A post composer would open here.
            } label: {
                Text("Add a Post")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.roundedRectangle(radius: 14))
            .padding(.horizontal, 16)
        }
    }

    /// Placeholder tiles rather than bundled photos — the app ships no assets,
    /// and a grid of gradients still shows the layout honestly.
    private var mediaShelf: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 3), count: 3),
            spacing: 3
        ) {
            ForEach(0 ..< 9, id: \.self) { index in
                Rectangle()
                    .fill(Theme.avatarGradient(for: index))
                    .aspectRatio(1, contentMode: .fill)
                    .overlay {
                        Image(systemName: index % 4 == 0 ? "play.circle.fill" : "photo")
                            .font(.title3)
                            .foregroundStyle(.white.opacity(0.85))
                    }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .padding(.horizontal, 16)
    }

    private var filesShelf: some View {
        SettingsCard {
            VStack(spacing: 0) {
                ForEach(Self.files) { file in
                    if file.id != Self.files.first?.id {
                        Divider().padding(.leading, 60)
                    }

                    HStack(spacing: 12) {
                        IconTile(symbol: file.symbol, tint: file.tint, side: 36)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(file.name)
                                .font(.subheadline)
                                .lineLimit(1)

                            Text(file.detail)
                                .font(.caption)
                                .foregroundStyle(Theme.secondaryLabel)
                        }

                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 11)
                }
            }
        }
        .padding(.horizontal, 16)
    }

    /// `Identifiable` rather than iterating `enumerated()`: Swift has no key
    /// paths into tuple elements, so `id: \.offset` would not compile.
    private struct ProfileFile: Identifiable {
        let name: String
        let detail: String
        let symbol: String
        let tint: Color

        var id: String { name }
    }

    private static let files: [ProfileFile] = [
        ProfileFile(name: "Totem-brief.pdf", detail: "PDF - 2.4 MB", symbol: "doc.fill", tint: Theme.coral),
        ProfileFile(name: "type-specimen.zip", detail: "Archive - 18 MB", symbol: "shippingbox.fill", tint: Theme.amber),
        ProfileFile(name: "handoff-notes.md", detail: "Text - 12 KB", symbol: "doc.text.fill", tint: Theme.cobalt)
    ]
}

/// The sheet behind the QR glyph — a stand-in for a scannable username code.
struct UsernameCodeSheet: View {
    @Environment(AppSettings.self) private var settings
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                Image(systemName: "qrcode")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 190, height: 190)
                    .padding(24)
                    .background(
                        Theme.secondaryBackground,
                        in: RoundedRectangle(cornerRadius: 24, style: .continuous)
                    )

                VStack(spacing: 4) {
                    Text(settings.displayName)
                        .font(.title3.weight(.semibold))

                    Text(settings.username)
                        .font(.subheadline)
                        .foregroundStyle(Color.accentColor)
                }

                Text("People can scan this to find you without knowing your number.")
                    .font(.footnote)
                    .foregroundStyle(Theme.secondaryLabel)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                Spacer()
            }
            .padding(.top, 24)
            .background(Theme.groupedBackground)
            .navigationTitle("Username Code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    CloseButton { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

struct EditProfileView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var username = ""
    @State private var bio = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Spacer()

                        VStack(spacing: 10) {
                            AvatarView(
                                peer: Peer(id: "me", name: name.isEmpty ? "?" : name, kind: .user),
                                size: 96,
                                showsPresence: false
                            )

                            Button("Change Photo") {}
                                .font(.subheadline)
                        }

                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }

                Section {
                    TextField("Name", text: $name)
                        .textContentType(.name)
                } footer: {
                    Text("Enter your name and add an optional profile photo.")
                }

                Section {
                    TextField("Bio", text: $bio, axis: .vertical)
                        .lineLimit(3 ... 6)
                } footer: {
                    Text("A few words about you. Anyone who opens your profile can read this.")
                }

                Section {
                    HStack {
                        Text("Username")

                        Spacer()

                        TextField("@username", text: $username)
                            .multilineTextAlignment(.trailing)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }

                    LabeledContent("Number", value: settings.phoneNumber)
                } footer: {
                    Text("Your username lets people message you without your number.")
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", action: commit).fontWeight(.semibold)
                }
            }
            .onAppear {
                name = settings.displayName
                username = settings.username
                bio = settings.bio
            }
        }
    }

    private func commit() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        var trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)

        if !trimmedUsername.isEmpty, !trimmedUsername.hasPrefix("@") {
            trimmedUsername = "@" + trimmedUsername
        }

        if !trimmedName.isEmpty { settings.displayName = trimmedName }
        if !trimmedUsername.isEmpty { settings.username = trimmedUsername }
        settings.bio = bio.trimmingCharacters(in: .whitespacesAndNewlines)

        dismiss()
    }
}

#Preview {
    NavigationStack {
        ProfileView()
            .environment(AppSettings())
    }
}
