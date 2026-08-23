package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.runtime.SemanticCoverage;
import com.typeobject.wheeler.runtime.WheelerRuntime;
import java.nio.charset.StandardCharsets;
import org.junit.jupiter.api.Test;

/** Proves native semantic direction for forward calls and generated inverses. */
final class NativeDirectionCoverageExampleTest {
  private static final String SUBJECT = """
      classical class DirectionSubject {
        state long count = 0;

        rev void increment() {
          count += 1;
        }

        entry void main() {
          increment();
          reverse increment();
        }
      }
      """;

  @Test
  void nativeInverseDirectionMatchesStageZero() throws Exception {
    WheelerCompiler compiler = new WheelerCompiler();
    Program program = compiler.compile(SUBJECT);
    byte[] artifact = compiler.compileToBytecode(SUBJECT);
    SemanticCoverage stageZero = new SemanticCoverage();
    new WheelerRuntime().executeObserved(program, stageZero);

    VirtualMachine machine = VirtualMachine.withBinaryInput(
        NativeCoverageRunExampleTest.runner(), artifact, 32_768);
    CompilerMachineRunner.runWithoutRewindHistory(machine);

    byte[] expected = stageZero.canonicalReport().getBytes(StandardCharsets.UTF_8);
    assertArrayEquals(expected, machine.hostOutput());
    String report = new String(machine.hostOutput(), StandardCharsets.UTF_8);
    assertTrue(report.contains("\"direction\":\"forward\""));
    assertTrue(report.contains("\"direction\":\"inverse\""));
    assertTrue(report.contains("\"opcode\":\"UNCALL\""));
    assertTrue(report.contains("\"opcode\":\"SUB_CONST\""));
  }
}
