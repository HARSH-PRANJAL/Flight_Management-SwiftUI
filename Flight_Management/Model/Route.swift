import Foundation
import SwiftData

@Model
class Route {
    @Attribute(.unique)
    var id: UUID
    @Attribute(.unique)
    var name: String

    @Relationship(deleteRule: .cascade)
    var nodes: [RouteNode]
    @Relationship(deleteRule: .cascade, inverse: \Trip.route)
    var trips: [Trip]

    var nameSearchKey: String
    var isActive: Bool = true

    var totalPlannedDurationMinutes: Int {
        // Total duration is the arrival offset of the last node
        // which includes all journey times and turn-around times
        if nodes.count == 0 { return 0 }
        return nodes.max { $0.sequence < $1.sequence }?
            .plannedArrivalOffsetMinutes ?? 0
    }

    init(name: String) {
        self.id = UUID()
        self.name = name
        self.nameSearchKey = Route.normalisedSearchKey(from: name)
        self.nodes = []
        self.trips = []
    }

    func addNode(
        airport: Airport,
        journeyTimeMinutes: Int,
        turnAroundTimeMinutes: Int = 0
    ) {
        let sequence = nodes.count + 1
        let arrivalOffset: Int

        if let lastNode = nodes.last {
            // For subsequent nodes: previous offset + journey time + turn around time
            arrivalOffset =
                lastNode.plannedArrivalOffsetMinutes + journeyTimeMinutes
                + turnAroundTimeMinutes
        } else {
            // First node always has 0 arrival offset (departure point)
            // journeyTimeMinutes is ignored for first node
            arrivalOffset = 0
        }

        let newNode = RouteNode(
            plannedArrivalOffsetMinutes: arrivalOffset,
            airport: airport,
            sequence: sequence
        )
        nodes.append(newNode)
    }
}

extension Route {
    static func normalisedSearchKey(from value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "" }

        let withoutWhitespace =
            trimmed
            .components(separatedBy: .whitespacesAndNewlines)
            .joined()

        return withoutWhitespace.lowercased()
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
    var isRemoved: Bool = false

    var searchKey: String

    var fullName: String { "\(name) (\(code))" }
    var locationLabel: String { "\(city), \(country)" }

    init(code: String, name: String, city: String, country: String) {
        self.id = UUID()
        self.code = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.city = city.trimmingCharacters(in: .whitespacesAndNewlines)
        self.country = country.trimmingCharacters(in: .whitespacesAndNewlines)
        self.searchKey = Airport.makeSearchKey(
            code: code, name: name, city: city, country: country
        )
    }

    func updateDetails(code: String, name: String, city: String, country: String) {
        self.code = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.city = city.trimmingCharacters(in: .whitespacesAndNewlines)
        self.country = country.trimmingCharacters(in: .whitespacesAndNewlines)
        self.searchKey = Airport.makeSearchKey(
            code: code, name: name, city: city, country: country
        )
    }

    static func makeSearchKey(
        code: String, name: String, city: String, country: String
    ) -> String {
        "\(name) \(code) \(city) \(country)"
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
