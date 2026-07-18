package com.typeobject.wheeler.tools;

import java.io.IOException;
import java.io.InputStream;
import java.nio.ByteBuffer;
import java.nio.charset.CharacterCodingException;
import java.nio.charset.CodingErrorAction;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.LinkOption;
import java.nio.file.Path;
import java.nio.file.attribute.BasicFileAttributes;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Comparator;
import java.util.HashSet;
import java.util.List;
import java.util.Objects;
import java.util.Set;

/** Shared bounded, strict-UTF-8 input boundary for Wheeler source commands. */
final class SourceCommandInputs {
  static final int MAX_SOURCE_BYTES = 16 * 1024 * 1024;
  static final int MAX_SOURCE_FILES = 65_535;

  private SourceCommandInputs() {}

  static List<SourceFile> collect(List<String> arguments, String commandName) throws IOException {
    List<Path> paths = collectPaths(arguments, commandName);
    List<SourceFile> result = new ArrayList<>(paths.size());
    for (Path path : paths) {
      result.add(read(path, commandName));
    }
    return List.copyOf(result);
  }

  static String readStdin(InputStream input, String commandName) throws IOException {
    byte[] bytes = input.readNBytes(MAX_SOURCE_BYTES + 1);
    if (bytes.length > MAX_SOURCE_BYTES) {
      throw new IOException(commandName + " stdin exceeds 16 MiB");
    }
    return decode(bytes, "<stdin>", commandName);
  }

  private static List<Path> collectPaths(
      List<String> arguments, String commandName) throws IOException {
    List<Path> result = new ArrayList<>();
    Set<Path> identities = new HashSet<>();
    for (String argument : arguments) {
      Path requested = Path.of(argument).normalize();
      requirePhysical(requested, commandName);
      if (Files.isRegularFile(requested, LinkOption.NOFOLLOW_LINKS)) {
        addSource(requested, identities, result, commandName);
      } else if (Files.isDirectory(requested, LinkOption.NOFOLLOW_LINKS)) {
        List<Path> walked;
        try (var paths = Files.walk(requested)) {
          walked = paths.toList();
        }
        for (Path path : walked) {
          if (Files.isSymbolicLink(path)) {
            throw new IOException(commandName + " input contains a symbolic link: " + path);
          }
          if (Files.isRegularFile(path, LinkOption.NOFOLLOW_LINKS)
              && path.getFileName().toString().endsWith(".w")) {
            addSource(path.normalize(), identities, result, commandName);
          }
        }
      } else {
        throw new IOException(
            commandName + " input is not a physical file or directory: " + requested);
      }
    }
    result.sort(Comparator.comparing(Path::toString));
    return List.copyOf(result);
  }

  private static void requirePhysical(Path path, String commandName) throws IOException {
    if (Files.isSymbolicLink(path)) {
      throw new IOException(commandName + " input must not be a symbolic link: " + path);
    }
  }

  private static void addSource(
      Path source,
      Set<Path> identities,
      List<Path> result,
      String commandName) throws IOException {
    if (result.size() >= MAX_SOURCE_FILES) {
      throw new IOException(commandName + " input exceeds 65,535 source files");
    }
    if (!source.getFileName().toString().endsWith(".w")) {
      throw new IOException(commandName + " input is not a .w source: " + source);
    }
    Path identity = source.toRealPath();
    if (!identities.add(identity)) {
      throw new IOException("Duplicate " + commandName.toLowerCase() + " input: " + source);
    }
    result.add(source);
  }

  private static SourceFile read(Path path, String commandName) throws IOException {
    Path physical = path.toRealPath();
    BasicFileAttributes before = attributes(physical, commandName);
    if (before.size() > MAX_SOURCE_BYTES) {
      throw new IOException(commandName + " input exceeds 16 MiB: " + path);
    }
    byte[] bytes = Files.readAllBytes(physical);
    BasicFileAttributes after = attributes(physical, commandName);
    if (bytes.length > MAX_SOURCE_BYTES) {
      throw new IOException(commandName + " input exceeds 16 MiB: " + path);
    }
    if (!sameFile(before, after) || after.size() != bytes.length) {
      throw new IOException(commandName + " input changed while it was read: " + path);
    }
    return new SourceFile(
        path, physical, bytes, decode(bytes, path.toString(), commandName), after.fileKey());
  }

  private static BasicFileAttributes attributes(Path path, String commandName) throws IOException {
    if (Files.isSymbolicLink(path)) {
      throw new IOException(commandName + " input became a symbolic link: " + path);
    }
    BasicFileAttributes result = Files.readAttributes(
        path, BasicFileAttributes.class, LinkOption.NOFOLLOW_LINKS);
    if (!result.isRegularFile()) {
      throw new IOException(commandName + " input is not a physical file: " + path);
    }
    return result;
  }

  private static boolean sameFile(BasicFileAttributes left, BasicFileAttributes right) {
    Object leftKey = left.fileKey();
    Object rightKey = right.fileKey();
    return leftKey == null || rightKey == null
        ? left.size() == right.size()
            && left.lastModifiedTime().equals(right.lastModifiedTime())
        : Objects.equals(leftKey, rightKey);
  }

  private static String decode(byte[] bytes, String source, String commandName) throws IOException {
    try {
      return StandardCharsets.UTF_8.newDecoder()
          .onMalformedInput(CodingErrorAction.REPORT)
          .onUnmappableCharacter(CodingErrorAction.REPORT)
          .decode(ByteBuffer.wrap(bytes))
          .toString();
    } catch (CharacterCodingException exception) {
      throw new IOException(commandName + " input is not strict UTF-8: " + source, exception);
    }
  }

  record SourceFile(Path path, Path physicalPath, byte[] bytes, String text, Object fileKey) {
    SourceFile {
      if (path == null || physicalPath == null) {
        throw new IllegalArgumentException("Source paths are required");
      }
      bytes = Arrays.copyOf(bytes, bytes.length);
    }

    @Override
    public byte[] bytes() {
      return Arrays.copyOf(bytes, bytes.length);
    }
  }
}
