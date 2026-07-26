package com.typeobject.wheeler.tools;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.packageformat.BootstrapFeatureManifest;
import com.typeobject.wheeler.packageformat.BootstrapFeatureManifestParser;
import java.io.ByteArrayOutputStream;
import java.io.PrintStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

/** Command tests for publishing closed bootstrap feature profiles. */
final class BootstrapFeaturesCommandTest {
  @TempDir
  Path temporary;

  @Test
  void publishesTheCompleteKnownProfileCanonically() throws Exception {
    Path output = temporary.resolve(BootstrapFeatureManifest.FILE_NAME);
    ByteArrayOutputStream message = new ByteArrayOutputStream();

    int status = Wheeler.execute(
        new String[] {
            "bootstrap-features", "--profile", "bootstrap-1", "--output", output.toString()
        },
        new PrintStream(message),
        System.err);

    assertEquals(0, status);
    BootstrapFeatureManifest manifest = new BootstrapFeatureManifestParser().parse(
        Files.readAllBytes(output));
    assertEquals(BootstrapFeatureManifest.bootstrap1(), manifest);
    assertTrue(message.toString(StandardCharsets.UTF_8).contains(manifest.identity()));
  }

  @Test
  void rejectsUnknownProfilesWithoutPublishing() throws Exception {
    Path output = temporary.resolve(BootstrapFeatureManifest.FILE_NAME);

    int status = BootstrapFeaturesCommand.execute(
        new String[] {
            "bootstrap-features", "--profile", "bootstrap-2", "--output", output.toString()
        },
        System.out,
        System.err);

    assertEquals(2, status);
    assertFalse(Files.exists(output));
  }
}
