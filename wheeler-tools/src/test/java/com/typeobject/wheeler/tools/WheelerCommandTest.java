package com.typeobject.wheeler.tools;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.core.bytecode.BytecodeReader;
import com.typeobject.wheeler.packageformat.PackageArchive;
import com.typeobject.wheeler.packageformat.PackageArchive.DecodedPackage;
import java.io.ByteArrayOutputStream;
import java.io.PrintStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
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
    Path archivePath = temporary.resolve("demo.wpk");
    assertEquals(0, Wheeler.execute(
        new String[] {"package", project.toString(), "-o", archivePath.toString()},
        stdout,
        stderr));
    DecodedPackage archive = new PackageArchive().decode(Files.readAllBytes(archivePath));
    assertEquals("demo.counter", archive.manifest().name());
    assertEquals(0, Wheeler.execute(new String[] {"verify", archivePath.toString()}, stdout, stderr));

    String output = stdoutBytes.toString(StandardCharsets.UTF_8);
    assertTrue(output.contains("checked demo.counter 1.0.0"));
    assertTrue(output.contains("count = 1"));
    assertTrue(output.contains(archive.identity()));
    assertEquals("", stderrBytes.toString(StandardCharsets.UTF_8));
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
  void invalidCommandArgumentsFailWithoutSideEffects() throws Exception {
    ByteArrayOutputStream errors = new ByteArrayOutputStream();
    int status = Wheeler.execute(
        new String[] {"build", temporary.toString(), "bad", "output"},
        new PrintStream(new ByteArrayOutputStream()),
        new PrintStream(errors));

    assertEquals(2, status);
    assertTrue(errors.toString(StandardCharsets.UTF_8).contains("Expected -o"));
    assertEquals(0, Files.list(temporary).count());
  }
}
