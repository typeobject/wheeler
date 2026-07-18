package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.vm.MachineStatus;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Map;
import org.junit.jupiter.api.Test;

class Utf8LexerExampleTest {
  @Test
  void scannerParsesSignedMaximumAndReportsDecimalOverflow() throws Exception {
    String rootSource = """
        module examples.lexer.test;
        import examples.lexer.scanner;
        classical class ScannerTest {
          state long parsed = 0;
          entry void main(utf8 source) {
            parsed = parseNumber(source, 0, bufferLength(source));
          }
        }
        """;
    String scanner = Files.readString(
        Path.of("src/main/wheeler/lexer/Scanner.w"));
    var program = new WheelerCompiler().compileModuleFiles(
        Map.of("Scanner.w", scanner, "ScannerTest.w", rootSource),
        "examples.lexer.test");
    VirtualMachine maximum = new VirtualMachine(
        program, "9223372036854775807".getBytes(StandardCharsets.UTF_8));
    VirtualMachine overflow = new VirtualMachine(
        program, "9223372036854775808".getBytes(StandardCharsets.UTF_8));

    maximum.run();
    overflow.run();

    assertEquals(Long.MAX_VALUE, maximum.global("parsed"));
    assertEquals(-1, overflow.global("parsed"));
  }

  @Test
  void scannerReportsUnterminatedBlockCommentsWithoutReadingPastInput() throws Exception {
    String rootSource = """
        module examples.lexer.blocktest;
        import examples.lexer.scanner;
        classical class BlockTest {
          state long commentEnd = 0;
          entry void main(utf8 source) {
            commentEnd = blockCommentEnd(source, 0, bufferLength(source));
          }
        }
        """;
    String scanner = Files.readString(Path.of("src/main/wheeler/lexer/Scanner.w"));
    var program = new WheelerCompiler().compileModuleFiles(
        Map.of("Scanner.w", scanner, "BlockTest.w", rootSource),
        "examples.lexer.blocktest");
    VirtualMachine closed = new VirtualMachine(
        program, "/*ok*/".getBytes(StandardCharsets.UTF_8));
    VirtualMachine open = new VirtualMachine(
        program, "/*open".getBytes(StandardCharsets.UTF_8));

    closed.run();
    open.run();

    assertEquals(6, closed.global("commentEnd"));
    assertEquals(-1, open.global("commentEnd"));
  }

  @Test
  void scannerAcceptsOnlyClosedPrintableRawAsciiLiterals() throws Exception {
    String rootSource = """
        module examples.lexer.literaltest;
        import examples.lexer.scanner;
        classical class LiteralTest {
          state long literalEnd = 0;
          entry void main(utf8 source) {
            literalEnd = asciiLiteralEnd(source, 0, bufferLength(source));
          }
        }
        """;
    String scanner = Files.readString(Path.of("src/main/wheeler/lexer/Scanner.w"));
    var program = new WheelerCompiler().compileModuleFiles(
        Map.of("Scanner.w", scanner, "LiteralTest.w", rootSource),
        "examples.lexer.literaltest");
    VirtualMachine closed = new VirtualMachine(
        program, "\"abc\"".getBytes(StandardCharsets.UTF_8));
    VirtualMachine open = new VirtualMachine(
        program, "\"abc".getBytes(StandardCharsets.UTF_8));
    VirtualMachine nonAscii = new VirtualMachine(
        program, "\"caf\u00e9\"".getBytes(StandardCharsets.UTF_8));

    closed.run();
    open.run();
    nonAscii.run();

    assertEquals(5, closed.global("literalEnd"));
    assertEquals(-1, open.global("literalEnd"));
    assertEquals(-1, nonAscii.global("literalEnd"));
  }

  @Test
  void scannerReturnsStableDiagnosticCodesAndOffsets() throws Exception {
    String rootSource = """
        module examples.lexer.diagnostictest;
        import examples.lexer.scanner;
        classical class DiagnosticTest {
          state long code = 0;
          state long offset = 0;
          entry void main(utf8 source) {
            region arena = new region(96, 3);
            words kinds = allocate(arena, 4);
            words starts = allocate(arena, 4);
            words lengths = allocate(arena, 4);
            ScanResult result = scan(source, kinds, starts, lengths);
            match (result) {
              case ScanResult.Value(long count) { offset = count; }
              case ScanResult.Error(long errorCode, long errorOffset) {
                code = errorCode;
                offset = errorOffset;
              }
            }
            drop(lengths);
            drop(starts);
            drop(kinds);
            drop(arena);
          }
        }
        """;
    String scanner = Files.readString(Path.of("src/main/wheeler/lexer/Scanner.w"));
    var program = new WheelerCompiler().compileModuleFiles(
        Map.of("Scanner.w", scanner, "DiagnosticTest.w", rootSource),
        "examples.lexer.diagnostictest");
    VirtualMachine comment = new VirtualMachine(
        program, "x /*".getBytes(StandardCharsets.UTF_8));
    VirtualMachine literal = new VirtualMachine(
        program, "\"open".getBytes(StandardCharsets.UTF_8));
    VirtualMachine capacity = new VirtualMachine(
        program, "a b c d e".getBytes(StandardCharsets.UTF_8));

    comment.run();
    literal.run();
    capacity.run();

    assertEquals(1, comment.global("code"));
    assertEquals(2, comment.global("offset"));
    assertEquals(2, literal.global("code"));
    assertEquals(0, literal.global("offset"));
    assertEquals(3, capacity.global("code"));
    assertEquals(8, capacity.global("offset"));
  }

  @Test
  void explicitSourceInputIsTokenizedParsedAndExactlyRewound() throws Exception {
    Path root = Path.of("src/main/wheeler");
    var program = new WheelerCompiler().compileModuleFiles(
        Map.of(
            "src/main/wheeler/Utf8Lexer.w",
            Files.readString(root.resolve("Utf8Lexer.w")),
            "src/main/wheeler/lexer/Parser.w",
            Files.readString(root.resolve("lexer/Parser.w")),
            "src/main/wheeler/lexer/Scanner.w",
            Files.readString(root.resolve("lexer/Scanner.w"))),
        "examples.lexer.main");
    VirtualMachine machine = new VirtualMachine(
        program, "long x2=123;/*c*/".getBytes(StandardCharsets.UTF_8), 3);
    var initial = machine.snapshot();

    machine.run();

    assertEquals(MachineStatus.HALTED, machine.status());
    assertEquals(6, machine.global("tokenCount"));
    assertEquals(8, machine.global("numberStart"));
    assertEquals(12, machine.global("commentStart"));
    assertEquals(123, machine.global("numericValue"));
    assertEquals(0, machine.global("parseError"));
    assertEquals(0, machine.global("lexicalCode"));
    assertEquals(0, machine.global("lexicalError"));
    assertEquals(3, machine.global("outputLength"));
    assertEquals("123", new String(machine.hostOutput(), StandardCharsets.UTF_8));
    assertEquals(17, machine.global("finalCursor"));
    while (machine.historySize() > 0) {
      machine.rewindOne();
    }
    assertEquals(initial, machine.snapshot());
  }
}
