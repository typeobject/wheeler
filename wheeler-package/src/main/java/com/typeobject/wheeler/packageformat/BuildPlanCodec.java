package com.typeobject.wheeler.packageformat;

import com.typeobject.wheeler.packageformat.BuildPlan.Node;
import com.typeobject.wheeler.packageformat.BuildPlan.PackageInput;
import com.typeobject.wheeler.packageformat.PackageManifest.Capability;
import com.typeobject.wheeler.packageformat.PackageManifest.TargetKind;
import java.io.ByteArrayOutputStream;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.charset.CharacterCodingException;
import java.nio.charset.CodingErrorAction;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HexFormat;
import java.util.List;

/** Strict canonical binary codec for content-addressed Wheeler build plans. */
public final class BuildPlanCodec {
  private static final byte[] MAGIC = {'W', 'P', 'L', 'N', 0, 0, 0, 1};
  private static final int MAX_BYTES = 16 * 1024 * 1024;
  private static final int MAX_STRING = 4096;
  private static final int MAX_ITEMS = 100_000;

  public byte[] encode(BuildPlan plan) {
    ByteArrayOutputStream body = new ByteArrayOutputStream();
    body.writeBytes(hashBytes(plan.workspaceIdentity()));
    body.writeBytes(hashBytes(plan.compilerIdentity()));
    string(body, plan.profile());
    integer(body, plan.nodes().size());
    for (Node node : plan.nodes()) {
      body.writeBytes(hashBytes(node.identity()));
      string(body, node.packageName());
      string(body, node.packageVersion());
      body.writeBytes(hashBytes(node.manifestIdentity()));
      string(body, node.targetName());
      integer(body, targetKindCode(node.targetKind()));
      body.writeBytes(hashBytes(node.sourceIdentity()));
      string(body, node.outputPath());
      integer(body, node.packageInputs().size());
      for (PackageInput input : node.packageInputs()) {
        string(body, input.name());
        body.writeBytes(hashBytes(input.archiveIdentity()));
      }
      integer(body, node.capabilities().size());
      for (Capability capability : node.capabilities()) {
        string(body, capability.name());
        string(body, capability.pattern());
      }
    }
    byte[] payload = body.toByteArray();
    ByteArrayOutputStream result = new ByteArrayOutputStream();
    result.writeBytes(MAGIC);
    integer(result, plan.schemaVersion());
    integer(result, payload.length);
    result.writeBytes(payload);
    result.writeBytes(digest(payload));
    byte[] encoded = result.toByteArray();
    if (encoded.length > MAX_BYTES) {
      throw new PackageFormatException("Build plan exceeds " + MAX_BYTES + " bytes");
    }
    return encoded;
  }

  public BuildPlan decode(byte[] encoded) {
    if (encoded.length > MAX_BYTES || encoded.length < MAGIC.length + 8 + 32) {
      throw new PackageFormatException("Invalid build plan length");
    }
    ByteBuffer input = ByteBuffer.wrap(encoded).order(ByteOrder.LITTLE_ENDIAN);
    byte[] magic = new byte[MAGIC.length];
    input.get(magic);
    if (!Arrays.equals(magic, MAGIC)) {
      throw new PackageFormatException("Invalid build plan magic");
    }
    int schema = input.getInt();
    int length = input.getInt();
    if (length < 0 || length != input.remaining() - 32) {
      throw new PackageFormatException("Invalid build plan payload length");
    }
    byte[] payload = new byte[length];
    input.get(payload);
    byte[] expected = new byte[32];
    input.get(expected);
    if (!MessageDigest.isEqual(expected, digest(payload))) {
      throw new PackageFormatException("Build plan digest mismatch");
    }
    ByteBuffer body = ByteBuffer.wrap(payload).order(ByteOrder.LITTLE_ENDIAN);
    String workspace = hash(body);
    String compiler = hash(body);
    String profile = string(body);
    int count = count(body, "node");
    List<Node> nodes = new ArrayList<>(count);
    for (int index = 0; index < count; index++) {
      String identity = hash(body);
      String packageName = string(body);
      String version = string(body);
      String manifest = hash(body);
      String targetName = string(body);
      TargetKind kind = targetKind(integer(body, "target kind"));
      String source = hash(body);
      String output = string(body);
      int inputCount = count(body, "package input");
      List<PackageInput> inputs = new ArrayList<>(inputCount);
      for (int item = 0; item < inputCount; item++) {
        inputs.add(new PackageInput(string(body), hash(body)));
      }
      int capabilityCount = count(body, "capability");
      List<Capability> capabilities = new ArrayList<>(capabilityCount);
      for (int item = 0; item < capabilityCount; item++) {
        capabilities.add(new Capability(string(body), string(body)));
      }
      nodes.add(new Node(
          identity,
          packageName,
          version,
          manifest,
          targetName,
          kind,
          source,
          output,
          inputs,
          capabilities));
    }
    if (body.hasRemaining()) {
      throw new PackageFormatException("Trailing build plan payload data");
    }
    BuildPlan plan = new BuildPlan(schema, workspace, compiler, profile, nodes);
    if (!Arrays.equals(encoded, encode(plan))) {
      throw new PackageFormatException("Build plan is not canonical");
    }
    return plan;
  }

