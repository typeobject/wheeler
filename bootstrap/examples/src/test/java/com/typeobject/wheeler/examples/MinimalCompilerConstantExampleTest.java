package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.compiler.CompilerException;
import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeReader;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.MachineStatus;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import java.nio.charset.StandardCharsets;
import org.junit.jupiter.api.Test;

/** Differential coverage for the Wheeler-native scalar class-constant slice. */
class MinimalCompilerConstantExampleTest {
  private static final int OUTPUT_CAPACITY = 8_192;
  private static final int MAX_NATIVE_CONSTANTS = 128;
  private static final int MAX_NATIVE_DEPENDENCY_DEPTH = 64;

  @Test
  void substitutesSignedAndBooleanConstantsWithoutRuntimeState() throws Exception {
    Program compiler = CompilerSources.minimalCompilerProgram();
    String source = "classical class ScalarConstants { "
        + "public const long ANSWER = BASE - 2; private const boolean READY = ANSWER < 0; "
        + "const long BASE = -40; entry void main() { long answer = ANSWER; "
        + "boolean ready = READY; "
        + "boolean blocked = !READY; assert(answer == -42); assert(ready); } }";

    byte[] artifact = assertDifferentialHalt(compiler, source);
    Program decoded = new BytecodeReader().read(artifact);
    assertEquals(0, decoded.globals().size());
  }

  @Test
  void substitutesConstantsInStatefulAndValueReturningClasses() throws Exception {
    Program compiler = CompilerSources.minimalCompilerProgram();
    assertDifferentialHalt(
        compiler,
        "classical class StatefulConstants { state long value = 0; "
            + "const long ANSWER = 42; entry void main() { long answer = ANSWER; "
            + "value += answer; assert(value == 42); } }");
    assertDifferentialHalt(
        compiler,
        "classical class ConstantResults { const long ANSWER = BASE - 2; "
            + "const long BASE = -40; long answer() { return ANSWER; } entry void main() { "
            + "long result = answer(); assert(result == -42); } }");
    assertDifferentialHalt(
        compiler,
        "classical class ConstantBooleanResults { const boolean READY = VALUE == 1; "
            + "const long VALUE = 1; boolean ready() { return READY; } entry void main() { "
            + "boolean result = ready(); assert(result); } }");
  }

  @Test
  void resolvesConstantStateInitializersOnEitherSideOfState() throws Exception {
    Program compiler = CompilerSources.minimalCompilerProgram();
    String prefix = "classical class ConstantStateInitializer { ";
    String body = "entry void main() { value += 0; assert(value == 42); } }";
    String constantsFirst = prefix + "const long INITIAL = BASE + 2; const long BASE = 40; "
        + "state long value = INITIAL; " + body;
    String stateFirst = prefix + "state long value = INITIAL; const long BASE = 40; "
        + "const long INITIAL = BASE + 2; " + body;

    assertArrayEquals(compileNative(compiler, constantsFirst), compileNative(compiler, stateFirst));
    assertArrayEquals(
        new WheelerCompiler().compileToBytecode(constantsFirst),
        new WheelerCompiler().compileToBytecode(stateFirst));
    assertDifferentialHalt(compiler, constantsFirst);
  }

  @Test
  void resolvesConstantsBeforeStatefulHelpers() throws Exception {
    Program compiler = CompilerSources.minimalCompilerProgram();
    assertDifferentialHalt(
        compiler,
        "classical class ConstantBeforeStatefulHelper { const long INITIAL = 40 + 2; "
            + "const long INPUT = INITIAL; state long value = INITIAL; "
            + "long identity(long input) { return input; } entry void main() { "
            + "long result = identity(INPUT); assert(value == 42); assert(result == 42); } }");
  }

