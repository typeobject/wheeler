package com.typeobject.wheeler.tools;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.core.bytecode.BytecodeReader;
import com.typeobject.wheeler.core.vm.VmTrap;
import com.typeobject.wheeler.packageformat.BuildPlan;
import com.typeobject.wheeler.packageformat.BuildPlanCodec;
import com.typeobject.wheeler.packageformat.PackageArchive;
import com.typeobject.wheeler.packageformat.PackageArchive.DecodedPackage;
import com.typeobject.wheeler.packageformat.PackageFormatException;
import com.typeobject.wheeler.packageformat.PackageLock;
import com.typeobject.wheeler.packageformat.PackageLockParser;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.PrintStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

class WheelerCommandTest {
  @TempDir
  Path temporary;

  @Test
  void unifiedCommandChecksBuildsRunsPackagesAndVerifies() throws Exception {
    Path project = temporary.resolve("demo");
    Files.createDirectories(project.resolve("src"));
    Files.writeString(project.resolve("wheeler.package"), """
        package "demo.counter" version "1.0.0" profile "bootstrap-1";
        target example "counter" root "src/Counter.w";
        capability "build.read" path "src/**";
        capability "build.write" path "out/**";
        """);
    Files.writeString(project.resolve("src/Counter.w"), """
        classical class Counter {
            state long count = 0;
            rev void increment() { count += 1; }
            entry void main() { increment(); assert count == 1; }
        }
        """);
    ByteArrayOutputStream stdoutBytes = new ByteArrayOutputStream();
    ByteArrayOutputStream stderrBytes = new ByteArrayOutputStream();
    PrintStream stdout = new PrintStream(stdoutBytes, true, StandardCharsets.UTF_8);
    PrintStream stderr = new PrintStream(stderrBytes, true, StandardCharsets.UTF_8);

    assertEquals(0, Wheeler.execute(new String[] {"check", project.toString()}, stdout, stderr));
    assertEquals(0, Wheeler.execute(new String[] {"build", project.toString()}, stdout, stderr));
    Path artifact = project.resolve("out/counter.wbc");
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
    assertTrue(Files.notExists(project.resolve("out")));
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
    Files.writeString(project.resolve("wheeler.package"), """
        package "demo.modules" version "1.0.0" profile "bootstrap-1";
        target example "main" root "src/Main.w" module "demo.main"
            source "src/Arithmetic.w" source "src/Main.w";
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
          entry void main() { result = twice(9); assert result == 18; }
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
    new BytecodeReader().read(Files.readAllBytes(project.resolve("out/main.wbc")));
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
    Files.writeString(temporary.resolve("wheeler.workspace"), """
        workspace "demo" profile "bootstrap-1";
        member "second" path "second";
        member "first" path "first";
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
  void testSubcommandExecutesOnlyDeclaredTestTargets() throws Exception {
    Path project = temporary.resolve("tests");
    Files.createDirectories(project.resolve("src"));
    Files.writeString(project.resolve("wheeler.package"), """
        package "demo.tests" version "1.0.0" profile "bootstrap-1";
        target example "example" root "src/Example.w";
        target test "law" root "src/Law.w";
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
            entry void main() { value += 2; assert value == 2; }
        }
        """);
    ByteArrayOutputStream stdout = new ByteArrayOutputStream();

    assertEquals(0, Wheeler.execute(
        new String[] {"test", project.toString()},
        new PrintStream(stdout),
        new PrintStream(new ByteArrayOutputStream())));
    assertTrue(stdout.toString(StandardCharsets.UTF_8).contains("tested demo.tests (1 targets)"));
  }

  @Test
  void runBindsExplicitPhysicalInputAndPublishesOutputAtomically() throws Exception {
    Path project = temporary.resolve("input");
    Files.createDirectories(project.resolve("src"));
    Files.writeString(project.resolve("wheeler.package"), """
        package "demo.input" version "1.0.0" profile "bootstrap-1";
        target example "main" root "src/Main.w";
        """);
    Files.writeString(project.resolve("src/Main.w"), """
        classical class Main {
          state long scalars = 0;
          entry void main(utf8 source, bytes output) {
            scalars = utf8Count(source);
            setByte(output, 0, 79);
            setByte(output, 1, 75);
            assert scalars == 2;
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
  void runPublishesAWheelerWrittenExecutableArtifact() throws Exception {
    Path project = temporary.resolve("seed-writer");
    Files.createDirectories(project.resolve("src/compiler"));
    Files.writeString(project.resolve("wheeler.package"), """
        package "demo.seedwriter" version "1.0.0" profile "bootstrap-1";
        target example "seed" root "src/SeedArtifact.w" module "examples.compiler.seed"
            source "src/SeedArtifact.w" source "src/compiler/Encoding.w";
        """);
    Path examples = Path.of("../wheeler-examples/src/main/wheeler");
    Files.copy(examples.resolve("SeedArtifact.w"), project.resolve("src/SeedArtifact.w"));
    Files.copy(
        examples.resolve("compiler/Encoding.w"),
        project.resolve("src/compiler/Encoding.w"));
    Path artifact = temporary.resolve("seed.wbc");
    ByteArrayOutputStream bytes = new ByteArrayOutputStream();
    PrintStream output = new PrintStream(bytes, true, StandardCharsets.UTF_8);

    assertEquals(0, Wheeler.execute(
        new String[] {
            "run", project.toString(), "--target", "seed",
            "--output", artifact.toString(), "--output-bytes", "512"
        },
        output,
        output));
    new BytecodeReader().read(Files.readAllBytes(artifact));
    assertEquals(0, Wheeler.execute(
        new String[] {"run", artifact.toString()}, output, output));
    assertTrue(bytes.toString(StandardCharsets.UTF_8).contains("finalCursor = 360"));
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
  void resolveSubcommandConsumesVerifiedArchivesAndWritesCanonicalLock() throws Exception {
    Path library = temporary.resolve("library");
    createPackage(library, "demo.library", "Library", 1);
    Files.writeString(library.resolve("wheeler.package"), """
        package "demo.library" version "1.0.0" profile "bootstrap-1";
        target example "main" root "src/Main.w" module "demo.library.main"
            source "src/Helper.w" source "src/Main.w";
        capability "build.read" path "src/**";
        """);
    Files.writeString(library.resolve("src/Helper.w"), """
        module demo.library.helper;
        classical class Helper {
          public long increment(long value) { return value + 1; }
        }
        """);
    Files.writeString(library.resolve("src/Main.w"), """
        module demo.library.main;
        import demo.library.helper;
        classical class Library {
          state long value = 0;
          entry void main() { value = increment(value); assert value == 1; }
        }
        """);
    Path application = temporary.resolve("application");
    Files.createDirectories(application.resolve("src"));
    Files.writeString(application.resolve("wheeler.package"), """
        package "demo.application" version "1.0.0" profile "bootstrap-1";
        target binary "main" root "src/Main.w";
        dependency normal "demo.library" version "^1.0.0";
        """);
    Files.writeString(application.resolve("src/Main.w"), """
        classical class Main {
            state long value = 0;
            entry void main() { value += 1; }
        }
        """);
    Path catalog = temporary.resolve("catalog");
    Files.createDirectories(catalog);
    Path archive = catalog.resolve("library.wpk");
    Path lockPath = temporary.resolve("wheeler.lock");
    ByteArrayOutputStream stdout = new ByteArrayOutputStream();
    PrintStream output = new PrintStream(stdout);
    PrintStream sink = new PrintStream(new ByteArrayOutputStream());

    assertEquals(0, Wheeler.execute(
        new String[] {"package", library.toString(), "-o", archive.toString()}, output, sink));
    assertEquals(0, Wheeler.execute(
        new String[] {
            "resolve", application.toString(), "--catalog", catalog.toString(),
            "-o", lockPath.toString()
        },
        output,
        sink));
    PackageLock lock = new PackageLockParser().parse(Files.readAllBytes(lockPath));
    assertEquals(List.of("demo.library"),
        lock.entries().stream().map(PackageLock.Entry::name).toList());
    assertEquals(0, Wheeler.execute(
        new String[] {"verify-lock", lockPath.toString()}, output, sink));
    Path vendor = application.resolve("vendor");
    String[] vendorCommand = {
        "vendor", lockPath.toString(), "--catalog", catalog.toString(),
        "-o", vendor.toString()
    };
    assertEquals(0, Wheeler.execute(vendorCommand, output, sink));
    assertEquals(0, Wheeler.execute(vendorCommand, output, sink));
    assertEquals(Files.readString(lockPath), Files.readString(vendor.resolve("wheeler.lock")));
    try (var files = Files.list(vendor)) {
      assertEquals(2, files.count());
    }
    assertEquals(0, Wheeler.execute(
        new String[] {"check", application.toString()}, output, sink));
    assertEquals(0, Wheeler.execute(
        new String[] {"build", application.toString()}, output, sink));
    assertTrue(Files.isRegularFile(application.resolve("out/main.wbc")));
    assertTrue(Files.isRegularFile(
        application.resolve("out/dependencies/demo.library/main.wbc")));
    assertEquals(0, Wheeler.execute(
        new String[] {"run", application.toString(), "--target", "main"}, output, sink));

    Files.writeString(temporary.resolve("wheeler.workspace"), """
        workspace "locked" profile "bootstrap-1";
        member "application" path "application";
        """);
    Path planPath = temporary.resolve("locked.plan");
    assertEquals(0, Wheeler.execute(
        new String[] {
            "plan", temporary.toString(),
            "--grant-requested", "-o", planPath.toString()
        },
        output,
        sink));
    BuildPlan dependencyPlan = new BuildPlanCodec().decode(Files.readAllBytes(planPath));
    assertEquals(2, dependencyPlan.nodes().size());
    assertEquals(List.of("demo.library"), dependencyPlan.nodes().stream()
        .filter(node -> node.packageName().equals("demo.application"))
        .findFirst().orElseThrow().packageInputs().stream()
        .map(BuildPlan.PackageInput::name).toList());
    assertTrue(dependencyPlan.nodes().stream().allMatch(
        node -> node.capabilityGrants().equals(node.capabilityRequests())));

    Path vendoredArchive;
    try (var files = Files.list(vendor)) {
      vendoredArchive = files
          .filter(path -> path.getFileName().toString().endsWith(".wpk"))
          .findFirst()
          .orElseThrow();
    }
    Files.write(vendoredArchive, new byte[] {1});
    assertThrows(java.io.IOException.class, () -> Wheeler.execute(vendorCommand, output, sink));
    assertThrows(
        com.typeobject.wheeler.packageformat.PackageFormatException.class,
        () -> Wheeler.execute(
            new String[] {"check", application.toString()}, output, sink));
    assertTrue(stdout.toString(StandardCharsets.UTF_8).contains(lock.identity()));
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
                assert measured == 1;
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
    Files.createSymbolicLink(project.resolve("out"), external);

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
    Files.writeString(root.resolve("wheeler.package"), """
        package "%s" version "1.0.0" profile "bootstrap-1";
        target example "main" root "src/Main.w";
        capability "build.read" path "src/**";
        """.formatted(packageName));
    Files.writeString(root.resolve("src/Main.w"), """
        classical class %s {
            state long value = 0;
            entry void main() { value += %d; }
        }
        """.formatted(className, increment));
  }
}
