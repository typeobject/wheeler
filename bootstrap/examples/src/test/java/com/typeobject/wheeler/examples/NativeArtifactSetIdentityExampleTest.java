package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import java.io.ByteArrayOutputStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.MessageDigest;
import java.util.ArrayList;
import java.util.HexFormat;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Differential tests for bounded Wheeler-native bootstrap artifact-set identities. */
final class NativeArtifactSetIdentityExampleTest {
  private static final Path FIXTURE = Path.of(
      "../wheeler-conformance/src/main/wheeler/bootstrap/NativeArtifactSetIdentity.w");
  private static final String PROFILE = "wheeler.artifact-set/1";

  @Test
  void validatesTheClosedManifestBeforePublishingItsIdentity() throws Exception {
    Program program = program();
    List<Artifact> artifacts = List.of(
        new Artifact("compiler.wbc", "1".repeat(64), 504),
        new Artifact("runtime/vm.wbc", "a".repeat(64), 4_096));
    byte[] manifest = manifest(artifacts);
    VirtualMachine machine = vm(program, manifest);
    var initial = machine.snapshot();

    machine.run();

    byte[] expected = identity(artifacts);
    assertArrayEquals(expected, machine.hostOutput());
    assertEquals(2, machine.global("artifactCount"));
    assertEquals(canonical(artifacts).length, machine.global("canonicalLength"));
    assertEquals(9, machine.global("validationPhase"));
    assertEquals(1, machine.global("published"));
    while (machine.historySize() > 0) {
      machine.rewindOne();
    }
    assertEquals(initial, machine.snapshot());

    byte[] forgedIdentity = manifest.clone();
    forgedIdentity[forgedIdentity.length - 71] ^= 1;
    assertNoIdentity(program, forgedIdentity);
    assertNoIdentity(program, manifest(List.of(artifacts.get(1), artifacts.get(0))));
    assertNoIdentity(program, manifest(List.of(
        new Artifact("compiler.wbc", "A".repeat(64), 504))));
    assertNoIdentity(program, manifest(List.of(
        new Artifact("../compiler.wbc", "1".repeat(64), 504))));
    assertNoIdentity(program, new String(manifest, StandardCharsets.UTF_8)
        .replace("\"profile\"", "\"perhaps\"")
        .getBytes(StandardCharsets.UTF_8));
    assertNoIdentity(program, new byte[4_097]);

    List<Artifact> tooMany = new ArrayList<>();
    for (int index = 0; index < 9; index++) {
      tooMany.add(new Artifact("artifact-" + index + ".wbc", "b".repeat(64), index + 1));
    }
    List<Artifact> maximum = List.copyOf(tooMany.subList(0, 8));
    VirtualMachine maximumMachine = vm(program, manifest(maximum));
    maximumMachine.run();
    assertArrayEquals(identity(maximum), maximumMachine.hostOutput());
    assertEquals(8, maximumMachine.global("artifactCount"));
    assertNoIdentity(program, manifest(tooMany));
  }

  private static Program program() throws Exception {
    return new WheelerCompiler().compileModuleFiles(
        Map.of(
            "NativeArtifactSetIdentity.w", Files.readString(FIXTURE),
            "BootstrapSyntax.w", Files.readString(FIXTURE.resolveSibling("BootstrapSyntax.w")),
            "Sha256.w", CoreSources.read("crypto/Sha256.w")),
        "wheeler.conformance.bootstrap.artifact_set_identity");
  }

  private static VirtualMachine vm(Program program, byte[] manifest) {
    return VirtualMachine.withBinaryInput(program, manifest, 32);
  }

  private static void assertNoIdentity(Program program, byte[] manifest) {
    VirtualMachine machine = vm(program, manifest);
    assertThrows(VmTrap.class, machine::run);
    assertArrayEquals(new byte[32], machine.hostOutput());
    assertEquals(0, machine.global("published"));
  }

  private static byte[] manifest(List<Artifact> artifacts) throws Exception {
    StringBuilder json = new StringBuilder("{\"artifacts\":[");
    for (int index = 0; index < artifacts.size(); index++) {
      if (index > 0) {
        json.append(',');
      }
      Artifact artifact = artifacts.get(index);
      json.append("{\"bytes\":").append(artifact.bytes())
          .append(",\"path\":\"").append(artifact.path())
          .append("\",\"sha256\":\"").append(artifact.sha256()).append("\"}");
    }
    return json.append("],\"identity\":\"")
        .append(HexFormat.of().formatHex(identity(artifacts)))
        .append("\",\"profile\":\"").append(PROFILE).append("\"}\n")
        .toString().getBytes(StandardCharsets.UTF_8);
  }

  private static byte[] identity(List<Artifact> artifacts) throws Exception {
    return MessageDigest.getInstance("SHA-256").digest(canonical(artifacts));
  }

  private static byte[] canonical(List<Artifact> artifacts) {
    ByteArrayOutputStream bytes = new ByteArrayOutputStream();
    field(bytes, PROFILE);
    for (Artifact artifact : artifacts) {
      field(bytes, artifact.path());
      field(bytes, artifact.sha256());
      field(bytes, Long.toString(artifact.bytes()));
    }
    return bytes.toByteArray();
  }

  private static void field(ByteArrayOutputStream output, String value) {
    byte[] bytes = value.getBytes(StandardCharsets.UTF_8);
    output.write(bytes.length);
    output.write(bytes.length >>> 8);
    output.write(bytes.length >>> 16);
    output.write(bytes.length >>> 24);
    output.writeBytes(bytes);
  }

  private record Artifact(String path, String sha256, long bytes) {}
}
