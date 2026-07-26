package com.typeobject.wheeler.compiler;

import java.nio.charset.StandardCharsets;
import java.util.Arrays;
import java.util.List;

/** Read-only stage-0 inspection of a source file's canonical module header. */
public final class SourceModuleInspection {
  private SourceModuleInspection() {}

  /** Parses the exact module name and sorted direct imports without compiling the source body. */
  public static Header inspect(byte[] source) {
    String text = new String(source, StandardCharsets.UTF_8);
    if (!Arrays.equals(source, text.getBytes(StandardCharsets.UTF_8))) {
      throw new CompilerException(0, "Module source is not strict UTF-8");
    }
    SourceModuleHeaderParser.Header header = SourceModuleHeaderParser.parseSource(text);
    if (header.moduleName() == null) {
      throw new CompilerException(0, "Bootstrap module source has no module declaration");
    }
    return new Header(header.moduleName(), header.imports());
  }

  /** Canonical module declaration and direct imports recovered from source bytes. */
  public record Header(String name, List<String> imports) {
    public Header {
      imports = List.copyOf(imports);
    }
  }
}
