import SwiftUI

struct AdminHome: View {
    @Environment(SessionManager.self) var session

    @State var isAddStaffPresented: Bool = false
    @State var isAddRoutePresented: Bool = false

    var body: some View {
        TabView {
            Tab("Home", systemImage: "house") {
                NavigationStack {
                    AdminDashboardView()
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
    let sampleImage = UIImage(systemName: "person.crop.circle.fill")!
    let sampleData = sampleImage.pngData()
    return AdminHome()
        .environment(SessionManager.shared)
}
