// Offline tests: build the Jev requests without sending them (no API key needed).

function questions(req: baml.http.Request) -> map<string, baml.json.json> {
    let body = baml.json.from_string<map<string, baml.json.json>>(req.body ?? "{}");
    baml.json.from_string<map<string, baml.json.json>>(baml.json.to_string(body.get("questions")))
}

test "feels asks one Noul question with the quality in the instructions" {
    let req = Feels@build_request("prod is down", "urgent");
    assert.equal(req.url, "https://api.typesafe.ai/v1/systemone");
    let q = questions(req);
    assert.equal(q.keys(), ["result"]);
    assert.contains(baml.json.to_string(q.get("result")), "\"type\":\"noul\"");
    assert.contains(baml.json.to_string(q.get("result")), "Does this feel urgent?")
}

test "state_of passes strings through and serializes everything else" {
    assert.equal(state_of("plain"), "plain");
    assert.equal(state_of(42), "42");
    assert.equal(
        state_of(Ticket { customer: "Jo", tier: "free", message: "hi" }),
        `{"customer":"Jo","tier":"free","message":"hi"}`,
    )
}

test "the blanket impl is available on every type" {
    // Only type-checks the dispatch; no request is sent.
    let f1 = Feels@spec("a string", "urgent");
    let f2 = Judge<Team>@spec(state_of(sample_tickets()[0]), "which team?");
    assert.not_null(f1);
    assert.not_null(f2)
}
