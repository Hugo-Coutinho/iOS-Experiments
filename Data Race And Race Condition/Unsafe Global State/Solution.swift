/// Wrapped the shared mutable dictionary inside an actor, which enforces exclusive access to globalCache.
/// All readers and writers now go through the actor’s isolated methods, making concurrent access serialized and race-free.
/// Same logic kept and concurrency level — multiple writers and a reader still run concurrently, but Swift’s actor isolation ensures correctness.

import Foundation

actor GlobalCache {
    private var cache: [String: String] = [:]
    
    func writerTask(id: Int) async {
        for i in 1...5 {
            cache["key_\(id)_\(i)"] = "value_\(i)"
            try? await Task.sleep(nanoseconds: 10_000_000)
        }
    }
    
    func readerTask() async {
        for _ in 1...5 {
            print(cache.keys)
            try? await Task.sleep(nanoseconds: 15_000_000)
        }
    }
}

let globalCache = GlobalCache()

func runCacheStressTest() async {
    await withTaskGroup(of: Void.self) { group in
        for id in 1...3 {
            group.addTask {
                await globalCache.writerTask(id: id)
            }
        }
        
        group.addTask {
            await globalCache.readerTask()
        }
    }
}

Task {
    await runCacheStressTest()
}
