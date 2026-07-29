# Wheeler compiler

This directory owns the Wheeler-written compiler package. Sources under
`src/main/wheeler` define the scanner, compiler, verifier, codecs, and package driver.
Java does not get a weekend cottage here.

## Package boundary

`compiler/Driver.w` is the stateless compiler API. `MinimalCompiler.w` is its executable
wrapper and publishes only the verified output range. Identity tools call the same API
instead of maintaining a shadow compiler with a fake moustache.

The package keeps responsibilities narrow:

- `compiler/frontend` owns bounded token, structure, body, and statement parsing.
- `compiler/syntax` owns statement and call shapes.
- `compiler/resolution` owns typed locals, helper calls, operands, and scalar class
  constants.
- `compiler/ir` owns opcode, instruction-form, type, and proof identities.
- `compiler/backend` owns type tables, strings, control flow, returns, and encoding.
- `compiler/verification` owns complete check-before-publication artifact validation.

`wheeler.package.yaml`, its exact lock, and the canonical workspace sources define the
closed build. Generated `vendor/` trees belong to exported offline bundles, not source
control.

## Current recovery profile

The bounded compiler accepts one class, zero or one signed global, one optional helper,
and one entry. Entry and helper bodies admit at most sixty-four statements. The current
slice covers typed signed and Boolean locals, assertions, assignments, checked scalar
operations, calls, results, and narrow explicitly limited loops.

A class may place one contiguous block of at most sixty-four `const long` or `const boolean`
declarations around its optional signed state and before its helper or entry. Constants may
initialize that state, including a forward reference when state comes first. Splitting the
constant block around state fails rather than creating two lookup rules. Their bounded
expressions admit decimal, hexadecimal, and binary
integers, Booleans, parentheses, checked arithmetic, `!`, `^`, `&`, `==`, `<`, and forward
same-class dependencies. A lookup allows 4,096 evaluation steps, dependency paths stop at
sixty-four declarations, and parentheses stop at depth thirty-two. Cycles, unknown names,
type errors, malformed forms, and arithmetic traps publish nothing.

The resolver substitutes evaluated values into matching local declarations, scalar helper
returns, scalar assignments, checked signed updates, one- or two-argument scalar helper calls,
right operands of signed arithmetic and ordering expressions, signed or Boolean equality and
inequality expressions,
signed arithmetic or typed scalar comparison returns, signed equality or ordering assertions and conditions, and
bounded loop conditions and limits. Calls and mutations
may mix constants with prior locals. Helper parameters and locals cannot reuse constant names.
Constants create no global, initializer, lookup, or declaration-order artifact noise. Imported constants, qualification, `rotateRight32`, and
multi-file linking remain stage-0 work until native differential artifacts pin them down.

The narrow loop body and local constant graph are deliberate limits, not parser folklore.
Unsupported syntax fails before output publication. Each extension must match stage 0 byte
for byte before the profile claims it.

## Promotion

The temporary Java seed lives in [`../bootstrap/stage0`](../bootstrap/stage0). It compiles
this package into stage 1. Stage 1 must then compile the same sources into a byte-identical
stage 2. Promotion also requires the diverse-bootstrap and provenance evidence from
WIP-0007. A fixed point catches drift. Repetition alone does not exorcise a malicious
ancestor.

Examples consume this package through exact locks. They do not carry compiler copies.
New implementation features land in Wheeler once the recovery profile can express and
test them. Any Java addition needs a concrete stage-crossing reason and a deletion
condition.
