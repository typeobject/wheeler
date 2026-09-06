package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import com.typeobject.wheeler.runtime.WheelerRuntime;
import java.util.HexFormat;
import java.util.List;
import org.junit.jupiter.api.Test;

/** Native execution identities bind actual VM work, including calls and termination. */
final class NativeArtifactStepIdentityExampleTest {
  private static final String TERMINAL = "classical class Terminal { entry void main() {} }";

  @Test
  void bindsTerminalHelperResultAndInverseTransitionsToIndependentExecution() throws Exception {
    Program probe = NativeCoverageRunExampleTest.artifactExecutionIdentity();
    for (String source : List.of(
        TERMINAL,
        "classical class Assertion { entry void main() { assert(true); } }",
        """
        classical class Helper {
          private void helper() { assert(true); }
          entry void main() { helper(); }
        }
        """,
        """
        classical class Result {
          private long helper(long value) { return value; }
          entry void main() {
            long input = 7;
            long result = helper(input);
            assert(result == 7);
          }
        }
        """,
        """
        classical class Inverse {
          state long count = 0;
          rev void increment() { count += 1; }
          entry void main() {
            increment();
            reverse { increment(); }
            assert(count == 0);
          }
        }
        """)) {
      Program reference = new WheelerCompiler().compile(source);
      var execution = new WheelerRuntime().execute(reference, null);
      assertTrue(execution.workflowSteps() > 0);
      if (source.equals(TERMINAL)) {
        assertEquals(1, execution.workflowSteps());
      }
      byte[] artifact = new BytecodeWriter().write(reference);
      var writer = VirtualMachine.withBinaryInput(probe, artifact, 32);
      CompilerMachineRunner.runWithoutRewindHistory(writer);
      assertArrayEquals(HexFormat.of().parseHex(NativeTestReportOracle.executionIdentity(execution)),
          writer.hostOutput(), reference.name());
    }
  }

  @Test
  void rewindsIdentityPublicationAndRejectedArtifactAdmission() throws Exception {
    Program reference = new WheelerCompiler().compile(TERMINAL);
    byte[] artifact = new BytecodeWriter().write(reference);
    Program probe = NativeCoverageRunExampleTest.artifactExecutionIdentity();
    byte[] expected = HexFormat.of().parseHex(NativeTestReportOracle.executionIdentity(
        new WheelerRuntime().execute(reference, null)));
    for (boolean accepted : List.of(true, false)) {
      byte[] input = artifact.clone();
      if (!accepted) {
        input[0] ^= 1;
      }
      var writer = VirtualMachine.withBinaryInput(probe, input, 32);
      var initial = writer.snapshot();
      if (accepted) {
        writer.run();
        assertArrayEquals(expected, writer.hostOutput());
      } else {
        assertThrows(VmTrap.class, writer::run);
        assertArrayEquals(new byte[32], writer.hostOutput());
      }
      while (writer.historySize() > 0) {
        writer.rewindOne();
      }
      assertEquals(initial, writer.snapshot());
    }
  }
}
