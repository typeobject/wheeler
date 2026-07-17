package com.typeobject.wheeler.compiler;

import com.typeobject.wheeler.compiler.SourceModel.Circuit;
import com.typeobject.wheeler.compiler.SourceModel.Function;
import com.typeobject.wheeler.compiler.SourceModel.QuantumRegisterSource;
import com.typeobject.wheeler.compiler.SourceModel.SourceProgram;
import com.typeobject.wheeler.compiler.SourceModel.State;
import com.typeobject.wheeler.compiler.SourceModel.Statement;
import com.typeobject.wheeler.compiler.SourceToken.Type;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.Set;

/** Recursive-descent parser for Wheeler's formatting-independent source profile. */
final class SourceParser {
  private static final Set<String> DOMAINS = Set.of("classical", "quantum", "hybrid");
  private static final Set<String> VISIBILITY = Set.of("public", "private", "protected");

  private List<SourceToken> tokens;
  private int current;
  private final List<State> states = new ArrayList<>();
  private final List<Function> functions = new ArrayList<>();
  private final List<QuantumRegisterSource> registers = new ArrayList<>();
  private final List<Circuit> circuits = new ArrayList<>();

  SourceProgram parse(String source) {
    tokens = new SourceLexer(source).lex();
    current = 0;
    states.clear();
    functions.clear();
    registers.clear();
    circuits.clear();

    SourceToken domain = expect(Type.IDENTIFIER, "computation domain");
    if (!DOMAINS.contains(domain.text())) {
      fail(domain, "expected classical, quantum, or hybrid");
    }
    expectText("class");
    String name = expect(Type.IDENTIFIER, "class name").text();
    expect(Type.LEFT_BRACE, "'{' after class name");
    while (!check(Type.RIGHT_BRACE) && !check(Type.END)) {
      parseMember();
    }
    expect(Type.RIGHT_BRACE, "'}' after class body");
    expect(Type.END, "end of file");

    if (functions.stream().filter(Function::entry).count() != 1) {
      fail(domain, "exactly one 'entry void main()' method is required");
    }
    return new SourceProgram(
        name, domain.text(), states, functions, registers, circuits);
  }

  private void parseMember() {
    while (checkTextIn(VISIBILITY)) {
      advance();
    }
    if (matchText("state")) {
      parseState(previous());
      return;
    }
    if (matchText("qreg")) {
      parseQuantumRegister(previous());
      return;
    }
    parseMethod();
  }

  private void parseState(SourceToken start) {
    expectText("long");
    String name = expect(Type.IDENTIFIER, "state name").text();
    expect(Type.ASSIGN, "'=' in state declaration");
    long value = parseInteger(signedNumber(), start.line());
    expect(Type.SEMICOLON, "';' after state declaration");
    states.add(new State(name, value, start.line()));
  }

  private void parseQuantumRegister(SourceToken start) {
    String name = expect(Type.IDENTIFIER, "quantum register name").text();
    expect(Type.ASSIGN, "'=' in qreg declaration");
    expectText("new");
    expectText("qreg");
    expect(Type.LEFT_PAREN, "'(' after new qreg");
    long qubits = parseInteger(signedNumber(), start.line());
    if (qubits <= 0 || qubits > 62) {
      fail(start, "qreg size must be between 1 and 62");
    }
    expect(Type.RIGHT_PAREN, "')' after qreg size");
    expect(Type.SEMICOLON, "';' after qreg declaration");
    registers.add(new QuantumRegisterSource(name, (int) qubits, start.line()));
  }

