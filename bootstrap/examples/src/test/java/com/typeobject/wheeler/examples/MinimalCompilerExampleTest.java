package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeReader;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.MachineStatus;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Conformance tests for the Wheeler-written compiler seed and canonical artifact parity. */
class MinimalCompilerExampleTest {
  @Test
  void wheelerCompilesMinimalSourceToACanonicalExecutableArtifact() throws Exception {
    Program writerProgram = CompilerSources.minimalCompilerProgram();
    String source =
        "classical class LongClass { state long value = 7; "
            + "entry void main() { value += 5; } }";
    VirtualMachine writer = new VirtualMachine(
        writerProgram, source.getBytes(StandardCharsets.UTF_8), 512);
    var initial = writer.snapshot();

    writer.run();

    byte[] emitted = writer.hostOutput();
    byte[] stageZero = new WheelerCompiler().compileToBytecode(source);
    assertEquals(392, writer.global("codeStart"));
    assertEquals(504, writer.global("finalCursor"));
    assertEquals(1, writer.global("verification"));
    assertEquals(504, emitted.length);
    assertArrayEquals(stageZero, emitted);
    String moduleSource = "module examples.seed; " + source;
    VirtualMachine moduleWriter = new VirtualMachine(
        writerProgram, moduleSource.getBytes(StandardCharsets.UTF_8), 528);
    moduleWriter.run();
    assertArrayEquals(
        new BytecodeWriter().write(new WheelerCompiler().compileModuleFiles(
            Map.of("ModuleSubject.w", moduleSource), "examples.seed")),
        moduleWriter.hostOutput());
    String helperModuleSource = "module examples.seed; classical class ModuleHelper { "
        + "state long value = 1; private void bump() { value += 2; } "
        + "entry void main() { bump(); assert(value == 3); } }";
    VirtualMachine helperModuleWriter = new VirtualMachine(
        writerProgram, helperModuleSource.getBytes(StandardCharsets.UTF_8), 1024);
    var helperModuleInitial = helperModuleWriter.snapshot();
    helperModuleWriter.run();
    assertArrayEquals(
        new BytecodeWriter().write(new WheelerCompiler().compileModuleFiles(
            Map.of("ModuleHelper.w", helperModuleSource), "examples.seed")),
        helperModuleWriter.hostOutput());
    while (helperModuleWriter.historySize() > 0) {
      helperModuleWriter.rewindOne();
    }
    assertEquals(helperModuleInitial, helperModuleWriter.snapshot());
    String noStateHelperModuleSource =
        "module examples.seed; classical class NoStateModuleHelper { "
            + "public void inspect() { boolean ready = true; assert(ready); } "
            + "entry void main() { inspect(); } }";
    VirtualMachine noStateHelperModuleWriter = new VirtualMachine(
        writerProgram, noStateHelperModuleSource.getBytes(StandardCharsets.UTF_8), 1024);
    noStateHelperModuleWriter.run();
    assertArrayEquals(
        new BytecodeWriter().write(new WheelerCompiler().compileModuleFiles(
            Map.of("NoStateModuleHelper.w", noStateHelperModuleSource), "examples.seed")),
        noStateHelperModuleWriter.hostOutput());
    String noStateProofModuleSource =
        "module examples.seed; classical class NoStateModuleProof { "
            + "rev void inspect() { } "
            + "theorem inspectInverse proves inverse(inspect); "
            + "entry void main() { inspect(); reverse { inspect(); } } }";
    VirtualMachine noStateProofModuleWriter = new VirtualMachine(
        writerProgram, noStateProofModuleSource.getBytes(StandardCharsets.UTF_8), 1024);
    noStateProofModuleWriter.run();
    assertArrayEquals(
        new BytecodeWriter().write(new WheelerCompiler().compileModuleFiles(
            Map.of("NoStateModuleProof.w", noStateProofModuleSource), "examples.seed")),
        noStateProofModuleWriter.hostOutput());
    String proofModuleSource = "module examples.seed; classical class ModuleProof { "
        + "state long value = 1; rev void bump() { value += 2; } "
        + "theorem bumpInverse proves inverse(bump); "
        + "entry void main() { bump(); reverse { bump(); } } }";
    VirtualMachine proofModuleWriter = new VirtualMachine(
        writerProgram, proofModuleSource.getBytes(StandardCharsets.UTF_8), 1024);
    proofModuleWriter.run();
    assertArrayEquals(
        new BytecodeWriter().write(new WheelerCompiler().compileModuleFiles(
            Map.of("ModuleProof.w", proofModuleSource), "examples.seed")),
        proofModuleWriter.hostOutput());
    VirtualMachine malformedModule = new VirtualMachine(
        writerProgram,
        ("module examples.; " + source).getBytes(StandardCharsets.UTF_8),
        528);
    assertThrows(VmTrap.class, malformedModule::run);
    VirtualMachine undersizedOutput = new VirtualMachine(
        writerProgram, source.getBytes(StandardCharsets.UTF_8), emitted.length - 1);
    assertThrows(VmTrap.class, undersizedOutput::run);
    assertArrayEquals(new byte[emitted.length - 1], undersizedOutput.hostOutput());
    for (long variant = 1; variant <= 32; variant++) {
      String decorated = decoratedMinimalSource(variant);
      VirtualMachine decoratedWriter = new VirtualMachine(
          writerProgram, decorated.getBytes(StandardCharsets.UTF_8), 512);
      decoratedWriter.run();
      assertArrayEquals(stageZero, decoratedWriter.hostOutput());
      assertArrayEquals(
          stageZero,
          new WheelerCompiler().compileToBytecode(decorated));
    }
    String commentHeavy = "/*c*/".repeat(500) + source;
    VirtualMachine commentHeavyWriter = new VirtualMachine(
        writerProgram, commentHeavy.getBytes(StandardCharsets.UTF_8), 512);
    commentHeavyWriter.run();
    assertArrayEquals(stageZero, commentHeavyWriter.hostOutput());
    String commentOverflow = "/*c*/".repeat(1024) + source;
    VirtualMachine commentOverflowWriter = new VirtualMachine(
        writerProgram, commentOverflow.getBytes(StandardCharsets.UTF_8), 512);
    assertThrows(VmTrap.class, commentOverflowWriter::run);
    assertArrayEquals(new byte[512], commentOverflowWriter.hostOutput());

    var decoded = new BytecodeReader().read(emitted);
    assertArrayEquals(emitted, new BytecodeWriter().write(decoded));
    VirtualMachine seed = new VirtualMachine(decoded);
    seed.run();
    assertEquals(MachineStatus.HALTED, seed.status());
    assertEquals(12, seed.global("value"));

    while (writer.historySize() > 0) {
      writer.rewindOne();
    }
    assertEquals(initial, writer.snapshot());

    assertDifferentialHalt(
        writerProgram,
        "classical class Bare { entry void main() { } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class Local { entry void main() { long x = 2; } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class NoStateEmptyHelper { "
            + "void inspect() { } entry void main() { inspect(); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class NoStatePublicHelper { "
            + "public void inspect() { boolean ready = true; assert(ready); } "
            + "entry void main() { inspect(); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class NoStatePrivateHelper { "
            + "private void inspect() { boolean ready = true; assert(ready); } "
            + "entry void main() { inspect(); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class Local { entry void main() { long x = -2; } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class TrueLocal { entry void main() { boolean flag = true; } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class FalseLocal { entry void main() { boolean flag = false; } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class NegatedFalse { entry void main() { boolean flag = !false; } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class NegatedTrue { entry void main() { boolean flag = !true; } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class AssertTrue { entry void main() { assert(true); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class AssertNotFalse { entry void main() { assert(!false); } }");
    assertDifferentialTrap(
        writerProgram,
        "classical class AssertFalse { entry void main() { assert(false); } }");
    assertDifferentialTrap(
        writerProgram,
        "classical class AssertNotTrue { entry void main() { assert(!true); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class AssertEqualLiterals { entry void main() { assert(-1 == -1); } }");
    assertDifferentialTrap(
        writerProgram,
        "classical class AssertUnequalLiterals { entry void main() { assert(0 == 1); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class LocalSeries { entry void main() { "
            + "long amount = -2; boolean first = true; assert(first); "
            + "boolean second = !true; } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class LocalTruth { entry void main() { "
            + "boolean ready = !false; assert(ready); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class LocalTruthCopy { entry void main() { "
            + "boolean first = true; boolean second = first; assert(second); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class LocalTruthNot { entry void main() { "
            + "boolean first = false; boolean second = !first; assert(second); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class LocalBooleanEquality { entry void main() { "
            + "boolean first = true; boolean second = true; "
            + "boolean same = first == second; assert(same); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class LocalSignedEquality { entry void main() { "
            + "long first = 41; long second = 41; "
            + "boolean same = first == second; assert(same); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class AssertSignedPair { entry void main() { "
            + "long first = 41; long second = 41; assert(first == second); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class AssertBooleanPair { entry void main() { "
            + "boolean first = true; boolean second = true; assert(first == second); } }");
    assertDifferentialTrap(
        writerProgram,
        "classical class AssertUnequalPair { entry void main() { "
            + "long first = 41; long second = 42; assert(first == second); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class AssertLessPair { entry void main() { "
            + "long first = 41; long second = 42; assert(first < second); } }");
    assertDifferentialTrap(
        writerProgram,
        "classical class AssertNotLessPair { entry void main() { "
            + "long first = 42; long second = 41; assert(first < second); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class LocalSignedLessThan { entry void main() { "
            + "long first = 40; long second = 42; "
            + "boolean less = first < second; assert(less); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class LocalSignedEqualsLiteral { entry void main() { "
            + "long answer = 42; boolean same = answer == 42; assert(same); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class LocalSignedLessThanLiteral { entry void main() { "
            + "long answer = -2; boolean less = answer < -1; assert(less); } }");
    assertDifferentialTrap(
        writerProgram,
        "classical class LocalSignedNotEqualsLiteral { entry void main() { "
            + "long answer = 41; boolean same = answer == 42; assert(same); } }");
    assertDifferentialExecution(
        writerProgram,
        "classical class LessThanIfAdd { state long result = 0; entry void main() { "
            + "long answer = -2; if (answer < -1) { result += 1; } "
            + "assert(result == 1); } }",
        "result",
        1);
    assertDifferentialExecution(
        writerProgram,
        "classical class LessThanIfSkipped { state long result = 2; entry void main() { "
            + "long answer = 1; if (answer < 0) { result -= 1; } "
            + "assert(result == 2); } }",
        "result",
        2);
    assertDifferentialExecution(
        writerProgram,
        "classical class LessThanIfXor { state long result = 6; entry void main() { "
            + "long answer = 41; if (answer < 42) { result ^= 3; } "
            + "assert(result == 5); } }",
        "result",
        5);
    assertDifferentialExecution(
        writerProgram,
        "classical class LessThanIfAssign { state long result = 0; entry void main() { "
            + "long answer = 41; if (answer < 42) { result = 9; } "
            + "assert(result == 9); } }",
        "result",
        9);
    assertDifferentialExecution(
        writerProgram,
        "classical class EqualityIfAdd { state long result = 0; entry void main() { "
            + "long answer = 42; if (answer == 42) { result += 1; } "
            + "assert(result == 1); } }",
        "result",
        1);
    assertDifferentialExecution(
        writerProgram,
        "classical class EqualityIfSkipped { state long result = 2; entry void main() { "
            + "long answer = -1; if (answer == 0) { result -= 1; } "
            + "assert(result == 2); } }",
        "result",
        2);
    assertDifferentialExecution(
        writerProgram,
        "classical class EqualityIfXor { state long result = 6; entry void main() { "
            + "long answer = 42; if (answer == 42) { result ^= 3; } "
            + "assert(result == 5); } }",
        "result",
        5);
    assertDifferentialExecution(
        writerProgram,
        "classical class EqualityIfAssign { state long result = 0; entry void main() { "
            + "long answer = 42; if (answer == 42) { result = 9; } "
            + "assert(result == 9); } }",
        "result",
        9);
    assertDifferentialExecution(
        writerProgram,
        "classical class LocalIfAdd { state long result = 0; entry void main() { "
            + "boolean ready = true; if (ready) { result += 1; } assert(result == 1); } }",
        "result",
        1);
    assertDifferentialExecution(
        writerProgram,
        "classical class LocalIfSkipped { state long result = 0; entry void main() { "
            + "boolean ready = false; if (ready) { result += 1; } assert(result == 0); } }",
        "result",
        0);
    assertDifferentialExecution(
        writerProgram,
        "classical class LocalIfSub { state long result = 2; entry void main() { "
            + "boolean ready = true; if (ready) { result -= 1; } assert(result == 1); } }",
        "result",
        1);
    assertDifferentialExecution(
        writerProgram,
        "classical class LocalIfXor { state long result = 2; entry void main() { "
            + "boolean ready = true; if (ready) { result ^= 3; } assert(result == 1); } }",
        "result",
        1);
    assertDifferentialExecution(
        writerProgram,
        "classical class LocalIfNotAdd { state long result = 0; entry void main() { "
            + "boolean ready = false; if (!ready) { result += 1; } assert(result == 1); } }",
        "result",
        1);
    assertDifferentialExecution(
        writerProgram,
        "classical class LocalIfNotSkipped { state long result = 0; entry void main() { "
            + "boolean ready = true; if (!ready) { result += 1; } assert(result == 0); } }",
        "result",
        0);
    assertDifferentialExecution(
        writerProgram,
        "classical class LocalIfNotSub { state long result = 2; entry void main() { "
            + "boolean ready = false; if (!ready) { result -= 1; } assert(result == 1); } }",
        "result",
        1);
    assertDifferentialExecution(
        writerProgram,
        "classical class LocalIfNotXor { state long result = 2; entry void main() { "
            + "boolean ready = false; if (!ready) { result ^= 3; } assert(result == 1); } }",
        "result",
        1);
    assertDifferentialExecution(
        writerProgram,
        "classical class LocalIfAssign { state long result = 0; entry void main() { "
            + "boolean ready = true; if (ready) { result = 42; } assert(result == 42); } }",
        "result",
        42);
    assertDifferentialExecution(
        writerProgram,
        "classical class LocalIfNotAssign { state long result = 0; entry void main() { "
            + "boolean ready = false; if (!ready) { result = 42; } assert(result == 42); } }",
        "result",
        42);
    assertDifferentialExecution(
        writerProgram,
        "classical class LocalIfAssignSkipped { state long result = 7; entry void main() { "
            + "boolean ready = false; if (ready) { result = 42; } assert(result == 7); } }",
        "result",
        7);
    assertDifferentialExecution(
        writerProgram,
        "classical class LocalIfAssignValue { state long result = 0; entry void main() { "
            + "boolean ready = true; long answer = 42; "
            + "if (ready) { result = answer; } assert(result == 42); } }",
        "result",
        42);
    assertDifferentialExecution(
        writerProgram,
        "classical class LocalIfNotAssignValue { state long result = 0; entry void main() { "
            + "boolean ready = false; long answer = 42; "
            + "if (!ready) { result = answer; } assert(result == 42); } }",
        "result",
        42);
    assertDifferentialExecution(
        writerProgram,
        "classical class LocalAssignValue { state long result = 0; entry void main() { "
            + "long answer = 42; result = answer; assert(result == 42); } }",
        "result",
        42);
    assertDifferentialExecution(
        writerProgram,
        "classical class LocalUpdateAdd { state long result = 40; entry void main() { "
            + "long delta = 2; result += delta; assert(result == 42); } }",
        "result",
        42);
    assertDifferentialExecution(
        writerProgram,
        "classical class LocalUpdateSub { state long result = 44; entry void main() { "
            + "long delta = 2; result -= delta; assert(result == 42); } }",
        "result",
        42);
    assertDifferentialExecution(
        writerProgram,
        "classical class LocalUpdateXor { state long result = 40; entry void main() { "
            + "long delta = 2; result ^= delta; assert(result == 42); } }",
        "result",
        42);
    assertDifferentialExecution(
        writerProgram,
        "classical class LocalIfUpdateAdd { state long result = 40; entry void main() { "
            + "boolean ready = true; long delta = 2; "
            + "if (ready) { result += delta; } assert(result == 42); } }",
        "result",
        42);
    assertDifferentialExecution(
        writerProgram,
        "classical class LocalIfUpdateSub { state long result = 44; entry void main() { "
            + "boolean ready = true; long delta = 2; "
            + "if (ready) { result -= delta; } assert(result == 42); } }",
        "result",
        42);
    assertDifferentialExecution(
        writerProgram,
        "classical class LocalIfUpdateXor { state long result = 40; entry void main() { "
            + "boolean ready = true; long delta = 2; "
            + "if (ready) { result ^= delta; } assert(result == 42); } }",
        "result",
        42);
    assertDifferentialExecution(
        writerProgram,
        "classical class LocalIfNotUpdate { state long result = 40; entry void main() { "
            + "boolean ready = false; long delta = 2; "
            + "if (!ready) { result += delta; } assert(result == 42); } }",
        "result",
        42);
    assertDifferentialExecution(
        writerProgram,
        "classical class LocalIfUpdateSkipped { state long result = 40; entry void main() { "
            + "boolean ready = false; long delta = 2; "
            + "if (ready) { result += delta; } assert(result == 40); } }",
        "result",
        40);
    assertDifferentialHalt(
        writerProgram,
        "classical class FifthLocal { entry void main() { "
            + "boolean first = false; boolean second = false; boolean third = false; "
            + "boolean fourth = true; assert(fourth); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class EighthLocal { entry void main() { "
            + "boolean first = false; boolean second = false; boolean third = false; "
            + "boolean fourth = false; boolean fifth = false; boolean sixth = false; "
            + "boolean seventh = true; assert(seventh); } }");
    assertDifferentialTrap(
        writerProgram,
        "classical class LocalFalse { entry void main() { "
            + "boolean ready = false; assert(ready); } }");
    assertDifferentialExecution(
        writerProgram,
        "classical class Empty { state long idle = 7; "
            + "entry void main() { } }",
        "idle",
        7);
    assertDifferentialExecution(
        writerProgram,
        "classical class Set { state long result = 4; "
            + "entry void main() { result = 99; } }",
        "result",
        99);
    assertDifferentialExecution(
        writerProgram,
        "classical class zebra { state long alpha = 0; "
            + "entry void main() { alpha += 0; } }",
        "alpha",
        0);
    assertDifferentialExecution(
        writerProgram,
        "classical class zebra { state long alpha = 10; "
            + "entry void main() { alpha -= 3; } }",
        "alpha",
        7);
    assertDifferentialExecution(
        writerProgram,
        "classical class Omega { state long mask = 6; "
            + "entry void main() { mask ^= 9; } }",
        "mask",
        15);
    assertDifferentialExecution(
        writerProgram,
        "classical class Negative { state long value = -10; "
            + "entry void main() { value += -3; } }",
        "value",
        -13);
    assertDifferentialExecution(
        writerProgram,
        "classical class Mixed { state long total = 10; "
            + "entry void main() { total = 4; total ^= 7; } }",
        "total",
        3);
    assertDifferentialExecution(
        writerProgram,
        "classical class EmptyHelper { state long value = 1; "
            + "void noop() { } entry void main() { noop(); assert(value == 1); } }",
        "value",
        1);
    assertDifferentialExecution(
        writerProgram,
        "classical class EmptyReverse { state long value = 1; "
            + "rev void noop() { } entry void main() { noop(); reverse { noop(); } "
            + "assert(value == 1); } }",
        "value",
        1);
    assertDifferentialExecution(
        writerProgram,
        "classical class Calls { state long value = 1; "
            + "void bump() { value += 2; } "
            + "entry void main() { bump(); } }",
        "value",
        3);
    assertDifferentialExecution(
        writerProgram,
        "classical class CheckedCalls { state long value = 1; "
            + "void bump() { value += 2; } "
            + "entry void main() { bump(); assert(value == 3); } }",
        "value",
        3);
    assertDifferentialExecution(
        writerProgram,
        "classical class LocalCalls { state long value = 1; "
            + "void bump() { value += 2; } "
            + "entry void main() { bump(); long scratch = -4; } }",
        "value",
        3);
    assertDifferentialExecution(
        writerProgram,
        "classical class HelperBody { state long value = 1; "
            + "void mix() { value += 2; value ^= 7; value -= 1; "
            + "assert(value == 3); } "
            + "entry void main() { mix(); assert(value == 3); } }",
        "value",
        3);
    assertDifferentialExecution(
        writerProgram,
        "classical class FifthHelper { state long value = 1; "
            + "void mix() { value += 2; value ^= 7; value -= 1; value += 4; "
            + "assert(value == 7); } "
            + "entry void main() { mix(); assert(value == 7); } }",
        "value",
        7);
    assertDifferentialExecution(
        writerProgram,
        "classical class FifthHelperLocal { state long total = 1; "
            + "void setup() { boolean first = false; boolean second = false; "
            + "boolean third = false; boolean fourth = true; assert(fourth); } "
            + "entry void main() { setup(); assert(total == 1); } }",
        "total",
        1);
    assertDifferentialExecution(
        writerProgram,
        "classical class EighthHelperLocal { state long total = 1; "
            + "void setup() { boolean first = false; boolean second = false; "
            + "boolean third = false; boolean fourth = false; boolean fifth = false; "
            + "boolean sixth = false; boolean seventh = true; assert(seventh); } "
            + "entry void main() { setup(); assert(total == 1); } }",
        "total",
        1);
    assertDifferentialExecution(
        writerProgram,
        "classical class DoubleCalls { state long value = 1; "
            + "void bump() { value += 2; } "
            + "entry void main() { bump(); bump(); assert(value == 5); } }",
        "value",
        5);
    assertDifferentialExecution(
        writerProgram,
        "classical class ReversibleCalls { state long value = 1; "
            + "rev void bump() { value += 2; } "
            + "entry void main() { bump(); reverse { bump(); } } }",
        "value",
        1);
    assertDifferentialExecution(
        writerProgram,
        "classical class DoubleReverse { state long value = 1; "
            + "rev void bump() { value += 2; } "
            + "entry void main() { bump(); bump(); "
            + "reverse { bump(); bump(); } assert(value == 1); } }",
        "value",
        1);
    assertDifferentialExecution(
        writerProgram,
        "classical class CheckedReverse { state long value = 1; "
            + "rev void bump() { value += 2; } "
            + "entry void main() { bump(); reverse { bump(); } "
            + "assert(value == 1); } }",
        "value",
        1);
    assertDifferentialExecution(
        writerProgram,
        "classical class SubtractiveReverse { state long value = 5; "
            + "rev void lower() { value -= 2; } "
            + "entry void main() { lower(); reverse { lower(); } "
            + "assert(value == 5); } }",
        "value",
        5);
    assertDifferentialExecution(
        writerProgram,
        "classical class XorReverse { state long value = 5; "
            + "rev void flip() { value ^= 6; } "
            + "entry void main() { flip(); reverse { flip(); } "
            + "assert(value == 5); } }",
        "value",
        5);
    assertDifferentialExecution(
        writerProgram,
        "classical class ReversibleBody { state long value = 5; "
            + "rev void mix() { value += 2; value ^= 7; value -= 1; } "
            + "theorem mixInverse proves inverse(mix); "
            + "entry void main() { mix(); reverse { mix(); } "
            + "assert(value == 5); } }",
        "value",
        5);
    assertDifferentialExecution(
        writerProgram,
        "classical class EighthReverse { state long value = 0; "
            + "rev void raise() { value += 1; value += 1; value += 1; value += 1; "
            + "value += 1; value += 1; value += 1; value += 1; } "
            + "entry void main() { raise(); reverse { raise(); } assert(value == 0); } }",
        "value",
        0);
    assertDifferentialExecution(
        writerProgram,
        "classical class Certified { state long value = 1; "
            + "rev void bump() { value += 2; } "
            + "theorem bumpInverse proves inverse(bump); "
            + "entry void main() { bump(); reverse { bump(); } "
            + "assert(value == 1); } }",
        "value",
        1);
    assertDifferentialExecution(
        writerProgram,
        "classical class DoubleChecked { state long count = 0; "
            + "rev void increment() { count += 1; } "
            + "entry void main() { increment(); increment(); "
            + "assert(count == 2); reverse { increment(); increment(); } "
            + "assert(count == 0); } }",
        "count",
        0);
    String counterSource = Files.readString(
        Path.of("src/main/wheeler/classical/control/Counter.w"));
    assertDifferentialExecution(
        writerProgram,
        counterSource,
        "count",
        0);
    assertDifferentialExecution(
        writerProgram,
        "classical class WithLocal { state long total = 1; "
            + "entry void main() { long scratch = -2; total += 4; } }",
        "total",
        5);
    assertDifferentialExecution(
        writerProgram,
        "classical class WithBoolean { state long total = 1; "
            + "entry void main() { boolean ready = true; total += 4; "
            + "assert(total == 5); } }",
        "total",
        5);
    assertDifferentialExecution(
        writerProgram,
        "classical class HelperBooleans { state long total = 1; "
            + "void setup() { boolean ready = !true; long scratch = -2; } "
            + "entry void main() { setup(); assert(total == 1); } }",
        "total",
        1);
    assertDifferentialExecution(
        writerProgram,
        "classical class HelperTruth { state long total = 1; "
            + "void setup() { boolean ready = !false; assert(ready); total += 4; } "
            + "entry void main() { setup(); assert(total == 5); } }",
        "total",
        5);
    assertDifferentialTrap(
        writerProgram,
        "classical class HelperFalse { state long total = 1; "
            + "void setup() { boolean ready = false; assert(ready); } "
            + "entry void main() { setup(); } }");
    assertDifferentialExecution(
        writerProgram,
        "classical class Asserted { state long value = 1; "
            + "entry void main() { value += 2; assert(value == 3); } }",
        "value",
        3);
    assertDifferentialExecution(
        writerProgram,
        "classical class Series { state long value = 1; "
            + "entry void main() { value += 2; value ^= 7; } }",
        "value",
        4);
    assertDifferentialExecution(
        writerProgram,
        "classical class Four { state long value = 1; "
            + "entry void main() { value += 2; value ^= 7; "
            + "value -= 1; assert(value == 3); } }",
        "value",
        3);
    assertDifferentialExecution(
        writerProgram,
        "classical class Five { state long value = 1; "
            + "entry void main() { value += 2; value ^= 7; "
            + "value -= 1; value += 4; assert(value == 7); } }",
        "value",
        7);
    assertDifferentialExecution(
        writerProgram,
        "classical class Eight { state long value = 1; "
            + "entry void main() { value += 1; value += 1; value += 1; "
            + "value += 1; value += 1; value += 1; value += 1; "
            + "assert(value == 8); } }",
        "value",
        8);
    assertDifferentialExecution(
        writerProgram,
        "classical class SixtyFour { state long value = 0; entry void main() { "
            + "value += 1; ".repeat(63)
            + "assert(value == 63); } }",
        "value",
        63);
    assertDifferentialExecution(
        writerProgram,
        "classical class SixtyFourHelper { state long value = 0; public void setup() { "
            + "value += 1; ".repeat(63)
            + "assert(value == 63); } entry void main() { setup(); } }",
        "value",
        63);
    assertDifferentialExecution(
        writerProgram,
        "classical class SixtyFourReverse { state long value = 0; public rev void raise() { "
            + "value += 1; ".repeat(64)
            + "} entry void main() { raise(); reverse { raise(); } assert(value == 0); } }",
        "value",
        0);
    assertDifferentialHalt(
        writerProgram,
        "classical class SixtyFourLocals { entry void main() { "
            + booleanDeclarations(64)
            + "} }");
    assertDifferentialHalt(
        writerProgram,
        "classical class FullLocalWindow { entry void main() { "
            + booleanDeclarations(63)
            + "assert(value0); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class SignedLocalWindow { entry void main() { "
            + longDeclarations(63)
            + "assert(value62 == 62); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class SignedLocalCopy { entry void main() { "
            + "long first = 41; long second = first; assert(second == 41); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class SignedLocalAdd { entry void main() { "
            + "long first = 41; long second = first + 1; assert(second == 42); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class SignedLocalSub { entry void main() { "
            + "long first = 41; long second = first - 1; assert(second == 40); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class SignedLocalXor { entry void main() { "
            + "long first = 41; long second = first ^ 1; assert(second == 40); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class SignedLocalsAdd { entry void main() { "
            + "long first = 40; long second = 2; "
            + "long result = first + second; assert(result == 42); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class SignedLocalsSub { entry void main() { "
            + "long first = 44; long second = 2; "
            + "long result = first - second; assert(result == 42); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class SignedLocalsXor { entry void main() { "
            + "long first = 40; long second = 2; "
            + "long result = first ^ second; assert(result == 42); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class SignedLocalMul { entry void main() { "
            + "long first = 6; long result = first * 7; assert(result == 42); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class SignedLocalDiv { entry void main() { "
            + "long first = 84; long result = first / 2; assert(result == 42); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class SignedLocalMod { entry void main() { "
            + "long first = 44; long result = first % 2; assert(result == 0); } }");
    assertDifferentialTrap(
        writerProgram,
        "classical class SignedLocalDivZero { entry void main() { "
            + "long first = 84; long result = first / 0; } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class SignedLocalsMul { entry void main() { "
            + "long first = 6; long second = 7; "
            + "long result = first * second; assert(result == 42); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class SignedLocalsDiv { entry void main() { "
            + "long first = 84; long second = 2; "
            + "long result = first / second; assert(result == 42); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class SignedLocalsMod { entry void main() { "
            + "long first = 44; long second = 2; "
            + "long result = first % second; assert(result == 0); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class GlobalThenLocal { state long value = 7; entry void main() { "
            + "assert(value == 7); long answer = 41; assert(answer == 41); } }");
    assertDifferentialTrap(
        writerProgram,
        "classical class FalseSignedLocal { entry void main() { "
            + "long answer = 41; assert(answer == 42); } }");

    assertDifferentialHalt(
        writerProgram,
        "classical class NoStateReversibleHelper { "
            + "rev void inspect() { } "
            + "theorem inspectInverse proves inverse(inspect); "
            + "entry void main() { inspect(); reverse { inspect(); } } }");
  }

