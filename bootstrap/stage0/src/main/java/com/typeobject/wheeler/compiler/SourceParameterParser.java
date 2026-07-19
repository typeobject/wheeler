package com.typeobject.wheeler.compiler;

import com.typeobject.wheeler.compiler.SourceModel.Parameter;
import com.typeobject.wheeler.compiler.SourceModel.ParameterMode;
import java.util.List;

/** Parses explicit value, shared-loan, and exclusive-loan parameter modes. */
final class SourceParameterParser {
  private SourceParameterParser() {}

  static ParameterMode parseMode(SourceTokenCursor cursor) {
    if (!cursor.matchText("borrow")) {
      return ParameterMode.VALUE;
    }
    return cursor.matchText("mut") ? ParameterMode.BORROW_MUT : ParameterMode.BORROW;
  }

  static void validate(String type, ParameterMode mode, SourceToken token) {
    if (mode == ParameterMode.VALUE) {
      if (type.equals("byteview")) {
        SourceTokenCursor.fail(token, "byteview parameters require 'borrow'");
      }
      return;
    }
    boolean valid = mode == ParameterMode.BORROW
        ? type.equals("utf8") || type.equals("bytes") || type.equals("byteview")
        : type.equals("region") || type.equals("words")
            || type.equals("bytes") || type.equals("longmap");
    if (!valid) {
      SourceTokenCursor.fail(
          token, "unsupported " + display(mode) + " parameter type " + type);
    }
  }

  static boolean validEntry(List<Parameter> parameters) {
    return parameters.isEmpty()
        || (parameters.size() == 1
            && (input(parameters.getFirst()) || output(parameters.getFirst())))
        || (parameters.size() == 2
            && input(parameters.get(0)) && output(parameters.get(1)));
  }

  private static boolean input(Parameter parameter) {
    return parameter.mode() == ParameterMode.BORROW
        && (parameter.type().equals("utf8") || parameter.type().equals("byteview"));
  }

  private static boolean output(Parameter parameter) {
    return parameter.mode() == ParameterMode.BORROW_MUT
        && parameter.type().equals("bytes");
  }

  private static String display(ParameterMode mode) {
    return mode == ParameterMode.BORROW ? "borrow" : "borrow mut";
  }
}
