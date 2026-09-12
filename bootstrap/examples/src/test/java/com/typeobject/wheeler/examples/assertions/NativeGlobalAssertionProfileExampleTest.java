package com.typeobject.wheeler.examples.assertions;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.vm.MachineStatus;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import com.typeobject.wheeler.examples.CompilerSources;
import java.nio.charset.StandardCharsets;
import java.util.LinkedHashMap;
import java.util.List;
import org.junit.jupiter.api.Test;

/** Checks declaration-order selection and every active declaration coordinate without another parser. */
final class NativeGlobalAssertionProfileExampleTest {
  private static final int TOKENS = 4096;
  private static final String NAMES = "AlphaLater";

  @Test
  void distinguishesPriorDeclarationsFromLaterStatesAndGenericPredicates() throws Exception {
    check("Alpha == 5", true, "", 0, false);
    check("Alpha == -9223372036854775808", true, "", 0, false);
    check("Alpha == 9223372036854775807", true, "", 0, false);
    check("Alpha == 5", false, "", -1, false);
    check("Alpha == LIMIT", true, "", -1, false);
    check("5 == Alpha", true, "", -1, false);
    check("Alpha < 5", true, "", -1, false);
  }

  @Test
  void rejectsUnusedLateDeclarationCoordinatesWithoutMutatingAnyInput() throws Exception {
    for (String mutation : List.of(
        "set(globals, SOURCE_GLOBAL_DECLARATION_ROW + 1, -1);",
        "set(globals, SOURCE_GLOBAL_DECLARATION_ROW + 1, 9223372036854775807);",
        "set(globals, SOURCE_GLOBAL_DECLARATION_ROW + 1, bufferLength(source) - 4);",
        "set(globals, SOURCE_GLOBAL_LENGTH_ROW + 1, 0);",
        "set(globals, SOURCE_GLOBAL_LENGTH_ROW + 1, 9223372036854775807);")) {
      check("Alpha == 5", true, mutation, -1, true);
    }
  }

  private static void check(String predicate, boolean prior, String mutation, long expected, boolean trap)
      throws Exception {
    String declarations = "state long Alpha = 5; state long Later = 1;\n";
    String body = "long sample() { assert(" + predicate + "); }\n";
    String source = "// café 𝄞\nclassical class Example {\n"
        + (prior ? declarations + body : body + declarations) + "}";
    int assertion = byteOffset(source, source.indexOf("assert("));
    int alpha = byteOffset(source, source.indexOf("state long Alpha") + "state long ".length());
    int later = byteOffset(source, source.indexOf("state long Later") + "state long ".length());
    var sources = new LinkedHashMap<>(CompilerSources.moduleClosure("wheeler.compiler.closure.source_global_assertion_profile"));
    sources.putAll(CompilerSources.moduleClosure("wheeler.compiler.module_linker"));
    sources.put("Driver.w", """
        module example.global_assertion_profile;
        import wheeler.compiler.closure.source_global_assertion_profile;
        import wheeler.compiler.closure.source_global_schema;
        import wheeler.compiler.closure.source_reversible_result_relations;
        import wheeler.compiler.module_linker;
        classical class Driver {
          const long TOKENS = %d;
          const long NAMES = %d;
          const long TOKEN_COLUMNS = 3;
          const long WORD_BYTES = %d;
          const long ARENA_BYTES = (TOKENS * TOKEN_COLUMNS + SOURCE_GLOBAL_ROWS) * WORD_BYTES + NAMES;
          const long BUFFERS = TOKEN_COLUMNS + 2;
          state long prepared = 0;
          state long completed = 0;
          state long observed = -2;
          entry void main(borrow utf8 source) {
            region arena = new region(ARENA_BYTES, BUFFERS);
            words kinds = allocate(arena, TOKENS);
            words starts = allocate(arena, TOKENS);
            words lengths = allocate(arena, TOKENS);
            words globals = allocate(arena, SOURCE_GLOBAL_ROWS);
            bytes names = allocateBytes(arena, NAMES);
            writeAscii(names, 0, "AlphaLater");
            set(globals, 1, 5);
            set(globals, SOURCE_GLOBAL_LENGTH_ROW, 5);
            set(globals, SOURCE_GLOBAL_LENGTH_ROW + 1, 5);
            set(globals, SOURCE_GLOBAL_DECLARATION_ROW, %d);
            set(globals, SOURCE_GLOBAL_DECLARATION_ROW + 1, %d);
            long count = scanSemanticTokens(source, kinds, starts, lengths);
            assert(-1 < count);
            long token = 0;
            while (token < count) limit TOKENS {
              if (starts[token] == %d) { break; }
              token += 1;
            }
            assert(token < count);
            %s
            prepared = 1;
            requireSourceGlobalDeclarationRanges(source, 2, 0, globals);
            SourceReversibleResultRelation syntax = sourceAssertionRelation(source, token, count, kinds, starts, lengths);
            assert(syntax.valid);
            observed = globalLiteralAssertionOrdinal(syntax, source, starts, lengths, names, 2, 0, globals);
            completed = 1;
            drop(names); drop(globals); drop(lengths); drop(starts); drop(kinds); drop(arena);
          }
        }
        """.formatted(TOKENS, NAMES.length(), Long.BYTES, alpha, later, assertion, mutation));
    var program = new WheelerCompiler().compileModuleFiles(sources, "example.global_assertion_profile");
    var machine = new VirtualMachine(program, source.getBytes(StandardCharsets.UTF_8));
    while (machine.global("prepared") == 0) machine.stepWithoutRewindHistory();
    var before = machine.snapshot();
    run(machine, trap);
    var after = machine.snapshot();
    assertEquals(trap ? -2 : expected, machine.global("observed"));
    assertEquals(before.buffers(), after.buffers());
    assertEquals(before.regions(), after.regions());
    while (machine.historySize() > 0) machine.rewindOne();
    assertEquals(before, machine.snapshot());
    run(machine, trap);
    assertEquals(after, machine.snapshot());
    if (!trap) {
      while (machine.status() != MachineStatus.HALTED) machine.step();
      int borrowed = before.buffers().getFirst().regionId();
      assertTrue(machine.snapshot().buffers().stream().filter(b -> b.regionId() != borrowed).allMatch(b -> b.dropped()));
      assertTrue(machine.snapshot().regions().stream().filter(r -> r.id() != borrowed).allMatch(r -> r.dropped()));
    }
    while (machine.historySize() > 0) machine.rewindOne();
    assertEquals(before, machine.snapshot());
  }

  private static int byteOffset(String source, int character) {
    return source.substring(0, character).getBytes(StandardCharsets.UTF_8).length;
  }

  private static void run(VirtualMachine machine, boolean trap) {
    Runnable phase = () -> { while (machine.global("completed") == 0) machine.step(); };
    if (trap) assertThrows(VmTrap.class, phase::run);
    else phase.run();
  }
}
