import SwiftUI

struct RouteDetailView: View {
    let route: Route
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            DetailView(route: route)
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
