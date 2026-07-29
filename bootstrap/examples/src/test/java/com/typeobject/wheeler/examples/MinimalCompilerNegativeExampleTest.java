package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import java.nio.charset.StandardCharsets;
import org.junit.jupiter.api.Test;

/** Fail-closed corpus for malformed bounded compiler inputs. */
class MinimalCompilerNegativeExampleTest {
  private static final int MAX_RESULT_ENTRY_STATEMENTS = 64;

  @Test
  void rejectsMalformedOrUnresolvedSourcesWithoutPublishingOutput() throws Exception {
    Program writerProgram = CompilerSources.minimalCompilerProgram();
    VirtualMachine duplicate = new VirtualMachine(
        writerProgram,
        ("classical class main { state long alpha = 0; "
            + "entry void main() { alpha += 0; } }")
            .getBytes(StandardCharsets.UTF_8),
        512);
    assertTrapWithoutOutput(duplicate, 512);

    VirtualMachine duplicateHelperVisibility = new VirtualMachine(
        writerProgram,
        ("classical class DuplicateVisibility { state long value = 0; "
            + "public public void setup() { value += 1; } "
            + "entry void main() { setup(); } }")
            .getBytes(StandardCharsets.UTF_8),
        1024);
    assertTrapWithoutOutput(duplicateHelperVisibility, 1024);
    VirtualMachine duplicatePrivateVisibility = new VirtualMachine(
        writerProgram,
        ("classical class DuplicatePrivateVisibility { state long value = 0; "
            + "private private void setup() { value += 1; } "
            + "entry void main() { setup(); } }")
            .getBytes(StandardCharsets.UTF_8),
        1024);
    assertTrapWithoutOutput(duplicatePrivateVisibility, 1024);

    VirtualMachine irreversibleHelper = new VirtualMachine(
        writerProgram,
        ("classical class BadReverse { state long value = 1; "
            + "rev void set() { value = 2; } "
            + "entry void main() { set(); reverse { set(); } } }")
            .getBytes(StandardCharsets.UTF_8),
        1024);
    assertTrapWithoutOutput(irreversibleHelper, 1024);

    VirtualMachine signedOverflow = new VirtualMachine(
        writerProgram,
        ("classical class Overflow { "
            + "state long value = -9223372036854775808; "
            + "entry void main() { } }")
            .getBytes(StandardCharsets.UTF_8),
        1024);
    assertTrapWithoutOutput(signedOverflow, 1024);

    VirtualMachine invalid = new VirtualMachine(
        writerProgram,
        ("classical class Caf\u00e9 { state long value = 7; "
            + "entry void main() { value += 5; } }")
            .getBytes(StandardCharsets.UTF_8),
        512);
    assertTrapWithoutOutput(invalid, 512);

    VirtualMachine bareAssertion = new VirtualMachine(
        writerProgram,
        ("classical class Bare { state long value = 1; "
            + "entry void main() { assert value == 1; } }")
            .getBytes(StandardCharsets.UTF_8),
        512);
    assertTrapWithoutOutput(bareAssertion, 512);

    VirtualMachine malformedLiteralAssertion = new VirtualMachine(
        writerProgram,
        "classical class BadLiteralAssert { entry void main() { assert(0 = 0); } }"
            .getBytes(StandardCharsets.UTF_8),
        512);
    assertTrapWithoutOutput(malformedLiteralAssertion, 512);

    VirtualMachine invalidBoolean = new VirtualMachine(
        writerProgram,
        "classical class BadBoolean { entry void main() { boolean flag = 1; } }"
            .getBytes(StandardCharsets.UTF_8),
        512);
    assertTrapWithoutOutput(invalidBoolean, 512);

    VirtualMachine doubleNegation = new VirtualMachine(
        writerProgram,
        "classical class DoubleNot { entry void main() { boolean flag = !!false; } }"
            .getBytes(StandardCharsets.UTF_8),
        512);
    assertTrapWithoutOutput(doubleNegation, 512);

  }

