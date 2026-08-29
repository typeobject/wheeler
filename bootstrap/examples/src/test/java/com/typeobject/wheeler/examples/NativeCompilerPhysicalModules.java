package com.typeobject.wheeler.examples;

import java.util.List;

/** Owns the canonical physical-module product evidence set. */
final class NativeCompilerPhysicalModules {
  private NativeCompilerPhysicalModules() {}

  static List<NativeCompilerArchiveClosureProgram.PhysicalModule> all() {
    return List.of(
        physical("compiler/syntax/calls/assignment/AssignmentCallArities.w", "assignment_call_arities"),
        physical("compiler/syntax/calls/assignment/AssignmentCallColumns.w", "assignment_call_columns"),
        physical("compiler/syntax/calls/assignment/AssignmentCallIdentities.w", "assignment_call_identities"),
        physical("compiler/syntax/BooleanDeclarationKinds.w", "boolean_declaration_kinds"),
        physical("compiler/syntax/booleans/BooleanTokens.w", "boolean_tokens"),
        physical("compiler/syntax/intrinsics/BorrowedIntrinsicKinds.w", "borrowed_intrinsic_kinds"),
        physical("compiler/frontend/intrinsics/BorrowedIntrinsicShapes.w", "borrowed_intrinsic_shapes"),
        physical("compiler/syntax/calls/CallArgumentSources.w", "call_argument_sources"),
        physical("compiler/backend/calls/CallArguments.w", "call_arguments"),
        physical("compiler/ir/limits/CompilerProgramLimits.w", "compiler_program_limits"),
        physical("compiler/syntax/tokens/CompilerTokenLimits.w", "compiler_token_limits"),
        physical("compiler/syntax/EarlyReturnKinds.w", "early_return_kinds"),
        physical("compiler/syntax/EarlyReturnResultKinds.w", "early_return_result_kinds"),
        physical("compiler/syntax/returns/EarlyReturnSources.w", "early_return_sources"),
        physical("compiler/syntax/conditionals/EarlyUtf8CallForms.w", "early_utf8_call_forms"),
        physical("compiler/backend/EncodingWidths.w", "encoding_widths"),
        physical("compiler/syntax/calls/FourArgumentCalls.w", "four_argument_calls"),
        physical("compiler/syntax/helpers/HelperAbi.w", "helper_abi"),
        physical("compiler/syntax/helpers/HelperSignatures.w", "helper_signatures"),
        physical("compiler/syntax/IdentifierStarts.w", "identifier_starts"),
        physical("compiler/ir/InstructionForms.w", "instruction_forms"),
        physical("compiler/syntax/tokens/KeywordTokens.w", "keyword_tokens"),
        physical("compiler/syntax/conditionals/LiteralComparisonOperations.w", "literal_comparison_operations"),
        physical("compiler/backend/types/LocalTypeEncoding.w", "local_type_encoding"),
        physical("compiler/syntax/LoopKinds.w", "loop_kinds"),
        physical("compiler/syntax/loops/LoopBodyOpcodes.w", "loop_body_opcodes"),
        physical("compiler/closure/layouts/source/carriers/LoopBodyLayouts.w", "closure.loop_body_layouts"),
        physical("compiler/syntax/returns/NamedBooleanReturnKinds.w", "named_boolean_return_kinds"),
        physical("compiler/syntax/comparisons/NamedComparisonKinds.w", "named_comparison_kinds"),
        physical("compiler/syntax/conditionals/NamedConditionalBases.w", "named_conditional_bases"),
        physical("compiler/syntax/conditionals/NamedLiteralComparisonKinds.w", "named_literal_comparison_kinds"),
        physical("compiler/syntax/assignments/NamedLocalAssignmentKinds.w", "named_local_assignment_kinds"),
        physical("compiler/syntax/conditionals/NamedLocalConditionalKinds.w", "named_local_conditional_kinds"),
        physical("compiler/syntax/conditionals/NamedLocalConditionalValues.w", "named_local_conditional_values"),
        physical("compiler/syntax/updates/NamedLocalUpdateKinds.w", "named_local_update_kinds"),
        physical("compiler/syntax/locals/NamedLongOperations.w", "named_long_operations"),
        physical("compiler/syntax/returns/NamedReturnArithmeticKinds.w", "named_return_arithmetic_kinds"),
        physical("compiler/syntax/returns/NamedReturnComparisonOperands.w", "named_return_comparison_operands"),
        physical("compiler/syntax/returns/NamedSignedReturnKinds.w", "named_signed_return_kinds"),
        physical("compiler/syntax/calls/OneArgumentCalls.w", "one_argument_calls"),
        physical("compiler/ir/OpcodeKinds.w", "opcode_kinds"),
        physical("compiler/ir/Opcodes.w", "opcodes"),
        physical("compiler/ir/ProofRules.w", "proof_rules"),
        physical("compiler/syntax/assertions/ResolvedBooleanLiteralAssertions.w", "resolved_boolean_literal_assertions"),
        physical("compiler/syntax/booleans/ResolvedBooleanLiteralComparisons.w", "resolved_boolean_literal_comparisons"),
        physical("compiler/syntax/returns/ResolvedEarlyComparisonKinds.w", "resolved_early_comparison_kinds"),
        physical("compiler/syntax/returns/ResolvedEarlyResultKinds.w", "resolved_early_result_kinds"),
        physical("compiler/syntax/assertions/ResolvedLessThanAssertions.w", "resolved_less_than_assertions"),
        physical("compiler/syntax/conditionals/ResolvedLiteralComparisonKinds.w", "resolved_literal_comparison_kinds"),
        physical("compiler/syntax/assignments/ResolvedLocalAssignments.w", "resolved_local_assignments"),
        physical("compiler/syntax/conditionals/ResolvedLocalConditionalKinds.w", "resolved_local_conditional_kinds"),
        physical("compiler/syntax/conditionals/ResolvedLocalConditionalOperands.w", "resolved_local_conditional_operands"),
        physical("compiler/syntax/conditionals/ResolvedLocalConditionalSources.w", "resolved_local_conditional_sources"),
        physical("compiler/syntax/locals/ResolvedLocalCopyKinds.w", "resolved_local_copy_kinds"),
        physical("compiler/syntax/locals/ResolvedLocalEqualityKinds.w", "resolved_local_equality_kinds"),
        physical("compiler/syntax/locals/ResolvedLocalInequalityKinds.w", "resolved_local_inequality_kinds"),
        physical("compiler/syntax/locals/ResolvedLocalLessThanKinds.w", "resolved_local_less_than_kinds"),
        physical("compiler/syntax/locals/ResolvedLocalLiteralComparisonSources.w", "resolved_local_literal_comparison_sources"),
        physical("compiler/syntax/locals/ResolvedLocalLiteralComparisons.w", "resolved_local_literal_comparisons"),
        physical("compiler/syntax/loops/ResolvedLocalLoopForms.w", "resolved_local_loop_forms"),
        physical("compiler/syntax/loops/ResolvedLocalLoopKinds.w", "resolved_local_loop_kinds"),
        physical("compiler/syntax/loops/ResolvedLocalLoopOperands.w", "resolved_local_loop_operands"),
        physical("compiler/syntax/assertions/ResolvedLocalPairAssertions.w", "resolved_local_pair_assertions"),
        physical("compiler/syntax/returns/ResolvedLocalReturns.w", "resolved_local_returns"),
        physical(
            "compiler/syntax/returns/signed/ResolvedLocalResultKinds.w",
            "resolved_local_result_kinds"),
        physical(
            "compiler/syntax/returns/signed/ResolvedLocalReturnStatements.w",
            "resolved_local_return_statements"),
        physical("compiler/syntax/updates/ResolvedLocalUpdates.w", "resolved_local_updates"),
        physical("compiler/syntax/locals/ResolvedLongOperations.w", "resolved_long_operations"),
        physical(
            "compiler/syntax/returns/forwarded/ForwardedHelperResultKinds.w",
            "forwarded_helper_result_kinds"),
        physical(
            "compiler/syntax/returns/forwarded/ForwardedHelperResultStatements.w",
            "forwarded_helper_result_statements"),
        physical("compiler/syntax/returns/ResolvedReturnCallKinds.w", "resolved_return_call_kinds"),
        physical("compiler/ir/ResolvedStatements.w", "resolved_statements"),
        physical("compiler/verification/ResultSlotVerifier.w", "result_slot_verifier"),
        physical("compiler/resolution/returns/ReturnOpcodeKinds.w", "return_opcode_kinds"),
        physical("compiler/syntax/tokens/SourceScalars.w", "source_scalars"),
        physical("compiler/ir/StatementKinds.w", "statement_kinds"),
        physical(
            "compiler/syntax/returns/signed/SignedReturnStatements.w",
            "signed_return_statements"),
        physical("compiler/ir/StorageOpcodes.w", "storage_opcodes"),
        physical("compiler/syntax/calls/ThreeArgumentCalls.w", "three_argument_calls"),
        physical("compiler/syntax/calls/TwoArgumentCallKinds.w", "two_argument_call_kinds"),
        physical("compiler/ir/TypeCodes.w", "type_codes"),
        physical("compiler/ir/TypeKinds.w", "type_kinds"),
        physical("compiler/syntax/calls/VoidCallKinds.w", "void_call_kinds"),
        physical("compiler/syntax/calls/VoidCallSourceKinds.w", "void_call_source_kinds"),
        physical("compiler/resolution/returns/WideReturnSources.w", "wide_return_sources"),
        physical(
            "compiler/packages/PackageManifestTokens.w",
            "packages.manifest_tokens"),
        physical("compiler/packages/Names.w", "packages.names"),
        physical("compiler/packages/Paths.w", "packages.paths"),
        physical("compiler/packages/semver/SemverCoreValidation.w", "packages.semver_core_validation"),
        physical("compiler/packages/semver/SemverCoordinates.w", "packages.semver_coordinates"),
        physical(
            "compiler/closure/layouts/AggregateSourceProjection.w",
            "closure.aggregate_source_projection"),
        physical(
            "compiler/closure/syntax/ManifestAssertions.w",
            "closure.manifest_assertions"),
        physical(
            "compiler/closure/syntax/ManifestProfile.w",
            "closure.manifest_profile"),
        physical("compiler/closure/ManifestSyntax.w", "closure.manifest_syntax"),
        physical(
            "compiler/closure/products/source/coordinates/ReversibleTokenCoordinates.w",
            "closure.reversible_token_coordinates"),
        physical("compiler/backend/core/CoreParsing.w", "core_parsing"));
  }

