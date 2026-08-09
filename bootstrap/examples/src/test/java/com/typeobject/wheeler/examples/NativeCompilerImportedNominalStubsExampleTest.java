package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import java.nio.charset.StandardCharsets;
import java.util.LinkedHashMap;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Native evidence for deterministic imported nominal scaffolding. */
final class NativeCompilerImportedNominalStubsExampleTest {
  @Test
  void emitsSortedScaffoldingAndTemporaryTypeProjections() throws Exception {
    String source = "classical class Root {}";
    VirtualMachine machine = machine(source);

    CompilerMachineRunner.runWithoutRewindHistory(machine);

    assertEquals(1, machine.global("published"));
    assertEquals(2, machine.global("stubCount"));
    assertEquals(2, machine.global("projectionCount"));
    assertEquals(2, machine.global("firstOwner"));
    assertEquals(268_435_463, machine.global("firstSourceCode"));
    assertEquals(3, machine.global("firstTarget"));
    assertEquals(536_870_921, machine.global("secondSourceCode"));
    assertEquals(8, machine.global("secondTarget"));
    assertEquals(
        "classical class Root { private record WheelerNominal3(long value) {} "
            + "private variant WheelerNominal8 { case Value(long value); } }",
        new String(machine.hostOutput(), StandardCharsets.US_ASCII));
  }

  @Test
  void rejectsReservedNominalNamesBeforePublication() throws Exception {
    assertReservedNameFails("classical class Root { private long WheelerNominal3 = 0; }");
    assertReservedNameFails("classical class Root { private long __wheeler_nominal_3 = 0; }");
  }

  private static void assertReservedNameFails(String source) throws Exception {
    VirtualMachine machine = machine(source);
    assertThrows(
        VmTrap.class, () -> CompilerMachineRunner.runWithoutRewindHistory(machine));
    assertEquals(0, machine.global("published"));
  }

  private static VirtualMachine machine(String source) throws Exception {
    return VirtualMachine.withBinaryInput(
        program(), source.getBytes(StandardCharsets.US_ASCII), 32_768);
  }

  private static Program program() throws Exception {
    Map<String, String> sources = new LinkedHashMap<>();
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.imported_nominal_stubs"));
    sources.put("ImportedNominalStubsExample.w", """
        module example.imported_nominal_stubs;

        import wheeler.compiler.closure.imported_nominal_stubs;

        classical class ImportedNominalStubsExample {
          state long published = 0;
          state long stubCount = 0;
          state long projectionCount = 0;
          state long firstOwner = 0;
          state long firstSourceCode = 0;
          state long firstTarget = 0;
          state long secondSourceCode = 0;
          state long secondTarget = 0;

          entry void main(borrow byteview input, borrow mut bytes output) {
            region rows = new region(/* bytes= */ 688640, /* allocations= */ 3);
            words targets = allocate(rows, /* length= */ 64);
            words aggregates = allocate(rows, /* length= */ 36864);
            words projections = allocate(rows, /* length= */ 49152);
            set(targets, 0, 8);
            set(targets, 1, 3);
            set(aggregates, 3, 1);
            set(aggregates, 8, 4);
            ImportedNominalStubPlan plan = writeImportedNominalStubs(
              input,
              /* sourceStart= */ 0,
              bufferLength(input),
              /* moduleOwner= */ 2,
              /* firstRecordTypeId= */ 7,
              /* firstVariantTypeId= */ 9,
              /* targetCount= */ 2,
              targets,
              aggregates,
              projections,
              output
            );
            stubCount = plan.stubCount;
            projectionCount = plan.projectionCount;
            firstOwner = projections[0];
            firstSourceCode = projections[16384];
            firstTarget = projections[32768];
            secondSourceCode = projections[16385];
            secondTarget = projections[32769];
            published = 1;
            setOutputLength(output, plan.length);
            drop(projections);
            drop(aggregates);
            drop(targets);
            drop(rows);
          }
        }
        """);
    return new WheelerCompiler().compileModuleFiles(sources, "example.imported_nominal_stubs");
  }
}
