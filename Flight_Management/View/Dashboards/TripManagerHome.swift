import SwiftUI

struct TripManagerHome: View {
    @Environment(SessionManager.self) var session
    @Environment(\.modelContext) var modelContext
    
    @State private var isTripRegistrationPresented: Bool = false
    
    var body: some View {
        TabView {
            Tab("Home", systemImage: "house") {
                NavigationStack {
                    TripManagerDashboardView()
                        .navigationTitle("Manager")
                        .toolbar {
                            profileHandlerToolbarItem(session: session, modelContext: modelContext)
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
                    RouteListView(requiredFilters: [], selectedFilter: .active)
                }
            }

            Tab("Trips", systemImage: "airplane.departure") {
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
