/// <reference types="tree-sitter-cli/dsl" />
// @ts-check

module.exports = grammar({
  name: 'wheeler',

  extras: $ => [/[\s\uFEFF\u2060\u200B]/, $.line_comment, $.block_comment],
  word: $ => $.identifier,

  rules: {
    source_file: $ => $.class_declaration,

    class_declaration: $ => seq(
      optional('public'),
      field('domain', $.computation_domain),
      'class',
      field('name', $.identifier),
      field('body', $.class_body),
    ),

    computation_domain: _ => choice('classical', 'quantum', 'hybrid'),
    class_body: $ => seq('{', repeat($.member_declaration), '}'),
    member_declaration: $ => seq(
      repeat($.visibility_modifier),
      choice(
        $.record_declaration,
        $.variant_declaration,
        $.state_declaration,
        $.qreg_declaration,
        $.method_declaration,
      ),
    ),

    record_declaration: $ => seq(
      'record',
      field('name', $.identifier),
      '(',
      $.record_component,
      repeat(seq(',', $.record_component)),
      ')',
      '{',
      '}',
    ),
    record_component: $ => seq(
      field('type', $.value_type),
      field('name', $.identifier),
    ),

    variant_declaration: $ => seq(
      'variant',
      field('name', $.identifier),
      '{',
      repeat1($.variant_case_declaration),
      '}',
    ),
    variant_case_declaration: $ => seq(
      'case',
      field('name', $.identifier),
      '(',
      optional(seq($.record_component, repeat(seq(',', $.record_component)))),
      ')',
      ';',
    ),

    state_declaration: $ => seq(
      'state',
      'long',
      field('name', $.identifier),
      '=',
      field('value', $.integer_literal),
      ';',
    ),

    qreg_declaration: $ => seq(
      'qreg',
      field('name', $.identifier),
      '=',
      'new',
      'qreg',
      '(',
      field('size', $.integer_literal),
      ')',
      ';',
    ),

    method_declaration: $ => seq(
      repeat($.method_modifier),
      field('return_type', choice('void', $.value_type)),
      field('name', $.identifier),
      field('parameters', $.parameter_list),
      field('body', $.block),
    ),

    visibility_modifier: _ => choice('public', 'private', 'protected'),
    method_modifier: _ => choice('static', 'entry', 'rev', 'coherent', 'unitary'),
    parameter_list: $ => seq(
      '(',
      optional(seq($.parameter, repeat(seq(',', $.parameter)))),
      ')',
    ),
    value_type: $ => seq(
      choice('long', 'boolean', alias($.identifier, $.type_identifier)),
      optional($.array_extent),
    ),
    array_extent: $ => seq('[', optional(field('length', $.integer_literal)), ']'),
    parameter: $ => seq(
      field('type', $.value_type),
      field('name', $.identifier),
    ),
    block: $ => seq('{', repeat($.statement), '}'),

    statement: $ => choice(
      $.local_declaration,
      $.assignment_statement,
      $.assert_statement,
      $.call_statement,
      $.coherent_apply_statement,
      $.reverse_statement,
      $.if_statement,
      $.while_statement,
      $.for_statement,
      $.match_statement,
      $.break_statement,
      $.continue_statement,
      $.return_statement,
    ),

    match_statement: $ => seq(
      'match',
      '(',
      field('value', $.expression),
      ')',
      '{',
      repeat1($.match_case),
      '}',
    ),
    match_case: $ => seq(
      'case',
      field('type', $.identifier),
      '.',
      field('case', $.identifier),
      field('bindings', $.parameter_list),
      field('body', $.block),
    ),

    return_statement: $ => seq('return', $.expression, ';'),
    break_statement: _ => seq('break', ';'),
    continue_statement: _ => seq('continue', ';'),

    local_declaration: $ => seq(
      field('type', $.value_type),
      field('name', $.identifier),
      '=',
      field('value', $.expression),
      ';',
    ),

    if_statement: $ => seq(
      'if',
      '(',
      field('condition', $.expression),
      ')',
      field('consequence', $.block),
      optional(seq('else', field('alternative', $.block))),
    ),

    for_statement: $ => seq(
      'for',
      '(',
      field('initializer', $.local_declaration),
      field('condition', $.expression),
      ';',
      field('update', $.assignment_expression),
      ')',
      'limit',
      field('limit', $.expression),
      field('body', $.block),
    ),
    assignment_expression: $ => seq(
      field('target', $.identifier),
      field('operator', choice('=', '+=', '-=', '^=')),
      field('value', $.expression),
    ),

    while_statement: $ => seq(
      'while',
      '(',
      field('condition', $.expression),
      ')',
      'limit',
      field('limit', $.expression),
      field('body', $.block),
    ),

    assignment_statement: $ => seq(
      field('left', $.identifier),
      field('operator', choice('=', '+=', '-=', '^=')),
      field('right', $.expression),
      ';',
    ),

    assert_statement: $ => seq('assert', $.identifier, '==', $.integer_literal, ';'),
    call_statement: $ => seq($.call_expression, ';'),
    coherent_apply_statement: $ => seq(
      field('register', $.identifier),
      '.',
      'apply',
      '(',
      field('method', $.identifier),
      ')',
      ';',
    ),
    reverse_statement: $ => seq('reverse', choice($.block, seq($.call_expression, ';'))),

    expression: $ => choice(
      $.boolean_literal,
      $.integer_literal,
      $.number_literal,
      $.identifier,
      $.call_expression,
      $.record_creation,
      $.field_expression,
      $.array_access_expression,
      $.parenthesized_expression,
      $.binary_expression,
    ),
    parenthesized_expression: $ => seq('(', $.expression, ')'),
    binary_expression: $ => choice(
      prec.left(1, seq($.expression, field('operator', '=='), $.expression)),
      prec.left(2, seq($.expression, field('operator', '<'), $.expression)),
      prec.left(3, seq($.expression, field('operator', '^'), $.expression)),
      prec.left(4, seq($.expression, field('operator', choice('+', '-')), $.expression)),
    ),
    record_creation: $ => seq(
      'new',
      field('type', $.value_type),
      optional(seq('.', field('case', $.identifier))),
      '(',
      optional($.argument_list),
      ')',
    ),
    field_expression: $ => prec(5, seq(
      field('value', $.expression),
      '.',
      field('field', $.identifier),
    )),
    array_access_expression: $ => prec(5, seq(
      field('array', $.expression),
      '[',
      field('index', $.expression),
      ']',
    )),
    call_expression: $ => seq(
      field('function', $.identifier),
      '(',
      optional($.argument_list),
      ')',
    ),
    argument_list: $ => seq($.expression, repeat(seq(',', $.expression))),

    boolean_literal: _ => choice('true', 'false'),
    integer_literal: _ => token(choice(
      /-?[0-9][0-9_]*/,
      /-?0[xX][0-9a-fA-F][0-9a-fA-F_]*/,
      /-?0[bB][01][01_]*/,
    )),
    number_literal: _ => token(/-?[0-9][0-9_]*\.[0-9][0-9_]*(?:[eE][+-]?[0-9]+)?/),
    type_identifier: _ => /[A-Za-z_][A-Za-z0-9_]*/,
    identifier: _ => /[A-Za-z_][A-Za-z0-9_]*/,
    line_comment: _ => token(seq('//', /[^\n]*/)),
    block_comment: _ => token(seq('/*', /[^*]*\*+([^/*][^*]*\*+)*/, '/')),
  },
});
