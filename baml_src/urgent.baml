// urgent.baml — the tweet, verbatim, reading the email from stdin.
//   echo "prod is down, customers can't log in" | baml run urgent

function urgent() -> void {
    let email = baml.io.input("email: ");

    if (email.feels("urgent")) {
        baml.io.println(email.ask("Draft a reply"));
    }
}
