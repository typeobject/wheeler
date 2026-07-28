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
  @Test
  void rejectsMalformedOrUnresolvedSourcesWithoutPublishingOutput() throws Exception {
    Program writerProgram = CompilerSources.minimalCompilerProgram();
    VirtualMachine duplicate = new VirtualMachine(
        writerProgram,
        ("classical class main { state long alpha = 0; "
            + "entry void main() { alpha += 0; } }")
            .getBytes(StandardCharsets.UTF_8),
        512);
    assertThrows(VmTrap.class, duplicate::run);
    assertArrayEquals(new byte[512], duplicate.hostOutput());

    VirtualMachine duplicateHelperVisibility = new VirtualMachine(
        writerProgram,
        ("classical class DuplicateVisibility { state long value = 0; "
            + "public public void setup() { value += 1; } "
            + "entry void main() { setup(); } }")
            .getBytes(StandardCharsets.UTF_8),
        1024);
    assertThrows(VmTrap.class, duplicateHelperVisibility::run);
    assertArrayEquals(new byte[1024], duplicateHelperVisibility.hostOutput());
    VirtualMachine duplicatePrivateVisibility = new VirtualMachine(
        writerProgram,
        ("classical class DuplicatePrivateVisibility { state long value = 0; "
            + "private private void setup() { value += 1; } "
            + "entry void main() { setup(); } }")
            .getBytes(StandardCharsets.UTF_8),
        1024);
    assertThrows(VmTrap.class, duplicatePrivateVisibility::run);
    assertArrayEquals(new byte[1024], duplicatePrivateVisibility.hostOutput());

    VirtualMachine irreversibleHelper = new VirtualMachine(
        writerProgram,
        ("classical class BadReverse { state long value = 1; "
            + "rev void set() { value = 2; } "
            + "entry void main() { set(); reverse { set(); } } }")
            .getBytes(StandardCharsets.UTF_8),
        1024);
    assertThrows(VmTrap.class, irreversibleHelper::run);
    assertArrayEquals(new byte[1024], irreversibleHelper.hostOutput());

    VirtualMachine signedOverflow = new VirtualMachine(
        writerProgram,
        ("classical class Overflow { "
            + "state long value = -9223372036854775808; "
            + "entry void main() { } }")
            .getBytes(StandardCharsets.UTF_8),
        1024);
    assertThrows(VmTrap.class, signedOverflow::run);
    assertArrayEquals(new byte[1024], signedOverflow.hostOutput());

    VirtualMachine invalid = new VirtualMachine(
        writerProgram,
        ("classical class Caf\u00e9 { state long value = 7; "
            + "entry void main() { value += 5; } }")
            .getBytes(StandardCharsets.UTF_8),
        512);
    assertThrows(VmTrap.class, invalid::run);
    assertArrayEquals(new byte[512], invalid.hostOutput());

    VirtualMachine bareAssertion = new VirtualMachine(
        writerProgram,
        ("classical class Bare { state long value = 1; "
            + "entry void main() { assert value == 1; } }")
            .getBytes(StandardCharsets.UTF_8),
        512);
    assertThrows(VmTrap.class, bareAssertion::run);
    assertArrayEquals(new byte[512], bareAssertion.hostOutput());

    VirtualMachine malformedLiteralAssertion = new VirtualMachine(
        writerProgram,
        "classical class BadLiteralAssert { entry void main() { assert(0 = 0); } }"
            .getBytes(StandardCharsets.UTF_8),
        512);
    assertThrows(VmTrap.class, malformedLiteralAssertion::run);
    assertArrayEquals(new byte[512], malformedLiteralAssertion.hostOutput());

    VirtualMachine invalidBoolean = new VirtualMachine(
        writerProgram,
        "classical class BadBoolean { entry void main() { boolean flag = 1; } }"
            .getBytes(StandardCharsets.UTF_8),
        512);
    assertThrows(VmTrap.class, invalidBoolean::run);
    assertArrayEquals(new byte[512], invalidBoolean.hostOutput());

    VirtualMachine doubleNegation = new VirtualMachine(
        writerProgram,
        "classical class DoubleNot { entry void main() { boolean flag = !!false; } }"
            .getBytes(StandardCharsets.UTF_8),
        512);
    assertThrows(VmTrap.class, doubleNegation::run);
    assertArrayEquals(new byte[512], doubleNegation.hostOutput());

    VirtualMachine missingResult = new VirtualMachine(
        writerProgram,
        ("classical class MissingResult { long answer() { } "
                + "entry void main() { long value = answer(); } }")
            .getBytes(StandardCharsets.UTF_8),
        512);
    assertThrows(VmTrap.class, missingResult::run);
    assertArrayEquals(new byte[512], missingResult.hostOutput());

    VirtualMachine earlyResult = new VirtualMachine(
        writerProgram,
        ("classical class EarlyResult { long answer() { return 42; long late = 0; } "
                + "entry void main() { long value = answer(); } }")
            .getBytes(StandardCharsets.UTF_8),
        512);
    assertThrows(VmTrap.class, earlyResult::run);
    assertArrayEquals(new byte[512], earlyResult.hostOutput());

    VirtualMachine missingResultLocal = new VirtualMachine(
        writerProgram,
        ("classical class MissingResultLocal { "
                + "long answer() { long value = 42; return missing; } "
                + "entry void main() { long result = answer(); } }")
            .getBytes(StandardCharsets.UTF_8),
        512);
    assertThrows(VmTrap.class, missingResultLocal::run);
    assertArrayEquals(new byte[512], missingResultLocal.hostOutput());

    VirtualMachine booleanResultLocal = new VirtualMachine(
        writerProgram,
        ("classical class BooleanResultLocal { "
                + "long answer() { boolean value = true; return value; } "
                + "entry void main() { long result = answer(); } }")
            .getBytes(StandardCharsets.UTF_8),
        512);
    assertThrows(VmTrap.class, booleanResultLocal::run);
    assertArrayEquals(new byte[512], booleanResultLocal.hostOutput());

    VirtualMachine wrongReturnedParameter = new VirtualMachine(
        writerProgram,
        ("classical class WrongReturnedParameter { "
                + "long identity(long value) { return other; } "
                + "entry void main() { long answer = identity(42); } }")
            .getBytes(StandardCharsets.UTF_8),
        512);
    assertThrows(VmTrap.class, wrongReturnedParameter::run);
    assertArrayEquals(new byte[512], wrongReturnedParameter.hostOutput());

    VirtualMachine missingParameterPreludeSource = new VirtualMachine(
        writerProgram,
        ("classical class MissingParameterPreludeSource { "
                + "long increment(long value) { long result = missing + 1; return result; } "
                + "entry void main() { long answer = increment(41); } }")
            .getBytes(StandardCharsets.UTF_8),
        512);
    assertThrows(VmTrap.class, missingParameterPreludeSource::run);
    assertArrayEquals(new byte[512], missingParameterPreludeSource.hostOutput());

    VirtualMachine duplicateParameterLocal = new VirtualMachine(
        writerProgram,
        ("classical class DuplicateParameterLocal { "
                + "long increment(long value) { long value = value + 1; return value; } "
                + "entry void main() { long answer = increment(41); } }")
            .getBytes(StandardCharsets.UTF_8),
        512);
    assertThrows(VmTrap.class, duplicateParameterLocal::run);
    assertArrayEquals(new byte[512], duplicateParameterLocal.hostOutput());

    VirtualMachine wrongReturnRightParameter = new VirtualMachine(
        writerProgram,
        ("classical class WrongReturnRightParameter { "
                + "long identity(long value) { return value + other; } "
                + "entry void main() { long answer = identity(42); } }")
            .getBytes(StandardCharsets.UTF_8),
        512);
    assertThrows(VmTrap.class, wrongReturnRightParameter::run);
    assertArrayEquals(new byte[512], wrongReturnRightParameter.hostOutput());

    VirtualMachine duplicateParameters = new VirtualMachine(
        writerProgram,
        ("classical class DuplicateParameters { "
                + "long add(long value, long value) { return value + value; } "
                + "entry void main() { long answer = add(20, 22); } }")
            .getBytes(StandardCharsets.UTF_8),
        512);
    assertThrows(VmTrap.class, duplicateParameters::run);
    assertArrayEquals(new byte[512], duplicateParameters.hostOutput());

    VirtualMachine reversedParameters = new VirtualMachine(
        writerProgram,
        ("classical class ReversedParameters { "
                + "long subtract(long left, long right) { return right - left; } "
                + "entry void main() { long answer = subtract(64, 22); } }")
            .getBytes(StandardCharsets.UTF_8),
        512);
    assertThrows(VmTrap.class, reversedParameters::run);
    assertArrayEquals(new byte[512], reversedParameters.hostOutput());

    VirtualMachine missingPairPreludeSource = new VirtualMachine(
        writerProgram,
        ("classical class MissingPairPreludeSource { "
                + "long add(long left, long right) { "
                + "long result = left + missing; return result; } "
                + "entry void main() { long answer = add(20, 22); } }")
            .getBytes(StandardCharsets.UTF_8),
        512);
    assertThrows(VmTrap.class, missingPairPreludeSource::run);
    assertArrayEquals(new byte[512], missingPairPreludeSource.hostOutput());

    VirtualMachine thirdEntryPrelude = new VirtualMachine(
        writerProgram,
        ("classical class ThirdEntryPrelude { "
                + "long add(long left, long right) { return left + right; } "
                + "entry void main() { long first = 20; long second = 22; long third = 0; "
                + "long answer = add(first, second); } }")
            .getBytes(StandardCharsets.UTF_8),
        512);
    assertThrows(VmTrap.class, thirdEntryPrelude::run);
    assertArrayEquals(new byte[512], thirdEntryPrelude.hostOutput());

    VirtualMachine missingCallArgument = new VirtualMachine(
        writerProgram,
        ("classical class MissingCallArgument { long identity(long value) { return value; } "
                + "entry void main() { long answer = identity(); } }")
            .getBytes(StandardCharsets.UTF_8),
        512);
    assertThrows(VmTrap.class, missingCallArgument::run);
    assertArrayEquals(new byte[512], missingCallArgument.hostOutput());

    VirtualMachine unexpectedCallArgument = new VirtualMachine(
        writerProgram,
        ("classical class UnexpectedCallArgument { long answer() { return 42; } "
                + "entry void main() { long value = answer(1); } }")
            .getBytes(StandardCharsets.UTF_8),
        512);
    assertThrows(VmTrap.class, unexpectedCallArgument::run);
    assertArrayEquals(new byte[512], unexpectedCallArgument.hostOutput());

    VirtualMachine missingLocalCallArgument = new VirtualMachine(
        writerProgram,
        ("classical class MissingLocalCallArgument { "
                + "long identity(long value) { return value; } "
                + "entry void main() { long answer = identity(missing); } }")
            .getBytes(StandardCharsets.UTF_8),
        512);
    assertThrows(VmTrap.class, missingLocalCallArgument::run);
    assertArrayEquals(new byte[512], missingLocalCallArgument.hostOutput());

    VirtualMachine booleanCallArgument = new VirtualMachine(
        writerProgram,
        ("classical class BooleanCallArgument { long identity(long value) { return value; } "
                + "entry void main() { boolean flag = true; long answer = identity(flag); } }")
            .getBytes(StandardCharsets.UTF_8),
        512);
    assertThrows(VmTrap.class, booleanCallArgument::run);
    assertArrayEquals(new byte[512], booleanCallArgument.hostOutput());

    VirtualMachine booleanTwoArgument = new VirtualMachine(
        writerProgram,
        ("classical class BooleanTwoArgument { "
                + "long add(long left, long right) { return left + right; } "
                + "entry void main() { boolean flag = true; long answer = add(flag, 1); } }")
            .getBytes(StandardCharsets.UTF_8),
        512);
    assertThrows(VmTrap.class, booleanTwoArgument::run);
    assertArrayEquals(new byte[512], booleanTwoArgument.hostOutput());

    VirtualMachine wrongResultHelper = new VirtualMachine(
        writerProgram,
        ("classical class WrongResultHelper { long answer() { return 42; } "
                + "entry void main() { long value = other(); } }")
            .getBytes(StandardCharsets.UTF_8),
        512);
    assertThrows(VmTrap.class, wrongResultHelper::run);
    assertArrayEquals(new byte[512], wrongResultHelper.hostOutput());

    VirtualMachine valueFromVoid = new VirtualMachine(
        writerProgram,
        ("classical class ValueFromVoid { void answer() { return 42; } "
                + "entry void main() { answer(); } }")
            .getBytes(StandardCharsets.UTF_8),
        512);
    assertThrows(VmTrap.class, valueFromVoid::run);
    assertArrayEquals(new byte[512], valueFromVoid.hostOutput());

    VirtualMachine sixtyFifthHelperStatement = new VirtualMachine(
        writerProgram,
        ("classical class SixtyFiveHelperStatements { state long value = 0; "
            + "void setup() { "
            + "value += 1; ".repeat(65)
            + "} entry void main() { setup(); } }")
            .getBytes(StandardCharsets.UTF_8),
        8192);
    assertThrows(VmTrap.class, sixtyFifthHelperStatement::run);
    assertArrayEquals(new byte[8192], sixtyFifthHelperStatement.hostOutput());

    VirtualMachine sixtyFifthStatement = new VirtualMachine(
        writerProgram,
        ("classical class SixtyFiveLocals { entry void main() { "
            + booleanDeclarations(65)
            + "} }")
            .getBytes(StandardCharsets.UTF_8),
        8192);
    assertThrows(VmTrap.class, sixtyFifthStatement::run);
    assertArrayEquals(new byte[8192], sixtyFifthStatement.hostOutput());

    VirtualMachine unknownLocalCondition = new VirtualMachine(
        writerProgram,
        ("classical class UnknownLocalCondition { state long result = 0; "
                + "entry void main() { if (missing) { result += 1; } } }")
            .getBytes(StandardCharsets.UTF_8),
        512);
    assertThrows(VmTrap.class, unknownLocalCondition::run);
    assertArrayEquals(new byte[512], unknownLocalCondition.hostOutput());

    VirtualMachine unknownNegatedLocalCondition = new VirtualMachine(
        writerProgram,
        ("classical class UnknownNegatedLocalCondition { state long result = 0; "
                + "entry void main() { if (!missing) { result += 1; } } }")
            .getBytes(StandardCharsets.UTF_8),
        512);
    assertThrows(VmTrap.class, unknownNegatedLocalCondition::run);
    assertArrayEquals(new byte[512], unknownNegatedLocalCondition.hostOutput());

    VirtualMachine unknownLocalAssignment = new VirtualMachine(
        writerProgram,
        ("classical class UnknownLocalAssignment { state long result = 0; "
                + "entry void main() { result = missing; } }")
            .getBytes(StandardCharsets.UTF_8),
        512);
    assertThrows(VmTrap.class, unknownLocalAssignment::run);
    assertArrayEquals(new byte[512], unknownLocalAssignment.hostOutput());

    VirtualMachine booleanLocalAssignment = new VirtualMachine(
        writerProgram,
        ("classical class BooleanLocalAssignment { state long result = 0; "
                + "entry void main() { boolean answer = true; result = answer; } }")
            .getBytes(StandardCharsets.UTF_8),
        512);
    assertThrows(VmTrap.class, booleanLocalAssignment::run);
    assertArrayEquals(new byte[512], booleanLocalAssignment.hostOutput());

    VirtualMachine unknownLocalUpdate = new VirtualMachine(
        writerProgram,
        ("classical class UnknownLocalUpdate { state long result = 0; "
                + "entry void main() { result += missing; } }")
            .getBytes(StandardCharsets.UTF_8),
        512);
    assertThrows(VmTrap.class, unknownLocalUpdate::run);
    assertArrayEquals(new byte[512], unknownLocalUpdate.hostOutput());

    VirtualMachine booleanLocalUpdate = new VirtualMachine(
        writerProgram,
        ("classical class BooleanLocalUpdate { state long result = 0; "
                + "entry void main() { boolean delta = true; result += delta; } }")
            .getBytes(StandardCharsets.UTF_8),
        512);
    assertThrows(VmTrap.class, booleanLocalUpdate::run);
    assertArrayEquals(new byte[512], booleanLocalUpdate.hostOutput());

    VirtualMachine unknownGuardedLocalUpdate = new VirtualMachine(
        writerProgram,
        ("classical class UnknownGuardedLocalUpdate { state long result = 0; "
                + "entry void main() { boolean ready = true; "
                + "if (ready) { result += missing; } } }")
            .getBytes(StandardCharsets.UTF_8),
        512);
    assertThrows(VmTrap.class, unknownGuardedLocalUpdate::run);
    assertArrayEquals(new byte[512], unknownGuardedLocalUpdate.hostOutput());

    VirtualMachine booleanGuardedLocalUpdate = new VirtualMachine(
        writerProgram,
        ("classical class BooleanGuardedLocalUpdate { state long result = 0; "
                + "entry void main() { boolean ready = true; boolean delta = true; "
                + "if (ready) { result += delta; } } }")
            .getBytes(StandardCharsets.UTF_8),
        512);
    assertThrows(VmTrap.class, booleanGuardedLocalUpdate::run);
    assertArrayEquals(new byte[512], booleanGuardedLocalUpdate.hostOutput());

    VirtualMachine booleanLessThanCondition = new VirtualMachine(
        writerProgram,
        ("classical class BooleanLessThanCondition { state long result = 0; "
                + "entry void main() { boolean answer = true; "
                + "if (answer < 1) { result += 1; } } }")
            .getBytes(StandardCharsets.UTF_8),
        512);
    assertThrows(VmTrap.class, booleanLessThanCondition::run);
    assertArrayEquals(new byte[512], booleanLessThanCondition.hostOutput());

    VirtualMachine booleanEqualityCondition = new VirtualMachine(
        writerProgram,
        ("classical class BooleanEqualityCondition { state long result = 0; "
                + "entry void main() { boolean answer = true; "
                + "if (answer == 1) { result += 1; } } }")
            .getBytes(StandardCharsets.UTF_8),
        512);
    assertThrows(VmTrap.class, booleanEqualityCondition::run);
    assertArrayEquals(new byte[512], booleanEqualityCondition.hostOutput());

    VirtualMachine booleanLiteralEquality = new VirtualMachine(
        writerProgram,
        ("classical class BooleanLiteralEquality { entry void main() { "
                + "boolean answer = true; boolean same = answer == 1; } }")
            .getBytes(StandardCharsets.UTF_8),
        512);
    assertThrows(VmTrap.class, booleanLiteralEquality::run);
    assertArrayEquals(new byte[512], booleanLiteralEquality.hostOutput());

    VirtualMachine booleanLiteralLessThan = new VirtualMachine(
        writerProgram,
        ("classical class BooleanLiteralLessThan { entry void main() { "
                + "boolean answer = true; boolean less = answer < 1; } }")
            .getBytes(StandardCharsets.UTF_8),
        512);
    assertThrows(VmTrap.class, booleanLiteralLessThan::run);
    assertArrayEquals(new byte[512], booleanLiteralLessThan.hostOutput());

    VirtualMachine booleanLessThan = new VirtualMachine(
        writerProgram,
        ("classical class BooleanLessThan { entry void main() { "
                + "boolean first = false; boolean second = true; "
                + "boolean less = first < second; } }")
            .getBytes(StandardCharsets.UTF_8),
        512);
    assertThrows(VmTrap.class, booleanLessThan::run);
    assertArrayEquals(new byte[512], booleanLessThan.hostOutput());

    VirtualMachine mixedLocalEquality = new VirtualMachine(
        writerProgram,
        ("classical class MixedLocalEquality { entry void main() { "
                + "long first = 1; boolean second = true; "
                + "boolean same = first == second; } }")
            .getBytes(StandardCharsets.UTF_8),
        512);
    assertThrows(VmTrap.class, mixedLocalEquality::run);
    assertArrayEquals(new byte[512], mixedLocalEquality.hostOutput());

    VirtualMachine unresolvedBooleanCopy = new VirtualMachine(
        writerProgram,
        "classical class UnknownBooleanCopy { entry void main() { boolean result = missing; } }"
            .getBytes(StandardCharsets.UTF_8),
        512);
    assertThrows(VmTrap.class, unresolvedBooleanCopy::run);
    assertArrayEquals(new byte[512], unresolvedBooleanCopy.hostOutput());

    VirtualMachine unresolvedBooleanNot = new VirtualMachine(
        writerProgram,
        "classical class UnknownBooleanNot { entry void main() { boolean result = !missing; } }"
            .getBytes(StandardCharsets.UTF_8),
        512);
    assertThrows(VmTrap.class, unresolvedBooleanNot::run);
    assertArrayEquals(new byte[512], unresolvedBooleanNot.hostOutput());

    VirtualMachine unresolvedSignedCopy = new VirtualMachine(
        writerProgram,
        "classical class UnknownSignedCopy { entry void main() { long result = missing; } }"
            .getBytes(StandardCharsets.UTF_8),
        512);
    assertThrows(VmTrap.class, unresolvedSignedCopy::run);
    assertArrayEquals(new byte[512], unresolvedSignedCopy.hostOutput());

    VirtualMachine unresolvedSignedAdd = new VirtualMachine(
        writerProgram,
        "classical class UnknownSignedAdd { entry void main() { long result = missing + 1; } }"
            .getBytes(StandardCharsets.UTF_8),
        512);
    assertThrows(VmTrap.class, unresolvedSignedAdd::run);
    assertArrayEquals(new byte[512], unresolvedSignedAdd.hostOutput());

    VirtualMachine unresolvedSignedPair = new VirtualMachine(
        writerProgram,
        ("classical class UnknownSignedPair { entry void main() { "
                + "long first = 1; long result = first + missing; } }")
            .getBytes(StandardCharsets.UTF_8),
        512);
    assertThrows(VmTrap.class, unresolvedSignedPair::run);
    assertArrayEquals(new byte[512], unresolvedSignedPair.hostOutput());

    VirtualMachine unresolvedLocal = new VirtualMachine(
        writerProgram,
        "classical class UnknownLocal { entry void main() { assert(missing); } }"
            .getBytes(StandardCharsets.UTF_8),
        512);
    assertThrows(VmTrap.class, unresolvedLocal::run);
    assertArrayEquals(new byte[512], unresolvedLocal.hostOutput());

    VirtualMachine unresolvedHelperLocal = new VirtualMachine(
        writerProgram,
        ("classical class UnknownHelperLocal { state long total = 0; "
            + "void setup() { assert(missing); } entry void main() { setup(); } }")
            .getBytes(StandardCharsets.UTF_8),
        512);
    assertThrows(VmTrap.class, unresolvedHelperLocal::run);
    assertArrayEquals(new byte[512], unresolvedHelperLocal.hostOutput());
  }

  private static String booleanDeclarations(int count) {
    StringBuilder source = new StringBuilder();
    for (int index = 0; index < count; index++) {
      source.append("boolean value").append(index).append(" = true; ");
    }
    return source.toString();
  }
}
