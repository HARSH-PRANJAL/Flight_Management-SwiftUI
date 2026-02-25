import SwiftData
import SwiftUI

struct ReplaceStaffSheet: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext

    @State var searchedText: String = ""

    var currentStaff: Staff
    var availableStaffList: [Staff]
    var onReplacement: (Staff) -> Void

    var displayedStaff: [Staff] {
        return searchedText.isEmpty
            ? availableStaffList
            : availableStaffList.filter {
                $0.name.localizedCaseInsensitiveContains(searchedText)
            }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                Group {
                    if displayedStaff.isEmpty {
                        fallbackBackground
                    } else {
                        List {
                            ForEach(displayedStaff) { staff in
                                Button(action: {
                                    onReplacement(staff)
                                    dismiss()
                                }) {
                                    ListRow(staff: staff)
                                }
                            }
                        }
                        .listStyle(.insetGrouped)
                        .scrollDismissesKeyboard(.immediately)
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
                .searchable(
                    text: $searchedText,
                    placement: .automatic,
                    prompt: "Search by name"
                )
            }
        }
    }
}

extension ReplaceStaffSheet {
    var fallbackBackground: some View {
        ContentUnavailableView {
            Image(systemName: "person.2")
        } description: {
            Text("No staff")
        }
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
