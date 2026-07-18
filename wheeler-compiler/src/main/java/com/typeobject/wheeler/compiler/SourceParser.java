package com.typeobject.wheeler.compiler;

import com.typeobject.wheeler.compiler.SourceModel.Circuit;
import com.typeobject.wheeler.compiler.SourceModel.Function;
import com.typeobject.wheeler.compiler.SourceModel.Parameter;
import com.typeobject.wheeler.compiler.SourceModel.QuantumRegisterSource;
import com.typeobject.wheeler.compiler.SourceModel.RecordDefinition;
import com.typeobject.wheeler.compiler.SourceModel.RecordField;
import com.typeobject.wheeler.compiler.SourceModel.SourceProgram;
import com.typeobject.wheeler.compiler.SourceModel.State;
import com.typeobject.wheeler.compiler.SourceModel.Statement;
import com.typeobject.wheeler.compiler.SourceModel.VariantCase;
import com.typeobject.wheeler.compiler.SourceModel.VariantDefinition;
import com.typeobject.wheeler.compiler.SourceToken.Type;
import java.util.ArrayDeque;
import java.util.ArrayList;
import java.util.Deque;
import java.util.List;
import java.util.Locale;
import java.util.Set;

/** Recursive-descent parser for Wheeler's formatting-independent source profile. */
final class SourceParser extends SourceTokenCursor {
  private static final Set<String> DOMAINS = Set.of("classical", "quantum", "hybrid");
  private static final Set<String> VISIBILITY = Set.of("public", "private", "protected");

  private final List<State> states = new ArrayList<>();
  private final List<Function> functions = new ArrayList<>();
  private final List<RecordDefinition> records = new ArrayList<>();
  private final List<VariantDefinition> variants = new ArrayList<>();
  private final List<QuantumRegisterSource> registers = new ArrayList<>();
  private final List<Circuit> circuits = new ArrayList<>();
  private String domain;
  private boolean structuredStatements;
  private boolean valueReturnsAllowed;
  private int temporarySequence;
  private int labelSequence;
  private final Deque<LoopLabels> loops = new ArrayDeque<>();

