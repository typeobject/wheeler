package com.typeobject.wheeler.examples.proofs;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.vm.BufferValue;
import com.typeobject.wheeler.core.vm.MachineSnapshot;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import com.typeobject.wheeler.examples.CompilerSources;
import com.typeobject.wheeler.examples.CoreSources;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;

/** Owns caller snapshots independently of private proof staging and emitted bytes. */
final class ProofProductFixture {
  static final int MAX_PROOFS = 4096;
  static final int COLUMNS = 6;
  static final int ROWS = MAX_PROOFS * COLUMNS;
  static final int MAX_STRINGS = 16_384;
  static final int TABLE_BYTES = (ROWS + MAX_STRINGS) * Long.BYTES;
  static final int OUTPUT_START = 13;
  static final int DESCRIPTOR_BYTES = COLUMNS * Integer.BYTES;
  static final int CAPACITY = OUTPUT_START + Integer.BYTES + 2 * DESCRIPTOR_BYTES + 17;
  static final long WORD_MAX = (1L << Integer.SIZE) - 1;

  private ProofProductFixture() {}

  static byte[] artifact() {
    return new BytecodeWriter().write(new WheelerCompiler().compile("""
        classical class ProofProducts {
          rev void subject() {}
          theorem undoSubject proves inverse(subject);
          theorem boundedSubject proves steps(subject, 1);
          entry void main() {}
        }
        """));
  }

  static int section(byte[] artifact, int type) {
    var bytes = words(artifact);
    for (int index = 0; index < bytes.getInt(24); index++) {
      int directory = 40 + index * 32;
      if (bytes.getInt(directory) == type) {
        return Math.toIntExact(bytes.getLong(directory + 8));
      }
    }
    throw new AssertionError("missing section " + type);
  }

  static ByteBuffer words(byte[] bytes) {
    return ByteBuffer.wrap(bytes).order(ByteOrder.LITTLE_ENDIAN);
  }

  static VirtualMachine machine(byte[] artifact, boolean decode, String changes, int capacity)
      throws Exception {
    var modules = new LinkedHashMap<String, String>();
    modules.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.compiled_proof_products"));
    modules.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.linked_proof_section"));
    CoreSources.addBinaryClosure(modules);
    modules.put("ProofProducts.w", """
        module example.proof_products;
        import wheeler.compiler.closure.classical_proof_products;
        import wheeler.compiler.closure.compiled_proof_products;
        import wheeler.compiler.closure.linked_proof_section;

        classical class ProofProducts {
          private const long MAX_STRINGS = 16384;
          private const long NATIVE_WORD_BYTES = 8;
          private const long WORD_RADIX = 256 * 256 * 256 * 256;
          private const long WORD_MAX = WORD_RADIX - 1;
          private const long OUTPUT_PREFIX_BYTES = 13;
          private const long OUTPUT_TAIL_BYTES = 17;
          private const long FIXTURE_PROOFS = 2;
          private const long OUTPUT_BYTES = OUTPUT_PREFIX_BYTES + PROOF_WORD_BYTES
            + FIXTURE_PROOFS * CLASSICAL_PROOF_DESCRIPTOR_BYTES + OUTPUT_TAIL_BYTES;
          private const long TABLE_BYTES = (CLASSICAL_PROOF_ROWS + MAX_STRINGS) * NATIVE_WORD_BYTES;
          state long prepared = 0;
          state long published = 0;
          state long result = -1;

          entry void main(borrow byteview source, borrow mut bytes output) {
            region caller = new region(/* bytes= */ TABLE_BYTES, /* allocations= */ 2);
            words rows = allocate(caller, CLASSICAL_PROOF_ROWS);
            words strings = allocate(caller, MAX_STRINGS);
            long column = 0;
            while (column < CLASSICAL_PROOF_COLUMNS) limit CLASSICAL_PROOF_COLUMNS {
              set(rows, column * MAX_CLASSICAL_PROOFS, 211 + column);
              set(rows, (column + 1) * MAX_CLASSICAL_PROOFS - 1, 223 + column);
              column += 1;
            }
            set(strings, 0, 19);
            set(strings, MAX_STRINGS - 1, 31);
            long outputByte = 0;
            while (outputByte < bufferLength(output)) limit OUTPUT_BYTES {
              setByte(output, outputByte, (outputByte * 17 + 23) %% 251);
              outputByte += 1;
            }
            long moduleOwner = 7;
            long stringBase = 11;
            long stringCount = 64;
            long firstFunction = 17;
            long functionCount = 64;
            long firstProof = 3;
            long proofCount = FIXTURE_PROOFS;
            long outputStart = OUTPUT_PREFIX_BYTES;
            long artifactLength = bufferLength(source);
            %s
            %s
            prepared = 1;
            %s
            published = 1;
            drop(strings);
            drop(rows);
            drop(caller);
          }
        }
        """.formatted(decode ? "" : """
            set(strings, 11, 23);
            set(strings, 12, 29);
            set(rows, PROOF_NAME_ROW, 11);
            set(rows, PROOF_RULE_ROW, 1);
            set(rows, PROOF_SUBJECT_ROW, 18);
            set(rows, PROOF_ARGUMENT_LOW_ROW, WORD_MAX);
            set(rows, PROOF_ARGUMENT_HIGH_ROW, WORD_MAX);
            set(rows, PROOF_NAME_ROW + 1, 12);
            set(rows, PROOF_RULE_ROW + 1, 4);
            set(rows, PROOF_SUBJECT_ROW + 1, 17);
            set(rows, PROOF_ARGUMENT_LOW_ROW + 1, 8);
            """, changes, decode ? """
            result = appendCompiledProofProducts(
              source, artifactLength, moduleOwner, stringBase, stringCount,
              firstFunction, functionCount, firstProof, rows
            );
            """ : """
            result = emitLinkedProofSection(
              proofCount, functionCount, stringCount, rows, strings, output, outputStart
            );
            """));
    return VirtualMachine.withBinaryInput(new WheelerCompiler().compileModuleFiles(
        modules, "example.proof_products"), artifact, capacity);
  }

