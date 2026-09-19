// grep_with_vibes.baml — grep, but the pattern is a feeling.
//   git log --format=%s | baml run grep_with_vibes -- --feeling "a bug fix"

function grep_with_vibes(feeling: string) -> void {
    let lines = read_stdin_lines();
    //# Judge every line concurrently
    let hits = await baml.future.all(lines.map((l) -> { spawn { l.feels(feeling) } }));
    //# Print the ones that match
    let i = 0;
    while (i < lines.length()) {
        if (hits[i]) {
            baml.io.println(lines[i]);
        }
        i += 1;
    }
}

/// Read stdin until EOF or an empty line.
function read_stdin_lines() -> string[] {
    let lines: string[] = [];
    let line = baml.io.input(null);
    while (line != "") {
        lines.push(line);
        line = baml.io.input(null);
    }
    lines
}
