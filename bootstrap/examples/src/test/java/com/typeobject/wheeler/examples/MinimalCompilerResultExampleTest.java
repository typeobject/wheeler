package com.typeobject.wheeler.examples;

import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.OPERATION;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.RIGHT_SOURCE;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.SOURCE;
import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeReader;
import com.typeobject.wheeler.core.bytecode.Opcode;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.MachineStatus;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import java.nio.charset.StandardCharsets;
import org.junit.jupiter.api.Test;

/** Differential tests for bounded scalar helper parameters and results. */
class MinimalCompilerResultExampleTest {
  @Test
  void compilesReversibleSignedResultSlots() throws Exception {
    Program writerProgram = CompilerSources.minimalCompilerProgram();

    Program artifact = assertDifferentialHalt(
        writerProgram,
        "classical class ReversibleResult { const long RESULT = -1; "
            + "rev long minusOne() { return RESULT; } "
            + "theorem minusOneInverse proves inverse(minusOne); "
            + "entry void main() { long value = minusOne(); assert(value == -1); } }");

    assertTrue(artifact.function(0).implicitResultSlot());
    assertEquals(artifact.function(0).forward(), artifact.function(0).inverse());
    assertEquals(1, artifact.proofCertificates().size());

    assertDifferentialHalt(
        writerProgram,
        "classical class InterleavedReversibleResult { rev long answer() { return -1; } "
            + "entry void main() { long first = answer(); assert(first == -1); "
            + "long second = answer(); assert(second == -1); assert(first == -1); "
            + "assert(first == second); } }");

    assertDifferentialHalt(
        writerProgram,
        "classical class ParameterReversibleResult { rev long answer(long ignored) { "
            + "return -1; } entry void main() { long first = answer(42); "
            + "long second = answer(first); assert(first == second); } }");

    Program preserved = assertDifferentialHalt(
        writerProgram,
        "classical class PreservedReversibleResult { "
            + "rev long identity(long value) { return value; } "
            + "theorem identityInverse proves inverse(identity); "
            + "entry void main() { long first = identity(42); "
            + "long second = identity(first); assert(first == second); } }");
    assertEquals(Opcode.RESULT_FILL_SOURCE, preserved.function(0).forward().getFirst().opcode());
    assertEquals(preserved.function(0).forward(), preserved.function(0).inverse());

    String[][] computedCases = {
        {"+", Long.toString(Opcode.LOCAL_ADD.code()), "34", "8", "42"},
        {"-", Long.toString(Opcode.LOCAL_SUB.code()), "50", "8", "42"},
        {"*", Long.toString(Opcode.LOCAL_MUL.code()), "21", "2", "42"},
        {"/", Long.toString(Opcode.LOCAL_DIV.code()), "84", "2", "42"},
        {"%", Long.toString(Opcode.LOCAL_MOD.code()), "44", "42", "2"},
        {"^", Long.toString(Opcode.LOCAL_XOR.code()), "40", "2", "42"},
        {"&", Long.toString(Opcode.LOCAL_AND.code()), "47", "42", "42"}
    };
    for (String[] candidate : computedCases) {
      Program computed = assertDifferentialHalt(
          writerProgram,
          "classical class ComputedReversibleResult { "
              + "rev long compute(long value) { return value " + candidate[0] + " "
              + candidate[3] + "; } entry void main() { long answer = compute("
              + candidate[2] + "); assert(answer == " + candidate[4] + "); } }");
      assertEquals(Opcode.RESULT_FILL_BINARY, computed.function(0).forward().getFirst().opcode());
      assertEquals(
          Long.parseLong(candidate[1]),
          computed.function(0).forward().getFirst().operand(OPERATION));
    }

    Program computedConstant = assertDifferentialHalt(
        writerProgram,
        "classical class ComputedConstantReversibleResult { const long STEP = 8; "
            + "rev long compute(long value) { return value + STEP; } "
            + "theorem computeInverse proves inverse(compute); "
            + "entry void main() { long answer = compute(34); assert(answer == 42); } }");
    assertEquals(1, computedConstant.proofCertificates().size());

    Program computedSecond = assertDifferentialHalt(
        writerProgram,
        "classical class ComputedSecondReversibleResult { "
            + "rev long compute(long ignored, long value) { return value + 8; } "
            + "entry void main() { long answer = compute(1, 34); "
            + "assert(answer == 42); } }");
    assertEquals(1, computedSecond.function(0).forward().getFirst().operand(SOURCE));

    for (String[] candidate : computedCases) {
      Program computedSources = assertDifferentialHalt(
          writerProgram,
          "classical class ComputedSourceReversibleResult { "
              + "rev long compute(long left, long right) { return left " + candidate[0]
              + " right; } theorem computeInverse proves inverse(compute); "
              + "entry void main() { long answer = compute(" + candidate[2] + ", "
              + candidate[3] + "); assert(answer == " + candidate[4] + "); } }");
      var sourceFill = computedSources.function(0).forward().getFirst();
      assertEquals(Opcode.RESULT_FILL_BINARY_SOURCES, sourceFill.opcode());
      assertEquals(Long.parseLong(candidate[1]), sourceFill.operand(OPERATION));
      assertEquals(0, sourceFill.operand(SOURCE));
      assertEquals(1, sourceFill.operand(RIGHT_SOURCE));
      assertEquals(
          computedSources.function(0).forward(), computedSources.function(0).inverse());
    }

    for (String[] candidate : computedCases) {
      assertDifferentialHalt(
          writerProgram,
          "classical class ComputedPreludeReversibleResult { "
              + "rev long compute(long left, long right) { long result = left "
              + candidate[0] + " right; return result; } "
              + "entry void main() { long answer = compute(" + candidate[2] + ", "
              + candidate[3] + "); assert(answer == " + candidate[4] + "); } }");
    }

    Program computedPreludeConstant = assertDifferentialHalt(
        writerProgram,
        "classical class ComputedPreludeConstantResult { const long STEP = 8; "
            + "rev long compute(long value) { long result = value + STEP; "
            + "return result; } theorem computeInverse proves inverse(compute); "
            + "entry void main() { long answer = compute(34); assert(answer == 42); } }");
    assertEquals(Opcode.RESULT_FILL_BINARY,
        computedPreludeConstant.function(0).forward().getFirst().opcode());
    assertEquals(1, computedPreludeConstant.proofCertificates().size());

    Program selectedSecondPrelude = assertDifferentialHalt(
        writerProgram,
        "classical class SelectedSecondPreludeResult { "
            + "rev long compute(long left, long right) { "
            + "long ignored = left - right; long result = left + right; return result; } "
            + "entry void main() { long answer = compute(20, 22); assert(answer == 42); } }");
    assertEquals(Opcode.RESULT_FILL_BINARY_SOURCES,
        selectedSecondPrelude.function(0).forward().getFirst().opcode());
    assertEquals(Opcode.LOCAL_ADD.code(),
        selectedSecondPrelude.function(0).forward().getFirst().operand(OPERATION));

    Program selectedFirstPrelude = assertDifferentialHalt(
        writerProgram,
        "classical class SelectedFirstPreludeResult { "
            + "rev long compute(long left, long right) { "
            + "long result = left + right; long ignored = left - right; return result; } "
            + "entry void main() { long answer = compute(20, 22); assert(answer == 42); } }");
    assertEquals(Opcode.LOCAL_ADD.code(),
        selectedFirstPrelude.function(0).forward().getFirst().operand(OPERATION));

    assertDifferentialHalt(
        writerProgram,
        "classical class PreservedSecondResult { "
            + "rev long select(long left, long right) { return right; } "
            + "entry void main() { long value = select(1, 42); assert(value == 42); } }");

    assertDifferentialHalt(
        writerProgram,
        "classical class TwoParameterReversibleResult { "
            + "rev long answer(long left, long right) { return -1; } "
            + "entry void main() { long first = answer(1, 2); "
            + "long second = answer(first, 3); long third = answer(4, second); "
            + "long fourth = answer(first, third); assert(first == fourth); } }");
  }

