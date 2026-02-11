import SwiftUI
import SwiftData

struct RouteNodeData: Identifiable {
    let id: UUID = UUID()
    let airport: Airport
    var journeyTimeMinutes: String = ""
    
    var turnAroundTime: Int = 30
}

@Observable
final class RouteRegistrationFormViewModel {
    var routeName: String = ""
    var selectedNodes: [RouteNodeData] = []
    
    var fieldErrors: [FieldError: String] = [:]
    var submissionState: SubmissionState = .none
    
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
            guard let journeyTime = Int(node.journeyTimeMinutes), journeyTime > 0 else {
                fieldErrors[.journeyTime] = "Journey time for leg \(index + 1) must be greater than 0 minutes."
                return false
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

    func removeAirport(at index: Int) {
        guard index < selectedNodes.count else { return }
        selectedNodes.remove(at: index)
    }

    func updateJourneyTime(at index: Int, minutes: String) {
        guard index < selectedNodes.count else { return }
        selectedNodes[index].journeyTimeMinutes = minutes
        fieldErrors.removeValue(forKey: .journeyTime)
    }

    var routeSummary: String {
        let codes = selectedNodes.map { $0.airport.code }.joined(separator: " → ")
        return codes.isEmpty ? "No airports selected" : codes
    }

    var totalDuration: Int {
        selectedNodes.reduce(0) { sum, node in
            sum + (Int(node.journeyTimeMinutes) ?? 0)
        }
    }

    func saveRoute(to context: ModelContext) -> Bool {
        guard validateAll() else { return false }
        
        let route = Route(name: routeName.trimmingCharacters(in: .whitespacesAndNewlines))
        
        // Add nodes using the Route's addNode function
        for node in selectedNodes {
            if let journeyTime = Int(node.journeyTimeMinutes) {
                route.addNode(
                    airport: node.airport,
                    journeyTimeMinutes: journeyTime,
                    turnAroundTimeMinutes: node.turnAroundTime
                )
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
