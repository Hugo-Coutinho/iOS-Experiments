/// Example demonstrating unsafe access to a global cache leading to data races
/// This one mixes shared mutable state, multiple async writers, and interleaved readers.
/// Goal: fix it under Swift 6’s strict concurrency model — no data races, no isolation violations, no logic changes.

import Foundation

var globalCache: [String: String] = [:]

func writerTask(id: Int) async {
    for i in 1...5 {
        globalCache["key_\(id)_\(i)"] = "value_\(i)"   // ❌ Unsafe write
        try? await Task.sleep(nanoseconds: 10_000_000)
    }
}

func readerTask() async {
    for _ in 1...5 {
        print(globalCache.keys)   // ❌ Unsafe read
        try? await Task.sleep(nanoseconds: 15_000_000)
    }
}

func runCacheStressTest() async {
    await withTaskGroup(of: Void.self) { group in
        for id in 1...3 {
            group.addTask { await writerTask(id: id) }
        }
        group.addTask { await readerTask() }
    }
}

Task {
    await runCacheStressTest()
}
