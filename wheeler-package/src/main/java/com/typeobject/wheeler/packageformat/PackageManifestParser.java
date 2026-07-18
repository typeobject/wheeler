package com.typeobject.wheeler.packageformat;

import com.typeobject.wheeler.packageformat.PackageManifest.Capability;
import com.typeobject.wheeler.packageformat.PackageManifest.Dependency;
import com.typeobject.wheeler.packageformat.PackageManifest.DependencyKind;
import com.typeobject.wheeler.packageformat.PackageManifest.Target;
import com.typeobject.wheeler.packageformat.PackageManifest.TargetKind;
import java.nio.ByteBuffer;
import java.nio.charset.CharacterCodingException;
import java.nio.charset.CodingErrorAction;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;

/** Strict source-located parser for {@code wheeler.package}. */
public final class PackageManifestParser {
  private static final int MAX_BYTES = 1024 * 1024;

  public PackageManifest parse(byte[] utf8) {
    if (utf8.length > MAX_BYTES) {
      throw new PackageFormatException("Manifest exceeds " + MAX_BYTES + " bytes");
    }
    try {
      String source = StandardCharsets.UTF_8.newDecoder()
          .onMalformedInput(CodingErrorAction.REPORT)
          .onUnmappableCharacter(CodingErrorAction.REPORT)
          .decode(ByteBuffer.wrap(utf8))
          .toString();
      return new Parser(new Lexer(source).lex()).parse();
    } catch (CharacterCodingException exception) {
      throw new PackageFormatException("Manifest is not strict UTF-8", exception);
    }
  }

  public PackageManifest parse(String source) {
    return parse(source.getBytes(StandardCharsets.UTF_8));
  }

  private static final class Parser {
    private final List<Token> tokens;
    private int current;

    private Parser(List<Token> tokens) {
      this.tokens = tokens;
    }

    private PackageManifest parse() {
      expectWord("package");
      String name = expect(Type.STRING, "package name").text();
      expectWord("version");
      String version = expect(Type.STRING, "package version").text();
      expectWord("profile");
      String profile = expect(Type.STRING, "language profile").text();
      expect(Type.SEMICOLON, "';' after package declaration");

      List<Target> targets = new ArrayList<>();
      List<Dependency> dependencies = new ArrayList<>();
      List<Capability> capabilities = new ArrayList<>();
      while (!check(Type.END)) {
        Token declaration = expect(Type.WORD, "manifest declaration");
        switch (declaration.text()) {
          case "target" -> targets.add(parseTarget());
          case "dependency" -> dependencies.add(parseDependency());
          case "capability" -> capabilities.add(parseCapability());
          default -> fail(declaration, "unknown manifest declaration " + declaration.text());
        }
      }
      return new PackageManifest(name, version, profile, targets, dependencies, capabilities);
    }

    private Target parseTarget() {
      TargetKind kind = TargetKind.parse(expect(Type.WORD, "target kind").text());
      String name = expect(Type.STRING, "target name").text();
      expectWord("root");
      String root = expect(Type.STRING, "target root").text();
      expect(Type.SEMICOLON, "';' after target");
      return new Target(kind, name, root);
    }

    private Dependency parseDependency() {
      DependencyKind kind = DependencyKind.parse(
          expect(Type.WORD, "dependency kind").text());
      String name = expect(Type.STRING, "dependency name").text();
      expectWord("version");
      String constraint = expect(Type.STRING, "dependency version").text();
      expect(Type.SEMICOLON, "';' after dependency");
      return new Dependency(kind, name, constraint);
    }

    private Capability parseCapability() {
      String name = expect(Type.STRING, "capability name").text();
      expectWord("path");
      String path = expect(Type.STRING, "capability path").text();
      expect(Type.SEMICOLON, "';' after capability");
      return new Capability(name, path);
    }

    private void expectWord(String value) {
      Token token = expect(Type.WORD, "'" + value + "'");
      if (!token.text().equals(value)) {
        fail(token, "expected '" + value + "'");
      }
    }

    private Token expect(Type type, String description) {
      Token token = tokens.get(current);
      if (token.type() != type) {
        fail(token, "expected " + description);
      }
      current++;
      return token;
    }

    private boolean check(Type type) {
      return tokens.get(current).type() == type;
    }
  }

  private static final class Lexer {
    private final String source;
    private final List<Token> tokens = new ArrayList<>();
    private int offset;
    private int line = 1;
    private int column = 1;

    private Lexer(String source) {
      this.source = source;
    }

    private List<Token> lex() {
      while (offset < source.length()) {
        char value = peek();
        if (Character.isWhitespace(value)) {
          advance();
        } else if (value == '/' && peek(1) == '/') {
          while (offset < source.length() && peek() != '\n') {
            advance();
          }
        } else if (value == '"') {
          string();
        } else if (value == ';') {
          tokens.add(new Token(Type.SEMICOLON, ";", line, column));
          advance();
        } else if (Character.isLetter(value)) {
          word();
        } else {
          throw new PackageFormatException(
              "Manifest line " + line + ", column " + column + ": unexpected '" + value + "'");
        }
      }
      tokens.add(new Token(Type.END, "", line, column));
      return List.copyOf(tokens);
    }

    private void word() {
      int start = offset;
      int startLine = line;
      int startColumn = column;
      advance();
      while (offset < source.length()
          && (Character.isLetterOrDigit(peek()) || peek() == '_' || peek() == '-')) {
        advance();
      }
      tokens.add(new Token(
          Type.WORD, source.substring(start, offset), startLine, startColumn));
    }

    private void string() {
      int startLine = line;
      int startColumn = column;
      advance();
      StringBuilder value = new StringBuilder();
      while (offset < source.length() && peek() != '"') {
        char next = advance();
        if (next == '\n' || next == '\r') {
          throw new PackageFormatException(
              "Manifest line " + startLine + ": string crosses a line boundary");
        }
        if (next == '\\') {
          if (offset >= source.length()) {
            throw new PackageFormatException("Manifest has an unfinished string escape");
          }
          char escaped = advance();
          if (escaped != '\\' && escaped != '"') {
            throw new PackageFormatException(
                "Manifest line " + line + ": unsupported string escape");
          }
          next = escaped;
        }
        value.append(next);
      }
      if (offset >= source.length()) {
        throw new PackageFormatException("Manifest line " + startLine + ": unclosed string");
      }
      advance();
      tokens.add(new Token(Type.STRING, value.toString(), startLine, startColumn));
    }

    private char advance() {
      char value = source.charAt(offset++);
      if (value == '\n') {
        line++;
        column = 1;
      } else {
        column++;
      }
      return value;
    }

    private char peek() {
      return peek(0);
    }

    private char peek(int ahead) {
      return offset + ahead < source.length() ? source.charAt(offset + ahead) : '\0';
    }
  }

  private enum Type {
    WORD,
    STRING,
    SEMICOLON,
    END
  }

  private record Token(Type type, String text, int line, int column) {}

  private static void fail(Token token, String message) {
    throw new PackageFormatException(
        "Manifest line " + token.line() + ", column " + token.column() + ": " + message);
  }
}
