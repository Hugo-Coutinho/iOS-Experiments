/// This code eliminates data race conditions using an actor.
/// wrapped the shared mutable state (storage) inside an actor, which enforces actor isolation.
/// Each concurrent task now safely calls await counter.increment(), ensuring serialized access to storage.
/// The result (counterValue) will always be 1000, regardless of task scheduling order.

actor Counter {
    private var storage: Int = 0
     
    func increment() {
        storage += 1
    }
     
    func getValue() -> Int {
        return storage
    }
     
}
 
/// Actor object
var counter: Counter = Counter()
 
func incrementCounter() async {
    await withTaskGroup(of: Void.self) {
        group in for _ in 0..<1000 {
            group.addTask {
                /// Mutiple tasks using actor to increment `storage`
                await counter.increment()
            }
        }
    }
     
    /// Using actor to get `storage`
    let counterValue = await counter.getValue()
    print(counterValue)
}