//: # 🎯 Dynamic Sections Playground
//: Demo project showing protocol-oriented design, generics, actors, and error handling in Swift.
//: Domains: 🎵 Beatles, ⚽ Champions League, 🐺 Game of Thrones.

import Foundation

//: ## 1️⃣ Code Execution
//: Run this block to see the sections printed to console in a structured format.

Task {
    do {
        let server = RemoteServer()
        let externalFramework = ExternalFramework()
        let getSectionsUseCase = GetSectionsUseCase(remoteServer: server)
        
        await getSectionsUseCase.add(configurators: [
            BeatlesConfigurator(),
            ChampionsLeagueConfigurator(),
            GameOfThronesConfigurator()
        ])
        
        try await getSectionsUseCase.execute()
        await externalFramework.set(try getSectionsUseCase.get())
        
        await externalFramework.execute()
        
    } catch {
        print("❌ Error: \(error.localizedDescription)")
    }
}

//: ## 2️⃣ Sample JSON Data
//: This simulates the remote server response.

let jsonData: String = """
{
  "sections": [
    {
      "id": 123,
      "name": "🎵 The Beatles",
      "items": [
        { "id": 124, "name": "John Lennon" },
        { "id": 125, "name": "Paul McCartney" },
        { "id": 126, "name": "George Harrison" },
        { "id": 127, "name": "Ringo Starr" }
      ]
    },
    {
      "id": 321,
      "name": "⚽ Champions League",
      "items": [
        { "id": 322, "name": "Real Madrid", "score": 200 },
        { "id": 333, "name": "Manchester City", "score": 250 },
        { "id": 334, "name": "Bayern Munich", "score": 300 }
      ]
    },
    {
      "id": 231,
      "name": "🐺 Game of Thrones",
      "items": [
        { "id": 232, "name": "Jon Snow", "isAlive": true },
        { "id": 233, "name": "Daenerys Targaryen", "isAlive": false },
        { "id": 234, "name": "Arya Stark", "isAlive": true }
      ]
    }
  ]
}
"""

//: ## 3️⃣ External Framework Interfaces
/// Represents a section ready to be displayed in an external framework.
struct ExternalFrameworkSection {
    let description: String
    let contents: [ExternalFrameworkContent]
}

/// Represents a single piece of content inside a section.
struct ExternalFrameworkContent {
    let content: String
}

/// Simulates an external UI framework consuming and displaying sections.
actor ExternalFramework {
    private var sections: [ExternalFrameworkSection] = []
    
    /// Stores sections for later rendering
    func set(_ sections: [ExternalFrameworkSection]) async {
        self.sections = sections
    }
    
    /// Prints sections and their items to console in a structured format
    func execute() {
        sections.forEach { section in
            print("\n=== \(section.description) ===")
            section.contents.forEach { print("   → \($0.content)") }
            print(String(repeating: "-", count: 30))
        }
    }
}

//: ## 4️⃣ Remote Server Simulation
/// Simulates fetching JSON data from a remote server.
struct RemoteServer {
    func fetchData() async throws -> Data {
        Data(jsonData.utf8)
    }
}

//: ## 5️⃣ Business Logic - Use Case
/// Orchestrates fetching, decoding, and transforming sections.
actor GetSectionsUseCase {
    let remoteServer: RemoteServer
    var sectionsModel: [Int: Codable] = [:]
    var configurators: [Int: any SectionConfigurator] = [:]
    
    /// Error cases when decoding or mapping sections
    enum SectionDecodingError: Error, LocalizedError {
        case missingConfigurator(sectionId: Int)
        case typeMismatch(sectionId: Int, expected: String, actual: Any.Type)
        case decodingFailed(sectionId: Int, underlying: Error)
        
        var errorDescription: String? {
            switch self {
            case .missingConfigurator(let sectionId):
                return "No configurator found for section id: \(sectionId)"
            case .typeMismatch(let sectionId, let expected, let actual):
                return "Type mismatch in section \(sectionId). Expected \(expected), got \(actual)"
            case .decodingFailed(let sectionId, let underlying):
                return "Failed to decode section \(sectionId): \(underlying.localizedDescription)"
            }
        }
    }
    
    init(remoteServer: RemoteServer) {
        self.remoteServer = remoteServer
    }
    
    /// Adds new configurators to the use case.
    func add(configurators: [any SectionConfigurator]) async {
        configurators.forEach { self.configurators[$0.id] = $0 }
    }
    
    /// Builds all UI-ready sections using their configurators.
    func get() throws -> [ExternalFrameworkSection] {
        try configurators.map { _, configurator in
            try trySection(configurator: configurator)
        }
    }
    
    /// Fetches data, decodes sections, and stores them for later transformation.
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
    
    /// Tries to build an external section using a configurator and stored model
    private func trySection<TConfigurator: SectionConfigurator>(
        configurator: TConfigurator
    ) throws -> ExternalFrameworkSection {
        guard let sectionModel = sectionsModel[configurator.id] as? TConfigurator.SectionModel else {
            throw SectionDecodingError.typeMismatch(
                sectionId: configurator.id,
                expected: String(describing: TConfigurator.SectionModel.self),
                actual: type(of: sectionsModel[configurator.id] as Any)
            )
        }
        
        return configurator.createUIModel(sectionModel)
    }

    /// Decodes a section JSON into a strongly typed model using its configurator
    private func decode<TConfigurator: SectionConfigurator>(
        data: Data,
        configurator: TConfigurator
    ) throws -> Codable {
        try JSONDecoder().decode(TConfigurator.SectionModel.self, from: data)
    }
}

//: ## 6️⃣ Models & Configurators

// MARK: 🎵 Beatles
struct BeatlesConfigurator: SectionConfigurator {
    typealias Model = BeatleItem
    typealias SectionModel = Section<BeatleItem>
    
    let id: Int = 123
    
    func createUIModel(_ section: Section<BeatleItem>) -> ExternalFrameworkSection {
        let items = section.items.map { ExternalFrameworkContent(content: $0.name) }
        return ExternalFrameworkSection(description: section.name, contents: items)
    }
}

struct BeatleItem: Codable {
    let id: Int
    let name: String
}

// MARK: ⚽ Champions League
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

struct ChampionsLeagueItem: Codable {
    let id: Int
    let name: String
    let score: Int
}

// MARK: 🐺 Game of Thrones
struct GameOfThronesConfigurator: SectionConfigurator {
    typealias Model = GameOfThronesItem
    typealias SectionModel = Section<GameOfThronesItem>
    
    let id: Int = 231
    
    func createUIModel(_ section: Section<GameOfThronesItem>) -> ExternalFrameworkSection {
        let items = section.items.map { item in
            let status = item.isAlive ? "🟢 Alive" : "⚰️ Dead"
            return ExternalFrameworkContent(content: "\(item.name) - \(status)")
        }
        return ExternalFrameworkSection(description: section.name, contents: items)
    }
}

struct GameOfThronesItem: Codable {
    let id: Int
    let name: String
    let isAlive: Bool
}

//: ## SectionConfigurator Protocol
/// Defines a generic interface to configure a section for the external framework.
protocol SectionConfigurator {
    associatedtype Model: Codable
    associatedtype SectionModel: Section<Model>
    
    var id: Int { get }
    
    /// Transforms a strongly typed section model into an ExternalFrameworkSection for rendering
    func createUIModel(_ section: SectionModel) -> ExternalFrameworkSection
}

//: ## Section Model
/// Generic section containing a list of items of type `TItem`.
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


