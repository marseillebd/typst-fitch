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
    else if it.len() == 2 {
      if it.at(0) == none or type(it.at(0)) == label {
        toRow((..it, []))
      } else {
        toRow((none, ..it))
      }
    }
    else {
      assert(false,
        message: "each row in a fitch-style proof must have a line number, formula, and explanation"
      )
    }
  } else if (type(it) == dictionary) {
    assert(not(mustBeLeaf), message: "assumptions cannot nest, they must be leaf nodes")
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
    let depthUnder = calc.max(0, ..pre.below.map(x => x.depth))
    let depthHere = if pre.beside == none { 1 } else { 2 }
    (..pre, depth: depthHere + depthUnder)
  }
}

#let assume(beside: none, premise: none, premises: none, ..below) = {
  let msg = "must pass exactly one of either 'premise' or 'premises' arguments"
  assert(premise != none or premises != none, message: msg)
  assert(not(premise == none and premises == none), message: msg)
  let above = if premise == none { premises } else { (premise,) }
  (
    beside: beside,
    above: above,
    below: below.pos(),
  )
}

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
        kind: "go-fitch-lineno",
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
