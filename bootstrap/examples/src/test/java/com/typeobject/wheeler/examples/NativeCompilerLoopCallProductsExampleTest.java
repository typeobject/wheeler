package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Instruction;
import com.typeobject.wheeler.core.bytecode.Opcode;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.util.LinkedHashMap;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Native evidence for loop call code and relocation products. */
final class NativeCompilerLoopCallProductsExampleTest {
  @Test
  void emitsCallsTypesAndStableRelocationsAtomically() throws Exception {
    VirtualMachine machine = new VirtualMachine(program(false), new byte[0], 262_144);

    machine.run();

    assertEquals(1, machine.global("valid"));
    assertEquals(3, machine.global("instructionCount"));
    assertEquals(80, machine.global("length"));
    assertEquals(2, machine.global("relocationCount"));
    assertEquals(20, machine.global("firstInstruction"));
    assertEquals(3, machine.global("firstTarget"));
    assertEquals(7, machine.global("firstOwner"));
    assertEquals(0xab, machine.global("firstIdentityByte"));
    assertEquals(22, machine.global("secondInstruction"));
    assertEquals(4, machine.global("secondTarget"));
    assertEquals(8, machine.global("secondOwner"));
    assertEquals(0xcd, machine.global("secondIdentityByte"));
    assertEquals(1, machine.global("firstType"));
    assertEquals(1, machine.global("secondType"));
    assertEquals(Opcode.CALL_VALUE.code(), machine.global("firstOpcode"));
    assertEquals(Opcode.CALL.code(), machine.global("thirdOpcode"));
  }

  @Test
  void rejectsUnknownTargetsBeforeCodeOrRelocationsPublish() throws Exception {
    VirtualMachine machine = new VirtualMachine(program(true), new byte[0], 262_144);

    machine.run();

    assertEquals(0, machine.global("valid"));
    assertEquals(0, machine.global("instructionCount"));
    assertEquals(0, machine.global("relocationCount"));
    assertEquals(91, machine.global("firstInstruction"));
    assertEquals(0xee, machine.global("firstIdentityByte"));
    assertEquals(0xff, machine.global("firstOutputByte"));
  }

  private static Program program(boolean invalidTarget) throws Exception {
    Map<String, String> sources = new LinkedHashMap<>();
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.loop_call_products"));
    sources.put("LoopCallProductsExample.w", """
        module example.loop_call_products;

        import wheeler.compiler.closure.loop_call_products;

        classical class LoopCallProductsExample {
          state long valid = 0;
          state long instructionCount = 0;
          state long length = 0;
          state long relocationCount = 0;
          state long firstInstruction = 0;
          state long firstTarget = 0;
          state long firstOwner = 0;
          state long firstIdentityByte = 0;
          state long secondInstruction = 0;
          state long secondTarget = 0;
          state long secondOwner = 0;
          state long secondIdentityByte = 0;
          state long firstType = 0;
          state long secondType = 0;
          state long firstOpcode = 0;
          state long thirdOpcode = 0;
          state long firstOutputByte = 0;

          entry void main(borrow utf8 input, borrow mut bytes output) {
            assert(bufferLength(input) == 0);
            region products = new region(/* bytes= */ 157712, /* allocations= */ 7);
            words calls = allocate(products, /* length= */ 1024);
            bytes identities = allocateBytes(products, /* length= */ 131072);
            words relocations = allocate(products, /* length= */ 768);
            bytes relocationIdentities = allocateBytes(products, /* length= */ 8192);
            words types = allocate(products, /* length= */ 512);
            words unused0 = allocate(products, /* length= */ 1);
            words unused1 = allocate(products, /* length= */ 1);
            set(calls, 0, 7);
            set(calls, 256, 1);
            set(calls, 512, 12);
            set(calls, 768, 3);
            set(calls, 1, 8);
            set(calls, 257, 0);
            set(calls, 513, 14);
            set(calls, 769, TARGET);
            setByte(identities, 3 * 32, 0xab);
            setByte(identities, 4 * 32, 0xcd);
            set(relocations, 0, 91);
            setByte(relocationIdentities, 0, 0xee);
            setByte(output, 0, 0xff);
            LoopCallPlan plan = writeLoopCallProducts(
              /* callCount= */ 2,
              calls,
              /* targetCount= */ 5,
              identities,
              /* instructionBase= */ 20,
              relocations,
              relocationIdentities,
              types,
              output
            );
            if (plan.valid) {
              valid = 1;
            }
            instructionCount = plan.instructionCount;
            length = plan.length;
            relocationCount = plan.relocationCount;
            firstInstruction = relocations[0];
            firstTarget = relocations[256];
            firstOwner = relocations[512];
            firstIdentityByte = relocationIdentities[0];
            secondInstruction = relocations[1];
            secondTarget = relocations[257];
            secondOwner = relocations[513];
            secondIdentityByte = relocationIdentities[32];
            firstType = types[0];
            secondType = types[1];
            firstOpcode = output[0] + output[1] * 256;
            thirdOpcode = output[64] + output[65] * 256;
            firstOutputByte = output[0];
            drop(unused1);
            drop(unused0);
            drop(types);
            drop(relocationIdentities);
            drop(relocations);
            drop(identities);
            drop(calls);
            drop(products);
          }
        }
        """.replace("TARGET", invalidTarget ? "5" : "4"));
    return new WheelerCompiler().compileModuleFiles(sources, "example.loop_call_products");
  }
}
