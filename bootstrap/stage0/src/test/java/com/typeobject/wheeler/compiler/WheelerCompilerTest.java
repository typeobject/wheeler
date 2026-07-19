package com.typeobject.wheeler.compiler;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.core.bytecode.BytecodeReader;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.Opcode;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.bytecode.ValueType;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import java.nio.charset.StandardCharsets;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Conformance tests for source-to-bytecode lowering across the accepted language profile. */
class WheelerCompilerTest {
  private static final String COUNTER = """
      classical class Counter {
        state long count = 0;

        rev void increment() {
          count += 1;
        }

        entry void main() {
          increment();
          increment();
          assert(count == 2);
          reverse {
            increment();
            increment();
          }
          assert(count == 0);
        }
      }
      """;

  @Test
  void compactFormattingHasTheSameSemantics() {
    String compact = "classical class Tiny{state long x=0;rev void flip(){x^=1;}"
        + "entry void main(){flip();reverse flip();assert(x==0);}}";

    Program program = new WheelerCompiler().compile(compact);
    VirtualMachine machine = new VirtualMachine(program);
    machine.run();

    assertEquals(0, machine.global("x"));
  }

  @Test
  void requiresOneCallShapedAssertionForm() {
    WheelerCompiler compiler = new WheelerCompiler();
    CompilerException bare = assertThrows(CompilerException.class, () -> compiler.compile(
        "classical class Bad { state long value = 1; "
            + "entry void main() { assert value == 1; } }"));
    CompilerException duplicate = assertThrows(CompilerException.class, () -> compiler.compile(
        "classical class Bad { state long value = 1; "
            + "entry void main() { assertEquals(value, 1); } }"));
    CompilerException empty = assertThrows(CompilerException.class, () -> compiler.compile(
        "classical class Bad { entry void main() { assert(); } }"));
    CompilerException multiple = assertThrows(CompilerException.class, () -> compiler.compile(
        "classical class Bad { state long value = 1; "
            + "entry void main() { assert(value == 1, value == 1); } }"));
    CompilerException nonBoolean = assertThrows(CompilerException.class, () -> compiler.compile(
        "classical class Bad { state long value = 1; entry void main() { assert(value); } }"));

    assertTrue(bare.getMessage().contains("expected '(' after assert"));
    assertTrue(duplicate.getMessage().contains("void call signature mismatch: assertEquals"));
    assertTrue(empty.getMessage().contains("expected expression"));
    assertTrue(multiple.getMessage().contains("expected ')' after assertion"));
    assertTrue(nonBoolean.getMessage().contains("expected boolean expression"));
  }

  @Test
  void compilesAndRunsCounter() {
    WheelerCompiler compiler = new WheelerCompiler();
    Program program = compiler.compile(COUNTER);
    VirtualMachine machine = new VirtualMachine(program);

    machine.run();

    assertEquals(0, machine.global("count"));
    assertEquals(Opcode.ADD_CONST, program.function(0).forward().getFirst().opcode());
    assertEquals(Opcode.SUB_CONST, program.function(0).inverse().getFirst().opcode());
  }

