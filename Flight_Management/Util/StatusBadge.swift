import SwiftUI

struct StatusCapsuleView: View {
    
    let statusBadge: StatusBadge
    
    var body: some View {
        HStack {
            Circle()
                .fill(statusBadge.backgroundColor.opacity(20))
                .contrast(1)
                .frame(maxWidth: 10, maxHeight: 10)
                .padding(.leading, 10)
            Text(statusBadge.label)
                .fontWeight(.semibold)
                .foregroundStyle(statusBadge.backgroundColor.opacity(20))
                .padding([.trailing, .vertical], 10)
        }
        .overlay {
            Capsule(style: .circular)
                .fill(statusBadge.backgroundColor.opacity(0.15))
        }
    }
}

struct StatusBadge {
    let label: String
    let backgroundColor: Color

    static func from(staffStatus: StaffAvailabilityStatus) -> StatusBadge {
        let bgColor = Color.staffStatusColor(for: staffStatus)
        
        switch staffStatus {
        case .available:
            return StatusBadge(label: "Available", backgroundColor: bgColor)
        case .onDuty:
            return StatusBadge(label: "On Duty", backgroundColor: bgColor)
        case .unavailable:
            return StatusBadge(label: "Unavailable", backgroundColor: bgColor)
        }
    }

    static func from(aircraftStatus: AircraftStatus) -> StatusBadge {
        let bgColor = Color.aircraftStatusColor(for: aircraftStatus)
        
        switch aircraftStatus {
        case .available:
            return StatusBadge(
                label: "Available",
                backgroundColor: bgColor
            )
        case .assigned:
            return StatusBadge(
                label: "Assigned",
                backgroundColor: bgColor
            )
        }
    }

    static func from(tripStatus: TripStatus) -> StatusBadge {
        let bgColor = Color.tripStatusColor(for: tripStatus)
        
        switch tripStatus {
        case .scheduled:
            return StatusBadge(
                label: "Scheduled",
                backgroundColor: bgColor
            )
        case .onTime:
            return StatusBadge(
                label: "On Time",
                backgroundColor: bgColor
            )
        case .delayed:
            return StatusBadge(
                label: "Delayed",
                backgroundColor: bgColor
            )
        case .cancelled:
            return StatusBadge(
                label: "Cancelled",
                backgroundColor: bgColor
            )
        case .completed:
            return StatusBadge(
                label: "Completed",
                backgroundColor: bgColor
            )
        }
    }
}
