package com.typeobject.wheeler.examples;

import java.util.List;

/** Owns the canonical physical-module product evidence set. */
final class NativeCompilerPhysicalModules {
  private NativeCompilerPhysicalModules() {}

  static List<NativeCompilerArchiveClosureProgram.PhysicalModule> all() {
    return List.of(
        physical(3, "compiler/syntax/calls/assignment/AssignmentCallArities.w", "assignment_call_arities"),
        physical(6, "compiler/syntax/calls/assignment/AssignmentCallColumns.w", "assignment_call_columns"),
        physical(7, "compiler/syntax/calls/assignment/AssignmentCallIdentities.w", "assignment_call_identities"),
        physical(16, "compiler/syntax/BooleanDeclarationKinds.w", "boolean_declaration_kinds"),
        physical(18, "compiler/syntax/booleans/BooleanTokens.w", "boolean_tokens"),
        physical(20, "compiler/syntax/intrinsics/BorrowedIntrinsicKinds.w", "borrowed_intrinsic_kinds"),
        physical(22, "compiler/frontend/intrinsics/BorrowedIntrinsicShapes.w", "borrowed_intrinsic_shapes"),
        physical(24, "compiler/syntax/calls/CallArgumentSources.w", "call_argument_sources"),
        physical(25, "compiler/backend/calls/CallArguments.w", "call_arguments"),
        physical(126, "compiler/ir/limits/CompilerProgramLimits.w", "compiler_program_limits"),
        physical(127, "compiler/syntax/tokens/CompilerTokenLimits.w", "compiler_token_limits"),
        physical(136, "compiler/syntax/EarlyReturnKinds.w", "early_return_kinds"),
        physical(138, "compiler/syntax/EarlyReturnResultKinds.w", "early_return_result_kinds"),
        physical(139, "compiler/syntax/returns/EarlyReturnSources.w", "early_return_sources"),
        physical(145, "compiler/backend/EncodingWidths.w", "encoding_widths"),
        physical(148, "compiler/syntax/calls/FourArgumentCalls.w", "four_argument_calls"),
        physical(162, "compiler/syntax/helpers/HelperAbi.w", "helper_abi"),
        physical(170, "compiler/syntax/helpers/HelperSignatures.w", "helper_signatures"),
        physical(173, "compiler/syntax/IdentifierStarts.w", "identifier_starts"),
        physical(175, "compiler/ir/InstructionForms.w", "instruction_forms"),
        physical(178, "compiler/syntax/tokens/KeywordTokens.w", "keyword_tokens"),
        physical(180, "compiler/syntax/conditionals/LiteralComparisonOperations.w", "literal_comparison_operations"),
        physical(186, "compiler/backend/types/LocalTypeEncoding.w", "local_type_encoding"),
        physical(189, "compiler/syntax/LoopKinds.w", "loop_kinds"),
        physical(195, "compiler/syntax/returns/NamedBooleanReturnKinds.w", "named_boolean_return_kinds"),
        physical(196, "compiler/syntax/comparisons/NamedComparisonKinds.w", "named_comparison_kinds"),
        physical(197, "compiler/syntax/conditionals/NamedConditionalBases.w", "named_conditional_bases"),
        physical(198, "compiler/syntax/conditionals/NamedLiteralComparisonKinds.w", "named_literal_comparison_kinds"),
        physical(199, "compiler/syntax/assignments/NamedLocalAssignmentKinds.w", "named_local_assignment_kinds"),
        physical(200, "compiler/syntax/conditionals/NamedLocalConditionalKinds.w", "named_local_conditional_kinds"),
        physical(201, "compiler/syntax/conditionals/NamedLocalConditionalValues.w", "named_local_conditional_values"),
        physical(202, "compiler/syntax/updates/NamedLocalUpdateKinds.w", "named_local_update_kinds"),
        physical(203, "compiler/syntax/locals/NamedLongOperations.w", "named_long_operations"),
        physical(204, "compiler/syntax/returns/NamedReturnArithmeticKinds.w", "named_return_arithmetic_kinds"),
        physical(205, "compiler/syntax/returns/NamedReturnComparisonOperands.w", "named_return_comparison_operands"),
        physical(206, "compiler/syntax/returns/NamedSignedReturnKinds.w", "named_signed_return_kinds"),
        physical(207, "compiler/syntax/calls/OneArgumentCalls.w", "one_argument_calls"),
        physical(208, "compiler/ir/OpcodeKinds.w", "opcode_kinds"),
        physical(209, "compiler/ir/Opcodes.w", "opcodes"),
        physical(228, "compiler/ir/ProofRules.w", "proof_rules"),
        physical(230, "compiler/syntax/assertions/ResolvedBooleanLiteralAssertions.w", "resolved_boolean_literal_assertions"),
        physical(231, "compiler/syntax/booleans/ResolvedBooleanLiteralComparisons.w", "resolved_boolean_literal_comparisons"),
        physical(232, "compiler/syntax/returns/ResolvedEarlyComparisonKinds.w", "resolved_early_comparison_kinds"),
        physical(233, "compiler/syntax/returns/ResolvedEarlyResultKinds.w", "resolved_early_result_kinds"),
        physical(235, "compiler/syntax/assertions/ResolvedLessThanAssertions.w", "resolved_less_than_assertions"),
        physical(236, "compiler/syntax/conditionals/ResolvedLiteralComparisonKinds.w", "resolved_literal_comparison_kinds"),
        physical(237, "compiler/syntax/assignments/ResolvedLocalAssignments.w", "resolved_local_assignments"),
        physical(238, "compiler/syntax/conditionals/ResolvedLocalConditionalKinds.w", "resolved_local_conditional_kinds"),
        physical(239, "compiler/syntax/conditionals/ResolvedLocalConditionalOperands.w", "resolved_local_conditional_operands"),
        physical(240, "compiler/syntax/conditionals/ResolvedLocalConditionalSources.w", "resolved_local_conditional_sources"),
        physical(241, "compiler/syntax/locals/ResolvedLocalCopyKinds.w", "resolved_local_copy_kinds"),
        physical(242, "compiler/syntax/locals/ResolvedLocalEqualityKinds.w", "resolved_local_equality_kinds"),
        physical(243, "compiler/syntax/locals/ResolvedLocalInequalityKinds.w", "resolved_local_inequality_kinds"),
        physical(244, "compiler/syntax/locals/ResolvedLocalLessThanKinds.w", "resolved_local_less_than_kinds"),
        physical(245, "compiler/syntax/locals/ResolvedLocalLiteralComparisonSources.w", "resolved_local_literal_comparison_sources"),
        physical(246, "compiler/syntax/locals/ResolvedLocalLiteralComparisons.w", "resolved_local_literal_comparisons"),
        physical(247, "compiler/syntax/loops/ResolvedLocalLoopForms.w", "resolved_local_loop_forms"),
        physical(248, "compiler/syntax/loops/ResolvedLocalLoopKinds.w", "resolved_local_loop_kinds"),
        physical(249, "compiler/syntax/loops/ResolvedLocalLoopOperands.w", "resolved_local_loop_operands"),
        physical(250, "compiler/syntax/assertions/ResolvedLocalPairAssertions.w", "resolved_local_pair_assertions"),
        physical(251, "compiler/syntax/returns/ResolvedLocalReturns.w", "resolved_local_returns"),
        physical(252, "compiler/syntax/updates/ResolvedLocalUpdates.w", "resolved_local_updates"),
        physical(253, "compiler/syntax/locals/ResolvedLongOperations.w", "resolved_long_operations"),
        physical(254, "compiler/syntax/returns/ResolvedReturnCallKinds.w", "resolved_return_call_kinds"),
        physical(255, "compiler/ir/ResolvedStatements.w", "resolved_statements"),
        physical(257, "compiler/verification/ResultSlotVerifier.w", "result_slot_verifier"),
        physical(261, "compiler/resolution/returns/ReturnOpcodeKinds.w", "return_opcode_kinds"),
        physical(274, "compiler/syntax/tokens/SourceScalars.w", "source_scalars"),
        physical(275, "compiler/ir/StatementKinds.w", "statement_kinds"),
        physical(279, "compiler/ir/StorageOpcodes.w", "storage_opcodes"),
        physical(284, "compiler/syntax/calls/ThreeArgumentCalls.w", "three_argument_calls"),
        physical(286, "compiler/syntax/calls/TwoArgumentCallKinds.w", "two_argument_call_kinds"),
        physical(287, "compiler/ir/TypeCodes.w", "type_codes"),
        physical(288, "compiler/ir/TypeKinds.w", "type_kinds"),
        physical(291, "compiler/syntax/calls/VoidCallKinds.w", "void_call_kinds"),
        physical(295, "compiler/syntax/calls/VoidCallSourceKinds.w", "void_call_source_kinds"),
        physical(303, "compiler/resolution/returns/WideReturnSources.w", "wide_return_sources"));
  }