  @Test
  void discoversAndCompilesIndependentSourceTests() {
    String source = """
        classical class Laws {
          state long value = 0;
          boolean observe(boolean input) { value += 1; return input; }
          test void beta() { assert(value == 1); }
          test void alpha() { assert(value == 0); }
          test void flag(boolean input) cases(false, true) {
            if (input) { value = 1; } else { value = 0; }
            assert(observe(input) == input);
          }
          test void remembers(long input) cases(-1, 0, 2) {
            value = input;
            assert(input == value);
            assert(input < input + 1);
          }
          entry void main() { value += 2; }
        }
        """;

    WheelerCompiler compiler = new WheelerCompiler();
    List<WheelerCompiler.TestCase> tests = compiler.compileTests(source);

    assertEquals(
        List.of(
            "alpha", "beta", "flag[0]", "flag[1]",
            "remembers[0]", "remembers[1]", "remembers[2]"),
        tests.stream().map(WheelerCompiler.TestCase::name).toList());
    new VirtualMachine(tests.getFirst().program()).run();
    assertThrows(VmTrap.class, () -> new VirtualMachine(tests.get(1).program()).run());
    assertTrue(tests.get(2).program().functions().stream()
        .flatMap(function -> function.forward().stream())
        .anyMatch(instruction -> instruction.opcode() == Opcode.EXPECT_TRUE));
    for (int index = 0; index < 2; index++) {
      VirtualMachine flag = new VirtualMachine(tests.get(index + 2).program());
      flag.run();
      assertEquals(index + 1, flag.global("value"));
    }
    for (int index = 0; index < 3; index++) {
      VirtualMachine parameterized = new VirtualMachine(tests.get(index + 4).program());
      parameterized.run();
      assertEquals(List.of(-1L, 0L, 2L).get(index), parameterized.global("value"));
    }
    Program production = compiler.compile(source);
    assertEquals(2, production.functions().size());
    VirtualMachine ordinary = new VirtualMachine(production);
    ordinary.run();
    assertEquals(2, ordinary.global("value"));

    Program falseAssertion = compiler.compileTests("""
        classical class FalseAssertion {
          test void rejects(boolean input) cases(false) { assert(input); }
        }
        """).getFirst().program();
    VmTrap trap = assertThrows(
        VmTrap.class, () -> new VirtualMachine(falseAssertion).run());
    assertEquals(VmTrap.Code.ASSERTION, trap.code());
    assertEquals("Assertion failed", trap.getMessage());
  }

  @Test
  void compilesRootModuleTestsAgainstExactDependencies() {
    String dependency = """
        module laws.math;
        classical class Math {
          public long two() { return 2; }
        }
        """;
    String root = """
        module laws.main;
        import laws.math;
        classical class Main {
          state long result = 0;
          test void imported() {
            result = laws.math::two();
            assert(result == 2);
          }
          entry void main() { result = 1; }
        }
        """;

    List<WheelerCompiler.TestCase> tests = new WheelerCompiler().compilePackageTests(
        Map.of("src/Main.w", root), Map.of("vendor/Math.w", dependency), "laws.main");

    assertEquals(List.of("laws.main::imported"), tests.stream().map(
        WheelerCompiler.TestCase::name).toList());
    VirtualMachine machine = new VirtualMachine(tests.getFirst().program());
    machine.run();
    assertEquals(2, machine.global("result"));
  }

  @Test
  void rejectsUnsupportedTestShapes() {
    WheelerCompiler compiler = new WheelerCompiler();

    assertThrows(CompilerException.class, () -> compiler.compileTests(
        "classical class Bad { test void row(long value) {} }"));
    assertThrows(CompilerException.class, () -> compiler.compileTests(
        "quantum class Bad { test void measured() {} }"));
    assertThrows(CompilerException.class, () -> compiler.compileTests(
        "classical class Bad { test void row(long value) cases(1, 1) {} }"));
    assertThrows(CompilerException.class, () -> compiler.compileTests(
        "classical class Bad { test void row(boolean value) cases(maybe) {} }"));
    assertThrows(CompilerException.class, () -> compiler.compile(
        "classical class Bad { test rev void confused() {} entry void main() {} }"));
  }

  @Test
  void linksSortedPublicClassicalModulesDeterministically() {
    String arithmetic = """
        module bootstrap.arithmetic;
        classical class Arithmetic {
          private long add(long left, long right) { return left + right; }
          public long twice(long value) { return add(value, value); }
        }
        """;
    String root = """
        module bootstrap.main;
        import bootstrap.arithmetic;
        classical class Main {
          state long result = 0;
          entry void main() {
            result = bootstrap.arithmetic::twice(9);
            assert(result == 18);
          }
        }
        """;
    WheelerCompiler compiler = new WheelerCompiler();
    Map<String, String> first = new LinkedHashMap<>();
    first.put("bootstrap.main", root);
    first.put("bootstrap.arithmetic", arithmetic);
    Map<String, String> second = new LinkedHashMap<>();
    second.put("bootstrap.arithmetic", arithmetic);
    second.put("bootstrap.main", root);

    byte[] firstArtifact = compiler.compileModulesToBytecode(first, "bootstrap.main");
    byte[] secondArtifact = compiler.compileModulesToBytecode(second, "bootstrap.main");
    VirtualMachine machine = new VirtualMachine(new BytecodeReader().read(firstArtifact));
    machine.run();

    assertArrayEquals(firstArtifact, secondArtifact);
    assertEquals(18, machine.global("result"));
  }

