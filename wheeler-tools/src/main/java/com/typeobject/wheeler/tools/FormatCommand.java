package com.typeobject.wheeler.tools;

import com.typeobject.wheeler.compiler.CompilerException;
import com.typeobject.wheeler.compiler.SourceFormatter;
import java.io.IOException;
import java.io.InputStream;
import java.io.PrintStream;
import java.nio.ByteBuffer;
import java.nio.channels.FileChannel;
import java.nio.charset.StandardCharsets;
import java.nio.file.AtomicMoveNotSupportedException;
import java.nio.file.Files;
import java.nio.file.LinkOption;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.nio.file.StandardOpenOption;
import java.nio.file.attribute.BasicFileAttributes;
import java.nio.file.attribute.PosixFilePermission;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Objects;
import java.util.Set;

/** Deterministic, bounded, all-input-first Wheeler source formatting command. */
final class FormatCommand {
  private FormatCommand() {}

  static int execute(
      String[] args,
      InputStream input,
      PrintStream out,
      PrintStream error) {
    Arguments parsed = parse(args, error);
    if (parsed == null) {
      return 2;
    }
    try {
      if (parsed.stdin()) {
        return formatStdin(parsed.check(), input, out, error);
      }
      return formatFiles(parsed, out, error);
    } catch (IOException exception) {
      error.println("WFMT003 <input>:1:1 " + exception.getMessage());
      return 1;
    }
  }

  private static int formatStdin(
      boolean check,
      InputStream input,
      PrintStream out,
      PrintStream error) throws IOException {
    String source = SourceCommandInputs.readStdin(input, "Formatter");
    String formatted;
    try {
      formatted = SourceFormatter.format(source);
    } catch (CompilerException exception) {
      syntaxDiagnostic("<stdin>", exception, error);
      return 1;
    }
    byte[] bytes = formatted.getBytes(StandardCharsets.UTF_8);
    requireOutputLimit(bytes, "<stdin>");
    if (check) {
      if (!formatted.equals(source)) {
        differenceDiagnostic("<stdin>", out);
        return 1;
      }
    } else {
      out.write(bytes);
      out.flush();
    }
    return 0;
  }

  private static int formatFiles(
      Arguments parsed,
      PrintStream out,
      PrintStream error) throws IOException {
    List<SourceCommandInputs.SourceFile> sources = SourceCommandInputs.collect(
        parsed.paths(), "Formatter");
    List<FormattedSource> formatted = new ArrayList<>(sources.size());
    boolean syntaxFailure = false;
    for (SourceCommandInputs.SourceFile source : sources) {
      try {
        String text = SourceFormatter.format(source.text());
        byte[] bytes = text.getBytes(StandardCharsets.UTF_8);
        requireOutputLimit(bytes, source.path().toString());
        formatted.add(new FormattedSource(source, bytes));
      } catch (CompilerException exception) {
        syntaxDiagnostic(source.path().toString(), exception, error);
        syntaxFailure = true;
      }
    }
    if (syntaxFailure) {
      return 1;
    }

    List<FormattedSource> changed = formatted.stream()
        .filter(source -> !Arrays.equals(source.source().bytes(), source.bytes()))
        .toList();
    if (parsed.check()) {
      changed.forEach(source -> differenceDiagnostic(source.source().path().toString(), out));
      return changed.isEmpty() ? 0 : 1;
    }
    try {
      publish(changed);
      return 0;
    } catch (IOException exception) {
      error.println("WFMT004 <output>:1:1 " + exception.getMessage());
      return 1;
    }
  }

  private static void requireOutputLimit(byte[] bytes, String path) throws IOException {
    if (bytes.length > SourceCommandInputs.MAX_SOURCE_BYTES) {
      throw new IOException("Formatted output exceeds 16 MiB: " + path);
    }
  }

  private static void publish(List<FormattedSource> changed) throws IOException {
    for (FormattedSource source : changed) {
      verifyUnchanged(source.source());
    }
    List<StagedSource> staged = new ArrayList<>(changed.size());
    try {
      for (FormattedSource source : changed) {
        staged.add(stage(source));
      }
      for (FormattedSource source : changed) {
        verifyUnchanged(source.source());
      }
      for (StagedSource source : staged) {
        publish(source);
      }
    } finally {
      for (StagedSource source : staged) {
        Files.deleteIfExists(source.temporary());
      }
    }
  }

