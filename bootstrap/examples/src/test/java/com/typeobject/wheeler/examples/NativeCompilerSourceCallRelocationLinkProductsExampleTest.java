package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.FunctionBody;
import com.typeobject.wheeler.core.bytecode.Global;
import com.typeobject.wheeler.core.bytecode.Instruction;
import com.typeobject.wheeler.core.bytecode.Opcode;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Native evidence for retained source-call relocation linking. */
final class NativeCompilerSourceCallRelocationLinkProductsExampleTest {
  @Test
  void excludesStubInstructionsAndResolvesTheFinalTarget() throws Exception {
    VirtualMachine machine = new VirtualMachine(program(0));

    CompilerMachineRunner.runWithoutRewindHistory(machine);

    assertEquals(1, machine.global("retainedFunctions"));
    assertEquals(4, machine.global("retainedInstructions"));
    assertEquals(2, machine.global("excludedFunctions"));
    assertEquals(1, machine.global("resolvedTarget"));
    assertEquals(48, machine.global("linkedLength"));
    assertEquals(1, machine.global("linkedOperand"));
    assertEquals(1, machine.global("inverseLinkedOperand"));
    assertEquals(0, machine.global("suffixByte"));
    assertEquals(1, machine.global("published"));

    FunctionBody caller = new FunctionBody(
        0,
        "caller",
        false,
        0,
        List.of(),
        null,
        List.of(Instruction.of(Opcode.CALL, machine.global("linkedOperand")),
            Instruction.of(Opcode.RETURN)),
        List.of(Instruction.of(Opcode.UNCALL, machine.global("inverseLinkedOperand")),
            Instruction.of(Opcode.RETURN)));
    FunctionBody target = new FunctionBody(
        1,
        "target",
        false,
        0,
        List.of(),
        null,
        List.of(Instruction.of(Opcode.ADD_CONST, 0, 3), Instruction.of(Opcode.RETURN)),
        List.of(Instruction.of(Opcode.SUB_CONST, 0, 3), Instruction.of(Opcode.RETURN)));
    FunctionBody library = new FunctionBody(
        2,
        "$library",
        false,
        0,
        List.of(),
        null,
        List.of(Instruction.of(Opcode.HALT)),
        List.of());
    VirtualMachine executed = new VirtualMachine(
        new Program("linked-call-chain", 2, List.of(new Global("marker", 0)),
            List.of(caller, target, library)));
    executed.invoke(caller.id(), false);
    assertEquals(3, executed.global(0));
    executed.establishEffectBoundary();
    executed.invoke(caller.id(), true);
    assertEquals(0, executed.global(0));
  }

  @Test
  void rejectsAMismatchedRelocationOwnerBeforePublication() throws Exception {
    VirtualMachine machine = new VirtualMachine(program(1));

    assertThrows(VmTrap.class, () -> CompilerMachineRunner.runWithoutRewindHistory(machine));
    assertEquals(0, machine.global("published"));
  }

  @Test
  void rejectsAStaleTargetIdentityBeforePublication() throws Exception {
    VirtualMachine machine = new VirtualMachine(program(2));

    assertThrows(VmTrap.class, () -> CompilerMachineRunner.runWithoutRewindHistory(machine));
    assertEquals(0, machine.global("published"));
  }

