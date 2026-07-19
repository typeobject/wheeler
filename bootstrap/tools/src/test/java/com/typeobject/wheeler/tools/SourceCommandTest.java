package com.typeobject.wheeler.tools;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.PrintStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.attribute.FileTime;
import java.nio.file.attribute.PosixFilePermission;
import java.util.Set;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

/** Command-level conformance tests for documentation checks and atomic source formatting. */
class SourceCommandTest {
  @TempDir
  Path temporary;

  @Test
  void checkDocsWalksSourcesCanonicallyAndWritesNothing() throws Exception {
    Path documented = temporary.resolve("Documented.w");
    Files.writeString(documented, """
        //! Documented command fixture.
        classical class Documented {
            /// Runs without observable effects.
            ///
            /// - Effects: Performs no host effects.
            entry void main() {}
        }
        """);
    ByteArrayOutputStream outputBytes = new ByteArrayOutputStream();
    PrintStream output = new PrintStream(outputBytes, true, StandardCharsets.UTF_8);
    PrintStream error = new PrintStream(new ByteArrayOutputStream());

    assertEquals(
        0,
        Wheeler.execute(
            new String[] {"check-docs", documented.toString()}, output, error));
    assertEquals("", outputBytes.toString(StandardCharsets.UTF_8));
    assertEquals(
        0,
        DocumentationCommand.execute(
            new String[] {"check-docs", "--stdin"},
            new ByteArrayInputStream(Files.readAllBytes(documented)),
            output,
            error));
    assertThrows(
        IOException.class,
        () -> DocumentationCommand.execute(
            new String[] {"check-docs", "--stdin"},
            new ByteArrayInputStream(new byte[] {(byte) 0xc0}),
            output,
            error));

    Path directory = temporary.resolve("undocumented");
    Files.createDirectories(directory);
    Path first = directory.resolve("a.w");
    Path second = directory.resolve("b.w");
    Files.writeString(first, "classical class A {}\n");
    Files.writeString(second, "classical class B {}\n");
    assertEquals(
        1,
        Wheeler.execute(
            new String[] {"check-docs", directory.toString()}, output, error));
    String diagnostics = outputBytes.toString(StandardCharsets.UTF_8);
    assertTrue(diagnostics.indexOf(first.toString()) < diagnostics.indexOf(second.toString()));
    assertTrue(diagnostics.contains(
        "WDOC001 " + first + ":1:1 source file requires nonempty //! documentation"));
    assertThrows(
        IOException.class,
        () -> Wheeler.execute(
            new String[] {"check-docs", documented.toString(), documented.toString()},
            output,
            error));

    byte[] before = Files.readAllBytes(first);
    assertEquals(before.length, Files.size(first));
    assertArrayEquals(before, Files.readAllBytes(first));
  }

  @Test
  void formatCommandChecksStdinAndPublishesValidatedFiles() throws Exception {
    Path directory = temporary.resolve("format");
    Files.createDirectories(directory);
    Path first = directory.resolve("a.w");
    Path second = directory.resolve("b.w");
    String compactFirst = "classical class A{entry void main(){long value=1;}}";
    String compactSecond = "classical class B{entry void main(){long value=2;}}";
    Files.writeString(first, compactFirst);
    Files.writeString(second, compactSecond);
    Set<PosixFilePermission> permissions = null;
    if (Files.getFileStore(first).supportsFileAttributeView("posix")) {
      permissions = Set.of(PosixFilePermission.OWNER_READ, PosixFilePermission.OWNER_WRITE);
      Files.setPosixFilePermissions(first, permissions);
    }
    ByteArrayOutputStream outputBytes = new ByteArrayOutputStream();
    ByteArrayOutputStream errorBytes = new ByteArrayOutputStream();
    PrintStream output = new PrintStream(outputBytes, true, StandardCharsets.UTF_8);
    PrintStream error = new PrintStream(errorBytes, true, StandardCharsets.UTF_8);

    assertEquals(1, Wheeler.execute(
        new String[] {"format", "--check", directory.toString()}, output, error));
    assertEquals(compactFirst, Files.readString(first));
    String diagnostics = outputBytes.toString(StandardCharsets.UTF_8);
    assertTrue(diagnostics.indexOf(first.toString()) < diagnostics.indexOf(second.toString()));
    assertTrue(diagnostics.contains(
        "WFMT001 " + first + ":1:1 source is not canonically formatted"));

    assertEquals(0, Wheeler.execute(
        new String[] {"format", directory.toString()}, output, error));
    assertEquals("""
        classical class A {
          entry void main() {
            long value = 1;
          }
        }
        """, Files.readString(first));
    if (permissions != null) {
      assertEquals(permissions, Files.getPosixFilePermissions(first));
    }
    FileTime modified = Files.getLastModifiedTime(first);
    assertEquals(0, Wheeler.execute(
        new String[] {"format", directory.toString()}, output, error));
    assertEquals(modified, Files.getLastModifiedTime(first));

    ByteArrayOutputStream stdinOutput = new ByteArrayOutputStream();
    assertEquals(0, FormatCommand.execute(
        new String[] {"format", "--stdin"},
        new ByteArrayInputStream(compactFirst.getBytes(StandardCharsets.UTF_8)),
        new PrintStream(stdinOutput, true, StandardCharsets.UTF_8),
        error));
    assertEquals(Files.readString(first), stdinOutput.toString(StandardCharsets.UTF_8));
    assertEquals(1, FormatCommand.execute(
        new String[] {"format", "--stdin", "--check"},
        new ByteArrayInputStream(compactFirst.getBytes(StandardCharsets.UTF_8)),
        output,
        error));
    assertEquals("", errorBytes.toString(StandardCharsets.UTF_8));
  }

  @Test
  void formatCommandLeavesEveryFileUntouchedWhenValidationFails() throws Exception {
    Path directory = temporary.resolve("format-invalid");
    Files.createDirectories(directory);
    Path valid = directory.resolve("a.w");
    Path malformed = directory.resolve("b.w");
    String compact = "classical class A{entry void main(){}}";
    Files.writeString(valid, compact);
    Files.writeString(malformed, "classical class B { entry void main(] {} }");
    ByteArrayOutputStream errors = new ByteArrayOutputStream();

    assertEquals(1, Wheeler.execute(
        new String[] {"format", directory.toString()},
        new PrintStream(new ByteArrayOutputStream()),
        new PrintStream(errors, true, StandardCharsets.UTF_8)));
    assertEquals(compact, Files.readString(valid));
    assertTrue(errors.toString(StandardCharsets.UTF_8).contains(
        "WFMT002 " + malformed + ":1:1 unmatched delimiter ']'"));

    Path invalidUtf8 = directory.resolve("invalid.w");
    Files.delete(malformed);
    Files.write(invalidUtf8, new byte[] {(byte) 0xc0});
    errors.reset();
    assertEquals(1, Wheeler.execute(
        new String[] {"format", directory.toString()},
        new PrintStream(new ByteArrayOutputStream()),
        new PrintStream(errors, true, StandardCharsets.UTF_8)));
    assertEquals(compact, Files.readString(valid));
    assertTrue(errors.toString(StandardCharsets.UTF_8).contains("WFMT003"));
  }

}
