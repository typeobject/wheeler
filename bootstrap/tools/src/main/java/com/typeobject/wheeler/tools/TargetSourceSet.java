package com.typeobject.wheeler.tools;

import com.typeobject.wheeler.packageformat.PackageFormatException;
import com.typeobject.wheeler.packageformat.PackageManifest;
import java.io.ByteArrayOutputStream;
import java.io.DataOutputStream;
import java.io.IOException;
import java.nio.ByteBuffer;
import java.nio.charset.CharacterCodingException;
import java.nio.charset.CodingErrorAction;
import java.nio.charset.StandardCharsets;
import java.util.Map;
import java.util.TreeMap;

/** Canonical target-source collection shared by local and locked package builds. */
final class TargetSourceSet {
  private TargetSourceSet() {}

  static byte[] canonicalInput(
      PackageManifest.Target target, Map<String, byte[]> entries) {
    if (!target.modular()) {
      return source(target.root(), entries);
    }
    try {
      ByteArrayOutputStream bytes = new ByteArrayOutputStream();
      try (DataOutputStream output = new DataOutputStream(bytes)) {
        output.writeInt(target.sources().size());
        for (String logicalPath : target.sources()) {
          byte[] path = logicalPath.getBytes(StandardCharsets.UTF_8);
          byte[] source = source(logicalPath, entries);
          output.writeInt(path.length);
          output.write(path);
          output.writeInt(source.length);
          output.write(source);
        }
      }
      return bytes.toByteArray();
    } catch (IOException exception) {
      throw new IllegalStateException("In-memory source encoding failed", exception);
    }
  }

  static Map<String, String> strictText(
      PackageManifest.Target target, Map<String, byte[]> entries) {
    Map<String, String> result = new TreeMap<>();
    for (String logicalPath : target.sources()) {
      byte[] source = source(logicalPath, entries);
      try {
        result.put(logicalPath, StandardCharsets.UTF_8.newDecoder()
            .onMalformedInput(CodingErrorAction.REPORT)
            .onUnmappableCharacter(CodingErrorAction.REPORT)
            .decode(ByteBuffer.wrap(source))
            .toString());
      } catch (CharacterCodingException exception) {
        throw new PackageFormatException(
            "Target source is not strict UTF-8: " + logicalPath, exception);
      }
    }
    return Map.copyOf(result);
  }

  private static byte[] source(String path, Map<String, byte[]> entries) {
    byte[] source = entries.get(path);
    if (source == null) {
      throw new PackageFormatException("Package is missing target source " + path);
    }
    return source;
  }
}
