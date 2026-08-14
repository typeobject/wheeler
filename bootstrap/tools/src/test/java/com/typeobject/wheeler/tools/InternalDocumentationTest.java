package com.typeobject.wheeler.tools;

import static org.junit.jupiter.api.Assertions.assertEquals;

import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import org.junit.jupiter.api.Test;

/** Keeps maintainer documentation outside the site while checking repository-local links. */
final class InternalDocumentationTest {
  private static final Path ROOT = Path.of("docs/internal");
  private static final Pattern LINK = Pattern.compile("\\[[^]\\n]+]\\(([^)\\s]+)\\)");

  @Test
  void internalMarkdownLinksResolveInsideTheRepository() throws Exception {
    List<String> failures = new ArrayList<>();
    try (var paths = Files.walk(ROOT)) {
      for (Path source : paths.filter(Files::isRegularFile).sorted().toList()) {
        Matcher matcher = LINK.matcher(prose(Files.readString(source)));
        while (matcher.find()) {
          String target = matcher.group(1);
          if (target.startsWith("#") || target.startsWith("https://")
              || target.startsWith("http://") || target.startsWith("mailto:")) {
            continue;
          }
          int fragment = target.indexOf('#');
          String path = fragment < 0 ? target : target.substring(0, fragment);
          Path repository = Path.of(".").toAbsolutePath().normalize();
          Path resolved = source.getParent().resolve(path).toAbsolutePath().normalize();
          if (!resolved.startsWith(repository) || !Files.exists(resolved)) {
            failures.add(source + " -> " + target);
          }
        }
      }
    }
    assertEquals(List.of(), failures);
  }

  private static String prose(String markdown) {
    StringBuilder result = new StringBuilder(markdown.length());
    boolean fenced = false;
    for (String line : markdown.split("\\R", -1)) {
      if (line.trim().startsWith("```")) {
        fenced = !fenced;
      } else if (!fenced) {
        result.append(line.replaceAll("`[^`]*`", "")).append('\n');
      }
    }
    return result.toString();
  }
}
