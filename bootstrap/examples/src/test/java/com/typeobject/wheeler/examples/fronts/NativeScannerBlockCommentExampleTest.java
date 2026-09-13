package com.typeobject.wheeler.examples.fronts;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.BufferValue;
import com.typeobject.wheeler.core.vm.MachineStatus;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.examples.CompilerSources;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.regex.Pattern;
import org.junit.jupiter.api.Test;

/** Checks comment byte extents, full-window progress, diagnostics, and actual rewind. */
final class NativeScannerBlockCommentExampleTest {
  private static final int TOKEN_CAPACITY = 4;
  private static final int TOKEN_COLUMNS = 3;
  private static final int REPORT_COLUMNS = 5;
  private static final long SENTINEL = 211;

  @Test
  void scansAcrossTheFormerIterationBoundaryAndReplaysUtf8Coordinates() throws Exception {
    Program program = program();
    String prefix = "head \r\n";
    for (String body : List.of("x".repeat(255), "x".repeat(256), "\ud834\udd1e".repeat(256), "not /* nested")) {
      String comment = "/*" + body + "*/";
      int commentStart = byteLength(prefix);
      int commentLength = byteLength(comment);
      check(program, prefix + comment + " tail", List.of(1L, 5L, 1L),
          List.of(0L, (long) commentStart, (long) commentStart + commentLength + 1),
          List.of(4L, (long) commentLength, 4L), List.of(1L, 3L, SENTINEL, SENTINEL, SENTINEL), true);
    }
  }

  @Test
  void scansAndDiagnosesTheFullDeclaredInputWindowWithoutHistory() throws Exception {
    int sourceLimit = sourceByteLimit();
    Program program = program();
    String opener = "/*";
    String closer = "*/";
    String complete = opener + "x".repeat(sourceLimit - byteLength(opener + closer)) + closer;
    check(program, complete, List.of(5L), List.of(0L), List.of((long) sourceLimit),
        List.of(1L, 1L, SENTINEL, SENTINEL, SENTINEL), false);
    String incomplete = opener + "x".repeat(sourceLimit - byteLength(opener));
    check(program, incomplete, List.of(5L), List.of(0L), List.of(SENTINEL), List.of(0L, 1L, 0L, 1L, 1L), false);
  }

  @Test
  void reportsTheOpeningByteAndLineWithoutInventingATerminator() throws Exception {
    String prefix = "head \r\n";
    check(program(), prefix + "/*" + "\ud834\udd1e".repeat(256), List.of(1L, 5L), List.of(0L, (long) byteLength(prefix)),
        List.of(4L, SENTINEL), List.of(0L, 1L, (long) byteLength(prefix), 2L, 1L), true);
  }

  private static void check(Program program, String source, List<Long> kinds, List<Long> starts, List<Long> lengths,
      List<Long> report, boolean replay) {
    var machine = new VirtualMachine(program, source.getBytes(StandardCharsets.UTF_8));
    var initial = machine.snapshot();
    while (machine.global("phase") == 0) machine.stepWithoutRewindHistory();
    var prepared = machine.snapshot();
    while (machine.global("phase") != 2) {
      if (replay) machine.step(); else machine.stepWithoutRewindHistory();
    }
    var published = machine.snapshot();
    assertEquals(initial.buffers().getFirst(), published.buffers().getFirst());
    assertEquals(prepared.buffers().size(), published.buffers().size());
    assertEquals(prepared.regions(), published.regions());
    assertEquals(padded(kinds), published.buffers().get(1).elements());
    assertEquals(padded(starts), published.buffers().get(2).elements());
    assertEquals(padded(lengths), published.buffers().get(3).elements());
    assertEquals(report, published.buffers().get(4).elements());
    long reserved = (TOKEN_CAPACITY * TOKEN_COLUMNS + REPORT_COLUMNS) * Long.BYTES;
    assertEquals(reserved, published.regions().getLast().maxBytes());
    assertEquals(reserved, published.regions().getLast().usedBytes());
    while (machine.status() != MachineStatus.HALTED) {
      if (replay) machine.step(); else machine.stepWithoutRewindHistory();
    }
    var halted = machine.snapshot();
    assertTrue(halted.buffers().stream().skip(initial.buffers().size()).allMatch(BufferValue::dropped));
    if (replay) {
      while (machine.historySize() > 0) machine.rewindOne();
      assertEquals(prepared, machine.snapshot());
      while (machine.status() != MachineStatus.HALTED) machine.step();
      assertEquals(halted, machine.snapshot());
    } else {
      assertEquals(0, machine.historySize());
    }
  }

