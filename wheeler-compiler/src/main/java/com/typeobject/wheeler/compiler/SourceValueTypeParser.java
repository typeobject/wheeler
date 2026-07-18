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
    SourceToken element = cursor.peek();
    String elementName = parseNominalReference(cursor, description);
    boolean qualified = elementName.indexOf("::") >= 0;
    if (!knownType.test(elementName)
        && (!modular || (!qualified && !isNominalName(elementName)))) {
      SourceTokenCursor.fail(element, "expected declared " + description);
    }
    if (!cursor.match(Type.LEFT_BRACKET)) {
      return elementName;
    }
    if (isOwned(elementName)) {
      SourceTokenCursor.fail(element, "owned storage types cannot be array or slice elements");
    }
    if (cursor.match(Type.RIGHT_BRACKET)) {
      String name = elementName + "[]";
      if (slices.stream().noneMatch(slice -> slice.name().equals(name))) {
        slices.add(new SliceDefinition(name, elementName, element.line()));
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
    String name = elementName + "[" + length + "]";
    if (arrays.stream().noneMatch(array -> array.name().equals(name))) {
      arrays.add(new ArrayDefinition(
          name, elementName, Math.toIntExact(length), element.line()));
    }
    return name;
  }

  static String parseNominalReference(SourceTokenCursor cursor, String description) {
    StringBuilder name = new StringBuilder(
        cursor.expect(Type.IDENTIFIER, description).text());
    int distance = 0;
    while (cursor.lookaheadType(distance) == Type.DOT
        && cursor.lookaheadType(distance + 1) == Type.IDENTIFIER) {
      distance += 2;
    }
    if (cursor.lookaheadType(distance) == Type.DOUBLE_COLON) {
      while (cursor.match(Type.DOT)) {
        name.append('.').append(cursor.expect(Type.IDENTIFIER, description).text());
      }
      cursor.expect(Type.DOUBLE_COLON, "'::' before qualified type");
      name.append("::").append(cursor.expect(Type.IDENTIFIER, description).text());
    }
    return name.toString();
  }

  static boolean isQualifiedLocalDeclaration(SourceTokenCursor cursor) {
    int distance = 1;
    while (cursor.lookaheadType(distance) == Type.DOT
        && cursor.lookaheadType(distance + 1) == Type.IDENTIFIER) {
      distance += 2;
    }
    if (cursor.lookaheadType(distance) != Type.DOUBLE_COLON
        || cursor.lookaheadType(distance + 1) != Type.IDENTIFIER) {
      return false;
    }
    distance += 2;
    if (cursor.lookaheadType(distance) == Type.IDENTIFIER) {
      return true;
    }
    if (cursor.lookaheadType(distance) != Type.LEFT_BRACKET) {
      return false;
    }
    distance++;
    if (cursor.lookaheadType(distance) == Type.NUMBER) {
      distance++;
    }
    return cursor.lookaheadType(distance) == Type.RIGHT_BRACKET
        && cursor.lookaheadType(distance + 1) == Type.IDENTIFIER;
  }

  private static boolean isNominalName(String name) {
    return !name.isEmpty() && name.charAt(0) >= 'A' && name.charAt(0) <= 'Z';
  }

  private static boolean isOwned(String name) {
    return name.equals("region") || name.equals("words") || name.equals("bytes")
        || name.equals("longmap") || name.equals("utf8");
  }
}
