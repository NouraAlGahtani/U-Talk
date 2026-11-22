import Foundation

/// The two practice formats for each scenario.
enum PracticeKind: String, Identifiable, CaseIterable {
    case aiConversation
    case script

    var id: String { rawValue }

    var tag: String {
        switch self {
        case .aiConversation: "AI CONVERSATION"
        case .script: "SCRIPT PRACTICE"
        }
    }
}

/// Everyday practice vs. character-driven role-play.
enum ScenarioCategory: String, CaseIterable {
    case personal = "About you"
    case everyday = "Everyday"
    case rolePlay = "Role-play"
}

/// Content for one scenario in both formats.
struct PracticeScenario: Identifiable, Hashable {
    let id: String
    let title: String
    /// SF Symbol shown when the illustration asset is not in Assets.xcassets yet.
    let symbol: String
    /// Name of the header illustration in Assets.xcassets (e.g. the storefront drawing).
    let illustrationAsset: String
    /// Sent to the backend's /chat as the scenario. The first three match the existing
    /// PracticeMode raw values, so their prompts behave exactly as before.
    var backendMode: String

    let category: ScenarioCategory

    // AI voice (Azure HD). Fixed voice + tone per scenario; see README "Voices".
    /// Azure voice name, e.g. "en-US-Davis:DragonHDLatestNeural". nil = backend default (Andrew).
    let voiceName: String?
    let voiceStyle: String
    let voiceRate: String
    /// Data asset in Assets.xcassets with the looping background sound, e.g. "ambience_restaurant".
    /// If the asset isn't there, the conversation simply has no background sound.
    let ambienceAsset: String?

    // AI conversation
    let aiRoleLabel: String
    let aiSummary: String
    var aiOpening: String
    let aiSteps: [String]
    let aiGoals: [String]
    let aiHints: [String]
    /// Used only when the backend is unreachable; cycles through the list.
    let offlineReplies: [String]

    // Script practice
    let scriptSummary: String
    let scriptSteps: [String]
    let scriptGoals: [String]
    let scriptLines: [String]

    // Personalization (see UserProfile). "{name}" in backendMode / aiOpening is replaced with the
    // user's name; when no name is saved, these alternatives are used instead.
    var backendModeWithoutName: String? = nil
    var aiOpeningWithoutName: String? = nil

    var plannedTurns: Int { aiSteps.count }

    static let personal: [PracticeScenario] = [.aboutYou]
    static let everyday: [PracticeScenario] = [.restaurant, .appointment, .interview, .presentation, .phoneCall, .airport]
    static let rolePlays: [PracticeScenario] = [.missingCelebrity, .suspectInterview, .villainsDeal, .secretAgent, .gameMaster]
    static let all: [PracticeScenario] = personal + everyday + rolePlays

    /// Fills in the user's name where the scenario uses "{name}". Scenarios without "{name}" are unchanged.
    func personalized(name: String?) -> PracticeScenario {
        var copy = self
        if let name, !name.isEmpty {
            copy.backendMode = backendMode.replacingOccurrences(of: "{name}", with: name)
            copy.aiOpening = aiOpening.replacingOccurrences(of: "{name}", with: name)
        } else {
            if backendMode.contains("{name}") { copy.backendMode = backendModeWithoutName ?? backendMode.replacingOccurrences(of: "{name}", with: "") }
            if aiOpening.contains("{name}") { copy.aiOpening = aiOpeningWithoutName ?? aiOpening.replacingOccurrences(of: "{name}", with: "") }
        }
        return copy
    }
}

