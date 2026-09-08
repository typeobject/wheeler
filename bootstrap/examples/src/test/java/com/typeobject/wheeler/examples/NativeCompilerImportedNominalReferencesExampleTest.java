package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeReader;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.MachineSnapshot;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import java.nio.charset.StandardCharsets;
import java.util.LinkedHashMap;
import java.util.List;
import org.junit.jupiter.api.Test;

/** Complete source, projection, execution, and rewind evidence after callable rewriting. */
final class NativeCompilerImportedNominalReferencesExampleTest {
  private static final String AUTHORED = """
      classical class Root {
        state long observed = -9;
        private long call() { return dep.fun(); }
        private long use(Box value) { return value.value; }
        entry void main() {
          Box item = new Box(7);
          observed = use(item);
          assert(observed == 7);
        }
      }
      """.strip();
  private static final String CALLABLE = callableSource();
  private static final List<Integer> REFERENCES = List.of(
      AUTHORED.indexOf("Box value"), AUTHORED.indexOf("Box item"), AUTHORED.indexOf("Box(7)"));

  @Test
  void rewritesAdjustedReferencesBeforeUseAndExecutesTheCompleteResult() throws Exception {
    VirtualMachine machine = machine(0, false);
    MachineSnapshot initial = machine.snapshot();
    while (machine.global("prepared") == 0) { machine.step(); }
    MachineSnapshot before = machine.snapshot();
    byte[] expected = machine.hostOutput();
    String rewritten = CALLABLE.replace("Box", "WheelerNominal3");
    int opening = rewritten.indexOf('{') + 1;
    rewritten = rewritten.substring(0, opening)
        + " private record WheelerNominal3(long value) {}" + rewritten.substring(opening);
    byte[] source = rewritten.getBytes(StandardCharsets.US_ASCII);
    System.arraycopy(source, 0, expected, 0, source.length);
    while (machine.global("published") == 0) { machine.step(); }
    assertEquals(CALLABLE.length() + 3, machine.global("carrierLength"));
    assertEquals(108, machine.global("carrierFirst"));
    assertEquals(1, machine.global("stubCount"));
    assertEquals(1, machine.global("projectionCount"));
    assertArrayEquals(expected, machine.hostOutput());
    int caller = caller(before);
    var original = before.buffers().stream().filter(b -> b.regionId() == caller).toList();
    var actual = machine.snapshot().buffers().stream().filter(b -> b.regionId() == caller).toList();
    for (int row = 0; row < 3; row++) { assertEquals(original.get(row), actual.get(row)); }
    long[] projections = original.get(3).elements().stream().mapToLong(Long::longValue).toArray();
    projections[0] = 7;
    projections[16384] = 0x10000000L;
    projections[32768] = 3;
    assertArrayEquals(projections, actual.get(3).elements().stream().mapToLong(Long::longValue).toArray());
    machine.run();
    assertArrayEquals(source, machine.hostOutput());
    rewind(machine, initial);

    Program compiled = new WheelerCompiler().compile(rewritten);
    compiled = new BytecodeReader().read(new BytecodeWriter().write(compiled));
    assertEquals(1, compiled.recordTypes().size());
    assertEquals("WheelerNominal3", compiled.recordTypes().getFirst().name());
    VirtualMachine executable = new VirtualMachine(compiled);
    MachineSnapshot unexecuted = executable.snapshot();
    executable.run();
    assertEquals(7, executable.global("observed"));
    rewind(executable, unexecuted);
  }

  @Test
  void rejectsAReferenceOverlappingACallBeforePublicationAndRewinds() throws Exception {
    rejects(machine(0, true));
  }

  @Test
  void rejectsKindTagAliasesThroughTheProductionReferenceWriterAndRewinds() throws Exception {
    rejects(machine(0x10000000L, false));
    rejects(machine(Long.MAX_VALUE, false));
  }

  private static void rejects(VirtualMachine machine) {
    MachineSnapshot initial = machine.snapshot();
    while (machine.global("prepared") == 0) { machine.step(); }
    MachineSnapshot before = machine.snapshot();
    byte[] output = machine.hostOutput();
    assertThrows(VmTrap.class, machine::run);
    assertEquals(0, machine.global("published"));
    assertArrayEquals(output, machine.hostOutput());
    int caller = caller(before);
    assertEquals(before.buffers().stream().filter(b -> b.regionId() == caller).toList(),
        machine.snapshot().buffers().stream().filter(b -> b.regionId() == caller).toList());
    rewind(machine, initial);
  }