  @Test
  void qualifiedCallsResolveCollidingDirectExports() {
    String left = """
        module side.left;
        classical class Left {
          public record Value(long data) {}
          public Value make() { return new Value(7); }
        }
        """;
    String right = """
        module side.right;
        classical class Right {
          public record Value(long data) {}
          public Value make() { return new Value(11); }
        }
        """;
    String root = """
        module side.root;
        import side.left;
        import side.right;
        classical class Root {
          state long result = 0;
          entry void main() {
            side.left::Value left = side.left::make();
            side.right::Value right = side.right::make();
            result = left.data + right.data;
            assert(result == 18);
          }
        }
        """;
    VirtualMachine machine = new VirtualMachine(new WheelerCompiler().compileModules(
        Map.of("side.left", left, "side.right", right, "side.root", root),
        "side.root"));

    machine.run();

    assertEquals(18, machine.global("result"));
  }

  @Test
  void compilesEntrylessModuleLibrariesWithAnInertArtifactEntry() {
    String library = """
        module demo.math;
        classical class Math {
          public long twice(long value) { return value + value; }
        }
        """;

    Program program = new WheelerCompiler().compileLibraryModuleFiles(
        Map.of("src/Math.w", library), "demo.math");

    assertEquals("$library", program.function(program.entryFunctionId()).name());
    assertEquals(Opcode.HALT, program.function(program.entryFunctionId()).forward()
        .getFirst().opcode());
    assertTrue(program.functions().stream().anyMatch(
        function -> function.name().equals("demo.math::twice")));

    String root = """
        module demo.main;
        import demo.math;
        classical class Main {
          state long result = 0;
          entry void main() { result = twice(4); assert(result == 8); }
        }
        """;
    String unused = """
        module demo.unused;
        classical class Unused { public long value() { return 1; } }
        """;
    VirtualMachine linked = new VirtualMachine(
        new WheelerCompiler().compilePackageModuleFiles(
            Map.of("src/Main.w", root),
            Map.of("dependency/Math.w", library, "dependency/Unused.w", unused),
            "demo.main"));
    linked.run();
    assertEquals(8, linked.global("result"));

    assertThrows(
        CompilerException.class,
        () -> new WheelerCompiler().compileLibraryModuleFiles(
            Map.of("src/Math.w", library.replace(
                "public long twice", "entry void main() {} public long twice")),
            "demo.math"));
  }

  @Test
  void moduleLinkerFailsClosedOnVisibilityCyclesAndUnusedInputs() {
    String dependency = """
        module dep;
        classical class Dependency {
          private long hidden(long value) { return value; }
        }
        """;
    String hiddenCall = """
        module root;
        import dep;
        classical class Root {
          entry void main() { long value = hidden(1); }
        }
        """;
    String cycleA = """
        module a;
        import b;
        classical class A { entry void main() { } }
        """;
    String cycleB = """
        module b;
        import a;
        classical class B { }
        """;
    String leakyDependency = """
        module leaky;
        classical class Leaky {
          private record Secret(long value) {}
          public Secret expose(long value) { return new Secret(value); }
        }
        """;
    String leakyRoot = """
        module leakroot;
        import leaky;
        classical class LeakRoot { entry void main() { } }
        """;
    String leakyVariant = """
        module leakyvariant;
        classical class LeakyVariant {
          private variant SecretResult { case Value(long value); }
          public SecretResult expose(long value) {
            return new SecretResult.Value(value);
          }
        }
        """;
    String leakyVariantRoot = """
        module variantroot;
        import leakyvariant;
        classical class VariantRoot { entry void main() { } }
        """;
    String leakyCollection = """
        module leakycollection;
        classical class LeakyCollection {
          private record Secret(long value) {}
          public long expose(Secret[] values) { return values[0].value; }
        }
        """;
    String leakyCollectionRoot = """
        module collectionroot;
        import leakycollection;
        classical class CollectionRoot { entry void main() { } }
        """;
    String unused = """
        module unused;
        classical class Unused { }
        """;
    WheelerCompiler compiler = new WheelerCompiler();

    assertThrows(CompilerException.class, () -> compiler.compileModules(
        Map.of("root", hiddenCall, "dep", dependency), "root"));
    assertThrows(CompilerException.class, () -> compiler.compileModules(
        Map.of("a", cycleA, "b", cycleB), "a"));
    assertThrows(CompilerException.class, () -> compiler.compileModules(
        Map.of("leakroot", leakyRoot, "leaky", leakyDependency), "leakroot"));
    assertThrows(CompilerException.class, () -> compiler.compileModules(
        Map.of("variantroot", leakyVariantRoot, "leakyvariant", leakyVariant),
        "variantroot"));
    assertThrows(CompilerException.class, () -> compiler.compileModules(
        Map.of("collectionroot", leakyCollectionRoot, "leakycollection", leakyCollection),
        "collectionroot"));
    assertThrows(CompilerException.class, () -> compiler.compileModules(
        Map.of("root", hiddenCall.replace("long value = hidden(1);", ""),
            "dep", dependency,
            "unused", unused),
        "root"));
  }

