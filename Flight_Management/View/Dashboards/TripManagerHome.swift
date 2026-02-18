import SwiftUI

struct TripManagerHome: View {
    @Environment(SessionManager.self) var session
    
    @State private var isTripRegistrationPresented: Bool = false
    
    var body: some View {
        TabView {
            Tab("Home", systemImage: "house") {
                NavigationStack {
                    TripManagerDashboardView()
                        .navigationTitle("Manager")
                        .toolbar {
                            profileHandlerToolbarItem(session: session)
                        }
                }
            }

            Tab("Aircrafts", systemImage: "airplane") {
                NavigationStack {
                    AircraftListView()
                }
            }

            Tab("Routes", systemImage: "map") {
                NavigationStack {
                    RouteListView()
                }
            }

            Tab("Trips", systemImage: "pin") {
                NavigationStack {
                    TripListView()
                        .toolbar {
                            ToolbarItem(placement: .topBarLeading) {
                                Button {
                                    isTripRegistrationPresented.toggle()
                                } label: {
                                    Image(systemName: "plus")
                                }
                            }
                        }
                }
            }
        }
        .sheet(isPresented: $isTripRegistrationPresented) {
            NavigationStack {
                TripRegistrationForm(isPresented: $isTripRegistrationPresented)
            }
        }
    }
}
