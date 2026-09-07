package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeVerifier;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.Opcode;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.TransitionObserver;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;
import java.util.stream.IntStream;
import org.junit.jupiter.api.Test;

/** Exercises retained call arities independently of the scalar-helper compiler. */
final class NativeCompilerRetainedAritySourceProductExampleTest {
  private static final String[] PARAMETER_TYPES = {
      "long", "boolean", "borrow utf8", "borrow byteview", "borrow mut words",
      "borrow mut bytes", "long", "boolean"
  };
  private static final int[] TYPES = {1, 2, 8, 13, 10, 11, 1, 2};

  @Test
  void comparesRootLoopForwardedGuardedAndVoidCallsAtAllNewArityBoundaries() throws Exception {
    for (int arity : new int[] {9, 55, 64}) {
      for (String body : List.of(
          "long result = CALL; return result;",
          "return CALL;",
          "long index = 0; while (index < 1) limit 1 { long result = CALL; index += 1; } return p0;")) {
        assertLocal(arity, "long", body);
      }
      assertLocal(arity, "boolean", "if (CALL) { return false; } return true;");
      assertLocal(arity, "void", "CALL;");
      assertLocal(arity, "void", "long index = 0; while (index < 1) limit 1 { CALL; index += 1; }");
    }
  }

  @Test
  void comparesImportedBodiesStubsAndRelocationsThroughTheLastArgument() throws Exception {
    for (int arity : new int[] {9, 55, 64}) {
      for (String target : List.of("remote", "dep.alpha::remote")) {
        for (String result : List.of("long", "boolean", "void")) {
          String call = target + "(" + arguments(arity) + ");";
          String body = result.equals("void") ? call : result + " value = " + call + " return value;";
          int resultType = result.equals("void") ? 0 : result.equals("long") ? 1 : 2;
          NativeRetainedCallFixture.assertImported(
              source(arity, result, body), target, types(arity), resultType);
        }
      }
    }
  }

  @Test
  void rejectsExcessUnknownAndWrongFinalArgumentsBeforeArtifactPublication() throws Exception {
    int[] types = types(64);
    int[] excess = Arrays.copyOf(types, 65);
    excess[64] = 1;
    NativeRetainedCallFixture.assertRejected(
        source(64, "long", "return remote(" + arguments(64) + ", p0);"),
        true, types, excess, 1, 0);
    int[] wrong = types.clone();
    wrong[63] = 1;
    NativeRetainedCallFixture.assertRejected(
        source(64, "long", "return remote(" + arguments(64) + ");"),
        true, types, wrong, 1, 0);
    NativeRetainedCallFixture.assertRejected(
        source(64, "long", "return recurse(" + arguments(63) + ", missing);"),
        false, types, types, 1, 0);
  }

  @Test
  void keepsWideArgumentBearingInversesOutsideThisOrdinaryCallProfile() throws Exception {
    for (int arity : new int[] {55, 64}) {
      String source = source(arity, "rev void", "recurse(" + arguments(arity) + ");")
          .replace("\n}\n}\n", "\n}\ntheorem recurseInverse proves inverse(recurse);\n}\n");
      NativeRetainedCallFixture.assertRejected(source, false, types(arity), types(arity), 0, 2);
    }
  }

  @Test
  void fillsTheIndependentFrameAndRejectsItsFirstExcessBeforePublication() throws Exception {
    String declarations = IntStream.range(0, 32).mapToObj(index -> "long v" + index + " = p0;")
        .collect(Collectors.joining("\n"));
    String call = "recurse(" + arguments(64) + ");";
    Program accepted = NativeRetainedCallFixture.assertLocal(
        source(64, "void", declarations + "\n" + call), types(64));
    assertEquals(256, accepted.function(0).localTypes().size());
    String excess = source(64, "void", declarations + "\nassert(p1);\n" + call);
    Program oracle = new WheelerCompiler().compileLibraryModuleFiles(
        Map.of("Call.w", excess), NativeRetainedCallFixture.MODULE);
    assertEquals(257, oracle.function(0).localTypes().size());
    NativeRetainedCallFixture.assertRejected(excess, false, types(64), types(64), 0, 0);
  }

  @Test
  void executesNativeWideCallsInsideAnIndependentWrapperAndRewinds() throws Exception {
    for (int arity : new int[] {55, 64}) {
      String parameters = IntStream.range(0, arity).mapToObj(index -> "long p" + index)
          .collect(Collectors.joining(", "));
      String source = NativeRetainedCallFixture.source(parameters, "long",
          "if (p0 == 0) { return p" + (arity - 1) + "; }\nlong zero = 0;\nreturn recurse("
              + arguments(arity).replaceFirst("p0", "zero") + ");");
      int[] types = new int[arity];
      Arrays.fill(types, 1);
      Program retained = NativeRetainedCallFixture.assertLocal(source, types);
      String literals = IntStream.rangeClosed(1, arity).mapToObj(Integer::toString)
          .collect(Collectors.joining(", "));
      String wrapper = source.substring(0, source.lastIndexOf('}'))
          + "entry void main() { observed = recurse(" + literals + "); assert(observed == "
          + arity + "); }\n}\n";
      wrapper = wrapper.replace("classical class StructuredCall {",
          "classical class StructuredCall { state long observed = 0;");
      Program expected = new WheelerCompiler().compileModuleFiles(
          Map.of("Call.w", wrapper), NativeRetainedCallFixture.MODULE);
      assertEquals(expected.function(0), retained.function(0));
      Program executable = new Program(expected.name(), expected.entryFunctionId(), expected.globals(),
          List.of(retained.function(0), expected.function(1)));
      BytecodeVerifier.verify(executable);
      assertArrayEquals(new BytecodeWriter().write(expected), new BytecodeWriter().write(executable));
      var observations = new ArrayList<TransitionObserver.Observation>();
      var machine = new VirtualMachine(executable, observations::add);
      var initial = machine.snapshot();
      machine.run();
      assertEquals(arity, machine.global("observed"));
      assertEquals(1, observations.stream().filter(observation -> observation.functionId() == 0
          && observation.opcode() == Opcode.CALL_VALUE).count());
      while (machine.historySize() > 0) {
        machine.rewindOne();
      }
      assertEquals(initial, machine.snapshot());
    }
  }

  @Test
  void compilesTheFormerRegionAndMapArgumentRejectionsByteForByte() throws Exception {
    for (int type : new int[] {12, 9}) {
      int[] types = types(64);
      types[63] = type;
      String storage = type == 12 ? "region" : "longmap";
      String source = source(64, "long", "return recurse(" + arguments(64) + ");")
          .replace("boolean p63", "borrow mut " + storage + " p63");
      NativeRetainedCallFixture.assertLocal(source, types);
    }
  }

  private static void assertLocal(int arity, String result, String body) throws Exception {
    NativeRetainedCallFixture.assertLocal(
        source(arity, result, body.replace("CALL", "recurse(" + arguments(arity) + ")")), types(arity));
  }

  private static String source(int arity, String result, String body) {
    String parameters = IntStream.range(0, arity)
        .mapToObj(index -> PARAMETER_TYPES[index % PARAMETER_TYPES.length] + " p" + index)
        .collect(Collectors.joining(", "));
    return NativeRetainedCallFixture.source(parameters, result, body);
  }

  private static String arguments(int arity) {
    return IntStream.range(0, arity).mapToObj(index -> "p" + index).collect(Collectors.joining(", "));
  }

  private static int[] types(int arity) {
    return IntStream.range(0, arity).map(index -> TYPES[index % TYPES.length]).toArray();
  }
}
