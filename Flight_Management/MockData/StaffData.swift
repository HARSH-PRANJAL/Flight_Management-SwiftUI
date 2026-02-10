import Foundation
import SwiftData

// Helper to create realistic DOB
func makeDOB(year: Int, month: Int, day: Int) -> Date {
    var components = DateComponents()
    components.year  = year
    components.month = month
    components.day   = day
    return Calendar.current.date(from: components) ?? Date()
}

// Example function to create mock data (call once on first launch or in preview)
func insertMockStaff(context: ModelContext) {
    let staffList: [Staff] = [
        Staff(
            name: "Captain Rajesh Kumar",
            designation: .pilot,
            gender: .male,
            email: "rajesh.kumar@skyhigh.in",
            profileImage: nil,
            dob: makeDOB(year: 1978, month: 4, day: 12)
        ),
        Staff(
            name: "First Officer Priya Sharma",
            designation: .coPilot,
            gender: .female,
            email: "priya.sharma@skyhigh.in",
            profileImage: nil,
            dob: makeDOB(year: 1990, month: 11, day: 23)
        ),
        Staff(
            name: "Senior Cabin Crew Amit Patel",
            designation: .cabinCrew,
            gender: .male,
            email: "amit.patel@skyhigh.in",
            profileImage: nil,
            dob: makeDOB(year: 1985, month: 7, day: 8)
        ),
        Staff(
            name: "Captain Sarah Mathew",
            designation: .pilot,
            gender: .female,
            email: "sarah.mathew@skyhigh.in",
            profileImage: nil,
            dob: makeDOB(year: 1982, month: 2, day: 19)
        ),
        Staff(
            name: "Cabin Crew Neha Gupta",
            designation: .cabinCrew,
            gender: .female,
            email: "neha.gupta@skyhigh.in",
            profileImage: nil,
            dob: makeDOB(year: 1995, month: 9, day: 30)
        ),
        Staff(
            name: "First Officer Vikram Singh",
            designation: .coPilot,
            gender: .male,
            email: "vikram.singh@skyhigh.in",
            profileImage: nil,
            dob: makeDOB(year: 1988, month: 6, day: 15)
        ),
        Staff(
            name: "Lead Cabin Crew Anjali Desai",
            designation: .cabinCrew,
            gender: .female,
            email: "anjali.desai@skyhigh.in",
            profileImage: nil,
            dob: makeDOB(year: 1980, month: 12, day: 5)
        ),
        Staff(
            name: "Captain Arjun Reddy",
            designation: .pilot,
            gender: .male,
            email: "arjun.reddy@skyhigh.in",
            profileImage: nil,
            dob: makeDOB(year: 1975, month: 3, day: 27)
        ),
        Staff(
            name: "Cabin Crew Rohan Mehta",
            designation: .cabinCrew,
            gender: .male,
            email: "rohan.mehta@skyhigh.in",
            profileImage: nil,
            dob: makeDOB(year: 1993, month: 8, day: 14)
        ),
        Staff(
            name: "First Officer Kavita Iyer",
            designation: .coPilot,
            gender: .female,
            email: "kavita.iyer@skyhigh.in",
            profileImage: nil,
            dob: makeDOB(year: 1992, month: 1, day: 9)
        )
    ]

    let existing = try? context.fetch(FetchDescriptor<Staff>())
    if (existing?.isEmpty ?? true) {
        for member in staffList {
            member.isMarkedUnavailable = true
            context.insert(member)
        }
        try? context.save()
    }
}