  SourceProgram parse(String source) {
    reset(source);
    states.clear();
    functions.clear();
    records.clear();
    variants.clear();
    registers.clear();
    circuits.clear();
    loops.clear();

    SourceToken domain = expect(Type.IDENTIFIER, "computation domain");
    if (!DOMAINS.contains(domain.text())) {
      fail(domain, "expected classical, quantum, or hybrid");
    }
    this.domain = domain.text();
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
        name, domain.text(), states, records, variants, functions, registers, circuits);
  }

  private void parseMember() {
    while (checkTextIn(VISIBILITY)) {
      advance();
    }
    if (matchText("record")) {
      parseRecord(previous());
      return;
    }
    if (matchText("variant")) {
      parseVariant(previous());
      return;
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

  private void parseRecord(SourceToken start) {
    String name = expect(Type.IDENTIFIER, "record name").text();
    if (isValueType(name) || records.stream().anyMatch(record -> record.name().equals(name))) {
      fail(start, "duplicate or reserved record type: " + name);
    }
    expect(Type.LEFT_PAREN, "'(' after record name");
    List<RecordField> fields = new ArrayList<>();
    Set<String> fieldNames = new java.util.HashSet<>();
    if (!check(Type.RIGHT_PAREN)) {
      do {
        SourceToken type = expect(Type.IDENTIFIER, "record field type");
        if (!type.text().equals("long") && !type.text().equals("boolean")
            && records.stream().noneMatch(record -> record.name().equals(type.text()))) {
          fail(type, "record field type must be scalar or previously declared record");
        }
        SourceToken field = expect(Type.IDENTIFIER, "record field name");
        if (!fieldNames.add(field.text())) {
          fail(field, "duplicate record field: " + field.text());
        }
        fields.add(new RecordField(field.text(), type.text()));
      } while (match(Type.COMMA));
    }
    if (fields.isEmpty()) {
      fail(start, "record must declare at least one field");
    }
    expect(Type.RIGHT_PAREN, "')' after record fields");
    expect(Type.LEFT_BRACE, "'{' in record declaration");
    expect(Type.RIGHT_BRACE, "'}' in record declaration");
    records.add(new RecordDefinition(name, fields, start.line()));
  }

  private void parseVariant(SourceToken start) {
    String name = expect(Type.IDENTIFIER, "variant name").text();
    if (isValueType(name)) {
      fail(start, "duplicate or reserved variant type: " + name);
    }
    expect(Type.LEFT_BRACE, "'{' in variant declaration");
    List<VariantCase> cases = new ArrayList<>();
    Set<String> caseNames = new java.util.HashSet<>();
    while (!check(Type.RIGHT_BRACE) && !check(Type.END)) {
      expectText("case");
      SourceToken variantCase = expect(Type.IDENTIFIER, "variant case name");
      if (!caseNames.add(variantCase.text())) {
        fail(variantCase, "duplicate variant case: " + variantCase.text());
      }
      expect(Type.LEFT_PAREN, "'(' after variant case");
      List<RecordField> fields = new ArrayList<>();
      Set<String> fieldNames = new java.util.HashSet<>();
      if (!check(Type.RIGHT_PAREN)) {
        do {
          SourceToken type = expect(Type.IDENTIFIER, "variant payload type");
          if (!isValueType(type.text())) {
            fail(type, "variant payload type must be previously declared");
          }
          SourceToken field = expect(Type.IDENTIFIER, "variant payload name");
          if (!fieldNames.add(field.text())) {
            fail(field, "duplicate variant payload field: " + field.text());
          }
          fields.add(new RecordField(field.text(), type.text()));
        } while (match(Type.COMMA));
      }
      expect(Type.RIGHT_PAREN, "')' after variant payload");
      expect(Type.SEMICOLON, "';' after variant case");
      cases.add(new VariantCase(variantCase.text(), fields));
    }
    if (cases.isEmpty()) {
      fail(start, "variant must declare at least one case");
    }
    expect(Type.RIGHT_BRACE, "'}' after variant declaration");
    variants.add(new VariantDefinition(name, cases, start.line()));
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

    while (checkTextIn(Set.of("static", "coherent", "rev", "unitary", "entry"))) {
      String modifier = advance().text();
      switch (modifier) {
        case "static" -> { /* Accepted for Java familiarity; entry remains statically owned. */ }
        case "coherent" -> coherent = true;
        case "rev" -> reversible = true;
        case "unitary" -> unitary = true;
        case "entry" -> entry = true;
        default -> fail(previous(), "unsupported method modifier: " + modifier);
      }
    }
    SourceToken returnToken = expect(Type.IDENTIFIER, "method return type");
    String returnType = returnToken.text();
    if (!returnType.equals("void") && !isValueType(returnType)) {
      fail(returnToken, "expected void or declared value return type");
    }
    boolean returnsValue = !returnType.equals("void");
    String name = expect(Type.IDENTIFIER, "method name").text();
    expect(Type.LEFT_PAREN, "'(' after method name");
    List<Parameter> parameters = new ArrayList<>();
    if (!check(Type.RIGHT_PAREN)) {
      do {
        SourceToken type = expect(Type.IDENTIFIER, "parameter type");
        if (!isValueType(type.text())) {
          fail(type, "expected declared parameter type");
        }
        parameters.add(new Parameter(
            expect(Type.IDENTIFIER, "parameter name").text(), type.text()));
      } while (match(Type.COMMA));
    }
    expect(Type.RIGHT_PAREN, "')' after parameters");
    expect(Type.LEFT_BRACE, "'{' before method body");

    if (coherent && !reversible) {
      fail(start, "coherent methods must also be rev");
    }
    int semanticModifiers = (reversible ? 1 : 0) + (unitary ? 1 : 0) + (entry ? 1 : 0);
    if (semanticModifiers > 1) {
      fail(start, "rev, unitary, and entry are mutually exclusive method kinds");
    }
    if (entry && (!name.equals("main") || returnsValue || !parameters.isEmpty())) {
      fail(start, "entry method must have signature void main()");
    }
    if ((reversible || coherent || unitary) && (returnsValue || !parameters.isEmpty())) {
      fail(start, "parameters and return values are currently ordinary classical only");
    }

    if (unitary) {
      circuits.add(parseCircuit(name, start.line()));
    } else {
      functions.add(parseFunction(
          name, entry, reversible, coherent, parameters, returnType, start.line()));
    }
  }

  private Function parseFunction(
      String name,
      boolean entry,
      boolean reversible,
      boolean coherent,
      List<Parameter> parameters,
      String returnType,
      int line) {
    List<Statement> body = new ArrayList<>();
    structuredStatements = !reversible && (!entry || domain.equals("classical"));
    valueReturnsAllowed = !returnType.equals("void");
    temporarySequence = 0;
    labelSequence = 0;
    while (!check(Type.RIGHT_BRACE) && !check(Type.END)) {
      if (structuredStatements && checkLocalType()) {
        parseLocalDeclaration(body);
      } else if (structuredStatements && matchText("return")) {
        parseReturn(body, previous());
      } else if (structuredStatements && matchText("if")) {
        parseIf(body, previous());
      } else if (structuredStatements && matchText("while")) {
        parseWhile(body, previous());
      } else if (structuredStatements && matchText("for")) {
        parseFor(body, previous());
      } else if (structuredStatements && matchText("match")) {
        parseMatch(body, previous());
      } else if (structuredStatements && (matchText("break") || matchText("continue"))) {
        parseLoopJump(body, previous());
      } else if (structuredStatements && isAssignmentStart()) {
        parseStructuredAssignment(body);
      } else if (!structuredStatements
          && (checkLocalType() || checkText("if") || checkText("while") || checkText("for")
              || checkText("match") || checkText("return") || checkText("break")
              || checkText("continue"))) {
        fail(peek(), "local control flow is not available in this method kind");
      } else if (matchText("reverse")) {
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
    return new Function(
        name, entry, reversible, coherent, parameters, returnType, body, line);
  }

  private void parseReturn(List<Statement> body, SourceToken start) {
    if (!valueReturnsAllowed) {
      fail(start, "return value is not available in a void method");
    }
    String value = parseExpression(body);
    expect(Type.SEMICOLON, "';' after return value");
    body.add(statement("return_value", start.line(), value));
  }

  private void parseLocalDeclaration(List<Statement> body) {
    SourceToken start = advance();
    String type = start.text();
    if (!isValueType(type)) {
      fail(start, "expected declared local type");
    }
    String name = expect(Type.IDENTIFIER, "local name").text();
    expect(Type.ASSIGN, "'=' in local declaration");
    String value = parseExpression(body);
    expect(Type.SEMICOLON, "';' after local declaration");
    body.add(statement("local_bind", start.line(), name, value, type));
  }

  private void parseStructuredAssignment(List<Statement> body) {
    SourceToken target = advance();
    Type operator = advance().type();
    String value = parseExpression(body);
    expect(Type.SEMICOLON, "';' after assignment");
    body.add(statement("assign", target.line(), target.text(), operator.name(), value));
  }

  private void parseIf(List<Statement> body, SourceToken start) {
    expect(Type.LEFT_PAREN, "'(' after if");
    String condition = parseExpression(body);
    expect(Type.RIGHT_PAREN, "')' after if condition");
    String otherwise = label();
    String done = label();
    body.add(statement("jump_zero", start.line(), condition, otherwise));
    parseStructuredBlock(body, "if");
    body.add(statement("jump", start.line(), done));
    body.add(statement("label", start.line(), otherwise));
    if (matchText("else")) {
      parseStructuredBlock(body, "else");
    }
    body.add(statement("label", start.line(), done));
  }

  private void parseWhile(List<Statement> body, SourceToken start) {
    expect(Type.LEFT_PAREN, "'(' after while");
    List<Statement> conditionCode = new ArrayList<>();
    String condition = parseExpression(conditionCode);
    expect(Type.RIGHT_PAREN, "')' after while condition");
    expectText("limit");
    String limit = parseExpression(body);
    String iterations = temporary();
    body.add(statement("local_const", start.line(), iterations, "0"));
    String repeat = label();
    String done = label();
    body.add(statement("label", start.line(), repeat));
    body.addAll(conditionCode);
    body.add(statement("jump_zero", start.line(), condition, done));
    body.add(statement("loop_check", start.line(), iterations, limit));
    loops.push(new LoopLabels(repeat, done));
    parseStructuredBlock(body, "while");
    loops.pop();
    body.add(statement("jump", start.line(), repeat));
    body.add(statement("label", start.line(), done));
  }

  private void parseFor(List<Statement> body, SourceToken start) {
    expect(Type.LEFT_PAREN, "'(' after for");
    if (!checkLocalType()) {
      fail(peek(), "for initializer must declare a typed local");
    }
    parseLocalDeclaration(body);
    List<Statement> conditionCode = new ArrayList<>();
    String condition = parseExpression(conditionCode);
    expect(Type.SEMICOLON, "';' after for condition");
    List<Statement> updateCode = new ArrayList<>();
    parseForUpdate(updateCode);
    expect(Type.RIGHT_PAREN, "')' after for update");
    expectText("limit");
    String limit = parseExpression(body);
    String iterations = temporary();
    body.add(statement("local_const", start.line(), iterations, "0"));
    String repeat = label();
    String update = label();
    String done = label();
    body.add(statement("label", start.line(), repeat));
    body.addAll(conditionCode);
    body.add(statement("jump_zero", start.line(), condition, done));
    body.add(statement("loop_check", start.line(), iterations, limit));
    loops.push(new LoopLabels(update, done));
    parseStructuredBlock(body, "for");
    loops.pop();
    body.add(statement("label", start.line(), update));
    body.addAll(updateCode);
    body.add(statement("jump", start.line(), repeat));
    body.add(statement("label", start.line(), done));
  }

  private void parseForUpdate(List<Statement> body) {
    SourceToken target = expect(Type.IDENTIFIER, "for update target");
    if (!match(Type.ASSIGN, Type.PLUS_ASSIGN, Type.MINUS_ASSIGN, Type.XOR_ASSIGN)) {
      fail(peek(), "expected assignment in for update");
    }
    Type operator = previous().type();
    String value = parseExpression(body);
    body.add(statement("assign", target.line(), target.text(), operator.name(), value));
  }

  private void parseStructuredBlock(List<Statement> body, String owner) {
    expect(Type.LEFT_BRACE, "'{' before " + owner + " body");
    while (!check(Type.RIGHT_BRACE) && !check(Type.END)) {
      if (checkLocalType()) {
        parseLocalDeclaration(body);
      } else if (matchText("return")) {
        parseReturn(body, previous());
      } else if (matchText("if")) {
        parseIf(body, previous());
      } else if (matchText("while")) {
        parseWhile(body, previous());
      } else if (matchText("for")) {
        parseFor(body, previous());
      } else if (matchText("match")) {
        parseMatch(body, previous());
      } else if (matchText("break") || matchText("continue")) {
        parseLoopJump(body, previous());
      } else if (isAssignmentStart()) {
        parseStructuredAssignment(body);
      } else {
        body.add(parseStatement());
      }
    }
    expect(Type.RIGHT_BRACE, "'}' after " + owner + " body");
  }

  private void parseMatch(List<Statement> body, SourceToken start) {
    expect(Type.LEFT_PAREN, "'(' after match");
    String selector = parseExpression(body);
    expect(Type.RIGHT_PAREN, "')' after match selector");
    expect(Type.LEFT_BRACE, "'{' before match cases");
    List<MatchCase> parsed = new ArrayList<>();
    while (!check(Type.RIGHT_BRACE) && !check(Type.END)) {
      expectText("case");
      SourceToken type = expect(Type.IDENTIFIER, "variant type in case");
      expect(Type.DOT, "'.' before variant case");
      SourceToken caseName = expect(Type.IDENTIFIER, "variant case name");
      expect(Type.LEFT_PAREN, "'(' after variant case");
      List<Parameter> bindings = new ArrayList<>();
      if (!check(Type.RIGHT_PAREN)) {
        do {
          SourceToken bindingType = expect(Type.IDENTIFIER, "payload binding type");
          bindings.add(new Parameter(
              expect(Type.IDENTIFIER, "payload binding name").text(), bindingType.text()));
        } while (match(Type.COMMA));
      }
      expect(Type.RIGHT_PAREN, "')' after payload bindings");
      List<Statement> caseBody = new ArrayList<>();
      parseStructuredBlock(caseBody, "case");
      parsed.add(new MatchCase(type.text(), caseName.text(), bindings, caseBody, type.line()));
    }
    expect(Type.RIGHT_BRACE, "'}' after match cases");
    VariantDefinition variant = validateMatch(parsed, start);
    String done = label();
    for (int index = 0; index < parsed.size(); index++) {
      MatchCase selected = parsed.get(index);
      VariantCase descriptor = variant.cases().stream()
          .filter(candidate -> candidate.name().equals(selected.caseName()))
          .findFirst().orElseThrow();
      String next = index + 1 == parsed.size() ? null : label();
      if (next != null) {
        String condition = temporary();
        body.add(statement(
            "variant_tag", selected.line(), condition, selector,
            variant.name(), selected.caseName()));
        body.add(statement("jump_zero", selected.line(), condition, next));
      }
      for (int field = 0; field < selected.bindings().size(); field++) {
        body.add(statement(
            "variant_get",
            selected.line(),
            selected.bindings().get(field).name(),
            selector,
            variant.name(),
            selected.caseName(),
            Integer.toString(field)));
      }
      body.addAll(selected.body());
      if (next != null) {
        body.add(statement("jump", selected.line(), done));
        body.add(statement("label", selected.line(), next));
      }
    }
    body.add(statement("label", start.line(), done));
  }

  private VariantDefinition validateMatch(List<MatchCase> cases, SourceToken start) {
    if (cases.isEmpty()) {
      fail(start, "match must contain every variant case");
    }
    VariantDefinition variant = variants.stream()
        .filter(candidate -> candidate.name().equals(cases.getFirst().type()))
        .findFirst()
        .orElse(null);
    if (variant == null) {
      fail(start, "match case names an unknown variant type");
    }
    Set<String> seen = new java.util.HashSet<>();
    for (MatchCase parsed : cases) {
      VariantCase descriptor = variant.cases().stream()
          .filter(candidate -> candidate.name().equals(parsed.caseName()))
          .findFirst().orElse(null);
      if (!parsed.type().equals(variant.name()) || descriptor == null
          || !seen.add(parsed.caseName())
          || descriptor.fields().size() != parsed.bindings().size()) {
        fail(start, "match cases do not exhaust " + variant.name());
      }
      for (int field = 0; field < descriptor.fields().size(); field++) {
        if (!descriptor.fields().get(field).type().equals(parsed.bindings().get(field).type())) {
          fail(start, "variant payload binding type mismatch in " + parsed.caseName());
        }
      }
    }
    if (seen.size() != variant.cases().size()) {
      fail(start, "match cases do not exhaust " + variant.name());
    }
    return variant;
  }

  private void parseLoopJump(List<Statement> body, SourceToken keyword) {
    if (loops.isEmpty()) {
      fail(keyword, keyword.text() + " is only valid inside a bounded loop");
    }
    expect(Type.SEMICOLON, "';' after " + keyword.text());
    LoopLabels loop = loops.getFirst();
    body.add(statement(
        "jump",
        keyword.line(),
        keyword.text().equals("break") ? loop.done() : loop.repeat()));
  }

  private String parseExpression(List<Statement> body) {
    return parseEquality(body);
  }

  private String parseEquality(List<Statement> body) {
    String left = parseComparison(body);
    while (match(Type.EQUAL)) {
      left = binary(body, previous(), "eq", left, parseComparison(body));
    }
    return left;
  }

  private String parseComparison(List<Statement> body) {
    String left = parseXor(body);
    while (match(Type.LESS)) {
      left = binary(body, previous(), "lt", left, parseXor(body));
    }
    return left;
  }

  private String parseXor(List<Statement> body) {
    String left = parseAdditive(body);
    while (match(Type.XOR)) {
      left = binary(body, previous(), "xor", left, parseAdditive(body));
    }
    return left;
  }

  private String parseAdditive(List<Statement> body) {
    String left = parsePrimary(body);
    while (match(Type.PLUS, Type.MINUS)) {
      SourceToken operator = previous();
      left = binary(
          body, operator, operator.type() == Type.PLUS ? "add" : "sub", left, parsePrimary(body));
    }
    return left;
  }

  private String parsePrimary(List<Statement> body) {
    if (match(Type.LEFT_PAREN)) {
      String value = parseExpression(body);
      expect(Type.RIGHT_PAREN, "')' after expression");
      return parseFieldAccess(body, value, previous().line());
    }
    SourceToken start = peek();
    if (match(Type.MINUS)) {
      String value = "-" + expect(Type.NUMBER, "numeric literal").text();
      return constant(body, start, value);
    }
    if (match(Type.NUMBER)) {
      return constant(body, previous(), previous().text());
    }
    if (matchText("new")) {
      SourceToken type = expect(Type.IDENTIFIER, "aggregate type after new");
      boolean record = records.stream().anyMatch(candidate -> candidate.name().equals(type.text()));
      VariantDefinition variant = variants.stream()
          .filter(candidate -> candidate.name().equals(type.text()))
          .findFirst().orElse(null);
      String caseName = null;
      if (!record && variant != null) {
        expect(Type.DOT, "'.' before variant case");
        caseName = expect(Type.IDENTIFIER, "variant case after new").text();
        String selected = caseName;
        if (variant.cases().stream().noneMatch(candidate -> candidate.name().equals(selected))) {
          fail(type, "unknown variant case: " + type.text() + "." + caseName);
        }
      } else if (!record) {
        fail(type, "unknown aggregate type: " + type.text());
      }
      expect(Type.LEFT_PAREN, "'(' after aggregate constructor");
      List<String> arguments = new ArrayList<>();
      if (!check(Type.RIGHT_PAREN)) {
        do {
          arguments.add(parseExpression(body));
        } while (match(Type.COMMA));
      }
      expect(Type.RIGHT_PAREN, "')' after aggregate fields");
      String result = temporary();
      List<String> construction = new ArrayList<>();
      construction.add(result);
      construction.add(type.text());
      if (variant != null) {
        construction.add(caseName);
      }
      construction.addAll(arguments);
      body.add(new Statement(
          variant == null ? "record_new" : "variant_new", construction, start.line()));
      return parseFieldAccess(body, result, start.line());
    }
    if (checkText("true") || checkText("false")) {
      SourceToken value = advance();
      String result = temporary();
      body.add(statement(
          "local_boolean", value.line(), result, value.text().equals("true") ? "1" : "0"));
      return result;
    }
    if (match(Type.IDENTIFIER)) {
      if (match(Type.LEFT_PAREN)) {
        List<String> arguments = new ArrayList<>();
        if (!check(Type.RIGHT_PAREN)) {
          do {
            arguments.add(parseExpression(body));
          } while (match(Type.COMMA));
        }
        expect(Type.RIGHT_PAREN, "')' after call arguments");
        String result = temporary();
        List<String> call = new ArrayList<>();
        call.add(result);
        call.add(start.text());
        call.addAll(arguments);
        body.add(new Statement("call_value", call, start.line()));
        return parseFieldAccess(body, result, start.line());
      }
      String result = temporary();
      body.add(statement("local_read", start.line(), result, start.text()));
      return parseFieldAccess(body, result, start.line());
    }
    fail(start, "expected expression");
    throw new AssertionError("unreachable");
  }

  private String parseFieldAccess(List<Statement> body, String source, int line) {
    String value = source;
    while (match(Type.DOT)) {
      String field = expect(Type.IDENTIFIER, "record field name").text();
      String result = temporary();
      body.add(statement("record_get", line, result, value, field));
      value = result;
    }
    return value;
  }

  private String constant(List<Statement> body, SourceToken source, String value) {
    String result = temporary();
    body.add(statement("local_const", source.line(), result, value));
    return result;
  }

  private String binary(
      List<Statement> body, SourceToken source, String operator, String left, String right) {
    String result = temporary();
    body.add(statement("local_binary", source.line(), result, operator, left, right));
    return result;
  }

  private boolean checkLocalType() {
    return check(Type.IDENTIFIER) && isValueType(peek().text());
  }

  private boolean isValueType(String name) {
    return name.equals("long") || name.equals("boolean")
        || records.stream().anyMatch(record -> record.name().equals(name))
        || variants.stream().anyMatch(variant -> variant.name().equals(name));
  }

  private boolean isAssignmentStart() {
    if (!check(Type.IDENTIFIER)) {
      return false;
    }
    Type next = lookaheadType(1);
    return next == Type.ASSIGN
        || next == Type.PLUS_ASSIGN
        || next == Type.MINUS_ASSIGN
        || next == Type.XOR_ASSIGN;
  }

  private String temporary() {
    return "$t" + temporarySequence++;
  }

  private String label() {
    return "$l" + labelSequence++;
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

  private record MatchCase(
      String type, String caseName, List<Parameter> bindings, List<Statement> body, int line) {
    private MatchCase {
      bindings = List.copyOf(bindings);
      body = List.copyOf(body);
    }
  }

  private record LoopLabels(String repeat, String done) {}

  private record QubitReference(String register, int index) {}
}
