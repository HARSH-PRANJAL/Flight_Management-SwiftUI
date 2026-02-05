import Foundation
import SwiftData

@Model
class Route {
    @Attribute(.unique)
    var id: UUID
    
    @Relationship(deleteRule: .cascade)
    var nodes: [RouteNode]
    
    var name: String

    var numberOfStops: Int {
        nodes.count - 1
    }

    var totalPlannedDurationMinutes: Int {
        nodes.last?.plannedArrivalOffsetMinutes ?? 0
    }

    init(name: String) {
        self.id = UUID()
        self.name = name
        self.nodes = []
    }

    func addNode(airport: Airport, journeyTime: Int) {
        let sequence = nodes.count

        var previousOffset: Int
        if nodes.count == 0 {
            previousOffset = 0
        } else {
            previousOffset = nodes.last!.plannedDepartureOffsetMinutes
        }

        let arrivalOffset = previousOffset + journeyTime
        let departureOffset = arrivalOffset + 20
        let newNode = RouteNode(
            sequence: sequence,
            plannedArrivalOffsetMinutes: arrivalOffset,
            plannedDepartureOffsetMinutes: departureOffset,
            airport: airport
        )
        nodes.append(newNode)
    }
}

@Model
class RouteNode {
    @Attribute(.unique) var id: UUID
    var sequence: Int

    @Relationship(deleteRule: .noAction)
    var airport: Airport

    var plannedArrivalOffsetMinutes: Int
    var plannedDepartureOffsetMinutes: Int

    init(
        sequence: Int,
        plannedArrivalOffsetMinutes: Int,
        plannedDepartureOffsetMinutes: Int,
        airport: Airport
    ) {
        self.id = UUID()
        self.sequence = sequence
        self.plannedArrivalOffsetMinutes = plannedArrivalOffsetMinutes
        self.plannedDepartureOffsetMinutes = plannedDepartureOffsetMinutes
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
