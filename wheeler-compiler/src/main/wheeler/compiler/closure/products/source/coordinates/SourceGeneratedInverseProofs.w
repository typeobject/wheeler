//! Derives declared generated-inverse proof rows from one local source module.

module wheeler.compiler.closure.source_generated_inverse_proofs;

import wheeler.compiler.compiler_token_limits;
import wheeler.compiler.keyword_tokens;
import wheeler.compiler.module_linker;
import wheeler.compiler.source_scalars;
import wheeler.compiler.tokens;

classical class SourceGeneratedInverseProofs {
  private const long MAX_CALLABLES = 64;
  private const long MAX_STRINGS = 256;

  /// Reports one complete generated-inverse proof table.
  public record SourceGeneratedInverseProofPlan(long proofCount, boolean valid) {}

  /// Reports homogeneous callable effects and their complete proof table.
  public record StructuredReversibleEvidencePlan(
    long reversibleCallableCount,
    long proofCount,
    boolean valid
  ) {}

  private boolean tokenMatchesBytes(
    borrow utf8 source,
    long token,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    borrow byteview strings,
    long start,
    long length
  ) {
    if (tokenLengths[token] != length) {
      return false;
    }

    long compared = 0;
    while (compared < length) limit 256 {
      long sourceValue = utf8Scalar(source, tokenStarts[token] + compared);
      if (127 < sourceValue) {
        return false;
      }

      if (sourceValue != strings[start + compared]) {
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
    long stringBytes,
    long stringCount,
    borrow mut words stringStarts,
    borrow mut words stringLengths,
    borrow mut words functionNameIds
  ) {
    long selected = -1;
    long callable = 0;
    while (callable < callableCount) limit MAX_CALLABLES {
      long nameId = functionNameIds[callable];
      if (nameId < 0) {
        return -1;
      }

      if (stringCount < nameId + 1) {
        return -1;
      }

      long start = stringStarts[nameId];
      long length = stringLengths[nameId];
      if (start < 0) {
        return -1;
      }

      if (length < 1) {
        return -1;
      }

      if (stringBytes < start + length) {
        return -1;
      }

      long callableNameStart = start;
      long nameByte = 0;
      while (nameByte + 1 < length) limit 256 {
        if (strings[start + nameByte] == 58) {
          if (strings[start + nameByte + 1] == 58) {
            callableNameStart = start + nameByte + 2;
          }
        }

        nameByte += 1;
      }

      long callableNameLength = start + length - callableNameStart;
      if (
        tokenMatchesBytes(
          source,
          token,
          tokenStarts,
          tokenLengths,
          strings,
          callableNameStart,
          callableNameLength
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
    while (compared < length) limit 256 {
      if (names[leftStart + compared] != names[rightStart + compared]) {
        return false;
      }

      compared += 1;
    }

    return true;
  }

  /// Validates homogeneous callable effects and publishes their exact proof rows.
  public StructuredReversibleEvidencePlan materializeStructuredReversibleEvidence(
    borrow utf8 source,
    long firstCallable,
    long callableCount,
    borrow mut words callableEffects,
    borrow byteview strings,
    long stringBytes,
    long stringCount,
    borrow mut words stringStarts,
    borrow mut words stringLengths,
    borrow mut words functionNameIds,
    borrow mut bytes proofNames,
    borrow mut words proofNameStarts,
    borrow mut words proofNameLengths,
    borrow mut words proofSubjects
  ) {
    assert(-1 < firstCallable);
    assert(0 < callableCount);
    assert(callableCount < MAX_CALLABLES + 1);
    assert(bufferLength(callableEffects) == 4096);
    assert(callableCount < 4096 - firstCallable + 1);
    long reversibleCallableCount = 0;
    boolean valid = true;
    long callable = 0;
    while (callable < callableCount) limit MAX_CALLABLES {
      long effect = callableEffects[firstCallable + callable];
      if (effect == 2) {
        reversibleCallableCount += 1;
      } else {
        if (effect != 0) {
          valid = false;
        }
      }

      callable += 1;
    }

    if (0 < reversibleCallableCount) {
      if (reversibleCallableCount != callableCount) {
        valid = false;
      }
    }

    long proofCount = 0;
    if (valid) {
      if (0 < reversibleCallableCount) {
        SourceGeneratedInverseProofPlan proofs = materializeSourceGeneratedInverseProofs(
          source,
          callableCount,
          strings,
          stringBytes,
          stringCount,
          stringStarts,
          stringLengths,
          functionNameIds,
          proofNames,
          proofNameStarts,
          proofNameLengths,
          proofSubjects
        );
        valid = proofs.valid;
        proofCount = proofs.proofCount;
      }
    }

    return new StructuredReversibleEvidencePlan(reversibleCallableCount, proofCount, valid);
  }

  /// Publishes exact `theorem name proves inverse(callable);` rows in source order.
  public SourceGeneratedInverseProofPlan materializeSourceGeneratedInverseProofs(
    borrow utf8 source,
    long callableCount,
    borrow byteview strings,
    long stringBytes,
    long stringCount,
    borrow mut words stringStarts,
    borrow mut words stringLengths,
    borrow mut words functionNameIds,
    borrow mut bytes proofNames,
    borrow mut words proofNameStarts,
    borrow mut words proofNameLengths,
    borrow mut words proofSubjects
  ) {
    assert(0 < callableCount);
    assert(callableCount < MAX_CALLABLES + 1);
    assert(-1 < stringBytes);
    assert(stringBytes < bufferLength(strings) + 1);
    assert(0 < stringCount);
    assert(stringCount < MAX_STRINGS + 1);
    assert(bufferLength(stringStarts) == MAX_STRINGS);
    assert(bufferLength(stringLengths) == MAX_STRINGS);
    assert(bufferLength(functionNameIds) == MAX_CALLABLES);
    assert(bufferLength(proofNames) == 16384);
    assert(bufferLength(proofNameStarts) == MAX_CALLABLES);
    assert(bufferLength(proofNameLengths) == MAX_CALLABLES);
    assert(bufferLength(proofSubjects) == MAX_CALLABLES);

    region scanning = new region(/* bytes= */ 116224, /* allocations= */ 7);
    words tokenKinds = allocate(scanning, MAX_COMPILER_TOKENS);
    words tokenStarts = allocate(scanning, MAX_COMPILER_TOKENS);
    words tokenLengths = allocate(scanning, MAX_COMPILER_TOKENS);
    bytes stagedProofNames = allocateBytes(scanning, /* length= */ 16384);
    words stagedProofNameStarts = allocate(scanning, MAX_CALLABLES);
    words stagedProofNameLengths = allocate(scanning, MAX_CALLABLES);
    words stagedProofSubjects = allocate(scanning, MAX_CALLABLES);
    long tokenCount = scanSemanticTokens(source, tokenKinds, tokenStarts, tokenLengths);
    boolean valid = -1 < tokenCount;
    long proofCount = 0;
    long proofNameCursor = 0;
    long token = 0;
    while (valid) limit 1 {
      while (token < tokenCount) limit MAX_COMPILER_TOKENS {
        if (tokenHash(source, tokenStarts, tokenLengths, token) == TOKEN_THEOREM) {
          if (tokenCount < token + 8) {
            valid = false;
            break;
          }

          if (proofCount == MAX_CALLABLES) {
            valid = false;
            break;
          }

          boolean formValid = tokenKinds[token + 1] == 1;
          if (tokenHash(source, tokenStarts, tokenLengths, token + 2) != TOKEN_PROVES) {
            formValid = false;
          }

          if (
            tokenHash(source, tokenStarts, tokenLengths, token + 3) != TOKEN_INVERSE
          ) {
            formValid = false;
          }

          if (
            punctuationAt(source, tokenKinds, tokenStarts, token + 4, PUNCTUATION_OPEN_PAREN)
              == false
          ) {
            formValid = false;
          }

          if (tokenKinds[token + 5] != 1) {
            formValid = false;
          }

          if (
            punctuationAt(source, tokenKinds, tokenStarts, token + 6, PUNCTUATION_CLOSE_PAREN)
              == false
          ) {
            formValid = false;
          }

          if (
            punctuationAt(source, tokenKinds, tokenStarts, token + 7, PUNCTUATION_SEMICOLON)
              == false
          ) {
            formValid = false;
          }

          long proofLength = tokenLengths[token + 1];
          if (proofLength < 1) {
            formValid = false;
          }

          if (256 < proofLength) {
            formValid = false;
          }

          long subject = subjectCallable(
            source,
            token + 5,
            callableCount,
            tokenStarts,
            tokenLengths,
            strings,
            stringBytes,
            stringCount,
            stringStarts,
            stringLengths,
            functionNameIds
          );
          if (subject < 0) {
            formValid = false;
          }

          if (16384 < proofNameCursor + proofLength) {
            formValid = false;
          }

          long proofNameByte = 0;
          while (proofNameByte < proofLength) limit 256 {
            long nameValue = utf8Scalar(source, tokenStarts[token + 1] + proofNameByte);
            if (127 < nameValue) {
              formValid = false;
            } else {
              setByte(stagedProofNames, proofNameCursor + proofNameByte, nameValue);
            }

            proofNameByte += 1;
          }

          long earlierProof = 0;
          while (earlierProof < proofCount) limit MAX_CALLABLES {
            if (stagedProofNameLengths[earlierProof] == proofLength) {
              if (
                sameProofName(
                  stagedProofNames,
                  stagedProofNameStarts[earlierProof],
                  proofNameCursor,
                  proofLength
                )
              ) {
                formValid = false;
              }
            }

            if (stagedProofSubjects[earlierProof] == subject) {
              formValid = false;
            }

            earlierProof += 1;
          }

          if (formValid == false) {
            valid = false;
            break;
          }

          set(stagedProofNameStarts, proofCount, proofNameCursor);
          set(stagedProofNameLengths, proofCount, proofLength);
          set(stagedProofSubjects, proofCount, subject);
          proofNameCursor += proofLength;
          proofCount += 1;
          token += 7;
        }

        token += 1;
      }

      break;
    }

    if (proofCount != callableCount) {
      valid = false;
    }

    if (valid) {
      long publishedProof = 0;
      while (publishedProof < proofCount) limit MAX_CALLABLES {
        set(proofNameStarts, publishedProof, stagedProofNameStarts[publishedProof]);
        set(proofNameLengths, publishedProof, stagedProofNameLengths[publishedProof]);
        set(proofSubjects, publishedProof, stagedProofSubjects[publishedProof]);
        publishedProof += 1;
      }

      long publishedNameByte = 0;
      while (publishedNameByte < proofNameCursor) limit 16384 {
        setByte(proofNames, publishedNameByte, stagedProofNames[publishedNameByte]);
        publishedNameByte += 1;
      }
    } else {
      proofCount = 0;
    }

    drop(stagedProofSubjects);
    drop(stagedProofNameLengths);
    drop(stagedProofNameStarts);
    drop(stagedProofNames);
    drop(tokenLengths);
    drop(tokenStarts);
    drop(tokenKinds);
    drop(scanning);
    return new SourceGeneratedInverseProofPlan(proofCount, valid);
  }
}
