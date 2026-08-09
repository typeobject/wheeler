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

/** Native evidence for imported nominal reference rewriting after callable rewriting. */
final class NativeCompilerImportedNominalReferencesExampleTest {
  private static final String AUTHORED = """
      classical class Root { private long call() { return dep.fun(); } private long use(Box value) { return 1; } entry void main() {} }
      """.strip();
  private static final String CALLABLE = callableSource();

  @Test
  void rewritesAdjustedReferencesAndAppendsOneDeclarationPerTarget() throws Exception {
    VirtualMachine machine = machine(/* referenceStart= */ AUTHORED.indexOf("Box"));

    CompilerMachineRunner.runWithoutRewindHistory(machine);

    String rewritten = new String(machine.hostOutput(), StandardCharsets.US_ASCII);
    assertEquals(1, machine.global("stubCount"));
    assertEquals(1, machine.global("projectionCount"));
    assertEquals(7, machine.global("owner"));
    assertEquals(268_435_456, machine.global("sourceCode"));
    assertEquals(3, machine.global("target"));
    assertEquals(true, rewritten.contains("use(WheelerNominal3 value)"));
    assertEquals(true, rewritten.startsWith(
        "classical class Root { private record WheelerNominal3(long value) {} "));

    Program compiled = new WheelerCompiler().compile(rewritten);
    assertEquals(1, compiled.recordTypes().size());
    assertEquals("WheelerNominal3", compiled.recordTypes().getFirst().name());
  }

  @Test
  void rejectsAReferenceOverlappingACallBeforePublication() throws Exception {
    VirtualMachine machine = machine(/* referenceStart= */ AUTHORED.indexOf("dep.fun"));

    assertThrows(
        VmTrap.class, () -> CompilerMachineRunner.runWithoutRewindHistory(machine));
    assertEquals(0, machine.global("published"));
  }

  private static VirtualMachine machine(int referenceStart) throws Exception {
    byte[] authored = AUTHORED.getBytes(StandardCharsets.US_ASCII);
    byte[] callable = CALLABLE.getBytes(StandardCharsets.US_ASCII);
    byte[] input = new byte[authored.length + callable.length];
    System.arraycopy(authored, 0, input, 0, authored.length);
    System.arraycopy(callable, 0, input, authored.length, callable.length);
    return VirtualMachine.withBinaryInput(
        program(
            authored.length,
            callable.length,
            AUTHORED.indexOf("dep.fun"),
            referenceStart),
        input,
        32_768);
  }

  private static Program program(
      int authoredLength,
      int callableLength,
      int callStart,
      int referenceStart) throws Exception {
    Map<String, String> sources = new LinkedHashMap<>();
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.imported_nominal_references"));
    sources.put("ImportedNominalReferencesExample.w", """
        module example.imported_nominal_references;

        import wheeler.compiler.closure.imported_nominal_references;

        classical class ImportedNominalReferencesExample {
          state long published = 0;
          state long stubCount = 0;
          state long projectionCount = 0;
          state long owner = 0;
          state long sourceCode = 0;
          state long target = 0;

          entry void main(borrow byteview input, borrow mut bytes output) {
            region rows = new region(/* bytes= */ 698368, /* allocations= */ 4);
            words references = allocate(rows, /* length= */ 256);
            words calls = allocate(rows, /* length= */ 1024);
            words aggregates = allocate(rows, /* length= */ 36864);
            words projections = allocate(rows, /* length= */ 49152);
            set(references, 0, %d);
            set(references, 64, 3);
            set(references, 128, 3);
            set(references, 192, 1);
            set(calls, 0, %d);
            set(calls, 256, 7);
            set(calls, 768, 5);
            set(aggregates, 3, 1);
            ImportedNominalReferencePlan plan = writeImportedNominalReferences(
              input,
              /* sourceStart= */ 0,
              /* sourceLength= */ %d,
              input,
              /* callableSourceStart= */ %d,
              /* callableSourceLength= */ %d,
              /* moduleOwner= */ 7,
              /* firstRecordTypeId= */ 0,
              /* firstVariantTypeId= */ 0,
              /* referenceCount= */ 1,
              references,
              /* callCount= */ 1,
              calls,
              aggregates,
              projections,
              output
            );
            stubCount = plan.stubCount;
            projectionCount = plan.projectionCount;
            owner = projections[0];
            sourceCode = projections[16384];
            target = projections[32768];
            published = 1;
            setOutputLength(output, plan.length);
            drop(projections);
            drop(aggregates);
            drop(calls);
            drop(references);
            drop(rows);
          }
        }
        """.formatted(
            referenceStart,
            callStart,
            authoredLength,
            authoredLength,
            callableLength));
    return new WheelerCompiler().compileModuleFiles(
        sources, "example.imported_nominal_references");
  }

  private static String callableSource() {
    String rewritten = AUTHORED.replace("dep.fun", "__wheeler_import_5");
    int closing = rewritten.lastIndexOf('}');
    return rewritten.substring(0, closing)
        + " private long __wheeler_import_5() { return __wheeler_import_5(); } }";
  }
}
