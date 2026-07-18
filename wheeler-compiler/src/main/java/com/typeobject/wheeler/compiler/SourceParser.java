package com.typeobject.wheeler.compiler;

import com.typeobject.wheeler.compiler.SourceModel.ArrayDefinition;
import com.typeobject.wheeler.compiler.SourceModel.Circuit;
import com.typeobject.wheeler.compiler.SourceModel.Function;
import com.typeobject.wheeler.compiler.SourceModel.Parameter;
import com.typeobject.wheeler.compiler.SourceModel.ProofDeclaration;
import com.typeobject.wheeler.compiler.SourceModel.QuantumRegisterSource;
import com.typeobject.wheeler.compiler.SourceModel.RecordDefinition;
import com.typeobject.wheeler.compiler.SourceModel.RecordField;
import com.typeobject.wheeler.compiler.SourceModel.SliceDefinition;
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
import java.util.Set;

/** Recursive-descent parser for Wheeler's formatting-independent source profile. */
final class SourceParser extends SourceStatementParser {
  private static final int MAX_DECLARATIONS = 65_535;
  private static final int MAX_BLOCK_DEPTH = 256;
  private static final Set<String> DOMAINS = Set.of("classical", "quantum", "hybrid");
  private static final Set<String> VISIBILITY = Set.of("public", "private", "protected");

  private final List<State> states = new ArrayList<>();
  private final List<Function> functions = new ArrayList<>();
  private final List<RecordDefinition> records = new ArrayList<>();
  private final List<VariantDefinition> variants = new ArrayList<>();
  private final List<ArrayDefinition> arrays = new ArrayList<>();
  private final List<SliceDefinition> slices = new ArrayList<>();
  private final List<ProofDeclaration> proofs = new ArrayList<>();
  private final List<QuantumRegisterSource> registers = new ArrayList<>();
  private final List<Circuit> circuits = new ArrayList<>();
  private String domain;
  private boolean structuredStatements;
  private boolean valueReturnsAllowed;
  private int temporarySequence;
  private int labelSequence;
  private int blockDepth;
  private final Deque<LoopLabels> loops = new ArrayDeque<>();

