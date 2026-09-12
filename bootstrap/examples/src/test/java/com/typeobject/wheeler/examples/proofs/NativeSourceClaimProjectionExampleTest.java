package com.typeobject.wheeler.examples.proofs;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.compiler.CompilerException;
import com.typeobject.wheeler.compiler.SourceClaimOriginOracle;
import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.MachineSnapshot;
import com.typeobject.wheeler.core.vm.MachineStatus;
import com.typeobject.wheeler.core.vm.RegionValue;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.examples.CompilerSources;
import com.typeobject.wheeler.examples.CoreSources;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.charset.StandardCharsets;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.stream.IntStream;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;

/** Checks private claim erasure from counted byte origins without deciding proof truth. */
final class NativeSourceClaimProjectionExampleTest {
  private static final int SOURCE_BYTES = 32_768;
  private static final int CLAIMS = 64;
  private static final int ORIGIN_COLUMNS = 2;
  private static final int ORIGIN_WORDS = CLAIMS * ORIGIN_COLUMNS;
  private static final int WORD_BYTES = Long.BYTES;
  private static final int HEADER_WORDS = 4;
  private static final int TRANSPORT_WORDS = ORIGIN_WORDS + 1;
  private static final int PAYLOAD_START = (HEADER_WORDS + TRANSPORT_WORDS) * WORD_BYTES;
  private static final byte SENTINEL = (byte) 211;
  private static Program program;

  @BeforeAll
  static void compileDriver() throws Exception {
    var modules = new LinkedHashMap<>(CompilerSources.moduleClosure("wheeler.compiler.closure.source_classical_proofs"));
    CoreSources.addBinaryClosure(modules);
    modules.put("Projection.w", """
        module example.claim_projection;
        import wheeler.compiler.closure.source_classical_proofs;
        import wheeler.core.encoding.binary;
        classical class Projection {
          private const long SOURCE_BYTES = 32768;
          private const long WORD_BYTES = 8;
          private const long HEADER_WORDS = 4;
          private const long TRANSPORT_WORDS = SOURCE_PROOF_ORIGIN_ROWS + 1;
          private const long PAYLOAD_START = (HEADER_WORDS + TRANSPORT_WORDS) * WORD_BYTES;
          private const long ARENA_BYTES = TRANSPORT_WORDS * WORD_BYTES;
          state long phase = 0;
          state long accepted = 0;
          entry void main(borrow byteview input, borrow mut bytes output) {
            long originWords = readSigned(input, WORD_BYTES * 2);
            long payloadBytes = readSigned(input, WORD_BYTES * 3);
            region arena = new region(/* bytes= */ ARENA_BYTES, /* allocations= */ 1);
            words origins = allocate(arena, originWords);
            long cell = 0;
            while (cell < originWords) limit TRANSPORT_WORDS {
              set(origins, cell, readSigned(input, (HEADER_WORDS + cell) * WORD_BYTES));
              cell += 1;
            }
            long filled = 0;
            while (filled < bufferLength(output)) limit SOURCE_BYTES + 1 {
              long value = 211;
              if (filled < payloadBytes) { value = input[PAYLOAD_START + filled]; }
              setByte(output, filled, value);
              filled += 1;
            }
            phase = 1;
            boolean valid = projectSourceClaimOrigins(readSigned(input, 0),
              readSigned(input, WORD_BYTES), origins, output);
            if (valid) { accepted = 1; }
            phase = 2;
            drop(origins);
            drop(arena);
          }
        }
        """);
    program = new WheelerCompiler().compileModuleFiles(modules, "example.claim_projection");
  }

  @Test
  void projectsNativeBoundOriginsAndRetainsAllOriginalClaimFacts() throws Exception {
    String source = SourceProofFixture.source("public /* café 𝄞 */ protected private\r\n"
        + "theorem bound proves steps(alpha, BASE /* café */ + 1);\r\n"
        + "private public theorem inverseBound proves inverse(beta);");
    var binder = SourceProofFixture.machine(SourceProofFixture.program(""), source);
    while (binder.global("prepared") == 0) binder.stepWithoutRewindHistory();
    MachineSnapshot prepared = binder.snapshot();
    while (binder.global("published") == 0) binder.stepWithoutRewindHistory();
    SourceProofFixture.check(source, prepared, binder, true, SourceProofFixture.oracle(source));
    MachineSnapshot bound = binder.snapshot();
    long[] origins = bound.buffers().get(prepared.buffers().size() - 3).elements().stream().mapToLong(Long::longValue).toArray();
    check(source.getBytes(StandardCharsets.UTF_8), source.getBytes(StandardCharsets.UTF_8).length,
        2, origins, ORIGIN_WORDS, SOURCE_BYTES, true, true);
    assertEquals(bound, binder.snapshot(), "projection cannot mutate the original bound facts");
    while (binder.status() == MachineStatus.RUNNING) binder.stepWithoutRewindHistory();
    assertEquals(MachineStatus.HALTED, binder.status());
  }

