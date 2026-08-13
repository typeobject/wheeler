package com.typeobject.wheeler.compiler;

import com.typeobject.wheeler.compiler.SourceToken.Type;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

/** Parses one bounded canonical tag list attached to a test declaration. */
final class SourceTestTags {
  private static final int MAX_TAGS = 64;
  private static final int MAX_TAG_SCALARS = 128;

  private SourceTestTags() {}

  static List<String> parse(SourceParser parser, boolean test, SourceToken start) {
    if (!parser.matchText("tags")) {
      return List.of();
    }
    if (!test) {
      SourceParser.fail(start, "tags require a test method");
    }
    parser.expect(Type.LEFT_PAREN, "'(' after tags");
    List<String> tags = new ArrayList<>();
    Set<String> unique = new HashSet<>();
    if (!parser.check(Type.RIGHT_PAREN)) {
      do {
        String tag = parseTag(parser);
        if (!unique.add(tag)) {
          SourceParser.fail(parser.previous(), "duplicate test tag: " + tag);
        }
        if (tags.size() == MAX_TAGS) {
          SourceParser.fail(parser.previous(), "test declaration exceeds 64 tags");
        }
        tags.add(tag);
      } while (parser.match(Type.COMMA));
    }
    parser.expect(Type.RIGHT_PAREN, "')' after test tags");
    if (tags.isEmpty()) {
      SourceParser.fail(start, "test tags cannot be empty");
    }
    tags.sort(String::compareTo);
    return List.copyOf(tags);
  }

  private static String parseTag(SourceParser parser) {
    StringBuilder tag = new StringBuilder(
        parser.expect(Type.IDENTIFIER, "test tag name").text());
    while (parser.match(Type.DOT)) {
      tag.append('.').append(parser.expect(Type.IDENTIFIER, "test tag segment").text());
    }
    if (tag.codePointCount(0, tag.length()) > MAX_TAG_SCALARS) {
      SourceParser.fail(parser.previous(), "test tag exceeds 128 Unicode scalars");
    }
    return tag.toString();
  }
}
