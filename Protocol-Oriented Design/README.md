# Protocol-Oriented Design for Dynamic Sections

I will explain my solution for handling dynamic sections using **protocol-based design** + **clean architecture** with **generic types**.

---

## Problem

All the sections come from the same response, but they are unrelated. 
This means that sections can belong to different providers, each with its own data structure.

---

## Solution

The idea is to create a framework where the providers can inject their sections.  
They will conform to the `Configurator` protocol to set their conditions, and they inject it into our framework.

---

## Provider Perspective

magine I am a sports company and I need to create my own section for this use case. How would I do that?

The first step is to create a Decodable model for the items, since I am expecting the following JSON:

```json
{
  "id": 321,
  "name": "⚽ Champions League",
  "items": [
    {
      "id": 322,
      "name": "Real Madrid",
      "score": 200
    },
    {
      "id": 333,
      "name": "Manchester City",
      "score": 250
    },
    {
      "id": 334,
      "name": "Bayern Munich",
      "score": 300
    }
  ]
}
```

My Codable will be something like:

```swift
struct ChampionsLeagueItem: Codable {
    let id: Int
    let name: String
    let score: Int
}
```

Now, as a provider, I don’t have access to the framework’s code, so I cannot manually add my section there.
The framework needs to provide a way for me to inject my section.

Using protocol-oriented design, I can conform to a protocol that lets me access my Codable model values and create the UI objects needed to display them on screen,
based on the specific logic my section requires.

If I need any additional information from my section, it will be available through this protocol, allowing me to set data such as the ID.

```swift
struct ChampionsLeagueConfigurator: SectionConfigurator {
    typealias Model = ChampionsLeagueItem
    typealias SectionModel = Section<ChampionsLeagueItem>
     
    let id: Int = 321
     
    func createUIModel(_ section: Section<ChampionsLeagueItem>) -> ExternalFrameworkSection {
        let items = section.items.map { item in
            let content = item.score < 200 ? "⚽ Underdog" : "🏆 Top Club"
            return ExternalFrameworkContent(content: "\(item.name) - \(content)")
        }
        return ExternalFrameworkSection(description: section.name, contents: items)
    }
}
```

---
