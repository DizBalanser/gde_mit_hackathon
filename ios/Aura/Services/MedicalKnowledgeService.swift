import Foundation

// MARK: - Medical Reference Model

struct MedicalReference: Codable, Identifiable, Equatable {
    var id = UUID()
    let source: String
    let title: String
    let detail: String
    let url: String?
    let category: MedicalReferenceCategory

    static func == (lhs: MedicalReference, rhs: MedicalReference) -> Bool {
        lhs.id == rhs.id
    }
}

enum MedicalReferenceCategory: String, Codable {
    case adverseEvent = "adverse_event"
    case drugInteraction = "drug_interaction"
    case healthTopic = "health_topic"
    case nutritionFact = "nutrition_fact"
    case symptomInfo = "symptom_info"

    var iconName: String {
        switch self {
        case .adverseEvent: return "exclamationmark.shield"
        case .drugInteraction: return "pills"
        case .healthTopic: return "cross.case"
        case .nutritionFact: return "leaf"
        case .symptomInfo: return "stethoscope"
        }
    }

    var displayName: String {
        switch self {
        case .adverseEvent: return "FDA Adverse Event"
        case .drugInteraction: return "Drug Interaction"
        case .healthTopic: return "Health Topic"
        case .nutritionFact: return "Nutrition"
        case .symptomInfo: return "Symptom Info"
        }
    }
}

struct MedicalContext {
    var references: [MedicalReference]
    var contextForAI: String

    static let empty = MedicalContext(references: [], contextForAI: "")
}

// MARK: - MedicalKnowledgeService