  static List<NativeCompilerArchiveClosureProgram.PhysicalModule> importedCallableProducts() {
    return List.of(
        physical("compiler/syntax/calls/assignment/AssignmentCallCodeWidths.w", "assignment_call_code_widths"),
        physical("compiler/syntax/calls/assignment/AssignmentCallInstructionWidths.w", "assignment_call_instruction_widths"),
        physical("compiler/syntax/calls/assignment/AssignmentCallKinds.w", "assignment_call_kinds"),
        physical("compiler/syntax/calls/assignment/AssignmentCallLocalWidths.w", "assignment_call_local_widths"),
        physical("compiler/syntax/calls/assignment/AssignmentCallOperands.w", "assignment_call_operands"),
        physical("compiler/syntax/calls/assignment/AssignmentCallSyntax.w", "assignment_call_syntax"),
        physical("compiler/syntax/CallForms.w", "call_forms"),
        physical("compiler/syntax/returns/EarlyComparisonForms.w", "early_comparison_forms"),
        physical("compiler/syntax/helpers/HelperResultKinds.w", "helper_result_kinds"),
        physical(
            "compiler/syntax/helpers/SignedHelperResultKinds.w",
            "signed_helper_result_kinds"),
        physical("compiler/syntax/helpers/HelperValueKinds.w", "helper_value_kinds"),
        physical("compiler/syntax/calls/void/VoidCallOperands.w", "void_call_operands"),
        physical("compiler/frontend/calls/VoidCallSyntax.w", "void_call_syntax"),
        physical("compiler/syntax/calls/void/VoidCallSourceForms.w", "void_call_source_forms"),
        physical("compiler/syntax/calls/VoidCallSourceWidths.w", "void_call_source_widths"),
        physical("compiler/syntax/calls/VoidCallWidths.w", "void_call_widths"),
        physical("compiler/syntax/calls/WideLocalCalls.w", "wide_local_calls"),
        physical(
            "compiler/packages/semver/SemverPrereleaseValidation.w",
            "packages.semver_prerelease_validation"),
        physical(
            "compiler/packages/semver/SemverIdentifierComparison.w",
            "packages.semver_identifier_comparison"),
        physical(
            "compiler/packages/semver/SemverCoreComparison.w",
            "packages.semver_core_comparison"),
        physical(
            "compiler/packages/semver/SemverPrereleaseComparison.w",
            "packages.semver_prerelease_comparison"),
        physical(
            "compiler/packages/semver/SemverReleaseComparison.w",
            "packages.semver_release_comparison"),
        physical("compiler/packages/semver/Semver.w", "packages.semver"));
  }

  private static NativeCompilerArchiveClosureProgram.PhysicalModule physical(
      String path, String localName) {
    return new NativeCompilerArchiveClosureProgram.PhysicalModule(
        path, "wheeler.compiler." + localName);
  }
}
