package com.typeobject.wheeler.tools;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import java.io.ByteArrayOutputStream;
import java.io.PrintStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.attribute.FileTime;
import java.util.LinkedHashMap;
import java.util.Locale;
import java.util.TimeZone;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

/** Proves that ambient host presentation facts cannot enter compiler artifacts. */
final class CompilationReproducibilityTest {
  @TempDir
  Path temporary;

  @Test
  void ignoresCheckoutPathTimestampLocaleTimezoneAndModuleOrder() throws Exception {
    String source = "classical class Stable { entry void main() { long value = 3; } }\n";
    Path firstDirectory = temporary.resolve("first/checkout");
    Path secondDirectory = temporary.resolve("second/deeper/checkout");
    Files.createDirectories(firstDirectory);
    Files.createDirectories(secondDirectory);
    Path firstSource = firstDirectory.resolve("Stable.w");
    Path secondSource = secondDirectory.resolve("Stable.w");
    Files.writeString(firstSource, source);
    Files.writeString(secondSource, source);
    Files.setLastModifiedTime(firstSource, FileTime.fromMillis(1_000));
    Files.setLastModifiedTime(secondSource, FileTime.fromMillis(9_000_000));
    Path firstOutput = firstDirectory.resolve("Stable.wbc");
    Path secondOutput = secondDirectory.resolve("Stable.wbc");
    Locale originalLocale = Locale.getDefault();
    TimeZone originalZone = TimeZone.getDefault();
    try {
      Locale.setDefault(Locale.forLanguageTag("tr-TR"));
      TimeZone.setDefault(TimeZone.getTimeZone("Pacific/Kiritimati"));
      compile(firstSource, firstOutput);
      Locale.setDefault(Locale.JAPAN);
      TimeZone.setDefault(TimeZone.getTimeZone("Pacific/Pago_Pago"));
      compile(secondSource, secondOutput);
    } finally {
      Locale.setDefault(originalLocale);
      TimeZone.setDefault(originalZone);
    }
    assertArrayEquals(Files.readAllBytes(firstOutput), Files.readAllBytes(secondOutput));

    String dependency = """
        module stable.dependency;
        classical class Dependency { public const long VALUE = 3; }
        """;
    String root = """
        module stable.root;
        import stable.dependency;
        classical class Root {
          state long value = 0;
          entry void main() { value = VALUE; }
        }
        """;
    var forward = new LinkedHashMap<String, String>();
    forward.put("stable.dependency", dependency);
    forward.put("stable.root", root);
    var reverse = new LinkedHashMap<String, String>();
    reverse.put("stable.root", root);
    reverse.put("stable.dependency", dependency);
    WheelerCompiler compiler = new WheelerCompiler();
    assertArrayEquals(
        compiler.compileModulesToBytecode(forward, "stable.root"),
        compiler.compileModulesToBytecode(reverse, "stable.root"));
  }

  private static void compile(Path source, Path output) throws Exception {
    assertEquals(0, Wheeler.execute(
        new String[] {"compile", source.toString(), "-o", output.toString()},
        new PrintStream(new ByteArrayOutputStream()),
        new PrintStream(new ByteArrayOutputStream())));
  }
}
