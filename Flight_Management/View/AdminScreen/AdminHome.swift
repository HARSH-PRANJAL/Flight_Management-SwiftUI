import SwiftUI

struct AdminHome: View {
    @State var isAddStaffPresented: Bool = false
    @State var isAddRoutePresented: Bool = false

    @AppStorage("isLoggedIn") private var isLoggedIn: Bool?
    @AppStorage("currentUserName") private var currentUserName: String?
    @AppStorage("currentUserRole") private var currentUserRole: String?

    var body: some View {
        TabView {
            Tab("Home", systemImage: "house") {
                NavigationStack {
                    AdminDashboardView()
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Menu {
                                    Button("Logout") {
                                        currentUserName = ""
                                        currentUserRole = ""
                                        isLoggedIn = false
                                    }
                                } label: {
                                    Image(
                                        systemName: "line.3.horizontal.decrease"
                                    )
                                }
                            }
                        }
                }
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

            Tab("Route", systemImage: "location") {
                NavigationStack {
                    RouteListView()
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button {
                                    isAddRoutePresented.toggle()
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
            NavigationStack {
                StaffRegistrationForm()
                    .navigationTitle("Add Staff")
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
        .sheet(isPresented: $isAddRoutePresented) {
            NavigationStack {
                RouteRegistrationForm()
                    .navigationTitle("Create Route")
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
}

#Preview {
    AdminHome()
}
