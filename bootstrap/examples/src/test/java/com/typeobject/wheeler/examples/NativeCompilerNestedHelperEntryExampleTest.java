package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeReader;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Differential evidence for nested native scalar helpers called from an entry. */
final class NativeCompilerNestedHelperEntryExampleTest {
  @Test
  void compilesNestedScalarHelpersIntoEntryByteForByte() throws Exception {
    String arities = """
        module example.arities;
        classical class Arities {
          public long arity(long opcode) {
            if (opcode == 933) { return 7; }
            return -1;
          }
        }
        """;
    String widths = """
        module example.widths;
        import example.arities;
        classical class Widths {
          public long codeWidth(long opcode) {
            long arity = arity(opcode);
            if (arity < 0) { return -1; }
            long arguments = arity * 48;
            return arguments + 64;
          }
        }
        """;
    String root = """
        module example.entry;
        import example.widths;
        classical class Entry {
          entry void main() {
            long width = codeWidth(933);
            assert(width == 400);
          }
        }
        """;
    Program compiler = NativeModuleCompilerHarness.program();
    byte[] artifact = NativeModuleCompilerHarness.compile(
        compiler, List.of(arities, widths), root);
    byte[] expected = new BytecodeWriter().write(new WheelerCompiler().compileModuleFiles(
        Map.of("Arities.w", arities, "Widths.w", widths, "Entry.w", root),
        "example.entry"));
    assertArrayEquals(expected, artifact);
    new VirtualMachine(new BytecodeReader().read(artifact)).run();

    NativeModuleCompilerHarness.assertTrap(
        compiler,
        List.of(arities, widths),
        root.replace("codeWidth(933)", "missingWidth(933)"));
    NativeModuleCompilerHarness.assertTrap(
        compiler,
        List.of(arities, widths),
        root.replace("codeWidth(933)", "arity(933)"));
  }
}
