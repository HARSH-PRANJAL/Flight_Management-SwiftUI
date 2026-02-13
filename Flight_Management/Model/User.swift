import Foundation
import SwiftData
import SwiftUI
import Observation

@Model
class User {
    @Attribute(.unique)
    var id: UUID

    var name: String
    var password: String
    var role: UserRole
    var profileImage: Data?

    init(name: String, password: String, role: UserRole = .crew, profileImage: Data? = nil) {
        self.id = UUID()
        self.name = name
        self.password = password
        self.role = role
        self.profileImage = profileImage
    }
}

// for user session management
struct LoggedInUser: Codable {
    let id: String
    let name: String
    let role: String
    let profileImage: Data?
}

@Observable
final class SessionManager {

    static let shared = SessionManager()

    var user: LoggedInUser? {
        didSet {
            if let user {
                let data = try? JSONEncoder().encode(user)
                UserDefaults.standard.set(data, forKey: "loggedInUser")
            } else {
                UserDefaults.standard.removeObject(forKey: "loggedInUser")
            }
        }
    }

    var isLoggedIn: Bool { user != nil }

    private init() {
        if let data = UserDefaults.standard.data(forKey: "loggedInUser"),
           let savedUser = try? JSONDecoder().decode(LoggedInUser.self, from: data) {
            user = savedUser
        }
    }

    func logout() {
        user = nil
    }
    
    func loginUser(_ matched: User) {
            user = LoggedInUser(
                id: matched.id.uuidString,
                name: matched.name,
                role: matched.role.rawValue,
                profileImage: matched.profileImage
            )
        }
}