  @Test
  void substitutesConstantsIntoGeneratedReversibleUpdates() throws Exception {
    Program compiler = CompilerSources.minimalCompilerProgram();
    assertDifferentialHalt(
        compiler,
        "classical class ReversibleConstantUpdate { state long value = 0; "
            + "const long STEP = 1 + 1; rev void bump() { value += STEP; } "
            + "theorem bumpInverse proves inverse(bump); entry void main() { "
            + "bump(); assert(value == STEP); reverse { bump(); } assert(value == 0); } }");
  }

  @Test
  void passesTypedConstantsToScalarHelpers() throws Exception {
    Program compiler = CompilerSources.minimalCompilerProgram();
    assertDifferentialHalt(
        compiler,
        "classical class SignedConstantArgument { const long INPUT = BASE - 2; "
            + "const long BASE = -40; "
            + "long identity(long value) { return value; } entry void main() { "
            + "long result = identity(INPUT); assert(result == -42); } }");
    assertDifferentialHalt(
        compiler,
        "classical class BooleanConstantArgument { const boolean INPUT = VALUE < 2; "
            + "const long VALUE = 1; "
            + "boolean identity(boolean value) { return value; } entry void main() { "
            + "boolean result = identity(INPUT); assert(result); } }");
  }

  @Test
  void passesConstantsAndLocalsToTwoArgumentScalarHelpers() throws Exception {
    Program compiler = CompilerSources.minimalCompilerProgram();
    assertDifferentialHalt(
        compiler,
        "classical class SignedConstantPair { const long LEFT = 20 * 2; "
            + "const long RIGHT = LEFT - 38; "
            + "long add(long left, long right) { return left + right; } entry void main() { "
            + "long left = 40; long right = 2; long constants = add(LEFT, RIGHT); "
            + "long first = add(left, RIGHT); long second = add(LEFT, right); "
            + "assert(constants == 42); assert(first == 42); assert(second == 42); } }");
    assertDifferentialHalt(
        compiler,
        "classical class BooleanConstantPair { const boolean LEFT = !RIGHT; "
            + "const boolean RIGHT = false; boolean different(boolean left, boolean right) { "
            + "return left != right; } entry void main() { boolean left = true; "
            + "boolean right = false; boolean constants = different(LEFT, RIGHT); "
            + "boolean first = different(left, RIGHT); boolean second = different(LEFT, right); "
            + "assert(constants); assert(first); assert(second); } }");
    assertDifferentialHalt(
        compiler,
        "classical class SignedComparisonConstants { const long LEFT = 41; "
            + "const long RIGHT = 42; boolean ordered(long left, long right) { "
            + "return left < right; } entry void main() { long left = 41; long right = 42; "
            + "boolean constants = ordered(LEFT, RIGHT); boolean first = ordered(left, RIGHT); "
            + "boolean second = ordered(LEFT, right); assert(constants); assert(first); "
            + "assert(second); } }");
  }

  @Test
  void resolvesTypedConstantsInScalarComparisonReturns() throws Exception {
    Program compiler = CompilerSources.minimalCompilerProgram();
    assertDifferentialHalt(
        compiler,
        "classical class ConstantEqualityReturn { const long LIMIT = BASE + 2; "
            + "const long BASE = 40; boolean equal(long value) { return value == LIMIT; } "
            + "entry void main() { boolean result = equal(42); assert(result); } }");
    assertDifferentialHalt(
        compiler,
        "classical class ConstantInequalityReturn { const long LIMIT = 42; "
            + "boolean different(long value) { return value != LIMIT; } entry void main() { "
            + "boolean result = different(41); assert(result); } }");
    assertDifferentialHalt(
        compiler,
        "classical class ConstantOrderingReturn { const long LIMIT = 42; "
            + "boolean ordered(long value) { return value < LIMIT; } entry void main() { "
            + "boolean result = ordered(41); assert(result); } }");
    assertDifferentialHalt(
        compiler,
        "classical class ConstantBooleanEqualityReturn { const boolean EXPECTED = !false; "
            + "boolean equal(boolean value) { return value == EXPECTED; } entry void main() { "
            + "boolean result = equal(true); assert(result); } }");
    assertDifferentialHalt(
        compiler,
        "classical class ConstantBooleanInequalityReturn { const boolean EXPECTED = false; "
            + "boolean different(boolean value) { return value != EXPECTED; } "
            + "entry void main() { boolean result = different(true); assert(result); } }");
  }

