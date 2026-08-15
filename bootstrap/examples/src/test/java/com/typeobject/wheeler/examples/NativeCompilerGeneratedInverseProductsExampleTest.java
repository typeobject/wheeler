package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.FunctionBody;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Native evidence for generated inverse products over shared callable coordinates. */
final class NativeCompilerGeneratedInverseProductsExampleTest {
  @Test
  void matchesTheStageZeroGeneratedInverse() throws Exception {
    Program stageZero = new WheelerCompiler().compileLibraryModuleFiles(
        Map.of("InverseFixture.w", """
            module fixture.inverse;

            classical class InverseFixture {
              state long value = 0;

              rev void bump() {
                value += 3;
              }
            }
            """),
        "fixture.inverse");
    FunctionBody function = stageZero.functions().stream()
        .filter(candidate -> candidate.name().endsWith("::bump"))
        .findFirst()
        .orElseThrow();
    byte[] artifact = new BytecodeWriter().write(stageZero);
    byte[][] code = functionCode(artifact, function.id());
    VirtualMachine machine = new VirtualMachine(
        differentialProgram(code[0], function.forward().size()), null, 262_144);

    CompilerMachineRunner.runWithoutRewindHistory(machine);

    assertEquals(1, machine.global("published"));
    assertEquals(function.inverse().size(), machine.global("instructionCount"));
    org.junit.jupiter.api.Assertions.assertArrayEquals(code[1], machine.hostOutput());
  }

  @Test
  void reversesTwoExactCallableWindows() throws Exception {
    VirtualMachine machine = new VirtualMachine(program(false));

    CompilerMachineRunner.runWithoutRewindHistory(machine);

    assertEquals(1, machine.global("published"));
    assertEquals(6, machine.global("instructionCount"));
    assertEquals(96, machine.global("codeLength"));
    assertEquals(0x0303, machine.global("firstOpcode"));
    assertEquals(0x0101, machine.global("secondOpcode"));
    assertEquals(0x0102, machine.global("thirdOpcode"));
    assertEquals(0x0201, machine.global("fourthOpcode"));
    assertEquals(48, machine.global("secondStart"));
  }

  @Test
  void rejectsAnIrreversibleOpcodeWithoutPublishing() throws Exception {
    VirtualMachine machine = new VirtualMachine(program(true));

    CompilerMachineRunner.runWithoutRewindHistory(machine);

    assertEquals(0, machine.global("published"));
    assertEquals(77, machine.global("rowSentinel"));
    assertEquals(99, machine.global("codeSentinel"));
  }

  private static byte[][] functionCode(byte[] artifact, int function) {
    int functionSection = sectionStart(artifact, 5);
    int codeSection = sectionStart(artifact, 6);
    int descriptor = functionSection + 4 + function * 40;
    int forwardStart = codeSection + readU32(artifact, descriptor + 12);
    int forwardLength = readU32(artifact, descriptor + 16);
    int inverseStart = codeSection + readU32(artifact, descriptor + 20);
    int inverseLength = readU32(artifact, descriptor + 24);
    return new byte[][] {
        Arrays.copyOfRange(artifact, forwardStart, forwardStart + forwardLength),
        Arrays.copyOfRange(artifact, inverseStart, inverseStart + inverseLength)
    };
  }

  private static int sectionStart(byte[] artifact, int wantedType) {
    int sectionCount = readU32(artifact, 24);
    for (int section = 0; section < sectionCount; section++) {
      int directory = 40 + section * 32;
      if (readU32(artifact, directory) == wantedType) {
        return Math.toIntExact(readU64(artifact, directory + 8));
      }
    }
    throw new IllegalArgumentException("Missing section " + wantedType);
  }

  private static int readU32(byte[] input, int offset) {
    return input[offset] & 0xff
        | (input[offset + 1] & 0xff) << 8
        | (input[offset + 2] & 0xff) << 16
        | (input[offset + 3] & 0xff) << 24;
  }

  private static long readU64(byte[] input, int offset) {
    long value = 0;
    for (int index = 7; index >= 0; index--) {
      value = value << 8 | input[offset + index] & 0xffL;
    }
    return value;
  }