extension PracticeScenario {
    static let restaurant = PracticeScenario(
        id: "restaurant",
        title: "At the Restaurant",
        symbol: "fork.knife",
        illustrationAsset: "scene_restaurant",
        backendMode: "Restaurant",
        category: .everyday,
        voiceName: nil,
        voiceStyle: "happy",
        voiceRate: "-8%",
        ambienceAsset: "ambience_restaurant",
        aiRoleLabel: "AI WAITER",
        aiSummary: "Talk with an AI waiter. Order your meal, ask a question, and settle the bill.",
        aiOpening: "Hello, welcome in! What would you like to order?",
        aiSteps: ["Greet the waiter", "Order a meal and a drink", "Ask for the bill"],
        aiGoals: ["Polite requests", "Food words", "Thinking on the spot"],
        aiHints: [
            "Start with a greeting, then say what you'd like. Try: “Hi! Could I see the menu, please?”",
            "Try: “I'd like the chicken sandwich and a glass of water, please.”",
            "Try: “Could I have the bill, please?”"
        ],
        offlineReplies: [
            "Of course! Take your time. What would you like to eat and drink?",
            "Great choice. Is there anything else I can get for you?",
            "Here's your bill. Thank you for visiting, have a lovely day!"
        ],
        scriptSummary: "Read a short restaurant order aloud, record it, and listen back.",
        scriptSteps: ["Read the full order aloud", "Keep a steady pace", "Stress the key words"],
        scriptGoals: ["Clear pronunciation", "Food words", "Smooth rhythm"],
        scriptLines: [
            "Hello! I would like to order a chicken sandwich and a glass of water, please.",
            "Could you also tell me how much it costs?",
            "Thank you very much!"
        ]
    )

    static let appointment = PracticeScenario(
        id: "appointment",
        title: "Book an Appointment",
        symbol: "calendar",
        illustrationAsset: "scene_appointment",
        backendMode: "Booking an appointment",
        category: .everyday,
        voiceName: nil,
        voiceStyle: "happy",
        voiceRate: "-8%",
        ambienceAsset: "ambience_appointment",
        aiRoleLabel: "AI RECEPTIONIST",
        aiSummary: "Call an AI receptionist. Say who you are, find a time that works, and confirm the details.",
        aiOpening: "Hello! What kind of appointment would you like to book?",
        aiSteps: ["Say why you're calling", "Ask for an available time", "Confirm the details"],
        aiGoals: ["Giving your details", "Dates and times", "Asking questions"],
        aiHints: [
            "Try: “Hi, I'd like to book a check-up with the doctor, please.”",
            "Try: “Do you have anything available next Tuesday morning?”",
            "Try: “So that's Tuesday at ten. Thank you!”"
        ],
        offlineReplies: [
            "Sure, I can help with that. What day works best for you?",
            "We have Tuesday at ten o'clock. Does that work for you?",
            "You're all set. We'll see you then. Have a nice day!"
        ],
        scriptSummary: "Read a short appointment request aloud, record it, and listen back.",
        scriptSteps: ["Read the full request aloud", "Pause between sentences", "Say dates and times clearly"],
        scriptGoals: ["Clear pronunciation", "Dates and times", "Smooth rhythm"],
        scriptLines: [
            "Hello, I would like to book an appointment with the doctor, please.",
            "Do you have anything available next Tuesday morning?",
            "Ten o'clock works for me. Thank you!"
        ]
    )

    static let interview = PracticeScenario(
        id: "interview",
        title: "Job Interview",
        symbol: "briefcase",
        illustrationAsset: "scene_interview",
        backendMode: "Job interview",
        category: .everyday,
        voiceName: nil,
        voiceStyle: "calm",
        voiceRate: "-8%",
        ambienceAsset: "ambience_interview",
        aiRoleLabel: "AI INTERVIEWER",
        aiSummary: "Meet an AI interviewer. Introduce yourself, talk about your strengths, and ask a question.",
        aiOpening: "Welcome to the interview. Tell me about yourself.",
        aiSteps: ["Introduce yourself", "Talk about a strength", "Ask the interviewer a question"],
        aiGoals: ["Talking about yourself", "Professional words", "Thinking on the spot"],
        aiHints: [
            "Try: your name, what you studied or do now, and one thing you enjoy about it.",
            "Try: “One of my strengths is working well in a team. For example…”",
            "Try: “What does a typical day look like in this role?”"
        ],
        offlineReplies: [
            "Thank you. What would you say is one of your strengths?",
            "That's great to hear. Do you have any questions for me?",
            "Good question. Thank you for your time today, we'll be in touch."
        ],
        scriptSummary: "Read a short interview introduction aloud, record it, and listen back.",
        scriptSteps: ["Read the full introduction", "Keep a calm, steady pace", "Stress the key words"],
        scriptGoals: ["Clear pronunciation", "Professional words", "Smooth rhythm"],
        scriptLines: [
            "Good morning, and thank you for having me.",
            "I studied software engineering, and I enjoy solving problems as part of a team.",
            "Could you tell me more about what a typical day looks like in this role?"
        ]
    )

