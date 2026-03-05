import Foundation
import Score

struct Post: Entity {
    let id: UUID
    let authorID: UUID
    let content: String
    let createdAt: Date
    let syncVersion: Int
}
