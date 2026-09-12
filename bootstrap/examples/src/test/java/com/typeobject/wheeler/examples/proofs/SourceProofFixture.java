package com.typeobject.wheeler.examples.proofs;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.compiler.SourceClaimOriginOracle;
import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.MachineSnapshot;
import com.typeobject.wheeler.core.vm.RegionValue;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import com.typeobject.wheeler.examples.CompilerSources;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;

/** Source-only proof binding with complete caller-buffer and lifetime observations. */
final class SourceProofFixture {
  static final int CAPACITY = 64;
  static final int COLUMNS = 5;
  static final int ORIGIN_COLUMNS = 2;
  static final int ORIGIN_WORDS = CAPACITY * ORIGIN_COLUMNS;
  static final long SENTINEL = 211;
  static final String CONSTANT_NAMES = "BASEFLAGfixture.bounds";

  record Claim(String name, long rule, long subject, long argument) {}

  private SourceProofFixture() {}

  static String source(String members) {
    return """
        module fixture.source_proofs;
        import fixture.bounds;
        classical class SourceProofs {
          // café 𝄞 precedes every declaration coordinate.
          long alpha() { return BASE; }
          rev void beta() {}
          %s
        }
        """.formatted(members);
  }

  static Program compiled(String source) {
    return new WheelerCompiler().compileLibraryModuleFiles(
        java.util.Map.of("Source.w", source, "Bounds.w", """
            module fixture.bounds;
            classical class Bounds {
              public const long BASE = 7;
              public const boolean FLAG = true;
            }
            """), "fixture.source_proofs");
  }

  static List<Claim> oracle(String source) {
    var program = compiled(source);
    return program.proofCertificates().stream().map(proof -> {
      String function = program.functions().get(proof.subjectId()).name();
      int qualifier = function.lastIndexOf("::");
      String localName = qualifier < 0 ? function : function.substring(qualifier + 2);
      long subject = java.util.Map.of("alpha", 0L, "beta", 1L).get(localName);
      return new Claim(proof.name(), proof.rule().code(), subject,
          proof.argument());
    }).toList();
  }

