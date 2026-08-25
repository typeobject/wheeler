package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.packageformat.ApplicationCapsule;
import com.typeobject.wheeler.packageformat.CapsuleEntry;
import com.typeobject.wheeler.packageformat.CapsulePackageReceipt;
import com.typeobject.wheeler.packageformat.CapsuleRoot;
import com.typeobject.wheeler.packageformat.NativeImagePlan;
import com.typeobject.wheeler.packageformat.PlatformAbi;
import com.typeobject.wheeler.runtime.ApplicationCapsuleVerifier;
import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Builds one closed application capsule and binds it into a native image plan. */
final class ApplicationCapsuleExampleTest {
  @Test
  void bindsOneVerifiedCapsuleWithoutAdjacentFiles() {
    String source = """
        module example.hello;
        classical class Hello {
          entry void main() {}
        }
        """;
    byte[] artifact = new WheelerCompiler().compileModulesToBytecode(
        Map.of("example.hello", source), "example.hello");
    byte[] greeting = "hello from Wheeler\n".getBytes(StandardCharsets.UTF_8);
    CapsuleRoot root = new CapsuleRoot(
        hash(1),
        "hello",
        "bin/hello.wbc",
        "example.hello::main",
        hash(2),
        hash(3),
        hash(4),
        hash(5),
        hash(6),
        hash(7),
        NativeImagePlan.RuntimeMode.EMBEDDED_VM,
        List.of("io:stdout/1"));
    CapsulePackageReceipt receipt = new CapsulePackageReceipt(
        hash(8),
        "wheeler.hello@1.0.0",
        hash(9),
        "release",
        hash(10),
        hash(11),
        "hello",
        hash(1));
    CapsuleEntry wbc = new CapsuleEntry(
        CapsuleEntry.Kind.WBC,
        "bin/hello.wbc",
        4096,
        CapsuleEntry.REQUIRED | CapsuleEntry.STARTUP,
        artifact);
    CapsuleEntry resource = new CapsuleEntry(
        CapsuleEntry.Kind.RESOURCE,
        "resources/greeting.txt",
        64,
        CapsuleEntry.REQUIRED,
        greeting);
    ApplicationCapsule capsule =
        new ApplicationCapsule(root, List.of(receipt), List.of(resource, wbc));

    ApplicationCapsuleVerifier.VerifiedCapsule verified =
        ApplicationCapsuleVerifier.verify(capsule.canonicalBytes());
    NativeImagePlan image = new NativeImagePlan(
        PlatformAbi.Format.ELF,
        "aarch64-unknown-linux-gnu",
        NativeImagePlan.RuntimeMode.EMBEDDED_VM,
        true,
        true,
        hash(12),
        root.platformAbi(),
        verified.capsule().identity(),
        hash(13),
        hash(14),
        hash(15),
        hash(16),
        hash(17),
        hash(18),
        hash(19));

    assertEquals(verified.capsule().identity(), image.capsule());
    assertEquals("bin/hello.wbc", verified.capsule().entries().getFirst().name());
    assertEquals("example.hello::main",
        verified.rootProgram().function(verified.rootProgram().entryFunctionId()).name());
    assertArrayEquals(greeting, verified.capsule().entries().get(1).bytes());
  }

  private static String hash(int value) {
    return "%064x".formatted(value);
  }
}