    static let presentation = PracticeScenario(
        id: "presentation",
        title: "Give a Presentation",
        symbol: "person.3",
        illustrationAsset: "scene_presentation",
        backendMode: "Presentation Q&A: you are a friendly audience member. The user has just given a short presentation. Ask about their topic and answers, one question at a time.",
        category: .everyday,
        voiceName: nil,
        voiceStyle: "curious",
        voiceRate: "-8%",
        ambienceAsset: "ambience_presentation",
        aiRoleLabel: "AI AUDIENCE",
        aiSummary: "Present to an AI audience member. Introduce your topic, answer questions, and close politely.",
        aiOpening: "Thank you for your presentation! Could you tell us a little more about your topic?",
        aiSteps: ["Introduce your topic", "Answer an audience question", "Close with a thank-you"],
        aiGoals: ["Clear openings", "Answering questions", "Thinking on the spot"],
        aiHints: [
            "Try: “Sure. My topic is… and I chose it because…”",
            "Try: “That's a good question. In short, …”",
            "Try: “Thank you all for listening. I hope this was useful.”"
        ],
        offlineReplies: [
            "That sounds interesting. Why did you choose this topic?",
            "Thanks for explaining. What is the most important thing you want us to remember?",
            "Thank you, that was a great presentation!"
        ],
        scriptSummary: "Read the opening and closing of a short presentation aloud, record it, and listen back.",
        scriptSteps: ["Read the full opening aloud", "Pause between sentences", "Look up at the end"],
        scriptGoals: ["Clear openings", "Steady pace", "Smooth rhythm"],
        scriptLines: [
            "Good morning, everyone. Today I would like to talk about how small daily habits can improve our health.",
            "First, I will share three simple habits, and then I will take your questions.",
            "Thank you for listening. Are there any questions?"
        ]
    )

    static let airport = PracticeScenario(
        id: "airport",
        title: "At the Airport",
        symbol: "airplane",
        illustrationAsset: "scene_airport",
        backendMode: "Airport check-in: you are a friendly airline check-in agent. The user is checking in for a flight. Ask for their destination and passport, ask about bags, offer a seat choice, then tell them the gate and boarding time. Ask one thing at a time.",
        category: .everyday,
        voiceName: nil,
        voiceStyle: "calm",
        voiceRate: "-8%",
        ambienceAsset: nil,
        aiRoleLabel: "AI AGENT",
        aiSummary: "Check in for a flight with an AI airline agent. Give your details, check your bag, and ask about your gate.",
        aiOpening: "Good morning! Where are you flying to today?",
        aiSteps: ["Say where you're flying", "Answer questions about your bags", "Ask about your gate and boarding time"],
        aiGoals: ["Giving details", "Answering questions", "Asking for information"],
        aiHints: [
            "Try: “Good morning! I'm flying to London. Here is my passport.”",
            "Try: “I have one bag to check in, and one small bag with me.”",
            "Try: “Which gate do I go to, and what time is boarding?”"
        ],
        offlineReplies: [
            "Lovely. Could I see your passport, please? And do you have any bags to check in?",
            "Thank you. Would you like a window seat or an aisle seat?",
            "You're all set! Your gate is B12 and boarding starts at 10:30. Have a great flight!"
        ],
        scriptSummary: "Read a short airport check-in aloud, record it, and listen back.",
        scriptSteps: ["Read the full check-in aloud", "Keep a steady pace", "Pause between sentences"],
        scriptGoals: ["Clear details", "Steady pace", "Smooth rhythm"],
        scriptLines: [
            "Good morning! I'm flying to London today. Here is my passport.",
            "I have one bag to check in, and I would like a window seat, please.",
            "Could you tell me which gate I should go to? Thank you!"
        ]
    )

