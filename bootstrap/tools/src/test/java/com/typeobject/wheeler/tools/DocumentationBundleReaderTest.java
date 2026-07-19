package com.typeobject.wheeler.tools;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.packageformat.PackageFormatException;
import java.io.ByteArrayOutputStream;
import java.io.PrintStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

/** Malformed-corpus checks for the independent static-renderer bundle boundary. */
class DocumentationBundleReaderTest {
  @TempDir
  Path temporary;

  @Test
  void rejectsDigestProfileAndExactFileSetViolations() throws Exception {
    Path manuals = temporary.resolve("manuals");
    Path sources = temporary.resolve("sources");
    Files.createDirectories(manuals);
    Files.createDirectories(sources);
    Files.writeString(manuals.resolve("intro.md"), "# Introduction\n\nBounded prose.\n");
    Files.writeString(sources.resolve("Api.w"), """
        //! Documents one public fixture.
        module fixture.api;
        classical class Api {
            /// Returns one.
            public long one() { return 1; }
        }
        """);
    Path bundle = temporary.resolve("bundle");
    assertEquals(0, Wheeler.execute(
        new String[] {
            "docs", manuals.toString(), "--wheeler", sources.toString(),
            "-o", bundle.toString()
        },
        new PrintStream(new ByteArrayOutputStream()),
        new PrintStream(new ByteArrayOutputStream())));
    assertEquals(1, DocumentationBundleReader.read(bundle).pages().size());

    Path page = bundle.resolve("pages/intro.md");
    String originalPage = Files.readString(page);
    Files.writeString(page, originalPage + "changed\n");
    assertThrows(PackageFormatException.class, () -> DocumentationBundleReader.read(bundle));
    Files.writeString(page, originalPage);

    Path ambient = bundle.resolve("ambient.txt");
    Files.writeString(ambient, "ambient\n");
    assertThrows(PackageFormatException.class, () -> DocumentationBundleReader.read(bundle));
    Files.delete(ambient);

    Path manifest = bundle.resolve("manifest.json");
    String originalManifest = Files.readString(manifest, StandardCharsets.UTF_8);
    Files.writeString(
        manifest,
        originalManifest.replace("wheeler-doc-bundle-2", "wheeler-doc-bundle-1"),
        StandardCharsets.UTF_8);
    assertThrows(PackageFormatException.class, () -> DocumentationBundleReader.read(bundle));
  }
}
