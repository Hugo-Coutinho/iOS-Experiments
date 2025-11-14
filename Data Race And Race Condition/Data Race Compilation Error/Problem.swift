/// Passing closure as a 'sending' parameter risks causing data races between code in the current task and concurrent execution of the closure

class Connection {
    var id = UUID()
}

struct Session {
    var connection: Connection
}

func process(_ session: Session) async {
    await Task.detached {
        print(session.connection.id)
    }.value
}
