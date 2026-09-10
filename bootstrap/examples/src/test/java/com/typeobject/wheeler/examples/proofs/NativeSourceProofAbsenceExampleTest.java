package com.typeobject.wheeler.examples.proofs;

import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.BufferKind;
import com.typeobject.wheeler.core.vm.BufferValue;
import com.typeobject.wheeler.core.vm.MachineSnapshot;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.examples.CompilerMachineRunner;
import com.typeobject.wheeler.examples.CompilerSources;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Stream;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.Arguments;
import org.junit.jupiter.params.provider.MethodSource;
import org.junit.jupiter.params.provider.ValueSource;

/** Checks allocation-free proof absence against shared fronts and reusable private columns. */
final class NativeSourceProofAbsenceExampleTest {
  private static final int TOKEN_COLUMNS = 3;
  private static final int TOKEN_ROWS = 4096;
  private static final int MODULE_ROWS = 64;
  private static final long SENTINEL = 211;
  private static Program program;

  @BeforeAll
  static void compileDriver() throws Exception {
    Map<String, String> modules = new HashMap<>(
        CompilerSources.moduleClosure("wheeler.compiler.closure.source_classical_proofs"));
    modules.put("ProofAbsence.w", """
        module example.proof_absence;
        import wheeler.compiler.closure.source_classical_proofs;
        import wheeler.compiler.compiler_token_limits;
        classical class ProofAbsence {
          const long TOKEN_COLUMNS = 3;
          const long MODULE_ROWS = 64;
          const long WORD_BYTES = 8;
          const long TABLES = TOKEN_COLUMNS + 1;
          const long ARENA_BYTES = (MAX_COMPILER_TOKENS * TOKEN_COLUMNS + MODULE_ROWS) * WORD_BYTES;
          state long prepared = 0;
          state long admitted = -1;
          state long completed = 0;
          entry void main(borrow utf8 source) {
            region scratch = new region(ARENA_BYTES, TABLES);
            words kinds = allocate(scratch, MAX_COMPILER_TOKENS);
            words starts = allocate(scratch, MAX_COMPILER_TOKENS);
            words lengths = allocate(scratch, MAX_COMPILER_TOKENS);
            words moduleRange = allocate(scratch, MODULE_ROWS);
            long index = 0;
            while (index < MAX_COMPILER_TOKENS) limit MAX_COMPILER_TOKENS {
              set(kinds, index, 211);
              set(starts, index, 211);
              set(lengths, index, 211);
              index += 1;
            }
            index = 0;
            while (index < MODULE_ROWS) limit MODULE_ROWS {
              set(moduleRange, index, 211);
              index += 1;
            }
            prepared = 1;
            admitted = 0;
            if (sourceClassicalClaimsAbsent(source, kinds, starts, lengths, moduleRange)) {
              admitted = 1;
            }
            completed = 1;
            drop(moduleRange);
            drop(lengths);
            drop(starts);
            drop(kinds);
            drop(scratch);
          }
        }
        """);
    program = new WheelerCompiler().compileModuleFiles(modules, "example.proof_absence");
  }

  @ParameterizedTest
  @MethodSource("sources")
  void clearsEveryPrivateTokenCellAndAllocatesNoAdditionalBuffers(String source, boolean accepted) {
    check(source, accepted, true);
  }

  @ParameterizedTest
  @ValueSource(strings = {"structured_source_module_compiler", "source_classical_proofs",
      "source_generated_inverse_proofs"})
  void admitsPhysicalOwnersWithinTheUnchangedScannerWindow(String owner) throws Exception {
    String module = "wheeler.compiler.closure." + owner;
    String source = CompilerSources.moduleClosure(module).values().stream()
        .filter(value -> value.contains("module " + module + ";")).findFirst().orElseThrow();
    check(source, true, false);
  }

