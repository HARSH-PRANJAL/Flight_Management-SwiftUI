import SwiftUI

struct RouteDetailView: View {
    let route: Route
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            DetailView(
                profileImage: nil,
                titleText: route.name,
                subTitleText: "Airports: \(route.nodes.count)",
                statusBadge: nil,
                listData: route.trips.map { ListRow(trip: $0) }
            )
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .scrollDisabled(true)
            .toolbar(.hidden, for: .bottomBar)
        }
    }
}

#Preview {
    NavigationStack {
        RouteDetailView(
            route: Route(
                name: "London to New York"
            )
        )
    }
}
