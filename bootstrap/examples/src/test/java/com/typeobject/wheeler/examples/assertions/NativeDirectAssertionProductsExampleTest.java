package com.typeobject.wheeler.examples.assertions;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Instruction;
import com.typeobject.wheeler.core.bytecode.Opcode;
import com.typeobject.wheeler.core.vm.MachineStatus;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import com.typeobject.wheeler.examples.CompilerSources;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import org.junit.jupiter.api.Test;

/** Checks complete assertion type/code windows, failed preflight, and real publication replay. */
final class NativeDirectAssertionProductsExampleTest {
  private static final int TOKENS = 4096;
  private static final int STATEMENTS = 4096;
  private static final int LOOP_STATEMENT_COLUMNS = 7;
  private static final int STATEMENT_LOCAL_COLUMNS = 2;
  private static final int SOURCE_VALUE_COLUMNS = 7;
  private static final int GLOBAL_COLUMNS = 4;
  private static final int TYPE_COLUMNS = 3;
  private static final int TYPE_ROWS = STATEMENTS * TYPE_COLUMNS;
  private static final int SYMBOLS = 16384;
  private static final int VALUES = 1024;
  private static final int GLOBALS = 8;
  private static final int FRAME_LOCALS = 256;
  private static final int CODE_BYTES = 262144;
  private static final long SENTINEL = 211;
  private static final String NAME = "Alpha";
  private static final int SCALAR_LOCALS = 1;
  private static final int BINARY_LOCALS = 2 + SCALAR_LOCALS;
  private static final int SIGNED_TYPE = 1;
  private static final int BOOLEAN_TYPE = 2;
  private static final int SCALAR_BYTES = Instruction.of(Opcode.LOCAL_CONST, 0, 1).encodedLength()
      + Instruction.of(Opcode.EXPECT_TRUE, 0).encodedLength();
  private static final int BINARY_BYTES = Instruction.of(Opcode.LOCAL_LOAD_GLOBAL, 0, 0).encodedLength()
      + Instruction.of(Opcode.LOCAL_CONST, 0, 5).encodedLength()
      + Instruction.of(Opcode.LOCAL_EQ, 0, 0, 0).encodedLength()
      + Instruction.of(Opcode.EXPECT_TRUE, 0).encodedLength();

  private static final int GLOBAL_BYTES = Instruction.of(Opcode.EXPECT_EQ, 0, 5).encodedLength();

  private enum Profile { SCALAR, BINARY, GLOBAL_LITERAL }

  private record Case(Profile profile, long cursor, long base, long typeStart, int typeLength,
                      boolean valid, boolean trap) {}

  @Test
  void publishesOnlyActiveTypesAndCodeAtTerminalWindows() throws Exception {
    for (Case row : List.of(
        new Case(Profile.SCALAR, 3, 0, 2, TYPE_ROWS, true, false),
        new Case(Profile.BINARY, 3, 0, 2, TYPE_ROWS, true, false),
        new Case(Profile.GLOBAL_LITERAL, 3, 0, 2, TYPE_ROWS, true, false),
        new Case(Profile.SCALAR, CODE_BYTES - SCALAR_BYTES, FRAME_LOCALS - SCALAR_LOCALS,
            STATEMENTS - SCALAR_LOCALS, TYPE_ROWS, true, false),
        new Case(Profile.BINARY, CODE_BYTES - BINARY_BYTES, FRAME_LOCALS - BINARY_LOCALS,
            STATEMENTS - BINARY_LOCALS, TYPE_ROWS, true, false),
        new Case(Profile.GLOBAL_LITERAL, CODE_BYTES - GLOBAL_BYTES, FRAME_LOCALS,
            STATEMENTS, TYPE_ROWS, true, false))) {
      check(row);
    }
  }

  @Test
  void rejectsFirstExcessAndMalformedLateBackingWithoutPublishing() throws Exception {
    for (Case row : List.of(
        new Case(Profile.SCALAR, 3, 0, STATEMENTS, TYPE_ROWS, false, false),
        new Case(Profile.BINARY, 3, 0, STATEMENTS - BINARY_LOCALS + 1, TYPE_ROWS, false, false),
        new Case(Profile.BINARY, 3, 0, -1, TYPE_ROWS, false, false),
        new Case(Profile.BINARY, 3, 0, Long.MAX_VALUE, TYPE_ROWS, false, false),
        new Case(Profile.BINARY, 3, FRAME_LOCALS - BINARY_LOCALS + 1, 2, TYPE_ROWS, false, false),
        new Case(Profile.BINARY, CODE_BYTES - BINARY_BYTES + 1, 0, 2, TYPE_ROWS, false, false),
        new Case(Profile.BINARY, 3, 0, 2, TYPE_ROWS - 1, false, true),
        new Case(Profile.GLOBAL_LITERAL, -1, 0, 2, TYPE_ROWS, false, false),
        new Case(Profile.GLOBAL_LITERAL, 3, -1, 2, TYPE_ROWS, false, false),
        new Case(Profile.GLOBAL_LITERAL, 3, FRAME_LOCALS + 1, 2, TYPE_ROWS, false, false),
        new Case(Profile.GLOBAL_LITERAL, CODE_BYTES - GLOBAL_BYTES + 1, 0, 2, TYPE_ROWS, false, false),
        new Case(Profile.GLOBAL_LITERAL, 3, 0, STATEMENTS + 1, TYPE_ROWS, false, false),
        new Case(Profile.GLOBAL_LITERAL, 3, 0, 2, TYPE_ROWS - 1, false, true))) {
      check(row);
    }
  }

