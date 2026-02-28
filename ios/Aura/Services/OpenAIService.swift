import Foundation

// MARK: - Request / Response Codable Types

private struct AzureChatMessage: Codable {
    let role: String
    let content: String
}

private struct AzureChatRequest: Codable {
    let messages: [AzureChatMessage]
    let response_format: ResponseFormat?
    let temperature: Double?

    struct ResponseFormat: Codable {
        let type: String
    }
}

private struct AzureChatResponse: Codable {
    let choices: [Choice]

    struct Choice: Codable {
        let message: Message

        struct Message: Codable {
            let content: String
        }
    }
}

// MARK: - Result Types

struct AIAnalysisResult: Codable {
    let entryType: String
    let calories: Int?
    let protein: Int?
    let carbs: Int?
    let fat: Int?
    let symptomSeverity: Int?
    let symptomName: String?
    let moodScore: Double?
    let aiSummary: String
    let aiInsight: String
    let aiSuggestion: String

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        entryType       = (try? c.decode(String.self, forKey: .entryType)) ?? "food"
        calories        = try? c.decode(Int.self, forKey: .calories)
        protein         = try? c.decode(Int.self, forKey: .protein)
        carbs           = try? c.decode(Int.self, forKey: .carbs)
        fat             = try? c.decode(Int.self, forKey: .fat)
        symptomSeverity = try? c.decode(Int.self, forKey: .symptomSeverity)
        symptomName     = try? c.decode(String.self, forKey: .symptomName)
        moodScore       = try? c.decode(Double.self, forKey: .moodScore)
        aiSummary       = (try? c.decode(String.self, forKey: .aiSummary)) ?? ""
        aiInsight       = (try? c.decode(String.self, forKey: .aiInsight)) ?? ""
        aiSuggestion    = (try? c.decode(String.self, forKey: .aiSuggestion)) ?? ""
    }

    private enum CodingKeys: String, CodingKey {
        case entryType, calories, protein, carbs, fat
        case symptomSeverity, symptomName, moodScore
        case aiSummary, aiInsight, aiSuggestion
    }
}

private struct InsightAPIResult: Codable {
    let title: String
    let description: String
    let confidenceScore: Double
    let category: String
}

private struct InsightsAPIResponse: Codable {
    let insights: [InsightAPIResult]
}

// MARK: - OpenAIService Actor (Azure OpenAI)

