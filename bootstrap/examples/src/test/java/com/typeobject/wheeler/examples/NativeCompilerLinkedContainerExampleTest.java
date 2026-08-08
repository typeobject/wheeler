package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeReader;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.FunctionBody;
import com.typeobject.wheeler.core.bytecode.Global;
import com.typeobject.wheeler.core.bytecode.Instruction;
import com.typeobject.wheeler.core.bytecode.Opcode;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.proof.ProofCertificate;
import com.typeobject.wheeler.core.proof.ProofRule;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Native evidence for canonical header, directory, section, and padding assembly. */
final class NativeCompilerLinkedContainerExampleTest {
  @Test
  void reconstructsAndReadsACompleteCanonicalArtifact() throws Exception {
    byte[] artifact = artifact();
    VirtualMachine machine = VirtualMachine.withBinaryInput(
        program(artifact, false), artifact, 1_048_576);

    CompilerMachineRunner.runWithoutRewindHistory(machine);

    assertEquals(1, machine.global("published"));
    assertArrayEquals(artifact, machine.hostOutput());
    new BytecodeReader().read(machine.hostOutput());
  }

  @Test
  void preservesCanonicalOptionalSections() throws Exception {
    byte[] artifact = proofArtifact();
    VirtualMachine machine = VirtualMachine.withBinaryInput(
        program(artifact, false), artifact, 1_048_576);

    CompilerMachineRunner.runWithoutRewindHistory(machine);

    assertArrayEquals(artifact, machine.hostOutput());
    assertEquals(1, new BytecodeReader().read(machine.hostOutput()).proofCertificates().size());
  }

  @Test
  void rejectsInvalidSectionExtentsBeforePublication() throws Exception {
    byte[] artifact = artifact();
    VirtualMachine machine = VirtualMachine.withBinaryInput(
        program(artifact, true), artifact, 1_048_576);

    assertThrows(
        VmTrap.class, () -> CompilerMachineRunner.runWithoutRewindHistory(machine));
    assertEquals(0, machine.global("published"));
  }

  private static byte[] artifact() {
    String source = """
        module fixture.linked_container;

        classical class LinkedContainerFixture {
          state long marker = -9;

          record Pair(long left, boolean ready) {}

          entry void main() {
            Pair pair = new Pair(marker, true);
            assert(pair.ready);
          }
        }
        """;
    Program program = new WheelerCompiler().compileModuleFiles(
        Map.of("LinkedContainerFixture.w", source), "fixture.linked_container");
    return new BytecodeWriter().write(program);
  }

  private static byte[] proofArtifact() {
    FunctionBody main = new FunctionBody(
        0,
        "main",
        false,
        0,
        List.of(),
        null,
        List.of(Instruction.of(Opcode.CALL, 1), Instruction.of(Opcode.HALT)),
        List.of());
    FunctionBody increment = new FunctionBody(
        1,
        "increment",
        false,
        0,
        List.of(),
        null,
        List.of(Instruction.of(Opcode.ADD_CONST, 0, 1), Instruction.of(Opcode.RETURN)),
        List.of(Instruction.of(Opcode.SUB_CONST, 0, 1), Instruction.of(Opcode.RETURN)));
    ProofCertificate proof = new ProofCertificate(
        0, "incrementInverse", ProofRule.GENERATED_INVERSE, 1, -1);
    Program program = Program.classical(
        "ProofContainer",
        0,
        List.of(new Global("value", 0)),
        List.of(),
        List.of(),
        List.of(),
        List.of(),
        List.of(main, increment),
        List.of(proof));
    return new BytecodeWriter().write(program);
  }

  private static Program program(byte[] artifact, boolean invalid) throws Exception {
    ByteBuffer bytes = ByteBuffer.wrap(artifact).order(ByteOrder.LITTLE_ENDIAN);
    int sectionCount = bytes.getInt(24);
    StringBuilder rows = new StringBuilder();
    for (int section = 0; section < sectionCount; section++) {
      int directory = 40 + section * 32;
      long length = bytes.getLong(directory + 16);
      if (invalid && section == 0) {
        length++;
      }
      rows.append("set(types, ").append(section).append(", ")
          .append(bytes.getInt(directory)).append(");\n");
      rows.append("set(starts, ").append(section).append(", ")
          .append(bytes.getLong(directory + 8)).append(");\n");
      rows.append("set(lengths, ").append(section).append(", ")
          .append(length).append(");\n");
    }

    Map<String, String> sources = new LinkedHashMap<>();
    CoreSources.addBinaryClosure(sources);
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.linked_container"));
    sources.put("LinkedContainerExample.w", """
        module example.linked_container;

        import wheeler.compiler.closure.linked_container;

        classical class LinkedContainerExample {
          state long published = 0;

          entry void main(borrow byteview source, borrow mut bytes output) {
            region directory = new region(/* bytes= */ 1536, /* allocations= */ 3);
            words types = allocate(directory, /* length= */ 64);
            words starts = allocate(directory, /* length= */ 64);
            words lengths = allocate(directory, /* length= */ 64);
            %s
            long artifactBytes = emitCanonicalContainer(
              source,
              bufferLength(source),
              /* sectionCount= */ %d,
              types,
              starts,
              lengths,
              output
            );
            published = 1;
            setOutputLength(output, artifactBytes);
            drop(lengths);
            drop(starts);
            drop(types);
            drop(directory);
          }
        }
        """.formatted(rows, sectionCount));
    return new WheelerCompiler().compileModuleFiles(sources, "example.linked_container");
  }
}
