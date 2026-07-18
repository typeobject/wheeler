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
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;

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
          assert count == 2;
          reverse {
            increment();
            increment();
          }
          assert count == 0;
        }
      }
      """;

  @Test
  void compactFormattingHasTheSameSemantics() {
    String compact = "classical class Tiny{state long x=0;rev void flip(){x^=1;}"
        + "entry void main(){flip();reverse flip();assert x==0;}}";

    Program program = new WheelerCompiler().compile(compact);
    VirtualMachine machine = new VirtualMachine(program);
    machine.run();

    assertEquals(0, machine.global("x"));
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
            result = twice(9);
            assert result == 18;
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
        Map.of("root", hiddenCall.replace("long value = hidden(1);", ""),
            "dep", dependency,
            "unused", unused),
        "root"));
  }

  @Test
  void checkedMultiplicationUsesConventionalPrecedenceAndTrapsOnOverflow() {
    Program program = new WheelerCompiler().compile("""
        classical class Product {
          state long result = 0;
          entry void main() { result = 2 + 3 * 4; assert result == 14; }
        }
        """);
    VirtualMachine machine = new VirtualMachine(program);
    machine.run();
    assertEquals(14, machine.global("result"));

    VirtualMachine overflow = new VirtualMachine(new WheelerCompiler().compile("""
        classical class Overflow {
          entry void main() {
            long maximum = 9223372036854775807;
            long product = maximum * 2;
          }
        }
        """));
    assertThrows(VmTrap.class, overflow::run);
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
            assert sum == 10;
            assert branch == 1;
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
            assert result == 1;
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
            assert sum == 12;
            assert stopped == 7;
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
            assert sum == 9;
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
            assert count == 22;
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
            assert count == 0;
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
