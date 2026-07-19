package com.typeobject.wheeler.compiler;

import com.typeobject.wheeler.compiler.SourceConstantParser.ConstantValue;
import com.typeobject.wheeler.compiler.SourceModel.ProofDeclaration;
import com.typeobject.wheeler.compiler.SourceModel.QuantumRegisterSource;
import com.typeobject.wheeler.compiler.SourceModel.State;
import com.typeobject.wheeler.compiler.SourceToken.Type;

/** Parses state, quantum-register, and theorem member declarations. */
final class SourceScalarMemberParser {
  private SourceScalarMemberParser() {}

  static State parseState(SourceParser parser, SourceToken start) {
    parser.expectText("long");
    String name = parser.expect(Type.IDENTIFIER, "state name").text();
    parser.expect(Type.ASSIGN, "'=' in state declaration");
    ConstantValue value = SourceConstantParser.parseValue(
        parser, parser::resolveRequiredConstant);
    if (!value.type().equals("long")) {
      SourceTokenCursor.fail(start, "state initializer must be a long constant");
    }
    parser.expect(Type.SEMICOLON, "';' after state declaration");
    return new State(name, value.value(), start.line());
  }

  static QuantumRegisterSource parseQuantumRegister(
      SourceParser parser, SourceToken start) {
    String name = parser.expect(Type.IDENTIFIER, "quantum register name").text();
    parser.expect(Type.ASSIGN, "'=' in qreg declaration");
    parser.expectText("new");
    parser.expectText("qreg");
    parser.expect(Type.LEFT_PAREN, "'(' after new qreg");
    ConstantValue size = SourceConstantParser.parseValue(
        parser, parser::resolveRequiredConstant);
    if (!size.type().equals("long")) {
      SourceTokenCursor.fail(start, "qreg size must be a long constant");
    }
    long qubits = size.value();
    if (qubits <= 0 || qubits > 62) {
      SourceTokenCursor.fail(start, "qreg size must be between 1 and 62");
    }
    parser.expect(Type.RIGHT_PAREN, "')' after qreg size");
    parser.expect(Type.SEMICOLON, "';' after qreg declaration");
    return new QuantumRegisterSource(name, (int) qubits, start.line());
  }

  static ProofDeclaration parseTheorem(SourceParser parser, SourceToken start) {
    String name = parser.expect(Type.IDENTIFIER, "theorem name").text();
    parser.expectText("proves");
    SourceToken rule = parser.expect(Type.IDENTIFIER, "proof rule");
    if (!rule.text().equals("inverse")
        && !rule.text().equals("adjoint")
        && !rule.text().equals("equivalent")
        && !rule.text().equals("steps")) {
      SourceTokenCursor.fail(
          rule, "expected inverse, adjoint, equivalent, or steps proof rule");
    }
    parser.expect(Type.LEFT_PAREN, "'(' after " + rule.text());
    String subject = parser.expect(Type.IDENTIFIER, "proof subject name").text();
    String related = null;
    Long argument = null;
    if (rule.text().equals("equivalent")) {
      parser.expect(Type.COMMA, "',' between equivalent circuits");
      related = parser.expect(Type.IDENTIFIER, "related circuit name").text();
    } else if (rule.text().equals("steps")) {
      parser.expect(Type.COMMA, "',' before the step bound");
      ConstantValue bound = SourceConstantParser.parseValue(
          parser, parser::resolveRequiredConstant);
      if (!bound.type().equals("long") || bound.value() <= 0) {
        SourceTokenCursor.fail(start, "step bound must be a positive long constant");
      }
      argument = bound.value();
    }
    parser.expect(Type.RIGHT_PAREN, "')' after proof subject");
    parser.expect(Type.SEMICOLON, "';' after theorem");
    return new ProofDeclaration(
        name, rule.text(), subject, related, argument, start.line());
  }
}