  private static void check(Case row) throws Exception {
    var dimensions = new LinkedHashMap<String, Integer>();
    dimensions.put("kinds", TOKENS);
    dimensions.put("starts", TOKENS);
    dimensions.put("lengths", TOKENS);
    dimensions.put("statements", STATEMENTS * LOOP_STATEMENT_COLUMNS);
    dimensions.put("locals", STATEMENTS * STATEMENT_LOCAL_COLUMNS);
    dimensions.put("physical", STATEMENTS);
    dimensions.put("values", VALUES * SOURCE_VALUE_COLUMNS);
    for (String column : List.of("owners", "symbolStarts", "symbolLengths", "symbolTypes", "symbolValues", "resolved")) {
      dimensions.put(column, SYMBOLS);
    }
    dimensions.put("globals", GLOBALS * GLOBAL_COLUMNS);
    dimensions.put("types", row.typeLength());
    int words = dimensions.values().stream().mapToInt(Integer::intValue).sum();
    StringBuilder declarations = new StringBuilder();
    StringBuilder drops = new StringBuilder();
    dimensions.forEach((name, length) -> {
      declarations.append("words ").append(name).append(" = allocate(arena, ").append(length).append(");\n");
      drops.append("drop(").append(name).append(");\n");
    });
    var sources = new LinkedHashMap<>(CompilerSources.moduleClosure("wheeler.compiler.closure.direct_assertion_products"));
    sources.put("Sha256.w", Files.readString(Path.of("../wheeler-core/src/main/wheeler/crypto/Sha256.w")));
    sources.put("Driver.w", """
        module example.assertion_windows;
        import wheeler.compiler.closure.direct_assertion_products;
        import wheeler.compiler.closure.loop_body_values;
        import wheeler.lexer.scanner;
        classical class Driver {
          const long WORDS = %d;
          const long WORD_BYTES = %d;
          const long NAMES = %d;
          const long CODE_BYTES = %d;
          const long TYPE_ROWS = %d;
          const long BUFFERS = %d;
          const long ARENA_BYTES = WORDS * WORD_BYTES + NAMES + CODE_BYTES;
          state long prepared = 0;
          state long completed = 0;
          state long valid = -1;
          state long next = 0;
          state long typeCount = 0;
          state long instructionCount = 0;
          entry void main(borrow utf8 input) {
            region arena = new region(ARENA_BYTES, BUFFERS);
            %s
            bytes names = allocateBytes(arena, NAMES);
            bytes code = allocateBytes(arena, CODE_BYTES);
            writeAscii(names, 0, "Alpha");
            set(globals, 0, 0); set(globals, %d, NAMES);
            long cell = 0;
            while (cell < TYPE_ROWS) limit TYPE_ROWS { set(types, cell, %d); cell += 1; }
            long byte = 0;
            while (byte < CODE_BYTES) limit CODE_BYTES { setByte(code, byte, %d); byte += 1; }
            long count = 0;
            ScanResult scanned = scan(input, kinds, starts, lengths);
            match (scanned) {
              case ScanResult.Error(ScanDiagnostic diagnostic) { assert(false); }
              case ScanResult.Value(long scannedCount) { count = scannedCount; }
            }
            count = compactLoopBodyTokens(count, kinds, starts, lengths);
            prepared = 1;
            DirectAssertionProduct result = writeDirectAssertion(input, names, names,
              /* globalCount= */ 1, /* globalProductStart= */ 0, globals,
              /* token= */ 0, count, kinds, starts, lengths, /* moduleOwner= */ 0,
              /* owner= */ 0, /* ordinal= */ 0, /* statementCount= */ 0,
              statements, locals, physical, /* valueCount= */ 0, values,
              /* symbolCount= */ 0, owners, symbolStarts, symbolLengths,
              symbolTypes, symbolValues, resolved, types, %d, code, %d, %d);
            valid = 0; if (result.valid) { valid = 1; }
            next = result.next; typeCount = result.typeCount;
            instructionCount = result.instructionCount; completed = 1;
            drop(code); drop(names); %s drop(arena);
          }
        }
        """.formatted(words, Long.BYTES, NAME.length(), CODE_BYTES, row.typeLength(), dimensions.size() + 2,
            declarations, GLOBALS, SENTINEL, SENTINEL, row.typeStart(), row.cursor(), row.base(), drops));
    var program = new WheelerCompiler().compileModuleFiles(sources, "example.assertion_windows");
    String input = "// café 𝄞\n" + switch (row.profile()) {
      case SCALAR -> "assert(true);";
      case BINARY -> "assert(Alpha < 5);";
      case GLOBAL_LITERAL -> "assert(Alpha == 5);";
    };
    var machine = new VirtualMachine(program, input.getBytes(StandardCharsets.UTF_8));
    long preparation = 0;
    while (machine.global("prepared") == 0 && preparation++ < program.maxSteps()) machine.stepWithoutRewindHistory();
    assertEquals(1, machine.global("prepared"));
    var before = machine.snapshot();
    execute(machine, row.trap(), program.maxSteps());
    var after = machine.snapshot();
    assertEquals(row.trap() ? -1 : row.valid() ? 1 : 0, machine.global("valid"));
    int localCount = switch (row.profile()) {
      case SCALAR -> SCALAR_LOCALS;
      case BINARY -> BINARY_LOCALS;
      case GLOBAL_LITERAL -> 0;
    };
    var expectedCode = ByteBuffer.allocate(CODE_BYTES).order(ByteOrder.LITTLE_ENDIAN);
    java.util.Arrays.fill(expectedCode.array(), (byte) SENTINEL);
    var instructions = new ArrayList<Instruction>();
    if (row.valid()) {
      expectedCode.position((int) row.cursor());
      if (row.profile() == Profile.GLOBAL_LITERAL) {
        instructions.add(Instruction.of(Opcode.EXPECT_EQ, 0, 5));
      } else {
        if (row.profile() == Profile.BINARY) {
          instructions.add(Instruction.of(Opcode.LOCAL_LOAD_GLOBAL, row.base(), 0));
          instructions.add(Instruction.of(Opcode.LOCAL_CONST, row.base() + 1, 5));
          instructions.add(Instruction.of(Opcode.LOCAL_LT, row.base() + 2, row.base(), row.base() + 1));
        } else instructions.add(Instruction.of(Opcode.LOCAL_CONST, row.base(), 1));
        instructions.add(Instruction.of(Opcode.EXPECT_TRUE, row.base() + localCount - 1));
      }
      for (Instruction instruction : instructions) {
        expectedCode.putShort((short) instruction.opcode().code()).putShort((short) instruction.operands().size())
            .putInt(instruction.encodedLength());
        for (long operand : instruction.operands()) expectedCode.putLong(operand);
      }
    }
    assertEquals(row.valid() ? expectedCode.position() : 0, machine.global("next"));
    assertEquals(row.valid() ? row.typeStart() + localCount : 0, machine.global("typeCount"));
    assertEquals(instructions.size(), machine.global("instructionCount"));
    var types = after.buffers().get(dimensions.size()); // borrowed input precedes owned word buffers
    var expectedTypes = new ArrayList<>(before.buffers().get(dimensions.size()).elements());
    if (row.valid()) for (int local = 0; local < localCount; local++) {
      int type = local == localCount - 1 ? BOOLEAN_TYPE : SIGNED_TYPE;
      int index = (int) row.typeStart() + local;
      expectedTypes.set(index, 0L);
      expectedTypes.set(STATEMENTS + index, row.base() + local);
      expectedTypes.set(STATEMENTS * 2 + index, (long) type);
    }
    assertEquals(expectedTypes, types.elements());
    var code = after.buffers().getLast();
    for (int index = 0; index < CODE_BYTES; index++) {
      assertEquals(Byte.toUnsignedLong(expectedCode.array()[index]), code.elements().get(index));
    }
    assertEquals(before.regions(), after.regions());
    assertEquals(before.buffers().size(), after.buffers().size());
    for (int buffer = 0; buffer < after.buffers().size(); buffer++) {
      if (after.buffers().get(buffer).id() != types.id() && after.buffers().get(buffer).id() != code.id()) {
        assertEquals(before.buffers().get(buffer), after.buffers().get(buffer));
      }
    }
    while (machine.historySize() > 0) machine.rewindOne();
    assertEquals(before, machine.snapshot());
    execute(machine, row.trap(), program.maxSteps());
    assertEquals(after, machine.snapshot());
    if (!row.trap()) {
      while (machine.status() != MachineStatus.HALTED) machine.step();
      assertTrue(machine.snapshot().buffers().stream().skip(1).allMatch(buffer -> buffer.dropped()));
      assertTrue(machine.snapshot().regions().stream().skip(1).allMatch(region -> region.dropped()));
    }
    while (machine.historySize() > 0) machine.rewindOne();
    assertEquals(before, machine.snapshot());
  }

  private static void execute(VirtualMachine machine, boolean trap, long limit) {
    Runnable phase = () -> {
      long steps = 0;
      while (machine.global("completed") == 0 && steps++ < limit) machine.step();
      assertEquals(1, machine.global("completed"));
    };
    if (trap) assertThrows(VmTrap.class, phase::run);
    else phase.run();
  }
}
