package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeReader;
import com.typeobject.wheeler.core.bytecode.Opcode;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Map;
import org.junit.jupiter.api.Test;

class NativeVmExampleTest {
  @Test
  void wheelerInterpretsBoundedArtifactsIncludingCounter() throws Exception {
    Path root = Path.of("src/main/wheeler");
    Program interpreter = new WheelerCompiler().compileModuleFiles(
        Map.of(
            "Binary.w", Files.readString(root.resolve("packages/Binary.w")),
            "FunctionVerifier.w",
            Files.readString(root.resolve("compiler/FunctionVerifier.w")),
            "InstructionVerifier.w",
            Files.readString(root.resolve("compiler/InstructionVerifier.w")),
            "Interpreter.w", Files.readString(root.resolve("compiler/Interpreter.w")),
            "NativeVm.w", Files.readString(root.resolve("NativeVm.w")),
            "Opcodes.w", Files.readString(root.resolve("compiler/Opcodes.w")),
            "ProofRules.w", Files.readString(root.resolve("compiler/ProofRules.w")),
            "ProofVerifier.w", Files.readString(root.resolve("compiler/ProofVerifier.w")),
            "TypeCodes.w", Files.readString(root.resolve("compiler/TypeCodes.w")),
            "Verifier.w", Files.readString(root.resolve("compiler/Verifier.w"))),
        "examples.runtime.native_vm");
    WheelerCompiler compiler = new WheelerCompiler();
    byte[] update = compiler.compileToBytecode(
        "classical class NativeSubject { state long value = 7; "
            + "entry void main() { value += 5; assert value == 12; } }");
    VirtualMachine machine = VirtualMachine.withBinaryInput(interpreter, update);
    var initial = machine.snapshot();

    machine.run();

    assertEquals(12, machine.global("finalGlobal"));
    assertEquals(update.length, machine.global("artifactLength"));
    assertTrue(machine.global("interpretedSteps") > 0);
    VirtualMachine stageZero = new VirtualMachine(new BytecodeReader().read(update));
    stageZero.run();
    assertEquals(stageZero.global("value"), machine.global("finalGlobal"));
    assertInterpretedGlobal(
        interpreter,
        "classical class Conditional { state long value = 0; "
            + "entry void main() { long x = 3; if (x < 4) { value += 7; } "
            + "else { value += 1; } assert value == 7; } }",
        "value",
        7);
    byte[] damagedBranch = withBadJumpTarget(compiler.compileToBytecode(
        "classical class DamagedBranch { state long value = 0; "
            + "entry void main() { if (value == 0) { value += 1; } } }"));
    assertThrows(
        VmTrap.class,
        () -> VirtualMachine.withBinaryInput(interpreter, damagedBranch).run());
    assertInterpretedGlobal(
        interpreter,
        "classical class Equality { state long value = 0; "
            + "entry void main() { long x = 3; if (x == 3) { value += 4; } "
            + "assert value == 4; } }",
        "value",
        4);
    assertInterpretedGlobal(
        interpreter,
        "classical class ValueCall { state long value = 0; "
            + "long add(long left, long right) { return left + right; } "
            + "entry void main() { value = add(4, 5); assert value == 9; } }",
        "value",
        9);
    byte[] damagedCall = withBadCallTarget(compiler.compileToBytecode(
        "classical class DamagedCall { state long value = 0; "
            + "long identity(long input) { return input; } "
            + "entry void main() { value = identity(3); } }"));
    assertThrows(
        VmTrap.class,
        () -> VirtualMachine.withBinaryInput(interpreter, damagedCall).run());
    assertInterpretedGlobal(
        interpreter,
        "classical class VoidCall { state long value = 1; "
            + "void increase(long amount) { value += amount; } "
            + "entry void main() { increase(6); assert value == 7; } }",
        "value",
        7);
    assertInterpretedGlobal(
        interpreter,
        "classical class FunctionGraph { state long value = 0; "
            + "long add(long left, long right) { return left + right; } "
            + "long twice(long input) { return input * 2; } "
            + "boolean same(long left, long right) { return left == right; } "
            + "entry void main() { long sum = add(2, 3); "
            + "long doubled = twice(sum); boolean valid = same(doubled, 10); "
            + "if (valid) { value = doubled; } assert value == 10; } }",
        "value",
        10);
    String functionValues = Files.readString(root.resolve("FunctionValues.w"));
    assertInterpretedGlobal(interpreter, functionValues, "result", 10);
    assertInterpretedGlobal(
        interpreter,
        Files.readString(root.resolve("RecursiveValue.w")),
        "result",
        6);
    byte[] forgedBound = withForgedProofBound(
        compiler.compileToBytecode(functionValues));
    assertThrows(
        VmTrap.class,
        () -> VirtualMachine.withBinaryInput(interpreter, forgedBound).run());
    assertInterpretedGlobal(
        interpreter,
        "classical class Loop { state long value = 0; "
            + "entry void main() { long index = 0; "
            + "while (index < 3) limit 3 { value += 2; index += 1; } "
            + "assert value == 6; } }",
        "value",
        6);
    while (machine.historySize() > 0) {
      machine.rewindOne();
    }
    assertEquals(initial, machine.snapshot());

    String counterSource = Files.readString(root.resolve("Counter.w"));
    byte[] counter = compileInWheeler(root, counterSource);
    assertArrayEquals(compiler.compileToBytecode(counterSource), counter);
    VirtualMachine counterMachine = VirtualMachine.withBinaryInput(
        interpreter, counter);
    counterMachine.run();
    assertEquals(0, counterMachine.global("finalGlobal"));
    assertTrue(counterMachine.global("interpretedSteps") > 8);

    byte[] malformed = update.clone();
    malformed[0] = 0;
    VirtualMachine rejected = VirtualMachine.withBinaryInput(
        interpreter, malformed);
    assertThrows(VmTrap.class, rejected::run);
  }

