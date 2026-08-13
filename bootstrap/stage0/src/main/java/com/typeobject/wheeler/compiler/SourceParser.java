package com.typeobject.wheeler.compiler;

import com.typeobject.wheeler.compiler.SourceMatchValidator.MatchCase;
import com.typeobject.wheeler.compiler.SourceModel.ArrayDefinition;
import com.typeobject.wheeler.compiler.SourceModel.Circuit;
import com.typeobject.wheeler.compiler.SourceModel.ConstantDefinition;
import com.typeobject.wheeler.compiler.SourceModel.Function;
import com.typeobject.wheeler.compiler.SourceModel.Parameter;
import com.typeobject.wheeler.compiler.SourceModel.ParameterMode;
import com.typeobject.wheeler.compiler.SourceModel.ProofDeclaration;
import com.typeobject.wheeler.compiler.SourceModel.QuantumRegisterSource;
import com.typeobject.wheeler.compiler.SourceModel.RecordDefinition;
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
  private static final Set<String> NULL_LIKE_VALUES =
      Set.of("null", "nil", "none", "undefined");

  private final List<State> states = new ArrayList<>();
  private final List<ConstantDefinition> constants = new ArrayList<>();
  private final SourceConstantEnvironment constantEnvironment;
  private final List<Function> functions = new ArrayList<>();
  private final List<RecordDefinition> records = new ArrayList<>();
  private final List<VariantDefinition> variants = new ArrayList<>();
  private final List<VariantDefinition> importedVariants;
  private final List<ArrayDefinition> arrays = new ArrayList<>();
  private final List<SliceDefinition> slices = new ArrayList<>();
  private final List<ProofDeclaration> proofs = new ArrayList<>();
  private final List<QuantumRegisterSource> registers = new ArrayList<>();
  private final List<Circuit> circuits = new ArrayList<>();
  private final List<String> imports = new ArrayList<>();
  private String moduleName;
  private String domain;
  private boolean structuredStatements;
  private boolean valueReturnsAllowed;
  private int temporarySequence;
  private int labelSequence;
  private int blockDepth;
  private final Deque<LoopLabels> loops = new ArrayDeque<>();

  SourceParser() {
    this(List.of(), List.of());
  }

  SourceParser(
      List<VariantDefinition> importedVariants,
      List<ConstantDefinition> importedConstants) {
    this.importedVariants = List.copyOf(importedVariants);
    this.constantEnvironment = new SourceConstantEnvironment(importedConstants);
  }

  SourceProgram parse(String source) {
    return parse(source, true);
  }

  SourceProgram parse(String source, boolean requireEntry) {
    constantEnvironment.prepare(source);
    reset(source);
    states.clear();
    constants.clear();
    functions.clear();
    records.clear();
    variants.clear();
    arrays.clear();
    slices.clear();
    proofs.clear();
    registers.clear();
    circuits.clear();
    imports.clear();
    loops.clear();
    moduleName = null;
    blockDepth = 0;

    SourceModuleHeaderParser.Header header = SourceModuleHeaderParser.parse(this);
    moduleName = header.moduleName();
    imports.addAll(header.imports());

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

    SourceMemberValidator.validate(
        constants, states, functions, records, variants);
    long entryCount = functions.stream().filter(Function::entry).count();
    if ((requireEntry && entryCount != 1) || (!requireEntry && entryCount > 1)) {
      fail(domain, requireEntry
          ? "exactly one 'entry void main()' method is required"
          : "a module may declare at most one entry method");
    }
    return new SourceProgram(
        moduleName,
        imports,
        name,
        domain.text(),
        states,
        constants,
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
    int declarations = states.size() + constants.size() + functions.size()
        + records.size() + variants.size() + proofs.size() + registers.size() + circuits.size();
    if (declarations >= MAX_DECLARATIONS) {
      fail(peek(), "source exceeds the 65,535-declaration limit");
    }
    boolean exported = false;
    while (checkTextIn(VISIBILITY)) {
      exported |= advance().text().equals("public");
    }
    if (matchText("record")) {
      records.add(SourceNominalParser.parseRecord(
          this,
          previous(),
          exported,
          moduleName,
          records,
          this::isValueType,
          variants,
          arrays,
          slices));
      return;
    }
    if (matchText("variant")) {
      variants.add(SourceNominalParser.parseVariant(
          this,
          previous(),
          exported,
          moduleName,
          this::isValueType,
          variants,
          arrays,
          slices));
      return;
    }
    if (matchText("enum")) {
      variants.add(SourceEnumParser.parse(
          this, previous(), exported, records, variants));
      return;
    }
    if (matchText("const")) {
      ConstantDefinition constant = SourceConstantParser.parseDeclaration(
          this, previous(), exported);
      if (constants.stream().anyMatch(
          existing -> existing.name().equals(constant.name()))) {
        fail(previous(), "duplicate constant: " + constant.name());
      }
      constants.add(constant);
      return;
    }
    if (matchText("theorem")) {
      proofs.add(SourceScalarMemberParser.parseTheorem(this, previous()));
      return;
    }
    if (matchText("state")) {
      states.add(SourceScalarMemberParser.parseState(this, previous()));
      return;
    }
    if (matchText("qreg")) {
      registers.add(SourceScalarMemberParser.parseQuantumRegister(this, previous()));
      return;
    }
    parseMethod(exported);
  }

  private void parseMethod(boolean exported) {
    boolean coherent = false;
    boolean reversible = false;
    boolean unitary = false;
    boolean entry = false;
    boolean test = false;
    SourceToken start = peek();

    while (checkTextIn(Set.of("static", "coherent", "rev", "unitary", "entry", "test"))) {
      String modifier = advance().text();
      switch (modifier) {
        case "static" -> { /* Accepted for Java familiarity; entry remains statically owned. */ }
        case "coherent" -> coherent = true;
        case "rev" -> reversible = true;
        case "unitary" -> unitary = true;
        case "entry" -> entry = true;
        case "test" -> test = true;
        default -> fail(previous(), "unsupported method modifier: " + modifier);
      }
    }
    String returnType = matchText("void")
        ? "void"
        : parseValueType("method return type");
    boolean returnsValue = !returnType.equals("void");
    String name = SourceNames.binding(expect(Type.IDENTIFIER, "method name"));
    if (name.equals("slice")) {
      fail(start, "slice is a reserved value constructor");
    }
    expect(Type.LEFT_PAREN, "'(' after method name");
    List<Parameter> parameters = new ArrayList<>();
    if (!check(Type.RIGHT_PAREN)) {
      do {
        SourceToken parameterStart = peek();
        ParameterMode mode = SourceParameterParser.parseMode(this);
        String type = parseValueType("parameter type");
        SourceParameterParser.validate(type, mode, parameterStart);
        parameters.add(new Parameter(
            SourceNames.binding(expect(Type.IDENTIFIER, "parameter name")), type, mode));
      } while (match(Type.COMMA));
    }
    expect(Type.RIGHT_PAREN, "')' after parameters");
    List<List<String>> testCases = SourceTestCaseParser.parse(
        this, test, parameters, start);
    List<String> testTags = SourceTestTags.parse(this, test, start);
    expect(Type.LEFT_BRACE, "'{' before method body");

    if (coherent && !reversible) {
      fail(start, "coherent methods must also be rev");
    }
    int semanticModifiers = (reversible ? 1 : 0) + (unitary ? 1 : 0)
        + (entry ? 1 : 0) + (test ? 1 : 0);
    if (semanticModifiers > 1) {
      fail(start, "rev, unitary, entry, and test are mutually exclusive method kinds");
    }
    boolean validEntryParameters = SourceParameterParser.validEntry(parameters);
    if (entry && (!name.equals("main") || returnsValue || !validEntryParameters)) {
      fail(
          start,
          "entry parameters must be optional 'borrow utf8'/'borrow byteview' input then "
              + "optional 'borrow mut bytes' output");
    }
    SourceTestCaseParser.validateShape(
        test, domain, returnsValue, parameters, testCases, start);
    SourceResultParser.validateSpecialMethodShape(
        start, reversible, coherent, unitary, returnType, !parameters.isEmpty());

    if (unitary) {
      circuits.add(parseCircuit(name, start.line()));
    } else {
      functions.add(parseFunction(
          name, exported, entry, test, reversible, coherent, parameters, testCases,
          testTags, returnType, start.line()));
    }
  }

  private Function parseFunction(
      String name,
      boolean exported,
      boolean entry,
      boolean test,
      boolean reversible,
      boolean coherent,
      List<Parameter> parameters,
      List<List<String>> testCases,
      List<String> testTags,
      String returnType,
      int line) {
    List<Statement> body = new ArrayList<>();
    valueReturnsAllowed = !returnType.equals("void");
    structuredStatements = (!reversible || valueReturnsAllowed)
        && (!entry || domain.equals("classical"));
    temporarySequence = 0;
    labelSequence = 0;
    while (!check(Type.RIGHT_BRACE) && !check(Type.END)) {
      if (structuredStatements && checkLocalType()) {
        SourceResultParser.parseLocalDeclaration(this, body);
      } else if (structuredStatements && matchText("return")) {
        SourceResultParser.parseReturn(this, body, previous(), valueReturnsAllowed);
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
      } else if (structuredStatements && matchText("put")) {
        parseBufferSet(body, previous(), "map_put");
      } else if (structuredStatements && matchText("setByte")) {
        parseBufferSet(body, previous(), "bytes_set");
      } else if (structuredStatements && matchText("setOutputLength")) {
        SourceOutputEffectParser.parse(this, body, previous());
      } else if (structuredStatements && matchText("writeAscii")) {
        SourceAsciiWriteParser.parse(this, body);
      } else if (structuredStatements && matchText("set")) {
        parseBufferSet(body, previous(), "words_set");
      } else if (structuredStatements && matchText("drop")) {
        parseOwnedDrop(body, previous());
      } else if (structuredStatements && checkText("assert")) {
        parseAssertion(body);
      } else if (structuredStatements && SourceCallParser.statementCallAhead(this)) {
        SourceCallParser.parseVoid(this, body);
      } else if (structuredStatements && isAssignmentStart()) {
        parseStructuredAssignment(body);
      } else if (!structuredStatements && valueReturnsAllowed && matchText("return")) {
        SourceResultParser.parseReturn(this, body, previous(), true);
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
        name, exported, entry, test, reversible, coherent, parameters, testCases,
        testTags, returnType, body, line);
  }

  @Override
  protected String signedStatementOperand() {
    return SourceConstantParser.signedStatementOperand(this);
  }

  private void parseBufferSet(
      List<Statement> body, SourceToken start, String operation) {
    expect(Type.LEFT_PAREN, "'(' after " + start.text());
    String buffer = parseExpression(body);
    expect(Type.COMMA, "',' after buffer");
    String index = parseExpression(body);
    expect(Type.COMMA, "',' after buffer index");
    String value = parseExpression(body);
    expect(Type.RIGHT_PAREN, "')' after set arguments");
    expect(Type.SEMICOLON, "';' after set");
    body.add(statement(operation, start.line(), buffer, index, value));
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
    SourceResultParser.parseLocalDeclaration(this, body);
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

  private void parseAssertion(List<Statement> body) {
    if (simpleGlobalAssertionAhead()) {
      body.add(parseStatement());
      return;
    }
    SourceToken start = expectText("assert");
    expect(Type.LEFT_PAREN, "'(' after assert");
    String condition = parseExpression(body);
    expect(Type.RIGHT_PAREN, "')' after assertion");
    expect(Type.SEMICOLON, "';' after assertion");
    body.add(statement("local_expect", start.line(), condition));
  }

  private boolean simpleGlobalAssertionAhead() {
    if (lookaheadType(1) != Type.LEFT_PAREN
        || lookaheadType(2) != Type.IDENTIFIER
        || lookaheadType(3) != Type.EQUAL
        || states.stream().noneMatch(state -> state.name().equals(lookaheadText(2)))) {
      return false;
    }
    int value = lookaheadType(4) == Type.MINUS ? 5 : 4;
    return lookaheadType(value) == Type.NUMBER
        && lookaheadType(value + 1) == Type.RIGHT_PAREN
        && lookaheadType(value + 2) == Type.SEMICOLON;
  }

  private void parseStructuredBlock(List<Statement> body, String owner) {
    if (++blockDepth > MAX_BLOCK_DEPTH) {
      fail(peek(), "source exceeds the 256-block nesting limit");
    }
    try {
      expect(Type.LEFT_BRACE, "'{' before " + owner + " body");
      while (!check(Type.RIGHT_BRACE) && !check(Type.END)) {
        if (checkLocalType()) {
          SourceResultParser.parseLocalDeclaration(this, body);
        } else if (matchText("return")) {
          SourceResultParser.parseReturn(this, body, previous(), valueReturnsAllowed);
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
        } else if (matchText("put")) {
          parseBufferSet(body, previous(), "map_put");
        } else if (matchText("setByte")) {
          parseBufferSet(body, previous(), "bytes_set");
        } else if (matchText("setOutputLength")) {
          SourceOutputEffectParser.parse(this, body, previous());
        } else if (matchText("writeAscii")) {
          SourceAsciiWriteParser.parse(this, body);
        } else if (matchText("set")) {
          parseBufferSet(body, previous(), "words_set");
        } else if (matchText("drop")) {
          parseOwnedDrop(body, previous());
        } else if (checkText("assert")) {
          parseAssertion(body);
        } else if (SourceCallParser.statementCallAhead(this)) {
          SourceCallParser.parseVoid(this, body);
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
      SourceToken type = peek();
      String typeName = SourceValueTypeParser.parse(
          this,
          "variant type in case",
          moduleName != null,
          this::isValueType,
          variants,
          arrays,
          slices);
      expect(Type.DOT, "'.' before variant case");
      SourceToken caseName = expect(Type.IDENTIFIER, "variant case name");
      expect(Type.LEFT_PAREN, "'(' after variant case");
      List<Parameter> bindings = new ArrayList<>();
      if (!check(Type.RIGHT_PAREN)) {
        do {
          String bindingType = SourceValueTypeParser.parse(
              this,
              "payload binding type",
              moduleName != null,
              this::isValueType,
              variants,
              arrays,
              slices);
          bindings.add(new Parameter(
              SourceNames.binding(expect(Type.IDENTIFIER, "payload binding name")),
              bindingType,
              ParameterMode.VALUE));
        } while (match(Type.COMMA));
      }
      expect(Type.RIGHT_PAREN, "')' after payload bindings");
      List<Statement> caseBody = new ArrayList<>();
      parseStructuredBlock(caseBody, "case");
      parsed.add(new MatchCase(typeName, caseName.text(), bindings, caseBody, type.line()));
    }
    expect(Type.RIGHT_BRACE, "'}' after match cases");
    VariantDefinition variant = SourceMatchValidator.validate(
        parsed, start, variants, importedVariants);
    String done = label();
    boolean joinsDone = false;
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
      boolean exits = !selected.body().isEmpty()
          && selected.body().getLast().operation().equals("return_value");
      if (next != null) {
        if (!exits) {
          body.add(statement("jump", selected.line(), done));
          joinsDone = true;
        }
        body.add(statement("label", selected.line(), next));
      }
    }
    if (joinsDone) {
      body.add(statement("label", start.line(), done));
    }
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

  String parseExpression(List<Statement> body) {
    return parseEquality(body);
  }

  private String parseEquality(List<Statement> body) {
    String left = parseComparison(body);
    while (match(Type.EQUAL, Type.NOT_EQUAL)) {
      SourceToken operator = previous();
      left = binary(body, operator, "eq", left, parseComparison(body));
      if (operator.type() == Type.NOT_EQUAL) {
        left = negate(body, operator, left);
      }
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
    String left = parseAnd(body);
    while (match(Type.XOR)) {
      left = binary(body, previous(), "xor", left, parseAnd(body));
    }
    return left;
  }

  private String parseAnd(List<Statement> body) {
    String left = parseAdditive(body);
    while (match(Type.AND)) {
      left = binary(body, previous(), "and", left, parseAdditive(body));
    }
    return left;
  }

  private String parseAdditive(List<Statement> body) {
    String left = parseMultiplicative(body);
    while (match(Type.PLUS, Type.MINUS)) {
      SourceToken operator = previous();
      left = binary(
          body,
          operator,
          operator.type() == Type.PLUS ? "add" : "sub",
          left,
          parseMultiplicative(body));
    }
    return left;
  }

  private String parseMultiplicative(List<Statement> body) {
    String left = parseUnary(body);
    while (match(Type.STAR, Type.SLASH, Type.PERCENT)) {
      SourceToken operator = previous();
      String operation = switch (operator.type()) {
        case STAR -> "mul";
        case SLASH -> "div";
        case PERCENT -> "mod";
        default -> throw new AssertionError();
      };
      left = binary(body, operator, operation, left, parseUnary(body));
    }
    return left;
  }

  private String parseUnary(List<Statement> body) {
    if (!match(Type.NOT)) {
      return parsePrimary(body);
    }
    SourceToken operator = previous();
    return negate(body, operator, parseUnary(body));
  }

  private String negate(List<Statement> body, SourceToken operator, String value) {
    String truth = temporary();
    body.add(statement("local_boolean", operator.line(), truth, "1"));
    return binary(body, operator, "xor", value, truth);
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
        String maxBytes = regionLimit();
        expect(Type.COMMA, "',' after region byte limit");
        String maxObjects = regionLimit();
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
          .findFirst()
          .orElseGet(() -> importedVariants.stream()
              .filter(candidate -> candidate.name().equals(typeName))
              .findFirst()
              .orElse(null));
      String caseName = null;
      boolean array = arrays.stream().anyMatch(candidate -> candidate.name().equals(typeName));
      if (moduleName != null && !record && !array && variant == null) {
        record = true;
      }
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
    if (matchText("done")) {
      String result = temporary();
      body.add(statement("local_done", start.line(), result));
      return result;
    }
    if (checkTextIn(NULL_LIKE_VALUES)) {
      fail(start, "null-like values do not exist; use an explicit presence type");
    }
    if (checkText("true") || checkText("false")) {
      SourceToken value = advance();
      String result = temporary();
      body.add(statement(
          "local_boolean", value.line(), result, value.text().equals("true") ? "1" : "0"));
      return result;
    }
    if (match(Type.IDENTIFIER)) {
      String reference = start.text();
      if (SourceConstantParser.qualifiedReferenceAhead(this)) {
        reference = SourceConstantParser.qualifiedReference(this, start);
        return emitConstant(body, start, resolveConstant(reference, start, true));
      }
      ConstantDefinition constant = resolveConstant(reference, start, false);
      if (constant != null) {
        return emitConstant(body, start, constant);
      }
      if (SourceCallParser.qualifiedCallAhead(this)) {
        reference = SourceCallParser.qualifiedReference(this, start);
        return SourceCallParser.parse(this, body, start, reference);
      }
      if (match(Type.LEFT_PAREN)) {
        return SourceCallParser.parse(this, body, start, reference);
      }
      String result = temporary();
      body.add(statement("local_read", start.line(), result, start.text()));
      return parsePostfix(body, result, start.line());
    }
    fail(start, "expected expression");
    throw new AssertionError("unreachable");
  }

  String parsePostfix(List<Statement> body, String source, int line) {
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

  private String regionLimit() {
    if (check(Type.IDENTIFIER)) {
      SourceToken name = advance();
      ConstantDefinition definition = resolveRequiredConstant(name.text(), name);
      if (!definition.type().equals("long")) {
        fail(name, "region limit requires a signed constant");
      }
      return Long.toString(definition.value());
    }

    return signedNumber();
  }

  String constant(List<Statement> body, SourceToken source, String value) {
    String result = temporary();
    body.add(statement("local_const", source.line(), result, value));
    return result;
  }

  ConstantDefinition resolveConstant(
      String name, SourceToken source, boolean required) {
    return constantEnvironment.resolve(name, source, required);
  }

  ConstantDefinition resolveRequiredConstant(
      String name, SourceToken source) {
    return resolveConstant(name, source, true);
  }

  private String emitConstant(
      List<Statement> body, SourceToken source, ConstantDefinition definition) {
    String result = temporary();
    String operation = definition.type().equals("boolean")
        ? "local_boolean" : "local_const";
    body.add(statement(
        operation, source.line(), result, Long.toString(definition.value())));
    return result;
  }

  String binary(
      List<Statement> body, SourceToken source, String operator, String left, String right) {
    String result = temporary();
    body.add(statement("local_binary", source.line(), result, operator, left, right));
    return result;
  }

  String parseValueType(String description) {
    return SourceValueTypeParser.parse(
        this,
        description,
        moduleName != null,
        this::isValueType,
        variants,
        arrays,
        slices);
  }

  private boolean checkLocalType() {
    return check(Type.IDENTIFIER)
        && (peek().text().equals("Slot") || isValueType(peek().text())
            || (moduleName != null
                && (isNominalName(peek().text())
                    || SourceValueTypeParser.isQualifiedLocalDeclaration(this))));
  }

  private static boolean isNominalName(String name) {
    return !name.isEmpty() && name.charAt(0) >= 'A' && name.charAt(0) <= 'Z';
  }

  private boolean isValueType(String name) {
    return name.equals("long") || name.equals("boolean") || name.equals("Done")
        || name.equals("region") || name.equals("words") || name.equals("bytes")
        || name.equals("byteview") || name.equals("longmap") || name.equals("utf8")
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

  String temporary() {
    return "$t" + temporarySequence++;
  }

  private String label() {
    return "$l" + labelSequence++;
  }

  private record LoopLabels(String repeat, String done) {}

}
