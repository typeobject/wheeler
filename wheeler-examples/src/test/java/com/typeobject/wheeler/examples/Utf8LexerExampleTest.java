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
        program, "x=123;/*c*/".getBytes(StandardCharsets.UTF_8), 3);
    var initial = machine.snapshot();

    machine.run();

    assertEquals(MachineStatus.HALTED, machine.status());
    assertEquals(5, machine.global("tokenCount"));
    assertEquals(2, machine.global("numberStart"));
    assertEquals(6, machine.global("commentStart"));
    assertEquals(123, machine.global("numericValue"));
    assertEquals(0, machine.global("parseError"));
    assertEquals(0, machine.global("lexicalError"));
    assertEquals(3, machine.global("outputLength"));
    assertEquals("123", new String(machine.hostOutput(), StandardCharsets.UTF_8));
    assertEquals(11, machine.global("finalCursor"));
    while (machine.historySize() > 0) {
      machine.rewindOne();
    }
    assertEquals(initial, machine.snapshot());
  }
}
