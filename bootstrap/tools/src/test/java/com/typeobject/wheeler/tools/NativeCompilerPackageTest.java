package com.typeobject.wheeler.tools;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.nio.charset.StandardCharsets;
import java.nio.file.Path;
import java.util.List;
import java.util.Set;
import java.util.concurrent.TimeUnit;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.Timeout;

/** Proves the complete checked-in compiler package suite through the native runner. */
final class NativeCompilerPackageTest {
  @Test
  @Timeout(value = 47, unit = TimeUnit.MINUTES)
  void testsThePhysicalCompilerSpineNatively() throws Exception {
    Path compiler = Path.of("wheeler-compiler");
    PackageProject project = PackageProject.load(compiler);

    var result = NativePackageTestRunner.run(
        compiler, project.manifest(), 0, 1, Set.of()).orElseThrow();
    TestReport report = result.report();

    assertEquals(224, result.selected());
    assertEquals(224, result.passed());
    assertEquals(0, result.failed());
    assertEquals(result.report().identity(), report.identity());
    assertEquals(
        TestReportRenderer.render(report, project.manifest().name(), TestReportRenderer.Format.JSON),
        new String(result.json(), StandardCharsets.UTF_8));
    assertEquals(
        TestReportRenderer.render(
            report, project.manifest().name(), TestReportRenderer.Format.TERMINAL),
        new String(result.terminal(), StandardCharsets.UTF_8));
    assertEquals(
        TestReportRenderer.render(
            report, project.manifest().name(), TestReportRenderer.Format.JUNIT_XML),
        new String(result.junit(), StandardCharsets.UTF_8));

    for (String name : List.of(
        "classifiesFinalLiteralComparisonLessThan",
        "classifiesFinalLiteralComparisonSubtract",
        "classifiesFinalLiteralComparisonXor",
        "classifiesFinalLiteralComparisonAssignment")) {
      assertCase(
          report,
          "nativecompilerliteralcomparisonoperationtests",
          "native_compiler_literal_comparison_operations",
          name);
    }
    for (String name : List.of(
        "mapsFinalNamedLiteralComparisonBase", "mapsFinalNamedLocalConditionalBase")) {
      assertCase(
          report,
          "nativecompilernamedconditionalbasetests",
          "native_compiler_named_conditional_bases",
          name);
    }
    for (String name : List.of(
        "classifiesFirstResolvedEqualityForm", "classifiesFinalResolvedOrderingForm")) {
      assertCase(
          report,
          "nativecompilerearlycomparisonformtests",
          "native_compiler_early_comparison_forms",
          name);
    }
    for (String name : List.of(
        "classifiesFinalEarlyReturn", "mapsFinalEarlyReturnLocalCount")) {
      assertCase(
          report,
          "nativecompilerearlyreturnkindtests",
          "native_compiler_early_return_kinds",
          name);
    }
    for (String name : List.of(
        "classifiesFinalSignedHelperGuardResult",
        "classifiesFinalSignedComparisonGuardResult",
        "classifiesFinalComputedComparisonGuardResult",
        "classifiesComparisonGuardAdditionResult",
        "classifiesComparisonGuardRemainderResult",
        "classifiesComparisonGuardDivisionResult")) {
      assertCase(
          report,
          "nativecompilerearlyreturnresultkindtests",
          "native_compiler_early_return_result_kinds",
          name);
    }
    for (String name : List.of(
        "mapsResolvedLocalBufferLengthWidth",
        "mapsResolvedLocalBufferLengthResult",
        "mapsResolvedUtf8WidthCodeLength",
        "mapsResolvedUtf8WidthInstructionCount")) {
      assertCase(
          report,
          "nativecompilerborrowedintrinsicshapetests",
          "native_compiler_borrowed_intrinsic_shapes",
          name);
    }
    assertCase(
        report,
        "nativecompilercallargumenttests",
        "native_compiler_call_arguments",
        "mapsCallArgumentOpcodes");
    assertCase(
        report,
        "nativecompilerreversibletokentests",
        "native_compiler_reversible_tokens",
        "advancesSourceTokensReversibly");
    for (String name : List.of(
        "classifiesFinalFirstNamedCallArgument", "classifiesFinalSecondNamedCallArgument")) {
      assertCase(
          report,
          "nativecompilercallargumentsourcetests",
          "native_compiler_call_argument_sources",
          name);
    }
    for (String name : List.of(
        "classifiesFinalFourArgumentCall",
        "mapsFinalFourArgumentToken",
        "decodesFinalFourArgumentThirdSource",
        "decodesFinalFourArgumentFourthSource")) {
      assertCase(
          report,
          "nativecompilerfourargumentcalltests",
          "native_compiler_four_argument_calls",
          name);
    }
    for (String name : List.of(
        "classifiesFinalOneArgumentCall",
        "classifiesFinalNamedOneArgumentCall",
        "classifiesFinalBooleanOneArgumentCall",
        "classifiesFinalSignedBooleanOneArgumentCall")) {
      assertCase(
          report,
          "nativecompileroneargumentcalltests",
          "native_compiler_one_argument_calls",
          name);
    }
    for (String name : List.of(
        "classifiesFinalThreeArgumentCall",
        "mapsFinalThreeArgumentFirstToken",
        "mapsFinalThreeArgumentSecondToken",
        "mapsFinalThreeArgumentThirdToken",
        "decodesFinalThreeArgumentSource")) {
      assertCase(
          report,
          "nativecompilerthreeargumentcalltests",
          "native_compiler_three_argument_calls",
          name);
    }
    for (String name : List.of(
        "classifiesFinalTwoArgumentCall",
        "classifiesFinalSignedResultTwoArgumentCall",
        "classifiesFinalBooleanTwoArgumentCall",
        "classifiesFinalSignedBooleanTwoArgumentCall")) {
      assertCase(
          report,
          "nativecompilertwoargumentcallkindtests",
          "native_compiler_two_argument_call_kinds",
          name);
    }
    assertCase(
        report,
        "nativecompilerbooleandeclarationkindtests",
        "native_compiler_boolean_declaration_kinds",
        "classifiesFinalBooleanDeclaration");
    for (String name : List.of(
        "classifiesFinalDirectComparisonReturn",
        "classifiesFinalDirectInequalityReturn",
        "classifiesFinalDirectSignedComparisonReturn")) {
      assertCase(
          report,
          "nativecompilernamedcomparisonkindtests",
          "native_compiler_named_comparison_kinds",
          name);
    }
    assertCase(
        report,
        "nativecompilernamedliteralcomparisonkindtests",
        "native_compiler_named_literal_comparison_kinds",
        "classifiesFinalLiteralComparisonConditional");
    assertCase(
        report,
        "nativecompilernamedlocalassignmentkindtests",
        "native_compiler_named_local_assignment_kinds",
        "classifiesFinalNamedLocalAssignment");
    for (String name : List.of(
        "classifiesFinalNamedLocalConditional",
        "classifiesFinalNegatedNamedLocalConditional",
        "classifiesFinalNamedLocalAssignment",
        "classifiesFinalNamedLocalAssignmentValue")) {
      assertCase(
          report,
          "nativecompilernamedlocalconditionalkindtests",
          "native_compiler_named_local_conditional_kinds",
          name);
    }
    assertCase(
        report,
        "nativecompilernamedlocalconditionalvaluetests",
        "native_compiler_named_local_conditional_values",
        "classifiesFinalNamedConditionalValue");
    for (String name : List.of(
        "classifiesFinalResolvedLiteralComparison",
        "decodesFinalResolvedLiteralComparisonSource")) {
      assertCase(
          report,
          "nativecompilerresolvedliteralcomparisonkindtests",
          "native_compiler_resolved_literal_comparison_kinds",
          name);
    }
    for (String name : List.of(
        "classifiesFinalResolvedLocalConditional",
        "classifiesFinalNegatedResolvedLocalConditional",
        "classifiesFinalResolvedLocalAssignment",
        "classifiesFinalResolvedLocalAssignmentValue")) {
      assertCase(
          report,
          "nativecompilerresolvedlocalconditionalkindtests",
          "native_compiler_resolved_local_conditional_kinds",
          name);
    }
    assertCase(
        report,
        "nativecompilerresolvedlocalconditionaloperandtests",
        "native_compiler_resolved_local_conditional_operands",
        "decodesFinalConditionalSource");
    for (String name : List.of(
        "classifiesFinalResolvedLocalConditionalValue",
        "classifiesFinalResolvedLocalConditionalSubtract",
        "classifiesFinalResolvedLocalConditionalXor")) {
      assertCase(
          report,
          "nativecompilerresolvedlocalconditionalsourcetests",
          "native_compiler_resolved_local_conditional_sources",
          name);
    }
    assertCase(
        report,
        "nativecompilernamedlocalupdatekindtests",
        "native_compiler_named_local_update_kinds",
        "classifiesFinalNamedLocalUpdate");
    for (String name : List.of(
        "mapsFinalNamedLongLiteralBase",
        "mapsFinalNamedLongPairBase",
        "classifiesFinalNamedLongBinary",
        "classifiesFinalNamedLongPair",
        "classifiesFinalNamedGlobalUpdate")) {
      assertCase(
          report,
          "nativecompilernamedlongoperationtests",
          "native_compiler_named_long_operations",
          name);
    }
    for (String name : List.of(
        "classifiesFinalBooleanEqualityReturn",
        "classifiesFinalBooleanInequalityReturn",
        "classifiesFinalBooleanComparisonReturn")) {
      assertCase(
          report,
          "nativecompilernamedbooleanreturnkindtests",
          "native_compiler_named_boolean_return_kinds",
          name);
    }
    for (String name : List.of(
        "classifiesFinalLocalBinaryReturn", "classifiesFinalLocalPairReturn")) {
      assertCase(
          report,
          "nativecompilernamedreturnarithmetickindtests",
          "native_compiler_named_return_arithmetic_kinds",
          name);
    }
    for (String name : List.of(
        "classifiesFinalSignedEqualityReturn",
        "classifiesFinalSignedInequalityReturn",
        "classifiesFinalSignedLessThanReturn")) {
      assertCase(
          report,
          "nativecompilernamedsignedreturnkindtests",
          "native_compiler_named_signed_return_kinds",
          name);
    }
    assertCase(
        report,
        "nativecompilernamedreturncomparisonoperandtests",
        "native_compiler_named_return_comparison_operands",
        "classifiesFinalLocalRightComparison");
    for (String name : List.of(
        "decodesFinalHelperForwardingSource", "decodesFinalComparisonAdditionSource")) {
      assertCase(
          report,
          "nativecompilerearlyreturnsourcetests",
          "native_compiler_early_return_sources",
          name);
    }
    for (String name : List.of(
        "classifiesFinalBooleanLiteralEquality",
        "classifiesFinalBooleanLiteralInequality",
        "classifiesFinalBooleanLiteralComparison",
        "decodesFinalBooleanLiteralComparisonSource")) {
      assertCase(
          report,
          "nativecompilerresolvedbooleanliteralcomparisontests",
          "native_compiler_resolved_boolean_literal_comparisons",
          name);
    }
    for (String name : List.of(
        "classifiesFinalBooleanLiteralAssertion",
        "decodesFinalBooleanLiteralAssertionSource")) {
      assertCase(
          report,
          "nativecompilerresolvedbooleanliteralassertiontests",
          "native_compiler_resolved_boolean_literal_assertions",
          name);
    }
    for (String name : List.of(
        "classifiesFinalEqualityLocalReturn", "classifiesFinalLessThanAdditionReturn")) {
      assertCase(
          report,
          "nativecompilerresolvedearlycomparisontests",
          "native_compiler_resolved_early_comparisons",
          name);
    }
    for (String name : List.of(
        "classifiesFinalHelperForwardingReturn",
        "classifiesFinalHelperReturn",
        "classifiesFinalSignedReturn",
        "classifiesFinalLocalReturn",
        "classifiesFinalComputedReturn",
        "classifiesFinalAdditionReturn",
        "classifiesFinalRemainderReturn",
        "classifiesFinalDivisionReturn")) {
      assertCase(
          report,
          "nativecompilerresolvedearlyresulttests",
          "native_compiler_resolved_early_results",
          name);
    }
    for (String name : List.of(
        "classifiesFinalLocalLessThanAssertion",
        "classifiesFinalLiteralLessThanAssertion",
        "decodesFinalLiteralLessThanAssertionSource")) {
      assertCase(
          report,
          "nativecompilerresolvedlessthanassertiontests",
          "native_compiler_resolved_less_than_assertions",
          name);
    }
    for (String name : List.of(
        "classifiesFinalBooleanPairAssertion",
        "classifiesFinalSignedPairAssertion",
        "decodesFinalSignedPairAssertionSource",
        "decodesFinalBooleanPairAssertionSource")) {
      assertCase(
          report,
          "nativecompilerresolvedlocalpairassertiontests",
          "native_compiler_resolved_local_pair_assertions",
          name);
    }
    for (String name : List.of(
        "checksResolvedAssignmentMembership",
        "checksResolvedNamedAssignmentMembership",
        "checksResolvedBooleanAssignmentMembership",
        "checksResolvedAssignmentTarget")) {
      assertCase(
          report,
          "nativecompilerresolvedlocalassignmenttests",
          "native_compiler_resolved_local_assignments",
          name);
    }
    for (String name : List.of(
        "checksResolvedEqualityMembership",
        "checksResolvedSignedEqualityMembership",
        "checksResolvedBooleanEqualitySource")) {
      assertCase(
          report,
          "nativecompilerresolvedlocalequalitytests",
          "native_compiler_resolved_local_equality",
          name);
    }
    for (String name : List.of(
        "checksResolvedInequalityMembership",
        "checksResolvedSignedInequalityMembership",
        "checksResolvedBooleanInequalitySource")) {
      assertCase(
          report,
          "nativecompilerresolvedlocalinequalitytests",
          "native_compiler_resolved_local_inequality",
          name);
    }
    for (String name : List.of(
        "classifiesFinalResolvedLocalUpdate",
        "classifiesFinalNamedResolvedLocalUpdate",
        "decodesFinalResolvedLocalUpdateTarget")) {
      assertCase(
          report,
          "nativecompilerresolvedlocalupdatetests",
          "native_compiler_resolved_local_updates",
          name);
    }
    for (String name : List.of(
        "checksResolvedLongAssertionMembership",
        "checksResolvedLongCopyMembership",
        "checksResolvedBooleanCopyMembership",
        "checksResolvedBooleanNegationMembership")) {
      assertCase(
          report,
          "nativecompilerresolvedlocalcopytests",
          "native_compiler_resolved_local_copies",
          name);
    }
    for (String name : List.of(
        "checksResolvedLongBinaryMembership",
        "checksResolvedLongBinarySource",
        "checksResolvedLongPairMembership",
        "checksResolvedLongPairSource")) {
      assertCase(
          report,
          "nativecompilerresolvedlongoperationtests",
          "native_compiler_resolved_long_operations",
          name);
    }
    for (String name : List.of(
        "classifiesEquality",
        "classifiesInequality",
        "classifiesLessThan",
        "classifiesComparison")) {
      assertCase(
          report,
          "nativecompilerresolvedlocalliteralcomparisontests",
          "native_compiler_resolved_local_literal_comparisons",
          name);
    }
    for (String name : List.of(
        "decodesEqualitySource", "decodesLessThanSource", "decodesInequalitySource")) {
      assertCase(
          report,
          "nativecompilerresolvedlocalliteralsourcetests",
          "native_compiler_resolved_local_literal_sources",
          name);
    }
    for (String name : List.of(
        "classifiesSevenArgumentReturnCall",
        "decodesSevenArgumentReturnCallArity",
        "decodesFinalFourArgumentFirstSource",
        "decodesFinalFourArgumentSecondSource",
        "decodesFinalFourArgumentThirdSource",
        "decodesFinalFourArgumentFourthSource")) {
      assertCase(
          report,
          "nativecompilerresolvedreturncalltests",
          "native_compiler_resolved_return_calls",
          name);
    }
    for (String name : List.of(
        "selectsFinalSignedAmbiguousOpcode",
        "selectsFinalLiteralComparisonOpcode",
        "selectsFinalLiteralArithmeticOpcode")) {
      assertCase(
          report,
          "nativecompilerreturnopcodekindtests",
          "native_compiler_return_opcode_kinds",
          name);
    }
    assertCase(
        report,
        "nativecompilerresolvedlocallessthantests",
        "native_compiler_resolved_local_less_than",
        "checksFinalResolvedLocalLessThan");
    for (String name : List.of(
        "checksNamedConditionBit",
        "checksNamedLimitPair",
        "checksReversedCondition",
        "checksReversedUpdateBits")) {
      assertCase(
          report,
          "nativecompilerresolvedlocalloopformtests",
          "native_compiler_resolved_local_loop_forms",
          name);
    }
    assertCase(
        report,
        "nativecompilerresolvedlocalloopkindtests",
        "native_compiler_resolved_local_loop_kinds",
        "checksFinalResolvedLocalLoop");
    for (String name : List.of(
        "checksResolvedLoopTarget",
        "checksResolvedLoopForm")) {
      assertCase(
          report,
          "nativecompilerresolvedlocalloopoperandtests",
          "native_compiler_resolved_local_loop_operands",
          name);
    }
    for (String name : List.of(
        "checksResolvedReturnMembership",
        "checksSignedReturnMembership",
        "checksBooleanReturnSource")) {
      assertCase(
          report,
          "nativecompilerresolvedlocalreturntests",
          "native_compiler_resolved_local_returns",
          name);
    }
    assertCase(report, "nativecompilerspinetests", "native_compiler_spine", "checksEncodingWidth");
    assertCase(report, "nativecompilertypekindtests", "native_compiler_type_kinds", "checksTypeDescriptor");
    assertCase(
        report,
        "nativecompilerhelpersignaturetests",
        "native_compiler_helper_signatures",
        "checksSixteenParameterHelper");
    assertCase(
        report,
        "nativecompilerhelpersignaturetests",
        "native_compiler_helper_signatures",
        "checksSixteenParameterSignedKind");
    assertCase(
        report,
        "nativecompilerhelpersignaturetests",
        "native_compiler_helper_signatures",
        "checksSixteenParameterBooleanKind");
    assertCase(
        report,
        "nativecompilerhelpersignaturetests",
        "native_compiler_helper_signatures",
        "checksTenParameterUtf8Kind");
    assertCase(
        report,
        "nativecompilerhelpersignaturetests",
        "native_compiler_helper_signatures",
        "checksReversibleHelper");
    assertCase(
        report,
        "nativecompilerhelpersignaturetests",
        "native_compiler_helper_signatures",
        "checksResultSlotHelper");
    assertCase(
        report,
        "nativecompilerhelpersignaturetests",
        "native_compiler_helper_signatures",
        "checksUtf8ResultHelper");
    assertCase(
        report,
        "nativecompilerhelpersignaturetests",
        "native_compiler_helper_signatures",
        "checksBooleanResultHelper");
    assertCase(
        report,
        "nativecompilerhelpersignaturetests",
        "native_compiler_helper_signatures",
        "checksBooleanParameterHelper");
    for (String name : List.of(
        "classifiesOwnedAllocation",
        "classifiesSevenArgumentVoidCall",
        "classifiesBorrowedMapMutation",
        "classifiesSevenLocalCall",
        "classifiesTerminalLocalCallRange",
        "classifiesTerminalLocalReturnRange",
        "classifiesTerminalBooleanReturnRange",
        "classifiesHelperCallReturn",
        "classifiesFinalBorrowedReturn",
        "classifiesFinalBorrowedLocal")) {
      assertCase(
          report,
          "nativecompilerhelpervaluekindtests",
          "native_compiler_helper_value_kinds",
          name);
    }
    assertCase(
        report,
        "nativecompileridentifierstarttests",
        "native_compiler_identifier_starts",
        "checksFinalLowercaseIdentifierStart");
    assertCase(
        report,
        "nativecompilerinstructionformtests",
        "native_compiler_instruction_forms",
        "checksRecordProjectionOperandCount");
    for (String name : List.of(
        "checksGlobalConstantOpcode",
        "checksResultFillOpcode",
        "checksResultBinaryOpcode",
        "checksLocalMathOpcode")) {
      assertCase(
          report,
          "nativecompileropcodekindtests",
          "native_compiler_opcode_kinds",
          name);
    }
    assertCase(report, "nativecompilercallaritytests", "native_compiler_call_arity", "checksSevenArgumentAssignmentCall");
    assertCase(report, "nativecompilercallkindtests", "native_compiler_call_kinds", "checksSevenArgumentSourceMembership");
    assertCase(report, "nativecompilercallkindtests", "native_compiler_call_kinds", "checksSevenArgumentResolvedMembership");
    assertCase(report, "nativecompilercallkindtests", "native_compiler_call_kinds", "checksSevenArgumentResolvedIdentity");
    assertCase(report, "nativecompilercallkindtests", "native_compiler_call_kinds", "checksSevenArgumentResolvedTarget");
    assertCase(report, "nativecompilercallcolumntests", "native_compiler_call_columns", "checksSevenArgumentSourceKind");
    assertCase(report, "nativecompilercallcolumntests", "native_compiler_call_columns", "checksSevenArgumentResolvedBase");
    assertCase(report, "nativecompilercalloperandtests", "native_compiler_call_operand", "checksLeadingSevenArgumentSource");
    assertCase(report, "nativecompilervoidcallkindtests", "native_compiler_void_call_kinds", "checksThreeArgumentResolvedSource");
    assertCase(report, "nativecompilervoidcalloperandtests", "native_compiler_void_call_operand", "checksTrailingSevenArgumentSource");
    assertCase(report, "nativecompilervoidcallsourceformtests", "native_compiler_void_call_source_forms", "checksSevenArgumentSourceKind");
    assertCase(report, "nativecompilervoidcallsourcewidthtests", "native_compiler_void_call_source_widths", "checksSevenArgumentResolvedLocalWidth");
    assertCase(report, "nativecompilervoidcallwidthtests", "native_compiler_void_call_widths", "checksSevenArgumentInstructionWidth");
    for (String name : List.of(
        "checksLeadingWideReturnSources",
        "checksTrailingWideReturnSources",
        "checksFirstWideReturnSource",
        "checksSecondWideReturnSource",
        "checksThirdWideReturnSource",
        "checksFourthWideReturnSource",
        "checksFifthWideReturnSource",
        "checksSixthWideReturnSource",
        "checksSeventhWideReturnSource")) {
      assertCase(
          report,
          "nativecompilerwidereturnsourcetests",
          "native_compiler_wide_return_sources",
          name);
    }
  }

  private static void assertCase(
      TestReport report, String target, String module, String name) {
    String qualified = target + "::wheeler.compiler.tests." + module + "::" + name;
    assertTrue(report.cases().stream().anyMatch(testcase -> testcase.targetName().equals(qualified)));
  }
}
