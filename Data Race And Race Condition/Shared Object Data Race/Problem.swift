/// Shared integer counter that multiple concurrent tasks increment.
/// This code demonstrates a data race condition. 

var counter = 0

func incrementCounter() async {
    await withTaskGroup(of: Void.self) { group in
        for _ in 0..<1000 {
            group.addTask {
                counter += 1
            }
        }
    }
    print(counter)
}

await incrementCounter()
