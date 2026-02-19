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
        // Total duration is the arrival offset of the last node
        // which includes all journey times and turn-around times
        if nodes.count == 0 { return 0 }
        return nodes.max{ $0.sequence < $1.sequence }?.plannedArrivalOffsetMinutes ?? 0
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
        let sequence = nodes.count + 1
        let arrivalOffset: Int
        
        if nodes.isEmpty {
            // First node always has 0 arrival offset (departure point)
            // journeyTimeMinutes is ignored for first node
            arrivalOffset = 0
        } else {
            // For subsequent nodes: previous offset + journey time + turn around time
            let previousOffset = nodes.last!.plannedArrivalOffsetMinutes
            arrivalOffset = previousOffset + journeyTimeMinutes + turnAroundTimeMinutes
        }
        
        let newNode = RouteNode(
            plannedArrivalOffsetMinutes: arrivalOffset,
            airport: airport,
            sequence: sequence
        )
        nodes.append(newNode)
    }
}

@Model
class RouteNode {
    @Attribute(.unique) var id: UUID
    var airport: Airport
    var plannedArrivalOffsetMinutes: Int
    var sequence: Int

    init(
        plannedArrivalOffsetMinutes: Int,
        airport: Airport,
        sequence: Int
    ) {
        self.id = UUID()
        self.plannedArrivalOffsetMinutes = plannedArrivalOffsetMinutes
        self.airport = airport
        self.sequence = sequence
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
