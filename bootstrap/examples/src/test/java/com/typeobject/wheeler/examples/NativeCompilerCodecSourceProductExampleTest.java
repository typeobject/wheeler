package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeException;
import com.typeobject.wheeler.core.bytecode.BytecodeReader;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.FunctionBody;
import com.typeobject.wheeler.core.bytecode.Instruction;
import com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole;
import com.typeobject.wheeler.core.bytecode.Opcode;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.bytecode.ValueType;
import com.typeobject.wheeler.core.vm.BufferValue;
import com.typeobject.wheeler.core.vm.MachineStatus;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import java.security.MessageDigest;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Native source-local codec products are distinct from its linked verifier closure. */
final class NativeCompilerCodecSourceProductExampleTest {
  private static Program compiledProduct;

  @Test
  void compilesThePhysicalCodecAndPreservesCompleteCallerStorage() throws Exception {
    Program product = product();
    assertEquals(3, product.functions().size());
    assertEquals(NativeCodecProductFixture.FUNCTION, product.functions().getFirst().name());
  }

  @Test
  void executesTheRetainedCodecWithExactAndSpareCapacityAndRewinds() throws Exception {
    byte[] input = validArtifact();
    Program executable = executable();
    for (int spare : new int[] {0, 17}) {
      VirtualMachine machine =
          VirtualMachine.withBinaryInput(executable, input, input.length + spare);
      var before = machine.snapshot();
      machine.run();
      assertEquals(MachineStatus.HALTED, machine.status());
      assertArrayEquals(input, machine.hostOutput());
      assertCallerBytes(before.buffers().getFirst(), machine.snapshot().buffers(), input, 0);
      assertCallerBytes(before.buffers().get(1), machine.snapshot().buffers(), input, 0);
      rewind(machine);
      assertEquals(before, machine.snapshot());
    }
  }

  @Test
  void rejectsMalformedInputAndShortOutputBeforeAnyCallerWriteAndRewinds() throws Exception {
    byte[] input = validArtifact();
    byte[] damaged = input.clone();
    damaged[0] ^= 1;
    Program executable = executable();
    rejects(executable, damaged, input.length);
    byte[] invalidCode = input.clone();
    invalidCode[input.length - 8] ^= 0x7f;
    assertThrows(BytecodeException.class, () -> new BytecodeReader().read(invalidCode));
    rejects(executable, invalidCode, input.length);
    rejects(executable, new byte[0], input.length);
    rejects(executable, input, input.length - 1);
  }

  private static void rejects(Program executable, byte[] input, int capacity) {
    VirtualMachine machine = VirtualMachine.withBinaryInput(executable, input, capacity);
    var before = machine.snapshot();
    assertThrows(VmTrap.class, machine::run);
    assertArrayEquals(new byte[capacity], machine.hostOutput());
    for (BufferValue caller : before.buffers()) {
      assertEquals(caller, buffer(machine.snapshot().buffers(), caller.id()));
    }
    rewind(machine);
    assertEquals(before, machine.snapshot());
  }

  private static synchronized Program product() throws Exception {
    if (compiledProduct != null) {
      return compiledProduct;
    }
    Program reference = new WheelerCompiler().compileLibraryModuleFiles(
        NativeCodecProductFixture.referenceSources(), NativeCodecProductFixture.MODULE);
    FunctionBody body = named(reference, NativeCodecProductFixture.FUNCTION);
    FunctionBody verifier = named(reference, NativeCodecProductFixture.TARGET);
    assertEquals(2, body.parameterCount());
    assertEquals(List.of(ValueType.BYTE_VIEW, ValueType.BYTES_BORROW),
        body.localTypes().subList(0, 2));
    assertEquals(List.of(ValueType.BYTE_VIEW, ValueType.SIGNED),
        verifier.localTypes().subList(0, verifier.parameterCount()));
    assertEquals(ValueType.SIGNED, verifier.resultType());
    FunctionBody local = rebind(body, 0, Map.of(verifier.id(), 1));
    FunctionBody stub = new FunctionBody(1, "~00", false, 2,
        List.of(ValueType.BYTE_VIEW, ValueType.SIGNED, ValueType.SIGNED),
        ValueType.SIGNED, false,
        List.of(Instruction.of(Opcode.LOCAL_CONST, 2, 0),
            Instruction.of(Opcode.RETURN_VALUE, 2)), List.of());
    FunctionBody entry = rebind(reference.functions().getLast(), 2, Map.of());
    Program expected =
        new Program(reference.name(), 2, reference.globals(), List.of(local, stub, entry));
    byte[] artifact = new BytecodeWriter().write(expected);
    byte[] digest = MessageDigest.getInstance("SHA-256").digest(artifact);
    byte[] transport = Arrays.copyOf(artifact, artifact.length + 32);
    System.arraycopy(digest, 0, transport, artifact.length, 32);
    var run = NativeCodecProductFixture.prepare();
    VirtualMachine machine = run.machine();
    while (machine.global("published") == 0) {
      machine.stepWithoutRewindHistory();
    }
    assertEquals(artifact.length, machine.global("artifactLength"));
    assertEquals(1, machine.global("relocationCount"));
    assertArrayEquals(transport, machine.hostOutput());
    List<BufferValue> caller = run.caller();
    List<BufferValue> actual = machine.snapshot().buffers();
    int count = caller.size();
    for (int index = 0; index < count; index++) {
      BufferValue before = caller.get(index);
      BufferValue after = buffer(actual, before.id());
      if (index == 1) {
        assertCallerBytes(before, actual, transport, 0);
      } else if (index == count - 1) {
        assertCallerBytes(before, actual, digest, 211);
      } else if (index == count - 2) {
        assertCallerBytes(before, actual, artifact, 211);
      } else if (index == count - 3) {
        byte[] targetIdentity = new byte[32];
        targetIdentity[0] = 47;
        assertCallerBytes(before, actual, targetIdentity, 211);
      } else if (index == count - 4) {
        assertWords(before, after, Map.of(0, 0L));
      } else if (index == count - 5) {
        int call = 0;
        while (local.forward().get(call).opcode() != Opcode.CALL_VALUE) {
          call++;
        }
        assertWords(before, after, Map.of(0, (long) call, 256, 1L, 512, 0L));
      } else {
        assertEquals(before, after, "caller buffer " + before.id());
      }
    }
    CompilerMachineRunner.runWithoutRewindHistory(machine);
    assertEquals(MachineStatus.HALTED, machine.status());
    assertEquals(0, machine.historySize());
    assertEquals(2L, machine.snapshot().buffers().stream().filter(b -> !b.dropped()).count());
    compiledProduct =
        new BytecodeReader().read(Arrays.copyOf(machine.hostOutput(), artifact.length));
    return compiledProduct;
  }

