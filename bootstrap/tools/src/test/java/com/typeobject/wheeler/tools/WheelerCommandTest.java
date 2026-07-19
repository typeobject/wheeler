package com.typeobject.wheeler.tools;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeReader;
import com.typeobject.wheeler.core.vm.VmTrap;
import com.typeobject.wheeler.packageformat.BuildPlan;
import com.typeobject.wheeler.packageformat.BuildPlanCodec;
import com.typeobject.wheeler.packageformat.PackageArchive;
import com.typeobject.wheeler.packageformat.PackageArchive.DecodedPackage;
import com.typeobject.wheeler.packageformat.PackageFormatException;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.PrintStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.attribute.FileTime;
import java.nio.file.attribute.PosixFilePermission;
import java.util.List;
import java.util.Set;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

/** Conformance tests for the unified stage-0 command and its physical host boundaries. */
class WheelerCommandTest {
  @TempDir
  Path temporary;

  @Test
  void unifiedCommandChecksBuildsRunsPackagesAndVerifies() throws Exception {
    Path project = temporary.resolve("demo");
    Files.createDirectories(project.resolve("src"));
    Files.writeString(project.resolve("wheeler.package.yaml"), """
        schema: 1
        package:
          name: "demo.counter"
          version: "1.0.0"
          profile: "bootstrap-1"
        targets:
          - kind: "deployable"
            name: "counter"
            root: "src/Counter.w"
            test: false
        dependencies: []
        capabilities:
          - name: "build.read"
            path: "src/**"
          - name: "build.write"
            path: "build/**"
        """);
    Files.writeString(project.resolve("src/Counter.w"), """
        classical class Counter {
            state long count = 0;
            rev void increment() { count += 1; }
            entry void main() { increment(); assert(count == 1); }
        }
        """);
    ByteArrayOutputStream stdoutBytes = new ByteArrayOutputStream();
    ByteArrayOutputStream stderrBytes = new ByteArrayOutputStream();
    PrintStream stdout = new PrintStream(stdoutBytes, true, StandardCharsets.UTF_8);
    PrintStream stderr = new PrintStream(stderrBytes, true, StandardCharsets.UTF_8);

    assertEquals(0, Wheeler.execute(new String[] {"check", project.toString()}, stdout, stderr));
    assertEquals(0, Wheeler.execute(new String[] {"build", project.toString()}, stdout, stderr));
    Path artifact = project.resolve("build/counter.wbc");
    assertTrue(Files.isRegularFile(artifact));
    new BytecodeReader().read(Files.readAllBytes(artifact));

    assertEquals(0, Wheeler.execute(new String[] {"run", artifact.toString()}, stdout, stderr));
    assertEquals(0, Wheeler.execute(
        new String[] {"run", project.toString(), "--target", "counter"}, stdout, stderr));
    Path archivePath = temporary.resolve("demo.wpk");
    assertEquals(0, Wheeler.execute(
        new String[] {"package", project.toString(), "-o", archivePath.toString()},
        stdout,
        stderr));
    DecodedPackage archive = new PackageArchive().decode(Files.readAllBytes(archivePath));
    assertEquals("demo.counter", archive.manifest().name());
    assertEquals(0, Wheeler.execute(new String[] {"verify", archivePath.toString()}, stdout, stderr));
    assertEquals(0, Wheeler.execute(
        new String[] {"package", project.toString()}, stdout, stderr));
    Path defaultArchive = project.resolve("build/demo.counter-1.0.0.wpk");
    assertArrayEquals(Files.readAllBytes(archivePath), Files.readAllBytes(defaultArchive));

    Path registry = temporary.resolve("registry");
    Files.createDirectory(registry);
    String[] publish = {
        "publish", archivePath.toString(), "--registry", registry.toString()
    };
    assertEquals(0, Wheeler.execute(publish, stdout, stderr));
    assertEquals(0, Wheeler.execute(publish, stdout, stderr));
    Path fetched = temporary.resolve("fetched.wpk");
    assertEquals(0, Wheeler.execute(
        new String[] {
            "fetch", "demo.counter", "1.0.0", "--registry", registry.toString(),
            "-o", fetched.toString()
        },
        stdout,
        stderr));
    assertArrayEquals(Files.readAllBytes(archivePath), Files.readAllBytes(fetched));

    Files.writeString(project.resolve("src/Counter.w"), """
        classical class Counter {
            state long count = 0;
            entry void main() { count += 2; }
        }
        """);
    Path conflicting = temporary.resolve("conflicting.wpk");
    assertEquals(0, Wheeler.execute(
        new String[] {"package", project.toString(), "-o", conflicting.toString()},
        stdout,
        stderr));
    assertThrows(
        com.typeobject.wheeler.packageformat.PackageFormatException.class,
        () -> Wheeler.execute(
            new String[] {"publish", conflicting.toString(), "--registry", registry.toString()},
            stdout,
            stderr));
    Files.write(
        registry.resolve("archives").resolve(archive.identity() + ".wpk"),
        new byte[] {1});
    assertThrows(
        com.typeobject.wheeler.packageformat.PackageFormatException.class,
        () -> Wheeler.execute(
            new String[] {
                "fetch", "demo.counter", "1.0.0", "--registry", registry.toString(),
                "-o", temporary.resolve("corrupt.wpk").toString()
            },
            stdout,
            stderr));

    assertEquals(0, Wheeler.execute(new String[] {"clean", project.toString()}, stdout, stderr));
    assertTrue(Files.notExists(project.resolve("build")));
    assertTrue(Files.isRegularFile(project.resolve("src/Counter.w")));

    String output = stdoutBytes.toString(StandardCharsets.UTF_8);
    assertTrue(output.contains("checked demo.counter 1.0.0"));
    assertTrue(output.contains("count = 1"));
    assertTrue(output.contains(archive.identity()));
    assertTrue(output.contains("cleaned demo.counter"));
    assertEquals("", stderrBytes.toString(StandardCharsets.UTF_8));
  }

