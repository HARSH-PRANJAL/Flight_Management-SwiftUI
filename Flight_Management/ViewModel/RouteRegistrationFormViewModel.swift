import SwiftData
import SwiftUI

struct RouteNodeData: Identifiable, Equatable {
    let id: UUID = UUID()
    let airport: Airport
    var journeyTimeMinutes: String = ""

    var turnAroundTime: Int = 0

    static func == (lhs: RouteNodeData, rhs: RouteNodeData) -> Bool {
        lhs.id == rhs.id && lhs.airport.id == rhs.airport.id
            && lhs.journeyTimeMinutes == rhs.journeyTimeMinutes
            && lhs.turnAroundTime == rhs.turnAroundTime
    }
}

@Observable
final class RouteRegistrationFormViewModel {
    var routeName: String = ""
    var selectedNodes: [RouteNodeData] = []

    var fieldErrors: [FieldError: String] = [:]
    var submissionState: SubmissionState = .none

    var isEditMode: Bool = false
    var routeToEdit: Route?

    var originalSnapshot: Snapshot?
    struct Snapshot: Equatable {
        let routeName: String
        let selectedNodes: [RouteNodeData]
    }

    var isDirty: Bool {
        guard let original = originalSnapshot else { return false }
        return currentSnapshot() != original
    }

    func currentSnapshot() -> Snapshot {
        return Snapshot(
            routeName: routeName,
            selectedNodes: selectedNodes
        )
    }

    init() {}

    init(route: Route) {
        self.isEditMode = true
        self.routeToEdit = route
        self.loadRouteData(route)
    }

    private func loadRouteData(_ route: Route) {
        self.routeName = route.name
        self.selectedNodes = route.nodes.map { node in
            RouteNodeData(
                airport: node.airport,
                journeyTimeMinutes: "\(node.plannedArrivalOffsetMinutes)",
                turnAroundTime: 30
            )
        }
    }

    func resetForm() {
        routeName = ""
        selectedNodes = []
        fieldErrors = [:]
    }
}

// MARK: - Validators
extension RouteRegistrationFormViewModel {
    func validateRouteName() -> Bool {
        let trimmed = routeName.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            fieldErrors[.routeName] = "Route name cannot be empty."
            return false
        }

        routeName = trimmed
        return true
    }

    func validateAirports() -> Bool {
        if selectedNodes.count <= 1 {
            fieldErrors[.airports] = "Add at least two airport to the route."
            return false
        }

        // Check for duplicate airports
        let codes = Set(selectedNodes.map { $0.airport.code })
        if codes.count != selectedNodes.count {
            fieldErrors[.airports] = "Cannot add the same airport twice."
            return false
        }

        return true
    }

    func validateJourneyTimes() -> Bool {
        for (index, node) in selectedNodes.enumerated() {
            if index != 0 {
                guard let journeyTime = Int(node.journeyTimeMinutes),
                    journeyTime > 0
                else {
                    fieldErrors[.journeyTime] =
                        "Journey time for leg \(index + 1) must be greater than 0 minutes."
                    return false
                }
            }
        }

        return true
    }

    func validateAll() -> Bool {
        var isValid = true

        isValid = validateRouteName() && isValid
        isValid = validateAirports() && isValid
        isValid = validateJourneyTimes() && isValid

        return isValid
    }

    func addAirport(_ airport: Airport) {
        if !selectedNodes.contains(where: { $0.airport.code == airport.code }) {
            selectedNodes.append(RouteNodeData(airport: airport))
            fieldErrors.removeValue(forKey: .airports)
        }
    }

    func removeAirport(_ node: RouteNodeData) {
        selectedNodes.removeAll(where: {
            $0.id == node.id
        })
    }

    func updateJourneyTime(for node: RouteNodeData, minutes: String) {
        guard
            let index = selectedNodes.firstIndex(where: {
                $0.id == node.id
            })
        else {
            return
        }

        selectedNodes[index].journeyTimeMinutes = minutes
        fieldErrors.removeValue(forKey: .journeyTime)
    }

    var routeSummary: String {
        let codes = selectedNodes.map { $0.airport.code }.joined(
            separator: " → "
        )
        return codes.isEmpty ? "No airports selected" : codes
    }

    var totalDuration: Int {
        selectedNodes.reduce(0) { sum, node in
            sum + (Int(node.journeyTimeMinutes) ?? 0)
        }
    }

    func saveRoute(to context: ModelContext) -> Bool {
        guard validateAll() else { return false }
        let route = Route(
            name: routeName.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        for node in selectedNodes {
            if node.id == selectedNodes.first?.id {
                route.addNode(
                    airport: node.airport,
                    journeyTimeMinutes: 0,
                    turnAroundTimeMinutes: node.turnAroundTime
                )
            } else {
                if let journeyTime = Int(node.journeyTimeMinutes) {
                    route.addNode(
                        airport: node.airport,
                        journeyTimeMinutes: journeyTime,
                        turnAroundTimeMinutes: node.turnAroundTime
                    )
                }
            }
        }

        context.insert(route)

        do {
            try context.save()
            submissionState = .success
            return true
        } catch {
            submissionState = .error
            return false
        }
    }
}
