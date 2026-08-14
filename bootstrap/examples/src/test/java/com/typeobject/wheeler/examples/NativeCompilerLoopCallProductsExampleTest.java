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
    VirtualMachine machine = new VirtualMachine(program(false, false, false), new byte[0], 262_144);

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
    assertEquals(2, machine.global("localTypeCount"));
    assertEquals(1, machine.global("firstType"));
    assertEquals(1, machine.global("secondType"));
    assertEquals(2, machine.global("firstLocalWidth"));
    assertEquals(0, machine.global("secondLocalWidth"));
    assertEquals(5, machine.global("firstStatementWidth"));
    assertEquals(4, machine.global("secondStatementWidth"));
    assertEquals(Opcode.CALL_VALUE.code(), machine.global("firstOpcode"));
    assertEquals(Opcode.CALL.code(), machine.global("thirdOpcode"));
  }

  @Test
  void emitsTypedArgumentCallsAndRelocatesTheCallInstruction() throws Exception {
    VirtualMachine machine = new VirtualMachine(argumentProgram(false, false), new byte[0], 262_144);

    machine.run();

    assertEquals(1, machine.global("valid"));
    assertEquals(7, machine.global("instructionCount"));
    assertEquals(192, machine.global("length"));
    assertEquals(6, machine.global("localTypeCount"));
    assertEquals(Opcode.LOCAL_MOVE.code(), machine.global("firstOpcode"));
    assertEquals(Opcode.CALL_VALUE.code(), machine.global("thirdOpcode"));
    assertEquals(Opcode.LOCAL_MOVE.code(), machine.global("fourthOpcode"));
    assertEquals(Opcode.CALL_VOID.code(), machine.global("sixthOpcode"));
    assertEquals(22, machine.global("firstInstruction"));
    assertEquals(26, machine.global("secondInstruction"));
    assertEquals(1, machine.global("firstType"));
    assertEquals(2, machine.global("secondType"));
    assertEquals(4, machine.global("firstLocalWidth"));
    assertEquals(2, machine.global("secondLocalWidth"));
    assertEquals(7, machine.global("firstStatementWidth"));
    assertEquals(6, machine.global("secondStatementWidth"));
  }

  @Test
  void rejectsArgumentTypeMismatchBeforePublication() throws Exception {
    VirtualMachine machine = new VirtualMachine(argumentProgram(true, false), new byte[0], 262_144);

    machine.run();

    assertEquals(0, machine.global("valid"));
    assertEquals(0, machine.global("instructionCount"));
    assertEquals(0, machine.global("localTypeCount"));
    assertEquals(3, machine.global("firstStatementWidth"));
    assertEquals(4, machine.global("secondStatementWidth"));
    assertEquals(91, machine.global("firstInstruction"));
    assertEquals(0xee, machine.global("firstIdentityByte"));
    assertEquals(0xff, machine.global("firstOutputByte"));
  }

  @Test
  void rejectsUnknownArgumentValueProductsBeforePublication() throws Exception {
    VirtualMachine machine = new VirtualMachine(argumentProgram(false, true), new byte[0], 262_144);

    machine.run();

    assertEquals(0, machine.global("valid"));
    assertEquals(0, machine.global("instructionCount"));
    assertEquals(0, machine.global("localTypeCount"));
    assertEquals(3, machine.global("firstStatementWidth"));
    assertEquals(91, machine.global("firstInstruction"));
    assertEquals(0xee, machine.global("firstIdentityByte"));
    assertEquals(0xff, machine.global("firstOutputByte"));
  }

  @Test
  void rejectsUnknownTargetsBeforeCodeOrRelocationsPublish() throws Exception {
    VirtualMachine machine = new VirtualMachine(program(true, false, false), new byte[0], 262_144);

    machine.run();

    assertEquals(0, machine.global("valid"));
    assertEquals(0, machine.global("instructionCount"));
    assertEquals(0, machine.global("relocationCount"));
    assertEquals(3, machine.global("firstStatementWidth"));
    assertEquals(4, machine.global("secondStatementWidth"));
    assertEquals(91, machine.global("firstInstruction"));
    assertEquals(0xee, machine.global("firstIdentityByte"));
    assertEquals(0xff, machine.global("firstOutputByte"));
  }

  @Test
  void rejectsDetachedCallStatementsBeforePublication() throws Exception {
    VirtualMachine machine = new VirtualMachine(program(false, true, false), new byte[0], 262_144);

    machine.run();

    assertEquals(0, machine.global("valid"));
    assertEquals(0, machine.global("instructionCount"));
    assertEquals(3, machine.global("firstStatementWidth"));
    assertEquals(4, machine.global("secondStatementWidth"));
    assertEquals(91, machine.global("firstInstruction"));
    assertEquals(0xee, machine.global("firstIdentityByte"));
    assertEquals(0xff, machine.global("firstOutputByte"));
  }

  @Test
  void rejectsInvalidPlannedInstructionBeforePublication() throws Exception {
    VirtualMachine machine = new VirtualMachine(program(false, false, true), new byte[0], 262_144);

    machine.run();

    assertEquals(0, machine.global("valid"));
    assertEquals(0, machine.global("instructionCount"));
    assertEquals(3, machine.global("firstStatementWidth"));
    assertEquals(91, machine.global("firstInstruction"));
    assertEquals(0xee, machine.global("firstIdentityByte"));
    assertEquals(0xff, machine.global("firstOutputByte"));
  }

  private static Program program(
      boolean invalidTarget,
      boolean invalidStatement,
      boolean invalidInstruction) throws Exception {
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
          state long localTypeCount = 0;
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
          state long firstLocalWidth = 0;
          state long secondLocalWidth = 0;
          state long firstStatementWidth = 0;
          state long secondStatementWidth = 0;
          state long firstOpcode = 0;
          state long thirdOpcode = 0;
          state long fourthOpcode = 0;
          state long sixthOpcode = 0;
          state long firstOutputByte = 0;

          entry void main(borrow utf8 input, borrow mut bytes output) {
            assert(bufferLength(input) == 0);
            region products = new region(/* bytes= */ 524288, /* allocations= */ 18);
            words calls = allocate(products, /* length= */ 1024);
            words callArgumentStarts = allocate(products, /* length= */ 256);
            words callArgumentCounts = allocate(products, /* length= */ 256);
            words callStatements = allocate(products, /* length= */ 256);
            words callInstructionStarts = allocate(products, /* length= */ 256);
            words arguments = allocate(products, /* length= */ 3584);
            words argumentValues = allocate(products, /* length= */ 3584);
            words valueStarts = allocate(products, /* length= */ 1024);
            bytes identities = allocateBytes(products, /* length= */ 131072);
            words targetParameterStarts = allocate(products, /* length= */ 4096);
            words targetParameterCounts = allocate(products, /* length= */ 4096);
            words targetParameterTypes = allocate(products, /* length= */ 16384);
            words relocations = allocate(products, /* length= */ 768);
            bytes relocationIdentities = allocateBytes(products, /* length= */ 8192);
            words types = allocate(products, /* length= */ 4096);
            words localWidths = allocate(products, /* length= */ 256);
            words statementStarts = allocate(products, /* length= */ 4096);
            words statementWidths = allocate(products, /* length= */ 4096);
            set(calls, 0, 7);
            set(calls, 256, 1);
            set(calls, 512, 99);
            set(calls, 768, 3);
            set(calls, 1, 8);
            set(calls, 257, 0);
            set(calls, 513, 98);
            set(calls, 769, TARGET);
            set(callStatements, 0, STATEMENT);
            set(callStatements, 1, 11);
            set(callInstructionStarts, 0, INSTRUCTION_START);
            set(callInstructionStarts, 1, 22);
            set(statementStarts, 10, 12);
            set(statementStarts, 11, 14);
            set(statementWidths, 10, 3);
            set(statementWidths, 11, 4);
            setByte(identities, 3 * 32, 0xab);
            setByte(identities, 4 * 32, 0xcd);
            set(relocations, 0, 91);
            setByte(relocationIdentities, 0, 0xee);
            setByte(output, 0, 0xff);
            LoopCallPlan plan = writeLoopCallProducts(
              /* callCount= */ 2,
              calls,
              callArgumentStarts,
              callArgumentCounts,
              callStatements,
              callInstructionStarts,
              arguments,
              argumentValues,
              valueStarts,
              /* targetCount= */ 5,
              identities,
              targetParameterStarts,
              targetParameterCounts,
              targetParameterTypes,
              relocations,
              relocationIdentities,
              types,
              localWidths,
              statementStarts,
              statementWidths,
              output
            );
            if (plan.valid) {
              valid = 1;
            }
            instructionCount = plan.instructionCount;
            length = plan.length;
            relocationCount = plan.relocationCount;
            localTypeCount = plan.localTypeCount;
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
            firstLocalWidth = localWidths[0];
            secondLocalWidth = localWidths[1];
            firstStatementWidth = statementWidths[10];
            secondStatementWidth = statementWidths[11];
            firstOpcode = output[0] + output[1] * 256;
            thirdOpcode = output[64] + output[65] * 256;
            fourthOpcode = output[112] + output[113] * 256;
            sixthOpcode = output[160] + output[161] * 256;
            firstOutputByte = output[0];
            drop(statementWidths);
            drop(statementStarts);
            drop(localWidths);
            drop(types);
            drop(relocationIdentities);
            drop(relocations);
            drop(targetParameterTypes);
            drop(targetParameterCounts);
            drop(targetParameterStarts);
            drop(identities);
            drop(valueStarts);
            drop(argumentValues);
            drop(arguments);
            drop(callInstructionStarts);
            drop(callStatements);
            drop(callArgumentCounts);
            drop(callArgumentStarts);
            drop(calls);
            drop(products);
          }
        }
        """.replace("TARGET", invalidTarget ? "5" : "4")
            .replace("STATEMENT", invalidStatement ? "4096" : "10")
            .replace("INSTRUCTION_START", invalidInstruction ? "32768" : "20"));
    return new WheelerCompiler().compileModuleFiles(sources, "example.loop_call_products");
  }


  private static Program argumentProgram(
      boolean invalidType,
      boolean invalidValueProduct) throws Exception {
    Map<String, String> sources = new LinkedHashMap<>();
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.loop_call_products"));
    sources.put("LoopArgumentCallProductsExample.w", """
        module example.loop_argument_call_products;

        import wheeler.compiler.closure.loop_call_products;

        classical class LoopArgumentCallProductsExample {
          state long valid = 0;
          state long instructionCount = 0;
          state long length = 0;
          state long localTypeCount = 0;
          state long firstLocalWidth = 0;
          state long secondLocalWidth = 0;
          state long firstStatementWidth = 0;
          state long secondStatementWidth = 0;
          state long firstInstruction = 0;
          state long secondInstruction = 0;
          state long firstIdentityByte = 0;
          state long firstType = 0;
          state long secondType = 0;
          state long firstOpcode = 0;
          state long thirdOpcode = 0;
          state long fourthOpcode = 0;
          state long sixthOpcode = 0;
          state long firstOutputByte = 0;

          entry void main(borrow utf8 input, borrow mut bytes output) {
            assert(bufferLength(input) == 0);
            region products = new region(/* bytes= */ 524288, /* allocations= */ 18);
            words calls = allocate(products, /* length= */ 1024);
            words callArgumentStarts = allocate(products, /* length= */ 256);
            words callArgumentCounts = allocate(products, /* length= */ 256);
            words callStatements = allocate(products, /* length= */ 256);
            words callInstructionStarts = allocate(products, /* length= */ 256);
            words arguments = allocate(products, /* length= */ 3584);
            words argumentValues = allocate(products, /* length= */ 3584);
            words valueStarts = allocate(products, /* length= */ 1024);
            bytes identities = allocateBytes(products, /* length= */ 131072);
            words targetParameterStarts = allocate(products, /* length= */ 4096);
            words targetParameterCounts = allocate(products, /* length= */ 4096);
            words targetParameterTypes = allocate(products, /* length= */ 16384);
            words relocations = allocate(products, /* length= */ 768);
            bytes relocationIdentities = allocateBytes(products, /* length= */ 8192);
            words types = allocate(products, /* length= */ 4096);
            words localWidths = allocate(products, /* length= */ 256);
            words statementStarts = allocate(products, /* length= */ 4096);
            words statementWidths = allocate(products, /* length= */ 4096);
            set(calls, 0, 7);
            set(calls, 256, 1);
            set(calls, 512, 99);
            set(calls, 768, 3);
            set(calls, 1, 8);
            set(calls, 257, 0);
            set(calls, 513, 98);
            set(calls, 769, 4);
            set(callStatements, 0, 10);
            set(callStatements, 1, 11);
            set(callInstructionStarts, 0, 20);
            set(callInstructionStarts, 1, 24);
            set(statementStarts, 10, 12);
            set(statementStarts, 11, 20);
            set(statementWidths, 10, 3);
            set(statementWidths, 11, 4);
            set(callArgumentStarts, 0, 0);
            set(callArgumentCounts, 0, 1);
            set(callArgumentStarts, 1, 1);
            set(callArgumentCounts, 1, 1);
            set(arguments, 0, 99);
            set(arguments, 1792, 1);
            set(arguments, 1, 99);
            set(arguments, 1793, ARGUMENT_TYPE);
            set(argumentValues, 0, 0);
            set(argumentValues, 1792, 0);
            set(argumentValues, 1, VALUE_PRODUCT);
            set(argumentValues, 1793, 0);
            set(valueStarts, 0, 3);
            set(valueStarts, 1, 5);
            set(targetParameterStarts, 3, 0);
            set(targetParameterCounts, 3, 1);
            set(targetParameterTypes, 0, 1);
            set(targetParameterStarts, 4, 1);
            set(targetParameterCounts, 4, 1);
            set(targetParameterTypes, 1, 2);
            setByte(identities, 3 * 32, 0xab);
            setByte(identities, 4 * 32, 0xcd);
            set(relocations, 0, 91);
            setByte(relocationIdentities, 0, 0xee);
            setByte(output, 0, 0xff);
            LoopCallPlan plan = writeLoopCallProducts(
              /* callCount= */ 2,
              calls,
              callArgumentStarts,
              callArgumentCounts,
              callStatements,
              callInstructionStarts,
              arguments,
              argumentValues,
              valueStarts,
              /* targetCount= */ 5,
              identities,
              targetParameterStarts,
              targetParameterCounts,
              targetParameterTypes,
              relocations,
              relocationIdentities,
              types,
              localWidths,
              statementStarts,
              statementWidths,
              output
            );
            if (plan.valid) {
              valid = 1;
            }
            instructionCount = plan.instructionCount;
            length = plan.length;
            localTypeCount = plan.localTypeCount;
            firstInstruction = relocations[0];
            secondInstruction = relocations[1];
            firstIdentityByte = relocationIdentities[0];
            firstType = types[0];
            secondType = types[4];
            firstLocalWidth = localWidths[0];
            secondLocalWidth = localWidths[1];
            firstStatementWidth = statementWidths[10];
            secondStatementWidth = statementWidths[11];
            firstOpcode = output[0] + output[1] * 256;
            thirdOpcode = output[48] + output[49] * 256;
            fourthOpcode = output[112] + output[113] * 256;
            sixthOpcode = output[160] + output[161] * 256;
            firstOutputByte = output[0];
            drop(statementWidths);
            drop(statementStarts);
            drop(localWidths);
            drop(types);
            drop(relocationIdentities);
            drop(relocations);
            drop(targetParameterTypes);
            drop(targetParameterCounts);
            drop(targetParameterStarts);
            drop(identities);
            drop(valueStarts);
            drop(argumentValues);
            drop(arguments);
            drop(callInstructionStarts);
            drop(callStatements);
            drop(callArgumentCounts);
            drop(callArgumentStarts);
            drop(calls);
            drop(products);
          }
        }
        """.replace("ARGUMENT_TYPE", invalidType ? "1" : "2")
            .replace("VALUE_PRODUCT", invalidValueProduct ? "1024" : "1"));
    return new WheelerCompiler().compileModuleFiles(
        sources, "example.loop_argument_call_products");
  }
}
