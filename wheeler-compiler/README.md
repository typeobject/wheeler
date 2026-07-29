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

A class may place at most sixty-four literal `const long` or `const boolean` declarations
before its helper or entry. Public and private constants share one duplicate-name check.
The resolver substitutes them into matching local declarations, scalar helper returns,
scalar assignments, checked signed updates, and one- or two-argument scalar helper calls.
Calls and mutations may mix constants with prior locals. The resolver rejects helper
parameters or locals that reuse constant names. Constants create no global,
initializer, lookup, or declaration-order artifact noise. Full constant expressions, imports,
and multi-file linking remain stage-0 work
until their native implementations pass differential artifact tests.

The narrow loop body and literal-only constant prefix are deliberate limits, not parser
folklore. Unsupported syntax fails before output publication. Each extension must match
stage 0 byte for byte before the profile claims it.

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
