// ─── Vibes: out-of-body judgment methods on *every* type ─────────────────────
//
//   if (email.feels("urgent")) { ... }          bool     — Jev Noul, thresholded at 0.5
//   email.how("urgent")                          float    — Jev Noul, raw probability
//   email.matches<Team>()                        T        — Jev Choice / one-request class fan-out
//   email.judge<Mood>("What is the mood?")       T        — same, with explicit instructions
//   email.ask("Draft a reply")                   string   — generative model, for when you need text
//
// The blanket `implements<S> Vibes for S` below is what makes this work on
// strings, ints, classes, arrays — anything. The value is serialized (strings
// pass through, everything else becomes JSON) and handed to TypeSafe's Jev
// classifier as the `state`. The *return type* of each method is the schema
// Jev is asked to fill.

interface Vibes {
    /// Yes/no judgment. `true` when Jev's probability is >= 0.5.
    function feels(self, quality: string) -> bool throws unknown;
    /// Same question as `feels`, but you keep the probability and pick the threshold.
    function how(self, quality: string) -> float throws unknown;
    /// Classify into T. T is an enum, a literal union, or a class of such fields
    /// (a class becomes one request with one question per field).
    function matches<T>(self) -> T throws unknown;
    /// `matches<T>` with explicit instructions — needed for literal unions,
    /// which carry no `@@description` of their own.
    function judge<T>(self, question: string) -> T throws unknown;
    /// Free-form generation about this value (not Jev — Jev only classifies).
    function ask(self, instruction: string) -> string throws unknown;
}

implements<S> Vibes for S {
    function feels(self, quality: string) -> bool {
        Feels(state_of(self), quality)
    }
    function how(self, quality: string) -> float {
        How(state_of(self), quality)
    }
    function matches<T>(self) -> T {
        Matches<T>(state_of(self))
    }
    function judge<T>(self, question: string) -> T {
        Judge<T>(state_of(self), question)
    }
    function ask(self, instruction: string) -> string {
        Ask(state_of(self), instruction)
    }
}

/// Strings go to the model verbatim; anything else is serialized as JSON.
function state_of<S>(v: S) -> string {
    match (v) {
        let s: string => s,
        _ => baml.json.to_string(v),
    }
}

// ─── The LLM functions behind the methods ────────────────────────────────────
// Jev is a classifier: the return type is the question shape, `role("instructions")`
// is the question, everything else in the prompt is the `state` being judged.

client Jev = typesafeai.Client.new(model = "jev-latest", api_key = env.TYPESAFE_API_KEY);

function Feels(state: string, quality: string) -> bool {
    client: Jev
    prompt: `
        ${role("instructions")}
        Does this feel ${quality}?
        ${role("user")}
        ${state}
    `
}

function How(state: string, quality: string) -> float {
    client: Jev
    prompt: `
        ${role("instructions")}
        Does this feel ${quality}?
        ${role("user")}
        ${state}
    `
}

// No instructions: the question comes from T itself — an enum's @@description,
// a class field's @description, etc.
function Matches<T>(state: string) -> T {
    client: Jev
    prompt: `${state}`
}

function Judge<T>(state: string, question: string) -> T {
    client: Jev
    prompt: `
        ${role("instructions")}
        ${question}
        ${role("user")}
        ${state}
    `
}

// Generation is not Jev's job — hand that to a regular model.
client Writer = anthropic.Client.new(model = "claude-sonnet-5", api_key = env.ANTHROPIC_API_KEY);

function Ask(state: string, instruction: string) -> string {
    client: Writer
    prompt: `
        ${role("system")}
        ${instruction}
        Reply with only the result — no preamble.
        ${role("user")}
        ${state}
    `
}
