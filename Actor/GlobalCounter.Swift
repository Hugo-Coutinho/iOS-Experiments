//1. The Global Counter
//
//Scenario:
//Your app needs to track total downloads across all users. Requests come from hundreds of concurrent clients. Occasionally, the server process restarts.
//
//Questions:
//Would you use an actor to manage the counter?
//
//If yes, which type? Stateful? Persistent? Clustered?
//
//How do you handle concurrent increments, retries, and crashes?
//
//When would an actor not be appropriate?
//
//Focus:
//State encapsulation
//
//Concurrency reasoning
//
//Durability vs stateless services

import Foundation

actor GlobalCounter {
    private var value: Int = 0
    private var processedRequests: Set<UUID> = []

    /// Simulated persistence
    private func persist(_ value: Int) {
        // imagine writing to disk / database
    }

    /// Increment with idempotency
    func increment(requestId: UUID) async -> Int {
        if processedRequests.contains(requestId) {
            // Retry detected
            return value
        }

        processedRequests.insert(requestId)
        value += 1
        persist(value)

        return value
    }

    func getValue() async -> Int {
        value
    }
}

struct DownloadTracker {
    let counter = GlobalCounter()

    func increment() async -> Int {
        let requestId = UUID()
        return await counter.increment(requestId: requestId)
    }

    func getValue() async -> Int {
        await counter.getValue()
    }
}

let tracker = DownloadTracker()

Task {
    await withTaskGroup(of: Int.self) { group in
        for _ in 0..<100 {
            group.addTask {
                await tracker.increment()
            }
        }

        for await value in group {
            print("Counter value observed: \(value)")
        }
    }
}
