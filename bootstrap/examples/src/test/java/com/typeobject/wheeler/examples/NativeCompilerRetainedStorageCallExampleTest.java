package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.compiler.CompilerException;
import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeVerifier;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.Opcode;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.TransitionObserver;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;
import java.util.stream.IntStream;
import org.junit.jupiter.api.Test;

/** Retains exact storage-loan types without treating regions or maps as buffers. */
final class NativeCompilerRetainedStorageCallExampleTest {
  private static final String PARAMETERS =
      "borrow mut region arena, borrow mut longmap values, long number, boolean flag";
  private static final String ARGUMENTS = "arena, values, number, flag";
  private static final int[] TYPES = {12, 9, 1, 2};

  @Test
  void compilesStorageLoansAtEveryOrdinaryCallPosition() throws Exception {
    for (String body : List.of(
        "long result = CALL; return result;", "return CALL;",
        "long index = 0; while (index < 1) limit 1 { long result = CALL; index += 1; } return number;")) {
      assertLocal("long", body);
    }
    assertLocal("boolean", "if (CALL) { return false; } return true;");
    assertLocal("void", "CALL;");
    assertLocal("void", "long index = 0; while (index < 1) limit 1 { CALL; index += 1; }");
  }

  @Test
  void preservesImportedTypesStubsAndRelocationsWithoutDependencySource() throws Exception {
    for (String target : List.of("remote", "dep.alpha::remote")) {
      for (String result : List.of("long", "boolean", "void")) {
        String call = target + "(" + ARGUMENTS + ");";
        String body = result.equals("void") ? call : result + " answer = " + call + " return answer;";
        int code = result.equals("void") ? 0 : result.equals("long") ? 1 : 2;
        NativeRetainedCallFixture.assertImported(source(result, body), target, TYPES, code);
      }
    }
  }

  @Test
  void bindsBothLoanKindsThroughArgument64AndRejectsTheFirstExcess() throws Exception {
    for (String loan : List.of("borrow mut region", "borrow mut longmap")) {
      int loanType = loan.endsWith("region") ? 12 : 9;
      for (int arity : new int[] {1, 55, 64, 65}) {
        String parameters = IntStream.range(0, arity).mapToObj(index ->
            (index == arity - 1 ? loan : "long") + " p" + index).collect(Collectors.joining(", "));
        String arguments = IntStream.range(0, arity).mapToObj(index -> "p" + index)
            .collect(Collectors.joining(", "));
        int[] types = IntStream.range(0, arity).map(index -> index == arity - 1 ? loanType : 1).toArray();
        String source = NativeRetainedCallFixture.source(parameters, "long",
            "return recurse(" + arguments + ");");
        if (arity == 65) {
          new WheelerCompiler().compileLibraryModuleFiles(
              Map.of("Call.w", source), NativeRetainedCallFixture.MODULE);
          NativeRetainedCallFixture.assertRejected(source, false, types, types, 1, 0);
        } else {
          NativeRetainedCallFixture.assertLocal(source, types);
          String imported = source.replace("return recurse(", "return remote(");
          NativeRetainedCallFixture.assertImported(imported, "remote", types, 1);
          int[] wrong = types.clone();
          wrong[arity - 1] = loanType == 12 ? 9 : 12;
          NativeRetainedCallFixture.assertRejected(imported, true, types, wrong, 1, 0);
          String absent = source.replace("return recurse(" + arguments + ");",
              "return recurse(" + arguments.substring(0, arguments.lastIndexOf('p')) + "missing);");
          NativeRetainedCallFixture.assertRejected(absent, false, types, types, 1, 0);
        }
      }
    }
  }

  @Test
  void keepsQualifiedForwardingIndependentOfStorageLoanAdmission() throws Exception {
    for (String parameters : List.of("long number", PARAMETERS)) {
      String arguments = parameters.equals(PARAMETERS) ? ARGUMENTS : "number";
      int[] types = parameters.equals(PARAMETERS) ? TYPES : new int[] {1};
      String source = NativeRetainedCallFixture.source(parameters, "long",
          "return dep.alpha::remote(" + arguments + ");");
      String root = source.replace("module " + NativeRetainedCallFixture.MODULE + ";",
          "module " + NativeRetainedCallFixture.MODULE + "; import dep.alpha;");
      String dependency = "module dep.alpha; classical class Remote { public long remote("
          + parameters + ") { return number; } }";
      new WheelerCompiler().compileLibraryModuleFiles(
          Map.of("Call.w", root, "Remote.w", dependency), NativeRetainedCallFixture.MODULE);
      NativeRetainedCallFixture.assertRejected(source, true, types, types, 1, 0);
    }
  }

