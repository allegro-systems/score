import Foundation
import Score

struct SocialUser: Entity {
    let id: UUID
    let username: String
    let displayName: String
    let avatarURL: String
}
