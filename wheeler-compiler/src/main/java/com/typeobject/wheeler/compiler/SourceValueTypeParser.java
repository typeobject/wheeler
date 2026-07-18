package com.typeobject.wheeler.compiler;

import com.typeobject.wheeler.compiler.SourceModel.ArrayDefinition;
import com.typeobject.wheeler.compiler.SourceModel.SliceDefinition;
import com.typeobject.wheeler.compiler.SourceToken.Type;
import java.util.List;
import java.util.function.Predicate;

/** Parses scalar, nominal, fixed-array, and nonescaping-slice type spellings. */
final class SourceValueTypeParser {
  private SourceValueTypeParser() {}

  static String parse(
      SourceTokenCursor cursor,
      String description,
      boolean modular,
      Predicate<String> knownType,
      List<ArrayDefinition> arrays,
      List<SliceDefinition> slices) {
    SourceToken element = cursor.expect(Type.IDENTIFIER, description);
    if (!knownType.test(element.text())
        && (!modular || !isNominalName(element.text()))) {
      SourceTokenCursor.fail(element, "expected declared " + description);
    }
    if (!cursor.match(Type.LEFT_BRACKET)) {
      return element.text();
    }
    if (isOwned(element.text())) {
      SourceTokenCursor.fail(element, "owned storage types cannot be array or slice elements");
    }
    if (cursor.match(Type.RIGHT_BRACKET)) {
      String name = element.text() + "[]";
      if (slices.stream().noneMatch(slice -> slice.name().equals(name))) {
        slices.add(new SliceDefinition(name, element.text(), element.line()));
      }
      return name;
    }
    SourceToken lengthToken = cursor.expect(Type.NUMBER, "fixed array length");
    long length = SourceParser.parseInteger(lengthToken.text(), lengthToken.line());
    if (length <= 0 || length > 65_535) {
      SourceTokenCursor.fail(
          lengthToken, "fixed array length must be between 1 and 65535");
    }
    cursor.expect(Type.RIGHT_BRACKET, "']' after fixed array length");
    String name = element.text() + "[" + length + "]";
    if (arrays.stream().noneMatch(array -> array.name().equals(name))) {
      arrays.add(new ArrayDefinition(
          name, element.text(), Math.toIntExact(length), element.line()));
    }
    return name;
  }

  private static boolean isNominalName(String name) {
    return !name.isEmpty() && name.charAt(0) >= 'A' && name.charAt(0) <= 'Z';
  }

  private static boolean isOwned(String name) {
    return name.equals("region") || name.equals("words") || name.equals("bytes")
        || name.equals("longmap") || name.equals("utf8");
  }
}