  @Test
  void explicitHostUtf8EntryInputIsStrictBoundedAndRewindable() {
    Program program = new WheelerCompiler().compile("""
        classical class InputCount {
          state long byteCount = 0;
          state long scalars = 0;
          entry void main(utf8 source) {
            byteCount = bufferLength(source);
            scalars = utf8Count(source);
            assert(byteCount == 3);
            assert(scalars == 2);
          }
        }
        """);
    assertThrows(VmTrap.class, () -> new VirtualMachine(program));
    assertThrows(
        VmTrap.class,
        () -> new VirtualMachine(program, new byte[] {(byte) 0xc0, (byte) 0x80}));
    VirtualMachine machine = new VirtualMachine(
        program, "A¢".getBytes(StandardCharsets.UTF_8));
    var initial = machine.snapshot();

    machine.run();

    assertEquals(3, machine.global("byteCount"));
    assertEquals(2, machine.global("scalars"));
    while (machine.historySize() > 0) {
      machine.rewindOne();
    }
    assertEquals(initial, machine.snapshot());
  }

  @Test
  void entrySelectsABoundedRewindableHostOutputPrefix() {
    Program program = new WheelerCompiler().compile("""
        classical class Prefix {
          entry void main(bytes output) {
            setByte(output, 0, 65);
            setByte(output, 1, 66);
            setOutputLength(output, 2);
          }
        }
        """);
    VirtualMachine machine = new VirtualMachine(program, null, 8);
    var initial = machine.snapshot();

    machine.run();

    assertArrayEquals(new byte[] {65, 66}, machine.hostOutput());
    while (machine.historySize() > 0) {
      machine.rewindOne();
    }
    assertEquals(initial, machine.snapshot());

    Program oversized = new WheelerCompiler().compile("""
        classical class Oversized {
          entry void main(bytes output) { setOutputLength(output, 3); }
        }
        """);
    VirtualMachine invalid = new VirtualMachine(oversized, null, 2);
    assertThrows(VmTrap.class, invalid::run);
    assertArrayEquals(new byte[] {0, 0}, invalid.hostOutput());
  }

  @Test
  void checkedMultiplicationUsesConventionalPrecedenceAndTrapsOnOverflow() {
    Program program = new WheelerCompiler().compile("""
        classical class Product {
          state long result = 0;
          state long quotient = 0;
          state long remainder = 0;
          entry void main() {
            result = 2 + 3 * 4;
            quotient = 20 / 3;
            remainder = 20 % 3;
            assert(result == 14);
            assert(quotient == 6);
            assert(remainder == 2);
          }
        }
        """);
    VirtualMachine machine = new VirtualMachine(program);
    var initial = machine.snapshot();
    machine.run();
    assertEquals(14, machine.global("result"));
    assertEquals(6, machine.global("quotient"));
    assertEquals(2, machine.global("remainder"));
    while (machine.historySize() > 0) {
      machine.rewindOne();
    }
    assertEquals(initial, machine.snapshot());

    VirtualMachine overflow = new VirtualMachine(new WheelerCompiler().compile("""
        classical class Overflow {
          entry void main() {
            long maximum = 9223372036854775807;
            long product = maximum * 2;
          }
        }
        """));
    assertThrows(VmTrap.class, overflow::run);

    VirtualMachine divisionByZero = new VirtualMachine(new WheelerCompiler().compile("""
        classical class DivisionByZero {
          entry void main() {
            long zero = 0;
            long invalid = 1 / zero;
          }
        }
        """));
    assertThrows(VmTrap.class, divisionByZero::run);
  }