  @Test
  void rejectsInvalidHelperResultsWithoutPublishingOutput() throws Exception {
    Program writerProgram = CompilerSources.minimalCompilerProgram();
    VirtualMachine missingResult = new VirtualMachine(
        writerProgram,
        ("classical class MissingResult { long answer() { } "
                + "entry void main() { long value = answer(); } }")
            .getBytes(StandardCharsets.UTF_8),
        512);
    assertTrapWithoutOutput(missingResult, 512);

    VirtualMachine earlyResult = new VirtualMachine(
        writerProgram,
        ("classical class EarlyResult { long answer() { return 42; long late = 0; } "
                + "entry void main() { long value = answer(); } }")
            .getBytes(StandardCharsets.UTF_8),
        512);
    assertTrapWithoutOutput(earlyResult, 512);

    VirtualMachine missingResultLocal = new VirtualMachine(
        writerProgram,
        ("classical class MissingResultLocal { "
                + "long answer() { long value = 42; return missing; } "
                + "entry void main() { long result = answer(); } }")
            .getBytes(StandardCharsets.UTF_8),
        512);
    assertTrapWithoutOutput(missingResultLocal, 512);

    VirtualMachine booleanResultLocal = new VirtualMachine(
        writerProgram,
        ("classical class BooleanResultLocal { "
                + "long answer() { boolean value = true; return value; } "
                + "entry void main() { long result = answer(); } }")
            .getBytes(StandardCharsets.UTF_8),
        512);
    assertTrapWithoutOutput(booleanResultLocal, 512);

    VirtualMachine booleanResultAsSigned = new VirtualMachine(
        writerProgram,
        ("classical class BooleanResultAsSigned { boolean ready() { return true; } "
                + "entry void main() { long result = ready(); } }")
            .getBytes(StandardCharsets.UTF_8),
        512);
    assertTrapWithoutOutput(booleanResultAsSigned, 512);

    VirtualMachine signedResultAsBoolean = new VirtualMachine(
        writerProgram,
        ("classical class SignedResultAsBoolean { long answer() { return 1; } "
                + "entry void main() { boolean result = answer(); } }")
            .getBytes(StandardCharsets.UTF_8),
        512);
    assertTrapWithoutOutput(signedResultAsBoolean, 512);

    VirtualMachine signedLocalAsBooleanResult = new VirtualMachine(
        writerProgram,
        ("classical class SignedLocalAsBooleanResult { "
                + "boolean ready() { long value = 1; return value; } "
                + "entry void main() { boolean result = ready(); } }")
            .getBytes(StandardCharsets.UTF_8),
        512);
    assertTrapWithoutOutput(signedLocalAsBooleanResult, 512);

  }

  @Test
  void rejectsInvalidHelperParametersWithoutPublishingOutput() throws Exception {
    Program writerProgram = CompilerSources.minimalCompilerProgram();
    VirtualMachine wrongReturnedParameter = new VirtualMachine(
        writerProgram,
        ("classical class WrongReturnedParameter { "
                + "long identity(long value) { return other; } "
                + "entry void main() { long answer = identity(42); } }")
            .getBytes(StandardCharsets.UTF_8),
        512);
    assertTrapWithoutOutput(wrongReturnedParameter, 512);

    VirtualMachine missingParameterPreludeSource = new VirtualMachine(
        writerProgram,
        ("classical class MissingParameterPreludeSource { "
                + "long increment(long value) { long result = missing + 1; return result; } "
                + "entry void main() { long answer = increment(41); } }")
            .getBytes(StandardCharsets.UTF_8),
        512);
    assertTrapWithoutOutput(missingParameterPreludeSource, 512);

    VirtualMachine duplicateParameterLocal = new VirtualMachine(
        writerProgram,
        ("classical class DuplicateParameterLocal { "
                + "long increment(long value) { long value = value + 1; return value; } "
                + "entry void main() { long answer = increment(41); } }")
            .getBytes(StandardCharsets.UTF_8),
        512);
    assertTrapWithoutOutput(duplicateParameterLocal, 512);

    VirtualMachine wrongReturnRightParameter = new VirtualMachine(
        writerProgram,
        ("classical class WrongReturnRightParameter { "
                + "long identity(long value) { return value + other; } "
                + "entry void main() { long answer = identity(42); } }")
            .getBytes(StandardCharsets.UTF_8),
        512);
    assertTrapWithoutOutput(wrongReturnRightParameter, 512);

    VirtualMachine duplicateParameters = new VirtualMachine(
        writerProgram,
        ("classical class DuplicateParameters { "
                + "long add(long value, long value) { return value + value; } "
                + "entry void main() { long answer = add(20, 22); } }")
            .getBytes(StandardCharsets.UTF_8),
        512);
    assertTrapWithoutOutput(duplicateParameters, 512);

    VirtualMachine reversedParameters = new VirtualMachine(
        writerProgram,
        ("classical class ReversedParameters { "
                + "long subtract(long left, long right) { return right - left; } "
                + "entry void main() { long answer = subtract(64, 22); } }")
            .getBytes(StandardCharsets.UTF_8),
        512);
    assertTrapWithoutOutput(reversedParameters, 512);

    VirtualMachine missingPairPreludeSource = new VirtualMachine(
        writerProgram,
        ("classical class MissingPairPreludeSource { "
                + "long add(long left, long right) { "
                + "long result = left + missing; return result; } "
                + "entry void main() { long answer = add(20, 22); } }")
            .getBytes(StandardCharsets.UTF_8),
        512);
    assertTrapWithoutOutput(missingPairPreludeSource, 512);

  }

