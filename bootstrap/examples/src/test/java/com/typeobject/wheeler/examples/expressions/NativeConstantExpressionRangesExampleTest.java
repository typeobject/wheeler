package com.typeobject.wheeler.examples.expressions;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.compiler.CompilerException;
import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.MachineSnapshot;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import com.typeobject.wheeler.examples.CompilerSources;
import java.nio.charset.StandardCharsets;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.stream.Stream;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.Arguments;
import org.junit.jupiter.params.provider.MethodSource;
import org.junit.jupiter.params.provider.ValueSource;

/** Exact expression windows share declaration precedence and consume counted constants only. */
final class NativeConstantExpressionRangesExampleTest {
  private static Program evaluator;

  @BeforeAll
  static void compileEvaluator() throws Exception {
    evaluator = program("");
  }

  static Stream<Arguments> expressions() {
    return Stream.of(
        Arguments.of("1 + 2 * 3", true),
        Arguments.of("(1 + 2) * 3", true),
        Arguments.of("20 - 6 - 3", true),
        Arguments.of("100 / 10 / 2", true),
        Arguments.of("11 % 4 % 2", true),
        Arguments.of("31 & 6 + 1", true),
        Arguments.of("16 ^ 12 & 3", true),
        Arguments.of("16 ^ 12 ^ 3", true),
        Arguments.of("1 + 2 < 4 ^ 1", false),
        Arguments.of("1 < 2 == true", false),
        Arguments.of("1 == 1 == true", false),
        Arguments.of("true == true == false", false),
        Arguments.of("!(1 == 2)", false),
        Arguments.of("!!false", false),
        Arguments.of("-9223372036854775808", true),
        Arguments.of("9223372036854775807 - 1", true),
        Arguments.of("-9 / 2", true),
        Arguments.of("-9 % 2", true),
        Arguments.of("-9223372036854775808 % -1", true),
        Arguments.of("rotateRight32(1 + 2, 1)", true),
        Arguments.of("rotateRight32(4294967295, 31)", true),
        Arguments.of("BASE * 2 + 1", true),
        Arguments.of("fixture.bounds::BASE + BASE", true),
        Arguments.of("FLAG == (BASE < 8)", false),
        Arguments.of("!fixture.bounds::FLAG", false),
        Arguments.of("rotateRight32(BASE, BASE - 6)", true));
  }

  @ParameterizedTest
  @MethodSource("expressions")
  void agreesWithDeclarationsWithoutBorrowingTheirDependencySource(String expression, boolean signed) {
    long expected = oracle(expression, signed);
    var machine = machine(evaluator, expression);
    MachineSnapshot initial = machine.snapshot();
    MachineSnapshot prepared = prepare(machine);
    publish(machine);
    assertEquals(1, machine.global("valid"));
    assertEquals(expected, machine.global("value"));
    assertEquals(signed ? 1 : 0, machine.global("signed"));
    assertEquals(machine.global("end"), machine.global("next"));
    assertEquals(prepared.buffers(), machine.snapshot().buffers().subList(0, prepared.buffers().size()));
    finishAndReplay(machine, initial);
  }

  @ParameterizedTest
  @ValueSource(strings = {
      "1 2", "BASE BASE", "BASE +", "1 = 1", "1 = = 1", "1 = /* gap */ = 1",
      "1 ==", "1 < 2 < 3", "true & false", "true ^ false", "true + 1", "1 == true",
      "!1", "-BASE", "(1 + 2", "1 + 2)", "unknown", "private.bounds::BASE",
      "rotateRight32(1, -1)", "rotateRight32(1, 32)", "rotateRight32(true, 1)",
      "rotateRight32(1, true)", "rotateRight32(1)", "1 / 0", "1 % 0",
      "9223372036854775808", "-9223372036854775809"
  })
  void rejectsInvalidSyntaxTypesAndValidPrefixesWithoutChangingInputs(String expression) {
    assertThrows(CompilerException.class, () -> oracle(expression, true));
    var machine = machine(evaluator, expression);
    MachineSnapshot initial = machine.snapshot();
    MachineSnapshot prepared = prepare(machine);
    publish(machine);
    assertEquals(0, machine.global("valid"));
    assertEquals(prepared.buffers(), machine.snapshot().buffers().subList(0, prepared.buffers().size()));
    finishAndReplay(machine, initial);
  }