  static List<NativeCompilerArchiveClosureProgram.PhysicalModule> importedCallableProducts() {
    return List.of(
        physical(4, "compiler/syntax/calls/assignment/AssignmentCallCodeWidths.w", "assignment_call_code_widths"),
        physical(8, "compiler/syntax/calls/assignment/AssignmentCallInstructionWidths.w", "assignment_call_instruction_widths"),
        physical(9, "compiler/syntax/calls/assignment/AssignmentCallKinds.w", "assignment_call_kinds"),
        physical(10, "compiler/syntax/calls/assignment/AssignmentCallLocalWidths.w", "assignment_call_local_widths"),
        physical(11, "compiler/syntax/calls/assignment/AssignmentCallOperands.w", "assignment_call_operands"),
        physical(26, "compiler/syntax/CallForms.w", "call_forms"),
        physical(134, "compiler/syntax/returns/EarlyComparisonForms.w", "early_comparison_forms"),
        physical(169, "compiler/syntax/helpers/HelperResultKinds.w", "helper_result_kinds"),
        physical(172, "compiler/syntax/helpers/HelperValueKinds.w", "helper_value_kinds"),
        physical(292, "compiler/syntax/calls/void/VoidCallOperands.w", "void_call_operands"),
        physical(294, "compiler/syntax/calls/void/VoidCallSourceForms.w", "void_call_source_forms"),
        physical(297, "compiler/syntax/calls/VoidCallSourceWidths.w", "void_call_source_widths"),
        physical(299, "compiler/syntax/calls/VoidCallWidths.w", "void_call_widths"));
  }

  private static NativeCompilerArchiveClosureProgram.PhysicalModule physical(
      int owner, String path, String localName) {
    return new NativeCompilerArchiveClosureProgram.PhysicalModule(
        owner, path, "wheeler.compiler." + localName);
  }
}
