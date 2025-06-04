#import "../lib.typ": *
#set page(height: auto, width: auto, margin: 1em)
#set text(font: "New Computer Modern")

#fitch(
  premise: [],
  assume(
    premise: (<ass-p>, [$P$]),
    assume(
      premise: (<ass-np>, [$not P$]),
      (<oops>, [$bot$], [$bot$*I* @ass-p, @ass-np]),
    ),
    (<nnp>, [$not not P$], [contra @ass-np, @oops]),
  ),
  assume(
    premise: (<ass-nnp>, [$not not P$]),
    (<p>, [$P$], [$not^2$*E* @ass-nnp]),
  ),
  (<forward>, [$P -> not not P$], [$->$*I* @ass-p -- @nnp]),
  (<backward>, [$not not P -> P$], [$->$*I* @ass-nnp -- @p]),
  ([$P <-> not not P$], [$<->$*E* @forward, @backward]),
)
