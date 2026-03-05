import Foundation
import Score

struct User: Entity {
    let id: UUID
    let username: String
    let email: String
    let plan: Plan

    enum Plan: String, Codable, Sendable {
        case free
        case pro
        case enterprise
    }
}
