// The first complete Wheeler program: one reversible function used in both directions.
wheeler 1
program Counter
kind classical

state count = 0

rev coherent increment {
  add count 1
}

entry {
  call increment
  call increment
  expect count 2

  // Language-level inverse invocation is new execution, not debugger rewind.
  uncall increment
  uncall increment
  expect count 0
  halt
}