  @ParameterizedTest
  @ValueSource(strings = {
      "firstDeclaration = -1;", "firstDeclaration = 1;", "memberStart = -1;",
      "memberStart = 9223372036854775807;", "expressionStart = -1;",
      "expressionStart = expressionEnd;", "expressionEnd = 9223372036854775807;",
      "expressionEnd = MAX_COMPILER_TOKENS + 1;"
  })
  void rejectsInvalidWindowsBeforeAllocatingEvaluationState(String change) throws Exception {
    var machine = machine(program(change), "BASE + 1");
    MachineSnapshot initial = machine.snapshot();
    MachineSnapshot prepared = prepare(machine);
    assertThrows(VmTrap.class, machine::run);
    assertEquals(0, machine.global("published"));
    assertEquals(prepared.buffers(), machine.snapshot().buffers());
    assertEquals(prepared.regions(), machine.snapshot().regions());
    MachineSnapshot rejected = machine.snapshot();
    rewind(machine, initial);
    assertThrows(VmTrap.class, machine::run);
    assertEquals(rejected, machine.snapshot());
    rewind(machine, initial);
  }

  @ParameterizedTest
  @ValueSource(strings = {"9223372036854775807 + 1", "-9223372036854775808 - 1",
      "9223372036854775807 * 2", "-9223372036854775808 / -1"})
  void rejectsCheckedArithmeticOverflowAndReplaysTheSameTrap(String expression) {
    assertThrows(CompilerException.class, () -> oracle(expression, true));
    var machine = machine(evaluator, expression);
    MachineSnapshot initial = machine.snapshot();
    MachineSnapshot prepared = prepare(machine);
    assertThrows(VmTrap.class, machine::run);
    assertEquals(0, machine.global("published"));
    assertEquals(prepared.buffers(), machine.snapshot().buffers().subList(0, prepared.buffers().size()));
    MachineSnapshot rejected = machine.snapshot();
    rewind(machine, initial);
    assertThrows(VmTrap.class, machine::run);
    assertEquals(rejected, machine.snapshot());
    rewind(machine, initial);
  }

  private static long oracle(String expression, boolean signed) {
    String dependency = """
        module fixture.bounds;
        classical class Bounds {
          public const long BASE = 7;
          public const boolean FLAG = true;
        }
        """;
    String source = """
        module fixture.expression;
        import fixture.bounds;
        classical class Expression {
          state long observed = 0;
          const %s RESULT = %s;
          entry void main() { %s }
        }
        """.formatted(signed ? "long" : "boolean", expression,
            signed ? "observed = RESULT;" : "if (RESULT) { observed = 1; }");
    var machine = new VirtualMachine(new WheelerCompiler().compileModuleFiles(
        Map.of("Bounds.w", dependency, "Expression.w", source), "fixture.expression"));
    machine.run();
    return machine.global("observed");
  }

  private static VirtualMachine machine(Program program, String expression) {
    String source = "// café 𝄞\n discarded " + expression + " ignored";
    return new VirtualMachine(program, source.getBytes(StandardCharsets.UTF_8));
  }

  private static MachineSnapshot prepare(VirtualMachine machine) {
    while (machine.global("prepared") == 0) {
      machine.step();
    }
    return machine.snapshot();
  }

  private static void publish(VirtualMachine machine) {
    while (machine.global("published") == 0) {
      machine.step();
    }
  }

  private static void finishAndReplay(VirtualMachine machine, MachineSnapshot initial) {
    machine.run();
    MachineSnapshot terminal = machine.snapshot();
    rewind(machine, initial);
    machine.run();
    assertEquals(terminal, machine.snapshot());
    rewind(machine, initial);
  }

  private static void rewind(VirtualMachine machine, MachineSnapshot initial) {
    while (machine.historySize() > 0) {
      machine.rewindOne();
    }
    assertEquals(initial, machine.snapshot());
  }

