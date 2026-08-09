package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.nio.charset.StandardCharsets;
import java.util.LinkedHashMap;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Native evidence for imported nominal lookup without dependency source. */
final class NativeCompilerImportedNominalProductsExampleTest {
  @Test
  void bindsQualificationAndPreservesUnqualifiedAmbiguity() throws Exception {
    VirtualMachine machine = machine(false);

    CompilerMachineRunner.runWithoutRewindHistory(machine);

    assertEquals(1, machine.global("rankedValid"));
    assertEquals(0, machine.global("rankedAggregate"));
    assertEquals(1, machine.global("rankedCandidates"));
    assertEquals(0, machine.global("unqualifiedValid"));
    assertEquals(-1, machine.global("unqualifiedAggregate"));
    assertEquals(2, machine.global("unqualifiedCandidates"));
  }

  @Test
  void rejectsMalformedStringProductsBeforeResolution() throws Exception {
    VirtualMachine machine = machine(true);

    CompilerMachineRunner.runWithoutRewindHistory(machine);

    assertEquals(0, machine.global("rankedValid"));
    assertEquals(-1, machine.global("rankedAggregate"));
    assertEquals(0, machine.global("rankedCandidates"));
  }

  private static VirtualMachine machine(boolean malformed) throws Exception {
    byte[] input = "Node".getBytes(StandardCharsets.US_ASCII);
    return VirtualMachine.withBinaryInput(program(malformed), input);
  }

  private static Program program(boolean malformed) throws Exception {
    Map<String, String> sources = new LinkedHashMap<>();
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.imported_nominal_products"));
    sources.put("ImportedNominalProductsExample.w", """
        module example.imported_nominal_products;

        import wheeler.compiler.closure.imported_nominal_products;

        classical class ImportedNominalProductsExample {
          state long rankedValid = 0;
          state long rankedAggregate = -1;
          state long rankedCandidates = 0;
          state long unqualifiedValid = 0;
          state long unqualifiedAggregate = -1;
          state long unqualifiedCandidates = 0;

          entry void main(borrow byteview input) {
            region rows = new region(/* bytes= */ 626688, /* allocations= */ 5);
            words candidates = allocate(rows, /* length= */ 8192);
            words aggregates = allocate(rows, /* length= */ 36864);
            words firstStrings = allocate(rows, /* length= */ 512);
            words stringStarts = allocate(rows, /* length= */ 16384);
            words stringLengths = allocate(rows, /* length= */ 16384);
            set(candidates, 0, 0);
            set(candidates, 1, 1);
            set(candidates, 4096, 0);
            set(candidates, 4097, 1);
            set(aggregates, 0, 1);
            set(aggregates, 1, 1);
            set(aggregates, 4096, 1);
            set(aggregates, 4097, 2);
            set(aggregates, 12288, 0);
            set(aggregates, 12289, 0);
            set(firstStrings, 1, 0);
            set(firstStrings, 2, 0);
            set(stringStarts, 0, 0);
            set(stringLengths, 0, %d);
            ImportedNominalResolution ranked = resolveImportedNominalProduct(
              input,
              /* sourceStart= */ 0,
              /* sourceLength= */ 4,
              input,
              /* dependencyRank= */ 0,
              /* candidateCount= */ 2,
              candidates,
              aggregates,
              firstStrings,
              stringStarts,
              stringLengths,
              /* expectedKind= */ 1
            );
            if (ranked.valid) {
              rankedValid = 1;
            }
            rankedAggregate = ranked.aggregateRow;
            rankedCandidates = ranked.candidateCount;
            ImportedNominalResolution unqualified = resolveImportedNominalProduct(
              input,
              /* sourceStart= */ 0,
              /* sourceLength= */ 4,
              input,
              /* dependencyRank= */ -1,
              /* candidateCount= */ 2,
              candidates,
              aggregates,
              firstStrings,
              stringStarts,
              stringLengths,
              /* expectedKind= */ 1
            );
            if (unqualified.valid) {
              unqualifiedValid = 1;
            }
            unqualifiedAggregate = unqualified.aggregateRow;
            unqualifiedCandidates = unqualified.candidateCount;
            drop(stringLengths);
            drop(stringStarts);
            drop(firstStrings);
            drop(aggregates);
            drop(candidates);
            drop(rows);
          }
        }
        """.formatted(malformed ? 5 : 4));
    return new WheelerCompiler().compileModuleFiles(sources, "example.imported_nominal_products");
  }
}