  private void parseMethod() {
    boolean coherent = false;
    boolean reversible = false;
    boolean unitary = false;
    boolean entry = false;
    SourceToken start = peek();

    while (!checkText("void") && !check(Type.END)) {
      String modifier = expect(Type.IDENTIFIER, "method modifier or void").text();
      switch (modifier) {
        case "static" -> { /* Accepted for Java familiarity; entry remains statically owned. */ }
        case "coherent" -> coherent = true;
        case "rev" -> reversible = true;
        case "unitary" -> unitary = true;
        case "entry" -> entry = true;
        default -> fail(previous(), "unsupported method modifier: " + modifier);
      }
    }
    expectText("void");
    String name = expect(Type.IDENTIFIER, "method name").text();
    expect(Type.LEFT_PAREN, "'(' after method name");
    expect(Type.RIGHT_PAREN, "zero-argument method profile");
    expect(Type.LEFT_BRACE, "'{' before method body");

    if (coherent && !reversible) {
      fail(start, "coherent methods must also be rev");
    }
    int semanticModifiers = (reversible ? 1 : 0) + (unitary ? 1 : 0) + (entry ? 1 : 0);
    if (semanticModifiers > 1) {
      fail(start, "rev, unitary, and entry are mutually exclusive method kinds");
    }
    if (entry && !name.equals("main")) {
      fail(start, "entry method must be named main");
    }

    if (unitary) {
      circuits.add(parseCircuit(name, start.line()));
    } else {
      functions.add(parseFunction(name, entry, reversible, coherent, start.line()));
    }
  }

  private Function parseFunction(
      String name, boolean entry, boolean reversible, boolean coherent, int line) {
    List<Statement> body = new ArrayList<>();
    while (!check(Type.RIGHT_BRACE) && !check(Type.END)) {
      if (matchText("reverse")) {
        SourceToken reverse = previous();
        if (match(Type.LEFT_BRACE)) {
          List<Statement> calls = new ArrayList<>();
          while (!check(Type.RIGHT_BRACE) && !check(Type.END)) {
            Statement call = parseStatement();
            if (!call.operation().equals("invoke")) {
              fail(reverse, "reverse blocks currently contain method calls only");
            }
            calls.add(call);
          }
          expect(Type.RIGHT_BRACE, "'}' after reverse block");
          for (int i = calls.size() - 1; i >= 0; i--) {
            Statement call = calls.get(i);
            body.add(statement("reverse", call.line(), call.arguments().getFirst()));
          }
        } else {
          SourceToken target = expect(Type.IDENTIFIER, "method name after reverse");
          emptyArguments();
          expect(Type.SEMICOLON, "';' after reverse call");
          body.add(statement("reverse", reverse.line(), target.text()));
        }
      } else {
        body.add(parseStatement());
      }
    }
    expect(Type.RIGHT_BRACE, "'}' after method body");
    if (entry) {
      body.add(statement("halt", line));
    }
    return new Function(name, entry, reversible, coherent, body, line);
  }

  private Statement parseStatement() {
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

  private Circuit parseCircuit(String name, int line) {
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

  private void emptyArguments() {
    expect(Type.LEFT_PAREN, "'(' after method name");
    expect(Type.RIGHT_PAREN, "zero-argument method call");
  }

  private String signedNumber() {
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

  private static Statement statement(String operation, int line, String... arguments) {
    return new Statement(operation, List.of(arguments), line);
  }

  private boolean matchText(String text) {
    if (!checkText(text)) {
      return false;
    }
    advance();
    return true;
  }

  private SourceToken expectText(String text) {
    if (!checkText(text)) {
      fail(peek(), "expected '" + text + "'");
    }
    return advance();
  }

  private boolean checkText(String text) {
    return peek().type() == Type.IDENTIFIER && peek().text().equals(text);
  }

  private boolean checkTextIn(Set<String> values) {
    return peek().type() == Type.IDENTIFIER && values.contains(peek().text());
  }

  private boolean match(Type... types) {
    for (Type type : types) {
      if (check(type)) {
        advance();
        return true;
      }
    }
    return false;
  }

  private SourceToken expect(Type type, String description) {
    if (!check(type)) {
      fail(peek(), "expected " + description + ", got '" + peek().text() + "'");
    }
    return advance();
  }

  private boolean check(Type type) {
    return peek().type() == type;
  }

  private SourceToken advance() {
    if (!check(Type.END)) {
      current++;
    }
    return previous();
  }

  private SourceToken peek() {
    return tokens.get(current);
  }

  private SourceToken previous() {
    return tokens.get(current - 1);
  }

  private static void fail(SourceToken token, String message) {
    throw new CompilerException(token.line(), message + " at column " + token.column());
  }

  private record QubitReference(String register, int index) {}
}
