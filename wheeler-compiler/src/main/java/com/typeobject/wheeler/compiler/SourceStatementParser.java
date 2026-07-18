package com.typeobject.wheeler.compiler;

import com.typeobject.wheeler.compiler.SourceModel.Circuit;
import com.typeobject.wheeler.compiler.SourceModel.Statement;
import com.typeobject.wheeler.compiler.SourceToken.Type;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;

/** Parser support for intrinsic statements, quantum circuits, and numeric literals. */
abstract class SourceStatementParser extends SourceTokenCursor {
  protected final Statement parseStatement() {
    SourceToken start = expect(Type.IDENTIFIER, "statement");
    if (start.text().equals("assert")) {
      String state = expect(Type.IDENTIFIER, "state after assert").text();
      expect(Type.EQUAL, "'==' in assertion");
      String value = signedNumber();
      expect(Type.SEMICOLON, "';' after assertion");
      return statement("expect", start.line(), state, value);
    }

    if (match(Type.PLUS_ASSIGN, Type.MINUS_ASSIGN, Type.XOR_ASSIGN, Type.ASSIGN)) {
      Type operator = previous().type();
      if (operator == Type.ASSIGN && matchText("measure")) {
        expect(Type.LEFT_PAREN, "'(' after measure");
        String register = expect(Type.IDENTIFIER, "register to measure").text();
        expect(Type.RIGHT_PAREN, "')' after measurement register");
        expect(Type.SEMICOLON, "';' after measurement");
        return statement("measure", start.line(), register, start.text());
      }
      String value = signedNumber();
      expect(Type.SEMICOLON, "';' after assignment");
      String operation = switch (operator) {
        case PLUS_ASSIGN -> "add";
        case MINUS_ASSIGN -> "sub";
        case XOR_ASSIGN -> "xor";
        case ASSIGN -> "set";
        default -> throw new AssertionError("unhandled assignment");
      };
      return statement(operation, start.line(), start.text(), value);
    }

    expect(Type.LEFT_PAREN, "'(' after method name");
    if (start.text().equals("prepare")) {
      String register = expect(Type.IDENTIFIER, "register to prepare").text();
      expect(Type.COMMA, "',' after preparation register");
      String basis = signedNumber();
      expect(Type.RIGHT_PAREN, "')' after preparation");
      expect(Type.SEMICOLON, "';' after preparation");
      return statement("prepare", start.line(), register, basis);
    }
    expect(Type.RIGHT_PAREN, "zero-argument method call");
    expect(Type.SEMICOLON, "';' after method call");
    if (start.text().equals("checkpoint") || start.text().equals("commit")) {
      return statement(start.text(), start.line());
    }
    return statement("invoke", start.line(), start.text());
  }

  protected final Circuit parseCircuit(String name, int line) {
    List<Statement> body = new ArrayList<>();
    String register = null;
    while (!check(Type.RIGHT_BRACE) && !check(Type.END)) {
      SourceToken operation = expect(Type.IDENTIFIER, "gate or qreg reference");
      if (match(Type.DOT)) {
        expectText("apply");
        expect(Type.LEFT_PAREN, "'(' after apply");
        String function = expect(Type.IDENTIFIER, "coherent method reference").text();
        expect(Type.RIGHT_PAREN, "')' after coherent method reference");
        expect(Type.SEMICOLON, "';' after coherent application");
        register = sameRegister(register, operation.text(), operation);
        body.add(statement("lift", operation.line(), function));
        continue;
      }

      String gate = operation.text().toLowerCase(Locale.ROOT);
      expect(Type.LEFT_PAREN, "'(' after gate name");
      QubitReference first = qubitReference();
      register = sameRegister(register, first.register(), operation);
      List<String> arguments = new ArrayList<>();
      arguments.add(Integer.toString(first.index()));
      int arity = switch (gate) {
        case "h", "x", "z", "phase" -> 1;
        case "cphase", "cnot", "cz", "swap" -> 2;
        default -> throw new CompilerException(operation.line(), "unknown gate: " + operation.text());
      };
      if (arity == 2) {
        expect(Type.COMMA, "',' between gate qubits");
        QubitReference second = qubitReference();
        register = sameRegister(register, second.register(), operation);
        arguments.add(Integer.toString(second.index()));
      }
      if (gate.equals("phase") || gate.equals("cphase")) {
        expect(Type.COMMA, "',' before gate angle");
        arguments.add(signedNumber());
      }
      expect(Type.RIGHT_PAREN, "')' after gate arguments");
      expect(Type.SEMICOLON, "';' after gate");
      body.add(new Statement(gate.equals("swap") ? "qswap" : gate, arguments, operation.line()));
    }
    expect(Type.RIGHT_BRACE, "'}' after unitary method");
    if (register == null) {
      fail(peek(), "unitary method must operate on a qreg");
    }
    return new Circuit(name, register, body, line);
  }

  private QubitReference qubitReference() {
    SourceToken register = expect(Type.IDENTIFIER, "quantum register");
    expect(Type.LEFT_BRACKET, "'[' after quantum register");
    long index = parseInteger(signedNumber(), register.line());
    if (index < 0 || index > Integer.MAX_VALUE) {
      fail(register, "invalid qubit index");
    }
    expect(Type.RIGHT_BRACKET, "']' after qubit index");
    return new QubitReference(register.text(), (int) index);
  }

  private static String sameRegister(String currentRegister, String next, SourceToken source) {
    if (currentRegister != null && !currentRegister.equals(next)) {
      throw new CompilerException(
          source.line(), "one unitary method cannot mix registers in the first profile");
    }
    return next;
  }

  protected final void emptyArguments() {
    expect(Type.LEFT_PAREN, "'(' after method name");
    expect(Type.RIGHT_PAREN, "zero-argument method call");
  }

  protected final String signedNumber() {
    String sign = match(Type.MINUS) ? "-" : "";
    return sign + expect(Type.NUMBER, "numeric literal").text();
  }

  static long parseInteger(String text, int line) {
    try {
      boolean negative = text.startsWith("-");
      String magnitude = negative ? text.substring(1) : text;
      int radix = 10;
      if (magnitude.startsWith("0x")) {
        radix = 16;
        magnitude = magnitude.substring(2);
      } else if (magnitude.startsWith("0b")) {
        radix = 2;
        magnitude = magnitude.substring(2);
      }
      long value = Long.parseLong(magnitude.replace("_", ""), radix);
      return negative ? Math.negateExact(value) : value;
    } catch (ArithmeticException | NumberFormatException exception) {
      throw new CompilerException(line, "invalid 64-bit integer: " + text);
    }
  }

  static double parseAngle(String text, int line) {
    try {
      double value = Double.parseDouble(text);
      if (!Double.isFinite(value)) {
        throw new CompilerException(line, "angle must be finite");
      }
      return value;
    } catch (NumberFormatException exception) {
      throw new CompilerException(line, "invalid angle: " + text);
    }
  }

  protected static Statement statement(String operation, int line, String... arguments) {
    return new Statement(operation, List.of(arguments), line);
  }

  private record QubitReference(String register, int index) {}
}