  @Test
  void resolvesConstantsInSignedArithmeticReturns() throws Exception {
    Program compiler = CompilerSources.minimalCompilerProgram();
    String[] operators = {"+", "-", "*", "/", "%", "^", "&"};
    long[] expected = {42, 38, 80, 20, 0, 42, 0};
    for (int index = 0; index < operators.length; index++) {
      String source = "classical class ConstantArithmeticReturn { state long outcome = 0; "
          + "const long RIGHT = 1 + 1; long calculate(long left) { return left "
          + operators[index] + " RIGHT; } entry void main() { long result = calculate(40); "
          + "outcome = result; } }";
      byte[] artifact = assertDifferentialHalt(compiler, source);
      VirtualMachine program = new VirtualMachine(new BytecodeReader().read(artifact));
      program.run();
      assertEquals(expected[index], program.global("outcome"));
    }
    assertDifferentialHalt(
        compiler,
        "classical class TwoParameterConstantReturn { const long RIGHT = 2; "
            + "long calculate(long left, long ignored) { return left + RIGHT; } "
            + "entry void main() { long result = calculate(40, 0); assert(result == 42); } }");
  }

  @Test
  void evaluatesTypedConstantExpressionsAndForwardDependencies() throws Exception {
    Program compiler = CompilerSources.minimalCompilerProgram();
    assertDifferentialHalt(
        compiler,
        "classical class ConstantExpressions { const long ANSWER = HALF * 2 + 2; "
            + "const boolean READY = ANSWER == 42; const long HALF = 20; "
            + "const long MASKED = (ANSWER ^ 3) & 63; const long QUOTIENT = 84 / 2; "
            + "const long REMAINDER = 85 % 43; const long RADIX = 0x2_8 + 0b10; "
            + "const long ROTATION = 2 + 2; "
            + "const long ROTATED = rotateRight32(0x2a0, ROTATION); "
            + "const boolean ORDERED = HALF < ANSWER; const boolean BLOCKED = !READY; "
            + "entry void main() { long answer = ANSWER; long masked = MASKED; "
            + "long quotient = QUOTIENT; long remainder = REMAINDER; long radix = RADIX; "
            + "long rotated = ROTATED; "
            + "boolean ready = READY; boolean ordered = ORDERED; boolean blocked = BLOCKED; "
            + "boolean clear = !blocked; assert(answer == 42); assert(masked == 41); "
            + "assert(quotient == 42); assert(remainder == 42); assert(radix == 42); "
            + "assert(rotated == 42); assert(ready); assert(ordered); "
            + "assert(clear); } }");
  }

  @Test
  void substitutesConstantsIntoSignedExpressionOperands() throws Exception {
    Program compiler = CompilerSources.minimalCompilerProgram();
    assertDifferentialHalt(
        compiler,
        "classical class ConstantExpressionOperands { const long TWO = 1 + 1; "
            + "const long THREE = TWO + 1; const long FORTY = 20 * TWO; "
            + "entry void main() { long base = FORTY; long add = base + TWO; "
            + "long subtract = add - TWO; long xor = base ^ THREE; long and = xor & TWO; "
            + "long multiply = base * TWO; long divide = multiply / TWO; "
            + "long remainder = add % FORTY; boolean equal = add == FORTY; "
            + "boolean different = add != FORTY; boolean ordered = base < FORTY; "
            + "boolean notEqual = !equal; boolean notOrdered = !ordered; assert(add == 42); assert(subtract == 40); assert(xor == 43); assert(and == 2); "
            + "assert(multiply == 80); assert(divide == 40); assert(remainder == 2); "
            + "assert(notEqual); assert(different); assert(notOrdered); } }");
  }

