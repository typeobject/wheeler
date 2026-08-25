package com.typeobject.wheeler.tools;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeException;
import com.typeobject.wheeler.core.bytecode.BytecodeReader;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.packageformat.ApplicationCapsule;
import com.typeobject.wheeler.packageformat.CapsuleEntry;
import com.typeobject.wheeler.packageformat.CapsulePackageReceipt;
import com.typeobject.wheeler.packageformat.CapsuleRoot;
import com.typeobject.wheeler.packageformat.NativeImagePlan;
import com.typeobject.wheeler.packageformat.PackageFormatException;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.PrintStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

/** Command evidence for nonexecuting application capsule inspection and verification. */
final class ImageCommandTest {
  @TempDir
  Path temporary;

  @Test
  void inspectsEveryRootReceiptAndEntryIdentityDeterministically() throws Exception {
    ApplicationCapsule capsule = capsule(validWbc(), null);
    Path file = write("hello.capsule", capsule.canonicalBytes());
    CommandResult first = execute("image", "inspect", file.toString());
    CommandResult second = execute("image", "inspect", file.toString());

    assertEquals(0, first.status());
    assertEquals(first.output(), second.output());
    assertTrue(first.output().startsWith("{\n  \"schema\": 1,\n"));
    assertTrue(first.output().contains("\"identity\": \"" + capsule.identity() + "\""));
    assertTrue(first.output().contains("\"entry\": \"example.hello::main\""));
    assertTrue(first.output().contains("\"coordinate\": \"wheeler.hello@1.0.0\""));
    assertTrue(first.output().contains("\"name\": \"resources/greeting.txt\""));
    assertEquals("", first.error());
  }

  @Test
  void verifiesEveryWbcAndTheExactRootFunction() throws Exception {
    byte[] wbc = validWbc();
    ApplicationCapsule capsule = capsule(wbc, null);
    Path file = write("hello.capsule", capsule.canonicalBytes());
    CommandResult result = execute("image", "verify", file.toString());

    assertEquals(0, result.status());
    assertEquals(
        "verified capsule " + capsule.identity() + " (2 entries, 1 WBC artifacts)\n",
        result.output());
    assertEquals("", result.error());

    CapsuleRoot wrongRoot = root("example.hello::other");
    Path wrong = write(
        "wrong-root.capsule",
        new ApplicationCapsule(wrongRoot, receipts(), entries(wbc)).canonicalBytes());
    assertThrows(
        IllegalArgumentException.class,
        () -> execute("image", "verify", wrong.toString()));
  }

  @Test
  void inspectionDoesNotLaunderMalformedWbcOrCapsuleBytes() throws Exception {
    ApplicationCapsule malformedWbc = capsule(new byte[] {'W', 'B', 'C', 1}, "fixture::main");
    Path malformed = write("malformed-wbc.capsule", malformedWbc.canonicalBytes());

    assertEquals(0, execute("image", "inspect", malformed.toString()).status());
    assertThrows(
        BytecodeException.class,
        () -> execute("image", "verify", malformed.toString()));

    byte[] corrupted = malformedWbc.canonicalBytes();
    corrupted[corrupted.length - 1] ^= 1;
    Path damaged = write("damaged.capsule", corrupted);
    assertThrows(
        PackageFormatException.class,
        () -> execute("image", "inspect", damaged.toString()));
  }

  @Test
  void rejectsUsageAndNonphysicalInput() throws Exception {
    CommandResult usage = execute("image", "run", "missing.capsule");
    assertEquals(2, usage.status());
    assertEquals("Usage: wheeler image <inspect|verify> <application.capsule>\n", usage.error());

    Path directory = Files.createDirectory(temporary.resolve("directory.capsule"));
    assertThrows(
        IOException.class,
        () -> execute("image", "inspect", directory.toString()));
  }

  private ApplicationCapsule capsule(byte[] wbc, String entryOverride) {
    Program program = null;
    if (entryOverride == null) {
      program = new BytecodeReader().read(wbc);
    }
    String entry = entryOverride == null
        ? program.function(program.entryFunctionId()).name()
        : entryOverride;
    return new ApplicationCapsule(root(entry), receipts(), entries(wbc));
  }

  private CapsuleRoot root(String entry) {
    return new CapsuleRoot(
        hash(1),
        "hello",
        "bin/hello.wbc",
        entry,
        hash(2),
        hash(3),
        hash(4),
        hash(5),
        hash(6),
        hash(7),
        NativeImagePlan.RuntimeMode.EMBEDDED_VM,
        List.of("io:stdout/1"));
  }

  private static List<CapsulePackageReceipt> receipts() {
    return List.of(new CapsulePackageReceipt(
        hash(8),
        "wheeler.hello@1.0.0",
        hash(9),
        "release",
        hash(10),
        hash(11),
        "hello",
        hash(1)));
  }

  private static List<CapsuleEntry> entries(byte[] wbc) {
    return List.of(
        new CapsuleEntry(
            CapsuleEntry.Kind.RESOURCE,
            "resources/greeting.txt",
            64,
            CapsuleEntry.REQUIRED,
            "hello\n".getBytes(StandardCharsets.UTF_8)),
        new CapsuleEntry(
            CapsuleEntry.Kind.WBC,
            "bin/hello.wbc",
            4096,
            CapsuleEntry.REQUIRED | CapsuleEntry.STARTUP,
            wbc));
  }

  private static byte[] validWbc() {
    String source = """
        module example.hello;
        classical class Hello {
          entry void main() {}
        }
        """;
    return new WheelerCompiler().compileModulesToBytecode(
        Map.of("example.hello", source), "example.hello");
  }

  private Path write(String name, byte[] bytes) throws IOException {
    Path path = temporary.resolve(name);
    Files.write(path, bytes);
    return path;
  }

  private static CommandResult execute(String... arguments) throws Exception {
    ByteArrayOutputStream outputBytes = new ByteArrayOutputStream();
    ByteArrayOutputStream errorBytes = new ByteArrayOutputStream();
    try (PrintStream output = new PrintStream(outputBytes, true, StandardCharsets.UTF_8);
        PrintStream error = new PrintStream(errorBytes, true, StandardCharsets.UTF_8)) {
      int status = Wheeler.execute(arguments, output, error);
      return new CommandResult(
          status,
          outputBytes.toString(StandardCharsets.UTF_8),
          errorBytes.toString(StandardCharsets.UTF_8));
    }
  }

  private static String hash(int value) {
    return "%064x".formatted(value);
  }

  private record CommandResult(int status, String output, String error) {}
}
