package com.typeobject.wheeler.tools;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Set;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

/** Proves package-command invocation of the native fixed test profile. */
class NativePackageTestRunnerTest {
  @TempDir Path temporary;

  @Test
  void invokesNativeDiscoveryWithoutCaseNamesOrArtifacts() throws Exception {
    Path project = temporary.resolve("native-tests");
    Files.createDirectories(project.resolve("src"));
    Files.writeString(project.resolve("wheeler.package.yaml"), """
        schema: 1
        package:
          name: "demo.native"
          version: "1.0.0"
          profile: "bootstrap-1"
        targets:
          - kind: "tool"
            name: "laws"
            root: "src/Main.w"
            module: "demo.native.tests"
            sources:
              - "src/Main.w"
            test: true
        dependencies: []
        capabilities: []
        """);
    Files.writeString(project.resolve("src/Main.w"), """
        module demo.native.tests;
        classical class NativeTests {
          test void passes() tags(fast) limits(steps = 512, history = 512) {
            assert(true);
          }
        }
        """);
    PackageProject packageProject = PackageProject.load(project);

    var result = NativePackageTestRunner.run(
        project, packageProject.manifest(), 0, 1, Set.of("fast"));
    TestReport report = packageProject.test(0, 1, Set.of("fast"));

    assertTrue(result.isPresent());
    assertEquals(1, result.orElseThrow().selected());
    assertEquals(1, result.orElseThrow().passed());
    assertEquals(0, result.orElseThrow().failed());
    assertEquals(64, result.orElseThrow().identity().length());
    assertEquals(1, report.selected());
    assertEquals(1, report.passed());
  }
}
