package com.typeobject.wheeler.examples.fronts;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.compiler.CompilerException;
import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.MachineSnapshot;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.examples.CompilerSources;
import java.nio.charset.StandardCharsets;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Source type syntax does not decide nominal identity or lower aggregate layouts. */
final class NativeCompilerSourceTypeSyntaxExampleTest {
  private record Type(String text, long primitive, boolean compound) {}
  private record Execution(VirtualMachine machine, MachineSnapshot initial) {}

  @Test
  void parsesCompleteTypeSpansWithoutChangingScannerRowsAndRewinds() throws Exception {
    Program program = program();
    for (Type type : List.of(
        new Type("long", 1, false), new Type("boolean", 2, false),
        new Type("region", 3, false), new Type("words", 4, false),
        new Type("bytes", 5, false), new Type("longmap", 6, false),
        new Type("utf8", 7, false), new Type("byteview", 13, false),
        new Type("Done", 14, false), new Type("void", 0, false),
        new Type("long [ 65535 ]", 1, true), new Type("boolean[]", 2, true),
        new Type("Slot<long>", 1, true), new Type("Slot<Slot<Done>[2]>", 14, true),
        new Type("Slot<long[2]>[]", 1, true), new Type("Slot", -1, false),
        new Type("Pair", -1, false), new Type("test", -1, false),
        new Type("types.parts :: Pair [2]", -1, true),
        new Type("types.parts::void", -1, false),
        new Type("Slot<".repeat(256) + "long" + ">".repeat(256), 1, true))) {
      var execution = execute(program, "// café 𝄞\n" + type.text());
      var machine = execution.machine();
      assertEquals(1, machine.global("complete"), type.text());
      assertEquals(type.text().equals("void") ? 0 : 1,
          machine.global("valueComplete"), type.text());
      assertEquals(type.primitive(), machine.global("baseType"), type.text());
      assertEquals(type.compound() ? 1 : 0, machine.global("compound"), type.text());
      rewind(execution);
    }
  }

  @Test
  void rejectsMalformedTypesAndFirstExcessBoundsWithoutPublishingAFront() throws Exception {
    Program program = program();
    for (String type : List.of("", "long[0]", "long[65536]", "long[-1]", "long[",
        "long[]]", "long[1][2]", "words[]", "void[]", "Slot<long[]>",
        "Slot<bytes>", "Slot<Pair>", "Slot<void>", "Slot<long", "Slot<>",
        "types.Pair", "types::", "types::1", "types:::Pair", "long[9223372036854775808]",
        "Slot<".repeat(257) + "long" + ">".repeat(257))) {
      var execution = execute(program, type);
      assertEquals(0, execution.machine().global("complete"), type);
      assertEquals(0, execution.machine().global("valueComplete"), type);
      rewind(execution);
      assertThrows(CompilerException.class, () -> new WheelerCompiler().compileLibraryModuleFiles(
          Map.of("Type.w", "module example.types; classical class Types { void take("
              + type + " value) {} }"), "example.types"), type);
    }
  }

  private static Execution execute(Program program, String source) {
    var machine = new VirtualMachine(program, source.getBytes(StandardCharsets.UTF_8));
    var initial = machine.snapshot();
    machine.run();
    return new Execution(machine, initial);
  }

  private static void rewind(Execution execution) {
    var machine = execution.machine();
    while (machine.historySize() > 0) {
      machine.rewindOne();
    }
    assertEquals(execution.initial(), machine.snapshot());
  }

  private static Program program() throws Exception {
    Map<String, String> sources = new LinkedHashMap<>(CompilerSources.moduleClosure(
        "wheeler.compiler.source_type_syntax"));
    sources.putAll(CompilerSources.moduleClosure("wheeler.compiler.module_linker"));
    sources.put("TypeProbe.w", """
        module example.type_probe;
        import wheeler.compiler.module_linker;
        import wheeler.compiler.source_type_syntax;
        classical class TypeProbe {
          state long complete = 0;
          state long valueComplete = 0;
          state long baseType = 0;
          state long compound = 0;
          entry void main(borrow utf8 source) {
            region arena = new region(/* bytes= */ 49152, /* allocations= */ 6);
            words kinds = allocate(arena, 1024);
            words starts = allocate(arena, 1024);
            words lengths = allocate(arena, 1024);
            words oldKinds = allocate(arena, 1024);
            words oldStarts = allocate(arena, 1024);
            words oldLengths = allocate(arena, 1024);
            long count = scanSemanticTokens(source, kinds, starts, lengths);
            assert(-1 < count);
            long row = 0;
            while (row < 1024) limit 1024 {
              set(oldKinds, row, kinds[row]);
              set(oldStarts, row, starts[row]);
              set(oldLengths, row, lengths[row]);
              row += 1;
            }
            SourceTypeFront front = sourceTypeFront(source, kinds, starts, lengths, count, 0, true);
            if (front.valid) {
              if (front.nextToken == count) {
                complete = 1;
                baseType = front.baseType;
                if (front.compound) { compound = 1; }
              }
            }
            SourceTypeFront value = sourceTypeFront(source, kinds, starts, lengths, count, 0, false);
            if (value.valid) {
              if (value.nextToken == count) { valueComplete = 1; }
            }
            long minimum = -9223372036854775807 - 1;
            long maximum = 9223372036854775807;
            SourceTypeFront negative = sourceTypeFront(
              source, kinds, starts, lengths, count, minimum, true
            );
            assert(negative.valid == false);
            SourceTypeFront excess = sourceTypeFront(
              source, kinds, starts, lengths, count, maximum, true
            );
            assert(excess.valid == false);
            SourceTypeFront shortColumns = sourceTypeFront(
              source, kinds, starts, lengths, 1025, 0, true
            );
            assert(shortColumns.valid == false);
            SourceTypeFront excessiveCount = sourceTypeFront(
              source, kinds, starts, lengths, maximum, 0, true
            );
            assert(excessiveCount.valid == false);
            row = 0;
            while (row < 1024) limit 1024 {
              assert(kinds[row] == oldKinds[row]);
              assert(starts[row] == oldStarts[row]);
              assert(lengths[row] == oldLengths[row]);
              row += 1;
            }
            drop(oldLengths);
            drop(oldStarts);
            drop(oldKinds);
            drop(lengths);
            drop(starts);
            drop(kinds);
            drop(arena);
          }
        }
        """);
    return new WheelerCompiler().compileModuleFiles(sources, "example.type_probe");
  }
}