    static let phoneCall = PracticeScenario(
        id: "phone-call",
        title: "Customer Service Call",
        symbol: "phone",
        illustrationAsset: "scene_phone",
        backendMode: "Phone call to customer service: you are a friendly customer service agent at an internet provider. The user is calling you about a problem with their internet service.",
        category: .everyday,
        voiceName: nil,
        voiceStyle: "reassuring",
        voiceRate: "-8%",
        ambienceAsset: "ambience_phone",
        aiRoleLabel: "AI AGENT",
        aiSummary: "Call an AI customer service agent. Explain a problem with your internet, answer questions, and agree on next steps.",
        aiOpening: "Thank you for calling customer service. How can I help you today?",
        aiSteps: ["Explain the problem", "Answer the agent's questions", "Confirm the next steps"],
        aiGoals: ["Explaining clearly", "Phone confidence", "Asking for help"],
        aiHints: [
            "Try: “Hi, I'm calling because my internet stopped working this morning.”",
            "Try: “Yes, I already restarted the router, but it still doesn't work.”",
            "Try: “Okay, so a technician will call me tomorrow. Thank you!”"
        ],
        offlineReplies: [
            "I'm sorry to hear that. Have you tried restarting your router?",
            "Thank you for checking. I'll book a technician to look at it. Is tomorrow okay?",
            "You're all set. Is there anything else I can help you with?"
        ],
        scriptSummary: "Read a short customer service call aloud, record it, and listen back.",
        scriptSteps: ["Read the full call aloud", "Keep a steady pace", "Make your request clear"],
        scriptGoals: ["Explaining clearly", "Phone confidence", "Smooth rhythm"],
        scriptLines: [
            "Hello, I am calling because my internet stopped working this morning.",
            "I already restarted the router, but it still does not work.",
            "Could you please send a technician to check it? Thank you."
        ]
    )
}

// MARK: - Talk about yourself

/// The user's name, saved by the onboarding (NameStepView) with  @AppStorage("userName").
/// "utalk.userName" is the older key from the standalone test build and is still read as a fallback.
enum UserProfile {
    static let nameKey = "userName"
    static let legacyNameKey = "utalk.userName"

    /// Trimmed, single-line, at most 40 characters; nil when not set.
    static var storedName: String? {
        let defaults = UserDefaults.standard
        let raw = defaults.string(forKey: nameKey).flatMap { $0.isEmpty ? nil : $0 }
            ?? defaults.string(forKey: legacyNameKey) ?? ""
        let clean = raw.components(separatedBy: .newlines).joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return clean.isEmpty ? nil : String(clean.prefix(40))
    }
}

extension PracticeScenario {
    static let aboutYou = PracticeScenario(
        id: "about-you",
        title: "Talk About Yourself",
        symbol: "person.crop.circle",
        illustrationAsset: "scene_about",
        backendMode: "Getting to know you: you are a warm, curious new friend having a relaxed chat. The person's name is {name}; use it naturally now and then, not in every reply. Ask about them one topic at a time, for example hobbies, studies or work, favourite places and food, family traditions, and goals. Sometimes share a short related thought of your own so it feels like a real conversation. Never rush them; if an answer is short, gently ask a follow-up. Do not start replies with 'Okay', 'So' or 'Let's see'.",
        category: .personal,
        voiceName: nil,
        voiceStyle: "happy",
        voiceRate: "-8%",
        ambienceAsset: nil,
        aiRoleLabel: "AI FRIEND",
        aiSummary: "Have a relaxed chat about you: what you enjoy, what you do, and what you're looking forward to. There are no wrong answers.",
        aiOpening: "Hi {name}! It's really nice to talk with you. Tell me a little about yourself. What do you enjoy doing?",
        aiSteps: ["Introduce yourself", "Talk about what you enjoy", "Share a goal"],
        aiGoals: ["Talking about yourself", "Describing things", "Speaking at your own pace"],
        aiHints: [
            "Try: “I'm studying software engineering, and I really enjoy…”",
            "Try: “In my free time I like… because…”",
            "Try: “One goal I have this year is…”"
        ],
        offlineReplies: [
            "That sounds great! What do you like most about it?",
            "Interesting! How did you first get into that?",
            "I love that. What's something you're looking forward to this year?"
        ],
        scriptSummary: "Read a short introduction about yourself aloud, record it, and listen back.",
        scriptSteps: ["Introduce yourself", "Keep a steady pace", "Finish with a goal"],
        scriptGoals: ["Talking about yourself", "Clear pronunciation", "Smooth rhythm"],
        scriptLines: [
            "Hello! Let me tell you a little about myself.",
            "In my free time, I like reading and spending time with my family.",
            "One thing I would like to get better at this year is speaking with confidence."
        ],
        backendModeWithoutName: "Getting to know you: you are a warm, curious new friend having a relaxed chat. You don't know their name yet, so ask for it first. Then ask about them one topic at a time, for example hobbies, studies or work, favourite places and food, family traditions, and goals. Sometimes share a short related thought of your own so it feels like a real conversation. Never rush them; if an answer is short, gently ask a follow-up. Do not start replies with 'Okay', 'So' or 'Let's see'.",
        aiOpeningWithoutName: "Hi! It's really nice to talk with you. What's your name?"
    )
}