  @Test
  void packageCommandsBuildRunAndArchiveExactModuleSourceSets() throws Exception {
    Path project = temporary.resolve("modules");
    Files.createDirectories(project.resolve("src"));
    Files.writeString(project.resolve("wheeler.package.yaml"), """
        schema: 1
        package:
          name: "demo.modules"
          version: "1.0.0"
          profile: "bootstrap-1"
        targets:
          - kind: "deployable"
            name: "main"
            root: "src/Main.w"
            module: "demo.main"
            sources:
              - "src/Arithmetic.w"
              - "src/Main.w"
            test: false
        dependencies: []
        capabilities: []
        """);
    Files.writeString(project.resolve("src/Arithmetic.w"), """
        module demo.arithmetic;
        classical class Arithmetic {
          public long twice(long value) { return value + value; }
        }
        """);
    Files.writeString(project.resolve("src/Main.w"), """
        module demo.main;
        import demo.arithmetic;
        classical class Main {
          state long result = 0;
          entry void main() { result = twice(9); assert(result == 18); }
        }
        """);
    ByteArrayOutputStream bytes = new ByteArrayOutputStream();
    PrintStream output = new PrintStream(bytes, true, StandardCharsets.UTF_8);

    assertEquals(0, Wheeler.execute(
        new String[] {"check", project.toString()}, output, output));
    assertEquals(0, Wheeler.execute(
        new String[] {"run", project.toString(), "--target", "main"}, output, output));
    assertEquals(0, Wheeler.execute(
        new String[] {"build", project.toString()}, output, output));
    new BytecodeReader().read(Files.readAllBytes(project.resolve("build/main.wbc")));
    Path archivePath = temporary.resolve("modules.wpk");
    assertEquals(0, Wheeler.execute(
        new String[] {"package", project.toString(), "-o", archivePath.toString()},
        output,
        output));
    DecodedPackage archive = new PackageArchive().decode(Files.readAllBytes(archivePath));
    assertEquals(
        List.of("src/Arithmetic.w", "src/Main.w"),
        archive.entries().keySet().stream().toList());
  }