  @Test
  void typedLocalsBranchesAndBoundedLoopsExecute() {
    String source = """
        classical class Control {
          state long sum = 0;
          state long branch = 0;
          entry void main() {
            long i = 0;
            while (i < 5) limit 5 {
              sum += i;
              i += 1;
            }
            boolean complete = sum == 10;
            if (complete) { branch = 1; } else { branch = 2; }
            assert(sum == 10);
            assert(branch == 1);
          }
        }
        """;
    Program program = new WheelerCompiler().compile(source);
    VirtualMachine machine = new VirtualMachine(program);

    machine.run();

    assertEquals(10, machine.global("sum"));
    assertEquals(1, machine.global("branch"));
    assertTrue(program.function(program.entryFunctionId()).localCount() > 0);
    assertTrue(program.function(program.entryFunctionId()).localTypes()
        .contains(ValueType.BOOLEAN));
  }

  @Test
  void booleanParametersAndResultsRoundTripAndExecute() {
    Program program = new WheelerCompiler().compile("""
        classical class Predicates {
          state long result = 0;
          boolean same(boolean left, boolean right) { return left == right; }
          entry void main() {
            boolean equal = same(true, true);
            if (equal) { result = 1; } else { result = 2; }
            assert(result == 1);
          }
        }
        """);
    Program decoded = new BytecodeReader().read(new BytecodeWriter().write(program));
    var predicate = decoded.functions().stream()
        .filter(function -> function.name().equals("same"))
        .findFirst()
        .orElseThrow();
    VirtualMachine machine = new VirtualMachine(decoded);

    machine.run();

    assertEquals(ValueType.BOOLEAN, predicate.resultType());
    assertEquals(
        List.of(ValueType.BOOLEAN, ValueType.BOOLEAN),
        predicate.localTypes().subList(0, predicate.parameterCount()));
    assertEquals(1, machine.global("result"));
  }

  @Test
  void earlyReturnBreakAndContinuePreserveBoundedControl() {
    Program program = new WheelerCompiler().compile("""
        classical class LoopControl {
          state long sum = 0;
          state long stopped = 0;
          long choose(boolean first) {
            if (first) { return 7; }
            return 9;
          }
          entry void main() {
            long i = 0;
            while (i < 6) limit 6 {
              i += 1;
              if (i < 3) { continue; }
              sum += i;
              if (i == 5) { break; }
            }
            stopped = choose(i == 5);
            assert(sum == 12);
            assert(stopped == 7);
          }
        }
        """);
    VirtualMachine machine = new VirtualMachine(program);

    machine.run();

    assertEquals(12, machine.global("sum"));
    assertEquals(7, machine.global("stopped"));
  }

  @Test
  void boundedForExecutesUpdateOnContinueAndSkipsItOnBreak() {
    Program program = new WheelerCompiler().compile("""
        classical class ForControl {
          state long sum = 0;
          entry void main() {
            for (long i = 0; i < 6; i += 1) limit 6 {
              if (i < 2) { continue; }
              sum += i;
              if (i == 4) { break; }
            }
            assert(sum == 9);
          }
        }
        """);
    VirtualMachine machine = new VirtualMachine(program);

    machine.run();

    assertEquals(9, machine.global("sum"));
  }

  @Test
  void nestedLoopJumpsTargetTheInnermostLoop() {
    Program program = new WheelerCompiler().compile("""
        classical class NestedLoops {
          state long count = 0;
          entry void main() {
            long outer = 0;
            while (outer < 2) limit 2 {
              outer += 1;
              long inner = 0;
              while (inner < 3) limit 3 {
                inner += 1;
                if (inner == 2) { break; }
                count += 1;
              }
              count += 10;
            }
            assert(count == 22);
          }
        }
        """);
    VirtualMachine machine = new VirtualMachine(program);

    machine.run();

    assertEquals(22, machine.global("count"));
  }