  public String identity(byte[] canonicalPlan) {
    decode(canonicalPlan);
    return HexFormat.of().formatHex(digest(canonicalPlan));
  }

  private static int targetKindCode(TargetKind kind) {
    return switch (kind) {
      case LIBRARY -> 1;
      case BINARY -> 2;
      case TOOL -> 3;
      case TEST -> 4;
      case EXAMPLE -> 5;
    };
  }

  private static TargetKind targetKind(int code) {
    return switch (code) {
      case 1 -> TargetKind.LIBRARY;
      case 2 -> TargetKind.BINARY;
      case 3 -> TargetKind.TOOL;
      case 4 -> TargetKind.TEST;
      case 5 -> TargetKind.EXAMPLE;
      default -> throw new PackageFormatException("Invalid build target kind");
    };
  }

  private static String string(ByteBuffer input) {
    int length = integer(input, "string length");
    if (length < 0 || length > MAX_STRING || length > input.remaining()) {
      throw new PackageFormatException("Invalid build plan string length");
    }
    ByteBuffer bytes = input.slice(input.position(), length);
    input.position(input.position() + length);
    try {
      return StandardCharsets.UTF_8.newDecoder()
          .onMalformedInput(CodingErrorAction.REPORT)
          .onUnmappableCharacter(CodingErrorAction.REPORT)
          .decode(bytes)
          .toString();
    } catch (CharacterCodingException exception) {
      throw new PackageFormatException("Invalid build plan UTF-8", exception);
    }
  }

  private static void string(ByteArrayOutputStream output, String value) {
    byte[] bytes = value.getBytes(StandardCharsets.UTF_8);
    if (bytes.length > MAX_STRING) {
      throw new PackageFormatException("Build plan string is too long");
    }
    integer(output, bytes.length);
    output.writeBytes(bytes);
  }

  private static String hash(ByteBuffer input) {
    if (input.remaining() < 32) {
      throw new PackageFormatException("Truncated build plan identity");
    }
    byte[] bytes = new byte[32];
    input.get(bytes);
    return HexFormat.of().formatHex(bytes);
  }

  private static byte[] hashBytes(String value) {
    return HexFormat.of().parseHex(value);
  }

  private static int count(ByteBuffer input, String description) {
    int value = integer(input, description + " count");
    if (value < 0 || value > MAX_ITEMS) {
      throw new PackageFormatException("Invalid " + description + " count");
    }
    return value;
  }

  private static int integer(ByteBuffer input, String description) {
    if (input.remaining() < Integer.BYTES) {
      throw new PackageFormatException("Truncated build plan " + description);
    }
    return input.getInt();
  }

  private static void integer(ByteArrayOutputStream output, int value) {
    output.write(value);
    output.write(value >>> 8);
    output.write(value >>> 16);
    output.write(value >>> 24);
  }

  private static byte[] digest(byte[] bytes) {
    try {
      return MessageDigest.getInstance("SHA-256").digest(bytes);
    } catch (NoSuchAlgorithmException exception) {
      throw new IllegalStateException("SHA-256 is unavailable", exception);
    }
  }
}
