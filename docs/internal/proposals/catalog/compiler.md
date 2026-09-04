# Compiler products and bootstrap

[Proposal guide](../index.mdx) · [Open work](../roadmap.md)

Source-local compilation, semantic products, linking, bounded publication, and seed provenance.

Each record appears in one catalog. Cross-cutting work links its other owners from the proposal itself. Implemented records describe the evidence and bounds at that milestone, not the current whole-system profile.

| WIP | Status | Decision |
| --- | --- | --- |
| [WIP-0007](../WIP-0007-self-hosting-compiler-and-bootstrap.md) | Implementing | Self-hosting compiler and reproducible bootstrap |
| [WIP-0043](../WIP-0043-bounded-generic-compiler-module-graph-execution.md) | Implemented | Bounded generic compiler module graph execution |
| [WIP-0044](../WIP-0044-counted-native-compiler-closure-execution.md) | Implementing | Counted native compiler closure execution |
| [WIP-0045](../WIP-0045-counted-native-module-symbol-products.md) | Implementing | Counted native module symbol products |
| [WIP-0046](../WIP-0046-counted-native-aggregate-layout-products.md) | Implementing | Counted native aggregate layout products |
| [WIP-0047](../WIP-0047-counted-native-callable-bytecode-products.md) | Implementing | Counted native callable bytecode products |
| [WIP-0048](../WIP-0048-canonical-native-product-linker.md) | Implementing | Canonical native product linker |
| [WIP-0049](../WIP-0049-bounded-native-source-product-compilation.md) | Implementing | Bounded native source-product compilation |
| [WIP-0050](../WIP-0050-native-aggregate-source-lowering.md) | Implemented | Native aggregate source lowering |
| [WIP-0051](../WIP-0051-native-aggregate-frontend-products.md) | Implementing | Native aggregate frontend products |
| [WIP-0052](../WIP-0052-bounded-native-structured-loop-products.md) | Implemented | Bounded native structured-loop products |
| [WIP-0053](../WIP-0053-auditable-bootstrap-seed-chain.md) | Draft | Auditable bootstrap seed chain |
| [WIP-0054](../WIP-0054-native-source-product-artifact-integration.md) | Implementing | Native source-product artifact integration |
| [WIP-0055](../WIP-0055-source-ordered-callable-coordinate-products.md) | Implemented | Source-ordered callable coordinate products |
| [WIP-0056](../WIP-0056-measured-source-statement-local-products.md) | Implemented | Measured source statement local products |
| [WIP-0057](../WIP-0057-source-call-relocation-and-ownership-coordinate-products.md) | Implemented | Source call, relocation, and ownership coordinate products |
| [WIP-0058](../WIP-0058-nested-source-call-window-products.md) | Implemented | Nested source call window products |
| [WIP-0059](../WIP-0059-imported-source-call-target-products.md) | Implemented | Imported source call target products |
| [WIP-0060](../WIP-0060-imported-call-stub-and-relocation-products.md) | Implemented | Imported call stub and relocation products |
| [WIP-0061](../WIP-0061-qualified-imported-source-calls.md) | Implemented | Qualified imported source calls |
| [WIP-0062](../WIP-0062-atomic-source-call-link-publication.md) | Implemented | Atomic source-call link publication |
| [WIP-0063](../WIP-0063-generated-inverse-coordinate-products.md) | Implemented | Generated inverse coordinate products |
| [WIP-0064](../WIP-0064-reversible-source-product-evidence.md) | Implemented | Reversible source-product evidence |
| [WIP-0065](../WIP-0065-reversible-call-and-result-portfolio.md) | Implemented | Reversible call and result portfolio |
| [WIP-0066](../WIP-0066-boolean-reversible-result-slots.md) | Implemented | Boolean reversible result slots |
| [WIP-0067](../WIP-0067-exact-physical-loop-value-products.md) | Implemented | Exact physical loop-value products |
| [WIP-0068](../WIP-0068-callable-free-source-product-artifacts.md) | Implemented | Callable-free source-product artifacts |
| [WIP-0069](../WIP-0069-exact-scalar-return-expression-products.md) | Implemented | Exact scalar return-expression products |
| [WIP-0070](../WIP-0070-exact-scalar-declaration-products.md) | Implemented | Exact scalar declaration products |
| [WIP-0071](../WIP-0071-exact-root-byte-mutation-products.md) | Implemented | Exact root byte-mutation products |
| [WIP-0072](../WIP-0072-exact-root-byte-projection-products.md) | Implemented | Exact root byte-projection products |
| [WIP-0073](../WIP-0073-exact-root-conditional-return-products.md) | Implemented | Exact root conditional-return products |
| [WIP-0074](../WIP-0074-direct-conditional-classifier-adoption.md) | Implemented | Direct conditional-classifier adoption |
| [WIP-0075](../WIP-0075-exact-computed-conditional-return-products.md) | Implemented | Exact computed conditional-return products |
| [WIP-0076](../WIP-0076-direct-range-decoder-adoption.md) | Implemented | Direct range-decoder adoption |
| [WIP-0077](../WIP-0077-exact-constant-return-products.md) | Implemented | Exact constant-return products |
| [WIP-0078](../WIP-0078-bounded-direct-conditional-lookups.md) | Implemented | Bounded direct-conditional lookups |
| [WIP-0079](../WIP-0079-exact-signed-literal-return-products.md) | Implemented | Exact signed-literal return products |
| [WIP-0080](../WIP-0080-exact-root-boolean-declaration-products.md) | Implemented | Exact root Boolean declaration products |
| [WIP-0081](../WIP-0081-direct-leaf-assignment-classifier-adoption.md) | Implemented | Direct leaf assignment-classifier adoption |
| [WIP-0082](../WIP-0082-exact-boolean-equality-products.md) | Implemented | Exact Boolean equality products |
| [WIP-0083](../WIP-0083-zero-allocation-unobserved-transitions.md) | Implemented | Zero-allocation unobserved transitions |
| [WIP-0084](../WIP-0084-direct-comparison-classifier-adoption.md) | Implemented | Direct comparison-classifier adoption |
| [WIP-0085](../WIP-0085-root-task-state-specialization.md) | Implemented | Root task state specialization |
| [WIP-0086](../WIP-0086-direct-named-scalar-classifier-adoption.md) | Implemented | Direct named scalar-classifier adoption |
| [WIP-0087](../WIP-0087-bounded-direct-product-publication.md) | Implemented | Bounded direct-product publication |
| [WIP-0088](../WIP-0088-direct-comparison-operand-classifier-adoption.md) | Implemented | Direct comparison-operand classifier adoption |
| [WIP-0089](../WIP-0089-direct-signed-return-classifier-adoption.md) | Implemented | Direct signed return-classifier adoption |
| [WIP-0090](../WIP-0090-direct-arithmetic-return-classifier-adoption.md) | Implemented | Direct arithmetic return-classifier adoption |
| [WIP-0091](../WIP-0091-direct-literal-condition-classifier-adoption.md) | Implemented | Direct literal-condition classifier adoption |
| [WIP-0092](../WIP-0092-direct-conditional-value-classifier-adoption.md) | Implemented | Direct conditional-value classifier adoption |
| [WIP-0093](../WIP-0093-direct-assertion-range-decoder-adoption.md) | Implemented | Direct assertion range-decoder adoption |
| [WIP-0094](../WIP-0094-direct-local-assignment-range-adoption.md) | Implemented | Direct local-assignment range adoption |
| [WIP-0095](../WIP-0095-direct-boolean-declaration-classifier-adoption.md) | Implemented | Direct Boolean declaration-classifier adoption |
| [WIP-0096](../WIP-0096-direct-local-loop-classifier-adoption.md) | Implemented | Direct local-loop classifier adoption |
| [WIP-0097](../WIP-0097-projection-free-direct-physical-routing.md) | Implemented | Projection-free direct physical routing |
| [WIP-0098](../WIP-0098-early-callable-free-archive-publication.md) | Implemented | Early callable-free archive publication |
| [WIP-0099](../WIP-0099-exact-boolean-literal-return-products.md) | Implemented | Exact Boolean literal return products |
| [WIP-0100](../WIP-0100-direct-local-loop-form-adoption.md) | Implemented | Direct local-loop form adoption |
| [WIP-0101](../WIP-0101-direct-boolean-return-classifier-adoption.md) | Implemented | Direct Boolean return-classifier adoption |
| [WIP-0102](../WIP-0102-compact-empty-imported-target-views.md) | Implemented | Compact empty imported-target views |
| [WIP-0103](../WIP-0103-direct-conditional-operand-decoder-adoption.md) | Implemented | Direct conditional-operand decoder adoption |
| [WIP-0104](../WIP-0104-direct-local-return-decoder-adoption.md) | Implemented | Direct local-return decoder adoption |
| [WIP-0105](../WIP-0105-sparse-zero-owned-buffer-pages.md) | Implemented | Sparse zero owned-buffer pages |
| [WIP-0106](../WIP-0106-direct-local-update-decoder-adoption.md) | Implemented | Direct local-update decoder adoption |
| [WIP-0107](../WIP-0107-direct-return-opcode-selector-adoption.md) | Implemented | Direct return-opcode selector adoption |
| [WIP-0108](../WIP-0108-direct-boolean-token-classifier-adoption.md) | Implemented | Direct Boolean token-classifier adoption |
| [WIP-0109](../WIP-0109-direct-identifier-start-classifier-adoption.md) | Implemented | Direct identifier-start classifier adoption |
| [WIP-0110](../WIP-0110-direct-call-argument-source-classifier-adoption.md) | Implemented | Direct call-argument source-classifier adoption |
| [WIP-0111](../WIP-0111-direct-one-argument-call-classifier-adoption.md) | Implemented | Direct one-argument call-classifier adoption |
| [WIP-0112](../WIP-0112-direct-three-argument-call-syntax-adoption.md) | Implemented | Direct three-argument call-syntax adoption |
| [WIP-0113](../WIP-0113-direct-two-argument-call-classifier-adoption.md) | Implemented | Direct two-argument call-classifier adoption |
| [WIP-0114](../WIP-0114-direct-resolved-local-conditional-classifier-adoption.md) | Implemented | Direct resolved local-conditional classifier adoption |
| [WIP-0115](../WIP-0115-root-committed-transition-dispatch.md) | Implemented | Root committed-transition dispatch |
| [WIP-0116](../WIP-0116-direct-resolved-local-conditional-source-adoption.md) | Implemented | Direct resolved local-conditional source adoption |
| [WIP-0117](../WIP-0117-direct-early-return-result-classifier-adoption.md) | Implemented | Direct early-return result-classifier adoption |
| [WIP-0118](../WIP-0118-direct-void-call-source-classifier-adoption.md) | Implemented | Direct void-call source-classifier adoption |
| [WIP-0119](../WIP-0119-direct-early-return-source-decoder-adoption.md) | Implemented | Direct early-return source-decoder adoption |
| [WIP-0120](../WIP-0120-direct-resolved-void-call-adoption.md) | Implemented | Direct resolved void-call adoption |
| [WIP-0121](../WIP-0121-direct-assignment-call-column-adoption.md) | Implemented | Direct assignment-call column adoption |
| [WIP-0122](../WIP-0122-direct-assignment-call-arity-adoption.md) | Implemented | Direct assignment-call arity adoption |
| [WIP-0123](../WIP-0123-exact-call-conditioned-literal-return-products.md) | Implemented | Exact call-conditioned literal-return products |
| [WIP-0124](../WIP-0124-direct-call-argument-encoding-adoption.md) | Implemented | Direct call-argument encoding adoption |
| [WIP-0125](../WIP-0125-lazy-committed-root-status-publication.md) | Implemented | Lazy committed root-status publication |
| [WIP-0126](../WIP-0126-direct-named-local-conditional-adoption.md) | Implemented | Direct named local-conditional adoption |
| [WIP-0127](../WIP-0127-direct-resolved-forwarding-call-decoder-adoption.md) | Implemented | Direct resolved forwarding-call decoder adoption |
| [WIP-0134](../WIP-0134-single-pass-committed-vm-storage.md) | Implemented | Single-pass committed VM storage |
| [WIP-0135](../WIP-0135-exact-call-conditioned-constant-return-products.md) | Implemented | Exact call-conditioned constant-return products |
| [WIP-0136](../WIP-0136-exact-call-conditioned-signed-literal-products.md) | Implemented | Exact call-conditioned signed-literal products |
| [WIP-0137](../WIP-0137-direct-helper-signature-adoption.md) | Implemented | Direct helper-signature adoption |
| [WIP-0138](../WIP-0138-direct-borrowed-intrinsic-shape-adoption.md) | Implemented | Direct borrowed-intrinsic shape adoption |
| [WIP-0139](../WIP-0139-structured-imported-call-product-foundations.md) | Implemented | Structured imported-call product foundations |
| [WIP-0140](../WIP-0140-direct-void-call-syntax-physical-product.md) | Implemented | Direct void-call syntax physical product |
| [WIP-0141](../WIP-0141-direct-assignment-call-width-products.md) | Implemented | Direct assignment-call width products |
| [WIP-0142](../WIP-0142-direct-void-call-form-and-width-products.md) | Implemented | Direct void-call form and width products |
| [WIP-0143](../WIP-0143-direct-early-comparison-form-product.md) | Implemented | Direct early-comparison form product |
| [WIP-0144](../WIP-0144-private-structured-instruction-target-staging.md) | Implemented | Private structured instruction-target staging |
| [WIP-0145](../WIP-0145-sparse-structured-instruction-target-publication.md) | Implemented | Sparse structured instruction-target publication |
| [WIP-0146](../WIP-0146-sparse-imported-target-publication.md) | Implemented | Sparse imported-target publication |
| [WIP-0147](../WIP-0147-sparse-source-call-target-table-publication.md) | Implemented | Sparse source-call target-table publication |
| [WIP-0148](../WIP-0148-sparse-referenced-call-target-publication.md) | Implemented | Sparse referenced call-target publication |
| [WIP-0149](../WIP-0149-direct-assignment-call-kind-product.md) | Implemented | Direct assignment-call kind product |
| [WIP-0150](../WIP-0150-sparse-source-value-publication.md) | Implemented | Sparse source-value publication |
| [WIP-0151](../WIP-0151-sparse-loop-body-publication.md) | Implemented | Sparse loop-body publication |
| [WIP-0153](../WIP-0153-sparse-source-loop-publication.md) | Implemented | Sparse source-loop publication |
| [WIP-0154](../WIP-0154-sparse-source-block-publication.md) | Implemented | Sparse source-block publication |
| [WIP-0155](../WIP-0155-sparse-physical-loop-publication.md) | Implemented | Sparse physical-loop publication |
| [WIP-0156](../WIP-0156-sparse-source-call-layout-publication.md) | Implemented | Sparse source-call layout publication |
| [WIP-0157](../WIP-0157-sparse-call-emission-publication.md) | Implemented | Sparse call-emission publication |
| [WIP-0158](../WIP-0158-committed-owned-storage.md) | Implemented | Committed owned storage |
| [WIP-0159](../WIP-0159-sparse-callable-composition-publication.md) | Implemented | Sparse callable-composition publication |
| [WIP-0160](../WIP-0160-sparse-callable-coordinate-publication.md) | Implemented | Sparse callable-coordinate publication |
| [WIP-0161](../WIP-0161-sparse-call-instruction-publication.md) | Implemented | Sparse call-instruction publication |
| [WIP-0162](../WIP-0162-sparse-callable-return-publication.md) | Implemented | Sparse callable-return publication |
| [WIP-0163](../WIP-0163-sparse-reversible-evidence-publication.md) | Implemented | Sparse reversible-evidence publication |
| [WIP-0164](../WIP-0164-sparse-compiled-function-publication.md) | Implemented | Sparse compiled-function publication |
| [WIP-0165](../WIP-0165-bounded-source-artifact-publication.md) | Implemented | Bounded source-artifact publication |
| [WIP-0166](../WIP-0166-sparse-archive-source-index-publication.md) | Implemented | Sparse archive-source index publication |
| [WIP-0167](../WIP-0167-bounded-structured-artifact-publication.md) | Implemented | Bounded structured-artifact publication |
| [WIP-0168](../WIP-0168-direct-call-form-physical-product.md) | Implemented | Direct call-form physical product |
| [WIP-0169](../WIP-0169-direct-helper-result-kind-physical-product.md) | Implemented | Direct helper-result kind physical product |
| [WIP-0170](../WIP-0170-direct-helper-value-kind-physical-product.md) | Implemented | Direct helper-value kind physical product |
| [WIP-0171](../WIP-0171-direct-void-call-operand-physical-product.md) | Implemented | Direct void-call operand physical product |
| [WIP-0172](../WIP-0172-direct-assignment-call-operand-physical-product.md) | Implemented | Direct assignment-call operand physical product |
| [WIP-0173](../WIP-0173-sparse-source-aggregate-publication.md) | Implemented | Sparse source-aggregate publication |
| [WIP-0174](../WIP-0174-sparse-counted-aggregate-projection.md) | Implemented | Sparse counted-aggregate projection |
| [WIP-0175](../WIP-0175-sparse-aggregate-operation-publication.md) | Implemented | Sparse aggregate-operation publication |
| [WIP-0176](../WIP-0176-sparse-aggregate-target-publication.md) | Implemented | Sparse aggregate-target publication |
| [WIP-0177](../WIP-0177-sparse-aggregate-frontend-binding-publication.md) | Implemented | Sparse aggregate frontend-binding publication |
| [WIP-0178](../WIP-0178-sparse-primitive-placeholder-projection.md) | Implemented | Sparse primitive-placeholder projection |
| [WIP-0179](../WIP-0179-sparse-aggregate-instruction-composition.md) | Implemented | Sparse aggregate-instruction composition |
| [WIP-0180](../WIP-0180-sparse-nominal-projection-publication.md) | Implemented | Sparse nominal-projection publication |
| [WIP-0181](../WIP-0181-sparse-aggregate-body-product-transfer.md) | Implemented | Sparse aggregate body-product transfer |
| [WIP-0182](../WIP-0182-sparse-aggregate-expression-values.md) | Implemented | Sparse aggregate-expression values |
| [WIP-0183](../WIP-0183-sparse-aggregate-owner-publication.md) | Implemented | Sparse aggregate-owner publication |
| [WIP-0184](../WIP-0184-sparse-aggregate-ownership-projection.md) | Implemented | Sparse aggregate ownership projection |
| [WIP-0185](../WIP-0185-sparse-ownership-coordinate-publication.md) | Implemented | Sparse ownership-coordinate publication |
| [WIP-0186](../WIP-0186-sparse-local-nominal-carrier-rewrite.md) | Implemented | Sparse local nominal-carrier rewrite |
| [WIP-0187](../WIP-0187-sparse-nominal-reference-publication.md) | Implemented | Sparse nominal-reference publication |
| [WIP-0188](../WIP-0188-sparse-loop-instruction-staging.md) | Implemented | Sparse loop-instruction staging |
| [WIP-0189](../WIP-0189-sparse-aggregate-operation-staging.md) | Implemented | Sparse aggregate-operation staging |
| [WIP-0190](../WIP-0190-bounded-qualified-call-width-publication.md) | Implemented | Bounded qualified-call width publication |
| [WIP-0191](../WIP-0191-available-callable-dependency-products.md) | Implemented | Available callable dependency products |
| [WIP-0192](../WIP-0192-bounded-direct-result-type-publication.md) | Implemented | Bounded direct result-type publication |
| [WIP-0193](../WIP-0193-terminal-aggregate-operation-failure.md) | Implemented | Terminal aggregate-operation failure |
| [WIP-0391](../WIP-0391-boolean-local-equality-guard-returns.md) | Implemented | Boolean-local equality guard returns |
| [WIP-0392](../WIP-0392-physical-bootstrap-manifest-primitives.md) | Implemented | Physical bootstrap manifest primitives |
| [WIP-0393](../WIP-0393-mixed-scalar-wide-call-sources.md) | Implemented | Mixed scalar wide-call sources |
| [WIP-0394](../WIP-0394-mixed-boolean-wide-call-results.md) | Implemented | Mixed Boolean wide-call results |
| [WIP-0411](../WIP-0411-closed-assignment-and-wide-call-products.md) | Implemented | Closed assignment and wide-call source products |
| [WIP-0413](../WIP-0413-closed-guarded-utf8-call-product.md) | Implemented | Closed guarded UTF-8 call product |
| [WIP-0414](../WIP-0414-bounded-signed-helper-result-owner.md) | Implemented | Bounded signed helper-result ownership |
| [WIP-0415](../WIP-0415-retained-manifest-assertion-product.md) | Implemented | Retained manifest assertion product |
| [WIP-0416](../WIP-0416-boolean-source-conditional-return-products.md) | Implemented | Boolean-source conditional return products |
| [WIP-0417](../WIP-0417-utf8-loop-projection-products.md) | Implemented | UTF-8 loop projection products |
| [WIP-0418](../WIP-0418-focused-loop-arithmetic-declarations.md) | Implemented | Focused loop arithmetic declarations |
| [WIP-0419](../WIP-0419-local-right-nested-loop-guards.md) | Implemented | Local-right nested loop guards |
| [WIP-0490](../WIP-0490-exact-root-word-mutation-products.md) | Implemented | Exact root word-mutation products |
