/// sharedLog is protected by an actor, so there is no data race.
/// You can still see non-deterministic ordering in the output because tasks run concurrently — this illustrates a race condition in task ordering.
actor Log {
    var entries: [String] = []

    func append(_ value: String) {
        entries.append(value)
    }

    func getEntries() -> [String] {
        return entries
    }
}

let sharedLog = Log()

func taskA() async {
    for i in 1...5 {
        await sharedLog.append("A\(i)")
        try? await Task.sleep(nanoseconds: 50_000_000)
    }
}

func taskB() async {
    for i in 1...5 {
        await sharedLog.append("B\(i)")
        try? await Task.sleep(nanoseconds: 30_000_000)
    }
}

Task {
    async let a = taskA()
    async let b = taskB()

    await a
    await b

    let finalLog = await sharedLog.getEntries()
    print(finalLog)
}