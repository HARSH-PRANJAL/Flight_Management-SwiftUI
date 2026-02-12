import Foundation
import SwiftData

@Model
class User {
    @Attribute(.unique)
    var id: UUID

    var name: String
    var password: String
    var role: UserRole

    init(name: String, password: String, role: UserRole = .crew) {
        self.id = UUID()
        self.name = name
        self.password = password
        self.role = role
    }
}
