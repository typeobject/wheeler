package com.typeobject.wheeler.examples;

import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.io.ByteArrayOutputStream;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.charset.StandardCharsets;
import java.util.List;

/** Writes the canonical native test-runner input used by package examples. */
final class NativeTestRunnerInput {
  private NativeTestRunnerInput() {}

  static byte[] descriptor(
      String manifest, List<NativeTestSourcePlan.Source> sources, byte[] artifact) {
    return descriptor(manifest, sources, artifact, "test::entry");
  }

  static byte[] descriptor(
      String manifest,
      List<NativeTestSourcePlan.Source> sources,
      byte[] artifact,
      String caseName) {
    return descriptors(manifest, sources, List.of(new NamedArtifact(caseName, artifact)));
  }

  static byte[] descriptors(
      String manifest,
      List<NativeTestSourcePlan.Source> sources,
      List<NamedArtifact> cases) {
    return descriptors(manifest, sources, cases, List.of());
  }

  static byte[] descriptors(
      String manifest,
      List<NativeTestSourcePlan.Source> sources,
      List<NamedArtifact> cases,
      List<String> selectedTags) {
    return descriptorTransport(manifest, sources, cases, selectedTags, false);
  }

  static byte[] discoveredDescriptors(
      String manifest,
      List<NativeTestSourcePlan.Source> sources,
      List<String> selectedTags) {
    return descriptorTransport(manifest, sources, List.of(), selectedTags, true);
  }

  static byte[] execute(Program runner, byte[] input) {
    VirtualMachine machine = VirtualMachine.withBinaryInput(runner, input, 39);
    CompilerMachineRunner.runWithoutRewindHistory(machine);
    return machine.hostOutput();
  }

  private static byte[] descriptorTransport(
      String manifest,
      List<NativeTestSourcePlan.Source> sources,
      List<NamedArtifact> cases,
      List<String> selectedTags,
      boolean discoverDescriptors) {
    return descriptorTransport(
        manifest,
        sources,
        cases,
        selectedTags,
        discoverDescriptors,
        NativeTestManifestInput.emptyLock(manifest));
  }

  private static byte[] descriptorTransport(
      String manifest,
      List<NativeTestSourcePlan.Source> sources,
      List<NamedArtifact> cases,
      List<String> selectedTags,
      boolean discoverDescriptors,
      byte[] lock) {
    byte[] plan = NativeTestSourcePlan.write(sources);
    ByteArrayOutputStream input = new ByteArrayOutputStream();
    input.writeBytes(ByteBuffer.allocate(4).order(ByteOrder.LITTLE_ENDIAN)
        .putShort((short) 0).putShort((short) 1).array());
    writeShortText(input, "pkg");
    writeShortText(input, "1.0.0");
    writeShortText(input, "test");
    writeBytes(input, manifest.getBytes(StandardCharsets.UTF_8));
    writeBytes(input, lock);
    input.write(0);
    writeBytes(input, plan);
    input.write(selectedTags.size());
    selectedTags.forEach(tag -> writeShortText(input, tag));
    input.write(discoverDescriptors ? 255 : cases.size());
    for (NamedArtifact testcase : cases) {
      writeShortText(input, testcase.name());
      writeBytes(input, testcase.artifact());
    }
    return input.toByteArray();
  }

  private static void writeShortText(ByteArrayOutputStream output, String text) {
    byte[] bytes = text.getBytes(StandardCharsets.UTF_8);
    output.write(bytes.length);
    output.writeBytes(bytes);
  }

  private static void writeBytes(ByteArrayOutputStream output, byte[] bytes) {
    output.writeBytes(ByteBuffer.allocate(4).order(ByteOrder.LITTLE_ENDIAN)
        .putInt(bytes.length).array());
    output.writeBytes(bytes);
  }

  record NamedArtifact(String name, byte[] artifact) {}
}
