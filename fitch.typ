= Hello

#table(
  columns: 3,
  stroke: none,
  [1], table.cell(stroke: (left: 1pt,))[all men are mortal], [],
  [2], table.cell(stroke: (left: 1pt,))[socrates is a man], [],
  table.hline(start: 1,),
  [3], table.cell(stroke: (left: 1pt,))[socrates is a mortal], [$forall$*I* 1,2],
)

So far, I
- skimmed the manual
- installed the cli
- in about half an hour before work, got the above table
Overall, I'm quite happy with Typst so far.

#let empty = table.cell(inset: 0.2em, [])
#table(
  columns: 4,
  stroke: none,
  table.vline(x: 1),
  // now we have the bulk of the table
  [1], table.cell(colspan: 2, [$forall x. "man"(x) -> "mortal"(x)$]), [],
  [2], table.cell(colspan: 2, [$exists x. "man"(x)$]), [],
  table.hline(start: 1, end: 3),
  empty, table.cell(colspan: 2, inset: 0pt, empty), empty,
  [], [$a$], [], [],
  table.hline(start: 2, end: 3),
  [3.1], [], [$"man"(a)$], [$exists$*E* 1],
  [3.2], [], [$"man"(a) -> "mortal"(a)$], [$forall$*E* 1],
  [3.3], [], [$"mortal"(a)$], [$->$*E* 3.2, 3.1],
  [4], table.cell(colspan: 2, [$exists x. "mortal"(x)$]), [$exists$*I* 3.3],
  // after identifying the typst rows that need assumption lines, output those lines
  table.vline(x: 2, start: 3, end: 7),
)

#let toFitch(mustBeLeaf: false, it) = {
  let toRow(row) = (row: row, depth: 0)
  if type(it) == content {
    toRow((none, it, []))
  }
  else if type(it) == array {
    if it.len() == 3 {
      assert(it.at(0) == none or type(it.at(0)) == label,
        message: "first element in row must be none or label"
      )
      toRow(it)
    }
    else if it.len == 2 {
      if it.at(0) == none or type(it.at(0)) == label {
        toRow(..it, [])
      } else {
        toRow(none, ..it)
      }
    }
    else {
      assert(false,
        message: "each row in a fitch-style proof must have a line number, formula, and explanation"
      )
    }
  } else if (type(it) == dictionary) {
    assert(not(mustBeLeaf), message: "assumptions canot nest, they must be leaf nodes")
    assert("beside" in it, message: "assumptions must have a 'beside' field")
    if it.beside != none {
      assert(type(it.beside) == content, message: "'beside' field must be content or none")
    }
    assert("above" in it, message: "assumptions must have a 'above' field")
    assert(type(it.above) == array, message: "'above' field must be an array")
    assert(it.above.len() > 0, message: "assumptions must be non-empty")
    assert("below" in it, message: "assumptions must have a 'below' field")
    assert(type(it.below) == array, message: "'below' field must be an array")
    let pre = (
      beside: it.beside,
      above: it.above.map(toFitch.with(mustBeLeaf: true)),
      below: it.below.map(toFitch),
    )
    let depthUnder = calc.max(..pre.below.map(x => x.depth))
    let depthHere = if pre.beside == none { 1 } else { 2 }
    (..pre, depth: depthHere + depthUnder)
  }
}

#let assume(beside: none, premise: none, premises: none, ..below) = {
  let msg = "must pass exactly one of either 'premise' or 'premises' arguments"
  assert(premise != none or premises != none, message: msg)
  assert(not(premise != none and premises != none), message: msg)
  let above = if premise == none { premises } else { (premise,) }
  (
    beside: beside,
    above: above,
    below: below.pos(),
  )
}

#show figure.where(kind: "fitchline"): it => it.body

