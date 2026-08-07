package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.util.LinkedHashMap;
import org.junit.jupiter.api.Test;

/** Conformance tests for the Wheeler-written canonical artifact verifier. */
class MinimalCompilerVerifierExampleTest {
  @Test
  void wheelerVerifierRejectsMalformedArtifactOperands() throws Exception {
    String root = """
        module examples.compiler.verifiertest;
        import wheeler.compiler.verifier;
        classical class VerifierTest {
          state long result = 0;

          private long nybble(borrow utf8 source, long offset) {
            long scalar = utf8Scalar(source, offset);
            if (47 < scalar) {
              if (scalar < 58) {
                return scalar - 48;
              }
            }
            if (96 < scalar) {
              if (scalar < 103) {
                return scalar - 87;
              }
            }
            return 0;
          }

          entry void main(borrow utf8 source) {
            long sourceLength = bufferLength(source);
            region arena = new region(2048, 1);
            bytes artifact = allocateBytes(arena, 2048);
            long sourceCursor = 0;
            long artifactCursor = 0;
            while (sourceCursor < sourceLength) limit 4096 {
              long high = nybble(source, sourceCursor);
              long low = nybble(source, sourceCursor + 1);
              setByte(artifact, artifactCursor, high * 16 + low);
              sourceCursor += 2;
              artifactCursor += 1;
            }
            result = verifyArtifact(artifact, artifactCursor);
            drop(artifact);
            drop(arena);
          }
        }
        """;
    var modules = new LinkedHashMap<>(
        CompilerSources.moduleClosure("wheeler.compiler.verifier"));
    CoreSources.addBinaryClosure(modules);
    modules.put("VerifierTest.w", root);
    Program program = new WheelerCompiler().compileModuleFiles(
        modules, "examples.compiler.verifiertest");
    WheelerCompiler stageZero = new WheelerCompiler();
    byte[] locals = stageZero.compileToBytecode(
        "classical class OperandCheck { state long value = 1; "
            + "entry void main() { value += 2; } }");
    assertEquals(1, verifyWithWheeler(program, locals));

    byte[] badLocal = locals.clone();
    putOperand(badLocal, 1024, 0, 99);
    assertEquals(0, verifyWithWheeler(program, badLocal));

    byte[] badGlobal = locals.clone();
    putOperand(badGlobal, 1025, 1, 99);
    assertEquals(0, verifyWithWheeler(program, badGlobal));

    byte[] badGlobalType = locals.clone();
    ByteBuffer.wrap(badGlobalType)
        .order(ByteOrder.LITTLE_ENDIAN)
        .putInt(sectionOffset(badGlobalType, 2) + 8, 2);
    assertEquals(0, verifyWithWheeler(program, badGlobalType));

    byte[] badLocalType = locals.clone();
    ByteBuffer.wrap(badLocalType)
        .order(ByteOrder.LITTLE_ENDIAN)
        .putInt(sectionOffset(badLocalType, 4) + 44, 2);
    assertEquals(0, verifyWithWheeler(program, badLocalType));

    byte[] call = stageZero.compileToBytecode(
        "classical class CallCheck { state long value = 1; "
            + "void bump() { value += 2; } "
            + "entry void main() { bump(); } }");
    assertEquals(1, verifyWithWheeler(program, call));
    putOperand(call, 512, 0, 1);
    assertEquals(0, verifyWithWheeler(program, call));

    byte[] certified = stageZero.compileToBytecode(
        "classical class ProofCheck { state long value = 1; "
            + "rev void bump() { value += 2; } "
            + "theorem bumpInverse proves inverse(bump); "
            + "entry void main() { bump(); reverse { bump(); } } }");
    assertEquals(1, verifyWithWheeler(program, certified));
    byte[] badSubject = certified.clone();
    ByteBuffer.wrap(badSubject)
        .order(ByteOrder.LITTLE_ENDIAN)
        .putInt(sectionOffset(badSubject, 6) + 16, 1);
    assertEquals(0, verifyWithWheeler(program, badSubject));
    byte[] badProofArgument = certified.clone();
    badProofArgument[sectionOffset(badProofArgument, 6) + 20] = 0;
    assertEquals(0, verifyWithWheeler(program, badProofArgument));
  }

  private static long verifyWithWheeler(Program verifier, byte[] artifact) {
    String hex = java.util.HexFormat.of().formatHex(artifact);
    VirtualMachine machine = new VirtualMachine(
        verifier, hex.getBytes(StandardCharsets.UTF_8));
    machine.run();
    return machine.global("result");
  }

  private static void putOperand(
      byte[] artifact, int opcode, int operand, long value) {
    int instruction = instructionOffset(artifact, opcode);
    ByteBuffer.wrap(artifact)
        .order(ByteOrder.LITTLE_ENDIAN)
        .putLong(instruction + 8 + operand * Long.BYTES, value);
  }

  private static int sectionOffset(byte[] artifact, int section) {
    ByteBuffer bytes = ByteBuffer.wrap(artifact).order(ByteOrder.LITTLE_ENDIAN);
    return Math.toIntExact(bytes.getLong(40 + section * 32 + 8));
  }

  private static int instructionOffset(byte[] artifact, int expectedOpcode) {
    ByteBuffer bytes = ByteBuffer.wrap(artifact).order(ByteOrder.LITTLE_ENDIAN);
    int directory = 40 + 5 * 32;
    int cursor = sectionOffset(artifact, 5);
    int end = cursor + Math.toIntExact(bytes.getLong(directory + 16));
    while (cursor < end) {
      int opcode = Short.toUnsignedInt(bytes.getShort(cursor));
      if (opcode == expectedOpcode) {
        return cursor;
      }
      cursor += bytes.getInt(cursor + 4);
    }
    throw new AssertionError("missing opcode " + expectedOpcode);
  }

}