  private static int caller(MachineSnapshot snapshot) {
    return snapshot.regions().stream().filter(r -> r.maxBytes() == 698368)
        .findFirst().orElseThrow().id();
  }

  private static void rewind(VirtualMachine machine, MachineSnapshot initial) {
    while (machine.historySize() > 0) { machine.rewindOne(); }
    assertEquals(initial, machine.snapshot());
  }

  private static VirtualMachine machine(long firstRecord, boolean overlap) throws Exception {
    byte[] authored = AUTHORED.getBytes(StandardCharsets.US_ASCII);
    byte[] callable = CALLABLE.getBytes(StandardCharsets.US_ASCII);
    byte[] input = new byte[authored.length + callable.length];
    System.arraycopy(authored, 0, input, 0, authored.length);
    System.arraycopy(callable, 0, input, authored.length, callable.length);
    var sources = new LinkedHashMap<>(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.imported_nominal_references"));
    StringBuilder references = new StringBuilder();
    for (int row = 0; row < REFERENCES.size(); row++) {
      references.append("set(references, ").append(row).append(", ")
          .append(overlap && row == 0 ? AUTHORED.indexOf("dep.fun") : REFERENCES.get(row)).append(");\n")
          .append("set(references, ").append(64 + row).append(", 3);\n")
          .append("set(references, ").append(128 + row).append(", 3);\n")
          .append("set(references, ").append(192 + row).append(", 1);\n");
    }
    sources.put("ImportedNominalReferencesExample.w", """
        module example.imported_nominal_references;
        import wheeler.compiler.closure.imported_nominal_references;

        classical class ImportedNominalReferencesExample {
          state long prepared = 0;
          state long published = 0;
          state long carrierLength = 0;
          state long carrierFirst = 0;
          state long stubCount = 0;
          state long projectionCount = 0;

          entry void main(borrow byteview input, borrow mut bytes output) {
            region rows = new region(/* bytes= */ 698368, /* allocations= */ 4);
            words references = allocate(rows, /* length= */ 256);
            words calls = allocate(rows, /* length= */ 1024);
            words aggregates = allocate(rows, /* length= */ 36864);
            words projections = allocate(rows, /* length= */ 49152);
            %s
            set(calls, 0, %d);
            set(calls, 256, 7);
            set(calls, 768, 5);
            set(aggregates, 3, 1);
            set(projections, 0, 17);
            set(projections, 12345, 19);
            set(projections, 49151, 23);
            setByte(output, 0, 29);
            setByte(output, 12345, 31);
            setByte(output, 32767, 37);
            if (%s) {
              ImportedNominalCarrierPlan carrier = writeImportedNominalCarriers(
                input, 0, %d, input, %d, %d, 3, references, 1, calls, aggregates, output
              );
              carrierLength = carrier.length;
              carrierFirst = output[%d];
            }
            prepared = 1;
            ImportedNominalReferencePlan plan = writeImportedNominalReferences(
              input, 0, %d, input, %d, %d, 7, %d, 0, 3, references,
              1, calls, aggregates, projections, output
            );
            stubCount = plan.stubCount;
            projectionCount = plan.projectionCount;
            published = 1;
            setOutputLength(output, plan.length);
            drop(projections);
            drop(aggregates);
            drop(calls);
            drop(references);
            drop(rows);
          }
        }
        """.formatted(references, AUTHORED.indexOf("dep.fun"), !overlap,
            authored.length, authored.length, callable.length, REFERENCES.getFirst() + 11,
            authored.length, authored.length, callable.length, firstRecord));
    Program program = new WheelerCompiler().compileModuleFiles(
        sources, "example.imported_nominal_references");
    return VirtualMachine.withBinaryInput(program, input, 32768);
  }

  private static String callableSource() {
    String rewritten = AUTHORED.replace("dep.fun", "__wheeler_import_5");
    int closing = rewritten.lastIndexOf('}');
    return rewritten.substring(0, closing)
        + " private long __wheeler_import_5() { return __wheeler_import_5(); } }";
  }
}
