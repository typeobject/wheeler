package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import com.typeobject.wheeler.packageformat.PackageArchive;
import com.typeobject.wheeler.packageformat.PackageManifestParser;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.MessageDigest;
import java.util.Map;
import org.junit.jupiter.api.Test;

class NativeArchiveExampleTest {
  @Test
  void wheelerInspectsOuterAndEntryDigestCheckedArchive() throws Exception {
    Path root = Path.of("src/main/wheeler");
    Program inspector = new WheelerCompiler().compileModuleFiles(
        Map.of(
            "Archive.w", Files.readString(root.resolve("packages/Archive.w")),
            "Binary.w", Files.readString(root.resolve("packages/Binary.w")),
            "NativeArchive.w", Files.readString(root.resolve("NativeArchive.w")),
            "Sha256.w", Files.readString(root.resolve("crypto/Sha256.w"))),
        "examples.packages.archive_main");
    String manifestText =
        "package \"demo.archive\" version \"1.0.0\" profile \"bootstrap-1\";\n"
            + "target example \"main\" root \"src/Main.w\";\n";
    var manifest = new PackageManifestParser().parse(manifestText);
    byte[] encoded = new PackageArchive().encode(
        manifest, Map.of("src/Main.w", new byte[] {1, 2, 3, (byte) 255}));
    VirtualMachine machine = VirtualMachine.withBinaryInput(inspector, encoded);
    var initial = machine.snapshot();

    machine.run();

    assertEquals(103, machine.global("manifestLength"));
    assertEquals(1, machine.global("entryCount"));
    assertEquals(10, machine.global("pathLength"));
    assertEquals(4, machine.global("dataLength"));
    assertEquals(encoded.length, machine.global("finalLength"));
    while (machine.historySize() > 0) {
      machine.rewindOne();
    }
    assertEquals(initial, machine.snapshot());
    new PackageArchive().decode(encoded);

    byte[] badOuterDigest = encoded.clone();
    badOuterDigest[badOuterDigest.length - 1] ^= 1;
    assertRejected(inspector, badOuterDigest);
    byte[] badEntryData = encoded.clone();
    badEntryData[dataStart(badEntryData)] ^= 1;
    resignOuter(badEntryData);
    assertRejected(inspector, badEntryData);
    byte[] badPath = encoded.clone();
    int path = pathStart(badPath);
    badPath[path] = '.';
    badPath[path + 1] = '.';
    badPath[path + 2] = '/';
    resignOuter(badPath);
    assertRejected(inspector, badPath);
  }

  private static void assertRejected(Program inspector, byte[] archive) {
    VirtualMachine machine = VirtualMachine.withBinaryInput(inspector, archive);
    assertThrows(VmTrap.class, machine::run);
  }

  private static int pathStart(byte[] archive) {
    ByteBuffer bytes = ByteBuffer.wrap(archive).order(ByteOrder.LITTLE_ENDIAN);
    return 16 + bytes.getInt(8) + 12;
  }

  private static int dataStart(byte[] archive) {
    ByteBuffer bytes = ByteBuffer.wrap(archive).order(ByteOrder.LITTLE_ENDIAN);
    int path = pathStart(archive);
    return path + bytes.getInt(path - 12) + 32;
  }

  private static void resignOuter(byte[] archive) throws Exception {
    int payloadLength = archive.length - 32;
    byte[] digest = MessageDigest.getInstance("SHA-256")
        .digest(java.util.Arrays.copyOf(archive, payloadLength));
    System.arraycopy(digest, 0, archive, payloadLength, digest.length);
  }
}
