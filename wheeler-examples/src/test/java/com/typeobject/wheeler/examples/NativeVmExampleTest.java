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
        Map.ofEntries(
            Map.entry(
                "AggregateInterpreter.w",
                Files.readString(root.resolve("compiler/AggregateInterpreter.w"))),
            Map.entry(
                "AggregateVerifier.w",
                Files.readString(root.resolve("compiler/AggregateVerifier.w"))),
            Map.entry("Binary.w", Files.readString(root.resolve("packages/Binary.w"))),
            Map.entry(
                "FunctionVerifier.w",
                Files.readString(root.resolve("compiler/FunctionVerifier.w"))),
            Map.entry(
                "InstructionVerifier.w",
                Files.readString(root.resolve("compiler/InstructionVerifier.w"))),
            Map.entry(
                "Interpreter.w", Files.readString(root.resolve("compiler/Interpreter.w"))),
            Map.entry(
                "MapInterpreter.w",
                Files.readString(root.resolve("compiler/MapInterpreter.w"))),
            Map.entry("NativeVm.w", Files.readString(root.resolve("NativeVm.w"))),
            Map.entry("Opcodes.w", Files.readString(root.resolve("compiler/Opcodes.w"))),
            Map.entry("ProofRules.w", Files.readString(root.resolve("compiler/ProofRules.w"))),
            Map.entry(
                "ProofVerifier.w",
                Files.readString(root.resolve("compiler/ProofVerifier.w"))),
            Map.entry(
                "StorageInterpreter.w",
                Files.readString(root.resolve("compiler/StorageInterpreter.w"))),
            Map.entry(
                "StorageVerifier.w",
                Files.readString(root.resolve("compiler/StorageVerifier.w"))),
            Map.entry("TypeCodes.w", Files.readString(root.resolve("compiler/TypeCodes.w"))),
            Map.entry(
                "Utf8Interpreter.w",
                Files.readString(root.resolve("compiler/Utf8Interpreter.w"))),
            Map.entry("Verifier.w", Files.readString(root.resolve("compiler/Verifier.w")))),
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
    assertInterpretedTwoGlobals(
        interpreter,
        Files.readString(root.resolve("LoopControl.w")),
        "sum",
        12,
        "selected",
        7);
    String arrays = "classical class NativeArrays { "
        + "state long selected = 0; state long sliceSelected = 0; "
        + "entry void main() { "
        + "long[4] first = new long[4](2, 4, 6, 8); "
        + "long[] middle = slice(first, 1, 2); "
        + "selected = first[2]; sliceSelected = middle[1]; "
        + "assert selected == 6; assert sliceSelected == 6; } }";
    assertInterpretedTwoGlobals(
        interpreter, arrays, "selected", 6, "sliceSelected", 6);
    byte[] forgedArray = withBadArrayIndex(
        compiler.compileToBytecode(arrays));
    assertThrows(
        VmTrap.class,
        () -> VirtualMachine.withBinaryInput(interpreter, forgedArray).run());
    byte[] forgedSlice = withBadSliceIndex(
        compiler.compileToBytecode(arrays));
    assertThrows(
        VmTrap.class,
        () -> VirtualMachine.withBinaryInput(interpreter, forgedSlice).run());
    String storage = "classical class NativeStorage { "
        + "state long first = 0; state long byteValue = 0; "
        + "long readWord(words data, long index) { return data[index]; } "
        + "long readByte(bytes data, long index) { return data[index]; } "
        + "long scratch(region arena, long value) { "
        + "long one = 1; words temporary = allocate(arena, one); "
        + "set(temporary, 0, value); long result = temporary[0]; "
        + "drop(temporary); return result; } "
        + "entry void main() { "
        + "region arena = new region(32, 2); first = scratch(arena, 7); "
        + "long length = 2; words data = allocate(arena, length); "
        + "set(data, 0, 7); first = readWord(data, 0); "
        + "long packetLength = 3; "
        + "bytes packet = allocateBytes(arena, packetLength); "
        + "setByte(packet, 1, 194); byteValue = readByte(packet, 1); "
        + "long measuredLength = bufferLength(packet); "
        + "first = measuredLength; assert first == 3; first = 7; "
        + "assert first == 7; assert byteValue == 194; "
        + "drop(packet); drop(data); drop(arena); } }";
    assertInterpretedTwoGlobals(
        interpreter, storage, "first", 7, "byteValue", 194);
    byte[] forgedStorage = withBadWordsIndex(
        compiler.compileToBytecode(storage));
    assertThrows(
        VmTrap.class,
        () -> VirtualMachine.withBinaryInput(interpreter, forgedStorage).run());
    byte[] forgedBytes = withBadBytesIndex(
        compiler.compileToBytecode(storage));
    assertThrows(
        VmTrap.class,
        () -> VirtualMachine.withBinaryInput(interpreter, forgedBytes).run());
    String utf8 = "classical class NativeUtf8 { "
        + "state long valid = 0; state long scalars = 0; "
        + "entry void main() { region arena = new region(3, 1); "
        + "long length = 3; bytes packet = allocateBytes(arena, length); "
        + "setByte(packet, 0, 65); setByte(packet, 1, 194); "
        + "setByte(packet, 2, 162); boolean accepted = utf8Valid(packet); "
        + "if (accepted) { valid = 1; } else { valid = 0; } "
        + "long decoded = utf8Scalar(packet, 1); scalars = decoded; "
        + "assert scalars == 162; long width = utf8Width(packet, 1); "
        + "valid = width; assert valid == 2; "
        + "if (accepted) { valid = 1; } else { valid = 0; } "
        + "long count = utf8Count(packet); scalars = count; "
        + "assert valid == 1; assert scalars == 2; "
        + "drop(packet); drop(arena); } }";
    assertInterpretedTwoGlobals(
        interpreter, utf8, "valid", 1, "scalars", 2);
    assertInterpretedGlobal(
        interpreter,
        "classical class InvalidNativeUtf8 { state long valid = 1; "
            + "entry void main() { region arena = new region(2, 1); "
            + "long length = 2; bytes packet = allocateBytes(arena, length); "
            + "setByte(packet, 0, 192); setByte(packet, 1, 128); "
            + "boolean accepted = utf8Valid(packet); "
            + "if (accepted) { valid = 1; } else { valid = 0; } "
            + "assert valid == 0; drop(packet); drop(arena); } }",
        "valid",
        0);
    assertInterpretedTwoGlobals(
        interpreter,
        Files.readString(root.resolve("FrozenUtf8.w")),
        "byteLength",
        6,
        "scalarCount",
        3);
    byte[] malformedFreeze = compiler.compileToBytecode(
        "classical class InvalidFreeze { entry void main() { "
            + "region arena = new region(2, 1); long length = 2; "
            + "bytes raw = allocateBytes(arena, length); "
            + "setByte(raw, 0, 192); setByte(raw, 1, 128); "
            + "utf8 text = freezeUtf8(raw); drop(text); drop(arena); } }");
    assertThrows(
        VmTrap.class,
        () -> VirtualMachine.withBinaryInput(
            interpreter, malformedFreeze).run());
    byte[] forgedUtf8 = withBadUtf8Index(
        compiler.compileToBytecode(utf8));
    assertThrows(
        VmTrap.class,
        () -> VirtualMachine.withBinaryInput(interpreter, forgedUtf8).run());
    String map = "classical class NativeMap { "
        + "state long selected = 0; state long present = 0; "
        + "entry void main() { region arena = new region(96, 1); "
        + "longmap values = allocateMap(arena, 4); put(values, 7, 19); "
        + "selected = mapGet(values, 7); "
        + "boolean found = mapHas(values, 7); "
        + "if (found) { present = 1; } else { present = 0; } "
        + "assert selected == 19; assert present == 1; "
        + "drop(values); drop(arena); } }";
    assertInterpretedTwoGlobals(
        interpreter, map, "selected", 19, "present", 1);
    assertInterpretedTwoGlobals(
        interpreter,
        "classical class BorrowedNativeMap { "
            + "state long selected = 0; state long present = 0; "
            + "long lookup(longmap values, long key) { "
            + "return mapGet(values, key); } "
            + "entry void main() { region arena = new region(24, 1); "
            + "longmap values = allocateMap(arena, 1); put(values, 7, 17); "
            + "selected = lookup(values, 7); boolean found = mapHas(values, 7); "
            + "if (found) { present = 1; } else { present = 0; } "
            + "assert selected == 17; assert present == 1; "
            + "drop(values); drop(arena); } }",
        "selected",
        17,
        "present",
        1);
    byte[] forgedMap = withBadMapKey(
        compiler.compileToBytecode(map));
    assertThrows(
        VmTrap.class,
        () -> VirtualMachine.withBinaryInput(interpreter, forgedMap).run());
    String records = Files.readString(root.resolve("Records.w"));
    assertInterpretedTwoGlobals(
        interpreter, records, "width", 5, "equal", 1);
    assertInterpretedGlobal(
        interpreter,
        Files.readString(root.resolve("FiniteEnums.w")),
        "selected",
        7);
    String variants = Files.readString(root.resolve("Variants.w"));
    assertInterpretedTwoGlobals(
        interpreter, variants, "selected", 9, "equal", 1);
    byte[] forgedVariant = withBadVariantTag(
        compiler.compileToBytecode(variants));
    assertThrows(
        VmTrap.class,
        () -> VirtualMachine.withBinaryInput(interpreter, forgedVariant).run());
    byte[] forgedRecord = withBadRecordField(
        compiler.compileToBytecode(records));
    assertThrows(
        VmTrap.class,
        () -> VirtualMachine.withBinaryInput(interpreter, forgedRecord).run());
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
    byte[] forgedInverse = withForgedInverseOpcode(counter);
    assertThrows(
        VmTrap.class,
        () -> VirtualMachine.withBinaryInput(interpreter, forgedInverse).run());

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

  private static void assertInterpretedTwoGlobals(
      Program interpreter,
      String source,
      String firstGlobal,
      long firstExpected,
      String secondGlobal,
      long secondExpected) {
    byte[] artifact = new WheelerCompiler().compileToBytecode(source);
    VirtualMachine nativeMachine = VirtualMachine.withBinaryInput(interpreter, artifact);
    var initial = nativeMachine.snapshot();
    nativeMachine.run();
    Program decoded = new BytecodeReader().read(artifact);
    VirtualMachine stageZero = new VirtualMachine(decoded);
    stageZero.run();
    assertEquals(firstExpected, stageZero.global(firstGlobal));
    assertEquals(secondExpected, stageZero.global(secondGlobal));
    assertEquals(stageZero.global(firstGlobal), nativeMachine.global("finalGlobal"));
    assertEquals(stageZero.global(secondGlobal), nativeMachine.global("finalGlobalOne"));
    assertEquals(decoded.globals().size(), nativeMachine.global("interpretedGlobalCount"));
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

  private static byte[] withBadMapKey(byte[] artifact) {
    byte[] damaged = artifact.clone();
    ByteBuffer bytes = ByteBuffer.wrap(damaged).order(ByteOrder.LITTLE_ENDIAN);
    int codeDirectory = 40 + 5 * 32;
    int cursor = Math.toIntExact(bytes.getLong(codeDirectory + 8));
    int end = cursor + Math.toIntExact(bytes.getLong(codeDirectory + 16));
    while (cursor < end) {
      int opcode = Short.toUnsignedInt(bytes.getShort(cursor));
      if (opcode == Opcode.MAP_GET.code()) {
        bytes.putLong(cursor + 24, Long.MAX_VALUE);
        return damaged;
      }
      cursor += bytes.getInt(cursor + 4);
    }
    throw new AssertionError("map fixture has no lookup");
  }

  private static byte[] withBadUtf8Index(byte[] artifact) {
    byte[] damaged = artifact.clone();
    ByteBuffer bytes = ByteBuffer.wrap(damaged).order(ByteOrder.LITTLE_ENDIAN);
    int codeDirectory = 40 + 5 * 32;
    int cursor = Math.toIntExact(bytes.getLong(codeDirectory + 8));
    int end = cursor + Math.toIntExact(bytes.getLong(codeDirectory + 16));
    while (cursor < end) {
      int opcode = Short.toUnsignedInt(bytes.getShort(cursor));
      if (opcode == Opcode.UTF8_SCALAR.code()) {
        bytes.putLong(cursor + 24, Long.MAX_VALUE);
        return damaged;
      }
      cursor += bytes.getInt(cursor + 4);
    }
    throw new AssertionError("UTF-8 fixture has no scalar read");
  }

  private static byte[] withBadBytesIndex(byte[] artifact) {
    byte[] damaged = artifact.clone();
    ByteBuffer bytes = ByteBuffer.wrap(damaged).order(ByteOrder.LITTLE_ENDIAN);
    int codeDirectory = 40 + 5 * 32;
    int cursor = Math.toIntExact(bytes.getLong(codeDirectory + 8));
    int end = cursor + Math.toIntExact(bytes.getLong(codeDirectory + 16));
    while (cursor < end) {
      int opcode = Short.toUnsignedInt(bytes.getShort(cursor));
      if (opcode == Opcode.BYTES_GET.code()) {
        bytes.putLong(cursor + 24, Long.MAX_VALUE);
        return damaged;
      }
      cursor += bytes.getInt(cursor + 4);
    }
    throw new AssertionError("storage fixture has no byte read");
  }

  private static byte[] withBadWordsIndex(byte[] artifact) {
    byte[] damaged = artifact.clone();
    ByteBuffer bytes = ByteBuffer.wrap(damaged).order(ByteOrder.LITTLE_ENDIAN);
    int codeDirectory = 40 + 5 * 32;
    int cursor = Math.toIntExact(bytes.getLong(codeDirectory + 8));
    int end = cursor + Math.toIntExact(bytes.getLong(codeDirectory + 16));
    while (cursor < end) {
      int opcode = Short.toUnsignedInt(bytes.getShort(cursor));
      if (opcode == Opcode.WORDS_GET.code()) {
        bytes.putLong(cursor + 24, Long.MAX_VALUE);
        return damaged;
      }
      cursor += bytes.getInt(cursor + 4);
    }
    throw new AssertionError("storage fixture has no word read");
  }

  private static byte[] withBadSliceIndex(byte[] artifact) {
    byte[] damaged = artifact.clone();
    ByteBuffer bytes = ByteBuffer.wrap(damaged).order(ByteOrder.LITTLE_ENDIAN);
    int codeDirectory = 40 + 5 * 32;
    int cursor = Math.toIntExact(bytes.getLong(codeDirectory + 8));
    int end = cursor + Math.toIntExact(bytes.getLong(codeDirectory + 16));
    while (cursor < end) {
      int opcode = Short.toUnsignedInt(bytes.getShort(cursor));
      if (opcode == Opcode.SLICE_GET.code()) {
        bytes.putLong(cursor + 24, Long.MAX_VALUE);
        return damaged;
      }
      cursor += bytes.getInt(cursor + 4);
    }
    throw new AssertionError("slice fixture has no element read");
  }

  private static byte[] withBadArrayIndex(byte[] artifact) {
    byte[] damaged = artifact.clone();
    ByteBuffer bytes = ByteBuffer.wrap(damaged).order(ByteOrder.LITTLE_ENDIAN);
    int codeDirectory = 40 + 5 * 32;
    int cursor = Math.toIntExact(bytes.getLong(codeDirectory + 8));
    int end = cursor + Math.toIntExact(bytes.getLong(codeDirectory + 16));
    while (cursor < end) {
      int opcode = Short.toUnsignedInt(bytes.getShort(cursor));
      if (opcode == Opcode.ARRAY_GET.code()) {
        bytes.putLong(cursor + 24, Long.MAX_VALUE);
        return damaged;
      }
      cursor += bytes.getInt(cursor + 4);
    }
    throw new AssertionError("array fixture has no element read");
  }

  private static byte[] withBadVariantTag(byte[] artifact) {
    byte[] damaged = artifact.clone();
    ByteBuffer bytes = ByteBuffer.wrap(damaged).order(ByteOrder.LITTLE_ENDIAN);
    int codeDirectory = 40 + 5 * 32;
    int cursor = Math.toIntExact(bytes.getLong(codeDirectory + 8));
    int end = cursor + Math.toIntExact(bytes.getLong(codeDirectory + 16));
    while (cursor < end) {
      int opcode = Short.toUnsignedInt(bytes.getShort(cursor));
      if (opcode == Opcode.VARIANT_NEW.code()) {
        bytes.putLong(cursor + 24, Long.MAX_VALUE);
        return damaged;
      }
      cursor += bytes.getInt(cursor + 4);
    }
    throw new AssertionError("variant fixture has no construction");
  }

  private static byte[] withBadRecordField(byte[] artifact) {
    byte[] damaged = artifact.clone();
    ByteBuffer bytes = ByteBuffer.wrap(damaged).order(ByteOrder.LITTLE_ENDIAN);
    int codeDirectory = 40 + 5 * 32;
    int cursor = Math.toIntExact(bytes.getLong(codeDirectory + 8));
    int end = cursor + Math.toIntExact(bytes.getLong(codeDirectory + 16));
    while (cursor < end) {
      int opcode = Short.toUnsignedInt(bytes.getShort(cursor));
      if (opcode == Opcode.RECORD_GET.code()) {
        bytes.putLong(cursor + 24, Long.MAX_VALUE);
        return damaged;
      }
      cursor += bytes.getInt(cursor + 4);
    }
    throw new AssertionError("record fixture has no field read");
  }

  private static byte[] withForgedInverseOpcode(byte[] artifact) {
    byte[] forged = artifact.clone();
    ByteBuffer bytes = ByteBuffer.wrap(forged).order(ByteOrder.LITTLE_ENDIAN);
    int functionsDirectory = 40 + 4 * 32;
    int codeDirectory = 40 + 5 * 32;
    int functionsOffset = Math.toIntExact(bytes.getLong(functionsDirectory + 8));
    int codeOffset = Math.toIntExact(bytes.getLong(codeDirectory + 8));
    int inverseOffset = bytes.getInt(functionsOffset + 24);
    bytes.putShort(codeOffset + inverseOffset, (short) Opcode.ADD_CONST.code());
    return forged;
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
            Map.entry(
                "AggregateVerifier.w",
                Files.readString(root.resolve("compiler/AggregateVerifier.w"))),
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
                "StorageVerifier.w",
                Files.readString(root.resolve("compiler/StorageVerifier.w"))),
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