actor OpenAIService {
    static let shared = OpenAIService()

    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 120
        return URLSession(configuration: config)
    }()

    private init() {}

    // MARK: - System Prompts

    private let analysisSystemPrompt = """
    You are a clinical-grade health diary AI assistant backed by real medical databases (FDA FAERS, NLM MedlinePlus). Analyze the user's health diary entry and return a JSON object with the following exact schema. Be accurate, evidence-based, and helpful.

    If medical database context is provided below the entry, incorporate that evidence into your insight and suggestion — cite the source briefly (e.g. "per FDA data" or "per NIH guidelines").

    JSON Schema:
    {
      "entryType": "food|symptom|mood",
      "calories": null or integer (estimate for food entries),
      "protein": null or integer (grams, for food entries),
      "carbs": null or integer (grams, for food entries),
      "fat": null or integer (grams, for food entries),
      "symptomSeverity": null or integer 1-10 (for symptom entries),
      "symptomName": null or string (primary symptom name, for symptom entries),
      "moodScore": null or float -1.0 to 1.0 (for mood entries, negative=bad, positive=good),
      "aiSummary": "short summary 15 words or fewer",
      "aiInsight": "one health insight sentence — reference medical evidence when available",
      "aiSuggestion": "one actionable recommendation — reference clinical guidelines when available"
    }

    Rules:
    - entryType must be exactly "food", "symptom", or "mood"
    - Only fill nutrition fields for food entries
    - Only fill symptom fields for symptom entries
    - Only fill moodScore for mood entries
    - Keep aiSummary under 15 words
    - When medical database context is available, your insight MUST reference it
    - Return ONLY valid JSON, no markdown, no explanation
    """

    private let insightsSystemPrompt = """
    You are a clinical health pattern analyst backed by FDA and NIH medical databases. Given a list of health diary entries, identify 3 to 5 meaningful health patterns or insights. Where medical database context is provided, incorporate that evidence.

    Return a JSON object with this schema:
    {
      "insights": [
        {
          "title": "Short insight title",
          "description": "2-3 sentence description of the pattern. Reference medical evidence (FDA FAERS data, NIH guidelines) when available.",
          "confidenceScore": 0.0 to 1.0,
          "category": "nutrition|sleep|mood|symptom|pattern|warning|positive"
        }
      ]
    }

    Focus on:
    - Correlations between food and symptoms (reference FDA adverse event data when relevant)
    - Mood patterns related to diet or exercise
    - Recurring symptoms and potential triggers
    - Positive health behaviors to reinforce
    - Warning patterns that need clinical attention

    Return ONLY valid JSON, no markdown.
    """

    private let summarySystemPrompt = """
    You are a compassionate health coach backed by clinical medical databases (FDA FAERS, NLM MedlinePlus). Based on the health diary entries and any medical database context provided, write a 3-paragraph summary.

    Paragraph 1: Overall health patterns and notable observations
    Paragraph 2: Areas of concern with specific examples — reference FDA or NIH data when relevant
    Paragraph 3: Positive behaviors and personalized, evidence-based recommendations

    Write in second person ("you"), be encouraging but honest. Reference medical sources where applicable. Plain text only, no markdown.
    """

    private let soapSystemPrompt = """
    You are a clinical documentation assistant. Transform patient health diary entries into a structured SOAP note that a clinician can review during a patient visit. Use medical database context (FDA FAERS, NLM MedlinePlus) when provided.

    Return a JSON object with this exact schema:
    {
      "subjective": "Patient-reported complaints, symptoms, food intake, mood changes, and medication use over the reporting period. Organize chronologically. Use clinical language while preserving the patient's own words where relevant. Include onset, duration, and severity of symptoms.",
      "objective": "Measurable data extracted from diary entries: average daily caloric intake, macronutrient breakdown, symptom frequency and average severity scores, mood score trends (range -1.0 to +1.0), number of entries by type, any medication or substance use patterns. Present as structured data points.",
      "assessment": "Clinical pattern analysis: correlations between diet and symptoms, medication side effects cross-referenced with FDA FAERS data, mood trend analysis, recurring symptom patterns, risk factors identified. Cite FDA or NIH data where applicable.",
      "plan": "Evidence-based recommendations: dietary modifications, suggested follow-up with specialists, medication review suggestions (citing FDA adverse event data), lifestyle modifications, monitoring recommendations. Each recommendation should reference the clinical evidence supporting it.",
      "medicalSourcesUsed": ["list", "of", "medical", "databases", "referenced"]
    }

    Rules:
    - Write in third person clinical style ("Patient reports...", "Data shows...")
    - Be specific with dates, numbers, and frequencies
    - Reference FDA FAERS or NIH data when the medical database context supports it
    - Each section should be 3-6 sentences
    - Return ONLY valid JSON, no markdown
    """

    // MARK: - Public API

    /// Analyzes a diary entry, optionally enriched with medical database context.
    func analyzeEntry(text: String, medicalContext: MedicalContext? = nil) async throws -> AIAnalysisResult {
        var userContent = "Analyze this health diary entry: \(text)"

        if let ctx = medicalContext, !ctx.contextForAI.isEmpty {
            userContent += "\n\n--- Medical Database Context ---\n\(ctx.contextForAI)"
        }

        let messages: [AzureChatMessage] = [
            AzureChatMessage(role: "system", content: analysisSystemPrompt),
            AzureChatMessage(role: "user", content: userContent)
        ]

        let request = AzureChatRequest(
            messages: messages,
            response_format: AzureChatRequest.ResponseFormat(type: "json_object"),
            temperature: 0.3
        )

        let responseContent = try await performChatCompletion(request: request)
        print("[AzureAI] Raw analysis response: \(responseContent.prefix(500))")

        let cleaned = responseContent
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let data = cleaned.data(using: .utf8) else {
            throw AzureOpenAIError.invalidResponse("Could not convert response to data")
        }

        do {
            return try JSONDecoder().decode(AIAnalysisResult.self, from: data)
        } catch {
            print("[AzureAI] Decode error: \(error)")
            print("[AzureAI] Attempted to decode: \(cleaned.prefix(500))")
            throw AzureOpenAIError.decodingFailed("Failed to decode analysis result: \(error.localizedDescription)")
        }
    }

    func generateInsights(entries: [HealthEntry]) async throws -> [Insight] {
        guard !entries.isEmpty else { return [] }

        let diaryText = formatEntriesAsText(entries)

        let medicalContext = await MedicalKnowledgeService.shared.fetchMedicalContext(
            for: entries.suffix(10).map { $0.rawText }.joined(separator: ". ")
        )

        var userContent = "Health diary entries:\n\n\(diaryText)"
        if !medicalContext.contextForAI.isEmpty {
            userContent += "\n\n--- Medical Database Context ---\n\(medicalContext.contextForAI)"
        }

        let messages: [AzureChatMessage] = [
            AzureChatMessage(role: "system", content: insightsSystemPrompt),
            AzureChatMessage(role: "user", content: userContent)
        ]

        let request = AzureChatRequest(
            messages: messages,
            response_format: AzureChatRequest.ResponseFormat(type: "json_object"),
            temperature: 0.4
        )

        let responseContent = try await performChatCompletion(request: request)

        guard let data = responseContent.data(using: .utf8) else {
            throw AzureOpenAIError.invalidResponse("Could not convert response to data")
        }

        let apiResponse = try JSONDecoder().decode(InsightsAPIResponse.self, from: data)

        return apiResponse.insights.map { result in
            let category = InsightCategory(rawValue: result.category) ?? .pattern
            return Insight(
                title: result.title,
                description: result.description,
                confidenceScore: result.confidenceScore,
                category: category
            )
        }
    }

    func generateSOAPNote(entries: [HealthEntry]) async throws -> SOAPNote {
        guard !entries.isEmpty else {
            throw AzureOpenAIError.invalidResponse("No entries to generate SOAP note from")
        }

        let diaryText = formatEntriesAsText(entries)
        let sorted = entries.sorted { $0.date < $1.date }
        let periodStart = sorted.first?.date ?? Date()
        let periodEnd = sorted.last?.date ?? Date()

        let medicalContext = await MedicalKnowledgeService.shared.fetchMedicalContext(
            for: entries.suffix(10).map { $0.rawText }.joined(separator: ". ")
        )

        var userContent = """
        Generate a SOAP clinical note from these patient health diary entries.
        Reporting period: \(DateFormatter.localizedString(from: periodStart, dateStyle: .medium, timeStyle: .none)) to \(DateFormatter.localizedString(from: periodEnd, dateStyle: .medium, timeStyle: .none))
        Total entries: \(entries.count)
        Food entries: \(entries.filter { $0.entryType == .food }.count)
        Symptom entries: \(entries.filter { $0.entryType == .symptom }.count)
        Mood entries: \(entries.filter { $0.entryType == .mood }.count)

        --- Diary Entries ---
        \(diaryText)
        """

        if !medicalContext.contextForAI.isEmpty {
            userContent += "\n\n--- Medical Database Context ---\n\(medicalContext.contextForAI)"
        }

        let messages: [AzureChatMessage] = [
            AzureChatMessage(role: "system", content: soapSystemPrompt),
            AzureChatMessage(role: "user", content: userContent)
        ]

        let request = AzureChatRequest(
            messages: messages,
            response_format: AzureChatRequest.ResponseFormat(type: "json_object"),
            temperature: 0.3
        )

        let responseContent = try await performChatCompletion(request: request)

        let cleaned = responseContent
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let data = cleaned.data(using: .utf8) else {
            throw AzureOpenAIError.invalidResponse("Could not convert SOAP response to data")
        }

        struct SOAPAPIResponse: Codable {
            let subjective: String?
            let objective: String?
            let assessment: String?
            let plan: String?
            let medicalSourcesUsed: [String]?
        }

        let apiResponse = try JSONDecoder().decode(SOAPAPIResponse.self, from: data)

        return SOAPNote(
            periodStart: periodStart,
            periodEnd: periodEnd,
            subjective: apiResponse.subjective ?? "",
            objective: apiResponse.objective ?? "",
            assessment: apiResponse.assessment ?? "",
            plan: apiResponse.plan ?? "",
            medicalSourcesUsed: (apiResponse.medicalSourcesUsed ?? []) +
                medicalContext.references.map { $0.source }
        )
    }

    func generateHealthSummary(entries: [HealthEntry]) async throws -> String {
        guard !entries.isEmpty else { return "" }

        let diaryText = formatEntriesAsText(entries)

        let medicalContext = await MedicalKnowledgeService.shared.fetchMedicalContext(
            for: entries.suffix(10).map { $0.rawText }.joined(separator: ". ")
        )

        var userContent = "My health diary from the past two weeks:\n\n\(diaryText)"
        if !medicalContext.contextForAI.isEmpty {
            userContent += "\n\n--- Medical Database Context ---\n\(medicalContext.contextForAI)"
        }

        let messages: [AzureChatMessage] = [
            AzureChatMessage(role: "system", content: summarySystemPrompt),
            AzureChatMessage(role: "user", content: userContent)
        ]

        let request = AzureChatRequest(
            messages: messages,
            response_format: nil,
            temperature: 0.5
        )

        return try await performChatCompletion(request: request)
    }

    // MARK: - Azure OpenAI HTTP

    private func performChatCompletion(request: AzureChatRequest) async throws -> String {
        guard let url = URL(string: APIConfig.chatCompletionsURL) else {
            throw AzureOpenAIError.invalidResponse("Invalid Azure endpoint URL")
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue(APIConfig.azureAPIKey, forHTTPHeaderField: "api-key")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(request)

        let (data, response) = try await session.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AzureOpenAIError.invalidResponse("Not an HTTP response")
        }

        guard httpResponse.statusCode == 200 else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("[AzureAI] HTTP \(httpResponse.statusCode): \(errorBody.prefix(500))")
            throw AzureOpenAIError.httpError(statusCode: httpResponse.statusCode, body: errorBody)
        }

        let chatResponse = try JSONDecoder().decode(AzureChatResponse.self, from: data)

        guard let content = chatResponse.choices.first?.message.content else {
            throw AzureOpenAIError.invalidResponse("Empty choices in response")
        }

        return content
    }

    private func formatEntriesAsText(_ entries: [HealthEntry]) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short

        let sorted = entries.sorted { $0.date < $1.date }

        return sorted.map { entry in
            var lines: [String] = []
            lines.append("[\(formatter.string(from: entry.date))] [\(entry.entryType.displayName.uppercased())]")
            lines.append("Entry: \(entry.rawText)")

            if let cal = entry.calories { lines.append("Calories: \(cal) kcal") }
            if let pro = entry.protein { lines.append("Protein: \(pro)g") }
            if let carbs = entry.carbs { lines.append("Carbs: \(carbs)g") }
            if let fat = entry.fat { lines.append("Fat: \(fat)g") }
            if let name = entry.symptomName { lines.append("Symptom: \(name)") }
            if let sev = entry.symptomSeverity { lines.append("Severity: \(sev)/10") }
            if let mood = entry.moodScore { lines.append(String(format: "Mood Score: %.1f", mood)) }
            if !entry.aiSummary.isEmpty { lines.append("Summary: \(entry.aiSummary)") }

            return lines.joined(separator: "\n")
        }.joined(separator: "\n\n---\n\n")
    }
}

// MARK: - Error Types

enum AzureOpenAIError: LocalizedError {
    case invalidResponse(String)
    case httpError(statusCode: Int, body: String)
    case decodingFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse(let msg): return "Invalid response: \(msg)"
        case .httpError(let code, let body): return "HTTP \(code): \(body.prefix(200))"
        case .decodingFailed(let msg): return "Decoding failed: \(msg)"
        }
    }
}
