package com.typeobject.wheeler.compiler;

import static org.junit.jupiter.api.Assertions.assertEquals;

import java.util.Map;
import org.junit.jupiter.api.Test;

/** Module-link evidence for dependency-owned generated-inverse proofs. */
final class SourceModuleProofTest {
  @Test
  void qualifiesAndRetainsDependencyProofs() {
    String left = """
        module fixture.left;

        classical class Left {
          public rev long identity(long value) {
            return value;
          }

          theorem identityInverse proves inverse(identity);
        }
        """;
    String right = left
        .replace("fixture.left", "fixture.right")
        .replace("class Left", "class Right");
    String root = """
        module fixture.root;

        import fixture.left;
        import fixture.right;

        classical class Root {}
        """;

    var program = new WheelerCompiler().compileLibraryModuleFiles(
        Map.of("Left.w", left, "Right.w", right, "Root.w", root),
        "fixture.root");

    assertEquals(2, program.proofCertificates().size());
    assertEquals(
        "fixture.left::identityInverse",
        program.proofCertificates().get(0).name());
    assertEquals(
        "fixture.left::identity",
        program.function(program.proofCertificates().get(0).subjectId()).name());
    assertEquals(
        "fixture.right::identityInverse",
        program.proofCertificates().get(1).name());
    assertEquals(
        "fixture.right::identity",
        program.function(program.proofCertificates().get(1).subjectId()).name());
  }
}
