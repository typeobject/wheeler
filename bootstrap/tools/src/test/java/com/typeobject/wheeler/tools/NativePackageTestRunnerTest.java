package com.typeobject.wheeler.tools;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.core.vm.VmTrap;
import com.typeobject.wheeler.packageformat.PackageArchive;
import com.typeobject.wheeler.packageformat.PackageManifestParser;
import com.typeobject.wheeler.runtime.WheelerRuntime;
import java.io.ByteArrayOutputStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.MessageDigest;
import java.util.HexFormat;
import java.util.Map;
import java.util.Set;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

/** Proves package-command invocation of the native fixed test profile. */
class NativePackageTestRunnerTest {
  @TempDir Path temporary;

  @Test
  void boundsNativeDependencyOwnerMembers() {
    StringBuilder source = new StringBuilder("""
        module demo.members;
        classical class Members {
        """);
    for (int index = 0; index < 23; index++) {
      source.append("  public long member").append(index).append("() { return ")
          .append(index).append("; }\n");
    }
    source.append("}\n");

    assertTrue(NativePackageTestRunner.fixedSourceProfile(source.toString()));
    source.insert(source.length() - 2, "  public long excess() { return 23; }\n");
    assertFalse(NativePackageTestRunner.fixedSourceProfile(source.toString()));

    StringBuilder constants = nativeConstantOwner(256);
    assertTrue(NativePackageTestRunner.fixedSourceProfile(constants.toString()));
    constants.insert(
        constants.length() - 2, "  public const long VALUE_256 = 256;\n");
    assertFalse(NativePackageTestRunner.fixedSourceProfile(constants.toString()));
  }

  @Test
  void enforcesNativeManifestByteLimit() throws Exception {
    Path admittedRoot = temporary.resolve("native-large-manifest-tests");
    PackageProject admitted = largeManifestProject(admittedRoot, 15, 1268);
    long admittedLength = Files.size(admittedRoot.resolve("wheeler.package.yaml"));
    assertEquals(28672, admittedLength);
    var result = NativePackageTestRunner.run(
        admittedRoot, admitted.manifest(), 0, 1, Set.of());
    assertTrue(result.isPresent());
    assertEquals(1, result.orElseThrow().selected());
    assertEquals(1, result.orElseThrow().passed());

    Path rejectedRoot = temporary.resolve("native-oversized-manifest-tests");
    PackageProject rejected = largeManifestProject(rejectedRoot, 15, 1269);
    assertEquals(28673, Files.size(rejectedRoot.resolve("wheeler.package.yaml")));
    assertThrows(
        VmTrap.class,
        () -> NativePackageTestRunner.run(
            rejectedRoot, rejected.manifest(), 0, 1, Set.of()));
  }

  @Test
  void reducesPackageTargetsIndependentOfArrivalOrder() throws Exception {
    var reducer = PackageProject.load(Path.of("wheeler-conformance"))
        .compileRunnable("nativetestpackagereportidentity");
    byte[] first = packageRows(1, 2);
    byte[] second = packageRows(2, 1);
    byte[] firstOutput = new WheelerRuntime().executeBinaryInput(reducer, first, 38).output();
    byte[] secondOutput = new WheelerRuntime().executeBinaryInput(reducer, second, 38).output();

    assertArrayEquals(firstOutput, secondOutput);
    assertEquals(3, unsigned16(firstOutput, 32));
    assertEquals(2, unsigned16(firstOutput, 34));
    assertEquals(1, unsigned16(firstOutput, 36));
    assertThrows(VmTrap.class, () -> new WheelerRuntime().executeBinaryInput(
        reducer, packageRows(1, 1), 38));
  }