  @Test
  void rejectsAnOversizedResultEntryWithoutPublishingOutput() throws Exception {
    Program writerProgram = CompilerSources.minimalCompilerProgram();
    StringBuilder oversizedResultEntry = new StringBuilder(
        "classical class OversizedResultEntry { long value() { return 1; } entry void main() { ");
    for (int statement = 0; statement < MAX_RESULT_ENTRY_STATEMENTS; statement++) {
      oversizedResultEntry.append("long value").append(statement).append(" = ")
          .append(statement).append("; ");
    }
    oversizedResultEntry.append("long answer = value(); } }");
    VirtualMachine oversizedResultEntryMachine = new VirtualMachine(
        writerProgram,
        oversizedResultEntry.toString().getBytes(StandardCharsets.UTF_8),
        4096);
    assertTrapWithoutOutput(oversizedResultEntryMachine, 4096);

  }

  @Test
  void rejectsInvalidHelperCallsWithoutPublishingOutput() throws Exception {
    Program writerProgram = CompilerSources.minimalCompilerProgram();
    VirtualMachine missingResultCall = new VirtualMachine(
        writerProgram,
        ("classical class MissingResultCall { long value() { return 1; } "
                + "entry void main() { long ignored = 0; } }")
            .getBytes(StandardCharsets.UTF_8),
        512);
    assertTrapWithoutOutput(missingResultCall, 512);

    VirtualMachine missingCallArgument = new VirtualMachine(
        writerProgram,
        ("classical class MissingCallArgument { long identity(long value) { return value; } "
                + "entry void main() { long answer = identity(); } }")
            .getBytes(StandardCharsets.UTF_8),
        512);
    assertTrapWithoutOutput(missingCallArgument, 512);

    VirtualMachine unexpectedCallArgument = new VirtualMachine(
        writerProgram,
        ("classical class UnexpectedCallArgument { long answer() { return 42; } "
                + "entry void main() { long value = answer(1); } }")
            .getBytes(StandardCharsets.UTF_8),
        512);
    assertTrapWithoutOutput(unexpectedCallArgument, 512);

    VirtualMachine missingLocalCallArgument = new VirtualMachine(
        writerProgram,
        ("classical class MissingLocalCallArgument { "
                + "long identity(long value) { return value; } "
                + "entry void main() { long answer = identity(missing); } }")
            .getBytes(StandardCharsets.UTF_8),
        512);
    assertTrapWithoutOutput(missingLocalCallArgument, 512);

    VirtualMachine booleanCallArgument = new VirtualMachine(
        writerProgram,
        ("classical class BooleanCallArgument { long identity(long value) { return value; } "
                + "entry void main() { boolean flag = true; long answer = identity(flag); } }")
            .getBytes(StandardCharsets.UTF_8),
        512);
    assertTrapWithoutOutput(booleanCallArgument, 512);

    VirtualMachine signedBooleanCallArgument = new VirtualMachine(
        writerProgram,
        ("classical class SignedBooleanCallArgument { "
                + "boolean identity(boolean value) { return value; } "
                + "entry void main() { boolean answer = identity(1); } }")
            .getBytes(StandardCharsets.UTF_8),
        512);
    assertTrapWithoutOutput(signedBooleanCallArgument, 512);

    VirtualMachine signedLocalBooleanCallArgument = new VirtualMachine(
        writerProgram,
        ("classical class SignedLocalBooleanCallArgument { "
                + "boolean identity(boolean value) { return value; } "
                + "entry void main() { long value = 1; boolean answer = identity(value); } }")
            .getBytes(StandardCharsets.UTF_8),
        512);
    assertTrapWithoutOutput(signedLocalBooleanCallArgument, 512);

    VirtualMachine booleanSignedCallArgument = new VirtualMachine(
        writerProgram,
        ("classical class BooleanSignedCallArgument { "
                + "boolean nonzero(long value) { boolean result = value != 0; return result; } "
                + "entry void main() { boolean answer = nonzero(true); } }")
            .getBytes(StandardCharsets.UTF_8),
        512);
    assertTrapWithoutOutput(booleanSignedCallArgument, 512);

    VirtualMachine mixedBooleanResultParameters = new VirtualMachine(
        writerProgram,
        ("classical class MixedBooleanResultParameters { "
                + "boolean compare(long left, boolean right) { return right; } "
                + "entry void main() { boolean answer = compare(1, true); } }")
            .getBytes(StandardCharsets.UTF_8),
        512);
    assertTrapWithoutOutput(mixedBooleanResultParameters, 512);

    VirtualMachine booleanLocalSignedPairArgument = new VirtualMachine(
        writerProgram,
        ("classical class BooleanLocalSignedPairArgument { "
                + "boolean different(long left, long right) { "
                + "boolean result = left != right; return result; } "
                + "entry void main() { boolean left = true; "
                + "boolean answer = different(left, 42); } }")
            .getBytes(StandardCharsets.UTF_8),
        512);
    assertTrapWithoutOutput(booleanLocalSignedPairArgument, 512);

    VirtualMachine mixedLocalSignedPairArguments = new VirtualMachine(
        writerProgram,
        ("classical class MixedLocalSignedPairArguments { "
                + "boolean different(long left, long right) { "
                + "boolean result = left != right; return result; } "
                + "entry void main() { boolean left = true; long right = 42; "
                + "boolean answer = different(left, right); } }")
            .getBytes(StandardCharsets.UTF_8),
        512);
    assertTrapWithoutOutput(mixedLocalSignedPairArguments, 512);

    VirtualMachine signedBooleanPairArgument = new VirtualMachine(
        writerProgram,
        ("classical class SignedBooleanPairArgument { "
                + "boolean same(boolean left, boolean right) { return left; } "
                + "entry void main() { boolean answer = same(true, 1); } }")
            .getBytes(StandardCharsets.UTF_8),
        512);
    assertTrapWithoutOutput(signedBooleanPairArgument, 512);

    VirtualMachine missingBooleanPairArgument = new VirtualMachine(
        writerProgram,
        ("classical class MissingBooleanPairArgument { "
                + "boolean same(boolean left, boolean right) { return left; } "
                + "entry void main() { boolean answer = same(true); } }")
            .getBytes(StandardCharsets.UTF_8),
        512);
    assertTrapWithoutOutput(missingBooleanPairArgument, 512);

    VirtualMachine duplicateBooleanParameters = new VirtualMachine(
        writerProgram,
        ("classical class DuplicateBooleanParameters { "
                + "boolean same(boolean value, boolean value) { return value; } "
                + "entry void main() { boolean answer = same(true, true); } }")
            .getBytes(StandardCharsets.UTF_8),
        512);
    assertTrapWithoutOutput(duplicateBooleanParameters, 512);

    VirtualMachine booleanTwoArgument = new VirtualMachine(
        writerProgram,
        ("classical class BooleanTwoArgument { "
                + "long add(long left, long right) { return left + right; } "
                + "entry void main() { boolean flag = true; long answer = add(flag, 1); } }")
            .getBytes(StandardCharsets.UTF_8),
        512);
    assertTrapWithoutOutput(booleanTwoArgument, 512);

    VirtualMachine wrongResultHelper = new VirtualMachine(
        writerProgram,
        ("classical class WrongResultHelper { long answer() { return 42; } "
                + "entry void main() { long value = other(); } }")
            .getBytes(StandardCharsets.UTF_8),
        512);
    assertTrapWithoutOutput(wrongResultHelper, 512);

    VirtualMachine valueFromVoid = new VirtualMachine(
        writerProgram,
        ("classical class ValueFromVoid { void answer() { return 42; } "
                + "entry void main() { answer(); } }")
            .getBytes(StandardCharsets.UTF_8),
        512);
    assertTrapWithoutOutput(valueFromVoid, 512);

  }