  @Test
  void substitutesConstantsIntoBooleanComparisonOperands() throws Exception {
    Program compiler = CompilerSources.minimalCompilerProgram();
    assertDifferentialHalt(
        compiler,
        "classical class ConstantBooleanComparisonOperands { "
            + "const boolean EXPECTED = !false; const boolean OTHER = false; "
            + "entry void main() { boolean value = true; boolean same = value == EXPECTED; "
            + "boolean different = value != OTHER; assert(value == EXPECTED); "
            + "assert(same); assert(different); } }");
  }

  @Test
  void substitutesConstantsIntoSignedConditionalOperands() throws Exception {
    Program compiler = CompilerSources.minimalCompilerProgram();
    assertDifferentialHalt(
        compiler,
        "classical class ConstantConditionalOperands { state long outcome = 0; "
            + "const long LIMIT = 40 + 2; const long UPPER = LIMIT + 1; "
            + "const long STEP = 1; const long EXPECTED_OUTCOME = UPPER - 41; "
            + "entry void main() { long value = 42; "
            + "if (value == LIMIT) { outcome += STEP; } "
            + "if (value < UPPER) { outcome += STEP; } "
            + "assert(value == LIMIT); assert(value < UPPER); "
            + "assert(outcome == EXPECTED_OUTCOME); } }");
  }

  @Test
  void substitutesConstantsIntoBoundedLoopOperands() throws Exception {
    Program compiler = CompilerSources.minimalCompilerProgram();
    assertDifferentialHalt(
        compiler,
        "classical class ConstantLoopOperands { const long STOP = HALF * 2; "
            + "const long HALF = 2; const long LIMIT = STOP + 1; entry void main() { "
            + "long up = 0; while (up < STOP) limit LIMIT { up += 1; } "
            + "long down = STOP; while (0 < down) limit LIMIT { down -= 1; } "
            + "assert(up == 4); assert(down == 0); } }");
  }

  @Test
  void substitutesConstantsIntoScalarAssignmentsAndCheckedUpdates() throws Exception {
    Program compiler = CompilerSources.minimalCompilerProgram();
    assertDifferentialHalt(
        compiler,
        "classical class ConstantMutations { state long total = 0; "
            + "const long STEP = 1 + 1; const long MASK = STEP + 1; const long ONE = MASK - 2; "
            + "const long ANSWER = 40 + STEP; const boolean READY = ANSWER == 42; "
            + "entry void main() { long value = 0; value += STEP; value ^= MASK; "
            + "value -= ONE; value = ANSWER; boolean ready = false; ready = READY; "
            + "total += STEP; total ^= MASK; total -= ONE; total = ANSWER; "
            + "assert(value == 42); assert(ready); assert(total == 42); } }");
  }

  @Test
  void keepsDependencyOrderOutOfTheArtifact() throws Exception {
    Program compiler = CompilerSources.minimalCompilerProgram();
    String prefix = "classical class OrderedConstants { ";
    String body = "entry void main() { long answer = ANSWER; boolean ready = READY; "
        + "assert(answer == 42); assert(ready); } }";
    String first = prefix + "const long BASE = 40; const long ANSWER = BASE + 2; "
        + "const boolean READY = ANSWER == 42; " + body;
    String second = prefix + "const boolean READY = ANSWER == 42; "
        + "const long ANSWER = BASE + 2; const long BASE = 40; " + body;

    assertArrayEquals(compileNative(compiler, first), compileNative(compiler, second));
    assertArrayEquals(
        new WheelerCompiler().compileToBytecode(first),
        new WheelerCompiler().compileToBytecode(second));
  }