  private static Program differentialProgram(byte[] forwardCode, int instructionCount)
      throws Exception {
    StringBuilder writes = new StringBuilder();
    for (int index = 0; index < forwardCode.length; index++) {
      writes.append("setByte(forwardCode, ").append(index).append(", ")
          .append(forwardCode[index] & 0xff).append(");\n");
    }
    Map<String, String> sources = new LinkedHashMap<>();
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.generated_inverse_products"));
    CoreSources.addBinaryClosure(sources);
    sources.put("GeneratedInverseDifferential.w", """
        module example.generated_inverse_differential;

        import wheeler.compiler.closure.generated_inverse_products;

        classical class GeneratedInverseDifferential {
          state long published = 0;
          state long instructionCount = 0;

          entry void main(borrow mut bytes output) {
            region arena = new region(/* bytes= */ ARENA_BYTES, /* allocations= */ 3);
            bytes forwardCode = allocateBytes(arena, /* length= */ FORWARD_LENGTH);
            words callableRows = allocate(arena, /* length= */ 320);
            words inverseRows = allocate(arena, /* length= */ 192);
            FORWARD_WRITES
            set(callableRows, 64, INSTRUCTION_COUNT);
            set(callableRows, 128, 0);
            set(callableRows, 192, FORWARD_LENGTH);
            GeneratedInversePlan plan = materializeGeneratedInverseProducts(
              /* callableCount= */ 1,
              callableRows,
              forwardCode,
              /* forwardCodeLength= */ FORWARD_LENGTH,
              inverseRows,
              output
            );
            assert(plan.valid);
            published = 1;
            instructionCount = plan.instructionCount;
            setOutputLength(output, plan.codeLength);
            drop(inverseRows);
            drop(callableRows);
            drop(forwardCode);
            drop(arena);
          }
        }
        """
            .replace("ARENA_BYTES", Integer.toString(4_096 + forwardCode.length))
            .replace("FORWARD_LENGTH", Integer.toString(forwardCode.length))
            .replace("INSTRUCTION_COUNT", Integer.toString(instructionCount))
            .replace("FORWARD_WRITES", writes));
    return new WheelerCompiler().compileModuleFiles(
        sources, "example.generated_inverse_differential");
  }

  private static Program program(boolean malformed) throws Exception {
    Map<String, String> sources = new LinkedHashMap<>();
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.generated_inverse_products"));
    CoreSources.addBinaryClosure(sources);
    sources.put("GeneratedInverseProductsExample.w", """
        module example.generated_inverse_products;

        import wheeler.compiler.closure.generated_inverse_products;
        import wheeler.compiler.opcodes;
        import wheeler.core.encoding.binary;

        classical class GeneratedInverseProductsExample {
          state long published = 0;
          state long instructionCount = 0;
          state long codeLength = 0;
          state long firstOpcode = 0;
          state long secondOpcode = 0;
          state long thirdOpcode = 0;
          state long fourthOpcode = 0;
          state long secondStart = 0;
          state long rowSentinel = 0;
          state long codeSentinel = 0;

          private long writeHeader(
            borrow mut bytes output,
            long cursor,
            long opcode,
            long operandCount
          ) {
            setByte(output, cursor, opcode % 256);
            setByte(output, cursor + 1, opcode / 256);
            setByte(output, cursor + 2, operandCount);
            long length = 8 + operandCount * 8;
            setByte(output, cursor + 4, length);
            return cursor + length;
          }

          entry void main() {
            region arena = new region(/* bytes= */ 266336, /* allocations= */ 4);
            bytes forwardCode = allocateBytes(arena, /* length= */ 96);
            words callableRows = allocate(arena, /* length= */ 320);
            words inverseRows = allocate(arena, /* length= */ 192);
            bytes inverseCode = allocateBytes(arena, /* length= */ 262144);
            long cursor = 0;
            cursor = writeHeader(forwardCode, cursor, OPCODE_ADD_CONST, 2);
            cursor = writeHeader(forwardCode, cursor, OPCODE_EXPECT_TRUE, 1);
            cursor = writeHeader(forwardCode, cursor, OPCODE_RETURN, 0);
            cursor = writeHeader(forwardCode, cursor, OPCODE_CALL, 1);
            cursor = writeHeader(forwardCode, cursor, SECOND_OPCODE, 2);
            cursor = writeHeader(forwardCode, cursor, OPCODE_RETURN, 0);
            assert(cursor == 96);
            set(callableRows, 64, 3);
            set(callableRows, 65, 3);
            set(callableRows, 128, 0);
            set(callableRows, 129, 48);
            set(callableRows, 192, 48);
            set(callableRows, 193, 48);
            set(inverseRows, 0, 77);
            setByte(inverseCode, 0, 99);
            GeneratedInversePlan plan = materializeGeneratedInverseProducts(
              /* callableCount= */ 2,
              callableRows,
              forwardCode,
              /* forwardCodeLength= */ 96,
              inverseRows,
              inverseCode
            );
            if (plan.valid) {
              published = 1;
              instructionCount = plan.instructionCount;
              codeLength = plan.codeLength;
              firstOpcode = readUnsigned(inverseCode, /* start= */ 0, /* width= */ 2);
              secondOpcode = readUnsigned(inverseCode, /* start= */ 16, /* width= */ 2);
              thirdOpcode = readUnsigned(inverseCode, /* start= */ 48, /* width= */ 2);
              fourthOpcode = readUnsigned(inverseCode, /* start= */ 72, /* width= */ 2);
              secondStart = inverseRows[1];
            }
            rowSentinel = inverseRows[0];
            codeSentinel = inverseCode[0];
            drop(inverseCode);
            drop(inverseRows);
            drop(callableRows);
            drop(forwardCode);
            drop(arena);
          }
        }
        """.replace(
            "SECOND_OPCODE", malformed ? "OPCODE_LOCAL_CONST" : "OPCODE_XOR_CONST"));
    return new WheelerCompiler().compileModuleFiles(sources, "example.generated_inverse_products");
  }
}