  @Test
  void compilesSignedHelperResultsAndCheckedArithmetic() throws Exception {
    Program writerProgram = CompilerSources.minimalCompilerProgram();

    assertDifferentialHalt(
        writerProgram,
        "classical class BooleanResultHelper { boolean ready() { return true; } "
            + "entry void main() { boolean value = ready(); assert(value); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class BooleanFalseResultHelper { boolean ready() { return false; } "
            + "entry void main() { boolean value = ready(); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class BooleanLocalResultHelper { "
            + "boolean ready() { boolean result = true; return result; } "
            + "entry void main() { boolean value = ready(); assert(value); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class RepeatedBooleanResultCalls { boolean ready() { return true; } "
            + "entry void main() { boolean first = ready(); boolean second = ready(); "
            + "assert(first == second); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class BooleanParameterLiteral { "
            + "boolean identity(boolean value) { return value; } "
            + "entry void main() { boolean result = identity(true); assert(result); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class BooleanParameterLocal { "
            + "boolean identity(boolean value) { boolean result = value; return result; } "
            + "entry void main() { boolean seed = true; boolean result = identity(seed); "
            + "assert(result); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class BooleanParameterFalse { "
            + "boolean identity(boolean value) { return value; } "
            + "entry void main() { boolean result = identity(false); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class BooleanParameterNot { "
            + "boolean invert(boolean value) { return !value; } "
            + "entry void main() { boolean result = invert(false); assert(result); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class BooleanLocalNotResult { "
            + "boolean invert(boolean value) { boolean copy = value; return !copy; } "
            + "entry void main() { boolean result = invert(false); assert(result); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class BooleanParameterLiteralEquality { "
            + "boolean isFalse(boolean value) { return value == false; } "
            + "entry void main() { boolean result = isFalse(false); assert(result); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class BooleanParameterDirectEquality { "
            + "boolean same(boolean left, boolean right) { return left == right; } "
            + "entry void main() { boolean result = same(true, true); assert(result); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class BooleanLocalDirectEquality { "
            + "boolean ready() { boolean left = true; boolean right = true; "
            + "return left == right; } "
            + "entry void main() { boolean result = ready(); assert(result); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class BooleanParameterLiteralInequality { "
            + "boolean isTrue(boolean value) { return value != false; } "
            + "entry void main() { boolean result = isTrue(true); assert(result); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class BooleanParameterDirectInequality { "
            + "boolean different(boolean left, boolean right) { return left != right; } "
            + "entry void main() { boolean result = different(true, false); assert(result); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class BooleanLocalInequalityResult { "
            + "boolean different(boolean left, boolean right) { "
            + "boolean result = left != right; return result; } "
            + "entry void main() { boolean result = different(true, false); assert(result); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class BooleanParameterPair { "
            + "boolean same(boolean left, boolean right) { "
            + "boolean result = left == right; return result; } "
            + "entry void main() { boolean left = true; boolean right = true; "
            + "boolean literals = same(true, true); boolean first = same(left, true); "
            + "boolean second = same(true, right); boolean locals = same(left, right); "
            + "assert(literals); assert(first); assert(second); assert(locals); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class BooleanResultSignedParameter { "
            + "boolean negative(long value) { boolean result = value < 0; return result; } "
            + "entry void main() { long input = -42; boolean literal = negative(-42); "
            + "boolean local = negative(input); assert(literal); assert(local); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class BooleanResultSignedPair { "
            + "boolean different(long left, long right) { "
            + "boolean result = left != right; return result; } "
            + "entry void main() { long left = 41; long right = 42; "
            + "boolean literals = different(41, 42); "
            + "boolean first = different(left, 42); "
            + "boolean second = different(41, right); "
            + "boolean locals = different(left, right); "
            + "assert(literals); assert(first); assert(second); assert(locals); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class SignedParameterDirectEquality { "
            + "boolean answer(long value) { return value == 42; } "
            + "entry void main() { boolean result = answer(42); assert(result); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class SignedParameterDirectInequality { "
            + "boolean different(long value) { return value != 42; } "
            + "entry void main() { boolean result = different(41); assert(result); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class SignedParameterDirectLessThan { "
            + "boolean negative(long value) { return value < 0; } "
            + "entry void main() { boolean result = negative(-42); assert(result); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class SignedPairDirectComparisons { "
            + "boolean ordered(long left, long right) { return left < right; } "
            + "entry void main() { long left = 41; long right = 42; "
            + "boolean literals = ordered(41, 42); "
            + "boolean locals = ordered(left, right); assert(literals); assert(locals); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class SignedPairDirectEquality { "
            + "boolean same(long left, long right) { return left == right; } "
            + "entry void main() { boolean result = same(42, 42); assert(result); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class SignedPairDirectInequality { "
            + "boolean different(long left, long right) { return left != right; } "
            + "entry void main() { boolean result = different(41, 42); assert(result); } }");

    assertDifferentialHalt(
        writerProgram,
        "classical class BoundedLocalWhileLiterals { entry void main() { "
            + "long index = 0; while (index < 3) limit 3 { index += 1; } "
            + "assert(index == 3); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class BoundedLocalWhileNamed { entry void main() { "
            + "long index = 0; long count = 3; long bound = 3; "
            + "while (index < count) limit bound { index += 1; } "
            + "assert(index == 3); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class BoundedLocalWhileCountdown { entry void main() { "
            + "long value = 3; while (0 < value) limit 3 { value -= 1; } "
            + "assert(value == 0); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class BoundedLocalWhileXor { entry void main() { "
            + "long value = 0; while (value < 1) limit 1 { value ^= 1; } "
            + "assert(value == 1); } }");
    assertDifferentialTrap(
        writerProgram,
        "classical class BoundedLocalWhileSubtract { entry void main() { "
            + "long value = 0; while (value < 1) limit 2 { value -= 1; } } }");

    assertDifferentialHalt(
        writerProgram,
        "classical class SignedLocalAssignments { entry void main() { "
            + "long value = 1; long answer = 42; value = 41; value = answer; "
            + "assert(value == 42); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class BooleanLocalAssignments { entry void main() { "
            + "boolean value = false; boolean ready = true; value = true; value = ready; "
            + "assert(value); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class SignedParameterAssignment { "
            + "long answer(long value) { value = 42; return value; } "
            + "entry void main() { long result = answer(1); assert(result == 42); } }");

    assertDifferentialHalt(
        writerProgram,
        "classical class SignedLocalLiteralUpdates { entry void main() { "
            + "long value = 40; value += 2; value -= 1; value ^= 1; "
            + "assert(value == 40); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class SignedLocalNamedUpdates { entry void main() { "
            + "long value = 40; long two = 2; long one = 1; "
            + "value += two; value -= one; value ^= one; assert(value == 40); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class SignedParameterUpdates { "
            + "long adjust(long value) { value += 2; value -= 1; value ^= 1; return value; } "
            + "entry void main() { long answer = adjust(40); assert(answer == 40); } }");

    assertDifferentialHalt(
        writerProgram,
        "classical class SignedResultHelper { long answer() { return -42; } "
            + "entry void main() { long value = answer(); assert(value == -42); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class SignedResultLocalHelper { "
            + "long answer() { long base = 20; long result = base + 22; return result; } "
            + "entry void main() { long value = answer(); assert(value == 42); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class SignedParameterHelper { long identity(long value) { return value; } "
            + "entry void main() { long answer = identity(-42); "
            + "assert(answer == -42); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class SignedTwoParameterAdd { "
            + "long add(long left, long right) { return left + right; } "
            + "entry void main() { long answer = add(20, 22); assert(answer == 42); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class SignedTwoParameterLocalResult { "
            + "long add(long left, long right) { long result = left + right; return result; } "
            + "entry void main() { long answer = add(20, 22); assert(answer == 42); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class SignedTwoLocalArguments { "
            + "long add(long left, long right) { return left + right; } "
            + "entry void main() { long first = 20; long second = 22; long ignored = 0; "
            + "long answer = add(first, second); assert(answer == 42); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class RepeatedSignedResultCalls { "
            + "long increment(long value) { return value + 1; } "
            + "entry void main() { long first = increment(20); "
            + "long second = increment(first); assert(second == 22); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class SignedTwoParameterFirstLocal { "
            + "long add(long left, long right) { return left + right; } "
            + "entry void main() { long left = 20; long answer = add(left, 22); "
            + "assert(answer == 42); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class SignedTwoParameterSecondLocal { "
            + "long add(long left, long right) { return left + right; } "
            + "entry void main() { long right = 22; long answer = add(20, right); "
            + "assert(answer == 42); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class SignedTwoParameterBothLocal { "
            + "long add(long left, long right) { return left + right; } "
            + "entry void main() { long half = 21; long answer = add(half, half); "
            + "assert(answer == 42); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class SignedTwoParameterSubtract { "
            + "long subtract(long left, long right) { return left - right; } "
            + "entry void main() { long answer = subtract(64, 22); assert(answer == 42); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class SignedTwoParameterMultiply { "
            + "long multiply(long left, long right) { return left * right; } "
            + "entry void main() { long answer = multiply(6, 7); assert(answer == 42); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class SignedTwoParameterDivide { "
            + "long divide(long left, long right) { return left / right; } "
            + "entry void main() { long answer = divide(84, 2); assert(answer == 42); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class SignedTwoParameterRemainder { "
            + "long remainder(long left, long right) { return left % right; } "
            + "entry void main() { long answer = remainder(85, 43); assert(answer == 42); } }");
    assertDifferentialTrap(
        writerProgram,
        "classical class SignedTwoParameterDivideZero { "
            + "long divide(long left, long right) { return left / right; } "
            + "entry void main() { long answer = divide(42, 0); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class SignedParameterPairAdd { long twice(long value) { return value + value; } "
            + "entry void main() { long answer = twice(21); assert(answer == 42); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class SignedParameterPairSubtract { "
            + "long zero(long value) { return value - value; } "
            + "entry void main() { long answer = zero(42); assert(answer == 0); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class SignedParameterPairMultiply { "
            + "long square(long value) { return value * value; } "
            + "entry void main() { long answer = square(6); assert(answer == 36); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class SignedParameterPairDivide { "
            + "long unit(long value) { return value / value; } "
            + "entry void main() { long answer = unit(42); assert(answer == 1); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class SignedParameterPairRemainder { "
            + "long zero(long value) { return value % value; } "
            + "entry void main() { long answer = zero(42); assert(answer == 0); } }");
    assertDifferentialTrap(
        writerProgram,
        "classical class SignedParameterPairDivideZero { "
            + "long fail(long value) { return value / value; } "
            + "entry void main() { long answer = fail(0); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class SignedParameterAdd { long increment(long value) { return value + 1; } "
            + "entry void main() { long answer = increment(41); "
            + "assert(answer == 42); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class SignedParameterLocalResult { "
            + "long increment(long value) { long result = value + 1; return result; } "
            + "entry void main() { long answer = increment(41); assert(answer == 42); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class SignedParameterLocalChain { "
            + "long adjust(long value) { "
            + "long doubled = value * 2; long result = doubled - 42; return result; } "
            + "entry void main() { long answer = adjust(42); assert(answer == 42); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class SignedLocalArgument { long increment(long value) { return value + 1; } "
            + "entry void main() { long seed = 41; long answer = increment(seed); "
            + "assert(answer == 42); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class SignedParameterSubtract { "
            + "long adjust(long value) { return value - 2; } "
            + "entry void main() { long answer = adjust(44); assert(answer == 42); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class SignedParameterMultiply { "
            + "long doubleValue(long value) { return value * 2; } "
            + "entry void main() { long answer = doubleValue(21); assert(answer == 42); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class SignedParameterDivide { "
            + "long half(long value) { return value / 2; } "
            + "entry void main() { long answer = half(84); assert(answer == 42); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class SignedParameterRemainder { "
            + "long reduce(long value) { return value % 43; } "
            + "entry void main() { long answer = reduce(85); assert(answer == 42); } }");
    assertDifferentialTrap(
        writerProgram,
        "classical class SignedParameterDivideZero { "
            + "long fail(long value) { return value / 0; } "
            + "entry void main() { long answer = fail(42); } }");
    assertDifferentialTrap(
        writerProgram,
        "classical class SignedParameterOverflow { "
            + "long increment(long value) { return value + 1; } "
            + "entry void main() { long answer = increment(9223372036854775807); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class SignedParameterXorLiteral { "
            + "long mask(long value) { return value ^ 3; } "
            + "entry void main() { long answer = mask(41); assert(answer == 42); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class SignedParameterXorItself { "
            + "long clear(long value) { return value ^ value; } "
            + "entry void main() { long answer = clear(42); assert(answer == 0); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class SignedParameterXorPair { "
            + "long xor(long left, long right) { return left ^ right; } "
            + "entry void main() { long answer = xor(40, 2); assert(answer == 42); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class SignedParameterAndLiteral { "
            + "long mask(long value) { return value & 63; } "
            + "entry void main() { long answer = mask(106); assert(answer == 42); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class SignedParameterAndPair { "
            + "long and(long left, long right) { return left & right; } "
            + "entry void main() { long answer = and(47, 58); assert(answer == 42); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class SignedLocalAndLiteral { "
            + "long mask(long value) { long result = value & 63; return result; } "
            + "entry void main() { long answer = mask(106); assert(answer == 42); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class SignedLocalAndPair { "
            + "long mask(long left, long right) { long result = left & right; return result; } "
            + "entry void main() { long answer = mask(47, 58); assert(answer == 42); } }");
  }