  private static void assertInterpretedGlobal(
      Program interpreter, String source, String global, long expected) {
    byte[] artifact = new WheelerCompiler().compileToBytecode(source);
    VirtualMachine nativeMachine = VirtualMachine.withBinaryInput(interpreter, artifact);
    var initial = nativeMachine.snapshot();
    nativeMachine.run();
    VirtualMachine stageZero = new VirtualMachine(new BytecodeReader().read(artifact));
    stageZero.run();
    assertEquals(expected, stageZero.global(global));
    assertEquals(stageZero.global(global), nativeMachine.global("finalGlobal"));
    while (nativeMachine.historySize() > 0) {
      nativeMachine.rewindOne();
    }
    assertEquals(initial, nativeMachine.snapshot());
  }

  private static byte[] withBadJumpTarget(byte[] artifact) {
    byte[] damaged = artifact.clone();
    ByteBuffer bytes = ByteBuffer.wrap(damaged).order(ByteOrder.LITTLE_ENDIAN);
    int directory = 40 + 5 * 32;
    int cursor = Math.toIntExact(bytes.getLong(directory + 8));
    int end = cursor + Math.toIntExact(bytes.getLong(directory + 16));
    while (cursor < end) {
      int opcode = Short.toUnsignedInt(bytes.getShort(cursor));
      if (opcode == Opcode.JUMP.code()) {
        bytes.putLong(cursor + 8, Long.MAX_VALUE);
        return damaged;
      }
      if (opcode == Opcode.JUMP_IF_ZERO.code()) {
        bytes.putLong(cursor + 16, Long.MAX_VALUE);
        return damaged;
      }
      cursor += bytes.getInt(cursor + 4);
    }
    throw new AssertionError("control-flow fixture has no branch");
  }

  private static byte[] withBadCallTarget(byte[] artifact) {
    byte[] damaged = artifact.clone();
    ByteBuffer bytes = ByteBuffer.wrap(damaged).order(ByteOrder.LITTLE_ENDIAN);
    int directory = 40 + 5 * 32;
    int cursor = Math.toIntExact(bytes.getLong(directory + 8));
    int end = cursor + Math.toIntExact(bytes.getLong(directory + 16));
    while (cursor < end) {
      int opcode = Short.toUnsignedInt(bytes.getShort(cursor));
      if (opcode == Opcode.CALL_VALUE.code() || opcode == Opcode.CALL_VOID.code()) {
        bytes.putLong(cursor + 8, Long.MAX_VALUE);
        return damaged;
      }
      cursor += bytes.getInt(cursor + 4);
    }
    throw new AssertionError("call fixture has no argument call");
  }

  private static byte[] withForgedProofBound(byte[] artifact) {
    byte[] forged = artifact.clone();
    ByteBuffer bytes = ByteBuffer.wrap(forged).order(ByteOrder.LITTLE_ENDIAN);
    int proofDirectory = 40 + 6 * 32;
    int proofOffset = Math.toIntExact(bytes.getLong(proofDirectory + 8));
    bytes.putLong(proofOffset + 20, 3);
    return forged;
  }

  private static byte[] compileInWheeler(Path root, String source) throws Exception {
    Program compiler = new WheelerCompiler().compileModuleFiles(
        Map.ofEntries(
            Map.entry("Codegen.w", Files.readString(root.resolve("compiler/Codegen.w"))),
            Map.entry("Encoding.w", Files.readString(root.resolve("compiler/Encoding.w"))),
            Map.entry(
                "FunctionVerifier.w",
                Files.readString(root.resolve("compiler/FunctionVerifier.w"))),
            Map.entry(
                "HelperParser.w",
                Files.readString(root.resolve("compiler/HelperParser.w"))),
            Map.entry(
                "InstructionVerifier.w",
                Files.readString(root.resolve("compiler/InstructionVerifier.w"))),
            Map.entry("Ir.w", Files.readString(root.resolve("compiler/Ir.w"))),
            Map.entry(
                "MinimalCompiler.w", Files.readString(root.resolve("MinimalCompiler.w"))),
            Map.entry("Opcodes.w", Files.readString(root.resolve("compiler/Opcodes.w"))),
            Map.entry("Parser.w", Files.readString(root.resolve("compiler/Parser.w"))),
            Map.entry("ProofRules.w", Files.readString(root.resolve("compiler/ProofRules.w"))),
            Map.entry(
                "ProofVerifier.w",
                Files.readString(root.resolve("compiler/ProofVerifier.w"))),
            Map.entry("Scanner.w", Files.readString(root.resolve("lexer/Scanner.w"))),
            Map.entry(
                "Statements.w", Files.readString(root.resolve("compiler/Statements.w"))),
            Map.entry(
                "StringTable.w", Files.readString(root.resolve("compiler/StringTable.w"))),
            Map.entry("Structure.w", Files.readString(root.resolve("compiler/Structure.w"))),
            Map.entry("Tokens.w", Files.readString(root.resolve("compiler/Tokens.w"))),
            Map.entry("TypeCodes.w", Files.readString(root.resolve("compiler/TypeCodes.w"))),
            Map.entry("Verifier.w", Files.readString(root.resolve("compiler/Verifier.w"))),
            Map.entry("Binary.w", Files.readString(root.resolve("packages/Binary.w")))),
        "examples.compiler.seed");
    VirtualMachine machine = new VirtualMachine(
        compiler, source.getBytes(StandardCharsets.UTF_8), 1024);
    machine.run();
    return machine.hostOutput();
  }
}