  @Test
  void invokesEveryNativePackageTestTarget() throws Exception {
    Path project = temporary.resolve("native-target-tests");
    Files.createDirectories(project.resolve("src"));
    Files.writeString(project.resolve("wheeler.package.yaml"), """
        schema: 1
        package:
          name: "demo.native.targets"
          version: "1.0.0"
          profile: "bootstrap-1"
        targets:
          - kind: "tool"
            name: "alpha"
            root: "src/Alpha.w"
            module: "demo.native.targets.alpha"
            sources:
              - "src/Alpha.w"
            test: true
          - kind: "tool"
            name: "beta"
            root: "src/Beta.w"
            module: "demo.native.targets.beta"
            sources:
              - "src/Beta.w"
            test: true
        dependencies: []
        capabilities: []
        """);
    Files.writeString(project.resolve("src/Alpha.w"), """
        module demo.native.targets.alpha;
        classical class AlphaTests {
          test void passes() tags(fast) { assert(true); }
        }
        """);
    Files.writeString(project.resolve("src/Beta.w"), """
        module demo.native.targets.beta;
        classical class BetaTests {
          test void passes() tags(slow) { assert(true); }
        }
        """);
    PackageProject packageProject = PackageProject.load(project);

    var result = NativePackageTestRunner.run(
        project, packageProject.manifest(), 0, 1, Set.of());
    TestReport report = packageProject.test();
    var fastResult = NativePackageTestRunner.run(
        project, packageProject.manifest(), 0, 1, Set.of("fast"));
    TestReport fastReport = packageProject.test(0, 1, Set.of("fast"));
    assertThrows(
        com.typeobject.wheeler.packageformat.PackageFormatException.class,
        () -> NativePackageTestRunner.run(
            project, packageProject.manifest(), 0, 1, Set.of("missing")));
    assertThrows(
        com.typeobject.wheeler.packageformat.PackageFormatException.class,
        () -> packageProject.test(0, 1, Set.of("missing")));

    assertTrue(result.isPresent());
    assertEquals(2, result.orElseThrow().identities().size());
    assertEquals(64, result.orElseThrow().packageIdentity().length());
    assertEquals(2, result.orElseThrow().selected());
    assertEquals(2, result.orElseThrow().passed());
    assertEquals(0, result.orElseThrow().failed());
    assertEquals(2, report.passed());
    assertEquals(result.orElseThrow().report().cases(), report.cases());
    assertEquals(result.orElseThrow().report().identity(), report.identity());
    assertTrue(fastResult.isPresent());
    assertEquals(1, fastResult.orElseThrow().selected());
    assertEquals(1, fastResult.orElseThrow().passed());
    assertEquals(1, fastReport.passed());
  }

  @Test
  void rendersAnEmptyNativeSelection() throws Exception {
    Path project = temporary.resolve("native-empty-render");
    Files.createDirectories(project.resolve("src"));
    Files.writeString(project.resolve("wheeler.package.yaml"), """
        schema: 1
        package:
          name: "demo.native.empty"
          version: "1.0.0"
          profile: "bootstrap-1"
        targets:
          - kind: "tool"
            name: "laws"
            root: "src/Main.w"
            module: "demo.native.empty.tests"
            sources:
              - "src/Main.w"
            test: true
        dependencies: []
        capabilities: []
        """);
    Files.writeString(project.resolve("src/Main.w"), """
        module demo.native.empty.tests;
        classical class NativeEmptyTests {
          test void fastCase() tags(fast) { assert(true); }
          test void slowCase() tags(slow) { assert(true); }
        }
        """);
    PackageProject packageProject = PackageProject.load(project);

    var result = NativePackageTestRunner.run(
        project, packageProject.manifest(), 0, 1, Set.of("fast", "slow"));

    assertTrue(result.isPresent());
    assertEquals(0, result.orElseThrow().selected());
    assertEquals(
        TestReportRenderer.render(
            result.orElseThrow().report(),
            packageProject.manifest().name(),
            TestReportRenderer.Format.JSON),
        new String(result.orElseThrow().json(), StandardCharsets.UTF_8));
    assertEquals(
        TestReportRenderer.render(
            result.orElseThrow().report(),
            packageProject.manifest().name(),
            TestReportRenderer.Format.TERMINAL),
        new String(result.orElseThrow().terminal(), StandardCharsets.UTF_8));
    assertEquals(
        TestReportRenderer.render(
            result.orElseThrow().report(),
            packageProject.manifest().name(),
            TestReportRenderer.Format.JUNIT_XML),
        new String(result.orElseThrow().junit(), StandardCharsets.UTF_8));
  }

