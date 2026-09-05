package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Opcode;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.util.LinkedHashMap;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Native call encoding, typed relocation, and whole-output rejection evidence. */
final class NativeCompilerLoopCallProductsExampleTest {
  @Test
  void emitsCallsTypesAndStableRelocationsAtomically() throws Exception {
    VirtualMachine machine = run(false, "");
    assertGlobals(machine, Map.of(
        "valid", 1, "instructionCount", 3, "length", 80, "relocationCount", 2,
        "localTypeCount", 2, "firstType", 1, "secondType", 1,
        "firstOpcode", Opcode.CALL_VALUE.code(), "callOpcode", Opcode.CALL.code()));
    assertGlobals(machine, Map.of(
        "firstInstruction", 20, "firstTarget", 3, "firstOwner", 7,
        "firstIdentityByte", 0xab, "secondInstruction", 22,
        "secondTarget", 4, "secondOwner", 8, "secondIdentityByte", 0xcd));
  }

  @Test
  void emitsTypedArgumentCallsAndRelocatesTheCallInstruction() throws Exception {
    VirtualMachine machine = run(true, "");
    assertGlobals(machine, Map.of(
        "valid", 1, "instructionCount", 7, "length", 192, "relocationCount", 2,
        "localTypeCount", 6, "firstType", 1, "secondType", 2,
        "firstOpcode", Opcode.LOCAL_MOVE.code(), "callOpcode", Opcode.CALL_VALUE.code()));
    assertEquals(22, machine.global("firstInstruction"));
    assertEquals(26, machine.global("secondInstruction"));
  }

  @Test
  void rejectsBadArgumentRowsAndTargetWindowsBeforePublication() throws Exception {
    for (String mutation : new String[] {
        "set(arguments, 2049, 1);",
        "set(argumentValues, 1, 1024);",
        "set(valueStarts, 1, 9223372036854775807); set(argumentValues, 2049, 1);",
        "set(valueStarts, 1, -9223372036854775807 - 1);",
        "set(argumentValues, 2049, 15);",
        "set(callArgumentCounts, 1, 9);",
        "set(callArgumentCounts, 1, -1);",
        "set(callArgumentStarts, 1, -9223372036854775807 - 1);",
        "set(targetParameterStarts, 4, 16384);",
        "set(targetParameterStarts, 4, -9223372036854775807 - 1);"
    }) {
      assertRejected(true, mutation);
    }
  }

  @Test
  void rejectsDetachedTargetsStatementsAndInstructionsBeforePublication() throws Exception {
    for (String mutation : new String[] {
        "set(calls, 769, 5);",
        "set(callStatements, 0, 4096);",
        "set(callInstructionStarts, 0, 32768);",
        "set(calls, 257, -1);"
    }) {
      assertRejected(false, mutation);
    }
  }

  private static void assertRejected(boolean arguments, String mutation) throws Exception {
    VirtualMachine machine = run(arguments, mutation);
    assertGlobals(machine, Map.of(
        "valid", 0, "instructionCount", 0, "length", 0, "relocationCount", 0,
        "localTypeCount", 0, "firstInstruction", 91, "firstIdentityByte", 0xee));
    byte[] expected = new byte[262_144];
    expected[0] = (byte) 0xff;
    assertArrayEquals(expected, machine.hostOutput());
  }

  private static void assertGlobals(VirtualMachine machine, Map<String, Integer> expected) {
    expected.forEach((name, value) -> assertEquals(value.longValue(), machine.global(name), name));
  }

  private static VirtualMachine run(boolean arguments, String mutation) throws Exception {
    VirtualMachine machine = new VirtualMachine(program(arguments, mutation), new byte[0], 262_144);
    CompilerMachineRunner.runWithoutRewindHistory(machine);
    return machine;
  }

