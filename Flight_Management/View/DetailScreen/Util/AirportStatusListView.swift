import SwiftUI

struct AirportStatusListView: View {

    let trip: Trip

    var body: some View {
        List {
            ForEach(stopInfos) { stop in
                HStack(alignment: .top, spacing: 12) {

                    VStack(alignment: .leading, spacing: 2) {
                        Text(stop.code)
                            .font(.headline)
                        Text(stop.name)
                            .font(.subheadline)
                            .foregroundStyle(Color(.secondaryLabel))
                            .multilineTextAlignment(.leading)

                        Text(stop.city)
                            .font(.callout)
                            .foregroundStyle(Color(.secondaryLabel))
                            .multilineTextAlignment(.leading)

                        Text(stop.plannedTimeLabel)
                            .font(.callout)
                            .foregroundStyle(Color(.label))
                            .padding(.top, 2)

                        if let actual = stop.actualTimeLabel {
                            Text(actual)
                                .font(.callout)
                                .fontWeight(.medium)
                                .foregroundStyle(Color(.label))
                        }
                    }

                    Spacer(minLength: 8)

                    VStack(alignment: .trailing, spacing: 4) {
                        stop.statusBadge

                        if stop.delayMinutes > 0 {
                            Text("+\(stop.delayMinutes) min")
                                .font(.callout)
                                .foregroundStyle(
                                    Color.tripStatusColor(for: .delayed)
                                )
                        }
                    }
                    .padding(.top, 2)
                }
                .padding(.vertical, 4)
            }
        }
        .listStyle(.insetGrouped)
        .scrollIndicators(.hidden)
        .navigationTitle("\(trip.tripNumber) legs")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Util
extension AirportStatusListView {

    private struct StopInfo: Identifiable {
        let id: UUID
        let code: String
        let name: String
        let city: String
        let plannedTimeLabel: String
        let actualTimeLabel: String?
        let delayMinutes: Int
        let statusBadge: Text
    }

    private var sortedNodes: [RouteNode] {
        trip.route.nodes.sorted { $0.sequence < $1.sequence }
    }

    private var statusByNodeId: [UUID: TripNodeStatus] {
        Dictionary(
            uniqueKeysWithValues: trip.nodeStatuses.map {
                ($0.routeNode.id, $0)
            }
        )
    }

    private var stopInfos: [StopInfo] {
        sortedNodes.map { node in
            let isSource = node.sequence == 1

            // Planned time for this node
            let planned = trip.scheduledDepartureTime.addingTimeInterval(
                TimeInterval(node.plannedArrivalOffsetMinutes * 60)
            )
            var plannedLabel =
                isSource
                ? "Planned dep: \(format(planned))"
                : "Planned arr: \(format(planned))"

            let nodeStatus = statusByNodeId[node.id]

            let hasDeparted: Bool =
                isSource
                ? nodeStatus?.actualDepartureTime != nil
                : nodeStatus?.actualArrivalTime != nil

            let isCovered = trip.isCompleted || hasDeparted

            if isCovered {
                let delay =
                    nodeStatus?.totalDelayMinutes(
                        tripStartTime: trip.scheduledDepartureTime
                    ) ?? 0

                var actualLabel: String? = nil

                if isSource {
                    if let dep = nodeStatus?.actualDepartureTime,
                       Calendar.current.isDate(planned, equalTo: dep, toGranularity: .minute) {
                        plannedLabel = "Departed at: \(format(planned))"
                    } else if let dep = nodeStatus?.actualDepartureTime {
                        actualLabel = "Actual dep: \(format(dep))"
                    }
                } else {
                    if let arr = nodeStatus?.actualArrivalTime,
                       Calendar.current.isDate(planned, equalTo: arr, toGranularity: .minute) {
                        plannedLabel = "Arrived at: \(format(planned))"
                    } else if let arr = nodeStatus?.actualArrivalTime {
                        actualLabel = "Actual arr: \(format(arr))"
                    }
                }

                let badge: Text =
                    delay > 0
                    ? Text("Delayed")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.tripStatusColor(for: .delayed))
                    : Text("On Time")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.tripStatusColor(for: .onTime))

                return StopInfo(
                    id: node.id,
                    code: node.airport.code,
                    name: node.airport.name,
                    city: node.airport.locationLabel,
                    plannedTimeLabel: plannedLabel,
                    actualTimeLabel: actualLabel,
                    delayMinutes: delay,
                    statusBadge: badge
                )
            }

            // Cancelled at or beyond this point
            if trip.isCancelled {
                let badge = Text("Cancelled")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.tripStatusColor(for: .cancelled))

                return StopInfo(
                    id: node.id,
                    code: node.airport.code,
                    name: node.airport.name,
                    city: node.airport.locationLabel,
                    plannedTimeLabel: plannedLabel,
                    actualTimeLabel: nil,
                    delayMinutes: 0,
                    statusBadge: badge
                )
            }

            // Upcoming airport
            let badge = Text("Scheduled")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.tripStatusColor(for: .scheduled))

            return StopInfo(
                id: node.id,
                code: node.airport.code,
                name: node.airport.name,
                city: node.airport.locationLabel,
                plannedTimeLabel: plannedLabel,
                actualTimeLabel: nil,
                delayMinutes: 0,
                statusBadge: badge
            )
        }
    }

    private func format(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM, HH:mm"
        formatter.locale = Locale.current
        return formatter.string(from: date)
    }
}
