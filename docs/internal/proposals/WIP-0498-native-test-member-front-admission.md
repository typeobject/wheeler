# WIP-0498: Native test member-front admission

| Field | Value |
| --- | --- |
| Status | Draft |
| Owners | Wheeler compiler and testing maintainers |
| Created | 2026-09-05 |
| Updated | 2026-09-05 |
| Area | Native source admission, test discovery |
| Depends on | WIP-0051, WIP-0497 |
| Supersedes | None |
| Superseded by | None |

## Boundary

[WIP-0497](WIP-0497-exact-source-word-admission.md) removes hash aliases from word
classification. Automatic test discovery still treats an unknown declaration
front as irrelevant text. Replacing `test` with `tetU`, or `void` with `vojE`, in
two tagged declarations makes stage 0 reject the source. The native runner
instead emits a successful 39-byte report with zero selected tests. An unrelated
entry in the same class does not make those declarations valid.

Explicit test descriptors detect the missing declarations. That check does not
establish source admission for automatic discovery. The scanner validates token
ranges, not class-member grammar.

## Change

Walk class-member fronts before automatic descriptor construction. Dispatch
admitted state, constant, nominal, proof, and callable fronts through their
owning source products. Track declaration and body boundaries rather than
searching every token for the word `test`. An unknown modifier or malformed
return-type/name sequence must not disappear as a non-test declaration.

Keep identifier spelling separate from keyword policy. A word unknown to the
fixed vocabulary may still name a declared type or function. Reuse bound names
and existing type/signature products rather than adding a keyword blacklist or a
second nominal resolver.

Complete front admission precedes caller-visible descriptors, reports, artifacts,
and identities. Private staging may survive a rejected later front. Caller
publication must not change. Preserve the existing source, token, case, and
package-plan bounds.

## Evidence

- Reproduce both malformed tagged declarations against independent stage 0 and
  the native automatic-discovery transport.
- Reject malformed first and later fronts with zero selected tags, no matching
  tags, explicit descriptors, and automatic descriptors.
- Preserve valid empty discovery, ordinary helpers, entries, constants, nominal
  declarations, metadata, and parameter rows. A legitimate non-test member must
  not become a test or an error merely because of its name.
- Check complete caller publication and rewind. Keep the 255-case and complete
  physical-source boundaries in the confirming suite.

## Acceptance

- [ ] Member-front ownership and rejection precedence are explicit.
- [ ] Native discovery consumes admitted fronts rather than raw keyword searches.
- [ ] Both alias regressions reject before any caller publication.
- [ ] Valid mixed members and empty selections retain their behavior.
- [ ] Complete publication, boundary, and rewind evidence passes.
- [ ] Docs, examples, package identities, and locks agree.

## Remaining work

This record does not validate every method body or complete the frontend.
[WIP-0051](WIP-0051-native-aggregate-frontend-products.md) still owns complete
source-derived frontend products. Full lowering, diagnostic parity, the compiler
fixed point, recovery, and Java-free operation remain open.
