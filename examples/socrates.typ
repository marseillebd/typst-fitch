#import "../lib.typ": *
#set page(height: auto, width: auto, margin: 1em)
#set text(font: "New Computer Modern")

#fitch(
  premises: (
    (<men-are-mortal>, [$forall x. "man"(x) -> "mortal"(x)$], []),
    (<theres-a-man>, [$exists x. "man"(x) and "socrates"(x)$], []),
  ),
  assume(
    beside: $a$,
    premise:
      (<a-is-man>, [$"man"(a) and "socrates"(a)$], [$exists$*E* @men-are-mortal]),
    (<man-a-then-mortal-a>, [$"man"(a) → "mortal"(a)$], [$forall$*E* @theres-a-man]),
    (<a-is-man1>, [$"man"(a)$], [$and$*E* @a-is-man]),
    (<a-is-mortal>, [$"mortal"(a)$], [$->$*E* @man-a-then-mortal-a, @a-is-man1]),
    (<a-is-man2>, [$"socrates"(a)$], [$and$*E* @a-is-man]),
    (<socrates-is-mortal>, [$"socrates"(a) and "mortal"(a)$], [$and$*I* @a-is-man2, @a-is-mortal]),
  ),
  (none, [$exists x. "socrates"(x) and "mortal"(x)$], [$exists$*I* @socrates-is-mortal]),
)