  @Test
  void publishesTargetRowsInCaseIdentityOrder() throws Exception {
    Path project = temporary.resolve("native-row-order");
    Files.createDirectories(project.resolve("src"));
    Files.writeString(project.resolve("wheeler.package.yaml"), """
        schema: 1
        package:
          name: "demo.native.order"
          version: "1.0.0"
          profile: "bootstrap-1"
        targets:
          - kind: "tool"
            name: "laws"
            root: "src/Main.w"
            module: "demo.native.order.tests"
            sources:
              - "src/Main.w"
            test: true
        dependencies: []
        capabilities: []
        """);
    Files.writeString(project.resolve("src/Main.w"), """
        module demo.native.order.tests;
        classical class NativeOrderTests {
          test void alpha() { assert(true); }
          test void beta() { assert(true); }
        }
        """);

    TestReport report = PackageProject.load(project).test();

    assertEquals(2, report.selected());
    assertTrue(report.cases().get(0).caseIdentity()
        .compareTo(report.cases().get(1).caseIdentity()) < 0);
  }

  @Test
  void publishesCompleteNativeFailureRows() throws Exception {
    Path project = temporary.resolve("native-failure-rows");
    Files.createDirectories(project.resolve("src"));
    Files.writeString(project.resolve("wheeler.package.yaml"), """
        schema: 1
        package:
          name: "demo.native.failure"
          version: "1.0.0"
          profile: "bootstrap-1"
        targets:
          - kind: "tool"
            name: "laws"
            root: "src/Main.w"
            module: "demo.native.failure.tests"
            sources:
              - "src/Main.w"
            test: true
        dependencies: []
        capabilities: []
        """);
    Files.writeString(project.resolve("src/Main.w"), """
        module demo.native.failure.tests;
        classical class NativeFailureTests {
          test void fails() { assert(false); }
        }
        """);
    PackageProject packageProject = PackageProject.load(project);

    PackageProject.TestOutput result = packageProject.testOutput(0, 1, Set.of());
    TestReport report = result.report();

    assertEquals(
        TestReportRenderer.render(
            report, packageProject.manifest().name(), TestReportRenderer.Format.JSON),
        new String(result.nativeJson(), StandardCharsets.UTF_8));
    assertEquals(
        TestReportRenderer.render(
            report, packageProject.manifest().name(), TestReportRenderer.Format.TERMINAL),
        new String(result.nativeTerminal(), StandardCharsets.UTF_8));
    assertEquals(
        TestReportRenderer.render(
            report, packageProject.manifest().name(), TestReportRenderer.Format.JUNIT_XML),
        new String(result.nativeJunit(), StandardCharsets.UTF_8));
    assertEquals(1, report.selected());
    assertEquals(0, report.passed());
    assertEquals(1, report.failed());
    assertEquals("WTEST003", report.cases().getFirst().diagnosticCode());
    assertEquals(1, report.cases().getFirst().assertions());
    assertEquals(64, report.identity().length());
  }

  @Test
  void invokesNativeTestsWithAnUnusedLockedDependency() throws Exception {
    Path project = temporary.resolve("native-dependency-tests");
    Files.createDirectories(project.resolve("src"));
    String manifest = """
        schema: 1
        package:
          name: "demo.native.dependency"
          version: "1.0.0"
          profile: "bootstrap-1"
        targets:
          - kind: "tool"
            name: "laws"
            root: "src/Main.w"
            module: "demo.native.dependency.tests"
            sources:
              - "src/Main.w"
            test: true
        dependencies:
          - kind: "normal"
            name: "demo.dep"
            version: "^1.0.0"
        capabilities: []
        """;
    Files.writeString(project.resolve("wheeler.package.yaml"), manifest);
    Files.writeString(project.resolve("src/Main.w"), """
        module demo.native.dependency.tests;
        classical class NativeDependencyTests {
          test void passes() { assert(true); }
        }
        """);
    String root = HexFormat.of().formatHex(
        MessageDigest.getInstance("SHA-256").digest(manifest.getBytes(StandardCharsets.UTF_8)));
    String digest = "0".repeat(64);
    Files.writeString(project.resolve("wheeler.package.lock.yaml"), ("""
        schema: 3
        root: "%s"
        packages:
          - name: "demo.dep"
            version: "1.0.0"
            repository: "%s"
            snapshot: "%s"
            archive: "%s"
            manifest: "%s"
            dependencies: []
        """).formatted(root, digest, digest, digest, digest));
    PackageProject packageProject = PackageProject.load(project);

    var result = NativePackageTestRunner.run(
        project, packageProject.manifest(), 0, 1, Set.of());

    assertTrue(result.isPresent());
    assertEquals(1, result.orElseThrow().selected());
    assertEquals(1, result.orElseThrow().passed());
    assertEquals(0, result.orElseThrow().failed());
  }

