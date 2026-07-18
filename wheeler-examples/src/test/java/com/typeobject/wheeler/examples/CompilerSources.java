package com.typeobject.wheeler.examples;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;

/** Resolves canonical Wheeler compiler sources without lending the examples a private copy. */
final class CompilerSources {
  private static final Path ROOT = Path.of("../wheeler-compiler/src/main/wheeler");

  private CompilerSources() {}

  /** Returns one canonical compiler source path. */
  static Path path(String logicalPath) {
    return ROOT.resolve(logicalPath);
  }

  /** Reads one canonical compiler source as strict host text. */
  static String read(String logicalPath) throws IOException {
    return Files.readString(path(logicalPath));
  }
}
