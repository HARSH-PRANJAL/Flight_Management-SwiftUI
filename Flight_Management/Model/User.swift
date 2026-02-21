import Foundation
import Observation
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
    var profileBgColor: ColorData
    @Attribute(.unique)
    var email: String

    init(
        name: String,
        email: String,
        password: String,
        role: UserRole,
        profileImage: Data? = nil,
        profileBgColor: ColorData = ColorData(Color.gray)
    ) {
        self.id = UUID()
        self.name = name
        self.email = email
        self.password = password
        self.role = role
        self.profileImage = profileImage
        self.profileBgColor = profileBgColor
    }
}

// for user session management
struct LoggedInUser: Codable {
    let id: String
    let name: String
    let role: String
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
            let savedUser = try? JSONDecoder().decode(
                LoggedInUser.self,
                from: data
            )
        {
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
            role: matched.role.rawValue
        )
    }

    func getUserFromDB(modelContext: ModelContext) async -> User? {
        if !self.isLoggedIn {
            return nil
        }

        guard let userIdString = user?.id,
            let userUUID = UUID(uuidString: userIdString)
        else { return nil }

        do {
            let predicate = #Predicate<User> { $0.id == userUUID }
            let descriptor = FetchDescriptor<User>(
                predicate: predicate,
                sortBy: []
            )
            let results = try modelContext.fetch(descriptor)

            if let fetchedUser = results.first {
                print(fetchedUser.name)
                return fetchedUser
            }
        } catch {
            print("Failed to fetch user: \(error)")
        }
        
        return nil
    }
}