  private static Program program(String change) throws Exception {
    var sources = new LinkedHashMap<>(CompilerSources.moduleClosure("wheeler.compiler.constant_expressions"));
    sources.putAll(CompilerSources.moduleClosure("wheeler.compiler.module_linker"));
    String names = "BASEFLAGfixture.bounds";
    var nameWrites = new StringBuilder();
    for (int index = 0; index < names.length(); index++) {
      nameWrites.append("setByte(names, ").append(index).append(", ")
          .append((int) names.charAt(index)).append(");\n");
    }
    sources.put("ExpressionRanges.w", """
        module example.expression_ranges;
        import wheeler.compiler.compiler_token_limits;
        import wheeler.compiler.constant_expressions;
        import wheeler.compiler.constant_product_schema;
        import wheeler.compiler.module_linker;
        classical class ExpressionRanges {
          private const long NAME_BYTES = %d;
          private const long TOKEN_COLUMNS = 3;
          private const long WORD_BYTES = 8;
          private const long ARENA_BYTES = NAME_BYTES
            + (TOKEN_COLUMNS * MAX_COMPILER_TOKENS + CONSTANT_PRODUCT_ROWS) * WORD_BYTES;
          private const long ARENA_ALLOCATIONS = TOKEN_COLUMNS + 2;
          private const long BASE_NAME_BYTES = 4;
          private const long FLAG_NAME_BYTES = 4;
          private const long MODULE_NAME_START = BASE_NAME_BYTES + FLAG_NAME_BYTES;
          private const long MODULE_NAME_BYTES = NAME_BYTES - MODULE_NAME_START;
          private const long CONSTANT_FIELDS = 7;
          private const long COUNT_WORDS = 1;
          private const long FIRST_CONSTANT = COUNT_WORDS;
          private const long SECOND_CONSTANT = FIRST_CONSTANT + CONSTANT_FIELDS;
          private const long NAME_START_FIELD = 0;
          private const long NAME_LENGTH_FIELD = 1;
          private const long TYPE_FIELD = 2;
          private const long VALUE_FIELD = 3;
          private const long RESOLVED_FIELD = 4;
          private const long MODULE_START_FIELD = 5;
          private const long MODULE_LENGTH_FIELD = 6;
          state long prepared = 0;
          state long published = 0;
          state long value = 0;
          state long next = -1;
          state long signed = 0;
          state long valid = 0;
          state long end = -1;
          entry void main(borrow utf8 source) {
            region arena = new region(/* bytes= */ ARENA_BYTES, /* allocations= */ ARENA_ALLOCATIONS);
            words kinds = allocate(arena, MAX_COMPILER_TOKENS);
            words starts = allocate(arena, MAX_COMPILER_TOKENS);
            words lengths = allocate(arena, MAX_COMPILER_TOKENS);
            words rows = allocate(arena, CONSTANT_PRODUCT_ROWS);
            bytes names = allocateBytes(arena, NAME_BYTES);
            %s
            set(rows, 0, 2);
            set(rows, FIRST_CONSTANT + NAME_LENGTH_FIELD, BASE_NAME_BYTES);
            set(rows, FIRST_CONSTANT + TYPE_FIELD, /* signed= */ 1);
            set(rows, FIRST_CONSTANT + VALUE_FIELD, /* BASE= */ 7);
            set(rows, FIRST_CONSTANT + RESOLVED_FIELD, 1);
            set(rows, FIRST_CONSTANT + MODULE_START_FIELD, MODULE_NAME_START);
            set(rows, FIRST_CONSTANT + MODULE_LENGTH_FIELD, MODULE_NAME_BYTES);
            set(rows, SECOND_CONSTANT + NAME_START_FIELD, BASE_NAME_BYTES);
            set(rows, SECOND_CONSTANT + NAME_LENGTH_FIELD, FLAG_NAME_BYTES);
            set(rows, SECOND_CONSTANT + TYPE_FIELD, /* Boolean= */ 2);
            set(rows, SECOND_CONSTANT + VALUE_FIELD, /* FLAG= */ 1);
            set(rows, SECOND_CONSTANT + RESOLVED_FIELD, 1);
            set(rows, SECOND_CONSTANT + MODULE_START_FIELD, MODULE_NAME_START);
            set(rows, SECOND_CONSTANT + MODULE_LENGTH_FIELD, MODULE_NAME_BYTES);
            set(rows, CONSTANT_PRODUCT_ROWS - 1, 223);
            long count = scanSemanticTokens(source, kinds, starts, lengths);
            assert(1 < count);
            long firstDeclaration = 0;
            long memberStart = 0;
            long expressionStart = 1;
            long expressionEnd = count - 1;
            %s
            end = expressionEnd;
            prepared = 1;
            ExpressionValue result = evaluateScalarExpressionWithProducts(
              source, starts, lengths, firstDeclaration, memberStart,
              expressionStart, expressionEnd, names, rows
            );
            value = result.value;
            next = result.next;
            if (result.signed) { signed = 1; }
            if (result.valid) { valid = 1; }
            published = 1;
            drop(names);
            drop(rows);
            drop(lengths);
            drop(starts);
            drop(kinds);
            drop(arena);
          }
        }
        """.formatted(names.length(), nameWrites, change));
    return new WheelerCompiler().compileModuleFiles(sources, "example.expression_ranges");
  }
}
