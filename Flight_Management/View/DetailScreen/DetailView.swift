import SwiftUI

struct DetailView: View {
    @Binding var profileImage: Image?
    @Binding var titleText: String
    @Binding var subTitleText: String
    @Binding var detailText: String?
    @Binding var statusBadge: StatusBadge
    @Binding var primaryRow: ListRow?
    @Binding var listData: [ListRow]
    
    var onActionButtonTapped: (() -> Void)? = {
        print("test")
    }
    var actionButtonTitle: String = "Change Status"
    var currentTaskTitle: String = "Current Task"
    var listDataTitle: String = "Completed Tasks"
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    primaryCard
                        .padding(.bottom, 10)
                    
                    if onActionButtonTapped != nil {
                        Text(actionButtonTitle)
                            .font(.title3)
                            .foregroundColor(Color(.systemBlue).opacity(0.5))
                            .contrast(1.5)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                Color(.tertiarySystemBackground)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            )
                            .padding(.bottom, 30)
                    }
                    
                    if primaryRow != nil {
                        VStack(alignment: .leading, spacing: 0) {
                            Label {
                                Text(currentTaskTitle)
                                    .font(.headline)
                                    .foregroundStyle(Color.primary)
                            } icon: {
                                Image(systemName: "clock.badge.airplane")
                                    .foregroundStyle(Color(.systemCyan))
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 10)
                            
                            primaryRow!
                                .padding(.horizontal, 16)
                                .background(
                                    Color(.tertiarySystemBackground)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                )
                        }
                        .padding(.bottom, 25)
                    }
                    
                    if !listData.isEmpty {
                        VStack(alignment: .leading, spacing: 0) {
                            Label {
                                Text(listDataTitle)
                                    .font(.headline)
                                    .foregroundStyle(Color.primary)
                            } icon: {
                                Image(systemName: "checkmark.circle")
                                    .foregroundStyle(Color(.systemGreen))
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 10)
                            
                            LazyVStack(spacing: 0) {
                                ForEach(listData, id: \.title) { row in
                                    row
                                        .padding(.horizontal, 16)
                                        .background(
                                            Color(.tertiarySystemBackground)
                                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                        )
                                        .padding(.bottom, 10)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 15)
            }
            .scrollIndicators(.hidden)
        }
    }
    
    var primaryCard: some View {
        VStack(spacing: 0) {
            displayImage
                .padding(.bottom, 20)
            Text(titleText)
                .font(.title)
                .fontWeight(.semibold)
                .padding(.bottom, 10)
            Text(subTitleText)
                .font(.title2)
                .foregroundStyle(Color(.systemGray))
                .padding(.bottom, 10)
            if let detailText = self.detailText {
                TextWithCopyView(text: detailText)
            }
            statusCapsule
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            Color(.tertiarySystemBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        )
    }
    
    var statusCapsule: some View {
        HStack {
            Circle()
                .fill(statusBadge.backgroundColor.opacity(20))
                .contrast(1)
                .frame(maxWidth: 10, maxHeight: 10)
                .padding(.leading, 10)
            Text(statusBadge.label)
                .fontWeight(.semibold)
                .foregroundStyle(statusBadge.backgroundColor.opacity(20))
                .padding([.trailing, .vertical], 10)
        }
        .overlay {
            Capsule(style: .circular)
                .fill(statusBadge.backgroundColor.opacity(0.15))
        }
    }
    
    var displayImage: some View {
        Group {
            if profileImage != nil {
                profileImage!
                    .resizable()
                    .frame(width: 150, height: 150)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color(.secondarySystemBackground), lineWidth: 3))
                    .foregroundStyle(.gray)
            } else {
                EmptyView()
            }
        }
    }
}

#Preview {
    NavigationStack {
        DetailView(
            profileImage: .constant(
                Image(systemName: "person.crop.circle.fill")
            ),
            titleText: .constant("Sarah Johnson"),
            subTitleText: .constant("Senior Software Engineer"),
            detailText: .constant("hp@gmail.com"),
            statusBadge: .constant(
                StatusBadge(label: "Active", backgroundColor: Color.onTime)
            ),
            primaryRow: .constant(
                ListRow(
                    profileImage: nil,
                    title: "Implement User Authentication",
                    subtitle:
                        "Create login and signup functionality with JWT tokens",
                    status: StatusBadge(label: "HIGH", backgroundColor: .red)
                )
            ),
            listData: .constant([
                ListRow(
                    profileImage: nil,
                    title: "Design Database Schema",
                    subtitle: "Complete"
                ),
                ListRow(
                    profileImage: nil,
                    title: "Design Database Schem",
                    subtitle: "Complete"
                ),
                ListRow(
                    profileImage: nil,
                    title: "Design Database Sche",
                    subtitle: "Complete"
                ),
                ListRow(
                    profileImage: nil,
                    title: "Design Database Sch",
                    subtitle: "Complete"
                ),
                ListRow(
                    profileImage: nil,
                    title: "Design Database ",
                    subtitle: "Complete"
                ),
                ListRow(
                    profileImage: nil,
                    title: "Design Databas",
                    subtitle: "Complete"
                ),
            ])
        )
    }
}