  @Test
  void workspaceCheckAndBuildUseCanonicalMemberOrderAndIsolatedOutputs() throws Exception {
    Files.writeString(temporary.resolve("wheeler.workspace.yaml"), """
        schema: 1
        workspace:
          name: "demo"
          profile: "bootstrap-1"
        members:
          - name: "first"
            path: "first"
          - name: "second"
            path: "second"
        """);
    createPackage(temporary.resolve("first"), "demo.first", "First", 1);
    createPackage(temporary.resolve("second"), "demo.second", "Second", 2);
    Path output = temporary.resolve("artifacts");
    ByteArrayOutputStream stdout = new ByteArrayOutputStream();
    PrintStream sink = new PrintStream(new ByteArrayOutputStream());

    assertEquals(0, Wheeler.execute(
        new String[] {"check", temporary.toString()}, new PrintStream(stdout), sink));
    assertEquals(0, Wheeler.execute(
        new String[] {"build", temporary.toString(), "-o", output.toString()},
        new PrintStream(stdout),
        sink));

    assertTrue(Files.isRegularFile(output.resolve("first/main.wbc")));
    assertTrue(Files.isRegularFile(output.resolve("second/main.wbc")));
    assertEquals(0, Wheeler.execute(
        new String[] {"build", temporary.toString()}, new PrintStream(stdout), sink));
    assertTrue(Files.isRegularFile(temporary.resolve("build/first/main.wbc")));
    assertTrue(Files.isRegularFile(temporary.resolve("build/second/main.wbc")));
    assertEquals(0, Wheeler.execute(
        new String[] {"build", temporary.resolve("first").toString()},
        new PrintStream(stdout),
        sink));
    assertTrue(Files.isRegularFile(temporary.resolve("build/first/main.wbc")));
    assertEquals(0, Wheeler.execute(
        new String[] {"package", temporary.resolve("first").toString()},
        new PrintStream(stdout),
        sink));
    assertTrue(Files.isRegularFile(
        temporary.resolve("build/first/demo.first-1.0.0.wpk")));
    assertEquals(0, Wheeler.execute(
        new String[] {"plan", temporary.toString()}, new PrintStream(stdout), sink));
    assertTrue(Files.isRegularFile(
        temporary.resolve("build/wheeler.workspace.plan")));
    Path planPath = temporary.resolve("build.plan");
    assertEquals(0, Wheeler.execute(
        new String[] {
            "plan", temporary.toString(), "-o", planPath.toString()
        },
        new PrintStream(stdout),
        sink));
    BuildPlan plan = new BuildPlanCodec().decode(Files.readAllBytes(planPath));
    assertEquals(List.of("first/main.wbc", "second/main.wbc"),
        plan.nodes().stream().map(BuildPlan.Node::outputPath).toList());
    assertTrue(plan.nodes().stream().allMatch(
        node -> node.executionLimits().equals(BuildPlan.ExecutionLimits.DEFAULT)));
    assertTrue(plan.nodes().stream().allMatch(node -> node.capabilityGrants().isEmpty()));
    assertEquals(0, Wheeler.execute(
        new String[] {"verify-plan", planPath.toString()}, new PrintStream(stdout), sink));
    assertThrows(PackageFormatException.class, () -> Wheeler.execute(
        new String[] {
            "execute-plan", temporary.toString(), planPath.toString(),
            "-o", temporary.resolve("denied").toString()
        }, new PrintStream(stdout), sink));

    Path grantedPlan = temporary.resolve("granted.plan");
    assertEquals(0, Wheeler.execute(
        new String[] {
            "plan", temporary.toString(),
            "--grant-requested", "-o", grantedPlan.toString()
        }, new PrintStream(stdout), sink));
    BuildPlan executablePlan = new BuildPlanCodec().decode(Files.readAllBytes(grantedPlan));
    BuildPlan forgedCompiler = new BuildPlan(
        executablePlan.schemaVersion(),
        executablePlan.workspaceIdentity(),
        "f".repeat(64),
        executablePlan.profile(),
        executablePlan.nodes());
    Path forgedPlan = temporary.resolve("forged-compiler.plan");
    Files.write(forgedPlan, new BuildPlanCodec().encode(forgedCompiler));
    assertThrows(PackageFormatException.class, () -> Wheeler.execute(
        new String[] {
            "execute-plan", temporary.toString(), forgedPlan.toString(),
            "-o", temporary.resolve("forged").toString()
        }, new PrintStream(stdout), sink));

    Path plannedOutput = temporary.resolve("planned-artifacts");
    assertEquals(0, Wheeler.execute(
        new String[] {
            "execute-plan", temporary.toString(), grantedPlan.toString(),
            "-o", plannedOutput.toString()
        }, new PrintStream(stdout), sink));
    assertArrayEquals(
        Files.readAllBytes(output.resolve("first/main.wbc")),
        Files.readAllBytes(plannedOutput.resolve("first/main.wbc")));
    assertArrayEquals(
        Files.readAllBytes(output.resolve("second/main.wbc")),
        Files.readAllBytes(plannedOutput.resolve("second/main.wbc")));
    assertThrows(IOException.class, () -> Wheeler.execute(
        new String[] {
            "execute-plan", temporary.toString(), grantedPlan.toString(),
            "-o", plannedOutput.toString()
        }, new PrintStream(stdout), sink));

    Files.writeString(temporary.resolve("first/src/Main.w"), "classical class Changed {");
    assertThrows(PackageFormatException.class, () -> Wheeler.execute(
        new String[] {
            "execute-plan", temporary.toString(), grantedPlan.toString(),
            "-o", temporary.resolve("stale").toString()
        }, new PrintStream(stdout), sink));
    assertTrue(stdout.toString(StandardCharsets.UTF_8).contains("checked workspace demo (2 targets)"));
  }

