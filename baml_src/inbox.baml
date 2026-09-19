// inbox.baml — the "inbox department" from probably-lang, in BAML.
//
// Jev routes the email and gates on confidence; an LLM writes; a loop keeps
// rewriting until the draft stops feeling like corporate jargon. Everything
// is ordinary BAML control flow — `.feels()` / `.how()` / `.judge<T>()` are
// just methods (see vibes.baml).

type Kind = "a bug report" | "a sales pitch" | "a meeting request" | "something else";

function inbox(email: string) -> string {
    //# 1. Confidence-gated urgency: keep the probability, pick the threshold
    let urgency = email.how("genuinely urgent");
    if (urgency >= 0.8) {
        log.info("Drop everything.");
    } else if (urgency >= 0.5) {
        log.info("Probably urgent. Ask a follow-up question.");
    } else {
        log.info("It can wait.");
    }
    //# 2. Route between descriptions — a literal union is a Jev Choice
    let strategy = match (email.judge<Kind>("What kind of email is this?")) {
        "a bug report" => "Acknowledge the bug, ask for reproduction steps, promise a follow-up.",
        "a sales pitch" => "Politely decline in two sentences.",
        "a meeting request" => "Propose two concrete time slots next week.",
        "something else" => "Reply briefly and helpfully.",
    };
    //# 3. An LLM writes the draft
    let draft = email.ask(`Draft a reply. ${strategy}`);
    //# 4. Keep going until something stops feeling true (with a real loop bound)
    let attempts = 0;
    while (attempts < 5 && draft.feels("full of corporate jargon")) {
        draft = draft.ask("Rewrite this plainly, keeping the meaning.");
        attempts += 1;
    }
    //# 5. Subject line from the finished reply
    let subject = draft.ask("Write a subject line for this email. Just the subject.");
    `Subject: ${subject}\n\n${draft}`
}
