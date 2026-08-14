package com.typeobject.wheeler.runtime;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.core.bytecode.FunctionBody;
import com.typeobject.wheeler.core.bytecode.Global;
import com.typeobject.wheeler.core.bytecode.Instruction;
import com.typeobject.wheeler.core.bytecode.Opcode;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.HexFormat;
import java.util.List;
import org.junit.jupiter.api.Test;

/** Malformed-corpus and deterministic join checks for semantic point relations. */
final class SemanticCoverageMapTest {
  @Test
  void joinsExactRuntimePointsToSourceAndBytecodeCoordinates() throws Exception {
    Program program = program();
    SemanticCoverage coverage = coverage(program);
    List<SemanticCoverageMap.Relation> relations = relations(program);
    SemanticCoverageMap first = new SemanticCoverageMap(program, relations);
    SemanticCoverageMap second = new SemanticCoverageMap(
        program, List.of(relations.get(1), relations.get(0)));

    assertEquals(first.identity(), second.identity());
    assertEquals(first.join(coverage), second.join(coverage));
    String joined = first.join(coverage);
    assertTrue(joined.contains("\"profile\":\"wheeler-source-transition-coverage-1\""));
    assertTrue(joined.contains("\"source_path\":\"src/Counter.w\""));
    assertTrue(joined.contains("\"line\":7"));
    assertTrue(joined.contains("\"opcode\":\"ADD_CONST\""));
    assertTrue(joined.contains("\"branch\":\"none\""));
    assertTrue(joined.contains("\"path_coverage\":\"" + coverage.pathIdentity() + "\""));
    assertTrue(joined.contains("\"from_source_path\":\"src/Counter.w\""));
    assertTrue(joined.contains("\"to_source_path\":\"src/Counter.w\""));
    assertNotEquals(coverage.identity(), first.identity());
  }

  @Test
  void rejectsDanglingDuplicateOverlappingAndForgedRelations() {
    Program program = program();
    List<SemanticCoverageMap.Relation> valid = relations(program);
    SemanticCoverageMap.Relation first = valid.get(0);
    String zeros = "0".repeat(64);

    assertThrows(
        IllegalArgumentException.class,
        () -> new SemanticCoverageMap(program, List.of(new SemanticCoverageMap.Relation(
            first.source(), "forward", 0, 2, 1,
            SemanticCoverageMap.Origin.AUTHORED, zeros))));
    assertThrows(
        IllegalArgumentException.class,
        () -> new SemanticCoverageMap(program, List.of(first, first)));

    SemanticCoverageMap.Relation wide = relation(program, range(7, 1, 7, 10), 0, 2);
    SemanticCoverageMap.Relation overlap = relation(program, range(8, 1, 8, 5), 1, 1);
    assertThrows(
        IllegalArgumentException.class,
        () -> new SemanticCoverageMap(program, List.of(wide, overlap)));
    assertThrows(
        IllegalArgumentException.class,
        () -> new SemanticCoverageMap(program, List.of(new SemanticCoverageMap.Relation(
            first.source(), "forward", 0, 0, 1,
            SemanticCoverageMap.Origin.AUTHORED, zeros))));
    assertThrows(
        IllegalArgumentException.class,
        () -> new SemanticCoverageMap(program, List.of(new SemanticCoverageMap.Relation(
            first.source(), "forward", 0, 0, 1,
            SemanticCoverageMap.Origin.GENERATED_INVERSE, first.opcodeIdentity()))));
  }

  @Test
  void rejectsMissingRuntimeRelationsAndMalformedSourceCoordinates() {
    Program program = program();
    SemanticCoverageMap partial = new SemanticCoverageMap(
        program, List.of(relations(program).getFirst()));
    assertThrows(IllegalArgumentException.class, () -> partial.join(coverage(program)));
    assertThrows(
        IllegalArgumentException.class,
        () -> new SemanticCoverageMap.SourceRange(
            sourceIdentity(), "../Counter.w", 1, 1, 1, 2));
    assertThrows(
        IllegalArgumentException.class,
        () -> new SemanticCoverageMap.SourceRange(
            sourceIdentity(), "src/Counter.w", 1, 2, 1, 2));
  }

  private static List<SemanticCoverageMap.Relation> relations(Program program) {
    return List.of(
        relation(program, range(7, 1, 7, 10), 0, 1),
        relation(program, range(8, 1, 8, 5), 1, 1));
  }

  private static SemanticCoverageMap.Relation relation(
      Program program,
      SemanticCoverageMap.SourceRange source,
      int first,
      int count) {
    return new SemanticCoverageMap.Relation(
        source,
        "forward",
        0,
        first,
        count,
        SemanticCoverageMap.Origin.AUTHORED,
        SemanticCoverageMap.opcodeIdentity(program, "forward", 0, first, count));
  }

  private static SemanticCoverageMap.SourceRange range(
      int startLine, int startColumn, int endLine, int endColumn) {
    return new SemanticCoverageMap.SourceRange(
        sourceIdentity(), "src/Counter.w", startLine, startColumn, endLine, endColumn);
  }

  private static SemanticCoverage coverage(Program program) {
    SemanticCoverage coverage = new SemanticCoverage();
    new VirtualMachine(program, coverage).run();
    return coverage;
  }

  private static Program program() {
    FunctionBody main = new FunctionBody(
        0,
        "main",
        false,
        0,
        List.of(),
        null,
        List.of(Instruction.of(Opcode.ADD_CONST, 0, 1), Instruction.of(Opcode.HALT)),
        List.of());
    return new Program("Mapped", 0, List.of(new Global("value", 0)), List.of(main));
  }

  private static String sourceIdentity() {
    try {
      return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(
          "source".getBytes(StandardCharsets.UTF_8)));
    } catch (Exception exception) {
      throw new AssertionError(exception);
    }
  }
}
