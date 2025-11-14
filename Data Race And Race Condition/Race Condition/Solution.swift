/// Used an actor (Log) to safely contain and isolate shared mutable state (entries).
/// You accessed it only via await, fully respecting actor isolation.
/// withTaskGroup ensures both taskA() and taskB() run concurrently but complete before printing.

actor Log {
    private var entries: [String] = []

    func append(_ value: String) {
        entries.append(value)
    }

    func getEntries() -> [String] {
        return entries
    }
}

let sharedLog = Log()

func taskA() async {
    for i in 1...2 {
        await sharedLog.append("A\(i)")
        try? await Task.sleep(nanoseconds: 50_000_000)
    }
}

func taskB() async {
    for i in 1...2 {
        await sharedLog.append("B\(i)")
        try? await Task.sleep(nanoseconds: 30_000_000)
    }
}

Task {
    await withTaskGroup(of: Void.self) { group in
        group.addTask { await taskA() }
        group.addTask { await taskB() }
    }

    let finalLog = await sharedLog.getEntries()
    print(finalLog)
}
