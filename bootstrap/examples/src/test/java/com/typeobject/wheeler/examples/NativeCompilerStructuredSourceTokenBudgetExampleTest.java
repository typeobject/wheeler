package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.nio.charset.StandardCharsets;
import java.util.LinkedHashMap;
import org.junit.jupiter.api.Test;

/** Checks the orchestration module before paying for a complete archive pass. */
final class NativeCompilerStructuredSourceTokenBudgetExampleTest {
  @Test
  void keepsTheStructuredCompilerWithinTheNativeTokenArena() throws Exception {
    var sources = new LinkedHashMap<>(CompilerSources.moduleClosure("wheeler.compiler.module_linker"));
    sources.put("StructuredSourceTokens.w", """
        module example.structured_source_tokens;

        import wheeler.compiler.module_linker;

        classical class StructuredSourceTokens {
          state long count = -1;

          entry void main(borrow utf8 source) {
            region tokens = new region(/* bytes= */ 98304, /* allocations= */ 3);
            words kinds = allocate(tokens, 4096);
            words starts = allocate(tokens, 4096);
            words lengths = allocate(tokens, 4096);
            count = scanSemanticTokens(source, kinds, starts, lengths);
            drop(lengths);
            drop(starts);
            drop(kinds);
            drop(tokens);
          }
        }
        """);
    var program = new WheelerCompiler().compileModuleFiles(sources, "example.structured_source_tokens");
    byte[] input = CompilerSources.read(
        "compiler/closure/products/source/StructuredSourceModuleCompiler.w")
        .getBytes(StandardCharsets.UTF_8);
    var machine = new VirtualMachine(program, input);
    CompilerMachineRunner.runWithoutRewindHistory(machine);
    // The native scanner enforces capacity before discarding comments.
    assertTrue(0 < machine.global("count"), "structured compiler exceeds its native token arena");
  }
}