  @Test
  void rejectsStatementAndResolutionOverflowWithoutPublishingOutput() throws Exception {
    Program writerProgram = CompilerSources.minimalCompilerProgram();
    VirtualMachine sixtyFifthHelperStatement = new VirtualMachine(
        writerProgram,
        ("classical class SixtyFiveHelperStatements { state long value = 0; "
            + "void setup() { "
            + "value += 1; ".repeat(65)
            + "} entry void main() { setup(); } }")
            .getBytes(StandardCharsets.UTF_8),
        8192);
    assertTrapWithoutOutput(sixtyFifthHelperStatement, 8192);

    VirtualMachine sixtyFifthStatement = new VirtualMachine(
        writerProgram,
        ("classical class SixtyFiveLocals { entry void main() { "
            + booleanDeclarations(65)
            + "} }")
            .getBytes(StandardCharsets.UTF_8),
        8192);
    assertTrapWithoutOutput(sixtyFifthStatement, 8192);

  }

  @Test
  void rejectsInvalidLocalStateUpdatesWithoutPublishingOutput() throws Exception {
    Program writerProgram = CompilerSources.minimalCompilerProgram();
    VirtualMachine unknownLocalCondition = new VirtualMachine(
        writerProgram,
        ("classical class UnknownLocalCondition { state long result = 0; "
                + "entry void main() { if (missing) { result += 1; } } }")
            .getBytes(StandardCharsets.UTF_8),
        512);
    assertTrapWithoutOutput(unknownLocalCondition, 512);

    VirtualMachine unknownNegatedLocalCondition = new VirtualMachine(
        writerProgram,
        ("classical class UnknownNegatedLocalCondition { state long result = 0; "
                + "entry void main() { if (!missing) { result += 1; } } }")
            .getBytes(StandardCharsets.UTF_8),
        512);
    assertTrapWithoutOutput(unknownNegatedLocalCondition, 512);

    VirtualMachine unknownLocalAssignment = new VirtualMachine(
        writerProgram,
        ("classical class UnknownLocalAssignment { state long result = 0; "
                + "entry void main() { result = missing; } }")
            .getBytes(StandardCharsets.UTF_8),
        512);
    assertTrapWithoutOutput(unknownLocalAssignment, 512);

    VirtualMachine booleanLocalAssignment = new VirtualMachine(
        writerProgram,
        ("classical class BooleanLocalAssignment { state long result = 0; "
                + "entry void main() { boolean answer = true; result = answer; } }")
            .getBytes(StandardCharsets.UTF_8),
        512);
    assertTrapWithoutOutput(booleanLocalAssignment, 512);

    VirtualMachine unknownLocalUpdate = new VirtualMachine(
        writerProgram,
        ("classical class UnknownLocalUpdate { state long result = 0; "
                + "entry void main() { result += missing; } }")
            .getBytes(StandardCharsets.UTF_8),
        512);
    assertTrapWithoutOutput(unknownLocalUpdate, 512);

    VirtualMachine booleanLocalUpdate = new VirtualMachine(
        writerProgram,
        ("classical class BooleanLocalUpdate { state long result = 0; "
                + "entry void main() { boolean delta = true; result += delta; } }")
            .getBytes(StandardCharsets.UTF_8),
        512);
    assertTrapWithoutOutput(booleanLocalUpdate, 512);

    VirtualMachine unknownGuardedLocalUpdate = new VirtualMachine(
        writerProgram,
        ("classical class UnknownGuardedLocalUpdate { state long result = 0; "
                + "entry void main() { boolean ready = true; "
                + "if (ready) { result += missing; } } }")
            .getBytes(StandardCharsets.UTF_8),
        512);
    assertTrapWithoutOutput(unknownGuardedLocalUpdate, 512);

    VirtualMachine booleanGuardedLocalUpdate = new VirtualMachine(
        writerProgram,
        ("classical class BooleanGuardedLocalUpdate { state long result = 0; "
                + "entry void main() { boolean ready = true; boolean delta = true; "
                + "if (ready) { result += delta; } } }")
            .getBytes(StandardCharsets.UTF_8),
        512);
    assertTrapWithoutOutput(booleanGuardedLocalUpdate, 512);

  }