  @Test
  void retainsABoundThatPassesPlaceholderCodeButFailsActualNominalCode() throws Exception {
    String members = "record Pair(long value) {}";
    String original = SourceProofFixture.source(members).replace("return BASE;",
        "Pair pair = new Pair(BASE); return pair.value;");
    String placeholder = original.replace("Pair pair = new Pair(BASE); return pair.value;",
        "long pair = 0; return pair;");
    int placeholderSteps = SourceProofFixture.compiled(placeholder).functions().stream()
        .filter(function -> function.name().endsWith("::alpha")).findFirst().orElseThrow().forward().size();
    int actualSteps = SourceProofFixture.compiled(original).functions().stream()
        .filter(function -> function.name().endsWith("::alpha")).findFirst().orElseThrow().forward().size();
    assertTrue(placeholderSteps < actualSteps);
    String claim = "theorem bound proves steps(alpha, " + placeholderSteps + ");";
    SourceProofFixture.compiled(placeholder.replace(members, members + claim));
    String claimed = original.replace(members, members + claim);
    var rejected = assertThrows(CompilerException.class, () -> SourceProofFixture.compiled(claimed));
    assertTrue(rejected.getMessage().contains("Proof bound failed: declared step bound does not hold"));
    var binder = SourceProofFixture.machine(SourceProofFixture.program(""), claimed);
    MachineSnapshot initial = binder.snapshot();
    MachineSnapshot prepared = SourceProofFixture.prepare(binder);
    SourceProofFixture.publish(binder);
    SourceProofFixture.check(claimed, prepared, binder, true,
        List.of(new SourceProofFixture.Claim("bound", 4, 0, placeholderSteps)));
    var bound = binder.snapshot();
    long[] origins = bound.buffers().get(prepared.buffers().size() - 3).elements().stream().mapToLong(Long::longValue).toArray();
    check(bytes(claimed), bytes(claimed).length, 1, origins, ORIGIN_WORDS, SOURCE_BYTES, true, true);
    assertEquals(bound, binder.snapshot());
    SourceProofFixture.replay(binder, initial);
  }

  @Test
  void preservesUnselectedBytesForEmptyAdjacentAndTerminalWindows() {
    check(new byte[0], 0, 0, emptyOrigins(), ORIGIN_WORDS, SOURCE_BYTES, true, true);
    byte[] source = "a\r\nb café 𝄞 tail".getBytes(StandardCharsets.UTF_8);
    long[] origins = emptyOrigins();
    origins[0] = 0;
    origins[CLAIMS] = 4;
    origins[1] = 4;
    origins[CLAIMS + 1] = source.length - 4;
    check(source, source.length, 2, origins, ORIGIN_WORDS, SOURCE_BYTES, true, true);
  }

  @Test
  void acceptsAllOriginsAndTheFullSourceWindowWithoutHistoryGrowth() {
    String members = IntStream.range(0, CLAIMS).mapToObj(i -> "public theorem p" + i + " proves steps(f, 1);")
        .collect(java.util.stream.Collectors.joining());
    String source = "classical class C { void f() {} " + members + " }";
    check(bytes(source), bytes(source).length, CLAIMS, origins(source), ORIGIN_WORDS, SOURCE_BYTES, true, false);
    String prefix = "classical class C { void f() {} public theorem p proves steps(f, /*";
    String suffix = "*/ 1); }";
    String full = prefix + "x".repeat(SOURCE_BYTES - bytes(prefix).length - bytes(suffix).length) + suffix;
    check(bytes(full), SOURCE_BYTES, 1, origins(full), ORIGIN_WORDS, SOURCE_BYTES, true, false);
  }

  @Test
  void rejectsMalformedLaterOriginsAndUtf8SplitsBeforeErasingAnyByte() {
    byte[] source = bytes("0123456789 café 𝄞 end");
    long[] valid = emptyOrigins();
    valid[0] = 0;
    valid[CLAIMS] = 3;
    valid[1] = 4;
    valid[CLAIMS + 1] = 3;
    for (long[] change : List.of(new long[] {1, -1}, new long[] {1, 2}, new long[] {1, source.length + 1},
        new long[] {1, Long.MAX_VALUE}, new long[] {CLAIMS + 1, 0}, new long[] {CLAIMS + 1, -1},
        new long[] {CLAIMS + 1, source.length}, new long[] {CLAIMS + 1, Long.MAX_VALUE})) {
      long[] bad = valid.clone();
      bad[(int) change[0]] = change[1];
      check(source, source.length, 2, bad, ORIGIN_WORDS, SOURCE_BYTES, false, true);
    }
    int continuation = bytes("0123456789 caf").length + 1;
    for (long[] split : List.of(new long[] {continuation, 1}, new long[] {continuation - 1, 1})) {
      long[] bad = valid.clone();
      bad[1] = split[0];
      bad[CLAIMS + 1] = split[1];
      check(source, source.length, 2, bad, ORIGIN_WORDS, SOURCE_BYTES, false, true);
    }
  }

