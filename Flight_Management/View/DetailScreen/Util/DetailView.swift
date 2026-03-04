import SwiftUI

struct DetailView: View {
    var profileImage: Image?
    var titleText: String
    var subTitleText: String
    var detailText: String
    var profileBgColor: ColorData? = nil

    var onActionButtonTapped: (() -> Void)? = nil
    var actionButtonTitle: String = "Change Status"

    @State private var showImagePreview = false
    @State private var selectedTab: Tab = .detail

    enum Tab: String, CaseIterable {
        case detail = "Detail"
        case tripHistory = "Trip History"
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                detailView
            }
        }
        .fullScreenCover(isPresented: $showImagePreview) {
            NavigationStack {
                ImagePreviewer(
                    image: profileImage,
                    title: titleText,
                    profileBgColor: profileBgColor
                )
            }
        }
    }

    var detailView: some View {
        ScrollView {
            VStack(spacing: 16) {
                primaryCard
                if onActionButtonTapped != nil {
                    actionButton
                        .padding(.bottom, 16)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    var actionButton: some View {
        Button {
            onActionButtonTapped?()
        } label: {
            Text(actionButtonTitle)
                .font(.body.weight(.semibold))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
        }
        .buttonStyle(.bordered)
        .tint(Color(.systemBlue))
        .contentShape(Rectangle())
    }

    var primaryCard: some View {
        VStack(spacing: 0) {
            displayImage
                .padding(.bottom, 20)
            Text(titleText)
                .font(.title)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .padding(.bottom, 10)
            Text(subTitleText)
                .font(.title2)
                .foregroundStyle(Color(.systemGray))
                .lineLimit(1)
                .padding(.bottom, 10)
            TextWithCopyView(text: detailText)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            cardTheme()
        )
    }

    var displayImage: some View {
        Group {
            if profileImage != nil {
                profileImage!
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .onTapGesture {
                        showImagePreview = true
                    }
                    .hoverEffect(.highlight)
            } else {
                fallbackStaffImage()
                    .allowsHitTesting(false)
            }
        }
        .frame(width: 150, height: 150)
        .clipShape(Circle())
        .overlay(
            Circle().stroke(
                Color(.secondarySystemBackground),
                lineWidth: 3
            )
        )
        .foregroundStyle(.gray)
    }
}

#Preview {
    return UserDetailView()
        .environment(SessionManager.shared)
}