  private static Program assertDifferentialHalt(Program writerProgram, String source) {
    VirtualMachine writer = writer(writerProgram, source);
    runWriter(writer, writerProgram);
    byte[] expected = new WheelerCompiler().compileToBytecode(source);
    assertEquals(expected.length, writer.hostOutput().length);
    assertArrayEquals(expected, writer.hostOutput());
    Program artifactProgram = new BytecodeReader().read(writer.hostOutput());
    VirtualMachine artifact = new VirtualMachine(artifactProgram);
    artifact.run();
    assertEquals(MachineStatus.HALTED, artifact.status());
    return artifactProgram;
  }

  private static void assertDifferentialTrap(Program writerProgram, String source) {
    VirtualMachine writer = writer(writerProgram, source);
    runWriter(writer, writerProgram);
    assertArrayEquals(new WheelerCompiler().compileToBytecode(source), writer.hostOutput());

    VirtualMachine artifact = new VirtualMachine(new BytecodeReader().read(writer.hostOutput()));
    assertThrows(VmTrap.class, artifact::run);
  }

  private static void runWriter(VirtualMachine writer, Program writerProgram) {
    try {
      CompilerMachineRunner.runWithoutRewindHistory(writer);
    } catch (VmTrap trap) {
      throw new AssertionError(
          "Wheeler compiler trapped at instruction "
              + writer.snapshot().selectedFrames().getLast().programCounter()
              + " (" + writerProgramInstruction(writer, writerProgram) + ")"
              + ", output cursor " + writer.global("finalCursor")
              + ", and verification " + writer.global("verification"),
          trap);
    }
  }

  private static String writerProgramInstruction(VirtualMachine writer, Program writerProgram) {
    var frame = writer.snapshot().selectedFrames().getLast();
    return writerProgram.function(frame.functionId()).name() + " "
        + writerProgram.function(frame.functionId()).forward().get(frame.programCounter()).toString();
  }

  private static VirtualMachine writer(Program writerProgram, String source) {
    return new VirtualMachine(
        writerProgram,
        source.getBytes(StandardCharsets.UTF_8),
        8192);
  }
}
