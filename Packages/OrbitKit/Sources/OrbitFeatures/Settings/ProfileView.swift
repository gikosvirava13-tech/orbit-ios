import OrbitCore
import OrbitUI
import SwiftUI

/// Your own profile: a large avatar, the details people can look you up by,
/// and a posts shelf that is honest about being empty.
public struct ProfileView: View {
    @Environment(AppSettings.self) private var settings

    @State private var isEditing = false
    @State private var isShowingCode = false

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                header
                detailsCard
                postsSection
            }
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .background(Theme.groupedBackground)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // Grouped so iOS 26 renders the pair inside a single glass
            // capsule instead of two separate blurs sitting side by side.
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    // Story composer would open here.
                } label: {
                    Label("Add Story", systemImage: "plus.circle.dashed")
                }

                Button("Edit") { isEditing = true }
            }
        }
        .sheet(isPresented: $isEditing) {
            EditProfileView()
        }
        .sheet(isPresented: $isShowingCode) {
            UsernameCodeSheet()
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            AvatarView(
                peer: Peer(id: "me", name: settings.displayName, kind: .user),
                size: 140,
                showsPresence: false
            )

            Text(settings.displayName)
                .font(.largeTitle.weight(.bold))

            Text("online")
                .font(.title3)
                .foregroundStyle(Theme.secondaryLabel)
        }
        .padding(.bottom, 8)
    }

    private var detailsCard: some View {
        VStack(spacing: 0) {
            detailRow(label: "mobile", value: settings.phoneNumber, trailing: nil)

            Divider().padding(.leading, 16)

            detailRow(label: "username", value: settings.username) {
                Button {
                    isShowingCode = true
                } label: {
                    Image(systemName: "qrcode")
                        .font(.title3)
                        .foregroundStyle(Color.accentColor)
                }
                .accessibilityLabel("Show username code")
            }
        }
        .background(Theme.secondaryBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal, 16)
    }

    private func detailRow(
        label: String,
        value: String,
        @ViewBuilder trailing: () -> some View = { EmptyView() }
    ) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.subheadline)
                    .foregroundStyle(Theme.label)
                Text(value)
                    .font(.body)
                    .foregroundStyle(Color.accentColor)
            }

            Spacer()

            trailing()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(.rect)
    }

    private var postsSection: some View {
        VStack(spacing: 18) {
            Text("Posts")
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 22)
                .padding(.vertical, 9)
                .liquidGlass(in: .capsule)

            ContentUnavailableView {
                Label("No Posts Yet", systemImage: "photo.on.rectangle.angled")
            } description: {
                Text("Publish photos and videos to show them on your profile.")
            }

            Button {
                // Post composer would open here.
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
}

/// The sheet behind the QR glyph — a stand-in for a scannable username code.
struct UsernameCodeSheet: View {
    @Environment(AppSettings.self) private var settings
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "qrcode")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .padding(24)
                    .background(Theme.secondaryBackground, in: RoundedRectangle(cornerRadius: 24, style: .continuous))

                Text(settings.username)
                    .font(.title2.weight(.semibold))

                Text("People can scan this to find you without knowing your number.")
                    .font(.footnote)
                    .foregroundStyle(Theme.secondaryLabel)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                Spacer()
            }
            .padding(.top, 24)
            .navigationTitle("Username Code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    CloseButton { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
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
                    Text("A few words about you.")
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
