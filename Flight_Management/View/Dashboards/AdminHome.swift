import SwiftUI

struct AdminHome: View {
    @Environment(SessionManager.self) var session
    @Environment(NotificationManager.self) var notificationManager
    @Environment(\.modelContext) var modelContext

    @State var isAddStaffPresented: Bool = false
    @State var isAddRoutePresented: Bool = false

    var body: some View {
        TabView {
            Tab("Home", systemImage: "house") {
                NavigationStack {
                    AdminDashboardView()
                        .toolbar {
                            profileHandlerToolbarItem(
                                session: session,
                                modelContext: modelContext
                            )
                        }
                }
            }

            Tab("Staff", systemImage: "person.2") {
                NavigationStack {
                    StaffListView()
                        .toolbar {
                            ToolbarItem(placement: .topBarLeading) {
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
                            ToolbarItem(placement: .topBarLeading) {
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