  @Test
  void invokesOneLockedExternalImportNatively() throws Exception {
    Path project = temporary.resolve("native-external-import-tests");
    Files.createDirectories(project.resolve("src"));
    String manifestText = """
        schema: 1
        package:
          name: "demo.native.external"
          version: "1.0.0"
          profile: "bootstrap-1"
        targets:
          - kind: "tool"
            name: "laws"
            root: "src/Main.w"
            module: "demo.native.external.tests"
            sources:
              - "src/Main.w"
            test: true
        dependencies:
          - kind: "normal"
            name: "demo.dep"
            version: "=1.0.0"
        capabilities: []
        """;
    Files.writeString(project.resolve("wheeler.package.yaml"), manifestText);
    Files.writeString(project.resolve("src/Main.w"), """
        module demo.native.external.tests;
        import demo.dep.constants;
        classical class NativeExternalImportTests {
          test void readsLockedConstant() {
            long answer = ANSWER;
            assert(answer == 42);
          }
        }
        """);
    String dependencyManifestText = """
        schema: 1
        package:
          name: "demo.dep"
          version: "1.0.0"
          profile: "bootstrap-1"
        targets:
          - kind: "library"
            name: "library"
            root: "src/Constants.w"
            module: "demo.dep.constants"
            sources:
              - "src/Constants.w"
            test: false
        dependencies: []
        capabilities: []
        """;
    var dependencyManifest = new PackageManifestParser().parse(dependencyManifestText);
    PackageArchive codec = new PackageArchive();
    byte[] archive = codec.encode(dependencyManifest, Map.of(
        "src/Constants.w",
        """
        module demo.dep.constants;
        classical class Constants {
          public const long ANSWER = 42;
        }
        """.getBytes(StandardCharsets.UTF_8)));
    String archiveIdentity = codec.identity(archive);
    String rootIdentity = new PackageManifestParser().parse(manifestText).identity();
    String lock = ("""
        schema: 3
        root: "%s"
        packages:
          - name: "demo.dep"
            version: "1.0.0"
            repository: "%s"
            snapshot: "%s"
            archive: "%s"
            manifest: "%s"
            dependencies: []
        """).formatted(
            rootIdentity,
            "1".repeat(64),
            "2".repeat(64),
            archiveIdentity,
            dependencyManifest.identity());
    Files.writeString(project.resolve("wheeler.package.lock.yaml"), lock);
    Path vendor = project.resolve("vendor");
    Files.createDirectory(vendor);
    Files.writeString(vendor.resolve("wheeler.package.lock.yaml"), lock);
    Files.write(
        vendor.resolve("demo.dep-1.0.0-" + archiveIdentity + ".wpk"),
        archive);
    PackageProject packageProject = PackageProject.load(project);
    var selected = LockedPackageSet.load(project, packageProject.manifest())
        .fixedNativeArchives(Set.of("demo.dep.constants"));
    assertEquals(1, selected.size());

    var result = NativePackageTestRunner.run(
        project, packageProject.manifest(), 0, 1, Set.of());

    assertTrue(result.isPresent());
    assertEquals(1, result.orElseThrow().selected());
    assertEquals(1, result.orElseThrow().passed());
    assertEquals(0, result.orElseThrow().failed());
    assertEquals(1, result.orElseThrow().report().cases().getFirst().assertions());
  }