  private static Program program(boolean arguments, String mutation) throws Exception {
    Map<String, String> sources = new LinkedHashMap<>(CompilerSources.moduleClosure(
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
          state long firstOpcode = 0;
          state long callOpcode = 0;

          private void fill(borrow mut words rows, long value) {
            long row = 0;
            while (row < bufferLength(rows)) limit 12288 {
              set(rows, row, value);
              row += 1;
            }
          }

          private void unchanged(borrow mut words rows, long expected) {
            long row = 0;
            while (row < bufferLength(rows)) limit 12288 {
              assert(rows[row] == expected);
              row += 1;
            }
          }

          entry void main(borrow utf8 input, borrow mut bytes output) {
            assert(bufferLength(input) == 0);
            region products = new region(/* bytes= */ 600064, /* allocations= */ 19);
            words calls = allocate(products, 1024);
            words callArgumentStarts = allocate(products, 256);
            words callArgumentCounts = allocate(products, 256);
            words callStatements = allocate(products, 256);
            words callInstructionStarts = allocate(products, 256);
            words arguments = allocate(products, 4096);
            words argumentValues = allocate(products, 4096);
            words valueStarts = allocate(products, 1024);
            bytes identities = allocateBytes(products, 131072);
            words targetParameterStarts = allocate(products, 4096);
            words targetParameterCounts = allocate(products, 4096);
            words targetParameterTypes = allocate(products, 16384);
            words relocations = allocate(products, 768);
            bytes relocationIdentities = allocateBytes(products, 8192);
            words types = allocate(products, 12288);
            words localWidths = allocate(products, 256);
            words conditionalValues = allocate(products, 256);
            words statementStarts = allocate(products, 4096);
            words statementWidths = allocate(products, 4096);
            set(calls, 0, 7);
            set(calls, 256, 1);
            set(calls, 768, 3);
            set(calls, 1, 8);
            set(calls, 769, 4);
            set(callStatements, 0, 10);
            set(callStatements, 1, 11);
            set(callInstructionStarts, 0, 20);
            set(callInstructionStarts, 1, SECOND_INSTRUCTION_START);
            set(statementStarts, 10, 12);
            set(statementStarts, 11, 20);
            set(statementWidths, 10, FIRST_WIDTH);
            set(statementWidths, 11, SECOND_WIDTH);
            set(localWidths, 0, FIRST_WIDTH);
            set(localWidths, 1, SECOND_WIDTH);
            ARGUMENT_SETUP
            setByte(identities, 3 * 32, 0xab);
            setByte(identities, 4 * 32, 0xcd);
            fill(relocations, 91);
            fill(types, -7);
            long identityByte = 0;
            while (identityByte < 8192) limit 8192 {
              setByte(relocationIdentities, identityByte, 0xee);
              identityByte += 1;
            }
            setByte(output, 0, 0xff);
            MUTATION
            LoopCallPlan plan = writeLoopCallProducts(
              2, calls, callArgumentStarts, callArgumentCounts, callStatements,
              callInstructionStarts, arguments, argumentValues, valueStarts, 5, identities,
              targetParameterStarts, targetParameterCounts, targetParameterTypes,
              relocations, relocationIdentities, types, localWidths, conditionalValues,
              statementStarts, statementWidths, output
            );
            if (plan.valid) {
              valid = 1;
            } else {
              unchanged(relocations, 91);
              unchanged(types, -7);
              identityByte = 0;
              while (identityByte < 8192) limit 8192 {
                assert(relocationIdentities[identityByte] == 0xee);
                identityByte += 1;
              }
            }
            long widthRow = 0;
            while (widthRow < 4096) limit 4096 {
              long expected = 0;
              if (widthRow == 10) { expected = FIRST_WIDTH; }
              if (widthRow == 11) { expected = SECOND_WIDTH; }
              assert(statementWidths[widthRow] == expected);
              if (widthRow < 256) {
                long callWidth = 0;
                if (widthRow == 0) { callWidth = FIRST_WIDTH; }
                if (widthRow == 1) { callWidth = SECOND_WIDTH; }
                assert(localWidths[widthRow] == callWidth);
              }
              widthRow += 1;
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
            firstType = types[8192];
            secondType = types[SECOND_TYPE_ROW];
            firstOpcode = output[0] + output[1] * 256;
            callOpcode = output[CALL_OFFSET] + output[CALL_OFFSET + 1] * 256;
            drop(statementWidths);
            drop(statementStarts);
            drop(conditionalValues);
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
        """.replace("ARGUMENT_SETUP", arguments ? """
            set(callArgumentCounts, 0, 1);
            set(callArgumentStarts, 1, 1);
            set(callArgumentCounts, 1, 1);
            set(arguments, 2048, 1);
            set(arguments, 2049, 2);
            set(argumentValues, 1, 1);
            set(valueStarts, 0, 3);
            set(valueStarts, 1, 5);
            set(targetParameterCounts, 3, 1);
            set(targetParameterTypes, 0, 1);
            set(targetParameterStarts, 4, 1);
            set(targetParameterCounts, 4, 1);
            set(targetParameterTypes, 1, 2);
            """ : "")
            .replace("FIRST_WIDTH", arguments ? "4" : "2")
            .replace("SECOND_WIDTH", arguments ? "2" : "0")
            .replace("SECOND_TYPE_ROW", arguments ? "8196" : "8193")
            .replace("SECOND_INSTRUCTION_START", arguments ? "24" : "22")
            .replace("CALL_OFFSET", arguments ? "48" : "64")
            .replace("MUTATION", mutation));
    return new WheelerCompiler().compileModuleFiles(sources, "example.loop_call_products");
  }
}
