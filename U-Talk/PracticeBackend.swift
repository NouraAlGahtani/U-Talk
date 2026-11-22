import Foundation

/// Backend calls used by the practice screens. Same endpoints and baseURL as APIClient
/// in Conversation.swift (which is left unchanged), plus:
///  - any scenario name for /chat (not limited to PracticeMode), and
///  - a per-scenario Azure voice, speaking style and rate for /speak (needs the patched backend;
///    an unpatched backend ignores the extra fields and uses Andrew in his normal tone).
extension APIClient {
    /// The backend accepts at most 50 messages per request. Long (unlimited) conversations send the
    /// most recent ones; the scenario prompt keeps the story's key facts, so it stays consistent.
    static let maxMessagesPerRequest = 40

    func reply(scenarioMode: String, messages: [ChatMessage]) async throws -> String {
        var recent = Array(messages.suffix(Self.maxMessagesPerRequest))
        if recent.first?.role == "assistant", recent.count > 1, messages.count > recent.count {
            recent.removeFirst()   // start the trimmed history with a user turn
        }
        var request = URLRequest(url: Self.baseURL.appendingPathComponent("chat"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 180
        let body: [String: Any] = [
            "mode": scenarioMode,
            "messages": recent.map { ["role": $0.role, "content": $0.content] }
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(ConversationReply.self, from: data).reply
    }

    func voiceAudio(text: String, voice: String? = nil, style: String?, rate: String?) async throws -> Data {
        var request = URLRequest(url: Self.baseURL.appendingPathComponent("speak"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 180
        var body: [String: String] = ["text": text]
        if let voice { body["voice"] = voice }
        if let style { body["style"] = style }
        if let rate { body["rate"] = rate }
        request.httpBody = try JSONEncoder().encode(body)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return data
    }
}
