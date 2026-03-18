import SwiftData
import SwiftUI

struct UserDetailView: View {
    @Environment(SessionManager.self) var session
    @Environment(\.modelContext) var context
    @Environment(NotificationManager.self) var notification
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State var isEditPageShowing: Bool = false
    @State var user: User? = nil

    var profileImage: Image? {
        if let user = user,
            let imageData = user.profileImage,
            let uiImage = UIImage(data: imageData)
        {
            return Image(uiImage: uiImage)
        } else {
            return nil
        }
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    DetailView(
                        profileImage: profileImage,
                        titleText: user?.name ?? "Unknown User",
                        subTitleText: user?.role.rawValue ?? "Unknown Designation",
                        detailText: user?.email ?? "Unknown Email",
                        profileBgColor: user?.profileBgColor,
                        onActionButtonTapped: nil,
                        actionButtonTitle: "Update Profile"
                    )
                    .fixedSize(horizontal: false, vertical: true)

                    actionButtonsSection
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .toolbar(.hidden, for: .tabBar)
        }
        .sheet(isPresented: $isEditPageShowing) {
            NavigationStack {
                UserRegistrationForm(
                    isPresented: $isEditPageShowing
                )
            }
        }
        .task {
            if session.isLoggedIn == true {
                user = await session.getUserFromDB(modelContext: context)
            }
        }
    }

    @ViewBuilder
    private var actionButtonsSection: some View {
        if horizontalSizeClass == .regular {
            HStack(spacing: 12) {
                Button {
                    isEditPageShowing.toggle()
                } label: {
                    Text("Update Profile")
                        .font(.body.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.bordered)
                .tint(Color(.systemBlue))

                Button(role: .destructive) {
                    session.logout()
                    notification.showSuccess("Logged out successfully.")
                } label: {
                    Text("Log Out")
                        .font(.body.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.bordered)
                .tint(Color(.systemRed))
            }
        } else {
            VStack(spacing: 12) {
                Button {
                    isEditPageShowing.toggle()
                } label: {
                    Text("Update Profile")
                        .font(.body.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.bordered)
                .tint(Color(.systemBlue))

                Button(role: .destructive) {
                    session.logout()
                    notification.showSuccess("Logged out successfully.")
                } label: {
                    Text("Log Out")
                        .font(.body.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.bordered)
                .tint(Color(.systemRed))
            }
        }
    }
}

#Preview {
    let sampleImage = UIImage(systemName: "person.crop.circle.fill")!
    let sampleData = sampleImage.pngData()

    SessionManager.shared.user = LoggedInUser(
        id: "123",
        name: "Hp",
        role: "Admin"
    )
    return UserDetailView()
        .environment(SessionManager.shared)
}