  private static String longDeclarations(int count) {
    StringBuilder source = new StringBuilder();
    for (int index = 0; index < count; index++) {
      source.append("long value").append(index).append(" = ").append(index).append("; ");
    }
    return source.toString();
  }

  private static String booleanDeclarations(int count) {
    StringBuilder source = new StringBuilder();
    for (int index = 0; index < count; index++) {
      source.append("boolean value").append(index).append(" = true; ");
    }
    return source.toString();
  }

  private static String decoratedMinimalSource(long seed) {
    String[] tokens = {
        "classical", "class", "LongClass", "{", "state", "long", "value", "=", "7", ";",
        "entry", "void", "main", "(", ")", "{", "value", "+=", "5", ";", "}", "}"
    };
    String[] separators = {" ", "\n", " /* bootstrap-noise */ ", " // bootstrap-noise\n"};
    StringBuilder source = new StringBuilder();
    long state = seed;
    for (String token : tokens) {
      state = state * 1_103_515_245 + 12_345;
      int separator = (int) ((state >>> 16) & 3);
      source.append(separators[separator]).append(token);
    }
    return source.append('\n').toString();
  }

  private void assertDifferentialHalt(
      Program writerProgram,
      String source) {
    VirtualMachine writer = new VirtualMachine(
        writerProgram, source.getBytes(StandardCharsets.UTF_8), 8192);
    writer.run();
    assertArrayEquals(
        new WheelerCompiler().compileToBytecode(source),
        writer.hostOutput());
    VirtualMachine artifact = new VirtualMachine(
        new BytecodeReader().read(writer.hostOutput()));
    artifact.run();
    assertEquals(MachineStatus.HALTED, artifact.status());
  }