  @Test
  void rejectsCountsAndBackingsEvenForEmptyOriginWindows() {
    byte[] source = bytes("classical class Empty {}");
    for (long count : List.of(-1L, (long) CLAIMS + 1, Long.MAX_VALUE)) {
      check(source, source.length, count, emptyOrigins(), ORIGIN_WORDS, SOURCE_BYTES, false, true);
    }
    for (long length : List.of(-1L, (long) SOURCE_BYTES + 1, Long.MAX_VALUE)) {
      check(source, length, 0, emptyOrigins(), ORIGIN_WORDS, SOURCE_BYTES, false, true);
    }
    for (int backing : List.of(ORIGIN_WORDS - 1, ORIGIN_WORDS + 1)) {
      check(source, source.length, 0, emptyOrigins(), backing, SOURCE_BYTES, false, true);
    }
    for (int backing : List.of(SOURCE_BYTES - 1, SOURCE_BYTES + 1)) {
      check(source, source.length, 0, emptyOrigins(), ORIGIN_WORDS, backing, false, true);
    }
  }

  private static void check(byte[] source, long sourceLength, long count, long[] origins,
      int originWords, int outputBytes, boolean valid, boolean history) {
    ByteBuffer input = ByteBuffer.allocate(PAYLOAD_START + source.length).order(ByteOrder.LITTLE_ENDIAN);
    input.putLong(sourceLength).putLong(count).putLong(originWords).putLong(source.length);
    for (int cell = 0; cell < TRANSPORT_WORDS; cell++) input.putLong(cell < origins.length ? origins[cell] : 211);
    input.put(source);
    var machine = VirtualMachine.withBinaryInput(program, input.array(), outputBytes);
    var borrowed = machine.snapshot().regions().stream().map(RegionValue::id).toList();
    while (machine.global("phase") != 1) machine.stepWithoutRewindHistory();
    MachineSnapshot before = machine.snapshot();
    while (machine.global("phase") != 2) {
      if (history) machine.step(); else machine.stepWithoutRewindHistory();
    }
    MachineSnapshot after = machine.snapshot();
    assertEquals(valid ? 1 : 0, machine.global("accepted"));
    assertEquals(before.regions(), after.regions(), "no new owned regions");
    assertEquals(before.buffers().size(), after.buffers().size(), "no new lifetime buffers");
    assertEquals(before.buffers().getFirst(), after.buffers().getFirst(), "input bytes");
    assertEquals(before.buffers().getLast(), after.buffers().getLast(), "all origin cells");
    byte[] expected = new byte[outputBytes];
    Arrays.fill(expected, SENTINEL);
    System.arraycopy(source, 0, expected, 0, Math.min(source.length, outputBytes));
    if (valid) {
      for (int claim = 0; claim < count; claim++) {
        for (int at = (int) origins[claim]; at < origins[claim] + origins[CLAIMS + claim]; at++) {
          if (expected[at] != '\r' && expected[at] != '\n') expected[at] = ' ';
        }
      }
    }
    assertArrayEquals(expected, machine.hostOutput(), "complete projection and inactive tail");
    int steps = machine.historySize();
    if (history) {
      for (int step = 0; step < steps; step++) machine.rewindOne();
      assertEquals(before, machine.snapshot());
      for (int step = 0; step < steps; step++) machine.step();
      assertEquals(after, machine.snapshot());
    } else assertEquals(0, steps);
    while (machine.status() == MachineStatus.RUNNING) {
      if (history) machine.step(); else machine.stepWithoutRewindHistory();
    }
    assertEquals(MachineStatus.HALTED, machine.status());
    for (var buffer : machine.snapshot().buffers()) {
      if (!borrowed.contains(buffer.regionId())) assertTrue(buffer.dropped(), "buffer " + buffer.id());
    }
    for (var region : machine.snapshot().regions()) {
      if (!borrowed.contains(region.id())) assertTrue(region.dropped(), "region " + region.id());
    }
  }

  private static long[] emptyOrigins() {
    long[] rows = new long[ORIGIN_WORDS];
    Arrays.fill(rows, 211);
    return rows;
  }

  private static long[] origins(String source) {
    long[] rows = emptyOrigins();
    var expected = SourceClaimOriginOracle.origins(source);
    for (int row = 0; row < expected.size(); row++) {
      rows[row] = expected.get(row).start();
      rows[CLAIMS + row] = expected.get(row).length();
    }
    return rows;
  }

  private static byte[] bytes(String source) {
    return source.getBytes(StandardCharsets.UTF_8);
  }
}
