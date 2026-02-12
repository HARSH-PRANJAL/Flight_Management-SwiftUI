import SwiftUI

struct AdminHome: View {
    @State var isAddStaffPresented: Bool = false
    var body: some View {
        TabView {
            Tab("Home", systemImage: "house") {
                AdminDashboardView()
            }
            
            Tab("Staff", systemImage: "person.3") {
                NavigationStack {
                    StaffListView()
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button {
                                    isAddStaffPresented.toggle()
                                } label: {
                                    Image(systemName: "plus")
                                }
                            }
                        }
                }
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        .sheet(isPresented: $isAddStaffPresented) {
            StaffRegistrationForm()
        }
    }
}

#Preview {
    AdminHome()
}
