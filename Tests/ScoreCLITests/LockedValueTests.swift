import Foundation
import Testing

@testable import ScoreCLI

@Test func lockedValueStoresAndReturns() {
    let box = LockedValue(42)
    let result = box.withLock { $0 }
    #expect(result == 42)
}

@Test func lockedValueMutates() {
    let box = LockedValue(0)
    box.withLock { $0 += 10 }

    let result = box.withLock { $0 }
    #expect(result == 10)
}

@Test func lockedValueIsThreadSafe() async {
    let box = LockedValue(0)

    await withTaskGroup(of: Void.self) { group in
        for _ in 0..<100 {
            group.addTask {
                box.withLock { $0 += 1 }
            }
        }
    }

    let result = box.withLock { $0 }
    #expect(result == 100)
}

@Test func lockedValueWithOptional() {
    let box = LockedValue<String?>(nil)
    #expect(box.withLock { $0 } == nil)

    box.withLock { $0 = "hello" }
    #expect(box.withLock { $0 } == "hello")
}