  @Test
  void rejectsCrossKindLoansAndBufferOperationsBeforePublication() throws Exception {
    for (int changed : new int[] {0, 1}) {
      int[] target = TYPES.clone();
      target[changed] = changed == 0 ? 9 : 12;
      NativeRetainedCallFixture.assertRejected(source("long", "return remote(" + ARGUMENTS + ");"),
          true, TYPES, target, 1, 0);
    }
    for (String value : List.of("arena", "values")) {
      for (String expression : List.of("bufferLength(" + value + ")", value + "[number]")) {
        String source = source("long", "return " + expression + ";");
        assertThrows(CompilerException.class, () -> new WheelerCompiler().compileLibraryModuleFiles(
            Map.of("Call.w", source), NativeRetainedCallFixture.MODULE));
        NativeRetainedCallFixture.assertRejected(source, false, TYPES, TYPES, 1, 0);
      }
    }
  }

  @Test
  void executesRegionAllocationAndMapMutationThroughTheNativeCallerAndRewinds() throws Exception {
    String source = source("long", "return remote(" + ARGUMENTS + ");");
    Program retained = NativeRetainedCallFixture.assertImported(source, "remote", TYPES, 1);
    String wrapper = source.substring(0, source.lastIndexOf('}')) + """
        private long remote(borrow mut region arena, borrow mut longmap values,
            long number, boolean flag) {
          bytes scratch = allocateBytes(arena, 1);
          setByte(scratch, 0, number);
          long saved = scratch[0];
          drop(scratch);
          put(values, 0, saved);
          return mapGet(values, 0);
        }
        entry void main() {
          region arena = new region(/* bytes= */ ARENA_BYTES, /* allocations= */ 8);
          longmap values = allocateMap(arena, 4);
          observed = recurse(arena, values, 7, true);
          assert(observed == 7);
          assert(mapGet(values, 0) == 7);
          drop(values);
          drop(arena);
        }
        }
        """;
    wrapper = wrapper.replace("classical class StructuredCall {", """
        classical class StructuredCall {
          private const long ARENA_BYTES = 4096;
          state long observed = 0;
        """);
    Program expected = new WheelerCompiler().compileModuleFiles(
        Map.of("Call.w", wrapper), NativeRetainedCallFixture.MODULE);
    assertEquals(expected.function(0), retained.function(0));
    Program executable = new Program(expected.name(), expected.entryFunctionId(), expected.globals(),
        List.of(retained.function(0), expected.function(1), expected.function(2)));
    BytecodeVerifier.verify(executable);
    assertArrayEquals(new BytecodeWriter().write(expected), new BytecodeWriter().write(executable));
    var observations = new ArrayList<TransitionObserver.Observation>();
    var machine = new VirtualMachine(executable, observations::add);
    var initial = machine.snapshot();
    machine.run();
    assertEquals(7, machine.global("observed"));
    for (Opcode opcode : List.of(Opcode.CALL_VALUE, Opcode.REGION_BORROW, Opcode.MAP_BORROW)) {
      assertEquals(1, observations.stream().filter(row -> row.functionId() == 0
          && row.opcode() == opcode).count(), opcode.toString());
    }
    assertEquals(1, observations.stream().filter(row -> row.functionId() == 1
        && row.opcode() == Opcode.BYTES_ALLOC).count());
    assertTrue(machine.snapshot().regions().stream().allMatch(region -> region.dropped()));
    assertTrue(machine.snapshot().buffers().stream().allMatch(buffer -> buffer.dropped()));
    while (machine.historySize() > 0) { machine.rewindOne(); }
    assertEquals(initial, machine.snapshot());
  }

  private static void assertLocal(String result, String body) throws Exception {
    NativeRetainedCallFixture.assertLocal(
        source(result, body.replace("CALL", "recurse(" + ARGUMENTS + ")")), TYPES);
  }

  private static String source(String result, String body) {
    return NativeRetainedCallFixture.source(PARAMETERS, result, body);
  }
}