  @Test
  void invokesTwoLockedExternalImportsNatively() throws Exception {
    Path project = temporary.resolve("native-two-external-import-tests");
    Files.createDirectories(project.resolve("src"));
    String manifestText = """
        schema: 1
        package:
          name: "demo.native.external.two"
          version: "1.0.0"
          profile: "bootstrap-1"
        targets:
          - kind: "tool"
            name: "laws"
            root: "src/Main.w"
            module: "demo.native.external.two.tests"
            sources:
              - "src/Main.w"
            test: true
        dependencies:
          - kind: "normal"
            name: "demo.dep"
            version: "=1.0.0"
        capabilities: []
        """;
    Files.writeString(project.resolve("wheeler.package.yaml"), manifestText);
    Files.writeString(project.resolve("src/Main.w"), """
        module demo.native.external.two.tests;
        import demo.dep.a;
        import demo.dep.b;
        classical class NativeExternalImportTests {
          test void readsLockedConstants() {
            long answerA = ANSWER_A;
            assert(answerA == 41);
            long answerB = ANSWER_B;
            assert(answerB == 42);
          }
        }
        """);
    String dependencyManifestText = """
        schema: 1
        package:
          name: "demo.dep"
          version: "1.0.0"
          profile: "bootstrap-1"
        targets:
          - kind: "library"
            name: "library"
            root: "src/A.w"
            module: "demo.dep.a"
            sources:
              - "src/A.w"
              - "src/B.w"
            test: false
        dependencies: []
        capabilities: []
        """;
    var dependencyManifest = new PackageManifestParser().parse(dependencyManifestText);
    PackageArchive codec = new PackageArchive();
    byte[] archive = codec.encode(dependencyManifest, Map.of(
        "src/A.w", """
        module demo.dep.a;
        import demo.dep.b;
        classical class ConstantsA {
          public const long ANSWER_A = 41;
        }
        """.getBytes(StandardCharsets.UTF_8),
        "src/B.w", """
        module demo.dep.b;
        classical class ConstantsB {
          public const long ANSWER_B = 42;
        }
        """.getBytes(StandardCharsets.UTF_8)));
    String archiveIdentity = codec.identity(archive);
    String lock = ("""
        schema: 3
        root: "%s"
        packages:
          - name: "demo.dep"
            version: "1.0.0"
            repository: "%s"
            snapshot: "%s"
            archive: "%s"
            manifest: "%s"
            dependencies: []
        """).formatted(
            new PackageManifestParser().parse(manifestText).identity(),
            "1".repeat(64),
            "2".repeat(64),
            archiveIdentity,
            dependencyManifest.identity());
    Files.writeString(project.resolve("wheeler.package.lock.yaml"), lock);
    Path vendor = project.resolve("vendor");
    Files.createDirectory(vendor);
    Files.writeString(vendor.resolve("wheeler.package.lock.yaml"), lock);
    Files.write(vendor.resolve("demo.dep-1.0.0-" + archiveIdentity + ".wpk"), archive);
    PackageProject packageProject = PackageProject.load(project);
    var selected = LockedPackageSet.load(project, packageProject.manifest())
        .fixedNativeArchives(Set.of("demo.dep.a", "demo.dep.b"));
    assertEquals(1, selected.size());

    var result = NativePackageTestRunner.run(
        project, packageProject.manifest(), 0, 1, Set.of());

    assertTrue(result.isPresent());
    assertEquals(1, result.orElseThrow().selected());
    assertEquals(1, result.orElseThrow().passed());
    assertEquals(0, result.orElseThrow().failed());
    assertEquals(2, result.orElseThrow().report().cases().getFirst().assertions());
  }

  @Test
  void fillsNativeExternalSourcePlan() throws Exception {
    var fixture = NativeFullExternalFixture.create(
        temporary.resolve("native-full-external-import-tests"));
    var locked = LockedPackageSet.load(fixture.root(), fixture.project().manifest());
    var selected = locked.fixedNativeArchives(fixture.modules());
    assertEquals(2, selected.size());
    assertEquals(7, selected.stream().mapToInt(archive -> archive.entries().size()).sum());
    Set<String> overCapacity = new java.util.TreeSet<>(fixture.modules());
    overCapacity.add("demo.b.m3");
    assertTrue(locked.fixedNativeArchives(overCapacity).isEmpty());

    var result = NativePackageTestRunner.run(
        fixture.root(), fixture.project().manifest(), 0, 1, Set.of());

    assertTrue(result.isPresent());
    assertEquals(1, result.orElseThrow().selected());
    assertEquals(1, result.orElseThrow().passed());
    assertEquals(0, result.orElseThrow().failed());
    assertEquals(7, result.orElseThrow().report().cases().getFirst().assertions());
  }

