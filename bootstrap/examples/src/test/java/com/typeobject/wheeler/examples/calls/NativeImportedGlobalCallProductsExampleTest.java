package com.typeobject.wheeler.examples.calls;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeReader;
import com.typeobject.wheeler.core.bytecode.BytecodeVerifier;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.FunctionBody;
import com.typeobject.wheeler.core.bytecode.Global;
import com.typeobject.wheeler.core.bytecode.Instruction;
import com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole;
import com.typeobject.wheeler.core.bytecode.Opcode;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.bytecode.ValueType;
import com.typeobject.wheeler.core.vm.BufferValue;
import com.typeobject.wheeler.core.vm.MachineStatus;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.examples.StructuredCallSourceProductDriver;
import com.typeobject.wheeler.examples.globals.NativeGlobalExecutionAssertions;
import com.typeobject.wheeler.examples.globals.NativeGlobalRetentionAssertions;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;
import java.util.stream.IntStream;
import org.junit.jupiter.api.Test;

/** Checks source-free imported call products, then binds a real oracle body for execution evidence. */
final class NativeImportedGlobalCallProductsExampleTest {
  private static final String MODULE = "example.structured_call";
  private static final String SUBJECT = MODULE + "::recurse";
  private static final int CALLER = 0;
  private static final int TARGET = CALLER + 1;
  private static final int ENTRY = TARGET + 1;
  private static final int ARTIFACT_BYTES = 32_768;
  private static final int DIGEST_BYTES = 256 / Byte.SIZE;
  private static final int CALLS = 256;
  private static final int RELOCATION_COLUMNS = 3;
  private static final int SENTINEL = 211;

  @Test
  void storesRepeatedQualifiedAndUnqualifiedImportedResultsAtNonzeroOrdinals() throws Exception {
    check(1, false, true, 17, false, 1);
    check(1, true, true, 17, false, 1);
  }

  @Test
  void storesZeroAndMaximumArityImportedResultsWithoutDependencySource() throws Exception {
    check(0, true, false, 17, false, 1);
    check(64, true, false, 17, false, 1);
  }

  @Test
  void preservesSignedEndpointsAndReplaysAFailingCanonicalGlobalAssertion() throws Exception {
    for (long result : new long[] {Long.MIN_VALUE, 0, Long.MAX_VALUE}) {
      check(0, true, false, result, false, 1);
    }
    check(0, true, false, 17, true, 1);
    check(0, true, false, 17, false, 0);
    check(0, true, false, 17, false, 8 - 1);
  }