  @Test
  void testSubcommandExecutesOnlyTestSelectedTargets() throws Exception {
    Path project = temporary.resolve("tests");
    Files.createDirectories(project.resolve("src"));
    Files.writeString(project.resolve("wheeler.package.yaml"), """
        schema: 1
        package:
          name: "demo.tests"
          version: "1.0.0"
          profile: "bootstrap-1"
        targets:
          - kind: "deployable"
            name: "example"
            root: "src/Example.w"
            test: false
          - kind: "tool"
            name: "law"
            root: "src/Law.w"
            test: true
        dependencies: []
        capabilities: []
        """);
    Files.writeString(project.resolve("src/Example.w"), """
        classical class Example {
            state long value = 0;
            entry void main() { value += 1; }
        }
        """);
    Files.writeString(project.resolve("src/Law.w"), """
        classical class Law {
            state long value = 0;
            test void startsAtZero() { assert(value == 0); }
            test void accepts(long input) cases(-1, 2) { value = input; }
            test void addsTwo() { value += 2; assert(value == 2); }
            entry void main() { value += 2; assert(value == 2); }
        }
        """);
    ByteArrayOutputStream stdout = new ByteArrayOutputStream();

    assertEquals(0, Wheeler.execute(
        new String[] {"test", project.toString()},
        new PrintStream(stdout),
        new PrintStream(new ByteArrayOutputStream())));
    String firstReport = stdout.toString(StandardCharsets.UTF_8);
    assertTrue(firstReport.contains("PASS demo.tests::law::accepts[0]"));
    assertTrue(firstReport.contains("PASS demo.tests::law::accepts[1]"));
    assertTrue(firstReport.contains("PASS demo.tests::law::addsTwo"));
    assertTrue(firstReport.contains("PASS demo.tests::law::startsAtZero"));
    assertTrue(firstReport.lines().anyMatch(line ->
        line.contains("law::addsTwo") && line.contains(" assertions 1 ")));
    assertTrue(firstReport.lines().anyMatch(line ->
        line.contains("law::accepts[0]") && line.contains(" assertions 0 ")));
    assertTrue(firstReport.contains(" coverage "));
    assertTrue(firstReport.contains("tested demo.tests (4 cases, 4 passed, 0 failed, report "));
    stdout.reset();
    assertEquals(0, Wheeler.execute(
        new String[] {"test", project.toString()},
        new PrintStream(stdout),
        new PrintStream(new ByteArrayOutputStream())));
    assertEquals(firstReport, stdout.toString(StandardCharsets.UTF_8));
    stdout.reset();
    assertEquals(0, Wheeler.execute(
        new String[] {"run", project.toString(), "--target", "law"},
        new PrintStream(stdout),
        new PrintStream(new ByteArrayOutputStream())));
    assertTrue(stdout.toString(StandardCharsets.UTF_8).contains("value = 2"));
  }

  @Test
  void testSubcommandDiscoversRootModuleTests() throws Exception {
    Path project = temporary.resolve("module-tests");
    Files.createDirectories(project.resolve("src"));
    Files.writeString(project.resolve("wheeler.package.yaml"), """
        schema: 1
        package:
          name: "demo.modules"
          version: "1.0.0"
          profile: "bootstrap-1"
        targets:
          - kind: "tool"
            name: "laws"
            root: "src/Main.w"
            module: "tests.main"
            sources:
              - "src/Helper.w"
              - "src/Main.w"
            test: true
        dependencies: []
        capabilities: []
        """);
    Files.writeString(project.resolve("src/Helper.w"), """
        module tests.helper;
        classical class Helper {
          public long answer() { return 42; }
        }
        """);
    Files.writeString(project.resolve("src/Main.w"), """
        module tests.main;
        import tests.helper;
        classical class Main {
          state long result = 0;
          test void checksHelper() {
            result = tests.helper::answer();
            assert(result == 42);
          }
          entry void main() { result = 1; }
        }
        """);
    ByteArrayOutputStream stdout = new ByteArrayOutputStream();

    assertEquals(0, Wheeler.execute(
        new String[] {"test", project.toString()},
        new PrintStream(stdout),
        new PrintStream(new ByteArrayOutputStream())));

    String report = stdout.toString(StandardCharsets.UTF_8);
    assertTrue(report.contains(
        "PASS demo.modules::laws::tests.main::checksHelper"));
    assertTrue(report.contains("(1 cases, 1 passed, 0 failed, report "));
  }