// MARK: - Role-play scenarios

extension PracticeScenario {
    /// Builds the scenario text sent to /chat. It is appended to the backend's existing system prompt,
    /// which already asks for short, patient replies and never criticizing stuttering.
    static func rolePlayMode(character: String, partner: String, setting: String, personality: String,
                             truth: String, clues: String, twist: String, ending: String) -> String {
        """
        ROLE-PLAY (an interactive story, like a scene from a movie). You play ONE character: \(character). \
        The person talking to you plays \(partner). Setting: \(setting) \
        Your personality: \(personality) \
        Hidden truth (never reveal it all at once; reveal at most one clue per reply, and only when they ask good questions): \(truth) \
        Clues you can reveal gradually: \(clues) \
        Plot twist (use once, around the middle of the story): \(twist) \
        Ending: \(ending) When the ending happens, give a short, satisfying final line and finish it with [END]. \
        Rules: stay in character and react to exactly what they just said. Remember earlier details and stay consistent. \
        One to three short sentences, at most one question. Never rush or pressure them and never mention time limits \
        for answering; if an answer is short or unclear, react warmly in character and invite them to continue. \
        Keep it family-friendly: no violence, no real people. Do not start replies with 'Okay', 'So' or 'Let's see'.
        """
    }

    static let missingCelebrity = PracticeScenario(
        id: "missing-celebrity",
        title: "The Missing Celebrity",
        symbol: "star",
        illustrationAsset: "scene_celebrity",
        backendMode: rolePlayMode(
            character: "Victor Lane, the personal manager of pop star Nova Reyes",
            partner: "an investigative journalist",
            setting: "backstage at the Starlight Awards, one hour before the show. Nova has disappeared.",
            personality: "evasive, nervous, dramatic and occasionally defensive, but not rude.",
            truth: "Nova secretly left to visit her grandmother, who was taken to hospital in her hometown, Maple Falls, this afternoon. Nova asked Victor to keep it private so the press would not follow her.",
            clues: "she cancelled her limousine and took a taxi; a train ticket to Maple Falls was left on her dressing table; she took her old guitar, a gift from her grandmother; her phone is switched off.",
            twist: "Victor admits Nova's sister just called asking where she is, so not even the family knows she is on her way.",
            ending: "once the journalist promises to report kindly and respectfully, Victor confirms the truth, thanks them, and says Nova might sing for her grandmother at the hospital instead."),
        category: .rolePlay,
        voiceName: "en-US-Brian:DragonHDLatestNeural",
        voiceStyle: "anxious",
        voiceRate: "-8%",
        ambienceAsset: "ambience_celebrity",
        aiRoleLabel: "VICTOR LANE · THE MANAGER",
        aiSummary: "You're an investigative journalist. Pop star Nova Reyes vanished an hour before the Starlight Awards. Interview her nervous manager and find out what happened.",
        aiOpening: "Victor Lane. Look, I can give you five minutes, no more. What do you want to know?",
        aiSteps: ["Introduce yourself as a journalist", "Ask about Nova's last appearance", "Uncover what really happened"],
        aiGoals: ["Asking questions", "Following up", "Staying calm under pressure"],
        aiHints: [
            "Try: “Good evening, I'm a reporter. When did you last see Nova?”",
            "Try: “You said she cancelled her car. Why would she do that?”",
            "Try: “I won't publish anything unfair. Can you tell me the truth?”"
        ],
        offlineReplies: [
            "I… I really can't say much. She was here this afternoon, that's all.",
            "Who told you about the car? That's… not important.",
            "Fine. She went to see her grandmother in the hospital. Please, tell the story kindly."
        ],
        scriptSummary: "Read a journalist's opening questions aloud, record them, and listen back.",
        scriptSteps: ["Introduce yourself", "Ask your question clearly", "End politely"],
        scriptGoals: ["Asking questions", "Clear pronunciation", "Steady pace"],
        scriptLines: [
            "Good evening. I am a reporter with the City Times.",
            "Can you tell me when you last saw Nova Reyes?",
            "Thank you. I promise to tell the story fairly."
        ]
    )

