package com.typeobject.wheeler.tools;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.packageformat.PackageArchive;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

/** Conformance tests for bounded recursive Wheeler source-directory selectors. */
class PackageSourceDirectoryTest {
  @TempDir
  Path temporary;

  @Test
  void directorySelectorFindsOnlyPhysicalWheelerSourcesInLogicalOrder() throws Exception {
    Path project = temporary.resolve("demo");
    Files.createDirectories(project.resolve("src/support"));
    Files.writeString(project.resolve("wheeler.package.yaml"), """
        schema: 1
        package:
          name: "demo.directory"
          version: "1.0.0"
          profile: "bootstrap-1"
        targets:
          - kind: "library"
            name: "library"
            root: "src/Library.w"
            module: "demo.library"
            sources:
              - "src"
            test: false
        dependencies: []
        capabilities: []
        """);
    Files.writeString(project.resolve("src/Library.w"), """
        module demo.library;
        import demo.support;
        classical class Library {
          public long answer() { return helper(); }
        }
        """);
    Files.writeString(project.resolve("src/support/Helper.w"), """
        module demo.support;
        classical class Helper {
          public long helper() { return 42; }
        }
        """);
    Files.writeString(project.resolve("src/notes.txt"), "not a Wheeler source\n");
    PackageProject packageProject = PackageProject.load(project);

    packageProject.check();
    PackageArchive.DecodedPackage archive = new PackageArchive().decode(
        packageProject.archive());

    assertEquals(List.of("src/Library.w", "src/support/Helper.w"),
        archive.entries().keySet().stream().toList());
  }

  @Test
  void directorySelectorRejectsSymlinksBeforeReadingTheirTargets() throws Exception {
    Path project = temporary.resolve("linked");
    Files.createDirectories(project.resolve("src"));
    Files.writeString(project.resolve("wheeler.package.yaml"), """
        schema: 1
        package:
          name: "demo.linked"
          version: "1.0.0"
          profile: "bootstrap-1"
        targets:
          - kind: "library"
            name: "library"
            root: "src/Library.w"
            module: "demo.library"
            sources:
              - "src"
            test: false
        dependencies: []
        capabilities: []
        """);
    Files.writeString(project.resolve("src/Library.w"), """
        module demo.library;
        classical class Library {}
        """);
    Path outside = temporary.resolve("Outside.w");
    Files.writeString(outside, "module demo.outside; classical class Outside {}\n");
    Files.createSymbolicLink(project.resolve("src/Outside.w"), outside);
    PackageProject packageProject = PackageProject.load(project);

    assertThrows(IOException.class, packageProject::archive);
  }
}