  @Test
  void testSubcommandReducesCompileAndRuntimeFailuresIntoTheReport() throws Exception {
    Path project = temporary.resolve("test-failures");
    Files.createDirectories(project.resolve("src"));
    Files.writeString(project.resolve("wheeler.package.yaml"), """
        schema: 1
        package:
          name: "demo.failures"
          version: "1.0.0"
          profile: "bootstrap-1"
        targets:
          - kind: "tool"
            name: "assertion"
            root: "src/Assertion.w"
            test: true
          - kind: "tool"
            name: "compile"
            root: "src/Compile.w"
            test: true
          - kind: "tool"
            name: "runtime"
            root: "src/Runtime.w"
            test: true
        dependencies: []
        capabilities: []
        """);
    Files.writeString(project.resolve("src/Compile.w"),
        "classical class Compile { entry void main(] {} }");
    Files.writeString(project.resolve("src/Runtime.w"), """
        classical class Runtime {
            state long value = 1;
            entry void main() { long zero = 0; value = value / zero; }
        }
        """);
    Files.writeString(project.resolve("src/Assertion.w"), """
        classical class Assertion {
            state long value = 1;
            entry void main() { assert(value == 2); }
        }
        """);
    ByteArrayOutputStream stdout = new ByteArrayOutputStream();

    assertEquals(1, Wheeler.execute(
        new String[] {"test", project.toString()},
        new PrintStream(stdout),
        new PrintStream(new ByteArrayOutputStream())));
    String report = stdout.toString(StandardCharsets.UTF_8);
    assertTrue(report.contains("FAIL demo.failures::compile"));
    assertTrue(report.contains("WTEST001"));
    assertTrue(report.contains("FAIL demo.failures::runtime"));
    assertTrue(report.contains("WTEST002"));
    assertTrue(report.contains("FAIL demo.failures::assertion"));
    assertTrue(report.contains("WTEST003"));
    assertTrue(report.lines().anyMatch(line ->
        line.contains("demo.failures::assertion") && line.contains(" assertions 1 ")));
    assertTrue(report.contains("3 cases, 0 passed, 3 failed, report "));
  }

  @Test
  void runBindsExplicitPhysicalInputAndPublishesOutputAtomically() throws Exception {
    Path project = temporary.resolve("input");
    Files.createDirectories(project.resolve("src"));
    Files.writeString(project.resolve("wheeler.package.yaml"), """
        schema: 1
        package:
          name: "demo.input"
          version: "1.0.0"
          profile: "bootstrap-1"
        targets:
          - kind: "deployable"
            name: "main"
            root: "src/Main.w"
            test: false
        dependencies: []
        capabilities: []
        """);
    Files.writeString(project.resolve("src/Main.w"), """
        classical class Main {
          state long scalars = 0;
          entry void main(borrow utf8 source, borrow mut bytes output) {
            scalars = utf8Count(source);
            setByte(output, 0, 79);
            setByte(output, 1, 75);
            assert(scalars == 2);
          }
        }
        """);
    Path input = temporary.resolve("input.txt");
    Files.writeString(input, "A¢", StandardCharsets.UTF_8);
    Path result = temporary.resolve("result.bin");
    ByteArrayOutputStream stdout = new ByteArrayOutputStream();

    assertEquals(0, Wheeler.execute(
        new String[] {
            "run", project.toString(), "--target", "main",
            "--input", input.toString(),
            "--output", result.toString(), "--output-bytes", "2"
        },
        new PrintStream(stdout),
        new PrintStream(new ByteArrayOutputStream())));
    assertTrue(stdout.toString(StandardCharsets.UTF_8).contains("scalars = 2"));
    assertArrayEquals(new byte[] {79, 75}, Files.readAllBytes(result));

    Path malformed = temporary.resolve("malformed.txt");
    Files.write(malformed, new byte[] {(byte) 0xc0, (byte) 0x80});
    Files.writeString(result, "preserve");
    assertThrows(VmTrap.class, () -> Wheeler.execute(
        new String[] {
            "run", project.toString(), "--target", "main",
            "--input", malformed.toString(),
            "--output", result.toString(), "--output-bytes", "2"
        },
        new PrintStream(new ByteArrayOutputStream()),
        new PrintStream(new ByteArrayOutputStream())));
    assertEquals("preserve", Files.readString(result));
  }

  @Test
  void runBindsImmutableBinaryInputWithoutUtf8Guessing() throws Exception {
    Path project = temporary.resolve("binary-input");
    Files.createDirectories(project.resolve("src"));
    Files.writeString(project.resolve("wheeler.package.yaml"), """
        schema: 1
        package:
          name: "demo.binaryinput"
          version: "1.0.0"
          profile: "bootstrap-1"
        targets:
          - kind: "deployable"
            name: "main"
            root: "src/Main.w"
            test: false
        dependencies: []
        capabilities: []
        """);
    Files.writeString(project.resolve("src/Main.w"), """
        classical class Main {
          state long selected = 0;
          entry void main(borrow byteview source, borrow mut bytes output) {
            selected = source[1];
            setByte(output, 0, selected);
            assert(selected == 255);
          }
        }
        """);
    Path input = temporary.resolve("input.dat");
    Files.write(input, new byte[] {0, (byte) 255});
    Path result = temporary.resolve("binary-result.dat");
    ByteArrayOutputStream stdout = new ByteArrayOutputStream();

    assertEquals(0, Wheeler.execute(
        new String[] {
            "run", project.toString(), "--target", "main",
            "--input-bytes", input.toString(),
            "--output", result.toString(), "--output-bytes", "1"
        },
        new PrintStream(stdout),
        new PrintStream(new ByteArrayOutputStream())));
    assertTrue(stdout.toString(StandardCharsets.UTF_8).contains("selected = 255"));
    assertArrayEquals(new byte[] {(byte) 255}, Files.readAllBytes(result));
    assertThrows(VmTrap.class, () -> Wheeler.execute(
        new String[] {
            "run", project.toString(), "--target", "main",
            "--input", input.toString(),
            "--output", result.toString(), "--output-bytes", "1"
        },
        new PrintStream(new ByteArrayOutputStream()),
        new PrintStream(new ByteArrayOutputStream())));
  }

