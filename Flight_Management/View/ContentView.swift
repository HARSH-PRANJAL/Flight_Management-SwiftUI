import SwiftUI

struct ContentView: View {
    @State var addStaff = false
    @State var addAirport = false
    @State var addAircraft = false
    @State var addRoute = false
    
    var body: some View {
        NavigationStack {
                Button(action: {
                    addStaff = true
                }, label: {
                    Text("Add Staff")
                })
                Button(action: {
                    addAirport = true
                }, label: {
                    Text("Add Airport")
                })
                Button(action: {
                    addAircraft = true
                }, label: {
                    Text("Add Aircraft")
                })
                Button(action: {
                    addRoute = true
                }, label: {
                    Text("Add Route")
                })
            }
            .sheet(isPresented: $addStaff, content: {
                StaffRegistrationForm()
            })
            .sheet(isPresented: $addAirport, content: {
                AirportRegistrationForm()
            })
            .sheet(isPresented: $addAircraft, content: {
                AircraftRegistrationForm()
            })
            .sheet(isPresented: $addRoute, content: {
                RouteRegistrationForm()
            })
    }
}