  @Test
  void zeroIterationLoopAndGlobalStepDefenseRemainIndependent() {
    Program zero = new WheelerCompiler().compile("""
        classical class ZeroLoop {
          state long count = 0;
          entry void main() {
            while (false) limit 0 { count += 1; }
            assert(count == 0);
          }
        }
        """);
    VirtualMachine zeroMachine = new VirtualMachine(zero);
    zeroMachine.run();
    assertEquals(0, zeroMachine.global("count"));

    Program source = new WheelerCompiler().compile("""
        classical class StepDefense {
          entry void main() { while (true) limit 100 { } }
        }
        """);
    Program constrained = new Program(
        source.name(),
        source.entryFunctionId(),
        source.globals(),
        source.functions(),
        100,
        3);
    assertThrows(VmTrap.class, () -> new VirtualMachine(constrained).run());
  }

  @Test
  void loopLimitTrapsBeforeAnExtraIteration() {
    Program program = new WheelerCompiler().compile("""
        classical class Bounded {
          state long count = 0;
          entry void main() {
            long unchanged = 0;
            while (unchanged < 1) limit 2 {
              count += 1;
            }
          }
        }
        """);
    VirtualMachine machine = new VirtualMachine(program);

    assertThrows(VmTrap.class, machine::run);
    assertEquals(2, machine.global("count"));
  }

  @Test
  void recursiveValueCallRespectsFrameDepthLimit() {
    Program program = new WheelerCompiler().compile("""
        classical class Recursive {
          state long result = 0;
          long depth(long remaining) {
            long value = 0;
            if (0 < remaining) {
              value = depth(remaining - 1) + 1;
            }
            return value;
          }
          entry void main() {
            long value = depth(1100);
            result = value;
          }
        }
        """);
    VirtualMachine machine = new VirtualMachine(program);

    VmTrap trap = assertThrows(VmTrap.class, machine::run);

    assertTrue(trap.getMessage().contains("Call depth limit exceeded"));
    assertEquals(0, machine.global("result"));
  }

  @Test
  void lowersCheckedBitwiseAndRotateRight32() {
    WheelerCompiler compiler = new WheelerCompiler();
    Program program = compiler.compile("""
        classical class BitWords {
          state long result = 0;
          entry void main() {
            long selected = 4294967295 & 252645135;
            result = rotateRight32(selected, 4);
          }
        }
        """);
    VirtualMachine machine = new VirtualMachine(program);
    var initial = machine.snapshot();

    machine.run();

    assertEquals(4042322160L, machine.global("result"));
    while (machine.historySize() > 0) {
      machine.rewindOne();
    }
    assertEquals(initial, machine.snapshot());

    Program invalid = compiler.compile("""
        classical class BadRotate {
          state long result = 9;
          entry void main() { result = rotateRight32(1, 32); }
        }
        """);
    VirtualMachine rejected = new VirtualMachine(invalid);
    assertThrows(VmTrap.class, rejected::run);
    assertEquals(9, rejected.global("result"));
  }

  @Test
  void booleanNegationFoldsAndEvaluatesItsOperandOnce() {
    WheelerCompiler compiler = new WheelerCompiler();
    Program program = compiler.compile("""
        classical class Negation {
          const boolean DISABLED = !true;
          state long calls = 0;
          boolean falseOnce() { calls += 1; return false; }
          entry void main() {
            assert(!DISABLED);
            assert(!falseOnce());
            assert(!!true);
            assert(calls == 1);
          }
        }
        """);

    VirtualMachine machine = new VirtualMachine(program);
    machine.run();

    assertEquals(1, machine.global("calls"));
    CompilerException nonBoolean = assertThrows(
        CompilerException.class,
        () -> compiler.compile(
            "classical class Bad { entry void main() { assert(!1); } }"));
    assertTrue(nonBoolean.getMessage().contains("expression type mismatch"));
  }

  @Test
  void constantsFoldWithoutAddingGlobalState() {
    Program program = new WheelerCompiler().compile("""
        classical class NamedValues {
          const long CALL = BASE + 1;
          const long BASE = 0x0200;
          const long MASKED = (CALL ^ 1) & 0x02ff;
          const boolean ENABLED = MASKED == BASE;
          state long result = CALL;
          entry void main() {
            if (ENABLED) { result = CALL; }
            assert(result == 513);
          }
        }
        """);
    VirtualMachine machine = new VirtualMachine(program);

    assertEquals(513, machine.global("result"));
    machine.run();

    assertEquals(1, program.globals().size());
    assertEquals(513, machine.global("result"));
    assertArrayEquals(
        new WheelerCompiler().compileToBytecode("""
            classical class Reordered {
              const long FIRST = SECOND + 1;
              const long SECOND = 4;
              entry void main() { long value = FIRST; }
            }
            """),
        new WheelerCompiler().compileToBytecode("""
            classical class Reordered {
              const long SECOND = 4;
              const long FIRST = SECOND + 1;
              entry void main() { long value = FIRST; }
            }
            """));
  }