  private static StagedSource stage(FormattedSource source) throws IOException {
    Path destination = source.source().path().toAbsolutePath().normalize();
    Path parent = destination.getParent();
    if (parent == null
        || !Files.isDirectory(parent, LinkOption.NOFOLLOW_LINKS)
        || Files.isSymbolicLink(parent)) {
      throw new IOException("Formatter output has no physical parent: " + destination);
    }
    Set<PosixFilePermission> permissions = posixPermissions(destination);
    Path temporary = Files.createTempFile(parent, ".wfmt-", ".tmp");
    boolean accepted = false;
    try {
      try (FileChannel channel = FileChannel.open(
          temporary, StandardOpenOption.WRITE, StandardOpenOption.TRUNCATE_EXISTING)) {
        ByteBuffer buffer = ByteBuffer.wrap(source.bytes());
        while (buffer.hasRemaining()) {
          channel.write(buffer);
        }
        if (permissions != null) {
          Files.setPosixFilePermissions(temporary, permissions);
        }
        channel.force(true);
      }
      if (!Arrays.equals(Files.readAllBytes(temporary), source.bytes())) {
        throw new IOException("Formatter temporary-file validation failed: " + destination);
      }
      accepted = true;
      return new StagedSource(source, temporary);
    } finally {
      if (!accepted) {
        Files.deleteIfExists(temporary);
      }
    }
  }

  private static Set<PosixFilePermission> posixPermissions(Path source) throws IOException {
    if (!Files.getFileStore(source).supportsFileAttributeView("posix")) {
      return null;
    }
    return Set.copyOf(Files.getPosixFilePermissions(source, LinkOption.NOFOLLOW_LINKS));
  }

  private static void publish(StagedSource staged) throws IOException {
    FormattedSource source = staged.source();
    verifyUnchanged(source.source());
    Path destination = source.source().path().toAbsolutePath().normalize();
    try {
      Files.move(
          staged.temporary(),
          destination,
          StandardCopyOption.ATOMIC_MOVE,
          StandardCopyOption.REPLACE_EXISTING);
    } catch (AtomicMoveNotSupportedException exception) {
      throw new IOException("Atomic formatter replacement is unavailable: " + destination, exception);
    }
    if (!Files.isRegularFile(destination, LinkOption.NOFOLLOW_LINKS)
        || Files.isSymbolicLink(destination)
        || !Arrays.equals(Files.readAllBytes(destination), source.bytes())) {
      throw new IOException("Formatter replacement validation failed: " + destination);
    }
  }

  private static void verifyUnchanged(SourceCommandInputs.SourceFile source) throws IOException {
    Path path = source.path();
    if (Files.isSymbolicLink(path)) {
      throw new IOException("Formatter input became a symbolic link: " + path);
    }
    BasicFileAttributes attributes = Files.readAttributes(
        path, BasicFileAttributes.class, LinkOption.NOFOLLOW_LINKS);
    if (!attributes.isRegularFile()
        || source.fileKey() != null && !Objects.equals(source.fileKey(), attributes.fileKey())
        || !Arrays.equals(source.bytes(), Files.readAllBytes(path))) {
      throw new IOException("Formatter input changed before publication: " + path);
    }
  }

  private static void differenceDiagnostic(String path, PrintStream out) {
    out.println("WFMT001 " + path + ":1:1 source is not canonically formatted");
  }

  private static void syntaxDiagnostic(
      String path, CompilerException exception, PrintStream error) {
    String prefix = "line " + exception.line() + ": ";
    String message = exception.getMessage().startsWith(prefix)
        ? exception.getMessage().substring(prefix.length())
        : exception.getMessage();
    error.println("WFMT002 " + path + ":" + exception.line() + ":1 " + message);
  }

  private static Arguments parse(String[] args, PrintStream error) {
    boolean check = false;
    boolean stdin = false;
    List<String> paths = new ArrayList<>();
    for (int index = 1; index < args.length; index++) {
      switch (args[index]) {
        case "--check" -> {
          if (check) {
            return usage(error);
          }
          check = true;
        }
        case "--stdin" -> {
          if (stdin) {
            return usage(error);
          }
          stdin = true;
        }
        default -> {
          if (args[index].startsWith("--")) {
            return usage(error);
          }
          paths.add(args[index]);
        }
      }
    }
    if (stdin == !paths.isEmpty()) {
      return usage(error);
    }
    return new Arguments(check, stdin, List.copyOf(paths));
  }

  private static Arguments usage(PrintStream error) {
    error.println(
        "Usage: wheeler format [--check] <file-or-directory>... | --stdin [--check]");
    return null;
  }

  private record Arguments(boolean check, boolean stdin, List<String> paths) {}

  private record FormattedSource(
      SourceCommandInputs.SourceFile source, byte[] bytes) {
    private FormattedSource {
      bytes = Arrays.copyOf(bytes, bytes.length);
    }

    @Override
    public byte[] bytes() {
      return Arrays.copyOf(bytes, bytes.length);
    }
  }

  private record StagedSource(FormattedSource source, Path temporary) {}
}