  private static Program executable() throws Exception {
    var sources = NativeCodecProductFixture.referenceSources();
    sources.put("CodecExecution.w", """
        module example.codec_execution;
        import wheeler.compiler.codec;
        classical class CodecExecution {
          entry void main(borrow byteview input, borrow mut bytes output) {
            long copied = reencodeArtifact(input, output);
            setOutputLength(output, copied);
          }
        }
        """);
    Program reference =
        new WheelerCompiler().compileModuleFiles(sources, "example.codec_execution");
    FunctionBody expected = named(reference, NativeCodecProductFixture.FUNCTION);
    FunctionBody verifier = named(reference, NativeCodecProductFixture.TARGET);
    FunctionBody nativeBody = rebind(product().functions().getFirst(), expected.id(),
        Map.of(1, verifier.id()));
    assertEquals(expected, nativeBody);
    List<FunctionBody> functions = reference.functions().stream()
        .map(function -> function.id() == expected.id() ? nativeBody : function).toList();
    Program executable = new Program(
        reference.name(), reference.kind(), reference.entryFunctionId(), reference.globals(),
        reference.recordTypes(), reference.variantTypes(), reference.arrayTypes(),
        reference.sliceTypes(), functions, reference.proofCertificates(),
        reference.quantumRegisters(), reference.quantumCircuits(), reference.workflow(),
        reference.requiredInstructionExtensions(),
        reference.maxHistoryRecords(), reference.maxSteps());
    return new BytecodeReader().read(new BytecodeWriter().write(executable));
  }

  private static FunctionBody named(Program program, String name) {
    return program.functions().stream().filter(function -> function.name().equals(name))
        .findFirst().orElseThrow();
  }

  private static FunctionBody rebind(FunctionBody function, int id, Map<Integer, Integer> targets) {
    return new FunctionBody(id, function.name(), function.coherent(), function.parameterCount(),
        function.localTypes(), function.resultType(), function.implicitResultSlot(),
        rebind(function.forward(), targets), rebind(function.inverse(), targets));
  }

  private static List<Instruction> rebind(List<Instruction> body, Map<Integer, Integer> targets) {
    return body.stream().map(instruction -> {
      int role = instruction.opcode().form().roles().indexOf(OperandRole.FUNCTION);
      if (role < 0) {
        return instruction;
      }
      List<Long> operands = new ArrayList<>(instruction.operands());
      Integer target = targets.get(Math.toIntExact(operands.get(role)));
      assertNotNull(target, "unexpected function operand");
      operands.set(role, target.longValue());
      return new Instruction(instruction.opcode(), operands);
    }).toList();
  }

  private static byte[] validArtifact() {
    Program program =
        new WheelerCompiler().compile("classical class Tiny { entry void main() {} }");
    return new BytecodeWriter().write(program);
  }

  private static BufferValue buffer(List<BufferValue> buffers, int id) {
    return buffers.stream().filter(buffer -> buffer.id() == id).findFirst().orElseThrow();
  }

  private static void assertCallerBytes(
      BufferValue before, List<BufferValue> buffers, byte[] prefix, int tail) {
    BufferValue after = buffer(buffers, before.id());
    assertEquals(before.length(), after.length());
    assertFalse(after.dropped());
    byte[] expected = new byte[before.length()];
    Arrays.fill(expected, (byte) tail);
    System.arraycopy(prefix, 0, expected, 0, prefix.length);
    byte[] actual = new byte[after.length()];
    for (int cell = 0; cell < actual.length; cell++) {
      actual[cell] = after.elements().get(cell).byteValue();
    }
    assertArrayEquals(expected, actual, "buffer " + before.id());
  }

  private static void assertWords(
      BufferValue before, BufferValue actual, Map<Integer, Long> changed) {
    assertEquals(before.length(), actual.length());
    assertFalse(actual.dropped());
    for (int cell = 0; cell < actual.length(); cell++) {
      assertEquals(changed.getOrDefault(cell, 211L), actual.elements().get(cell),
          "buffer " + actual.id() + " cell " + cell);
    }
  }

  private static void rewind(VirtualMachine machine) {
    while (machine.historySize() > 0) {
      machine.rewindOne();
    }
  }
}
