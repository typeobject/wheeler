package com.typeobject.wheeler.examples.calls;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Instruction;
import com.typeobject.wheeler.core.bytecode.Opcode;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.examples.CompilerMachineRunner;
import com.typeobject.wheeler.examples.CompilerSources;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.List;
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
        "set(arguments, ARGUMENT_TYPE_ROW + 1, 1);",
        "set(argumentValues, 1, 1024);",
        "set(valueStarts, 1, 9223372036854775807); set(argumentValues, ARGUMENT_TYPE_ROW + 1, 1);",
        "set(valueStarts, 1, -9223372036854775807 - 1);",
        "set(argumentValues, ARGUMENT_TYPE_ROW + 1, 15);",
        "set(callArgumentCounts, 1, 65);",
        "set(callArgumentCounts, 1, -1);",
        "set(callArgumentStarts, 1, -9223372036854775807 - 1);",
        "set(callArgumentStarts, 1, 16384);",
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

  @Test
  void storesCallResultsWithoutASecondLocalAndReplaysTheWholePublication() throws Exception {
    for (boolean arguments : new boolean[] {false, true}) {
      VirtualMachine machine = new VirtualMachine(program(arguments, "", true), new byte[0], 262_144);
      var borrowedRegions = machine.snapshot().regions().stream().map(r -> r.id()).toList();
      while (machine.global("phase") != 1) machine.stepWithoutRewindHistory();
      var before = machine.snapshot();
      while (machine.global("phase") != 2) machine.step();
      var after = machine.snapshot();
      assertEquals(1, machine.global("valid"));
      assertEquals(arguments ? 5 : 1, machine.global("localTypeCount"));
      assertStorePublication(machine, arguments);
      int caller = before.regions().stream().filter(r -> r.maxObjects() == 19).findFirst().orElseThrow().id();
      var original = before.buffers().stream().filter(b -> b.regionId() == caller).toList();
      var current = after.buffers().stream().filter(b -> b.regionId() == caller).toList();
      for (int row = 0; row < original.size(); row++) {
        if (row < 12 || 14 < row) assertEquals(original.get(row), current.get(row));
      }
      int transitions = machine.historySize();
      while (machine.historySize() > 0) machine.rewindOne();
      assertEquals(before, machine.snapshot());
      for (int step = 0; step < transitions; step++) machine.step();
      assertEquals(after, machine.snapshot());
      while (machine.historySize() > 0) machine.rewindOne();
      for (int step = 0; step < transitions; step++) machine.stepWithoutRewindHistory();
      CompilerMachineRunner.runWithoutRewindHistory(machine);
      for (var buffer : machine.snapshot().buffers()) {
        if (!borrowedRegions.contains(buffer.regionId())) assertEquals(true, buffer.dropped());
      }
    }
  }

  @Test
  void rejectsGlobalOperandsAndMalformedLaterCallsBeforeAnyPublication() throws Exception {
    for (String mutation : new String[] {
        "set(resultOperands, 0, -1);",
        "set(resultOperands, 0, 8);",
        "set(resultOperands, 0, 9223372036854775807);",
        "set(resultOperands, 1, 1);",
        "set(calls, 257, 10);"
    }) {
      VirtualMachine machine = new VirtualMachine(program(false, mutation, true), new byte[0], 262_144);
      CompilerMachineRunner.runWithoutRewindHistory(machine);
      assertEquals(0, machine.global("valid"));
      byte[] expected = new byte[262_144];
      expected[0] = (byte) 0xff;
      assertArrayEquals(expected, machine.hostOutput());
    }
  }

  @Test
  void fillsTheFinalFrameLocalAtTheSharedArityLimit() throws Exception {
    int arity = 64;
    int width = arity * 2 + 1;
    int frameLocals = 256;
    int base = frameLocals - width;
    VirtualMachine machine = new VirtualMachine(program("", true, arity, base, 0), new byte[0], 262_144);
    while (machine.global("phase") != 2) machine.stepWithoutRewindHistory();
    assertEquals(1, machine.global("valid"));
    assertStorePublication(machine, arity, base, 0, 0);
    CompilerMachineRunner.runWithoutRewindHistory(machine);
    for (String mutation : new String[] {
        "set(statementStarts, 10, 128);", "set(callArgumentCounts, 0, 65);"
    }) {
      VirtualMachine rejected = new VirtualMachine(program(mutation, true, arity, base, 0), new byte[0], 262_144);
      CompilerMachineRunner.runWithoutRewindHistory(rejected);
      assertEquals(0, rejected.global("valid"));
      byte[] expected = new byte[262_144];
      expected[0] = (byte) 0xff;
      assertArrayEquals(expected, rejected.hostOutput());
    }
  }

  private static void assertStorePublication(VirtualMachine machine, boolean arguments) {
    assertStorePublication(machine, arguments ? 1 : 0, 12, arguments ? 1 : 0, 3);
  }

  private static void assertStorePublication(VirtualMachine machine, int arity, int base,
      int secondArity, int firstValueBase) {
    List<Instruction> instructions = new ArrayList<>();
    for (int argument = 0; argument < arity; argument++) {
      instructions.add(Instruction.of(Opcode.LOCAL_MOVE, base + argument, firstValueBase + argument));
    }
    for (int argument = 0; argument < arity; argument++) {
      instructions.add(Instruction.of(Opcode.LOCAL_MOVE, base + arity + argument, base + argument));
    }
    int result = base + arity * 2;
    instructions.add(Instruction.of(Opcode.CALL_VALUE, 3, arity > 0 ? base + arity : 0, arity, result));
    instructions.add(Instruction.of(Opcode.LOCAL_STORE_GLOBAL, 7, result));
    if (secondArity > 0) {
      instructions.add(Instruction.of(Opcode.LOCAL_MOVE, 20, 5));
      instructions.add(Instruction.of(Opcode.LOCAL_MOVE, 21, 20));
      instructions.add(Instruction.of(Opcode.CALL_VOID, 4, 21, 1));
    } else {
      instructions.add(Instruction.of(Opcode.CALL, 4));
    }
    ByteBuffer expected = ByteBuffer.allocate(262_144).order(ByteOrder.LITTLE_ENDIAN);
    for (var instruction : instructions) {
      int operands = instruction.operands().size();
      int bytes = Short.BYTES * 2 + Integer.BYTES + operands * Long.BYTES;
      expected.putShort((short) instruction.opcode().code()).putShort((short) operands).putInt(bytes);
      for (long operand : instruction.operands()) expected.putLong(operand);
    }
    assertEquals(expected.position(), machine.global("length"));
    assertArrayEquals(expected.array(), machine.hostOutput());
    int region = machine.snapshot().regions().stream().filter(r -> r.maxObjects() == 19)
        .findFirst().orElseThrow().id();
    var buffers = machine.snapshot().buffers().stream().filter(b -> b.regionId() == region).toList();
    long[] relocations = new long[768];
    Arrays.fill(relocations, 91);
    relocations[0] = 20 + arity * 2;
    relocations[1] = 20 + arity * 2 + 2 + secondArity * 2;
    relocations[256] = 3; relocations[257] = 4;
    relocations[512] = 7; relocations[513] = 8;
    assertEquals(Arrays.stream(relocations).boxed().toList(), buffers.get(12).elements());
    long[] identities = new long[8192];
    Arrays.fill(identities, 0xee);
    Arrays.fill(identities, 0, 64, 0);
    identities[0] = 0xab; identities[32] = 0xcd;
    assertEquals(Arrays.stream(identities).boxed().toList(), buffers.get(13).elements());
    long[] types = new long[12288];
    Arrays.fill(types, -7);
    int firstWidth = arity * 2 + 1;
    int count = firstWidth + secondArity * 2;
    for (int row = 0; row < count; row++) {
      boolean first = row < firstWidth;
      types[row] = first ? 7 : 8;
      types[4096 + row] = first ? base + row : 20 + row - firstWidth;
      types[8192 + row] = first ? 1 : 2;
    }
    assertEquals(Arrays.stream(types).boxed().toList(), buffers.get(14).elements());
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
    return program(arguments, mutation, false);
  }

  private static Program program(boolean arguments, String mutation, boolean store) throws Exception {
    return program(mutation, store, arguments ? 1 : 0, 12, arguments ? 1 : 0);
  }

  private static Program program(String mutation, boolean store, int arity, int base,
      int secondArity) throws Exception {
    Map<String, String> sources = new LinkedHashMap<>(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.loop_call_products"));
    sources.put("LoopCallProductsExample.w", """
        module example.loop_call_products;

        import wheeler.compiler.closure.loop_call_products;

        classical class LoopCallProductsExample {
          private const long ARGUMENT_TYPE_ROW = 16384;
          private const long ARGUMENT_WORDS = ARGUMENT_TYPE_ROW * 2;
          private const long CALL_CAPACITY = 256;
          private const long CALL_COLUMNS = 4;
          private const long CALL_VECTOR_TABLES = 6;
          private const long ARGUMENT_TABLES = 2;
          private const long VALUE_CAPACITY = 1024;
          private const long TARGET_CAPACITY = 4096;
          private const long TARGET_VECTOR_TABLES = 2;
          private const long PARAMETER_CAPACITY = 16384;
          private const long RELOCATION_COLUMNS = 3;
          private const long TYPE_CAPACITY = 4096;
          private const long TYPE_COLUMNS = 3;
          private const long STATEMENT_CAPACITY = 4096;
          private const long STATEMENT_TABLES = 2;
          private const long IDENTITY_BYTES = 32;
          private const long WORD_BYTES = 8;
          private const long PRODUCT_WORDS = CALL_CAPACITY * (CALL_COLUMNS + CALL_VECTOR_TABLES)
            + ARGUMENT_WORDS * ARGUMENT_TABLES + VALUE_CAPACITY
            + TARGET_CAPACITY * TARGET_VECTOR_TABLES + PARAMETER_CAPACITY
            + CALL_CAPACITY * RELOCATION_COLUMNS + TYPE_CAPACITY * TYPE_COLUMNS
            + STATEMENT_CAPACITY * STATEMENT_TABLES;
          private const long PRODUCT_BYTES = PRODUCT_WORDS * WORD_BYTES
            + (TARGET_CAPACITY + CALL_CAPACITY) * IDENTITY_BYTES;
          private const long PRODUCT_BUFFERS = 1 + CALL_VECTOR_TABLES + ARGUMENT_TABLES
            + 1 + TARGET_VECTOR_TABLES + 1 + 1 + 1 + STATEMENT_TABLES + 2;
          state long phase = 0;
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
            region products = new region(PRODUCT_BYTES, PRODUCT_BUFFERS);
            words calls = allocate(products, 1024);
            words callArgumentStarts = allocate(products, 256);
            words callArgumentCounts = allocate(products, 256);
            words callStatements = allocate(products, 256);
            words callInstructionStarts = allocate(products, 256);
            words arguments = allocate(products, ARGUMENT_WORDS);
            words argumentValues = allocate(products, ARGUMENT_WORDS);
            words valueStarts = allocate(products, 1024);
            bytes identities = allocateBytes(products, 131072);
            words targetParameterStarts = allocate(products, 4096);
            words targetParameterCounts = allocate(products, 4096);
            words targetParameterTypes = allocate(products, 16384);
            words relocations = allocate(products, 768);
            bytes relocationIdentities = allocateBytes(products, 8192);
            words types = allocate(products, 12288);
            words localWidths = allocate(products, 256);
            words resultOperands = allocate(products, 256);
            words statementStarts = allocate(products, 4096);
            words statementWidths = allocate(products, 4096);
            set(calls, 0, 7);
            set(calls, 256, FIRST_KIND);
            set(resultOperands, 0, RESULT_OPERAND);
            set(calls, 768, 3);
            set(calls, 1, 8);
            set(calls, 769, 4);
            set(callStatements, 0, 10);
            set(callStatements, 1, 11);
            set(callInstructionStarts, 0, 20);
            set(callInstructionStarts, 1, SECOND_INSTRUCTION_START);
            set(statementStarts, 10, FIRST_BASE);
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
            phase = 1;
            LoopCallPlan plan = writeLoopCallProducts(
              2, calls, callArgumentStarts, callArgumentCounts, callStatements,
              callInstructionStarts, arguments, argumentValues, valueStarts, 5, identities,
              targetParameterStarts, targetParameterCounts, targetParameterTypes,
              relocations, relocationIdentities, types, localWidths, resultOperands,
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
            phase = 2;
            drop(statementWidths);
            drop(statementStarts);
            drop(resultOperands);
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
        """.replace("ARGUMENT_SETUP", """
            set(callArgumentCounts, 0, FIRST_ARITY);
            set(callArgumentStarts, 1, FIRST_ARITY);
            set(callArgumentCounts, 1, SECOND_ARITY);
            set(targetParameterCounts, 3, FIRST_ARITY);
            set(targetParameterStarts, 4, FIRST_ARITY);
            set(targetParameterCounts, 4, SECOND_ARITY);
            long argument = 0;
            while (argument < FIRST_ARITY) limit 64 {
              set(arguments, ARGUMENT_TYPE_ROW + argument, 1);
              set(argumentValues, argument, argument);
              set(valueStarts, argument, FIRST_VALUE_BASE + argument);
              set(targetParameterTypes, argument, 1);
              argument += 1;
            }
            if (SECOND_ARITY == 1) {
              set(arguments, ARGUMENT_TYPE_ROW + FIRST_ARITY, 2);
              set(argumentValues, FIRST_ARITY, FIRST_ARITY);
              set(valueStarts, FIRST_ARITY, 5);
              set(targetParameterTypes, FIRST_ARITY, 2);
            }
            """)
            .replace("FIRST_ARITY", Integer.toString(arity))
            .replace("SECOND_ARITY", Integer.toString(secondArity))
            .replace("FIRST_BASE", Integer.toString(base))
            .replace("FIRST_VALUE_BASE", arity == 64 ? "0" : "3")
            .replace("FIRST_KIND", store ? "9" : "1")
            .replace("RESULT_OPERAND", store ? "7" : "0")
            .replace("FIRST_WIDTH", Integer.toString(arity * 2 + (store ? 1 : 2)))
            .replace("SECOND_WIDTH", Integer.toString(secondArity * 2))
            .replace("SECOND_TYPE_ROW", secondArity > 0 ? "8196" : "8193")
            .replace("SECOND_INSTRUCTION_START", Integer.toString(20 + arity * 2 + 2))
            .replace("CALL_OFFSET", arity > 0 ? Integer.toString(arity * 48) : "64")
            .replace("MUTATION", mutation));
    return new WheelerCompiler().compileModuleFiles(sources, "example.loop_call_products");
  }
}