  private static void check(int arity, boolean qualified, boolean repeated,
      long literalResult, boolean assertionFails, int globalOrdinal) throws Exception {
    String globals = IntStream.range(0, globalOrdinal)
        .mapToObj(ordinal -> "state long G" + ordinal + " = -9223372036854775808;")
        .collect(Collectors.joining("\n"));
    String parameters = IntStream.range(0, arity).mapToObj(i -> "long p" + i)
        .collect(Collectors.joining(", "));
    String arguments = IntStream.range(0, arity).mapToObj(i -> i == 0 ? "previous" : "value")
        .collect(Collectors.joining(", "));
    String callee = qualified ? "dep.alpha::remote" : "remote";
    String call = "Alpha = " + callee + "(" + arguments + ");\n";
    long expectedValue = assertionFails ? literalResult + 1 : literalResult;
    String predicate = arity == 0 ? "Alpha == " + expectedValue : "Alpha == value";
    String source = """
        module example.structured_call;
        import dep.alpha;
        classical class StructuredCall {
          %s
          state long Alpha = 8;
          public long recurse(long value) {
            long previous = value;
            %s
            assert(%s);
            return Alpha;
          }
        }
        """.formatted(globals, call.repeat(repeated ? 2 : 1), predicate);
    String dependency = "module dep.alpha; classical class Alpha { public long remote("
        + parameters + ") { return " + (arity == 0 ? Long.toString(literalResult) : "p0") + "; } }";
    Program compiled = new WheelerCompiler().compileLibraryModuleFiles(
        Map.of("Root.w", source, "Dependency.w", dependency), MODULE);
    FunctionBody sourceCaller = compiled.functions().stream().filter(f -> f.name().equals(SUBJECT))
        .findFirst().orElseThrow();
    FunctionBody realTarget = compiled.functions().stream().filter(f -> f.name().equals("dep.alpha::remote"))
        .findFirst().orElseThrow();
    FunctionBody caller = new FunctionBody(CALLER, SUBJECT, false, sourceCaller.parameterCount(),
        sourceCaller.localTypes(), sourceCaller.resultType(), sourceCaller.forward().stream()
            .map(instruction -> {
              if (instruction.opcode() != Opcode.CALL_VALUE) return instruction;
              assertEquals(realTarget.id(), instruction.operand(OperandRole.FUNCTION));
              return Instruction.of(Opcode.CALL_VALUE, TARGET, instruction.operand(OperandRole.ARGUMENT_BASE),
                  instruction.operand(OperandRole.ARGUMENT_COUNT), instruction.operand(OperandRole.RESULT));
            }).toList(), List.of());
    var stubTypes = new ArrayList<>(java.util.Collections.nCopies(arity + 1, ValueType.SIGNED));
    FunctionBody stub = new FunctionBody(TARGET, "~00", false, arity, stubTypes, ValueType.SIGNED,
        List.of(Instruction.of(Opcode.LOCAL_CONST, arity, 0),
            Instruction.of(Opcode.RETURN_VALUE, arity)), List.of());
    Program transientOracle = program(compiled.globals(), caller, stub);
    byte[] expected = new BytecodeWriter().write(transientOracle);
    int bodyStart = source.indexOf('{', source.indexOf("recurse("));
    // The last non-class brace ends this sole callable. Count its exact immutable byte range.
    int bodyClose = source.lastIndexOf('}', source.lastIndexOf('}') - 1);
    int bodyLength = bodyClose - bodyStart + 1;
    int[] types = new int[arity];
    Arrays.fill(types, ValueType.SIGNED.code());
    long[] declarationStarts = compiled.globals().stream().mapToLong(global -> {
      String prefix = "state long ";
      int start = source.indexOf(prefix + global.name() + " =") + prefix.length();
      assertTrue(start >= prefix.length());
      return source.substring(0, start).getBytes(StandardCharsets.UTF_8).length;
    }).toArray();
    Program driver = StructuredCallSourceProductDriver.driverWithGlobals(
        bodyStart, bodyLength, types, ValueType.SIGNED.code(), compiled.globals(), declarationStarts);
    var machine = new VirtualMachine(driver, source.getBytes(StandardCharsets.UTF_8), ARTIFACT_BYTES);
    Set<Integer> borrowed = machine.snapshot().regions().stream()
        .map(r -> r.id()).collect(Collectors.toSet());
    while (machine.global("prepared") == 0) machine.stepWithoutRewindHistory();
    var before = machine.snapshot();
    while (machine.global("published") == 0) machine.stepWithoutRewindHistory();
    var published = machine.snapshot();
    var publication = published.regions().stream().filter(r -> !r.dropped()
        && r.maxBytes() == ARTIFACT_BYTES + DIGEST_BYTES && r.maxObjects() == 2)
        .findFirst().orElseThrow();
    List<BufferValue> buffers = published.buffers().stream()
        .filter(b -> b.regionId() == publication.id()).toList();
    byte[] full = new byte[ARTIFACT_BYTES];
    Arrays.fill(full, (byte) SENTINEL);
    System.arraycopy(expected, 0, full, 0, expected.length);
    byte[] actual = bytes(buffers.getFirst());
    int actualLength = Math.toIntExact(machine.global("artifactLength"));
    Program decoded = new BytecodeReader().read(Arrays.copyOf(actual, actualLength));
    assertEquals(transientOracle.functions(), decoded.functions(), "complete function descriptors and code");
    assertArrayEquals(full, actual);
    assertArrayEquals(MessageDigest.getInstance("SHA-256").digest(expected), bytes(buffers.getLast()));
    var relocations = published.buffers().stream().filter(b -> !b.dropped()
        && b.length() == CALLS * RELOCATION_COLUMNS).findFirst().orElseThrow();
    var relocationBuffers = published.buffers().stream()
        .filter(b -> b.regionId() == relocations.regionId()).toList();
    var owners = relocationBuffers.stream().filter(b -> b.length() == CALLS).findFirst().orElseThrow();
    var identities = relocationBuffers.stream().filter(b -> b.length() == CALLS * DIGEST_BYTES)
        .findFirst().orElseThrow();
    long[] expectedRows = new long[CALLS * RELOCATION_COLUMNS];
    byte[] expectedIdentities = new byte[CALLS * DIGEST_BYTES];
    int calls = 0;
    for (int instruction = 0; instruction < caller.forward().size(); instruction++) {
      if (caller.forward().get(instruction).opcode() != Opcode.CALL_VALUE) continue;
      expectedRows[calls] = instruction;
      expectedRows[CALLS + calls] = TARGET;
      expectedRows[CALLS * 2 + calls] = CALLER;
      expectedIdentities[calls * DIGEST_BYTES] = 42;
      calls++;
    }
    assertEquals(repeated ? 2 : 1, calls);
    assertArrayEquals(expectedRows, relocations.elements().stream().mapToLong(Long::longValue).toArray());
    assertArrayEquals(new long[CALLS], owners.elements().stream().mapToLong(Long::longValue).toArray());
    assertArrayEquals(expectedIdentities, bytes(identities));
    Set<Integer> outputs = Set.of(buffers.getFirst().id(), buffers.getLast().id(),
        relocations.id(), owners.id(), identities.id());
    for (BufferValue input : before.buffers()) {
      if (!outputs.contains(input.id())) assertEquals(input, published.buffers().get(input.id()));
    }
    while (machine.status() != MachineStatus.HALTED) machine.stepWithoutRewindHistory();
    assertEquals(calls, machine.global("relocationCount"));
    assertEquals(1, machine.global("retainedFunctionCount"));
    assertEquals(2, machine.global("excludedFunctionCount"));
    assertArrayEquals(expected, machine.hostOutput());
    assertTrue(machine.snapshot().buffers().stream().filter(b -> !borrowed.contains(b.regionId()))
        .allMatch(BufferValue::dropped));
    assertTrue(machine.snapshot().regions().stream().filter(r -> !borrowed.contains(r.id()))
        .allMatch(r -> r.dropped()));
    NativeGlobalRetentionAssertions.assertRetained(expected, transientOracle);

    // This is oracle-side body binding, not native retained linking. The native caller stays intact.
    FunctionBody executableTarget = new FunctionBody(TARGET, stub.name(), false, arity,
        realTarget.localTypes(), realTarget.resultType(), realTarget.forward(), List.of());
    Program runtimeOracle = program(compiled.globals(), caller, executableTarget);
    Program nativeProduct = new BytecodeReader().read(machine.hostOutput());
    assertEquals(caller, nativeProduct.function(CALLER));
    Program nativeExecutable = program(nativeProduct.globals(), nativeProduct.function(CALLER), executableTarget);
    NativeGlobalExecutionAssertions.assertExecution(
        new BytecodeWriter().write(nativeExecutable), runtimeOracle, SUBJECT, assertionFails);
  }

  private static Program program(List<Global> globals, FunctionBody caller, FunctionBody target) {
    FunctionBody library = new FunctionBody(ENTRY, "$library", false, 0, List.of(), null,
        List.of(Instruction.of(Opcode.HALT)), List.of());
    Program result = Program.classical("StructuredCall", ENTRY, globals, List.of(), List.of(),
        List.of(), List.of(), List.of(caller, target, library), List.of());
    BytecodeVerifier.verify(result);
    return result;
  }

  private static byte[] bytes(BufferValue buffer) {
    byte[] result = new byte[buffer.length()];
    for (int index = 0; index < result.length; index++) result[index] = buffer.elements().get(index).byteValue();
    return result;
  }
}
