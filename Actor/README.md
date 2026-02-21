# Swift Concurrency: Actors

A key concept for thread-safe programming.

## What Is an Actor?

An **actor** in Swift is a **reference type** that protects its internal state by serializing access to its properties, preventing **data races** and **race conditions**. Actors ensure that only one task at a time can access their isolated state, making concurrent code safer and easier to reason about. :contentReference[oaicite:0]{index=0}

It’s important to keep mutable actor properties `private`. An actor can protect what happens inside its own context, but once an object escapes that isolated scope, the actor can no longer guarantee thread safety. :contentReference[oaicite:1]{index=1}

In cases where you need to pass data from one isolated context to another, the right way to do that **without risking race conditions** is to ensure that the value is **Sendable**. :contentReference[oaicite:2]{index=2}

## Code Example

Below is an example showing how to safely handle concurrent updates to a live event score using an actor:

```swift
actor ScoreBoard {
    // Private state is protected by the actor,
    // ensuring that only one task can access it at a time.
    private var homeScore = 0
    private var awayScore = 0

    func incrementHome() {
        homeScore += 1
    }

    func incrementAway() {
        awayScore += 1
    }

    func currentScore() -> Score {
        Score(home: homeScore, away: awayScore)
    }
}

// Score is implicitly Sendable since it only contains value types (Int),
// so we don't need to mark it as such explicitly.
struct Score {
    let home: Int
    let away: Int
}

// You must use `await` when accessing the actor from outside its context.
let scoreBoard = ScoreBoard()

Task {
    await scoreBoard.incrementHome()
    await scoreBoard.incrementAway()
    let currentScore = await scoreBoard.currentScore()
    print("Current Score: Home \(currentScore.home) - Away \(currentScore.away)")
}
```

## References

- [The Swift Programming Language — Concurrency](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency/)
- [Swift Forums — Actors & Actor Isolation Discussion](https://forums.swift.org/t/concurrency-actors-actor-isolation/41613)
- [Swift by Sundell — Swift Actors](https://www.swiftbysundell.com/articles/swift-actors/)


