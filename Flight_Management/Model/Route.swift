import Foundation
import SwiftData

@Model
class Route {
    @Attribute(.unique)
    var id: UUID

    @Relationship(deleteRule: .cascade)
    var nodes: [RouteNode]
    @Relationship(deleteRule: .cascade, inverse: \Trip.route)
    var trips: [Trip]

    var name: String

    var totalPlannedDurationMinutes: Int {
        nodes.last?.plannedArrivalOffsetMinutes ?? 0
    }

    init(name: String) {
        self.id = UUID()
        self.name = name
        self.nodes = []
        self.trips = []
    }

    func addNode(
        airport: Airport,
        journeyTimeMinutes: Int,
        turnAroundTimeMinutes: Int = 30
    ) {
        var previousOffset: Int
        if nodes.count == 0 {
            previousOffset = 0
        } else {
            previousOffset = nodes.last!.plannedArrivalOffsetMinutes
        }

        // arrival offset is calculated from the source node
        let arrivalOffset =
            previousOffset + journeyTimeMinutes + turnAroundTimeMinutes
        let newNode = RouteNode(
            plannedArrivalOffsetMinutes: arrivalOffset,
            airport: airport
        )
        nodes.append(newNode)
    }
}

@Model
class RouteNode {
    @Attribute(.unique) var id: UUID
    var airport: Airport
    var plannedArrivalOffsetMinutes: Int

    init(
        plannedArrivalOffsetMinutes: Int,
        airport: Airport
    ) {
        self.id = UUID()
        self.plannedArrivalOffsetMinutes = plannedArrivalOffsetMinutes
        self.airport = airport
    }
}

@Model
class Airport {
    @Attribute(.unique)
    var id: UUID

    var code: String
    var name: String
    var city: String
    var country: String

    var fullName: String {
        "\(name) (\(code))"
    }

    var locationLabel: String {
        "\(city), \(country)"
    }

    init(code: String, name: String, city: String, country: String) {
        self.id = UUID()
        self.code = code
        self.name = name
        self.city = city
        self.country = country
    }
}