  @Test
  void fillsNativeTransitiveSourcePlan() throws Exception {
    var fixture = NativeFullExternalFixture.createTransitive(
        temporary.resolve("native-full-transitive-import-tests"));
    var locked = LockedPackageSet.load(fixture.root(), fixture.project().manifest());
    var selected = locked.fixedNativeArchives(fixture.modules());
    assertEquals(2, selected.size());
    assertEquals(7, selected.stream().mapToInt(archive -> archive.entries().size()).sum());
    assertTrue(locked.fixedNativeArchives(Set.of("demo.b.m0")).isEmpty());

    var result = NativePackageTestRunner.run(
        fixture.root(), fixture.project().manifest(), 0, 1, Set.of());

    assertTrue(result.isPresent());
    assertEquals(1, result.orElseThrow().selected());
    assertEquals(1, result.orElseThrow().passed());
    assertEquals(0, result.orElseThrow().failed());
    assertEquals(4, result.orElseThrow().report().cases().getFirst().assertions());
  }

  @Test
  void invokesFourLockedExternalImportsNatively() throws Exception {
    var fixture = NativeMultiEntryExternalFixture.create(
        temporary.resolve("native-four-external-import-tests"));
    var selected = LockedPackageSet.load(fixture.root(), fixture.project().manifest())
        .fixedNativeArchives(fixture.modules());
    assertEquals(1, selected.size());
    assertEquals(4, selected.getFirst().entries().size());

    var result = NativePackageTestRunner.run(
        fixture.root(), fixture.project().manifest(), 0, 1, Set.of());

    assertTrue(result.isPresent());
    assertEquals(1, result.orElseThrow().selected());
    assertEquals(1, result.orElseThrow().passed());
    assertEquals(0, result.orElseThrow().failed());
    assertEquals(4, result.orElseThrow().report().cases().getFirst().assertions());
  }

  @Test
  void invokesTwoLockedExternalPackagesNatively() throws Exception {
    var fixture = NativeTwoPackageExternalFixture.create(
        temporary.resolve("native-two-external-package-tests"));
    var selected = LockedPackageSet.load(fixture.root(), fixture.project().manifest())
        .fixedNativeArchives(fixture.modules());
    assertEquals(2, selected.size());

    var result = NativePackageTestRunner.run(
        fixture.root(), fixture.project().manifest(), 0, 1, Set.of());

    assertTrue(result.isPresent());
    assertEquals(1, result.orElseThrow().selected());
    assertEquals(1, result.orElseThrow().passed());
    assertEquals(0, result.orElseThrow().failed());
    assertEquals(2, result.orElseThrow().report().cases().getFirst().assertions());
  }

  @Test
  void invokesOneTransitiveLockedImportNatively() throws Exception {
    var fixture = NativeTwoPackageExternalFixture.createTransitive(
        temporary.resolve("native-transitive-external-package-tests"));
    var locked = LockedPackageSet.load(fixture.root(), fixture.project().manifest());
    var selected = locked.fixedNativeArchives(fixture.modules());
    assertEquals(2, selected.size());
    assertTrue(locked.fixedNativeArchives(Set.of("demo.b.constants")).isEmpty());

    var result = NativePackageTestRunner.run(
        fixture.root(), fixture.project().manifest(), 0, 1, Set.of());

    assertTrue(result.isPresent());
    assertEquals(1, result.orElseThrow().selected());
    assertEquals(1, result.orElseThrow().passed());
    assertEquals(0, result.orElseThrow().failed());
    assertEquals(1, result.orElseThrow().report().cases().getFirst().assertions());
  }

