package com.typeobject.wheeler.examples.proofs;

import static com.typeobject.wheeler.examples.proofs.SourceProofFixture.source;

import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.MachineSnapshot;
import java.util.List;
import java.util.stream.IntStream;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;

/** Source binding evidence, separate from final-code and manifest proof acceptance. */
final class NativeSourceClassicalProofsExampleTest {
  private static Program program;

  @BeforeAll
  static void compileDriver() throws Exception {
    program = SourceProofFixture.program("");
  }

  @Test
  void matchesBothStageZeroRulesWithRepeatedSubjectsAndForwardDeclarations() {
    String input = source("""
        theorem betaInverse proves inverse(beta);
        theorem alphaSteps proves steps(alpha, BASE + 1);
        theorem betaSteps proves steps(beta, fixture.bounds::BASE * 2);
        theorem betaAgain proves inverse(beta);
        """).replace("long alpha() { return BASE; }", "")
        .replace("rev void beta() {}", "")
        .replace("theorem betaAgain", "long alpha() { return BASE; } rev void beta() {} theorem betaAgain");
    check(input, true, SourceProofFixture.oracle(input));
  }

  @Test
  void usesDeclarationFrontsInsteadOfSearchingForTheoremWords() {
    String input = source("""
        state long theorem = 0;
        const long steps = 3;
        record Pair(long theorem) {}
        variant Choice { case theorem(); }
        enum Flag { case theorem; }
        long helper() { long theorem = 1; return theorem; }
        theorem theorem proves steps(alpha, 8);
        theorem betaInverse proves inverse(beta);
        """);
    check(input, true, SourceProofFixture.oracle(input));
  }

  @Test
  void checksQualifiedCallableOwnershipBeforeBindingTheLocalName() throws Exception {
    String input = source("theorem bound proves steps(alpha, 8);");
    check(SourceProofFixture.program("", "fixture.source_proofs::alpha", "fixture.source_proofs::beta"),
        input, true, SourceProofFixture.oracle(input), true);
    check(SourceProofFixture.program("", "fixture.other_source::alpha", "beta"),
        input, false, List.of(), true);
    check(SourceProofFixture.program("", "::alpha", "beta"), input, false, List.of(), true);
  }

  @Test
  void handlesAnEmptyCallableWindowWithoutInventingASubject() throws Exception {
    Program empty = SourceProofFixture.program("selectedCallables = 0; selectedStrings = 0; selectedBytes = 0;");
    check(empty, "classical class Empty {}", true, List.of(), true);
    check(empty, "classical class Empty { theorem bad proves steps(missing, 8); }",
        false, List.of(), true);
  }

  @ParameterizedTest
  @ValueSource(strings = {"selectedCallables = -1;", "selectedCallables = 65;",
      "selectedStrings = -1;", "selectedStrings = 257;", "selectedBytes = -1;",
      "selectedBytes = NAME_BYTES + 1;"})
  void rejectsInvalidCountedWindowsBeforeChangingCallerStorage(String changes) throws Exception {
    SourceProofFixture.rejectTrapAndReplay(
        SourceProofFixture.machine(SourceProofFixture.program(changes), source("")));
  }

  @Test
  void acceptsAnEmptyProofTableWithoutTouchingAnyPublicationCell() {
    String input = source("");
    check(input, true, SourceProofFixture.oracle(input));
  }

  @ParameterizedTest
  @ValueSource(longs = {1, 4294967295L, 4294967296L, Long.MAX_VALUE})
  void retainsFullPositiveBoundsWithoutAssertingTheyFitTheFinalManifest(long bound) {
    check(source("theorem bound proves steps(beta, " + bound + ");"), true,
        List.of(new SourceProofFixture.Claim("bound", 4, 1, bound)));
  }