  @Test
  void publicConstantsResolveAcrossModulesWithoutAmbientOverrides() {
    String values = """
        module values;
        classical class Values {
          public const long FRAME_LIMIT = 8 * 2;
          private const long HIDDEN = 99;
        }
        """;
    String root = """
        module root;
        import values;
        classical class Root {
          state long result = 0;
          entry void main() {
            long direct = FRAME_LIMIT;
            result = direct + values::FRAME_LIMIT;
            assert(result == 32);
          }
        }
        """;
    WheelerCompiler compiler = new WheelerCompiler();
    Program program = compiler.compileModules(
        Map.of("root", root, "values", values), "root");
    VirtualMachine machine = new VirtualMachine(program);

    machine.run();

    assertEquals(32, machine.global("result"));
    CompilerException hidden = assertThrows(
        CompilerException.class,
        () -> compiler.compileModules(
            Map.of(
                "root",
                root.replace("long direct = FRAME_LIMIT;", "long direct = values::HIDDEN;"),
                "values",
                values),
            "root"));
    String other = """
        module other;
        classical class Other { public const long FRAME_LIMIT = 7; }
        """;
    CompilerException ambiguous = assertThrows(
        CompilerException.class,
        () -> compiler.compileModules(
            Map.of(
                "root", root.replace("import values;", "import other; import values;"),
                "values", values,
                "other", other),
            "root"));
    assertTrue(hidden.getMessage().contains("unknown constant: values::HIDDEN"));
    assertTrue(ambiguous.getMessage().contains("ambiguous constant: FRAME_LIMIT"));
  }

  @Test
  void finiteEnumsUseThePayloadFreeVariantPath() {
    String source = """
        classical class Directions {
          enum Direction {
            case Left;
            case Right;
          }
          state long selected = 0;
          entry void main() {
            Direction direction = new Direction.Right();
            match (direction) {
              case Direction.Left() { selected = 1; }
              case Direction.Right() { selected = 2; }
            }
            assert(selected == 2);
          }
        }
        """;
    WheelerCompiler compiler = new WheelerCompiler();
    Program program = compiler.compile(source);
    VirtualMachine machine = new VirtualMachine(program);

    machine.run();

    assertEquals(1, program.variantTypes().size());
    assertTrue(program.variantTypes().getFirst().cases().stream()
        .allMatch(variantCase -> variantCase.fields().isEmpty()));
    assertArrayEquals(
        compiler.compileToBytecode(source),
        compiler.compileToBytecode(source.replace(
            "case Left;\n    case Right;",
            "case Right;\n    case Left;")));
    assertEquals(2, machine.global("selected"));
  }

  @Test
  void sourceProducesCanonicalBytecode() {
    WheelerCompiler compiler = new WheelerCompiler();
    byte[] encoded = compiler.compileToBytecode(COUNTER);
    byte[] reencoded = new BytecodeWriter().write(new BytecodeReader().read(encoded));

    assertArrayEquals(encoded, reencoded);
  }

  @Test
  void rejectsCheckedArithmeticFromTheCoherentSubset() {
    CompilerException exception = assertThrows(
        CompilerException.class,
        () -> new WheelerCompiler().compile(COUNTER.replace("rev void increment", "coherent rev void increment")));

    assertTrue(exception.getMessage().contains("coherent function contains ADD_CONST"));
  }

  @Test
  void reportsSourceErrorsWithLines() {
    CompilerException unknown = assertThrows(
        CompilerException.class,
        () -> new WheelerCompiler().compile(COUNTER.replace("count += 1", "missing += 1")));
    CompilerException irreversible = assertThrows(
        CompilerException.class,
        () -> new WheelerCompiler().compile(COUNTER.replace("count += 1", "count = 1")));

    assertTrue(unknown.getMessage().contains("line 5"));
    assertTrue(irreversible.getMessage().contains("no generated inverse"));
  }
}
