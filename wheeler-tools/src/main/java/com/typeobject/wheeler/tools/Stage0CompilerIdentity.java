package com.typeobject.wheeler.tools;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.net.URISyntaxException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.CodeSource;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.Comparator;
import java.util.HexFormat;
import java.util.List;
import java.util.TreeMap;
import java.util.jar.JarEntry;
import java.util.jar.JarFile;
import java.util.stream.Stream;

/** Content identity of the stage-0 compiler and its canonical bytecode implementation. */
final class Stage0CompilerIdentity {
  private Stage0CompilerIdentity() {}

  static String current() throws IOException {
    TreeMap<String, byte[]> entries = new TreeMap<>();
    collect("compiler", codeLocation(WheelerCompiler.class), entries);
    collect("core", codeLocation(Program.class), entries);
    ByteArrayOutputStream canonical = new ByteArrayOutputStream();
    field(canonical, "wheeler-stage0-compiler-identity-1");
    for (var entry : entries.entrySet()) {
      field(canonical, entry.getKey());
      field(canonical, HexFormat.of().formatHex(digest(entry.getValue())));
    }
    return HexFormat.of().formatHex(digest(canonical.toByteArray()));
  }

  private static Path codeLocation(Class<?> type) throws IOException {
    CodeSource source = type.getProtectionDomain().getCodeSource();
    if (source == null) {
      throw new IOException("Stage-0 compiler code source is unavailable: " + type.getName());
    }
    try {
      return Path.of(source.getLocation().toURI()).toRealPath();
    } catch (URISyntaxException exception) {
      throw new IOException("Invalid stage-0 compiler code source", exception);
    }
  }

  private static void collect(String domain, Path location, TreeMap<String, byte[]> entries)
      throws IOException {
    if (Files.isRegularFile(location)) {
      try (JarFile jar = new JarFile(location.toFile())) {
        List<JarEntry> jarEntries = jar.stream()
            .filter(entry -> !entry.isDirectory())
            .filter(entry -> entry.getName().endsWith(".class"))
            .sorted(Comparator.comparing(JarEntry::getName))
            .toList();
        for (JarEntry entry : jarEntries) {
          try (var input = jar.getInputStream(entry)) {
            entries.put(domain + "/" + entry.getName(), input.readAllBytes());
          }
        }
      }
      return;
    }
    if (!Files.isDirectory(location)) {
      throw new IOException("Stage-0 compiler code source is not physical: " + location);
    }
    try (Stream<Path> paths = Files.walk(location)) {
      for (Path path : paths.filter(Files::isRegularFile).sorted().toList()) {
        String relative = location.relativize(path).toString().replace(
            path.getFileSystem().getSeparator(), "/");
        if (relative.endsWith(".class")) {
          entries.put(domain + "/" + relative, Files.readAllBytes(path));
        }
      }
    }
  }

  private static byte[] digest(byte[] bytes) {
    try {
      return MessageDigest.getInstance("SHA-256").digest(bytes);
    } catch (NoSuchAlgorithmException exception) {
      throw new IllegalStateException("SHA-256 is unavailable", exception);
    }
  }

  private static void field(ByteArrayOutputStream output, String value) {
    byte[] bytes = value.getBytes(StandardCharsets.UTF_8);
    output.write(bytes.length);
    output.write(bytes.length >>> 8);
    output.write(bytes.length >>> 16);
    output.write(bytes.length >>> 24);
    output.writeBytes(bytes);
  }
}
