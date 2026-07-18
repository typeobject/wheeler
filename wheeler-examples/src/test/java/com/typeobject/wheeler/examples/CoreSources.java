package com.typeobject.wheeler.examples;

import java.nio.file.Path;

/** Resolves canonical Wheeler core sources without maintaining an example-side fork. */
final class CoreSources {
  private static final Path ROOT = Path.of("../wheeler-core/src/main/wheeler");

  private CoreSources() {}

  /** Returns one canonical core source path. */
  static Path path(String logicalPath) {
    return ROOT.resolve(logicalPath);
  }
}