  private void assertDifferentialTrap(
      Program writerProgram,
      String source) {
    VirtualMachine writer = new VirtualMachine(
        writerProgram, source.getBytes(StandardCharsets.UTF_8), 8192);
    writer.run();
    assertArrayEquals(
        new WheelerCompiler().compileToBytecode(source),
        writer.hostOutput());
    VirtualMachine artifact = new VirtualMachine(
        new BytecodeReader().read(writer.hostOutput()));
    assertThrows(VmTrap.class, artifact::run);
  }

  private void assertDifferentialExecution(
      Program writerProgram,
      String source,
      String global,
      long expected) {
    VirtualMachine writer = new VirtualMachine(
        writerProgram, source.getBytes(StandardCharsets.UTF_8), 8192);
    try {
      writer.run();
    } catch (VmTrap trap) {
      throw new AssertionError(
          "Wheeler compiler trapped at output cursor " + writer.global("finalCursor")
              + " with verification " + writer.global("verification"),
          trap);
    }
    assertArrayEquals(
        new WheelerCompiler().compileToBytecode(source),
        writer.hostOutput());
    VirtualMachine artifact = new VirtualMachine(
        new BytecodeReader().read(writer.hostOutput()));
    artifact.run();
    assertEquals(expected, artifact.global(global));
  }
}