  @Test
  void rejectsInvalidTypedExpressionsWithoutPublishingOutput() throws Exception {
    Program writerProgram = CompilerSources.minimalCompilerProgram();
    VirtualMachine booleanLessThanCondition = new VirtualMachine(
        writerProgram,
        ("classical class BooleanLessThanCondition { state long result = 0; "
                + "entry void main() { boolean answer = true; "
                + "if (answer < 1) { result += 1; } } }")
            .getBytes(StandardCharsets.UTF_8),
        512);
    assertTrapWithoutOutput(booleanLessThanCondition, 512);

    VirtualMachine booleanEqualityCondition = new VirtualMachine(
        writerProgram,
        ("classical class BooleanEqualityCondition { state long result = 0; "
                + "entry void main() { boolean answer = true; "
                + "if (answer == 1) { result += 1; } } }")
            .getBytes(StandardCharsets.UTF_8),
        512);
    assertTrapWithoutOutput(booleanEqualityCondition, 512);

    VirtualMachine booleanLiteralEquality = new VirtualMachine(
        writerProgram,
        ("classical class BooleanLiteralEquality { entry void main() { "
                + "boolean answer = true; boolean same = answer == 1; } }")
            .getBytes(StandardCharsets.UTF_8),
        512);
    assertTrapWithoutOutput(booleanLiteralEquality, 512);

    VirtualMachine booleanLiteralLessThan = new VirtualMachine(
        writerProgram,
        ("classical class BooleanLiteralLessThan { entry void main() { "
                + "boolean answer = true; boolean less = answer < 1; } }")
            .getBytes(StandardCharsets.UTF_8),
        512);
    assertTrapWithoutOutput(booleanLiteralLessThan, 512);

    VirtualMachine booleanLessThan = new VirtualMachine(
        writerProgram,
        ("classical class BooleanLessThan { entry void main() { "
                + "boolean first = false; boolean second = true; "
                + "boolean less = first < second; } }")
            .getBytes(StandardCharsets.UTF_8),
        512);
    assertTrapWithoutOutput(booleanLessThan, 512);

    VirtualMachine mixedLocalEquality = new VirtualMachine(
        writerProgram,
        ("classical class MixedLocalEquality { entry void main() { "
                + "long first = 1; boolean second = true; "
                + "boolean same = first == second; } }")
            .getBytes(StandardCharsets.UTF_8),
        512);
    assertTrapWithoutOutput(mixedLocalEquality, 512);

    VirtualMachine mixedLocalInequality = new VirtualMachine(
        writerProgram,
        ("classical class MixedLocalInequality { entry void main() { "
                + "long first = 1; boolean second = true; "
                + "boolean different = first != second; } }")
            .getBytes(StandardCharsets.UTF_8),
        512);
    assertTrapWithoutOutput(mixedLocalInequality, 512);
  }