  @Test
  void packageSelectedWheelerVerifierConsumesBinaryArtifact() throws Exception {
    Path artifact = temporary.resolve("native-subject.wbc");
    Files.write(
        artifact,
        new WheelerCompiler().compileToBytecode(
            "classical class NativeSubject { state long value = 2; "
                + "entry void main() { value += 3; } }"));
    ByteArrayOutputStream stdout = new ByteArrayOutputStream();

    assertEquals(0, Wheeler.execute(
        new String[] {
            "run", Path.of("wheeler-examples").toString(),
            "--target", "nativeverifier",
            "--input-bytes", artifact.toString()
        },
        new PrintStream(stdout),
        new PrintStream(new ByteArrayOutputStream())));
    assertTrue(stdout.toString(StandardCharsets.UTF_8).contains("verification = 1"));
  }

  @Test
  void runPublishesAWheelerWrittenExecutableArtifact() throws Exception {
    Path project = temporary.resolve("seed-writer");
    Files.createDirectories(project.resolve("src/compiler/backend"));
    Files.createDirectories(project.resolve("src/compiler/frontend"));
    Files.createDirectories(project.resolve("src/compiler/ir"));
    Files.createDirectories(project.resolve("src/compiler/verification"));
    Files.createDirectories(project.resolve("src/lexer"));
    Files.createDirectories(project.resolve("src/packages"));
    Files.writeString(project.resolve("wheeler.package.yaml"), """
        schema: 1
        package:
          name: "demo.seedwriter"
          version: "1.0.0"
          profile: "bootstrap-1"
        targets:
          - kind: "deployable"
            name: "compiler"
            root: "src/MinimalCompiler.w"
            module: "wheeler.compiler.driver"
            sources:
              - "src/MinimalCompiler.w"
              - "src/compiler/backend/Codegen.w"
              - "src/compiler/backend/Encoding.w"
              - "src/compiler/backend/StringTable.w"
              - "src/compiler/frontend/HelperParser.w"
              - "src/compiler/frontend/Parser.w"
              - "src/compiler/frontend/Statements.w"
              - "src/compiler/frontend/Structure.w"
              - "src/compiler/frontend/Tokens.w"
              - "src/compiler/ir/Ir.w"
              - "src/compiler/ir/Opcodes.w"
              - "src/compiler/ir/ProofRules.w"
              - "src/compiler/ir/TypeCodes.w"
              - "src/compiler/verification/AggregateVerifier.w"
              - "src/compiler/verification/FunctionVerifier.w"
              - "src/compiler/verification/InstructionVerifier.w"
              - "src/compiler/verification/ProofVerifier.w"
              - "src/compiler/verification/StorageVerifier.w"
              - "src/compiler/verification/Verifier.w"
              - "src/lexer/Scanner.w"
              - "src/packages/Binary.w"
            test: false
        dependencies: []
        capabilities: []
        """);
    Path examples = Path.of("wheeler-examples/src/main/wheeler");
    Path compilerSources = Path.of("wheeler-compiler/src/main/wheeler");
    Path coreSources = Path.of("wheeler-core/src/main/wheeler");
    Files.copy(
        compilerSources.resolve("MinimalCompiler.w"), project.resolve("src/MinimalCompiler.w"));
    Files.copy(
        compilerSources.resolve("compiler/verification/AggregateVerifier.w"),
        project.resolve("src/compiler/verification/AggregateVerifier.w"));
    Files.copy(
        compilerSources.resolve("compiler/backend/Codegen.w"),
        project.resolve("src/compiler/backend/Codegen.w"));
    Files.copy(
        compilerSources.resolve("compiler/backend/Encoding.w"),
        project.resolve("src/compiler/backend/Encoding.w"));
    Files.copy(
        compilerSources.resolve("compiler/verification/FunctionVerifier.w"),
        project.resolve("src/compiler/verification/FunctionVerifier.w"));
    Files.copy(
        compilerSources.resolve("compiler/frontend/HelperParser.w"),
        project.resolve("src/compiler/frontend/HelperParser.w"));
    Files.copy(
        compilerSources.resolve("compiler/verification/InstructionVerifier.w"),
        project.resolve("src/compiler/verification/InstructionVerifier.w"));
    Files.copy(
        compilerSources.resolve("compiler/ir/Ir.w"),
        project.resolve("src/compiler/ir/Ir.w"));
    Files.copy(
        compilerSources.resolve("compiler/ir/Opcodes.w"),
        project.resolve("src/compiler/ir/Opcodes.w"));
    Files.copy(
        compilerSources.resolve("compiler/frontend/Parser.w"),
        project.resolve("src/compiler/frontend/Parser.w"));
    Files.copy(
        compilerSources.resolve("compiler/ir/ProofRules.w"),
        project.resolve("src/compiler/ir/ProofRules.w"));
    Files.copy(
        compilerSources.resolve("compiler/verification/ProofVerifier.w"),
        project.resolve("src/compiler/verification/ProofVerifier.w"));
    Files.copy(
        compilerSources.resolve("compiler/frontend/Statements.w"),
        project.resolve("src/compiler/frontend/Statements.w"));
    Files.copy(
        compilerSources.resolve("compiler/verification/StorageVerifier.w"),
        project.resolve("src/compiler/verification/StorageVerifier.w"));
    Files.copy(
        compilerSources.resolve("compiler/backend/StringTable.w"),
        project.resolve("src/compiler/backend/StringTable.w"));
    Files.copy(
        compilerSources.resolve("compiler/frontend/Structure.w"),
        project.resolve("src/compiler/frontend/Structure.w"));
    Files.copy(
        compilerSources.resolve("compiler/frontend/Tokens.w"),
        project.resolve("src/compiler/frontend/Tokens.w"));
    Files.copy(
        compilerSources.resolve("compiler/ir/TypeCodes.w"),
        project.resolve("src/compiler/ir/TypeCodes.w"));
    Files.copy(
        compilerSources.resolve("compiler/verification/Verifier.w"),
        project.resolve("src/compiler/verification/Verifier.w"));
    Files.copy(compilerSources.resolve("lexer/Scanner.w"), project.resolve("src/lexer/Scanner.w"));
    Files.copy(
        coreSources.resolve("encoding/Binary.w"),
        project.resolve("src/packages/Binary.w"));
    Path className = temporary.resolve("class-name.txt");
    Files.writeString(
        className,
        "classical class LongClass { state long value = 7; "
            + "entry void main() { value += 5; } }",
        StandardCharsets.UTF_8);
    Path artifact = temporary.resolve("seed.wbc");
    ByteArrayOutputStream bytes = new ByteArrayOutputStream();
    PrintStream output = new PrintStream(bytes, true, StandardCharsets.UTF_8);

    assertEquals(0, Wheeler.execute(
        new String[] {
            "run", project.toString(), "--target", "compiler",
            "--input", className.toString(),
            "--output", artifact.toString(), "--output-bytes", "512"
        },
        output,
        output));
    new BytecodeReader().read(Files.readAllBytes(artifact));
    assertEquals(0, Wheeler.execute(
        new String[] {"run", artifact.toString()}, output, output));
    assertTrue(bytes.toString(StandardCharsets.UTF_8).contains("finalCursor = 504"));

    Path counter = temporary.resolve("Counter.w");
    Files.copy(
        examples.resolve("classical/control/Counter.w"),
        counter);
    Path counterArtifact = temporary.resolve("counter.wbc");
    assertEquals(0, Wheeler.execute(
        new String[] {
            "run", project.toString(), "--target", "compiler",
            "--input", counter.toString(),
            "--output", counterArtifact.toString(), "--output-bytes", "1024"
        },
        output,
        output));
    byte[] counterBytes = Files.readAllBytes(counterArtifact);
    assertArrayEquals(
        new WheelerCompiler().compileToBytecode(Files.readString(counter)),
        counterBytes);
    new BytecodeReader().read(counterBytes);
    assertEquals(0, Wheeler.execute(
        new String[] {"run", counterArtifact.toString()}, output, output));
    assertTrue(bytes.toString(StandardCharsets.UTF_8).contains("count = 0"));
  }

