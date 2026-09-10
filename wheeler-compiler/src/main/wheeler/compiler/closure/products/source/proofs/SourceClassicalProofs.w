//! Binds source classical claims to counted local callables and constant products.

module wheeler.compiler.closure.source_classical_proofs;

import wheeler.compiler.compiler_token_limits;
import wheeler.compiler.constant_expressions;
import wheeler.compiler.keyword_tokens;
import wheeler.compiler.module_headers;
import wheeler.compiler.module_linker;
import wheeler.compiler.proof_rules;
import wheeler.compiler.source_member_fronts;
import wheeler.compiler.source_member_modifiers;
import wheeler.compiler.source_scalars;
import wheeler.compiler.tokens;

classical class SourceClassicalProofs {
  /// Bounds source-local claims independently of the retained closure certificate capacity.
  public const long MAX_SOURCE_PROOFS = 64;
  /// Counts copied name start, name length, rule, subject, and signed argument columns.
  public const long SOURCE_PROOF_COLUMNS = 5;
  /// Sizes the complete source-local claim table.
  public const long SOURCE_PROOF_ROWS = MAX_SOURCE_PROOFS * SOURCE_PROOF_COLUMNS;
  /// Reserves the largest admitted name for every source-local claim.
  public const long SOURCE_PROOF_NAMES = MAX_SOURCE_PROOFS * MAX_QUALIFIED_NAME_BYTES;
  /// Starts the copied name-length column after the name-start column.
  public const long SOURCE_PROOF_LENGTH_ROW = MAX_SOURCE_PROOFS;
  /// Starts the shared proof-rule code column.
  public const long SOURCE_PROOF_RULE_ROW = SOURCE_PROOF_LENGTH_ROW + MAX_SOURCE_PROOFS;
  /// Starts the source-local callable subject column.
  public const long SOURCE_PROOF_SUBJECT_ROW = SOURCE_PROOF_RULE_ROW + MAX_SOURCE_PROOFS;
  /// Starts the signed argument column, retaining inverse's negative-one sentinel.
  public const long SOURCE_PROOF_ARGUMENT_ROW = SOURCE_PROOF_SUBJECT_ROW + MAX_SOURCE_PROOFS;

  private const long MAX_CALLABLES = 64;
  private const long MAX_STRINGS = 256;
  private const long NATIVE_WORD_BYTES = 8;
  private const long TOKEN_COLUMNS = 3;
  private const long PROOF_FRONT_COLUMNS = 2;
  private const long MODULE_NAME_COLUMNS = 2;
  private const long CALLABLE_COLUMNS = 3;
  private const long CLASS_PREFIX_TOKENS = 4;
  private const long THEOREM_NAME = 1;
  private const long THEOREM_RULE = 3;
  private const long THEOREM_SUBJECT = 5;
  private const long THEOREM_BOUND = 7;
  private const long THEOREM_TRAILER_TOKENS = 2;
  private const long ASCII_RADIX = 128;
  private const long MAX_ASCII = ASCII_RADIX - 1;
  private const long QUALIFIER_BYTES = 2;
  private const long MAX_FUNCTION_NAME_BYTES = MAX_QUALIFIED_NAME_BYTES * 2 + QUALIFIER_BYTES;
  private const long SCRATCH_WORDS = MAX_COMPILER_TOKENS * TOKEN_COLUMNS + MODULE_NAME_COLUMNS
    + MAX_SOURCE_PROOFS * PROOF_FRONT_COLUMNS + SOURCE_PROOF_ROWS + MAX_CALLABLES
    * CALLABLE_COLUMNS;
  private const long SCRATCH_BYTES = SCRATCH_WORDS * NATIVE_WORD_BYTES + SOURCE_PROOF_NAMES;
  private const long SCRATCH_ALLOCATIONS = TOKEN_COLUMNS + 1 + PROOF_FRONT_COLUMNS + 1
    + CALLABLE_COLUMNS + 1;

  /// Reports complete copied names and five-column claims, not acceptance by the proof kernel.
  public record SourceClassicalProofPlan(long proofCount, long nameBytes, boolean valid) {}

  /// Admits complete member fronts and proves that none declares a source claim.
  /// Effects: reuses private token columns and a module-name pair, clearing them on return.
  public boolean sourceClassicalClaimsAbsent(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths,
    borrow mut words moduleRange
  ) {
    assert(bufferLength(kinds) == MAX_COMPILER_TOKENS);
    assert(bufferLength(starts) == MAX_COMPILER_TOKENS);
    assert(bufferLength(lengths) == MAX_COMPILER_TOKENS);
    assert(MODULE_NAME_COLUMNS - 1 < bufferLength(moduleRange));
    long count = scanSemanticTokens(source, kinds, starts, lengths);
    boolean valid = 0 < count;
    long body = -1;
    if (valid) {
      body = moduleBodyStart(source, kinds, starts, lengths, moduleRange, count);
      valid = -1 < body;
    }

    if (valid) {
      valid = classPrefixValid(source, kinds, starts, lengths, body, count);
    }

    long cursor = body + CLASS_PREFIX_TOKENS;
    boolean closed = false;
    while (valid) limit MAX_COMPILER_TOKENS {
      if (cursor < count) {} else {
        valid = false;
        break;
      }

      if (punctuationAt(source, kinds, starts, cursor, PUNCTUATION_CLOSE_BRACE)) {
        closed = cursor + 1 == count;
        break;
      }

      SourceMemberFront front = sourceMemberFront(
        source,
        kinds,
        starts,
        lengths,
        count,
        cursor
      );
      if (front.valid == false) {
        valid = false;
        break;
      }

      if (front.kind == TOKEN_THEOREM) {
        valid = false;
        break;
      }

      cursor = front.nextToken;
    }

    long clear = 0;
    while (clear < MAX_COMPILER_TOKENS) limit MAX_COMPILER_TOKENS {
      set(kinds, clear, 0);
      set(starts, clear, 0);
      set(lengths, clear, 0);
      clear += 1;
    }

    set(moduleRange, 0, 0);
    set(moduleRange, 1, 0);
    if (closed == false) {
      valid = false;
    }

    return valid;
  }

  private boolean tokenMatchesBytes(
    borrow utf8 source,
    long token,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    borrow byteview names,
    long start,
    long length
  ) {
    if (tokenLengths[token] != length) {
      return false;
    }

    if (MAX_QUALIFIED_NAME_BYTES < length) {
      return false;
    }

    long compared = 0;
    while (compared < length) limit MAX_QUALIFIED_NAME_BYTES {
      if (
        utf8Scalar(source, tokenStarts[token] + compared) != names[start + compared]
      ) {
        return false;
      }

      compared += 1;
    }

    return true;
  }

  private long subjectCallable(
    borrow utf8 source,
    long token,
    long callableCount,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    borrow byteview strings,
    borrow mut words localNameStarts,
    borrow mut words localNameLengths
  ) {
    long selected = -1;
    long callable = 0;
    while (callable < callableCount) limit MAX_CALLABLES {
      if (
        tokenMatchesBytes(
          source,
          token,
          tokenStarts,
          tokenLengths,
          strings,
          localNameStarts[callable],
          localNameLengths[callable]
        )
      ) {
        if (-1 < selected) {
          return -1;
        }

        selected = callable;
      }

      callable += 1;
    }

    return selected;
  }

  private boolean sameProofName(
    borrow byteview names,
    long leftStart,
    long rightStart,
    long length
  ) {
    long compared = 0;
    while (compared < length) limit MAX_QUALIFIED_NAME_BYTES {
      if (names[leftStart + compared] != names[rightStart + compared]) {
        return false;
      }

      compared += 1;
    }

    return true;
  }

  /// Publishes name start, name length, rule, local subject, and signed argument columns.
  /// Member fronts own declaration windows. Constant products carry names and values only.
  /// Constant products must already be scoped by the scalar and dependency owners.
  /// Every supplied ordinary or rev callable must match its source declaration and effect.
  /// A qualified callable name must name this source module.
  /// Repeated subjects are permitted. Proof names remain unique within the source module.
  /// Other declarations still require their own semantic owners before artifact publication.
  public SourceClassicalProofPlan materializeSourceClassicalProofs(
    borrow utf8 source,
    long callableCount,
    borrow mut words callableEffects,
    borrow byteview strings,
    long stringBytes,
    long stringCount,
    borrow mut words stringStarts,
    borrow mut words stringLengths,
    borrow mut words functionNameIds,
    borrow byteview constantNames,
    borrow mut words constantRows,
    borrow mut bytes proofNames,
    borrow mut words proofRows
  ) {
    assert(-1 < callableCount);
    assert(callableCount < MAX_CALLABLES + 1);
    assert(bufferLength(callableEffects) == MAX_CALLABLES);
    assert(-1 < stringBytes);
    assert(stringBytes < bufferLength(strings) + 1);
    assert(-1 < stringCount);
    assert(stringCount < MAX_STRINGS + 1);
    assert(bufferLength(stringStarts) == MAX_STRINGS);
    assert(bufferLength(stringLengths) == MAX_STRINGS);
    assert(bufferLength(functionNameIds) == MAX_CALLABLES);
    assert(bufferLength(proofNames) == SOURCE_PROOF_NAMES);
    assert(bufferLength(proofRows) == SOURCE_PROOF_ROWS);

    long callable = 0;
    while (callable < callableCount) limit MAX_CALLABLES {
      long id = functionNameIds[callable];
      if (id < 0) {
        return new SourceClassicalProofPlan(0, 0, false);
      }

      if (id < stringCount) {} else {
        return new SourceClassicalProofPlan(0, 0, false);
      }

      long callableNameStart = stringStarts[id];
      long length = stringLengths[id];
      if (callableNameStart < 0) {
        return new SourceClassicalProofPlan(0, 0, false);
      }

      if (length < 1) {
        return new SourceClassicalProofPlan(0, 0, false);
      }

      if (MAX_FUNCTION_NAME_BYTES < length) {
        return new SourceClassicalProofPlan(0, 0, false);
      }

      if (stringBytes - length < callableNameStart) {
        return new SourceClassicalProofPlan(0, 0, false);
      }

      long nameByte = 0;
      while (nameByte < length) limit MAX_FUNCTION_NAME_BYTES {
        long nameValue = strings[callableNameStart + nameByte];
        if (nameValue < 1) {
          return new SourceClassicalProofPlan(0, 0, false);
        }

        if (MAX_ASCII < nameValue) {
          return new SourceClassicalProofPlan(0, 0, false);
        }

        nameByte += 1;
      }

      long effect = callableEffects[callable];
      if (effect != 0) {
        if (effect != MEMBER_REV) {
          return new SourceClassicalProofPlan(0, 0, false);
        }
      }

      callable += 1;
    }

    region scratch = new region(
      /* bytes= */ SCRATCH_BYTES,
      /* allocations= */ SCRATCH_ALLOCATIONS
    );
    words kinds = allocate(scratch, MAX_COMPILER_TOKENS);
    words starts = allocate(scratch, MAX_COMPILER_TOKENS);
    words lengths = allocate(scratch, MAX_COMPILER_TOKENS);
    words moduleRange = allocate(scratch, MODULE_NAME_COLUMNS);
    words proofStarts = allocate(scratch, MAX_SOURCE_PROOFS);
    words proofEnds = allocate(scratch, MAX_SOURCE_PROOFS);
    words staged = allocate(scratch, SOURCE_PROOF_ROWS);
    words declared = allocate(scratch, MAX_CALLABLES);
    words localNameStarts = allocate(scratch, MAX_CALLABLES);
    words localNameLengths = allocate(scratch, MAX_CALLABLES);
    bytes names = allocateBytes(scratch, SOURCE_PROOF_NAMES);
    long count = scanSemanticTokens(source, kinds, starts, lengths);
    boolean valid = 0 < count;
    long body = -1;
    if (valid) {
      body = moduleBodyStart(source, kinds, starts, lengths, moduleRange, count);
      valid = -1 < body;
    }

    if (valid) {
      valid = classPrefixValid(source, kinds, starts, lengths, body, count);
    }

    callable = 0;
    while (valid) limit 1 {
      while (callable < callableCount) limit MAX_CALLABLES {
        long nameId = functionNameIds[callable];
        long qualifiedStart = stringStarts[nameId];
        long qualifiedLength = stringLengths[nameId];
        long localStart = qualifiedStart;
        long qualifierByte = 0;
        while (qualifierByte + 1 < qualifiedLength) limit MAX_FUNCTION_NAME_BYTES {
          if (strings[qualifiedStart + qualifierByte] == PUNCTUATION_COLON) {
            if (strings[qualifiedStart + qualifierByte + 1] == PUNCTUATION_COLON) {
              localStart = qualifiedStart + qualifierByte + QUALIFIER_BYTES;
            }
          }

          qualifierByte += 1;
        }

        if (qualifiedStart < localStart) {
          long qualifierLength = localStart - qualifiedStart - QUALIFIER_BYTES;
          if (qualifierLength != moduleRange[1]) {
            valid = false;
            break;
          }

          if (qualifierLength < 1) {
            valid = false;
            break;
          }

          qualifierByte = 0;
          while (qualifierByte < qualifierLength) limit MAX_QUALIFIED_NAME_BYTES {
            if (
              utf8Scalar(source, moduleRange[0] + qualifierByte) != strings[qualifiedStart
                + qualifierByte]
            ) {
              valid = false;
            }

            qualifierByte += 1;
          }
        }

        set(localNameStarts, callable, localStart);
        set(localNameLengths, callable, qualifiedStart + qualifiedLength - localStart);
        callable += 1;
      }

      break;
    }

    long cursor = body + CLASS_PREFIX_TOKENS;
    long proofCount = 0;
    boolean closed = false;
    while (valid) limit MAX_COMPILER_TOKENS {
      if (cursor < count) {} else {
        valid = false;
        break;
      }

      if (punctuationAt(source, kinds, starts, cursor, PUNCTUATION_CLOSE_BRACE)) {
        closed = cursor + 1 == count;
        break;
      }

      SourceMemberFront front = sourceMemberFront(
        source,
        kinds,
        starts,
        lengths,
        count,
        cursor
      );
      if (front.valid == false) {
        valid = false;
        break;
      }

      if (front.kind == TOKEN_THEOREM) {
        if (proofCount == MAX_SOURCE_PROOFS) {
          valid = false;
          break;
        }

        set(proofStarts, proofCount, front.nameToken - THEOREM_NAME);
        set(proofEnds, proofCount, front.nextToken);
        proofCount += 1;
      }

      if (front.kind == 0) {
        long declaredSubject = subjectCallable(
          source,
          front.nameToken,
          callableCount,
          starts,
          lengths,
          strings,
          localNameStarts,
          localNameLengths
        );
        if (-1 < declaredSubject) {
          if (declared[declaredSubject] != 0) {
            valid = false;
            break;
          }

          if (front.effects != callableEffects[declaredSubject]) {
            valid = false;
            break;
          }

          set(declared, declaredSubject, 1);
        }
      }

      cursor = front.nextToken;
    }

    if (closed == false) {
      valid = false;
    }

    callable = 0;
    while (callable < callableCount) limit MAX_CALLABLES {
      if (declared[callable] != 1) {
        valid = false;
      }

      callable += 1;
    }

    long proof = 0;
    long nameBytes = 0;
    while (valid) limit 1 {
      while (proof < proofCount) limit MAX_SOURCE_PROOFS {
        long start = proofStarts[proof];
        long nameLength = lengths[start + THEOREM_NAME];
        if (nameLength < 1) {
          valid = false;
          break;
        }

        if (MAX_QUALIFIED_NAME_BYTES < nameLength) {
          valid = false;
          break;
        }

        long subject = subjectCallable(
          source,
          start + THEOREM_SUBJECT,
          callableCount,
          starts,
          lengths,
          strings,
          localNameStarts,
          localNameLengths
        );
        if (subject < 0) {
          valid = false;
          break;
        }

        long rule = 0;
        long argument = -1;
        long ruleWord = sourceTokenCode(source, starts, lengths, start + THEOREM_RULE);
        if (ruleWord == TOKEN_INVERSE) {
          rule = PROOF_GENERATED_INVERSE;
          if (callableEffects[subject] != MEMBER_REV) {
            valid = false;
          }
        } else {
          if (ruleWord == TOKEN_STEPS) {
            rule = PROOF_STATIC_STEP_BOUND;
            ExpressionValue bound = evaluateScalarExpressionWithProducts(
              source,
              starts,
              lengths,
              /* firstDeclaration= */ 0,
              /* memberStart= */ 0,
              start + THEOREM_BOUND,
              proofEnds[proof] - THEOREM_TRAILER_TOKENS,
              constantNames,
              constantRows
            );
            valid = bound.valid;
            if (bound.signed == false) {
              valid = false;
            }

            if (bound.value < 1) {
              valid = false;
            }

            argument = bound.value;
          } else {
            valid = false;
          }
        }

        if (valid == false) {
          break;
        }

        long copied = 0;
        while (copied < nameLength) limit MAX_QUALIFIED_NAME_BYTES {
          long value = utf8Scalar(source, starts[start + THEOREM_NAME] + copied);
          if (MAX_ASCII < value) {
            valid = false;
            break;
          }

          setByte(names, nameBytes + copied, value);
          copied += 1;
        }

        long earlier = 0;
        while (earlier < proof) limit MAX_SOURCE_PROOFS {
          if (staged[SOURCE_PROOF_LENGTH_ROW + earlier] == nameLength) {
            if (sameProofName(names, staged[earlier], nameBytes, nameLength)) {
              valid = false;
            }
          }

          earlier += 1;
        }

        set(staged, proof, nameBytes);
        set(staged, SOURCE_PROOF_LENGTH_ROW + proof, nameLength);
        set(staged, SOURCE_PROOF_RULE_ROW + proof, rule);
        set(staged, SOURCE_PROOF_SUBJECT_ROW + proof, subject);
        set(staged, SOURCE_PROOF_ARGUMENT_ROW + proof, argument);
        nameBytes += nameLength;
        proof += 1;
        if (valid == false) {
          break;
        }
      }

      break;
    }

    if (valid) {
      long column = 0;
      while (column < SOURCE_PROOF_COLUMNS) limit SOURCE_PROOF_COLUMNS {
        proof = 0;
        while (proof < proofCount) limit MAX_SOURCE_PROOFS {
          long cell = column * MAX_SOURCE_PROOFS + proof;
          set(proofRows, cell, staged[cell]);
          proof += 1;
        }

        column += 1;
      }

      long publishedNameByte = 0;
      while (publishedNameByte < nameBytes) limit SOURCE_PROOF_NAMES {
        setByte(proofNames, publishedNameByte, names[publishedNameByte]);
        publishedNameByte += 1;
      }
    } else {
      proofCount = 0;
      nameBytes = 0;
    }

    drop(names);
    drop(localNameLengths);
    drop(localNameStarts);
    drop(declared);
    drop(staged);
    drop(proofEnds);
    drop(proofStarts);
    drop(moduleRange);
    drop(lengths);
    drop(starts);
    drop(kinds);
    drop(scratch);
    return new SourceClassicalProofPlan(proofCount, nameBytes, valid);
  }
}
