# Mastery

This is the Elixir OTP project the book "Designing Elixir Systems with OTP" walks you through creating. The book is fantastic, and does a great job slowly introducing the tenets of architecting an OTP application.

_That said_, the end-point of the book leaves the app with a little to be desired (in my opinion, at least). Namely...

- The tests don't have 100% coverage
- The app blows up if a user provides a non-string answer
- The validators _always_ return `:ok` when the last field in the pipe is valid, even if earlier fields aren't
- Mastery invokes `GenServer.call` directly instead of delegating to QuizManager
- The Proctor is unnecessarily coupled to QuizManager for building quizzes and adding templates
  - Note: It's also coupled to QuizManager for removing quizzes, but that's necessary because quiz removal functionality is not on the public API provided by Mastery.ex

This repo includes fixes for these problems. That "validators _always_ return `:ok`" one was particularly insidious, because it means all the quiz titles the book has you use throughout (e.g. `:simple_addition`) are _technically_ invalid, as the validators stipulate titles are supposed to be non-blank binaries.

## Acknowledgements

As mentioned above, the book this project came from is titled _Designing Elixir Systems with OTP_, and I found it to be a highly-instructive read. If you're interested in checking it out, the check its listing out [on PragProg](https://pragprog.com/book/jgotp/designing-elixir-systems-with-otp).
