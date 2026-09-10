package com.typeobject.wheeler.examples.fronts;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.compiler.CompilerException;
import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.BufferKind;
import com.typeobject.wheeler.core.vm.BufferValue;
import com.typeobject.wheeler.core.vm.MachineSnapshot;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.examples.CompilerSources;
import java.nio.charset.StandardCharsets;
import java.util.HashMap;
import java.util.List;
import java.util.TreeSet;
import java.util.stream.IntStream;
import java.util.stream.Stream;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.MethodSource;
import org.junit.jupiter.params.provider.ValueSource;

/** Checks source whitespace and line-comment termination against independent lexical acceptance. */
final class NativeSourceWhitespaceExampleTest {
  private static final int CAPACITY = 64;
  private static final long SENTINEL = 211;
  private static Program program;

  @BeforeAll
  static void compileDriver() throws Exception {
    var sources = new HashMap<>(CompilerSources.moduleClosure("wheeler.lexer.scanner"));
    sources.put("Whitespace.w", """
        module example.whitespace;
        import wheeler.lexer.scanner;
        classical class Whitespace {
          const long TOKENS = 64;
          const long COLUMNS = 3;
          const long WORD_BYTES = 8;
          const long ARENA_BYTES = TOKENS * COLUMNS * WORD_BYTES;
          state long prepared = 0;
          state long completed = 0;
          state long tokenCount = -1;
          entry void main(borrow utf8 source) {
            region arena = new region(ARENA_BYTES, COLUMNS);
            words kinds = allocate(arena, TOKENS);
            words starts = allocate(arena, TOKENS);
            words lengths = allocate(arena, TOKENS);
            long index = 0;
            while (index < TOKENS) limit TOKENS {
              set(kinds, index, 211);
              set(starts, index, 211);
              set(lengths, index, 211);
              index += 1;
            }
            prepared = 1;
            ScanResult result = scan(source, kinds, starts, lengths);
            match (result) {
              case ScanResult.Value(long count) { tokenCount = count; }
              case ScanResult.Error(ScanDiagnostic diagnostic) { assert(diagnostic.code == 0); }
            }
            completed = 1;
            drop(lengths);
            drop(starts);
            drop(kinds);
            drop(arena);
          }
        }
        """);
    program = new WheelerCompiler().compileModuleFiles(sources, "example.whitespace");
  }

  @ParameterizedTest
  @MethodSource("separators")
  void matchesWhitespaceAcceptanceAndPreservesByteCoordinates(int scalar) {
    String separator = Character.toString(scalar);
    boolean whitespace = Character.isWhitespace(scalar);
    String declaration = "classical" + separator + "class Empty { entry void main() {} }";
    if (whitespace) {
      new WheelerCompiler().compile(declaration);
    } else {
      assertThrows(CompilerException.class, () -> new WheelerCompiler().compile(declaration));
    }
    String source = "alpha" + separator + "beta";
    int prefix = bytes("alpha");
    int width = bytes(separator);
    check(source, whitespace
        ? new long[][] {{1, 0, prefix}, {1, prefix + width, bytes("beta")}}
        : new long[][] {{1, 0, prefix}, {3, prefix, width}, {1, prefix + width, bytes("beta")}});
  }

  @ParameterizedTest
  @ValueSource(strings = {"\n", "\r", "\r\n"})
  void terminatesLineCommentsWithoutConsumingTheFollowingMember(String ending) {
    String comment = "// café 𝄞 comment";
    String source = "alpha" + comment + ending + "beta";
    int prefix = bytes("alpha");
    check(source, new long[][] {{1, 0, prefix}, {4, prefix, bytes(comment)},
        {1, prefix + bytes(comment + ending), bytes("beta")}});
    new WheelerCompiler().compile("classical class Empty {" + comment + ending + "entry void main() {} }");
  }

  private static void check(String source, long[][] expected) {
    VirtualMachine machine = new VirtualMachine(program, source.getBytes(StandardCharsets.UTF_8));
    MachineSnapshot initial = machine.snapshot();
    while (machine.global("prepared") == 0) {
      machine.step();
    }
    MachineSnapshot prepared = machine.snapshot();
    while (machine.global("completed") == 0) {
      machine.step();
    }
    MachineSnapshot result = machine.snapshot();
    assertEquals(expected.length, machine.global("tokenCount"));
    assertEquals(prepared.regions(), result.regions());
    assertEquals(prepared.buffers().size(), result.buffers().size());
    assertEquals(prepared.buffers().getFirst(), result.buffers().getFirst());
    List<BufferValue> columns = result.buffers().stream().filter(buffer -> buffer.kind() == BufferKind.WORDS).toList();
    for (int column = 0; column < columns.size(); column++) {
      for (int row = 0; row < CAPACITY; row++) {
        assertEquals(row < expected.length ? expected[row][column] : SENTINEL,
            columns.get(column).elements().get(row));
      }
    }
    machine.run();
    MachineSnapshot terminal = machine.snapshot();
    while (machine.historySize() > 0) {
      machine.rewindOne();
    }
    assertEquals(initial, machine.snapshot());
    machine.run();
    assertEquals(terminal, machine.snapshot());
    while (machine.historySize() > 0) {
      machine.rewindOne();
    }
    assertEquals(initial, machine.snapshot());
  }

  static Stream<Integer> separators() {
    TreeSet<Integer> values = new TreeSet<>();
    IntStream.rangeClosed(0, Character.MAX_CODE_POINT).filter(Character::isWhitespace).forEach(scalar -> {
      values.add(scalar);
      values.add(scalar - 1);
      values.add(scalar + 1);
    });
    values.addAll(List.of(0x85, 0xa0, 0x200b, 0x202f, 0x2060, 0xfeff));
    return values.stream();
  }

  private static int bytes(String value) {
    return value.getBytes(StandardCharsets.UTF_8).length;
  }
}
