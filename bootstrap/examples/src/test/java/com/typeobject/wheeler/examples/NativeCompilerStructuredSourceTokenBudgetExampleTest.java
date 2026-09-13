package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.nio.charset.StandardCharsets;
import java.util.LinkedHashMap;
import org.junit.jupiter.api.Test;

/** Checks physical source orchestrators before paying for a complete archive pass. */
final class NativeCompilerStructuredSourceTokenBudgetExampleTest {
  @Test
  void keepsTheStructuredCompilerWithinTheNativeTokenArena() throws Exception {
    checkOwner("StructuredSourceModuleCompiler.w");
  }

  @Test
  void keepsTheAggregateCompilerWithinTheNativeTokenArena() throws Exception {
    checkOwner("AggregateCompiledCallableBodies.w");
  }

  private static void checkOwner(String owner) throws Exception {
    var sources = new LinkedHashMap<>(CompilerSources.moduleClosure("wheeler.compiler.module_linker"));
    sources.put("StructuredSourceTokens.w", """
        module example.structured_source_tokens;

        import wheeler.compiler.compiler_token_limits;
        import wheeler.compiler.module_linker;

        classical class StructuredSourceTokens {
          const long TOKEN_COLUMNS = 3;
          const long WORD_BYTES = 8;
          const long TOKEN_BYTES = MAX_COMPILER_TOKENS * TOKEN_COLUMNS * WORD_BYTES;
          state long count = -1;

          entry void main(borrow utf8 source) {
            region tokens = new region(TOKEN_BYTES, TOKEN_COLUMNS);
            words kinds = allocate(tokens, MAX_COMPILER_TOKENS);
            words starts = allocate(tokens, MAX_COMPILER_TOKENS);
            words lengths = allocate(tokens, MAX_COMPILER_TOKENS);
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
        "compiler/closure/products/source/" + owner).getBytes(StandardCharsets.UTF_8);
    int sourceBytes = 32_768;
    assertTrue(input.length <= sourceBytes, owner + " exceeds its native source window");
    var machine = new VirtualMachine(program, input);
    CompilerMachineRunner.runWithoutRewindHistory(machine);
    // The native scanner enforces capacity before discarding comments.
    assertTrue(0 < machine.global("count"), owner + " exceeds its native token arena");
  }
}
