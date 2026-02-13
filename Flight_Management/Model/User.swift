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
@Observable
class SessionManager {
    static let shared = SessionManager()

    var user: User?
    var isLoggedIn: Bool { user != nil }
    var role: String? { user?.role.rawValue }
    var profileImage: Image? {
        if let profileImageData = user?.profileImage,
            let uiImage = UIImage(data: profileImageData)
        {
            return Image(uiImage: uiImage)
        } else {
            return nil
        }
    }
}