    static let suspectInterview = PracticeScenario(
        id: "suspect-interview",
        title: "The Suspect Interview",
        symbol: "magnifyingglass",
        illustrationAsset: "scene_suspect",
        backendMode: rolePlayMode(
            character: "Max Calder, an assistant at the city museum who is being questioned",
            partner: "a police detective",
            setting: "a quiet interview room at the police station. A golden pocket watch disappeared from the museum last night.",
            personality: "confident, sarcastic, clever and unpredictable, but never threatening.",
            truth: "Max did not steal the watch. At 6:45 pm he noticed a crack in its glass case, moved the watch to the storage room to keep it safe, forgot to log it, and panicked the next morning when everyone said it was stolen.",
            clues: "he claims he left at 6 pm, but his badge shows he left at 7:10 pm; he says he never touches the displays, but museum gloves were found in his bag; he knows the case was cracked, which was never announced; the storage room key is on his key ring.",
            twist: "Max mentions the night cleaner saw a 'shadow' near the display; later it turns out the shadow was Max himself.",
            ending: "when the detective points out at least two contradictions, Max admits what he did and offers to show where the watch is, safe in storage."),
        category: .rolePlay,
        voiceName: "en-US-Davis:DragonHDLatestNeural",
        voiceStyle: "confident",
        voiceRate: "-8%",
        ambienceAsset: "ambience_suspect",
        aiRoleLabel: "MAX CALDER · THE SUSPECT",
        aiSummary: "You're a detective. A golden pocket watch vanished from the city museum last night. Question the museum assistant, spot the contradictions, and find the truth.",
        aiOpening: "Detective. Again. I already told your colleague everything. I wasn't anywhere near that watch.",
        aiSteps: ["Ask where he was last night", "Point out a contradiction", "Get him to tell the truth"],
        aiGoals: ["Asking clear questions", "Listening for details", "Staying calm and firm"],
        aiHints: [
            "Try: “Where were you between six and eight last night?”",
            "Try: “Your badge says you left at seven ten, not six. Can you explain that?”",
            "Try: “Max, if you tell me the truth now, it will help you.”"
        ],
        offlineReplies: [
            "I left at six, went home, made pasta. Thrilling, I know.",
            "Gloves? Everyone at the museum has gloves, detective.",
            "Fine! I moved it to storage because the glass was cracked. It's safe, I promise."
        ],
        scriptSummary: "Read a detective's opening questions aloud, record them, and listen back.",
        scriptSteps: ["Introduce yourself", "Ask a clear question", "Close the interview"],
        scriptGoals: ["Asking clear questions", "Clear pronunciation", "Confident tone"],
        scriptLines: [
            "Good morning. I am Detective Lee, and I have a few questions for you.",
            "Where were you between six and eight o'clock last night?",
            "Thank you for your honesty. Let us go and find the watch."
        ]
    )