  private static Program program(int malformed) throws Exception {
    Map<String, String> sources = new LinkedHashMap<>();
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.source_call_relocation_link_products"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.linked_instruction_code"));
    CoreSources.addBinaryClosure(sources);
    sources.put("FixedBinary.w", CoreSources.read("encoding/FixedBinary.w"));
    sources.put("SourceCallRelocationLinkProductsExample.w", """
        module example.source_call_relocation_link_products;

        import wheeler.compiler.closure.callable_function_rows;
        import wheeler.compiler.closure.linked_instruction_code;
        import wheeler.compiler.closure.source_call_relocation_link_products;
        import wheeler.compiler.opcodes;

        classical class SourceCallRelocationLinkProductsExample {
          state long retainedFunctions = 0;
          state long retainedInstructions = 0;
          state long excludedFunctions = 0;
          state long resolvedTarget = -1;
          state long linkedLength = 0;
          state long linkedOperand = -1;
          state long inverseLinkedOperand = -1;
          state long suffixByte = -1;
          state long published = 0;

          entry void main() {
            region products = new region(/* bytes= */ 1728512, /* allocations= */ 11);
            words instructionRows = allocate(products, /* length= */ 24576);
            words relocationRows = allocate(products, /* length= */ 768);
            words relocationOwners = allocate(products, /* length= */ 256);
            bytes relocationIdentities = allocateBytes(products, /* length= */ 8192);
            bytes callableIdentities = allocateBytes(products, /* length= */ 131072);
            bytes functionIdentities = allocateBytes(products, /* length= */ 131072);
            words hashSlots = allocate(products, /* length= */ 8192);
            words hashFunctions = allocate(products, /* length= */ 8192);
            words callableFunctions = allocate(products, /* length= */ 4096);
            words publishedFunctions = allocate(products, /* length= */ 4096);
            words resolvedTargets = allocate(products, /* length= */ 131072);
            set(instructionRows, 0, 0);
            set(instructionRows, 1, 0);
            set(instructionRows, 2, 0);
            set(instructionRows, 3, 0);
            set(instructionRows, 4, 1);
            set(instructionRows, 5, 2);
            set(instructionRows, 4098, 1);
            set(instructionRows, 4099, 1);
            set(instructionRows, 12288, OPCODE_CALL);
            set(instructionRows, 12289, OPCODE_RETURN);
            set(instructionRows, 12290, OPCODE_UNCALL);
            set(instructionRows, 12291, OPCODE_RETURN);
            set(relocationOwners, 0, RELOCATION_OWNER);
            setByte(relocationIdentities, 0, 42);
            setByte(callableIdentities, 0, 9);
            setByte(callableIdentities, 32, 42);
            setByte(functionIdentities, 0, 9);
            setByte(functionIdentities, 32, TARGET_IDENTITY);
            mapCallableFunctionRows(
              /* callableCount= */ 2,
              callableIdentities,
              /* functionCount= */ 2,
              functionIdentities,
              hashSlots,
              hashFunctions,
              callableFunctions,
              publishedFunctions
            );
            SourceCallRelocationLinkPlan plan = materializeSourceCallRelocationLinkProducts(
              /* localFunctionCount= */ 1,
              /* compiledFunctionCount= */ 3,
              /* compiledInstructionCount= */ 6,
              instructionRows,
              /* relocationCount= */ 1,
              relocationRows,
              relocationOwners,
              relocationIdentities,
              /* finalFunctionCount= */ 2,
              functionIdentities,
              hashSlots,
              hashFunctions,
              resolvedTargets
            );
            retainedFunctions = plan.functionCount;
            retainedInstructions = plan.instructionCount;
            excludedFunctions = plan.excludedFunctionCount;
            resolvedTarget = resolvedTargets[0];
            region codeProducts = new region(/* bytes= */ 7348352, /* allocations= */ 5);
            bytes archive = allocateBytes(codeProducts, /* length= */ 64);
            words artifactStarts = allocate(codeProducts, /* length= */ 512);
            words artifactLengths = allocate(codeProducts, /* length= */ 512);
            words closureInstructions = allocate(codeProducts, /* length= */ 917504);
            bytes linkedCode = allocateBytes(codeProducts, /* length= */ 64);
            setByte(archive, 0, OPCODE_CALL % 256);
            setByte(archive, 4, 16);
            setByte(archive, 16, OPCODE_RETURN % 256);
            setByte(archive, 20, 8);
            setByte(archive, 24, OPCODE_UNCALL % 256);
            setByte(archive, 28, 16);
            setByte(archive, 40, OPCODE_RETURN % 256);
            setByte(archive, 44, 8);
            setByte(archive, 48, 77);
            set(artifactLengths, 0, 64);
            set(closureInstructions, 262144, 0);
            set(closureInstructions, 262145, 0);
            set(closureInstructions, 262146, 0);
            set(closureInstructions, 262147, 0);
            set(closureInstructions, 393216, 0);
            set(closureInstructions, 393217, 16);
            set(closureInstructions, 393218, 24);
            set(closureInstructions, 393219, 40);
            set(closureInstructions, 524288, OPCODE_CALL);
            set(closureInstructions, 524289, OPCODE_RETURN);
            set(closureInstructions, 524290, OPCODE_UNCALL);
            set(closureInstructions, 524291, OPCODE_RETURN);
            set(closureInstructions, 786432, 16);
            set(closureInstructions, 786433, 8);
            set(closureInstructions, 786434, 16);
            set(closureInstructions, 786435, 8);
            linkedLength = emitResolvedLinkedInstructionCodeAt(
              archive,
              /* archiveBytes= */ 64,
              artifactStarts,
              artifactLengths,
              /* functionCount= */ 2,
              plan.instructionCount,
              closureInstructions,
              resolvedTargets,
              linkedCode,
              /* outputStart= */ 0
            );
            linkedOperand = linkedCode[8];
            inverseLinkedOperand = linkedCode[32];
            suffixByte = linkedCode[48];
            published = 1;
            drop(linkedCode);
            drop(closureInstructions);
            drop(artifactLengths);
            drop(artifactStarts);
            drop(archive);
            drop(codeProducts);
            drop(resolvedTargets);
            drop(publishedFunctions);
            drop(callableFunctions);
            drop(hashFunctions);
            drop(hashSlots);
            drop(functionIdentities);
            drop(callableIdentities);
            drop(relocationIdentities);
            drop(relocationOwners);
            drop(relocationRows);
            drop(instructionRows);
            drop(products);
          }
        }
        """.replace("RELOCATION_OWNER", malformed == 1 ? "1" : "0")
            .replace("TARGET_IDENTITY", malformed == 2 ? "41" : "42"));
    return new WheelerCompiler().compileModuleFiles(
        sources, "example.source_call_relocation_link_products");
  }
}