  @Test
  void compileSubcommandReplacesTheStandaloneCompilerPath() throws Exception {
    Path source = temporary.resolve("Counter.w");
    Path output = temporary.resolve("custom.wbc");
    Files.writeString(source, """
        classical class Counter {
            state long count = 0;
            entry void main() { count += 2; }
        }
        """);

    assertEquals(0, Wheeler.execute(
        new String[] {"compile", source.toString(), "-o", output.toString()},
        new PrintStream(new ByteArrayOutputStream()),
        new PrintStream(new ByteArrayOutputStream())));
    new BytecodeReader().read(Files.readAllBytes(output));

    ByteArrayOutputStream disassembly = new ByteArrayOutputStream();
    assertEquals(0, Wheeler.execute(
        new String[] {"disassemble", output.toString()},
        new PrintStream(disassembly),
        new PrintStream(new ByteArrayOutputStream())));
    assertTrue(disassembly.toString(StandardCharsets.UTF_8).contains("Counter"));
  }

  @Test
  void manifestsAClosedVerifiedArtifactSetCanonically() throws Exception {
    Path set = temporary.resolve("artifact-set");
    Path nested = set.resolve("nested");
    Files.createDirectories(nested);
    Files.write(
        set.resolve("first.wbc"),
        new WheelerCompiler().compileToBytecode(
            "classical class First { entry void main() {} }"));
    Files.write(
        nested.resolve("second.wbc"),
        new WheelerCompiler().compileToBytecode(
            "classical class Second { entry void main() {} }"));
    ByteArrayOutputStream output = new ByteArrayOutputStream();
    PrintStream sink = new PrintStream(new ByteArrayOutputStream());

    assertEquals(0, Wheeler.execute(
        new String[] {"manifest-artifacts", set.toString()},
        new PrintStream(output),
        sink));
    String first = Files.readString(set.resolve(ArtifactSetManifest.FILE_NAME));
    assertTrue(first.contains("\"profile\":\"wheeler.artifact-set/1\""));
    assertTrue(first.contains("\"path\":\"first.wbc\""));
    assertTrue(first.contains("\"path\":\"nested/second.wbc\""));
    assertTrue(output.toString(StandardCharsets.UTF_8).contains("manifested 2 artifacts"));

    assertEquals(0, Wheeler.execute(
        new String[] {"manifest-artifacts", set.toString()},
        new PrintStream(new ByteArrayOutputStream()),
        sink));
    assertEquals(first, Files.readString(set.resolve(ArtifactSetManifest.FILE_NAME)));

    Files.writeString(set.resolve("ambient.txt"), "not part of the artifact graph\n");
    assertThrows(IOException.class, () -> Wheeler.execute(
        new String[] {"manifest-artifacts", set.toString()},
        new PrintStream(new ByteArrayOutputStream()),
        sink));
  }

