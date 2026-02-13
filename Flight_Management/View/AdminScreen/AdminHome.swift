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
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Menu {
                                    Button("Logout") {
                                        session.logout()
                                    }
                                } label: {
                                    Group {
                                        if let user = session.user,
                                            let imageData = user.profileImage,
                                            let uiImage = UIImage(
                                                data: imageData
                                            )
                                        {

                                            Image(uiImage: uiImage)
                                                .resizable()
                                                .scaledToFill()
                                        } else {
                                            Image(systemName: "person.fill")
                                                .resizable()
                                                .scaledToFit()
                                                .padding(6)
                                                .foregroundStyle(.gray)
                                        }
                                    }
                                    .frame(width: 32, height: 32)
                                    .clipShape(Circle())
                                }
                            }
                        }
                        .toolbarColorScheme(.none, for: .navigationBar)
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

    SessionManager.shared.user = LoggedInUser(
        id: "123",
        name: "Hp",
        role: "Admin",
        profileImage: nil
    )
    return AdminHome()
        .environment(SessionManager.shared)
}
