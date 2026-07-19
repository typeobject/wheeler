package com.typeobject.wheeler.packageformat;

import com.typeobject.wheeler.packageformat.WorkspaceManifest.Member;
import java.nio.ByteBuffer;
import java.nio.charset.CharacterCodingException;
import java.nio.charset.CodingErrorAction;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;

/** Strict source-located parser for {@code wheeler.workspace}. */
public final class WorkspaceManifestParser {
  private static final int MAX_BYTES = 1024 * 1024;
  private static final int MAX_TOKENS = 100_000;

  public WorkspaceManifest parse(byte[] utf8) {
    if (utf8.length > MAX_BYTES) {
      throw new PackageFormatException("Workspace manifest exceeds " + MAX_BYTES + " bytes");
    }
    try {
      String source = StandardCharsets.UTF_8.newDecoder()
          .onMalformedInput(CodingErrorAction.REPORT)
          .onUnmappableCharacter(CodingErrorAction.REPORT)
          .decode(ByteBuffer.wrap(utf8))
          .toString();
      return new Parser(new Lexer(source).lex()).parse();
    } catch (CharacterCodingException exception) {
      throw new PackageFormatException("Workspace manifest is not strict UTF-8", exception);
    }
  }

  public WorkspaceManifest parse(String source) {
    return parse(source.getBytes(StandardCharsets.UTF_8));
  }

  private enum Kind {
    WORD,
    STRING,
    SEMICOLON,
    EOF
  }

  private record Token(Kind kind, String text, int line, int column) {}

  private static final class Parser {
    private final List<Token> tokens;
    private int position;

    Parser(List<Token> tokens) {
      this.tokens = tokens;
    }

    WorkspaceManifest parse() {
      expectWord("workspace");
      String name = expect(Kind.STRING, "workspace name").text();
      expectWord("profile");
      String profile = expect(Kind.STRING, "profile").text();
      expect(Kind.SEMICOLON, "';'");
      List<Member> members = new ArrayList<>();
      while (!peek(Kind.EOF)) {
        Token declaration = expect(Kind.WORD, "member declaration");
        if (!declaration.text().equals("member")) {
          throw error(declaration, "Unknown workspace declaration " + declaration.text());
        }
        String memberName = expect(Kind.STRING, "member name").text();
        expectWord("path");
        String path = expect(Kind.STRING, "member path").text();
        expect(Kind.SEMICOLON, "';'");
        members.add(new Member(memberName, path));
      }
      return new WorkspaceManifest(name, profile, members);
    }

    private void expectWord(String value) {
      Token token = expect(Kind.WORD, "'" + value + "'");
      if (!token.text().equals(value)) {
        throw error(token, "Expected '" + value + "'");
      }
    }

    private Token expect(Kind kind, String description) {
      Token token = tokens.get(position);
      if (token.kind() != kind) {
        throw error(token, "Expected " + description);
      }
      position++;
      return token;
    }

    private boolean peek(Kind kind) {
      return tokens.get(position).kind() == kind;
    }

    private static PackageFormatException error(Token token, String message) {
      return new PackageFormatException(
          "workspace:" + token.line() + ":" + token.column() + ": " + message);
    }
  }

  private static final class Lexer {
    private final String source;
    private final List<Token> tokens = new ArrayList<>();
    private int index;
    private int line = 1;
    private int column = 1;

    Lexer(String source) {
      this.source = source;
    }

    List<Token> lex() {
      while (!atEnd()) {
        skipTrivia();
        if (atEnd()) {
          break;
        }
        int tokenLine = line;
        int tokenColumn = column;
        char current = current();
        if (current == ';') {
          advance();
          add(new Token(Kind.SEMICOLON, ";", tokenLine, tokenColumn));
        } else if (current == '"') {
          add(string(tokenLine, tokenColumn));
        } else if (Character.isLetter(current)) {
          add(word(tokenLine, tokenColumn));
        } else {
          throw new PackageFormatException(
              "workspace:" + line + ":" + column + ": Unexpected character '" + current + "'");
        }
      }
      add(new Token(Kind.EOF, "", line, column));
      return List.copyOf(tokens);
    }

    private void skipTrivia() {
      boolean again;
      do {
        again = false;
        while (!atEnd() && Character.isWhitespace(current())) {
          advance();
        }
        if (!atEnd() && current() == '/' && peek('/') ) {
          while (!atEnd() && current() != '\n') {
            advance();
          }
          again = true;
        }
      } while (again);
    }

    private Token word(int tokenLine, int tokenColumn) {
      int start = index;
      while (!atEnd() && (Character.isLetterOrDigit(current()) || current() == '_')) {
        advance();
      }
      return new Token(Kind.WORD, source.substring(start, index), tokenLine, tokenColumn);
    }

    private Token string(int tokenLine, int tokenColumn) {
      advance();
      StringBuilder value = new StringBuilder();
      while (!atEnd() && current() != '"') {
        char next = current();
        if (next == '\n' || next == '\r') {
          throw new PackageFormatException(
              "workspace:" + line + ":" + column + ": Unterminated string");
        }
        if (next == '\\') {
          advance();
          if (atEnd() || (current() != '\\' && current() != '"')) {
            throw new PackageFormatException(
                "workspace:" + line + ":" + column + ": Unsupported string escape");
          }
          next = current();
        }
        value.append(next);
        advance();
      }
      if (atEnd()) {
        throw new PackageFormatException(
            "workspace:" + tokenLine + ":" + tokenColumn + ": Unterminated string");
      }
      advance();
      return new Token(Kind.STRING, value.toString(), tokenLine, tokenColumn);
    }

    private void add(Token token) {
      if (tokens.size() >= MAX_TOKENS) {
        throw new PackageFormatException("Workspace manifest has too many tokens");
      }
      tokens.add(token);
    }

    private char current() {
      return source.charAt(index);
    }

    private boolean peek(char expected) {
      return index + 1 < source.length() && source.charAt(index + 1) == expected;
    }

    private boolean atEnd() {
      return index >= source.length();
    }

    private void advance() {
      char consumed = source.charAt(index++);
      if (consumed == '\n') {
        line++;
        column = 1;
      } else {
        column++;
      }
    }
  }
}