  @Test
  void qasmSubcommandLowersOneStaticQuantumSubmission() throws Exception {
    Path source = temporary.resolve("Quantum.w");
    Path artifact = temporary.resolve("Quantum.wbc");
    Path output = temporary.resolve("Quantum.qasm");
    Files.writeString(source, """
        quantum class Quantum {
            state long measured = 0;
            qreg q = new qreg(1);
            unitary void flip() { X(q[0]); }
            entry void main() {
                prepare(q, 0);
                flip();
                measured = measure(q);
                assert(measured == 1);
            }
        }
        """);
    PrintStream sink = new PrintStream(new ByteArrayOutputStream());

    assertEquals(0, Wheeler.execute(
        new String[] {"compile", source.toString(), "-o", artifact.toString()}, sink, sink));
    assertEquals(0, Wheeler.execute(
        new String[] {"qasm", artifact.toString(), output.toString()}, sink, sink));
    String qasm = Files.readString(output);
    assertTrue(qasm.startsWith("OPENQASM 3.0;"));
    assertTrue(qasm.contains("x q[0];"));
  }

  @Test
  void cleanRefusesSymbolicLinkOutputs() throws Exception {
    Path project = temporary.resolve("project");
    createPackage(project, "demo.project", "Project", 1);
    Path external = temporary.resolve("external");
    Files.createDirectories(external);
    Files.writeString(external.resolve("keep"), "keep");
    Files.createSymbolicLink(project.resolve("build"), external);

    assertThrows(
        java.io.IOException.class,
        () -> Wheeler.execute(
            new String[] {"clean", project.toString()},
            new PrintStream(new ByteArrayOutputStream()),
            new PrintStream(new ByteArrayOutputStream())));
    assertTrue(Files.isRegularFile(external.resolve("keep")));
  }

  @Test
  void invalidCommandArgumentsFailWithoutSideEffects() throws Exception {
    ByteArrayOutputStream errors = new ByteArrayOutputStream();
    int status = Wheeler.execute(
        new String[] {"build", temporary.toString(), "bad", "output"},
        new PrintStream(new ByteArrayOutputStream()),
        new PrintStream(errors));

    assertEquals(2, status);
    assertTrue(errors.toString(StandardCharsets.UTF_8).contains("Expected -o"));
    try (var entries = Files.list(temporary)) {
      assertEquals(0, entries.count());
    }
  }

  private static void createPackage(
      Path root, String packageName, String className, int increment) throws Exception {
    Files.createDirectories(root.resolve("src"));
    Files.writeString(root.resolve("wheeler.package.yaml"), """
        schema: 1
        package:
          name: "%s"
          version: "1.0.0"
          profile: "bootstrap-1"
        targets:
          - kind: "deployable"
            name: "main"
            root: "src/Main.w"
            test: false
        dependencies: []
        capabilities:
          - name: "build.read"
            path: "src/**"
        """.formatted(packageName));
    Files.writeString(root.resolve("src/Main.w"), """
        classical class %s {
            state long value = 0;
            entry void main() { value += %d; }
        }
        """.formatted(className, increment));
  }
}