  @Test
  void evaluatesTheMaximumBoundedForwardDependencyPath() throws Exception {
    Program compiler = CompilerSources.minimalCompilerProgram();
    StringBuilder source = new StringBuilder("classical class BoundedDependencyPath { ");
    for (int index = 0; index < MAX_NATIVE_DEPENDENCY_DEPTH - 1; index++) {
      source.append("const long VALUE_").append(index).append(" = VALUE_")
          .append(index + 1).append("; ");
    }
    source.append("const long VALUE_63 = 42; entry void main() { long value = VALUE_0; ")
        .append("assert(value == 42); } }");

    assertDifferentialHalt(compiler, source.toString());
  }

  @Test
  void evaluatesTheMaximumBoundedConstantTable() throws Exception {
    Program compiler = CompilerSources.minimalCompilerProgram();
    StringBuilder source = new StringBuilder("classical class BoundedConstantTable { ");
    for (int index = 0; index < MAX_NATIVE_CONSTANTS; index++) {
      source.append("const long VALUE_").append(index).append(" = ")
          .append(index).append("; ");
    }
    source.append("entry void main() { long value = VALUE_127; ")
        .append("assert(value == 127); } }");

    assertDifferentialHalt(compiler, source.toString());
  }

  @Test
  void rejectsMalformedAmbiguousAndOversizedConstantPrefixes() throws Exception {
    Program compiler = CompilerSources.minimalCompilerProgram();
    assertNativeTrap(
        compiler,
        "classical class DuplicateConstants { const long VALUE = 1; "
            + "const long VALUE = 2; entry void main() { long value = VALUE; } }");
    assertNativeTrap(
        compiler,
        "classical class ConstantStateCollision { state long VALUE = 0; "
            + "const long VALUE = 1; entry void main() { } }");
    assertNativeTrap(
        compiler,
        "classical class ConstantHelperCollision { const long answer = 1; "
            + "long answer() { return 1; } entry void main() { long value = answer(); } }");
    assertNativeTrap(
        compiler,
        "classical class ConstantEntryCollision { const long main = 1; "
            + "entry void main() { } }");
    assertNativeTrap(
        compiler,
        "classical class WrongConstantType { const boolean READY = true; "
            + "entry void main() { long value = READY; } }");
    assertNativeTrap(
        compiler,
        "classical class WrongSignedCallConstant { const boolean INPUT = true; "
            + "long identity(long value) { return value; } entry void main() { "
            + "long result = identity(INPUT); } }");
    assertNativeTrap(
        compiler,
        "classical class WrongBooleanCallConstant { const long INPUT = 1; "
            + "boolean identity(boolean value) { return value; } entry void main() { "
            + "boolean result = identity(INPUT); } }");
    assertNativeTrap(
        compiler,
        "classical class WrongSignedPairConstant { const boolean RIGHT = true; "
            + "long add(long left, long right) { return left + right; } entry void main() { "
            + "long result = add(1, RIGHT); } }");
    assertNativeTrap(
        compiler,
        "classical class WrongBooleanPairConstant { const long LEFT = 1; "
            + "const long RIGHT = 2; boolean both(boolean left, boolean right) { return left; } "
            + "entry void main() { boolean result = both(LEFT, RIGHT); } }");
    assertNativeTrap(
        compiler,
        "classical class WrongUpdateConstant { const boolean STEP = true; "
            + "entry void main() { long value = 0; value += STEP; } }");
    String wrongReversibleUpdate = "classical class WrongReversibleUpdate { "
        + "state long value = 0; const boolean STEP = true; "
        + "rev void bump() { value += STEP; } entry void main() { bump(); } }";
    assertNativeTrap(compiler, wrongReversibleUpdate);
    assertThrows(
        CompilerException.class,
        () -> new WheelerCompiler().compileToBytecode(wrongReversibleUpdate));
    assertNativeTrap(
        compiler,
        "classical class WrongExpressionConstant { const boolean STEP = true; "
            + "entry void main() { long value = 1; long result = value + STEP; } }");
    assertNativeTrap(
        compiler,
        "classical class WrongComparisonConstant { const boolean LIMIT = true; "
            + "entry void main() { long value = 1; boolean result = value < LIMIT; } }");
    assertNativeTrap(
        compiler,
        "classical class WrongBooleanComparisonConstant { const long EXPECTED = 1; "
            + "entry void main() { boolean value = true; "
            + "boolean result = value == EXPECTED; } }");
    assertNativeTrap(
        compiler,
        "classical class WrongBooleanAssertionConstant { const long EXPECTED = 1; "
            + "entry void main() { boolean value = true; assert(value == EXPECTED); } }");
    assertNativeTrap(
        compiler,
        "classical class WrongReturnComparisonConstant { const boolean LIMIT = true; "
            + "boolean ordered(long value) { return value < LIMIT; } entry void main() { "
            + "boolean result = ordered(1); } }");
    assertNativeTrap(
        compiler,
        "classical class WrongArithmeticReturnConstant { const boolean RIGHT = true; "
            + "long calculate(long left) { return left + RIGHT; } entry void main() { "
            + "long result = calculate(1); } }");
    assertNativeTrap(
        compiler,
        "classical class WrongSignedEqualityReturnConstant { const boolean LIMIT = true; "
            + "boolean equal(long value) { return value == LIMIT; } entry void main() { "
            + "boolean result = equal(1); } }");
    assertNativeTrap(
        compiler,
        "classical class WrongBooleanReturnConstant { const long EXPECTED = 1; "
            + "boolean equal(boolean value) { return value == EXPECTED; } entry void main() { "
            + "boolean result = equal(true); } }");
    assertNativeTrap(
        compiler,
        "classical class WrongLoopConstant { const boolean LIMIT = true; "
            + "entry void main() { long value = 0; "
            + "while (value < LIMIT) limit LIMIT { value += 1; } } }");
    assertNativeTrap(
        compiler,
        "classical class WrongConditionalConstant { state long outcome = 0; "
            + "const boolean LIMIT = true; entry void main() { long value = 0; "
            + "if (value < LIMIT) { outcome += 1; } } }");
    assertNativeTrap(
        compiler,
        "classical class WrongConditionalUpdateConstant { state long outcome = 0; "
            + "const boolean STEP = true; entry void main() { long value = 0; "
            + "if (value == 0) { outcome += STEP; } } }");
    assertNativeTrap(
        compiler,
        "classical class WrongAssertionConstant { const boolean EXPECTED = true; "
            + "entry void main() { long value = 1; assert(value == EXPECTED); } }");
    assertNativeTrap(
        compiler,
        "classical class WrongOrderingAssertionConstant { const boolean LIMIT = true; "
            + "entry void main() { long value = 1; assert(value < LIMIT); } }");
    assertNativeTrap(
        compiler,
        "classical class WrongAssignmentConstant { const long VALUE = 1; "
            + "entry void main() { boolean ready = false; ready = VALUE; } }");
    assertNativeTrap(
        compiler,
        "classical class WrongGlobalAssignmentConstant { state long value = 0; "
            + "const boolean READY = true; entry void main() { value = READY; } }");
    assertNativeTrap(
        compiler,
        "classical class WrongGlobalAssertionConstant { state long value = 0; "
            + "const boolean EXPECTED = true; entry void main() { assert(value == EXPECTED); } }");
    assertNativeTrap(
        compiler,
        "classical class WrongStateInitializerConstant { const boolean READY = true; "
            + "state long value = READY; entry void main() { } }");
    assertNativeTrap(
        compiler,
        "classical class MissingStateInitializerConstant { state long value = MISSING; "
            + "entry void main() { } }");
    assertNativeTrap(
        compiler,
        "classical class SplitConstantBlocks { const long FIRST = 1; state long value = FIRST; "
            + "const long SECOND = 2; entry void main() { } }");
    assertNativeTrap(
        compiler,
        "classical class ConstantLocalCollision { const long VALUE = 1; "
            + "entry void main() { long VALUE = 2; } }");
    assertNativeTrap(
        compiler,
        "classical class ConstantParameterCollision { const long VALUE = 1; "
            + "long identity(long VALUE) { return VALUE; } entry void main() { "
            + "long result = identity(1); } }");
    assertNativeTrap(
        compiler,
        "classical class MalformedConstantExpression { const long VALUE = 1 + ; "
            + "entry void main() { long value = VALUE; } }");
    assertNativeTrap(
        compiler,
        "classical class InvalidRadixConstant { const long VALUE = 0xnope; "
            + "entry void main() { long value = VALUE; } }");
    String nested = "(".repeat(33) + "1" + ")".repeat(33);
    assertNativeTrap(
        compiler,
        "classical class DeepConstantExpression { const long VALUE = " + nested
            + "; entry void main() { long value = VALUE; } }");
    assertNativeTrap(
        compiler,
        "classical class ConstantCycle { const long FIRST = SECOND + 1; "
            + "const long SECOND = FIRST + 1; entry void main() { long value = FIRST; } }");
    assertNativeTrap(
        compiler,
        "classical class UnknownConstantDependency { const long VALUE = MISSING + 1; "
            + "entry void main() { long value = VALUE; } }");
    assertNativeTrap(
        compiler,
        "classical class WrongConstantExpressionType { const long VALUE = true; "
            + "entry void main() { long value = VALUE; } }");
    assertNativeTrap(
        compiler,
        "classical class ConstantDivisionTrap { const long VALUE = 1 / 0; "
            + "entry void main() { long value = VALUE; } }");
    assertNativeTrap(
        compiler,
        "classical class NegativeConstantRotate { "
            + "const long VALUE = rotateRight32(1, -1); "
            + "entry void main() { long value = VALUE; } }");
    assertNativeTrap(
        compiler,
        "classical class WideConstantRotate { const long VALUE = rotateRight32(1, 32); "
            + "entry void main() { long value = VALUE; } }");
    assertNativeTrap(
        compiler,
        "classical class BooleanConstantRotate { "
            + "const long VALUE = rotateRight32(true, 1); "
            + "entry void main() { long value = VALUE; } }");
    assertNativeTrap(
        compiler,
        "classical class ConstantOverflow { const long VALUE = 9223372036854775807 + 1; "
            + "entry void main() { long value = VALUE; } }");
    assertNativeTrap(
        compiler,
        "classical class MissingConstant { entry void main() { long value = MISSING; } }");

    StringBuilder oversized = new StringBuilder("classical class TooManyConstants { ");
    for (int index = 0; index <= MAX_NATIVE_CONSTANTS; index++) {
      oversized.append("const long VALUE_").append(index).append(" = ")
          .append(index).append("; ");
    }
    oversized.append("entry void main() { } }");
    assertNativeTrap(compiler, oversized.toString());
  }

  private static byte[] assertDifferentialHalt(Program compiler, String source) {
    byte[] nativeArtifact = compileNative(compiler, source);
    assertArrayEquals(new WheelerCompiler().compileToBytecode(source), nativeArtifact);
    VirtualMachine program = new VirtualMachine(new BytecodeReader().read(nativeArtifact));
    program.run();
    assertEquals(MachineStatus.HALTED, program.status());
    return nativeArtifact;
  }

  private static byte[] compileNative(Program compiler, String source) {
    VirtualMachine writer = new VirtualMachine(
        compiler, source.getBytes(StandardCharsets.UTF_8), OUTPUT_CAPACITY);
    CompilerMachineRunner.runWithoutRewindHistory(writer);
    return writer.hostOutput();
  }

  private static void assertNativeTrap(Program compiler, String source) {
    VirtualMachine writer = new VirtualMachine(
        compiler, source.getBytes(StandardCharsets.UTF_8), OUTPUT_CAPACITY);
    assertThrows(
        VmTrap.class,
        () -> CompilerMachineRunner.runWithoutRewindHistory(writer));
    assertArrayEquals(new byte[OUTPUT_CAPACITY], writer.hostOutput());
  }
}