  @Test
  void admitsPhysicalCoreParsingWithCommentsAndHeaderWhitespace() throws Exception {
    String module = "wheeler.compiler.core_parsing";
    String source = CompilerSources.moduleClosure(module).values().stream()
        .filter(value -> value.contains("module " + module + ";")).findFirst().orElseThrow();
    check(source, true, false);
    check(source.replace("module " + module, "module\n" + module), true, false);
    check(source.replace("classical class CoreParsing", "classical\n/* header */ class\tCoreParsing"), true, false);
    check("// café 𝄞 module misleading.name; classical class Ghost {}\n" + source, true, false);
    check("/* module other.name; classical class Other {} */\n" + source, true, false);
    check(source + "\n// module trailing.name; classical class Last {}\n", true, false);
    check("// café 𝄞 module misleading.name; classical class Ghost {}\n"
        + "/* module other.name; classical class Other {} */\n"
        + source.replace("module " + module, "module\n" + module)
            .replace("classical class CoreParsing", "classical\n/* header */ class\tCoreParsing")
        + "\n// module trailing.name; classical class Last {}\n", true, false);
  }

  private static void check(String source, boolean accepted, boolean rewind) {
    VirtualMachine machine = SourceProofFixture.machine(program, source);
    MachineSnapshot initial = machine.snapshot();
    while (machine.global("prepared") == 0) {
      step(machine, rewind);
    }
    MachineSnapshot prepared = machine.snapshot();
    while (machine.global("completed") == 0) {
      step(machine, rewind);
    }
    MachineSnapshot result = machine.snapshot();
    assertEquals(accepted ? 1 : 0, machine.global("admitted"));
    assertEquals(prepared.regions(), result.regions());
    assertEquals(prepared.buffers().size(), result.buffers().size());
    assertEquals(prepared.buffers().getFirst(), result.buffers().getFirst());
    List<BufferValue> words = result.buffers().stream()
        .filter(value -> value.kind() == BufferKind.WORDS && value.length() == TOKEN_ROWS).toList();
    assertEquals(TOKEN_COLUMNS, words.size());
    for (BufferValue column : words) {
      for (long value : column.elements()) {
        assertEquals(0, value);
      }
    }
    BufferValue module = result.buffers().stream()
        .filter(value -> value.kind() == BufferKind.WORDS && value.length() == MODULE_ROWS)
        .findFirst().orElseThrow();
    for (int index = 0; index < MODULE_ROWS; index++) {
      assertEquals(index < 2 ? 0 : SENTINEL, module.elements().get(index));
    }
    if (rewind) {
      machine.run();
    } else {
      CompilerMachineRunner.runWithoutRewindHistory(machine);
      assertEquals(0, machine.historySize());
    }
    assertEquals(TOKEN_COLUMNS + 1, machine.snapshot().buffers().stream()
        .filter(value -> value.kind() == BufferKind.WORDS && value.dropped()).count());
    if (rewind) {
      SourceProofFixture.replay(machine, initial);
    }
  }

  private static void step(VirtualMachine machine, boolean rewind) {
    if (rewind) {
      machine.step();
    } else {
      machine.stepWithoutRewindHistory();
    }
  }

  static Stream<Arguments> sources() {
    return Stream.of(
        Arguments.of("classical class Empty {}", true),
        Arguments.of("classical class Names { long theorem() { long theorem = 1; return theorem; } }", true),
        Arguments.of("// café 𝄞 theorem\nmodule pkg.empty; classical class Empty {}", true),
        Arguments.of("classical class Types { record Pair(long x) {} enum E { case A; } "
            + "variant V { case Item(); } }", true),
        Arguments.of("classical class Bound { long f() { return 7; } theorem B proves steps(f, 8); }", false),
        Arguments.of("classical class Bound { rev void f() {} theorem B proves inverse(f); }", false),
        Arguments.of("classical class Bound { long f() { return 7; } // preceding comment\r"
            + "theorem B proves steps(f, 8); }", false),
        Arguments.of("classical class Bad { theorem B proves steps(missing,); }", false),
        Arguments.of("classical class Bad { tetU void f() {} }", false),
        Arguments.of("classical class Bad {", false),
        Arguments.of("classical class Empty {} classical class Trailing {}", false),
        Arguments.of("", false));
  }
}
