// triage.baml — `.matches<T>()` / `.how()` / `.judge<T>()` on richer types.
// Everything here is a *judgment* (finite choices, probabilities), so it all
// runs on Jev. No JSON parsing, no schema prompts — the return type IS the question.

enum Team {
    Billing @description("Payments, charges, refunds, or invoices"),
    Technical @description("Bugs, outages, or integrations"),
    Account @description("Login, identity, or account access"),

    @@description("Which team should handle this ticket?")
}

type Mood = "calm" | "concerned" | "angry";

class Ticket {
    customer: string,
    tier: "free" | "pro" | "enterprise",
    message: string,
}

/// A class = several independent judgments, sent as ONE Jev request.
class Triage {
    urgent: bool @description("Does this ticket require immediate attention?"),
    route: Team,
    churn_risk: float @description("How likely is this customer to churn over this?"),
    mood: Mood @description("What is the customer's emotional state?"),
}

function sample_tickets() -> Ticket[] {
    [
        Ticket {
            customer: "Acme Corp",
            tier: "enterprise",
            message: "Our production integration has been failing since 2am. This is unacceptable, we're losing money every minute.",
        },
        Ticket {
            customer: "Jo",
            tier: "free",
            message: "hi! i think i was charged twice this month? no rush, just wanted to flag it :)",
        },
        Ticket {
            customer: "Sam",
            tier: "pro",
            message: "Can't log in after enabling 2FA. Tried resetting my password twice.",
        },
    ]
}

function triage(t: Ticket) -> string {
    //# One request, four judgments — the class fields become Jev questions
    let tri = t.fill<Triage>();
    let tag = if (tri.urgent) {
        "🔥"
    } else {
        "  "
    };
    `${tag} ${t.customer} (${t.tier}) → ${tri.route}, mood=${tri.mood}, churn=${tri.churn_risk}`
}

function triage_all() -> string {
    //# Judge every ticket concurrently
    let lines = await baml.future.all(sample_tickets().map((t) -> { spawn { triage(t) } }));
    lines.join("\n")
}

// ─── Works on any type, not just strings ─────────────────────────────────────

function stars(review: string) -> 1 | 2 | 3 | 4 | 5 {
    //# Literal union → Jev Choice; the question comes from the argument
    review.judge<1 | 2 | 3 | 4 | 5>("How many stars does this review give the product?")
}

function route_or_leave(t: Ticket) -> Team? {
    //# `Team?` adds an explicit abstention choice
    t.judge<Team?>("Which team should handle this, if any?")
}

function scary_number(n: int) -> bool {
    //# Yes, even an int can have a vibe
    n.feels("like a suspiciously round number")
}

function demo() -> string {
    let out: string[] = [];
    out.push(triage_all());
    out.push(`stars: ${stars("It works, but the battery barely lasts a day. Fine for the price.")}`);
    out.push(
        `route_or_leave: ${route_or_leave(Ticket { customer: "?", tier: "free", message: "what is the weather like where you are?" }) ?? "<nobody>"}`,
    );
    out.push(`urgency of 'lunch?': ${"lunch?".how("urgent")}`);
    out.push(`urgency of 'SERVER ON FIRE': ${"SERVER ON FIRE".how("urgent")}`);
    out.push(`1000000 scary? ${scary_number(1000000)}   1337 scary? ${scary_number(1337)}`);
    out.join("\n")
}