  @Test
  void invokesNativeDiscoveryAcrossCanonicalLocalImports() throws Exception {
    Path project = temporary.resolve("native-import-tests");
    Files.createDirectories(project.resolve("src"));
    Files.writeString(project.resolve("wheeler.package.yaml"), """
        schema: 1
        package:
          name: "demo.native.imports"
          version: "1.0.0"
          profile: "bootstrap-1"
        targets:
          - kind: "tool"
            name: "laws"
            root: "src/Main.w"
            module: "demo.native.imports.tests"
            sources:
              - "src/Helper.w"
              - "src/Main.w"
            test: true
        dependencies: []
        capabilities: []
        """);
    Files.writeString(project.resolve("src/Helper.w"), nativeConstantOwner(256));
    Files.writeString(project.resolve("src/Main.w"), """
        module demo.native.imports.tests;
        import demo.native.imports.helper;
        classical class NativeImportTests {
          test void passes() {
            long value = VALUE_255;
            assert(value == 255);
          }
        }
        """);
    PackageProject packageProject = PackageProject.load(project);

    var result = NativePackageTestRunner.run(
        project, packageProject.manifest(), 0, 1, Set.of());
    TestReport report = packageProject.test();

    assertTrue(result.isPresent());
    assertEquals(1, result.orElseThrow().selected());
    assertEquals(1, result.orElseThrow().passed());
    assertEquals(0, result.orElseThrow().failed());
    assertEquals(1, report.passed());
  }

  private static StringBuilder nativeConstantOwner(int count) {
    StringBuilder source = new StringBuilder("""
        module demo.native.imports.helper;
        classical class Helper {
        """);
    for (int index = 0; index < count; index++) {
      source.append("  public const long VALUE_")
          .append(index)
          .append(" = ")
          .append(index)
          .append(";\n");
    }
    return source.append("}\n");
  }

  private static byte[] packageRows(int firstIdentity, int secondIdentity) {
    ByteArrayOutputStream rows = new ByteArrayOutputStream();
    rows.write(2);
    writeTargetRow(rows, firstIdentity, firstIdentity);
    writeTargetRow(rows, secondIdentity, secondIdentity);
    return rows.toByteArray();
  }

  private static void writeTargetRow(
      ByteArrayOutputStream rows, int identity, int selected) {
    rows.writeBytes(new byte[31]);
    rows.write(identity);
    rows.write(selected);
    rows.write(0);
    rows.write(1);
    rows.write(0);
    rows.write(selected - 1);
    rows.write(0);
  }

  private static int unsigned16(byte[] input, int offset) {
    return Byte.toUnsignedInt(input[offset]) + Byte.toUnsignedInt(input[offset + 1]) * 256;
  }

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
    assertEquals(1, result.orElseThrow().identities().size());
    assertEquals(64, result.orElseThrow().identities().getFirst().length());
    assertEquals(64, result.orElseThrow().packageIdentity().length());
    assertEquals(1, report.selected());
    assertEquals(1, report.passed());
  }

  private static PackageProject largeManifestProject(
      Path root, int capabilityCount, int lastPathLength) throws Exception {
    Files.createDirectories(root.resolve("src"));
    StringBuilder capabilities = new StringBuilder();
    for (int index = 0; index < capabilityCount; index++) {
      capabilities.append("  - name: \"build.%c\"\n    path: \"%c/%s\"\n".formatted(
          'a' + index,
          'a' + index,
          "x".repeat(index + 1 == capabilityCount ? lastPathLength : 1900)));
    }
    String manifest = """
        schema: 1
        package:
          name: "demo.large.manifest"
          version: "1.0.0"
          profile: "bootstrap-1"
        targets:
          - kind: "tool"
            name: "laws"
            root: "src/Main.w"
            module: "demo.large.manifest.tests"
            sources:
              - "src/Main.w"
            test: true
        dependencies: []
        capabilities:
        """ + capabilities;
    Files.writeString(root.resolve("wheeler.package.yaml"), manifest);
    Files.writeString(root.resolve("src/Main.w"), """
        module demo.large.manifest.tests;
        classical class LargeManifestTests {
          test void passes() {
            assert(true);
          }
        }
        """);
    return PackageProject.load(root);
  }
}
