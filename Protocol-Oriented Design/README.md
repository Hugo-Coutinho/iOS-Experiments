# Protocol-Oriented Design for Dynamic Sections

I will explain my solution for handling dynamic sections using **protocol-based design** + **clean architecture** with **generic types**.

---

## Problem

All the sections come from the same response, but they are unrelated. 
This means that sections can belong to different providers, each with its own data structure.

---

## Solution
<img width="1333" height="509" alt="Screenshot 2025-10-03 at 21 53 36" src="https://github.com/user-attachments/assets/f5c7bb50-ac61-4d2d-afcc-eb70d4f0d1f1" />

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

And to inject into the framework would be by your UseCase like this:

```swift
let getSectionsUseCase = GetSectionsUseCase(remoteServer: server)
         
await getSectionsUseCase.add(configurators: [
  ChampionsLeagueConfigurator()
])
```

---

## UseCase Implementation

The domain layer is where the business logic happens. In the execution of GetSectionsUseCase, we fetch data from a remote data source, decode it, and transform it into the input type required by the UI framework.

Just a note: I am skipping the data layers (such as service and repository) in order to keep this example as simple as possible.
Since this use case contains shared mutable state, we need to declare it as an actor.

```swift
actor GetSectionsUseCase {
    let remoteServer: RemoteServer
    var sectionsModel: [Int: Codable] = [:]
    var configurators: [Int: any SectionConfigurator] = [:]
```

After all projects have added their configurators, we are ready to execute this use case. Since the items in every section are of a generic type, we first retrieve the remote data, manipulate it as a JSON object to access the items, and then decode them using the corresponding configurator.

Since the items are of a generic type, we need to set constraints to decode them according to the section’s item type.

```swift
private func decode<TConfigurator: SectionConfigurator>(
        data: Data,
        configurator: TConfigurator
    ) throws -> Codable {
        try JSONDecoder().decode(TConfigurator.SectionModel.self, from: data)
    }
```

After decoding, we can store the Codable object associated with each section ID, so that we can easily access it later when needed.

```swift
func execute() async throws {
        let data = try await remoteServer.fetchData()
        let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
         
        for section in jsonObject["sections"] as! [[String: Any]] {
            guard let sectionId = section["id"] as? Int else {
                throw SectionDecodingError.typeMismatch(
                    sectionId: -1,
                    expected: "Int",
                    actual: type(of: section["id"] as Any)
                )
            }
             
            guard let configurator = configurators[sectionId] else {
                throw SectionDecodingError.missingConfigurator(sectionId: sectionId)
            }
             
            do {
                let sectionData = try JSONSerialization.data(withJSONObject: section)
                let decodedSection = try decode(data: sectionData, configurator: configurator)
                sectionsModel[sectionId] = decodedSection
            } catch {
                throw SectionDecodingError.decodingFailed(sectionId: sectionId, underlying: error)
            }
        }
    }
```

---

## Protocol Definition

All sections share the same basic properties, so my Model represents those. However, the items within each section are different. Following a framework mindset, whoever uses my use case should be responsible for defining their own item model. For this reason, I declared the model as generic using an associated type.

The configurator protocol is responsible for holding all the data definitions provided by the user.

```swift
protocol SectionConfigurator {
    associatedtype Model: Codable
    associatedtype SectionModel: Section<Model>
     
    var id: Int { get }
     
    func createUIModel(_ section: SectionModel) -> ExternalFrameworkSection
}
```

And Section Model will look like:

```swift
class Section<TItem: Codable>: Codable {
    let id: Int
    let name: String
    let items: [TItem]
     
    init(id: Int, name: String, items: [TItem]) {
        self.id = id
        self.name = name
        self.items = items
    }
}
```