  private static List<Long> padded(List<Long> values) {
    var result = new ArrayList<>(values);
    while (result.size() < TOKEN_CAPACITY) result.add(SENTINEL);
    return result;
  }

  private static int byteLength(String source) {
    return source.getBytes(StandardCharsets.UTF_8).length;
  }

  private static int sourceByteLimit() throws Exception {
    // Read the declared input contract, not the implementation's loop instruction.
    String scanner = CompilerSources.moduleClosure("wheeler.lexer.scanner").values().iterator().next();
    var limit = Pattern.compile("MAX_SCANNER_INPUT_BYTES = ([0-9]+);").matcher(scanner);
    assertTrue(limit.find());
    int value = Integer.parseInt(limit.group(1));
    assertFalse(limit.find());
    return value;
  }

  private static Program program() throws Exception {
    var sources = new LinkedHashMap<>(CompilerSources.moduleClosure("wheeler.lexer.scanner"));
    sources.put("Comments.w", """
        module example.scanner_comments;
        import wheeler.lexer.scanner;
        classical class Comments {
          const long TOKEN_CAPACITY = %d;
          const long TOKEN_COLUMNS = %d;
          const long REPORT_COLUMNS = %d;
          const long WORD_BYTES = %d;
          const long ARENA_WORDS = TOKEN_CAPACITY * TOKEN_COLUMNS + REPORT_COLUMNS;
          const long ARENA_BYTES = ARENA_WORDS * WORD_BYTES;
          const long ARENA_BUFFERS = TOKEN_COLUMNS + 1;
          const long SENTINEL = %d;
          state long phase = 0;
          entry void main(borrow utf8 input) {
            region arena = new region(ARENA_BYTES, ARENA_BUFFERS);
            words kinds = allocate(arena, TOKEN_CAPACITY);
            words starts = allocate(arena, TOKEN_CAPACITY);
            words lengths = allocate(arena, TOKEN_CAPACITY);
            words report = allocate(arena, REPORT_COLUMNS);
            long token = 0;
            while (token < TOKEN_CAPACITY) limit TOKEN_CAPACITY {
              set(kinds, token, SENTINEL); set(starts, token, SENTINEL); set(lengths, token, SENTINEL);
              token += 1;
            }
            long field = 0;
            while (field < REPORT_COLUMNS) limit REPORT_COLUMNS { set(report, field, SENTINEL); field += 1; }
            phase = 1;
            ScanResult result = scan(input, kinds, starts, lengths);
            match (result) {
              case ScanResult.Value(long count) { set(report, 0, 1); set(report, 1, count); }
              case ScanResult.Error(ScanDiagnostic diagnostic) {
                set(report, 0, 0); set(report, 1, diagnostic.code); set(report, 2, diagnostic.offset);
                set(report, 3, diagnostic.line); set(report, 4, diagnostic.column);
              }
            }
            phase = 2;
            drop(report); drop(lengths); drop(starts); drop(kinds); drop(arena);
          }
        }
        """.formatted(TOKEN_CAPACITY, TOKEN_COLUMNS, REPORT_COLUMNS, Long.BYTES, SENTINEL));
    return new WheelerCompiler().compileModuleFiles(sources, "example.scanner_comments");
  }
}
