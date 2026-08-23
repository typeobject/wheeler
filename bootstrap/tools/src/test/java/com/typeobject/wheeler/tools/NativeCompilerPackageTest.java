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
  @Timeout(value = 12, unit = TimeUnit.MINUTES)
  void testsThePhysicalCompilerSpineNatively() throws Exception {
    Path compiler = Path.of("wheeler-compiler");
    PackageProject project = PackageProject.load(compiler);

    var result = NativePackageTestRunner.run(
        compiler, project.manifest(), 0, 1, Set.of()).orElseThrow();
    TestReport report = result.report();

    assertEquals(125, result.selected());
    assertEquals(125, result.passed());
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