  @ParameterizedTest
  @ValueSource(strings = {
      "theorem bad proves steps(alpha, 0);",
      "theorem bad proves steps(alpha, -1);",
      "theorem bad proves steps(alpha, true);",
      "theorem bad proves steps(alpha, FLAG);",
      "theorem bad proves steps(alpha, BASE == 7);",
      "theorem bad proves steps(alpha, BASE = = 7);",
      "theorem bad proves steps(alpha, BASE =/*gap*/= 7);",
      "theorem bad proves steps(alpha, 1 + );",
      "theorem bad proves steps(alpha, 7 1);",
      "theorem bad proves steps(alpha, UNKNOWN);",
      "theorem bad proves steps(alpha, 7 / 0);",
      "theorem bad proves steps(missing, 8);",
      "theorem bad proves inverse(alpha);",
      "theorem bad proves inverse(missing);",
      "theorem bad proves adjoint(beta);",
      "theorem bad proves equivalent(beta, beta);",
      "theorem bad proves unknown(beta);",
      "theorem bad proves inverse(beta, 8);",
      "theorem bad proves steps(beta);",
      "theorem bad proves steps(beta, );",
      "theorem good proves steps(alpha, 8);"
  })
  void rejectsLaterMalformedClaimsWithoutPublishingTheirValidPredecessor(String rejected) {
    check(source("theorem good proves inverse(beta);\n" + rejected), false, List.of());
  }

  @ParameterizedTest
  @ValueSource(strings = {
      "set(ids, 1, -1);", "set(ids, 1, 2);",
      "set(ids, 1, 9223372036854775807);", "set(ids, 1, 0);",
      "set(starts, 1, -1);", "set(starts, 1, 9223372036854775807);",
      "set(lengths, 1, 0);", "set(lengths, 1, 5);",
      "set(lengths, 1, 9223372036854775807);",
      "set(effects, 1, 0);", "set(effects, 1, 4);",
      "setByte(names, 5, 0);", "setByte(names, 5, 128);",
      "setByte(names, 5, 120);"
  })
  void rejectsUnboundOrStaleCallableProductsAtomically(String changes) throws Exception {
    check(SourceProofFixture.program(changes), source("theorem good proves inverse(beta);"),
        false, List.of(), true);
  }

  @Test
  void checksNameBoundsBeforeCopyingAndComparesTheLastByte() {
    String prefix = "p".repeat(255);
    String input = source("theorem " + prefix + "a proves steps(alpha, 8);\n"
        + "theorem " + prefix + "b proves inverse(beta);");
    check(input, true, SourceProofFixture.oracle(input));
    check(input.replace(prefix + "b", prefix + "a"), false, List.of());
    check(input.replace(prefix + "b", prefix + "bb"), false, List.of());
  }

  @Test
  void admitsTheLastClaimAndRejectsTheFirstExcessWithCompleteTableComparisons() {
    String proofs = IntStream.range(0, SourceProofFixture.CAPACITY)
        .mapToObj(i -> "theorem " + "p".repeat(253) + "%03d".formatted(i)
            + " proves steps(beta, 8);\n")
        .collect(java.util.stream.Collectors.joining());
    String input = source(proofs);
    check(program, input, true, SourceProofFixture.oracle(input), false);
    check(program, source(proofs + "theorem excess proves inverse(beta);"), false, List.of(), false);
  }

  @ParameterizedTest
  @ValueSource(strings = {"9223372036854775807 + 1", "-9223372036854775808 - 1",
      "9223372036854775807 * 2"})
  void preservesCallerStorageAndReplaysCheckedArithmeticTraps(String expression) {
    SourceProofFixture.rejectTrapAndReplay(SourceProofFixture.machine(program,
        source("theorem good proves inverse(beta); theorem bad proves steps(alpha, " + expression + ");")));
  }

  private static void check(String source, boolean valid, List<SourceProofFixture.Claim> claims) {
    check(program, source, valid, claims, true);
  }

  private static void check(Program driver, String source, boolean valid,
      List<SourceProofFixture.Claim> claims, boolean history) {
    var machine = SourceProofFixture.machine(driver, source);
    MachineSnapshot initial = machine.snapshot();
    MachineSnapshot prepared;
    if (history) {
      prepared = SourceProofFixture.prepare(machine);
      SourceProofFixture.publish(machine);
    } else {
      while (machine.global("prepared") == 0) {
        machine.stepWithoutRewindHistory();
      }
      prepared = machine.snapshot();
      while (machine.global("published") == 0) {
        machine.stepWithoutRewindHistory();
      }
    }
    SourceProofFixture.check(prepared, machine, valid, claims);
    if (history) {
      SourceProofFixture.replay(machine, initial);
    } else {
      com.typeobject.wheeler.examples.CompilerMachineRunner.runWithoutRewindHistory(machine);
    }
  }
}