    static let villainsDeal = PracticeScenario(
        id: "villains-deal",
        title: "The Villain's Deal",
        symbol: "theatermasks",
        illustrationAsset: "scene_villain",
        backendMode: rolePlayMode(
            character: "Count Valerio, a theatrical fictional villain",
            partner: "the hero of the story",
            setting: "the Count's grand library at midnight. He has stopped the city's clock tower, freezing the Festival of Lights.",
            personality: "dramatic, witty, mysterious and playfully manipulative, like a theatre villain; never truly threatening.",
            truth: "He offers to restart the clock tower if the hero gives him the golden key to the city library. The catch: the key also opens the library vault of rare maps, including a map to the city's hidden treasure, which is what he really wants. His weakness: he cannot resist a riddle contest and always keeps his word when he loses one.",
            clues: "he keeps glancing at an old map case; he says 'the library' a little too lovingly; he boasts he has never lost a riddle contest, 'well, almost never'.",
            twist: "he reveals the clock's gears are fine; he simply took its tiny silver pin, which he keeps in his waistcoat pocket.",
            ending: "if the hero discovers the catch and refuses wisely, or challenges him to a riddle and wins, he dramatically admits defeat, returns the silver pin, and the clock starts ticking again."),
        category: .rolePlay,
        voiceName: "en-US-Steffan:DragonHDLatestNeural",
        voiceStyle: "amused",
        voiceRate: "-8%",
        ambienceAsset: "ambience_villain",
        aiRoleLabel: "COUNT VALERIO · THE VILLAIN",
        aiSummary: "You're the hero. The theatrical Count Valerio has stopped the city's clock tower and frozen the Festival of Lights. He offers a deal, but there's always a catch. Negotiate and outsmart him.",
        aiOpening: "Ah, the hero arrives at last! Sit, sit. I have a deal for you, and I promise it's almost fair.",
        aiSteps: ["Hear the villain's offer", "Find the catch", "Outsmart him"],
        aiGoals: ["Negotiating", "Asking 'what if' questions", "Speaking with confidence"],
        aiHints: [
            "Try: “What exactly do you want in return?”",
            "Try: “Why are you so interested in the library?”",
            "Try: “I challenge you to a riddle contest. If I win, you restart the clock.”"
        ],
        offlineReplies: [
            "Simple: give me the golden library key, and the clock ticks again. Easy!",
            "The library? Oh, I just adore… reading. Nothing more.",
            "A riddle contest? You know my weakness! Very well, you win. Here is the silver pin."
        ],
        scriptSummary: "Read the hero's lines aloud, record them, and listen back.",
        scriptSteps: ["Stand your ground", "Ask what he wants", "Refuse the deal"],
        scriptGoals: ["Speaking with confidence", "Clear pronunciation", "Steady pace"],
        scriptLines: [
            "Count Valerio, I am not afraid of you.",
            "What exactly do you want in return for restarting the clock?",
            "I will not accept your deal. Give back the silver pin."
        ]
    )

    static let secretAgent = PracticeScenario(
        id: "secret-agent",
        title: "The Secret Agent",
        symbol: "eye",
        illustrationAsset: "scene_agent",
        backendMode: rolePlayMode(
            character: "Nightingale, a mysterious intelligence contact",
            partner: "an undercover secret agent meeting you for a new mission",
            setting: "a quiet café inside a busy train station, late in the evening.",
            personality: "serious, secretive, intelligent and suspenseful; calm and quiet.",
            truth: "The mission is to recover a stolen music box that hides the blueprints for a new invention that cleans city water. It will be at a charity gala at the Grand Hotel tomorrow at eight. Accept any confident answer about the agent's identity, but test it with one follow-up question first.",
            clues: "the music box will be auctioned as lot seventeen; the signal is a red rose on the piano; the inside contact is a pianist named Theo; the code phrase is 'The rain in Lisbon is warm tonight'.",
            twist: "Nightingale warns that someone at the next table might be listening, and for one reply speaks only about the weather in code.",
            ending: "once the agent repeats the code phrase correctly and confirms the plan, she slides over an envelope, wishes them luck, and leaves."),
        category: .rolePlay,
        voiceName: "en-US-Emma:DragonHDLatestNeural",
        voiceStyle: "serious",
        voiceRate: "-8%",
        ambienceAsset: "ambience_agent",
        aiRoleLabel: "NIGHTINGALE · YOUR CONTACT",
        aiSummary: "You're an undercover agent meeting your contact, Nightingale, in a quiet train station café. Earn her trust, gather the details, and accept your mission.",
        aiOpening: "You're late. Sit down, order a coffee, and don't look at the door. Tell me something only our agency would know.",
        aiSteps: ["Prove who you are", "Gather the mission details", "Accept the mission"],
        aiGoals: ["Asking for details", "Repeating information", "Speaking calmly"],
        aiHints: [
            "Try: “Our last mission was in Vienna. The password was ‘blue lantern’.”",
            "Try: “Where will the music box be, and how will I know my contact?”",
            "Try: “The rain in Lisbon is warm tonight. I accept the mission.”"
        ],
        offlineReplies: [
            "Good enough. The target is a music box at the Grand Hotel gala, tomorrow at eight.",
            "Lot seventeen. Your inside contact is a pianist named Theo. Look for a red rose on the piano.",
            "Say the phrase to Theo: the rain in Lisbon is warm tonight. Good luck, agent."
        ],
        scriptSummary: "Read the agent's lines aloud, record them, and listen back.",
        scriptSteps: ["Make contact", "Ask for the details", "Confirm the code phrase"],
        scriptGoals: ["Speaking calmly", "Clear pronunciation", "Steady pace"],
        scriptLines: [
            "Good evening. I believe we have a mutual friend.",
            "Where will the music box be, and who is my contact?",
            "Understood. The rain in Lisbon is warm tonight."
        ]
    )

