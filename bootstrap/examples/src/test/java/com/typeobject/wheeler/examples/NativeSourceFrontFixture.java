package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.nio.charset.StandardCharsets;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.TreeSet;
import java.util.function.Consumer;

/** Shared scanner-column and full-rewind evidence for source front products. */
public final class NativeSourceFrontFixture {
  private NativeSourceFrontFixture() {}

  /** Checks the complete scanner columns and restores the initial machine snapshot. */
  public static void check(Program program, String source, Consumer<VirtualMachine> assertions) {
    var machine = new VirtualMachine(program, source.getBytes(StandardCharsets.UTF_8));
    var initial = machine.snapshot();
    machine.run();
    assertions.accept(machine);
    while (machine.historySize() > 0) {
      machine.rewindOne();
    }
    assertEquals(initial, machine.snapshot());
  }

  /** Builds a source-front fixture with explicit column capacity and no byte output. */
  public static Program program(List<String> owners, int capacity, String globals, String body)
      throws Exception {
    return program(owners, capacity, globals, body, false);
  }

  /** Builds a source-front fixture with an optional borrowed output window. */
  public static Program program(List<String> owners, int capacity, String globals, String body,
      boolean byteOutput) throws Exception {
    var imports = new TreeSet<>(owners);
    imports.add("wheeler.compiler.module_linker");
    Map<String, String> sources = new LinkedHashMap<>();
    for (String owner : imports) {
      sources.putAll(CompilerSources.moduleClosure(owner));
    }
    String importText = String.join("\n", imports.stream().map(name -> "import " + name + ";").toList());
    sources.put("SourceFrontProbe.w", """
        module example.source_front_probe;
        %s
        classical class SourceFrontProbe {
          %s
          entry void main(borrow utf8 source%s) {
            region arena = new region(/* bytes= */ %d, /* allocations= */ 6);
            words kinds = allocate(arena, %d);
            words starts = allocate(arena, %d);
            words lengths = allocate(arena, %d);
            words oldKinds = allocate(arena, %d);
            words oldStarts = allocate(arena, %d);
            words oldLengths = allocate(arena, %d);
            long count = scanSemanticTokens(source, kinds, starts, lengths);
            assert(-1 < count);
            long row = 0;
            while (row < %d) limit %d {
              set(oldKinds, row, kinds[row]);
              set(oldStarts, row, starts[row]);
              set(oldLengths, row, lengths[row]);
              row += 1;
            }
            %s
            row = 0;
            while (row < %d) limit %d {
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
        """.formatted(importText, globals, byteOutput ? ", borrow mut bytes output" : "",
            Math.multiplyExact(48, capacity), capacity, capacity,
            capacity, capacity, capacity, capacity, capacity, capacity, body, capacity, capacity));
    return new WheelerCompiler().compileModuleFiles(sources, "example.source_front_probe");
  }
}