  @Test
  void rejectsUnresolvedLocalsWithoutPublishingOutput() throws Exception {
    Program writerProgram = CompilerSources.minimalCompilerProgram();
    VirtualMachine unresolvedBooleanCopy = new VirtualMachine(
        writerProgram,
        "classical class UnknownBooleanCopy { entry void main() { boolean result = missing; } }"
            .getBytes(StandardCharsets.UTF_8),
        512);
    assertTrapWithoutOutput(unresolvedBooleanCopy, 512);

    VirtualMachine unresolvedBooleanNot = new VirtualMachine(
        writerProgram,
        "classical class UnknownBooleanNot { entry void main() { boolean result = !missing; } }"
            .getBytes(StandardCharsets.UTF_8),
        512);
    assertTrapWithoutOutput(unresolvedBooleanNot, 512);

    VirtualMachine signedBooleanHelperEquality = new VirtualMachine(
        writerProgram,
        ("classical class SignedBooleanHelperEquality { "
                + "boolean invalid() { long value = 1; return value == true; } "
                + "entry void main() { boolean result = invalid(); } }")
            .getBytes(StandardCharsets.UTF_8),
        512);
    assertTrapWithoutOutput(signedBooleanHelperEquality, 512);

    VirtualMachine unknownBooleanHelperNot = new VirtualMachine(
        writerProgram,
        ("classical class UnknownBooleanHelperNot { "
                + "boolean invert(boolean value) { return !missing; } "
                + "entry void main() { boolean result = invert(false); } }")
            .getBytes(StandardCharsets.UTF_8),
        512);
    assertTrapWithoutOutput(unknownBooleanHelperNot, 512);

    VirtualMachine unknownBooleanHelperInequality = new VirtualMachine(
        writerProgram,
        ("classical class UnknownBooleanHelperInequality { "
                + "boolean different(boolean value) { return value != missing; } "
                + "entry void main() { boolean result = different(false); } }")
            .getBytes(StandardCharsets.UTF_8),
        512);
    assertTrapWithoutOutput(unknownBooleanHelperInequality, 512);

    VirtualMachine booleanHelperXor = new VirtualMachine(
        writerProgram,
        ("classical class BooleanHelperXor { "
                + "long mask(long value) { return value ^ true; } "
                + "entry void main() { long result = mask(1); } }")
            .getBytes(StandardCharsets.UTF_8),
        512);
    assertTrapWithoutOutput(booleanHelperXor, 512);

    VirtualMachine booleanHelperAnd = new VirtualMachine(
        writerProgram,
        ("classical class BooleanHelperAnd { "
                + "long mask(long value) { return value & true; } "
                + "entry void main() { long result = mask(1); } }")
            .getBytes(StandardCharsets.UTF_8),
        512);
    assertTrapWithoutOutput(booleanHelperAnd, 512);

    VirtualMachine unresolvedSignedCopy = new VirtualMachine(
        writerProgram,
        "classical class UnknownSignedCopy { entry void main() { long result = missing; } }"
            .getBytes(StandardCharsets.UTF_8),
        512);
    assertTrapWithoutOutput(unresolvedSignedCopy, 512);

    VirtualMachine unresolvedSignedAdd = new VirtualMachine(
        writerProgram,
        "classical class UnknownSignedAdd { entry void main() { long result = missing + 1; } }"
            .getBytes(StandardCharsets.UTF_8),
        512);
    assertTrapWithoutOutput(unresolvedSignedAdd, 512);

    VirtualMachine unresolvedSignedPair = new VirtualMachine(
        writerProgram,
        ("classical class UnknownSignedPair { entry void main() { "
                + "long first = 1; long result = first + missing; } }")
            .getBytes(StandardCharsets.UTF_8),
        512);
    assertTrapWithoutOutput(unresolvedSignedPair, 512);

    VirtualMachine unresolvedLocal = new VirtualMachine(
        writerProgram,
        "classical class UnknownLocal { entry void main() { assert(missing); } }"
            .getBytes(StandardCharsets.UTF_8),
        512);
    assertTrapWithoutOutput(unresolvedLocal, 512);

    VirtualMachine unresolvedHelperLocal = new VirtualMachine(
        writerProgram,
        ("classical class UnknownHelperLocal { state long total = 0; "
            + "void setup() { assert(missing); } entry void main() { setup(); } }")
            .getBytes(StandardCharsets.UTF_8),
        512);
    assertTrapWithoutOutput(unresolvedHelperLocal, 512);
  }

  private static void assertTrapWithoutOutput(VirtualMachine machine, int outputCapacity) {
    assertThrows(
        VmTrap.class, () -> CompilerMachineRunner.runWithoutRewindHistory(machine));
    assertArrayEquals(new byte[outputCapacity], machine.hostOutput());
  }

  private static String booleanDeclarations(int count) {
    StringBuilder source = new StringBuilder();
    for (int index = 0; index < count; index++) {
      source.append("boolean value").append(index).append(" = true; ");
    }
    return source.toString();
  }
}