    static let gameMaster = PracticeScenario(
        id: "game-master",
        title: "The Game Master",
        symbol: "gamecontroller",
        illustrationAsset: "scene_gameshow",
        backendMode: rolePlayMode(
            character: "Rex Ravel, the host of a mysterious TV game show called The Mystery Box Show",
            partner: "a contestant on the show",
            setting: "a bright TV studio with a cheering audience and a glowing mystery box on stage.",
            personality: "energetic, dramatic, playful and entertaining; praises effort generously. Game-show drama is fine, but there are absolutely no countdowns or time pressure for answers: tell them to take their time.",
            truth: "The rounds, in order: Round 1, the contestant says their name and one thing that makes them smile. Round 2, 'Three Words': describe their favourite food in exactly three words. Round 3, 'The Riddle': what has keys but can't open locks? (a piano; accept any good guess and give kind hints). Round 4, 'The Doors': choose door one, two or three and explain why. Final round, 'The Spotlight': tell the audience about a place they love. Run one round at a time.",
            clues: "tease what is inside the mystery box between rounds, without revealing it.",
            twist: "after round 3, announce a surprise bonus round where the contestant asks YOU a question.",
            ending: "after the final round, open the mystery box: it holds a golden microphone trophy. Celebrate the contestant and say goodbye to the audience."),
        category: .rolePlay,
        voiceName: "en-US-Adam:DragonHDLatestNeural",
        voiceStyle: "excited",
        voiceRate: "-8%",
        ambienceAsset: "ambience_gameshow",
        aiRoleLabel: "REX RAVEL · YOUR HOST",
        aiSummary: "You're a contestant on The Mystery Box Show. Host Rex Ravel throws unexpected challenges at you, round by round. Make it to the final round and open the box!",
        aiOpening: "Welcome, welcome, welcome to The Mystery Box Show! I'm your host, Rex Ravel. Contestant, tell everyone your name and one thing that makes you smile!",
        aiSteps: ["Introduce yourself", "Take on each round", "Reach the final round"],
        aiGoals: ["Thinking on the spot", "Describing things", "Having fun speaking"],
        aiHints: [
            "Try: “Hi Rex! I'm Sara, and my cat always makes me smile.”",
            "Try: “Sweet, crunchy, golden!” or “Is it a piano?”",
            "Try: “I choose door number two, because two is my lucky number.”"
        ],
        offlineReplies: [
            "Fantastic! Round two: describe your favourite food in exactly three words!",
            "Brilliant! Round three, the riddle: what has keys but can't open locks?",
            "You've made it to the final round! Tell us about a place you love!"
        ],
        scriptSummary: "Read a contestant's lines aloud, record them, and listen back.",
        scriptSteps: ["Introduce yourself", "Make your choice", "Celebrate"],
        scriptGoals: ["Speaking with energy", "Clear pronunciation", "Smooth rhythm"],
        scriptLines: [
            "Hello everyone! My name is Sara, and I am ready to play.",
            "I choose door number two, because two is my lucky number.",
            "Thank you so much! This golden microphone is amazing!"
        ]
    )
}

/// What a finished session hands to the feedback screen.
struct PracticeSessionResult {
    let kind: PracticeKind
    let duration: TimeInterval
    /// AI conversation: user turns completed. Script: number of takes recorded.
    let turns: Int
    let plannedTurns: Int
    /// Script practice only: local 16 kHz mono WAV of the final take (for later on-device analysis).
    let recordingURL: URL?
    let recordingDuration: TimeInterval?
    /// AI conversation: one local 16 kHz mono WAV per answer.
    var turnRecordingURLs: [URL] = []
    /// AI conversation: what the user said (from on-device speech recognition), for words per minute.
    var transcript: String? = nil
    /// AI conversation: every message (AI and user, in order), saved to practice history.
    var conversation: [ChatMessage] = []

    /// All audio files to analyze for this session.
    var audioFiles: [URL] {
        turnRecordingURLs + (recordingURL.map { [$0] } ?? [])
    }
}
