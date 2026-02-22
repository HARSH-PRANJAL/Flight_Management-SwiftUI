import SwiftData
import SwiftUI

struct ReplaceStaffSheet: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext

    var currentStaff: Staff
    var availableStaffList: [Staff]
    var onReplacement: (Staff) -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                if availableStaffList.isEmpty {
                    VStack(spacing: 16) {
                        fallbackNoStaffDataImage()
                            .resizable()
                            .scaledToFit()
                            .foregroundStyle(Color(.systemGray3))
                        Text("No Available Staff")
                            .font(.headline)
                        Text(
                            "There are no available staff members with the designation \(currentStaff.designation.rawValue) to replace this crew member."
                        )
                        .font(.body)
                        .foregroundStyle(Color(.systemGray))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                    }
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity,
                        alignment: .center
                    )
                } else {
                    List {
                        ForEach(availableStaffList) { staff in
                            Button(action: {
                                onReplacement(staff)
                                dismiss()
                            }) {
                                HStack(spacing: 12) {
                                    Group {
                                        if let avatarImage = staff.avatarImage {
                                            avatarImage
                                                .resizable()
                                                .clipShape(Circle())
                                        } else {
                                            fallbackStaffImage()
                                        }
                                    }
                                    .frame(width: 48, height: 48)
                                    .overlay {
                                        Circle()
                                            .stroke(Color(.systemGray4), lineWidth: 1)
                                    }

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(staff.name)
                                            .font(.headline)
                                            .foregroundStyle(Color.primary)
                                        Text(staff.designation.rawValue)
                                            .font(.caption)
                                            .foregroundStyle(Color(.systemGray))
                                    }
                                }
                                .padding(.vertical, 8)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Select Replacement Staff")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
            }
        }
    }

    private func isFirstTrip(for staff: Staff) -> Bool {
        return staff.trips.count == 0
    }
    private func lastTripCompletedOn(for staff: Staff) -> String {
        guard let lastCompletedTrip = staff.lastCompletedTrip else {
            print("no last completed")
            return ""
        }

        return formatDate(
            lastCompletedTrip.estimatedArrivalTime,
            format: "d MMMM yyyy"
        )
    }
}

//#Preview {
//    let staff1 = Staff(
//        name: "John Doe",
//        designation: .pilot,
//        gender: .male,
//        email: "john@example.com",
//        dob: Date()
//    )
//    let staff2 = Staff(
//        name: "Jane Smith",
//        designation: .pilot,
//        gender: .female,
//        email: "jane@example.com",
//        dob: Date()
//    )
//
//    return ReplaceStaffSheet(
//        currentStaff: staff1,
//        availableStaffList: [staff2],
//        onReplacement: { _ in }
//    )
//    .modelContainer(for: Staff.self, inMemory: true)
//}
