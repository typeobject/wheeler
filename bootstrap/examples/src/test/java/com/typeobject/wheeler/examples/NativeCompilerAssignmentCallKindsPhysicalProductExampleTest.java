package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;
import java.util.stream.Stream;
import org.junit.jupiter.api.Tag;
import org.junit.jupiter.api.Test;

/** Native evidence for the direct imported assignment-call kind product. */
final class NativeCompilerAssignmentCallKindsPhysicalProductExampleTest {
  @Tag("closure-evidence")
  @Test
  void retainsKindFunctionsAndRelocatesArityAndBaseCalls() throws Exception {
    var module = NativeCompilerPhysicalSelection.callable(
        "wheeler.compiler.assignment_call_kinds");
    Program expectedProgram = new WheelerCompiler().compileLibraryModuleFiles(
        CompilerSources.moduleClosure(module.name()), module.name());
    var localFunctions = expectedProgram.functions().stream()
        .filter(function -> function.name().startsWith(module.name() + "::"))
        .toList();
    long expectedInstructions = localFunctions.stream()
        .mapToLong(function -> function.forward().size() + function.inverse().size())
        .sum();
    assertEquals(Set.of("assignmentCallSourceStatement", "assignmentCallStatement",
        "assignmentCallTarget", "globalAssignmentCallStatement", "resolvedAssignmentCall",
        "resolvedGlobalAssignmentCall"), localFunctions.stream()
        .map(function -> function.name().substring(module.name().length() + 2))
        .collect(Collectors.toSet()));
    long expectedRelocations = localFunctions.stream()
        .flatMap(function -> Stream.concat(function.forward().stream(), function.inverse().stream()))
        .filter(instruction -> instruction.opcode().form().roles().contains(OperandRole.FUNCTION))
        .filter(instruction -> {
          int operand = instruction.opcode().form().roles().indexOf(OperandRole.FUNCTION);
          return !expectedProgram.function(Math.toIntExact(instruction.operands().get(operand))).name()
              .startsWith(module.name() + "::");
        }).count();

    Program productProgram = NativeCompilerPhysicalPrograms.callable(module);
    var manifest = CompilerSources.bootstrapModuleManifest();
    VirtualMachine machine = VirtualMachine.withBinaryInput(
        productProgram,
        framed(CompilerSources.packageArchive(), manifest.canonicalBytes()),
        1_048_576);

    CompilerMachineRunner.runWithoutRewindHistory(machine);

    assertEquals(localFunctions.size(), machine.global("physicalRetainedFunctionCount"));
    assertEquals(expectedInstructions, machine.global("physicalRetainedInstructionCount"));
    assertEquals(1, machine.global("physicalCallableProductCount"));
    assertEquals(expectedRelocations, machine.global("physicalCallableRelocationCount"));
    assertEquals(expectedRelocations, machine.global("physicalResolvedCallableTargetCount"));
    NativeCompilerPhysicalProductAssertions.assertCallables(
        manifest, Map.of(module.name(), expectedProgram), machine.hostOutput());
  }

  private static byte[] framed(byte[] archive, byte[] manifest) {
    return ByteBuffer.allocate(Integer.BYTES + archive.length + manifest.length)
        .order(ByteOrder.LITTLE_ENDIAN)
        .putInt(archive.length)
        .put(archive)
        .put(manifest)
        .array();
  }
}
