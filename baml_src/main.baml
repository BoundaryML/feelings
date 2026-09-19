// urgent.baml — the demo from the tweet, in BAML. `.feels()` is not syntax:
// it's an interface method with a blanket impl (see vibes.baml), backed by Jev.

function main(
    email: string = "Hey — prod is down and none of our customers can log in. Need someone on this now.",
) -> string {
    //# Ask Jev: does this email feel urgent?
    if (email.feels("urgent")) {
        //# It does — have a generative model draft the reply
        return email.ask("Draft a reply");
    }
    "not urgent, skipping"
}
