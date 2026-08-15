package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.nio.charset.StandardCharsets;
import java.util.LinkedHashMap;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Native evidence for source-declared generated-inverse proof products. */
final class NativeCompilerSourceGeneratedInverseProofsExampleTest {
  @Test
  void publishesProofNamesAndSubjectsInDeclarationOrder() throws Exception {
    String source = """
        module fixture.inverse_proofs;

        classical class InverseProofs {
          rev void alpha() {}

          rev void beta() {}

          theorem betaInverse proves inverse(beta);
          theorem alphaInverse proves inverse(alpha);
        }
        """;
    VirtualMachine machine = new VirtualMachine(
        program(), source.getBytes(StandardCharsets.UTF_8), 16_384);

    CompilerMachineRunner.runWithoutRewindHistory(machine);

    assertEquals(1, machine.global("valid"));
    assertEquals(2, machine.global("proofCount"));
    assertEquals(1, machine.global("firstSubject"));
    assertEquals(0, machine.global("secondSubject"));
    assertArrayEquals(
        "betaInversealphaInverse".getBytes(StandardCharsets.UTF_8),
        machine.hostOutput());
  }

  @Test
  void leavesNameProductsUntouchedForDuplicateSubjects() throws Exception {
    String source = """
        module fixture.inverse_proofs;

        classical class InverseProofs {
          rev void alpha() {}

          rev void beta() {}

          theorem betaInverse proves inverse(beta);
          theorem betaAgain proves inverse(beta);
        }
        """;
    VirtualMachine machine = new VirtualMachine(
        program(), source.getBytes(StandardCharsets.UTF_8), 16_384);

    CompilerMachineRunner.runWithoutRewindHistory(machine);

    assertEquals(0, machine.global("valid"));
    assertEquals(0, machine.global("proofCount"));
    assertArrayEquals(new byte[] {99}, machine.hostOutput());
  }

  private static Program program() throws Exception {
    Map<String, String> sources = new LinkedHashMap<>();
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.source_generated_inverse_proofs"));
    sources.put("SourceGeneratedInverseProofsExample.w", """
        module example.source_generated_inverse_proofs;

        import wheeler.compiler.closure.source_generated_inverse_proofs;

        classical class SourceGeneratedInverseProofsExample {
          state long valid = 0;
          state long proofCount = 0;
          state long firstSubject = -1;
          state long secondSubject = -1;

          entry void main(borrow utf8 source, borrow mut bytes output) {
            assert(bufferLength(output) == 16384);
            region arena = new region(/* bytes= */ 6153, /* allocations= */ 7);
            bytes names = allocateBytes(arena, /* length= */ 9);
            words stringStarts = allocate(arena, /* length= */ 256);
            words stringLengths = allocate(arena, /* length= */ 256);
            words functionNameIds = allocate(arena, /* length= */ 64);
            words proofNameStarts = allocate(arena, /* length= */ 64);
            words proofNameLengths = allocate(arena, /* length= */ 64);
            words proofSubjects = allocate(arena, /* length= */ 64);
            setByte(output, 0, 99);
            setByte(names, 0, 97);
            setByte(names, 1, 108);
            setByte(names, 2, 112);
            setByte(names, 3, 104);
            setByte(names, 4, 97);
            setByte(names, 5, 98);
            setByte(names, 6, 101);
            setByte(names, 7, 116);
            setByte(names, 8, 97);
            set(stringStarts, 0, 0);
            set(stringLengths, 0, 5);
            set(stringStarts, 1, 5);
            set(stringLengths, 1, 4);
            set(functionNameIds, 0, 0);
            set(functionNameIds, 1, 1);
            SourceGeneratedInverseProofPlan plan = materializeSourceGeneratedInverseProofs(
              source,
              /* callableCount= */ 2,
              names,
              /* stringBytes= */ 9,
              /* stringCount= */ 2,
              stringStarts,
              stringLengths,
              functionNameIds,
              output,
              proofNameStarts,
              proofNameLengths,
              proofSubjects
            );
            proofCount = plan.proofCount;
            if (plan.valid) {
              valid = 1;
              firstSubject = proofSubjects[0];
              secondSubject = proofSubjects[1];
              setOutputLength(output, proofNameLengths[0] + proofNameLengths[1]);
            } else {
              setOutputLength(output, 1);
            }
            drop(proofSubjects);
            drop(proofNameLengths);
            drop(proofNameStarts);
            drop(functionNameIds);
            drop(stringLengths);
            drop(stringStarts);
            drop(names);
            drop(arena);
          }
        }
        """);
    return new WheelerCompiler().compileModuleFiles(
        sources, "example.source_generated_inverse_proofs");
  }
}