  SourceProgram parse(String source) {
    reset(source);
    states.clear();
    functions.clear();
    records.clear();
    variants.clear();
    arrays.clear();
    slices.clear();
    proofs.clear();
    registers.clear();
    circuits.clear();
    loops.clear();
    blockDepth = 0;

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
        name,
        domain.text(),
        states,
        records,
        variants,
        arrays,
        slices,
        proofs,
        functions,
        registers,
        circuits);
  }

  private void parseMember() {
    int declarations = states.size() + functions.size() + records.size() + variants.size()
        + proofs.size() + registers.size() + circuits.size();
    if (declarations >= MAX_DECLARATIONS) {
      fail(peek(), "source exceeds the 65,535-declaration limit");
    }
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
    if (matchText("theorem")) {
      parseTheorem(previous());
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

  private void parseTheorem(SourceToken start) {
    String name = expect(Type.IDENTIFIER, "theorem name").text();
    expectText("proves");
    SourceToken rule = expect(Type.IDENTIFIER, "proof rule");
    if (!rule.text().equals("inverse")
        && !rule.text().equals("adjoint")
        && !rule.text().equals("equivalent")
        && !rule.text().equals("steps")) {
      fail(rule, "expected inverse, adjoint, equivalent, or steps proof rule");
    }
    expect(Type.LEFT_PAREN, "'(' after " + rule.text());
    String subject = expect(Type.IDENTIFIER, "proof subject name").text();
    String related = null;
    Long argument = null;
    if (rule.text().equals("equivalent")) {
      expect(Type.COMMA, "',' between equivalent circuits");
      related = expect(Type.IDENTIFIER, "related circuit name").text();
    } else if (rule.text().equals("steps")) {
      expect(Type.COMMA, "',' before the step bound");
      SourceToken bound = expect(Type.NUMBER, "positive step bound");
      argument = parseInteger(bound.text(), bound.line());
    }
    expect(Type.RIGHT_PAREN, "')' after proof subject");
    expect(Type.SEMICOLON, "';' after theorem");
    proofs.add(new ProofDeclaration(
        name, rule.text(), subject, related, argument, start.line()));
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
    String returnType = matchText("void")
        ? "void"
        : parseValueType("method return type");
    boolean returnsValue = !returnType.equals("void");
    String name = expect(Type.IDENTIFIER, "method name").text();
    if (name.equals("slice")) {
      fail(start, "slice is a reserved value constructor");
    }
    expect(Type.LEFT_PAREN, "'(' after method name");
    List<Parameter> parameters = new ArrayList<>();
    if (!check(Type.RIGHT_PAREN)) {
      do {
        String type = parseValueType("parameter type");
        parameters.add(new Parameter(
            expect(Type.IDENTIFIER, "parameter name").text(), type));
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
      } else if (structuredStatements && matchText("set")) {
        parseBufferSet(body, previous());
      } else if (structuredStatements && matchText("drop")) {
        parseOwnedDrop(body, previous());
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
    SourceToken start = peek();
    String type = parseValueType("local type");
    String name = expect(Type.IDENTIFIER, "local name").text();
    expect(Type.ASSIGN, "'=' in local declaration");
    String value = parseExpression(body);
    expect(Type.SEMICOLON, "';' after local declaration");
    body.add(statement("local_bind", start.line(), name, value, type));
  }

  private void parseBufferSet(List<Statement> body, SourceToken start) {
    expect(Type.LEFT_PAREN, "'(' after set");
    String buffer = parseExpression(body);
    expect(Type.COMMA, "',' after buffer");
    String index = parseExpression(body);
    expect(Type.COMMA, "',' after buffer index");
    String value = parseExpression(body);
    expect(Type.RIGHT_PAREN, "')' after set arguments");
    expect(Type.SEMICOLON, "';' after set");
    body.add(statement("buffer_set", start.line(), buffer, index, value));
  }

  private void parseOwnedDrop(List<Statement> body, SourceToken start) {
    expect(Type.LEFT_PAREN, "'(' after drop");
    String value = parseExpression(body);
    expect(Type.RIGHT_PAREN, "')' after drop value");
    expect(Type.SEMICOLON, "';' after drop");
    body.add(statement("owned_drop", start.line(), value));
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
    if (++blockDepth > MAX_BLOCK_DEPTH) {
      fail(peek(), "source exceeds the 256-block nesting limit");
    }
    try {
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
        } else if (matchText("set")) {
          parseBufferSet(body, previous());
        } else if (matchText("drop")) {
          parseOwnedDrop(body, previous());
        } else if (isAssignmentStart()) {
          parseStructuredAssignment(body);
        } else {
          body.add(parseStatement());
        }
      }
      expect(Type.RIGHT_BRACE, "'}' after " + owner + " body");
    } finally {
      blockDepth--;
    }
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
      return parsePostfix(body, value, previous().line());
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
      if (matchText("region")) {
        expect(Type.LEFT_PAREN, "'(' after region");
        String maxBytes = signedNumber();
        expect(Type.COMMA, "',' after region byte limit");
        String maxObjects = signedNumber();
        expect(Type.RIGHT_PAREN, "')' after region limits");
        String result = temporary();
        body.add(statement("region_new", start.line(), result, maxBytes, maxObjects));
        return result;
      }
      SourceToken type = peek();
      String typeName = parseValueType("aggregate type after new");
      boolean record = records.stream().anyMatch(candidate -> candidate.name().equals(typeName));
      VariantDefinition variant = variants.stream()
          .filter(candidate -> candidate.name().equals(typeName))
          .findFirst().orElse(null);
      String caseName = null;
      boolean array = arrays.stream().anyMatch(candidate -> candidate.name().equals(typeName));
      if (!record && !array && variant != null) {
        expect(Type.DOT, "'.' before variant case");
        caseName = expect(Type.IDENTIFIER, "variant case after new").text();
        String selected = caseName;
        if (variant.cases().stream().noneMatch(candidate -> candidate.name().equals(selected))) {
          fail(type, "unknown variant case: " + typeName + "." + caseName);
        }
      } else if (!record && !array) {
        fail(type, "unknown aggregate type: " + typeName);
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
      construction.add(typeName);
      if (variant != null) {
        construction.add(caseName);
      }
      construction.addAll(arguments);
      String operation = array ? "array_new" : variant == null ? "record_new" : "variant_new";
      body.add(new Statement(operation, construction, start.line()));
      return parsePostfix(body, result, start.line());
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
        String operation = switch (start.text()) {
          case "slice" -> "slice_new";
          case "allocate" -> "buffer_alloc";
          default -> "call_value";
        };
        body.add(new Statement(operation, call, start.line()));
        return parsePostfix(body, result, start.line());
      }
      String result = temporary();
      body.add(statement("local_read", start.line(), result, start.text()));
      return parsePostfix(body, result, start.line());
    }
    fail(start, "expected expression");
    throw new AssertionError("unreachable");
  }

  private String parsePostfix(List<Statement> body, String source, int line) {
    String value = source;
    while (check(Type.DOT) || check(Type.LEFT_BRACKET)) {
      String result = temporary();
      if (match(Type.DOT)) {
        String field = expect(Type.IDENTIFIER, "record field name").text();
        body.add(statement("record_get", line, result, value, field));
      } else {
        expect(Type.LEFT_BRACKET, "'[' before array index");
        String index = parseExpression(body);
        expect(Type.RIGHT_BRACKET, "']' after array index");
        body.add(statement("array_get", line, result, value, index));
      }
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

  private String parseValueType(String description) {
    SourceToken element = expect(Type.IDENTIFIER, description);
    if (!isValueType(element.text())) {
      fail(element, "expected declared " + description);
    }
    if (!match(Type.LEFT_BRACKET)) {
      return element.text();
    }
    if (element.text().equals("region") || element.text().equals("words")) {
      fail(element, "owned storage types cannot be array or slice elements");
    }
    if (match(Type.RIGHT_BRACKET)) {
      String name = element.text() + "[]";
      if (slices.stream().noneMatch(slice -> slice.name().equals(name))) {
        slices.add(new SliceDefinition(name, element.text(), element.line()));
      }
      return name;
    }
    SourceToken lengthToken = expect(Type.NUMBER, "fixed array length");
    long length = parseInteger(lengthToken.text(), lengthToken.line());
    if (length <= 0 || length > 65_535) {
      fail(lengthToken, "fixed array length must be between 1 and 65535");
    }
    expect(Type.RIGHT_BRACKET, "']' after fixed array length");
    String name = element.text() + "[" + length + "]";
    if (arrays.stream().noneMatch(array -> array.name().equals(name))) {
      arrays.add(new ArrayDefinition(
          name, element.text(), Math.toIntExact(length), element.line()));
    }
    return name;
  }

  private boolean checkLocalType() {
    return check(Type.IDENTIFIER) && isValueType(peek().text());
  }

  private boolean isValueType(String name) {
    return name.equals("long") || name.equals("boolean")
        || name.equals("region") || name.equals("words")
        || records.stream().anyMatch(record -> record.name().equals(name))
        || variants.stream().anyMatch(variant -> variant.name().equals(name))
        || arrays.stream().anyMatch(array -> array.name().equals(name))
        || slices.stream().anyMatch(slice -> slice.name().equals(name));
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

  private record MatchCase(
      String type, String caseName, List<Parameter> bindings, List<Statement> body, int line) {
    private MatchCase {
      bindings = List.copyOf(bindings);
      body = List.copyOf(body);
    }
  }

  private record LoopLabels(String repeat, String done) {}

}