  static MachineSnapshot prepare(VirtualMachine machine) {
    while (machine.global("prepared") == 0) {
      machine.step();
    }
    return machine.snapshot();
  }

  static void publish(VirtualMachine machine) {
    while (machine.global("published") == 0) {
      machine.step();
    }
  }

  static List<BufferValue> tables(MachineSnapshot snapshot) {
    int region = snapshot.regions().stream().filter(r -> r.maxBytes() == TABLE_BYTES)
        .findFirst().orElseThrow().id();
    return snapshot.buffers().stream().filter(b -> b.regionId() == region).toList();
  }

  static void checkDecoded(MachineSnapshot prepared, MachineSnapshot published,
      byte[] artifact, int firstProof, int owner, int stringBase, int firstFunction) {
    var before = tables(prepared);
    var after = tables(published);
    var expected = new ArrayList<>(before.getFirst().elements());
    int start = section(artifact, 10);
    var bytes = words(artifact);
    int count = bytes.getInt(start);
    for (int proof = 0; proof < count; proof++) {
      for (int column = 0; column < COLUMNS; column++) {
        long value = Integer.toUnsignedLong(bytes.getInt(
            start + Integer.BYTES + proof * DESCRIPTOR_BYTES + column * Integer.BYTES));
        value = switch (column) {
          case 0 -> owner;
          case 1 -> value + stringBase;
          case 3 -> value + firstFunction;
          default -> value;
        };
        expected.set(column * MAX_PROOFS + firstProof + proof, value);
      }
    }
    assertEquals(expected, after.getFirst().elements());
    assertEquals(before.get(1), after.get(1));
    assertEquals(prepared.buffers().getFirst(), published.buffers().getFirst());
  }

  static void reject(VirtualMachine machine) {
    MachineSnapshot initial = machine.snapshot();
    MachineSnapshot prepared = prepare(machine);
    byte[] output = machine.hostOutput();
    assertThrows(VmTrap.class, machine::run);
    assertEquals(0, machine.global("published"));
    assertEquals(-1, machine.global("result"));
    assertArrayEquals(output, machine.hostOutput());
    assertEquals(tables(prepared), tables(machine.snapshot()));
    assertEquals(prepared.buffers().getFirst(), machine.snapshot().buffers().getFirst());
    MachineSnapshot rejected = machine.snapshot();
    rewind(machine, initial);
    assertThrows(VmTrap.class, machine::run);
    assertEquals(rejected, machine.snapshot());
    rewind(machine, initial);
  }

  static void finishAndReplay(VirtualMachine machine, MachineSnapshot initial) {
    machine.run();
    MachineSnapshot terminal = machine.snapshot();
    byte[] output = machine.hostOutput();
    rewind(machine, initial);
    machine.run();
    assertEquals(terminal, machine.snapshot());
    assertArrayEquals(output, machine.hostOutput());
    rewind(machine, initial);
  }

  private static void rewind(VirtualMachine machine, MachineSnapshot initial) {
    while (machine.historySize() > 0) {
      machine.rewindOne();
    }
    assertEquals(initial, machine.snapshot());
  }
}
