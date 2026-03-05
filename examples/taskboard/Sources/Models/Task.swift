import Foundation
import Score

struct BoardTask: Entity {
    let id: UUID
    let title: String
    let status: Status
    let priority: Priority

    enum Status: String, Codable, Sendable {
        case todo
        case inProgress = "in_progress"
        case done
    }

    enum Priority: String, Codable, Sendable {
        case low
        case medium
        case high
    }
}
