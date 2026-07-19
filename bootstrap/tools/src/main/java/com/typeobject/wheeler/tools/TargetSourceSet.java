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
      Map<String, byte[]> selected = selectedEntries(target, entries);
      ByteArrayOutputStream bytes = new ByteArrayOutputStream();
      try (DataOutputStream output = new DataOutputStream(bytes)) {
        output.writeInt(selected.size());
        for (Map.Entry<String, byte[]> entry : selected.entrySet()) {
          byte[] path = entry.getKey().getBytes(StandardCharsets.UTF_8);
          byte[] source = entry.getValue();
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
    for (Map.Entry<String, byte[]> entry : selectedEntries(target, entries).entrySet()) {
      try {
        result.put(entry.getKey(), StandardCharsets.UTF_8.newDecoder()
            .onMalformedInput(CodingErrorAction.REPORT)
            .onUnmappableCharacter(CodingErrorAction.REPORT)
            .decode(ByteBuffer.wrap(entry.getValue()))
            .toString());
      } catch (CharacterCodingException exception) {
        throw new PackageFormatException(
            "Target source is not strict UTF-8: " + entry.getKey(), exception);
      }
    }
    return Map.copyOf(result);
  }

  private static Map<String, byte[]> selectedEntries(
      PackageManifest.Target target, Map<String, byte[]> entries) {
    Map<String, byte[]> selected = new TreeMap<>();
    for (String selector : target.sources()) {
      byte[] exact = entries.get(selector);
      if (exact != null) {
        selected.put(selector, exact);
        continue;
      }
      String prefix = selector + "/";
      int before = selected.size();
      entries.forEach((path, bytes) -> {
        if (path.startsWith(prefix) && path.endsWith(".w")) {
          selected.put(path, bytes);
        }
      });
      if (selected.size() == before) {
        throw new PackageFormatException("Package is missing source selector " + selector);
      }
    }
    source(target.root(), selected);
    return Map.copyOf(selected);
  }

  private static byte[] source(String path, Map<String, byte[]> entries) {
    byte[] source = entries.get(path);
    if (source == null) {
      throw new PackageFormatException("Package is missing target source " + path);
    }
    return source;
  }
}