  static VirtualMachine machine(Program program, String source) {
    return new VirtualMachine(program, source.getBytes(StandardCharsets.UTF_8));
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

  static void check(String source, MachineSnapshot prepared, VirtualMachine machine, boolean valid,
      List<Claim> claims) {
    assertEquals(valid ? 1 : 0, machine.global("valid"));
    assertEquals(valid ? claims.size() : 0, machine.global("proofCount"));
    var before = prepared.buffers();
    var after = machine.snapshot().buffers();
    int originsIndex = before.size() - 3;
    int rowsIndex = before.size() - 2;
    int namesIndex = before.size() - 1;
    assertEquals(before.subList(0, originsIndex), after.subList(0, originsIndex));
    var origins = new ArrayList<>(before.get(originsIndex).elements());
    var expectedOrigins = valid ? SourceClaimOriginOracle.origins(source) : List.<SourceClaimOriginOracle.Origin>of();
    assertEquals(claims.size(), expectedOrigins.size());
    var rows = new ArrayList<>(before.get(rowsIndex).elements());
    var names = new ArrayList<>(before.get(namesIndex).elements());
    int nameCursor = 0;
    if (valid) {
      for (int proof = 0; proof < claims.size(); proof++) {
        Claim claim = claims.get(proof);
        var origin = expectedOrigins.get(proof);
        assertEquals(claim.name(), origin.name());
        origins.set(proof, origin.start());
        origins.set(CAPACITY + proof, origin.length());
        byte[] name = claim.name().getBytes(StandardCharsets.US_ASCII);
        long[] values = {nameCursor, name.length, claim.rule(), claim.subject(), claim.argument()};
        for (int column = 0; column < COLUMNS; column++) {
          rows.set(column * CAPACITY + proof, values[column]);
        }
        for (byte value : name) {
          names.set(nameCursor++, Byte.toUnsignedLong(value));
        }
      }
    }
    assertEquals(nameCursor, machine.global("nameBytes"));
    assertEquals(origins, after.get(originsIndex).elements(), "complete origin columns and inactive tails");
    assertEquals(rows, after.get(rowsIndex).elements());
    assertEquals(names, after.get(namesIndex).elements());
    if (valid) {
      int tokenCapacity = 4_096;
      int moduleRangeWords = 2;
      int nameCapacity = CAPACITY * 256;
      var wordLengths = List.of(tokenCapacity, tokenCapacity, tokenCapacity, moduleRangeWords,
          CAPACITY, CAPACITY, CAPACITY * (COLUMNS + ORIGIN_COLUMNS), CAPACITY, CAPACITY, CAPACITY);
      long scratchBytes = wordLengths.stream().mapToLong(Integer::longValue).sum() * Long.BYTES + nameCapacity;
      int scratchBuffers = wordLengths.size() + 1;
      long stepClaims = claims.stream().filter(claim -> claim.rule() == 4).count();
      assertEquals(before.size() + scratchBuffers + stepClaims, after.size(), "lifetime buffer identities");
      assertEquals(prepared.regions().size() + 1 + stepClaims, machine.snapshot().regions().size());
      var scratch = machine.snapshot().regions().get(prepared.regions().size());
      assertEquals(scratchBytes, scratch.maxBytes());
      assertEquals(scratchBuffers, scratch.maxObjects());
      for (int buffer = 0; buffer < wordLengths.size(); buffer++) {
        assertEquals(wordLengths.get(buffer).intValue(), after.get(before.size() + buffer).length());
      }
      assertEquals(nameCapacity, after.get(before.size() + wordLengths.size()).length());
    }
  }

  static void rejectTrapAndReplay(VirtualMachine machine) {
    MachineSnapshot initial = machine.snapshot();
    MachineSnapshot prepared = prepare(machine);
    assertThrows(VmTrap.class, machine::run);
    assertEquals(0, machine.global("published"));
    assertEquals(0, machine.global("valid"));
    assertEquals(-1, machine.global("proofCount"));
    assertEquals(-1, machine.global("nameBytes"));
    assertEquals(prepared.buffers(), machine.snapshot().buffers().subList(0, prepared.buffers().size()));
    MachineSnapshot rejected = machine.snapshot();
    rewind(machine, initial);
    assertThrows(VmTrap.class, machine::run);
    assertEquals(rejected, machine.snapshot());
    rewind(machine, initial);
  }

  static void replay(VirtualMachine machine, MachineSnapshot initial) {
    machine.run();
    MachineSnapshot terminal = machine.snapshot();
    cleanup(machine, initial);
    rewind(machine, initial);
    machine.run();
    assertEquals(terminal, machine.snapshot());
    rewind(machine, initial);
  }

  static void cleanup(VirtualMachine machine, MachineSnapshot initial) {
    var borrowed = initial.regions().stream().map(RegionValue::id).toList();
    for (var buffer : machine.snapshot().buffers()) {
      if (!borrowed.contains(buffer.regionId())) assertTrue(buffer.dropped(), "buffer " + buffer.id());
    }
    for (var region : machine.snapshot().regions()) {
      if (!borrowed.contains(region.id())) assertTrue(region.dropped(), "region " + region.id());
    }
  }

  static void rewind(VirtualMachine machine, MachineSnapshot initial) {
    while (machine.historySize() > 0) {
      machine.rewindOne();
    }
    assertEquals(initial, machine.snapshot());
  }

  static Program program(String changes) throws Exception {
    return program(changes, "alpha", "beta");
  }

  static Program program(String changes, String firstName, String secondName) throws Exception {
    return program(changes, firstName, secondName, ORIGIN_WORDS);
  }

  static Program program(String changes, String firstName, String secondName, int originWords) throws Exception {
    String callableNames = firstName + secondName;
    var sources = new LinkedHashMap<>(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.source_classical_proofs"));
    sources.putAll(CompilerSources.moduleClosure("wheeler.compiler.closure.scoped_constant_products"));
    StringBuilder writes = new StringBuilder();
    for (int index = 0; index < callableNames.length(); index++) {
      writes.append("setByte(names, ").append(index).append(", ")
          .append((int) callableNames.charAt(index)).append(");\n");
    }
    for (int index = 0; index < CONSTANT_NAMES.length(); index++) {
      writes.append("setByte(rawNames, ").append(index).append(", ")
          .append((int) CONSTANT_NAMES.charAt(index)).append(");\n");
    }
    sources.put("SourceProofBinding.w", """
        module example.source_proof_binding;
        import wheeler.compiler.closure.scoped_constant_products;
        import wheeler.compiler.closure.source_classical_proofs;
        import wheeler.compiler.constant_product_schema;
        classical class SourceProofBinding {
          private const long CALLABLES = 64;
          private const long STRINGS = 256;
          private const long WORD_BYTES = 8;
          private const long CONSTANT_COLUMNS = CONSTANT_PRODUCT_COLUMNS;
          private const long CONSTANT_COUNT = 2;
          private const long CONSTANT_ROWS = CONSTANT_PRODUCT_HEADER_ROWS + CONSTANT_COLUMNS * CONSTANT_COUNT;
          private const long NAME_BYTES = %d;
          private const long CONSTANT_NAME_BYTES = %d;
          private const long FIRST_NAME_BYTES = %d;
          private const long SECOND_NAME_BYTES = NAME_BYTES - FIRST_NAME_BYTES;
          private const long CALLABLE_BUFFERS = 5;
          private const long CONSTANT_BUFFERS = 4;
          private const long PROOF_BUFFERS = 3;
          private const long ORIGIN_WORDS = %d;
          private const long COPIED_CONSTANT_BYTES = BASE_BYTES + FLAG_BYTES + CONSTANT_COUNT * MODULE_BYTES;
          private const long ARENA_BYTES = (CALLABLES * 2 + STRINGS * 2 + CONSTANT_ROWS * 2
            + SOURCE_PROOF_ROWS + ORIGIN_WORDS) * WORD_BYTES + NAME_BYTES + CONSTANT_NAME_BYTES
            + COPIED_CONSTANT_BYTES + SOURCE_PROOF_NAMES;
          private const long ARENA_ALLOCATIONS = CALLABLE_BUFFERS + CONSTANT_BUFFERS + PROOF_BUFFERS;
          private const long BASE_BYTES = 4;
          private const long FLAG_BYTES = 4;
          private const long MODULE_START = BASE_BYTES + FLAG_BYTES;
          private const long MODULE_BYTES = CONSTANT_NAME_BYTES - MODULE_START;
          private const long NAME_START_COLUMN = 0;
          private const long NAME_LENGTH_COLUMN = 1;
          private const long TYPE_COLUMN = 2;
          private const long VALUE_COLUMN = 3;
          private const long RESOLVED_COLUMN = 4;
          private const long MODULE_START_COLUMN = 5;
          private const long MODULE_LENGTH_COLUMN = 6;
          state long prepared = 0;
          state long published = 0;
          state long valid = 0;
          state long proofCount = -1;
          state long nameBytes = -1;
          entry void main(borrow utf8 source) {
            region arena = new region(/* bytes= */ ARENA_BYTES, /* allocations= */ ARENA_ALLOCATIONS);
            bytes names = allocateBytes(arena, NAME_BYTES);
            words effects = allocate(arena, CALLABLES);
            words starts = allocate(arena, STRINGS);
            words lengths = allocate(arena, STRINGS);
            words ids = allocate(arena, CALLABLES);
            bytes rawNames = allocateBytes(arena, CONSTANT_NAME_BYTES);
            words rawConstants = allocate(arena, CONSTANT_ROWS);
            bytes constantNames = allocateBytes(arena, COPIED_CONSTANT_BYTES);
            words constants = allocate(arena, CONSTANT_ROWS);
            words origins = allocate(arena, ORIGIN_WORDS);
            words rows = allocate(arena, SOURCE_PROOF_ROWS);
            bytes proofNames = allocateBytes(arena, SOURCE_PROOF_NAMES);
            %s
            set(effects, 1, /* rev= */ 2);
            set(starts, 1, FIRST_NAME_BYTES);
            set(lengths, 0, FIRST_NAME_BYTES);
            set(lengths, 1, SECOND_NAME_BYTES);
            set(ids, 1, 1);
            set(rawConstants, 0, CONSTANT_COUNT);
            long first = CONSTANT_PRODUCT_HEADER_ROWS;
            long second = first + CONSTANT_COLUMNS;
            set(rawConstants, first + NAME_LENGTH_COLUMN, BASE_BYTES);
            set(rawConstants, first + TYPE_COLUMN, CONSTANT_SIGNED);
            set(rawConstants, first + VALUE_COLUMN, /* BASE= */ 7);
            set(rawConstants, first + RESOLVED_COLUMN, 1);
            set(rawConstants, first + MODULE_START_COLUMN, MODULE_START);
            set(rawConstants, first + MODULE_LENGTH_COLUMN, MODULE_BYTES);
            set(rawConstants, second + NAME_START_COLUMN, BASE_BYTES);
            set(rawConstants, second + NAME_LENGTH_COLUMN, FLAG_BYTES);
            set(rawConstants, second + TYPE_COLUMN, CONSTANT_BOOLEAN);
            set(rawConstants, second + VALUE_COLUMN, /* FLAG= */ 1);
            set(rawConstants, second + RESOLVED_COLUMN, 1);
            set(rawConstants, second + MODULE_START_COLUMN, MODULE_START);
            set(rawConstants, second + MODULE_LENGTH_COLUMN, MODULE_BYTES);
            ScopedConstantProductPlan copiedConstants = copyScopedConstantProducts(
              rawNames, rawNames, CONSTANT_COUNT, rawConstants, 0, constantNames, constants
            );
            assert(copiedConstants.productCount == CONSTANT_COUNT);
            assert(copiedConstants.nameBytes == COPIED_CONSTANT_BYTES);
            long originCell = 0;
            while (originCell < ORIGIN_WORDS) limit ORIGIN_WORDS {
              set(origins, originCell, SENTINEL);
              originCell += 1;
            }
            long cell = 0;
            while (cell < SOURCE_PROOF_ROWS) limit SOURCE_PROOF_ROWS {
              set(rows, cell, %d);
              cell += 1;
            }
            long name = 0;
            while (name < SOURCE_PROOF_NAMES) limit SOURCE_PROOF_NAMES {
              setByte(proofNames, name, %d);
              name += 1;
            }
            long selectedCallables = 2;
            long selectedStrings = 2;
            long selectedBytes = NAME_BYTES;
            %s
            prepared = 1;
            SourceClassicalProofPlan plan = materializeSourceClassicalProofs(source,
              selectedCallables, effects, names, selectedBytes, selectedStrings,
              starts, lengths, ids, constantNames, constants, proofNames, rows, origins);
            proofCount = plan.proofCount;
            nameBytes = plan.nameBytes;
            if (plan.valid) { valid = 1; }
            published = 1;
            drop(proofNames);
            drop(rows);
            drop(origins);
            drop(constants);
            drop(constantNames);
            drop(rawConstants);
            drop(rawNames);
            drop(ids);
            drop(lengths);
            drop(starts);
            drop(effects);
            drop(names);
            drop(arena);
          }
        }
        """.formatted(callableNames.length(), CONSTANT_NAMES.length(), firstName.length(), originWords, writes,
            SENTINEL, SENTINEL, changes).replace("SENTINEL", Long.toString(SENTINEL)));
    return new WheelerCompiler().compileModuleFiles(sources, "example.source_proof_binding");
  }
}
