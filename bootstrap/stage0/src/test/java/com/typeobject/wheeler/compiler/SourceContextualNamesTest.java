package com.typeobject.wheeler.compiler;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.vm.MachineStatus;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.nio.file.Files;
import java.nio.file.Path;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;

/** Editor fixtures retain the compiler's contextual names and inverse boundaries. */
final class SourceContextualNamesTest {
  @ParameterizedTest
  @ValueSource(strings = {
      "Reverse names and inverse calls",
      "Reverse nominal type and binding"
  })
  void executesAndRewindsTheEditorNameFixtures(String title) throws Exception {
    String source = corpusSource(title);
    var compiler = new WheelerCompiler();
    var program = compiler.compile(source);
    var formatted = compiler.compile(SourceFormatter.format(source));
    var writer = new BytecodeWriter();
    assertArrayEquals(writer.write(program), writer.write(formatted));

    var machine = new VirtualMachine(program);
    var initial = machine.snapshot();
    machine.run();
    assertEquals(MachineStatus.HALTED, machine.status());
    while (machine.historySize() > 0) {
      machine.rewindOne();
    }
    assertEquals(initial, machine.snapshot());
  }

  private static String corpusSource(String title) throws Exception {
    String corpus = Files.readString(Path.of(
        "../tree-sitter-wheeler/test/corpus/contextual_names.txt"));
    String header = "==================\n" + title + "\n==================\n";
    int start = corpus.indexOf(header);
    assertTrue(start >= 0, title);
    assertEquals(start, corpus.lastIndexOf(header), title);
    start += header.length();
    int end = corpus.indexOf("\n---\n", start);
    assertTrue(end > start, title);
    return corpus.substring(start, end);
  }
}
