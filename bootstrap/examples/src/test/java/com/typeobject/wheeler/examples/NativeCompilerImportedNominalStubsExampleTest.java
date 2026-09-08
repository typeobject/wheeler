package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
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

    var initial = machine.snapshot();
    while (machine.global("prepared") == 0) { machine.step(); }
    var before = machine.snapshot();
    byte[] output = machine.hostOutput();
    byte[] sourceBytes = ("classical class Root { private record WheelerNominal3(long value) {} "
        + "private variant WheelerNominal8 { case Value(long value); } }")
        .getBytes(StandardCharsets.US_ASCII);
    System.arraycopy(sourceBytes, 0, output, 0, sourceBytes.length);
    while (machine.global("published") == 0) { machine.step(); }
    assertArrayEquals(output, machine.hostOutput());
    int caller = before.regions().stream().filter(r -> r.maxBytes() == 688640)
        .findFirst().orElseThrow().id();
    var expected = before.buffers().stream().filter(b -> b.regionId() == caller).toList();
    var actual = machine.snapshot().buffers().stream().filter(b -> b.regionId() == caller).toList();
    assertEquals(expected.subList(0, 2), actual.subList(0, 2));
    long[] projections = expected.get(2).elements().stream().mapToLong(Long::longValue).toArray();
    projections[0] = 2;
    projections[1] = 2;
    projections[16384] = 268435463;
    projections[16385] = 536870921;
    projections[32768] = 3;
    projections[32769] = 8;
    assertArrayEquals(projections, actual.get(2).elements().stream().mapToLong(Long::longValue).toArray());
    machine.run();
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
    while (machine.historySize() > 0) { machine.rewindOne(); }
    assertEquals(initial, machine.snapshot());
  }

  @Test
  void rejectsTypeIdTagAliasesBeforeChangingCallerStorageAndRewinds() throws Exception {
    for (long[] ids : new long[][] {{268435456, 9}, {7, 268435456}, {Long.MAX_VALUE, 9}}) {
      VirtualMachine machine = VirtualMachine.withBinaryInput(program(ids[0], ids[1]),
          "classical class Root {}".getBytes(StandardCharsets.US_ASCII), 32768);
      rejects(machine);
    }
  }

  @Test
  void rejectsReservedNominalNamesBeforePublication() throws Exception {
    assertReservedNameFails("classical class Root { private long WheelerNominal3 = 0; }");
    assertReservedNameFails("classical class Root { private long __wheeler_nominal_3 = 0; }");
  }

  @Test
  void rejectsDuplicateTargetsBeforeChangingCallerStorageAndRewinds() throws Exception {
    rejects(VirtualMachine.withBinaryInput(program(7, 9, true),
        "classical class Root {}".getBytes(StandardCharsets.US_ASCII), 32768));
  }

  private static void assertReservedNameFails(String source) throws Exception {
    rejects(machine(source));
  }

  private static void rejects(VirtualMachine machine) {
    var initial = machine.snapshot();
    while (machine.global("prepared") == 0) { machine.step(); }
    var prepared = machine.snapshot();
    byte[] output = machine.hostOutput();
    assertThrows(VmTrap.class, machine::run);
    assertEquals(0, machine.global("published"));
    assertArrayEquals(output, machine.hostOutput());
    int caller = prepared.regions().stream().filter(r -> r.maxBytes() == 688640)
        .findFirst().orElseThrow().id();
    assertEquals(prepared.buffers().stream().filter(b -> b.regionId() == caller).toList(),
        machine.snapshot().buffers().stream().filter(b -> b.regionId() == caller).toList());
    while (machine.historySize() > 0) { machine.rewindOne(); }
    assertEquals(initial, machine.snapshot());
  }

  private static VirtualMachine machine(String source) throws Exception {
    return VirtualMachine.withBinaryInput(
        program(), source.getBytes(StandardCharsets.US_ASCII), 32_768);
  }

  private static Program program() throws Exception {
    return program(7, 9);
  }

  private static Program program(long firstRecord, long firstVariant) throws Exception {
    return program(firstRecord, firstVariant, false);
  }

  private static Program program(long firstRecord, long firstVariant, boolean duplicateTargets)
      throws Exception {
    Map<String, String> sources = new LinkedHashMap<>();
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.imported_nominal_stubs"));
    sources.put("ImportedNominalStubsExample.w", """
        module example.imported_nominal_stubs;

        import wheeler.compiler.closure.imported_nominal_stubs;

        classical class ImportedNominalStubsExample {
          state long published = 0;
          state long prepared = 0;
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
            set(projections, 0, 17);
            set(projections, 12345, 19);
            set(projections, 49151, 23);
            setByte(output, 0, 29);
            setByte(output, 12345, 31);
            setByte(output, 32767, 37);
            prepared = 1;
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
        """.replace("/* firstRecordTypeId= */ 7", "/* firstRecordTypeId= */ " + firstRecord)
            .replace("/* firstVariantTypeId= */ 9", "/* firstVariantTypeId= */ " + firstVariant)
            .replace("set(targets, 0, 8);", "set(targets, 0, " + (duplicateTargets ? 3 : 8) + ");"));
    return new WheelerCompiler().compileModuleFiles(sources, "example.imported_nominal_stubs");
  }
}
