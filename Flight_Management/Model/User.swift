import Foundation
import SwiftData
import SwiftUI

@Model
class User {
    @Attribute(.unique)
    var id: UUID

    var name: String
    var password: String
    var role: UserRole
    var profileImage: Data?

    init(name: String, password: String, role: UserRole = .crew) {
        self.id = UUID()
        self.name = name
        self.password = password
        self.role = role
    }
}

// for user session management
struct LoggedInUser {
    let id: String
    let name: String
    let role: String
    let profileImage: Data?
}

@Observable
final class SessionManager {
    static let shared = SessionManager()

    var user: LoggedInUser?
    var isLoggedIn: Bool { user != nil }
    
    func logout() {
        user = nil
    }

    func loginUser(user: User) {
        self.user = LoggedInUser(
            id: user.id.uuidString,
            name: user.name,
            role: user.role.rawValue,
            profileImage: user.profileImage
        )
    }
}
