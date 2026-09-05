package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.compiler.CompilerException;
import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import java.nio.charset.StandardCharsets;
import java.util.List;
import org.junit.jupiter.api.Test;

/** The recovery compiler must not publish artifacts for source-word aliases. */
final class NativeCompilerSourceKeywordRejectionExampleTest {
  private static final int OUTPUT_BYTES = 32768;
  private static final String BOOLEAN = """
      classical class BooleanWord {
        public const boolean READY = true;
        entry void main() {
          boolean value = READY;
          assert(value);
        }
      }
      """;
  private static final String ROTATE = """
      classical class RotateWord {
        public const long VALUE = rotateRight32(16, 1);
        entry void main() {
          long value = VALUE;
          assert(value == 8);
        }
      }
      """;

  @Test
  void rejectsLiteralTypeAndIntrinsicAliasesBeforePublicationAndRewinds() throws Exception {
    Program compiler = CompilerSources.minimalCompilerProgram();
    assertParity(compiler, BOOLEAN);
    assertParity(compiler, ROTATE);
    for (String word : List.of("classical", "class", "public", "const", "boolean", "true",
        "entry", "void", "assert")) {
      String alias = alias(word);
      assertEquals(word.hashCode(), alias.hashCode());
      assertRejected(compiler, BOOLEAN.replaceAll("\\b" + word + "\\b", alias));
    }
    assertRejected(compiler, ROTATE.replace("long", alias("long")));
    for (String alias : List.of("rotauFRight32", "rotateRigiU32")) {
      assertRejected(compiler, ROTATE.replace("rotateRight32", alias));
    }
    String falseLiteral = BOOLEAN.replace("= true", "= false").replace("assert(value)", "assert(true)");
    assertParity(compiler, falseLiteral);
    assertRejected(compiler, falseLiteral.replace("false", alias("false")));
  }

  private static void assertParity(Program compiler, String source) {
    var writer = new VirtualMachine(compiler, source.getBytes(StandardCharsets.UTF_8), OUTPUT_BYTES);
    CompilerMachineRunner.runWithoutRewindHistory(writer);
    assertArrayEquals(new WheelerCompiler().compileToBytecode(source), writer.hostOutput());
  }

  private static void assertRejected(Program compiler, String source) {
    assertThrows(CompilerException.class, () -> new WheelerCompiler().compileToBytecode(source));
    var writer = new VirtualMachine(compiler, source.getBytes(StandardCharsets.UTF_8), OUTPUT_BYTES);
    var initial = writer.snapshot();
    assertThrows(VmTrap.class, writer::run, source);
    assertArrayEquals(new byte[OUTPUT_BYTES], writer.hostOutput());
    while (writer.historySize() > 0) {
      writer.rewindOne();
    }
    assertEquals(initial, writer.snapshot());
  }

  private static String alias(String word) {
    char[] alias = word.toCharArray();
    alias[alias.length - 2]++;
    alias[alias.length - 1] -= 31;
    return new String(alias);
  }
}