#let fitch(
  stroke: black + 1pt,
  subproofInset: (left: 0.3em, y: 0.2em),
  justSep: 2em,
  line-numbering: "1.",
  premises: (),
  ..conclude
) = {
  assert(type(premises) == array)
  let root = toFitch(assume(premises: premises, ..conclude))
  let maxBodyCols = root.depth

  let c = counter("fitch proof")
  let mk = (
    padding: (colspan: 1) => table.cell(
      colspan: colspan,
      inset: subproofInset,
      // fill: orange,
      []
    ),
    gutter: (lbl) => {
      let lineno = figure(
        kind: "fitchline",
        supplement: [],
        [#set align(right); #c.step()#context c.display(line-numbering)],
      )
      let theLabel = if type(lbl) == label { lbl } else []
      table.cell(
        // fill: yellow,
        [#lineno#theLabel]
      )
    },
    preformula: (beside: none) =>
      if beside == none {
        table.cell(
          inset: 0pt,
          // fill: blue,
          []
        )
      }
      else {
        table.cell(
          align: right,
          stroke: (left: stroke),
          colspan: 2,
          // fill: blue,
          beside,
        )
      },
    subproof: () => table.cell(
      stroke: (left: stroke),
      inset: subproofInset,
      // fill: aqua,
      []
    ),
    formula: (colspan: 1, it) => table.cell(
      stroke: (left: stroke),
      colspan: colspan,
      // fill: green,
      it
    ),
    justify: (it) => table.cell(
      inset: (left: justSep),
      // fill: lime,
      it
    ),
  )

  let goFitch(parentLines: (), it) = {
    let curCol = parentLines.len()
    let nBodyCols = maxBodyCols - curCol

    let putRow(rowBeside: none, row) = (
      (mk.gutter)(row.at(0)),
      ..if it.beside == none { (
          ..parentLines,
          (mk.formula)(colspan: nBodyCols, row.at(1)),
        ) }
        else if rowBeside == none { (
          ..parentLines,
          (mk.preformula)(),
          (mk.formula)(colspan: nBodyCols - 1, row.at(1)),
        ) }
        else { (
          ..parentLines.slice(0, -1),
          (mk.preformula)(beside: rowBeside),
          (mk.formula)(colspan: nBodyCols - 1, row.at(1)),
        ) },
      (mk.justify)(row.at(2)),
    )

    if "row" in it {
      putRow(it.row)
    }
    else { // under an assumption block
      let parentLine = (
        ..if it.beside == none { () } else { ((mk.preformula)(),) },
        (mk.subproof)(),
      )

      (
        // padding row
        ..if curCol == 0 { () } else {
          ( (mk.padding)(), ..parentLines, (mk.padding)(colspan: nBodyCols + 1) )
        },
        // assumptions
        ..putRow(rowBeside: it.beside, it.above.at(0).row),
        ..it.above.slice(1).map(x => putRow(x.row)).join(),
        // divider
        table.hline(
          start: curCol + parentLine.len(),
          end: maxBodyCols + 1,
          stroke: stroke,
        ),
        // conclusions
        ..it.below.map(node =>
          if "row" in node { putRow(node.row) }
          else {
            goFitch(parentLines: parentLines + parentLine, node)
          }).join(),
      )
    }
  }

  table(
    columns: 1 + maxBodyCols + 1,
    stroke: none,
    // stroke: 0.5pt + gray,
    // the bulk of the table
    ..goFitch(root)
  )
}

#line(length: 100%)

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
    assume(
      premise: [#lorem(30)],
      [asdf]
    ),
    (<socrates-is-mortal>, [$"socrates"(a) and "mortal"(a)$], [$and$*I* @a-is-man2, @a-is-mortal]),
  ),
  assume(
    premise: [hi],
    [bye],
  ),
  (none, [$exists x. "socrates"(x) and "mortal"(x)$], [$exists$*I* @socrates-is-mortal]),
)

It may have taken the better part of a day, but now I have a function to specify the tree
and it will typeset all the lines for me!
Goodness gracious, that would have taken me a week or more to figure out in LaTeX,
and the result would be unreadable to beginners!

Next up, I want to have auto counters!
Also, I need to be able to configure attributes like stroke length and the gaps for empty cells.

#line(length: 100%)

The table I build is, well, something.
The idea is that each row is set independently.
On the left, there's a gutter (line number), and on the right some justification.
In the middle are a variable number of "body" columns, which get merged in interesting ways.

We compute the number of body colums essentially as the maximum depth of the assumptions.
However, if an item is placed on the left of an assumption line, that adds an extra column.
Each time we enter a new assumption, we push down "parent columns" which contain
  an optional empty column for the beside-item,
  and then an empty cell with the left border set for the assumption line.
These are created with `besideCell` and `lineCell` respectively.
The formula for the row takes up all the body columns,
  less one for the beside-item if this node in the tree has one.
It is created with `formulaCell`.
If there is a beside-item to set on the current row, that cell is "merged" with the previous one:
  the last cell of the parent columns is dropped (it was a `lineCell`),
  and `lineCell` is used again to fill the next two columsn with the beside-item.
We do this because the horizontal spacing from the parent's final `lineCell`
  would push the next assumption line too far over,
  visually adding that spaceing onto the left of the beside-item's cell.
By "merging" the cells, the beside-item gets only as much padding as a normal cell.

The approach I've describes places sibling assumptions as close as possible to the left,
  but this can mean they are "ragged": those with beside-items are pushed further right.
I'm not sure if I like this approach, but it's relatively easy to fix:
  in `toFitch`, replace any `(beside: none, ...)` with `(beside: [], ...)`.

We also don't want vertical lines crashing into the horizontal assumption lines,
  or into vertical lines from adjacent sibling sub-proofs.
Thus, we add a row before each new sub-proof which is empty except for padding and the parent lines.
