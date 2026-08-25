package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeReader;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.Opcode;
import com.typeobject.wheeler.core.bytecode.ValueType;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Differential evidence for bounded allocation and explicit affine destruction. */
final class NativeCompilerOwnedStorageExampleTest {
  @Test
  void allocatesAndDropsOwnedBytesByteForByte() throws Exception {
    String source = """
        module example.native_owned_storage;
        classical class NativeOwnedStorage {
          public long allocateThenDrop(borrow mut region arena, long length) {
            bytes value = allocateBytes(arena, length);
            drop(value);
            return length;
          }
        }
        """;
    byte[] expected = new BytecodeWriter().write(
        new WheelerCompiler().compileLibraryModuleFiles(
            Map.of("NativeOwnedStorage.w", source),
            "example.native_owned_storage"));
    byte[] actual = NativeModuleCompilerHarness.compile(
        NativeModuleCompilerHarness.program(), List.of(), source);
    assertArrayEquals(expected, actual);

    var body = new BytecodeReader().read(actual).functions().getFirst();
    assertEquals(2, body.parameterCount());
    assertEquals(7, body.localCount());
    assertEquals(ValueType.REGION_BORROW, body.localType(0));
    assertEquals(ValueType.SIGNED, body.localType(1));
    assertEquals(ValueType.REGION_BORROW, body.localType(2));
    assertEquals(ValueType.SIGNED, body.localType(3));
    assertEquals(ValueType.BYTES, body.localType(4));
    assertEquals(ValueType.BYTES, body.localType(5));
    assertEquals(ValueType.SIGNED, body.localType(6));
    assertEquals(Opcode.BYTES_ALLOC, body.forward().get(2).opcode());
    assertEquals(Opcode.BUFFER_DROP, body.forward().get(4).opcode());

    assertRejected(source.replace("borrow mut region arena", "long arena"));
    assertRejected(source.replace("long length", "borrow utf8 length"));
    assertRejected(source.replace("drop(value);", "drop(arena);"));
    assertRejected(source.replace("    drop(value);\n", ""));
    assertRejected(source.replace("drop(value);", "drop(value);\n    drop(value);"));
  }

  @Test
  void advancesAnOwnerThroughMutableByteWrites() throws Exception {
    String source = """
        module example.native_owned_storage;
        classical class NativeOwnedStorage {
          public long mutateThenDrop(borrow mut region arena, long index, long value) {
            bytes output = allocateBytes(arena, index);
            setByte(output, index, value);
            drop(output);
            return value;
          }
        }
        """;
    byte[] expected = new BytecodeWriter().write(
        new WheelerCompiler().compileLibraryModuleFiles(
            Map.of("NativeOwnedStorage.w", source),
            "example.native_owned_storage"));
    byte[] actual = NativeModuleCompilerHarness.compile(
        NativeModuleCompilerHarness.program(), List.of(), source);
    assertArrayEquals(expected, actual);

    var body = new BytecodeReader().read(actual).functions().getFirst();
    assertEquals(10, body.localCount());
    assertEquals(Opcode.BYTES_ALLOC, body.forward().get(2).opcode());
    assertEquals(Opcode.OWNED_MOVE, body.forward().get(3).opcode());
    assertEquals(Opcode.BYTES_SET, body.forward().get(6).opcode());
    assertEquals(Opcode.BUFFER_DROP, body.forward().get(7).opcode());

    assertRejected(source.replace("setByte(output, index, value);", "setByte(arena, index, value);"));
    assertRejected(source.replace(
        "setByte(output, index, value);\n    drop(output);",
        "drop(output);\n    setByte(output, index, value);"));
  }

  @Test
  void freezesAnAdvancedOwnerIntoUtf8() throws Exception {
    String source = """
        module example.native_owned_storage;
        classical class NativeOwnedStorage {
          public utf8 freezeBytes(borrow mut region arena, long index) {
            bytes output = allocateBytes(arena, index);
            setByte(output, index, index);
            return freezeUtf8(output);
          }
        }
        """;
    byte[] expected = new BytecodeWriter().write(
        new WheelerCompiler().compileLibraryModuleFiles(
            Map.of("NativeOwnedStorage.w", source),
            "example.native_owned_storage"));
    byte[] actual = NativeModuleCompilerHarness.compile(
        NativeModuleCompilerHarness.program(), List.of(), source);
    assertArrayEquals(expected, actual);

    var body = new BytecodeReader().read(actual).functions().getFirst();
    assertEquals(ValueType.UTF8, body.resultType());
    assertEquals(9, body.localCount());
    assertEquals(ValueType.UTF8, body.localType(8));
    assertEquals(Opcode.UTF8_FREEZE, body.forward().get(7).opcode());
    assertEquals(Opcode.RETURN_VALUE, body.forward().get(8).opcode());

    assertRejected(source.replace("public utf8 freezeBytes", "public long freezeBytes"));
    assertRejected(source.replace("long index)", "long index, long extra)"));
    assertRejected(source.replace("freezeUtf8(output)", "freezeUtf8(arena)"));
  }

  private static void assertRejected(String source) throws Exception {
    NativeModuleCompilerHarness.assertTrap(
        NativeModuleCompilerHarness.program(), List.of(), source);
  }
}
