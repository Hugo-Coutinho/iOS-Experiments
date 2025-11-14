/// A simple class representing a connection.
/// Marking Connection as Sendable ensures it can be safely used across concurrent contexts.

final class Connection: Sendable {
    let id: String
    
    init(id: String) {
        self.id = id
    }

}

struct Session {
    var connection: Connection
}

func process(_ session: Session) async {
    await Task.detached {
        let connectionId = session.connection.id
        print(connectionId)
    }.value
}