actor MedicalKnowledgeService {
    static let shared = MedicalKnowledgeService()

    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        config.timeoutIntervalForResource = 15
        return URLSession(configuration: config)
    }()

    private init() {}

    /// Fetches medical context from OpenFDA and NLM MedlinePlus for the given diary text.
    func fetchMedicalContext(for text: String) async -> MedicalContext {
        let keywords = extractMedicalKeywords(from: text)
        guard !keywords.isEmpty else { return .empty }

        async let fdaResults = queryOpenFDA(keywords: keywords, originalText: text)
        async let medlineResults = queryMedlinePlus(keywords: keywords)

        let fda = await fdaResults
        let medline = await medlineResults
        let allRefs = fda + medline

        guard !allRefs.isEmpty else { return .empty }

        let contextLines = allRefs.map { ref in
            "[\(ref.source)] \(ref.title): \(ref.detail)"
        }
        let contextString = contextLines.joined(separator: "\n")

        return MedicalContext(references: allRefs, contextForAI: contextString)
    }

    // MARK: - Keyword Extraction

    private func extractMedicalKeywords(from text: String) -> [String] {
        let lowered = text.lowercased()
        var keywords: [String] = []

        let symptomTerms = [
            "headache", "migraine", "nausea", "vomiting", "dizziness", "fatigue",
            "fever", "cough", "pain", "cramp", "bloating", "diarrhea", "constipation",
            "insomnia", "anxiety", "depression", "rash", "allergy", "swelling",
            "stomach", "chest pain", "shortness of breath", "palpitations", "joint pain",
            "back pain", "sore throat", "congestion", "heartburn", "acid reflux"
        ]

        let substanceTerms = [
            "caffeine", "coffee", "alcohol", "ibuprofen", "aspirin", "acetaminophen",
            "tylenol", "advil", "vitamin", "supplement", "melatonin", "antihistamine",
            "probiotic", "omega-3", "fish oil", "iron", "magnesium", "zinc"
        ]

        let foodHealthTerms = [
            "gluten", "lactose", "dairy", "sugar", "sodium", "cholesterol",
            "saturated fat", "trans fat", "fiber", "protein", "carbohydrate"
        ]

        for term in symptomTerms + substanceTerms + foodHealthTerms {
            if lowered.contains(term) {
                keywords.append(term)
            }
        }

        return Array(keywords.prefix(5))
    }

    // MARK: - OpenFDA API

    private func queryOpenFDA(keywords: [String], originalText: String) async -> [MedicalReference] {
        var references: [MedicalReference] = []

        let searchQuery = keywords.joined(separator: "+AND+")
        let urlString = "\(APIConfig.openFDABaseURL)/drug/event.json?search=patient.drug.openfda.generic_name:\(searchQuery)+OR+patient.reaction.reactionmeddrapt:\(searchQuery)&limit=3"

        guard let url = URL(string: urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? urlString) else {
            return references
        }

        do {
            let (data, response) = try await session.data(for: URLRequest(url: url))

            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                return references
            }

            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let results = json["results"] as? [[String: Any]] {
                for result in results.prefix(3) {
                    if let reactions = result["patient"] as? [String: Any],
                       let reactionList = reactions["reaction"] as? [[String: Any]] {
                        let reactionNames = reactionList
                            .compactMap { $0["reactionmeddrapt"] as? String }
                            .prefix(3)
                            .joined(separator: ", ")

                        let drugs = (reactions["drug"] as? [[String: Any]])?
                            .compactMap { $0["medicinalproduct"] as? String }
                            .prefix(2)
                            .joined(separator: ", ") ?? "Unknown"

                        if !reactionNames.isEmpty {
                            references.append(MedicalReference(
                                source: "FDA FAERS",
                                title: "Reported adverse events",
                                detail: "Reactions: \(reactionNames). Associated substances: \(drugs).",
                                url: "https://open.fda.gov/apis/drug/event/",
                                category: .adverseEvent
                            ))
                        }
                    }
                }
            }
        } catch {
            // Silent — medical enrichment is best-effort
        }

        // Also query food adverse events if food-related keywords present
        let foodKeywords = keywords.filter { ["caffeine", "gluten", "lactose", "dairy", "sugar", "sodium"].contains($0) }
        if !foodKeywords.isEmpty {
            await references.append(contentsOf: queryOpenFDAFood(keywords: foodKeywords))
        }

        return Array(references.prefix(3))
    }

    private func queryOpenFDAFood(keywords: [String]) async -> [MedicalReference] {
        let query = keywords.joined(separator: "+")
        let urlString = "\(APIConfig.openFDABaseURL)/food/event.json?search=reactions:\(query)&limit=2"

        guard let url = URL(string: urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? urlString) else {
            return []
        }

        do {
            let (data, response) = try await session.data(for: URLRequest(url: url))
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return [] }

            var results: [MedicalReference] = []

            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let records = json["results"] as? [[String: Any]] {
                for record in records.prefix(2) {
                    let reactions = (record["reactions"] as? [String])?.prefix(3).joined(separator: ", ") ?? ""
                    let products = (record["products"] as? [[String: Any]])?
                        .compactMap { $0["name_brand"] as? String }
                        .prefix(2)
                        .joined(separator: ", ") ?? ""

                    if !reactions.isEmpty {
                        results.append(MedicalReference(
                            source: "FDA CFSAN",
                            title: "Food adverse event report",
                            detail: "Reactions: \(reactions). Products: \(products.isEmpty ? "Not specified" : products).",
                            url: "https://open.fda.gov/apis/food/event/",
                            category: .adverseEvent
                        ))
                    }
                }
            }

            return results
        } catch {
            return []
        }
    }

    // MARK: - NLM MedlinePlus API

    private func queryMedlinePlus(keywords: [String]) async -> [MedicalReference] {
        let searchTerm = keywords.prefix(3).joined(separator: "+")
        let urlString = "\(APIConfig.medlinePlusSearchURL)?db=healthTopics&term=\(searchTerm)&retmax=3"

        guard let url = URL(string: urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? urlString) else {
            return []
        }

        do {
            let (data, response) = try await session.data(for: URLRequest(url: url))
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return [] }

            return parseMedlinePlusXML(data)
        } catch {
            return []
        }
    }

    /// Lightweight XML parsing for MedlinePlus results (avoids heavy XML parser dependency).
    private func parseMedlinePlusXML(_ data: Data) -> [MedicalReference] {
        guard let xmlString = String(data: data, encoding: .utf8) else { return [] }

        var references: [MedicalReference] = []

        let documents = xmlString.components(separatedBy: "<document")
        for doc in documents.dropFirst().prefix(3) {
            let title = extractXMLValue(from: doc, tag: "content", attribute: "name=\"title\"")
                ?? extractXMLValue(from: doc, tag: "content", attribute: "name=\"FullSummary\"")
                ?? "Health Topic"

            let snippet = extractXMLValue(from: doc, tag: "content", attribute: "name=\"snippet\"")
                ?? extractXMLValue(from: doc, tag: "content", attribute: "name=\"FullSummary\"")
                ?? ""

            let urlAttr = doc.components(separatedBy: "url=\"").dropFirst().first?
                .components(separatedBy: "\"").first

            let cleanSnippet = snippet
                .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .prefix(300)

            if !cleanSnippet.isEmpty {
                references.append(MedicalReference(
                    source: "NLM MedlinePlus",
                    title: title.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression),
                    detail: String(cleanSnippet),
                    url: urlAttr,
                    category: .healthTopic
                ))
            }
        }

        return references
    }

    private func extractXMLValue(from xml: String, tag: String, attribute: String) -> String? {
        let pattern = "<\(tag) [^>]*\(attribute)[^>]*>(.*?)</\(tag)>"
        guard let range = xml.range(of: pattern, options: .regularExpression) else { return nil }
        let match = String(xml[range])
        let content = match.components(separatedBy: ">").dropFirst().joined(separator: ">")
        return content.components(separatedBy: "</").first
    }

    // MARK: - Medication Side Effect Cross-Reference

    /// Scans recent entries for medications, then checks if any logged symptoms
    /// match known FDA adverse events for those medications.
    func checkMedicationSideEffects(entries: [HealthEntry]) async -> [MedicationAlert] {
        let medications = extractMedications(from: entries)
        guard !medications.isEmpty else { return [] }

        let symptoms = extractRecentSymptoms(from: entries)
        guard !symptoms.isEmpty else { return [] }

        var alerts: [MedicationAlert] = []

        for med in medications {
            let matchingSymptoms = await queryFDAAdverseEvents(medication: med.name, symptoms: symptoms)
            for match in matchingSymptoms {
                alerts.append(MedicationAlert(
                    medication: med.name,
                    symptom: match.symptom,
                    fdaReportCount: match.reportCount,
                    firstMentionedDate: med.date,
                    symptomDate: match.symptomDate
                ))
            }
        }

        return alerts
    }

    private struct MedicationMention {
        let name: String
        let date: Date
    }

    private func extractMedications(from entries: [HealthEntry]) -> [MedicationMention] {
        let medicationKeywords: [String: String] = [
            "ibuprofen": "Ibuprofen",
            "advil": "Ibuprofen",
            "motrin": "Ibuprofen",
            "aspirin": "Aspirin",
            "acetaminophen": "Acetaminophen",
            "tylenol": "Acetaminophen",
            "naproxen": "Naproxen",
            "aleve": "Naproxen",
            "omeprazole": "Omeprazole",
            "prilosec": "Omeprazole",
            "lisinopril": "Lisinopril",
            "metformin": "Metformin",
            "atorvastatin": "Atorvastatin",
            "lipitor": "Atorvastatin",
            "amlodipine": "Amlodipine",
            "metoprolol": "Metoprolol",
            "losartan": "Losartan",
            "gabapentin": "Gabapentin",
            "sertraline": "Sertraline",
            "zoloft": "Sertraline",
            "fluoxetine": "Fluoxetine",
            "prozac": "Fluoxetine",
            "prednisone": "Prednisone",
            "amoxicillin": "Amoxicillin",
            "azithromycin": "Azithromycin",
            "melatonin": "Melatonin",
            "antihistamine": "Antihistamine",
            "benadryl": "Diphenhydramine",
            "cetirizine": "Cetirizine",
            "zyrtec": "Cetirizine"
        ]

        var mentions: [MedicationMention] = []
        var seen = Set<String>()

        for entry in entries {
            let lowered = entry.rawText.lowercased()
            for (keyword, genericName) in medicationKeywords {
                if lowered.contains(keyword) && !seen.contains(genericName) {
                    mentions.append(MedicationMention(name: genericName, date: entry.date))
                    seen.insert(genericName)
                }
            }
        }

        return mentions
    }

    private struct SymptomMention {
        let name: String
        let date: Date
    }

    private func extractRecentSymptoms(from entries: [HealthEntry]) -> [SymptomMention] {
        entries
            .filter { $0.entryType == .symptom }
            .compactMap { entry in
                guard let name = entry.symptomName, !name.isEmpty else { return nil }
                return SymptomMention(name: name.lowercased(), date: entry.date)
            }
    }

    private struct FDASymptomMatch {
        let symptom: String
        let reportCount: Int
        let symptomDate: Date
    }

    private func queryFDAAdverseEvents(medication: String, symptoms: [SymptomMention]) async -> [FDASymptomMatch] {
        let urlString = "\(APIConfig.openFDABaseURL)/drug/event.json?search=patient.drug.openfda.generic_name:\"\(medication)\"&count=patient.reaction.reactionmeddrapt.exact&limit=50"

        guard let encoded = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: encoded) else {
            return []
        }

        do {
            let (data, response) = try await session.data(for: URLRequest(url: url))
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return [] }

            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let results = json["results"] as? [[String: Any]] else { return [] }

            let reactionCounts: [(String, Int)] = results.compactMap { result in
                guard let term = result["term"] as? String,
                      let count = result["count"] as? Int else { return nil }
                return (term.lowercased(), count)
            }

            var matches: [FDASymptomMatch] = []
            for symptom in symptoms {
                for (reaction, count) in reactionCounts {
                    if reaction.contains(symptom.name) || symptom.name.contains(reaction) {
                        matches.append(FDASymptomMatch(
                            symptom: symptom.name.capitalized,
                            reportCount: count,
                            symptomDate: symptom.date
                        ))
                        break
                    }
                }
            }

            return matches
        } catch {
            return []
        }
    }
}

// MARK: - Medication Alert Model

struct MedicationAlert: Identifiable, Equatable {
    let id = UUID()
    let medication: String
    let symptom: String
    let fdaReportCount: Int
    let firstMentionedDate: Date
    let symptomDate: Date

    var formattedCount: String {
        if fdaReportCount >= 1000 {
            return "\(fdaReportCount / 1000),\(String(format: "%03d", fdaReportCount % 1000))+"
        }
        return "\(fdaReportCount)+"
    }

    static func == (lhs: MedicationAlert, rhs: MedicationAlert) -> Bool {
        lhs.id == rhs.id
    }
}
