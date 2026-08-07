//! Parses bounded helper parameter names and canonical local type codes.

module wheeler.compiler.helper_parameter_types;

import wheeler.compiler.helper_abi;
import wheeler.compiler.keyword_tokens;
import wheeler.compiler.source_scalars;
import wheeler.compiler.tokens;
import wheeler.compiler.type_codes;

classical class HelperParameterTypes {
  /// Carries one parsed helper parameter and the following token.
  public record HelperParameter(long type, long nameToken, long nextToken, boolean valid) {}

  private HelperParameter invalidParameter() {
    return new HelperParameter(0, 0, 0, false);
  }

  /// Parses one signed owner-free parameter or one primitive borrow.
  public HelperParameter parseHelperParameter(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long cursor
  ) {
    long typeHash = tokenHash(source, tokenStarts, tokenLengths, cursor);
    long type = TYPE_SIGNED;
    long nameToken = cursor + 1;
    if (typeHash == TOKEN_LONG) {
      if (
        punctuationAt(source, tokenKinds, tokenStarts, cursor + 1, PUNCTUATION_OPEN_SQUARE)
      ) {
        long lengthToken = cursor + 2;
        if (tokenKinds[lengthToken] == 2) {} else {
          return invalidParameter();
        }

        if (signedNumberValid(source, tokenStarts, tokenLengths, lengthToken)) {} else {
          return invalidParameter();
        }

        long arrayLength = parsedSignedNumber(source, tokenStarts, tokenLengths, lengthToken);
        if (0 < arrayLength) {} else {
          return invalidParameter();
        }

        if (arrayLength < MAX_NATIVE_FIXED_ARRAY_LENGTH + 1) {} else {
          return invalidParameter();
        }

        if (
          punctuationAt(source, tokenKinds, tokenStarts, cursor + 3, PUNCTUATION_CLOSE_SQUARE)
        ) {} else {
          return invalidParameter();
        }

        type = TYPE_ARRAY + arrayLength * TYPE_SOURCE_METADATA_SCALE;
        nameToken = cursor + 4;
      }
    } else {
      if (typeHash == TOKEN_BORROW) {} else {
        return invalidParameter();
      }

      long borrowedTypeToken = cursor + 1;
      boolean mutable = tokenHash(source, tokenStarts, tokenLengths, borrowedTypeToken)
        == TOKEN_MUT;
      if (mutable) {
        borrowedTypeToken += 1;
      }

      long borrowedType = tokenHash(source, tokenStarts, tokenLengths, borrowedTypeToken);
      type = 0;
      if (borrowedType == TOKEN_UTF8) {
        if (mutable) {
          return invalidParameter();
        }

        type = TYPE_UTF8_BORROW;
      }

      if (borrowedType == TOKEN_BYTES) {
        type = TYPE_BYTES_BORROW;
      }

      if (borrowedType == TOKEN_BYTEVIEW) {
        if (mutable) {
          return invalidParameter();
        }

        type = TYPE_BYTE_VIEW;
      }

      if (borrowedType == TOKEN_WORDS) {
        type = TYPE_WORDS_BORROW;
      }

      if (borrowedType == TOKEN_REGION) {
        type = TYPE_REGION_BORROW;
      }

      if (borrowedType == TOKEN_LONGMAP) {
        type = TYPE_LONG_MAP_BORROW;
      }

      if (0 < type) {} else {
        return invalidParameter();
      }

      nameToken = borrowedTypeToken + 1;
    }

    if (tokenKinds[nameToken] == 1) {} else {
      return invalidParameter();
    }

    if (tokenLengths[nameToken] < 257) {} else {
      return invalidParameter();
    }

    return new HelperParameter(type, nameToken, nameToken + 1, true);
  }

  /// Returns one indexed parameter from a validated helper signature.
  public HelperParameter helperParameterAt(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long signatureStart,
    long index
  ) {
    long cursor = signatureStart + 3;
    long parameter = 0;
    while (parameter < index) limit MAX_SCALAR_HELPER_PARAMETERS {
      HelperParameter skipped = parseHelperParameter(
        source,
        tokenKinds,
        tokenStarts,
        tokenLengths,
        cursor
      );
      if (skipped.valid) {} else {
        return invalidParameter();
      }

      cursor = skipped.nextToken + 1;
      parameter += 1;
    }

    return parseHelperParameter(source, tokenKinds, tokenStarts, tokenLengths, cursor);
  }

  private long helperParameterType(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long signatureStart,
    long parameterCount,
    long index
  ) {
    if (index < parameterCount) {
      HelperParameter parameter = helperParameterAt(
        source,
        tokenKinds,
        tokenStarts,
        tokenLengths,
        signatureStart,
        index
      );
      if (parameter.valid) {
        return parameter.type;
      }
    }

    return 0;
  }

  /// Builds one immutable canonical parameter-type column from a parsed signature.
  public long[16] parsedHelperParameterTypes(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long signatureStart,
    long parameterCount
  ) {
    return new long[16](
      helperParameterType(
        source,
        tokenKinds,
        tokenStarts,
        tokenLengths,
        signatureStart,
        parameterCount,
        0
      ),
      helperParameterType(
        source,
        tokenKinds,
        tokenStarts,
        tokenLengths,
        signatureStart,
        parameterCount,
        1
      ),
      helperParameterType(
        source,
        tokenKinds,
        tokenStarts,
        tokenLengths,
        signatureStart,
        parameterCount,
        2
      ),
      helperParameterType(
        source,
        tokenKinds,
        tokenStarts,
        tokenLengths,
        signatureStart,
        parameterCount,
        3
      ),
      helperParameterType(
        source,
        tokenKinds,
        tokenStarts,
        tokenLengths,
        signatureStart,
        parameterCount,
        4
      ),
      helperParameterType(
        source,
        tokenKinds,
        tokenStarts,
        tokenLengths,
        signatureStart,
        parameterCount,
        5
      ),
      helperParameterType(
        source,
        tokenKinds,
        tokenStarts,
        tokenLengths,
        signatureStart,
        parameterCount,
        6
      ),
      helperParameterType(
        source,
        tokenKinds,
        tokenStarts,
        tokenLengths,
        signatureStart,
        parameterCount,
        7
      ),
      helperParameterType(
        source,
        tokenKinds,
        tokenStarts,
        tokenLengths,
        signatureStart,
        parameterCount,
        8
      ),
      helperParameterType(
        source,
        tokenKinds,
        tokenStarts,
        tokenLengths,
        signatureStart,
        parameterCount,
        9
      ),
      helperParameterType(
        source,
        tokenKinds,
        tokenStarts,
        tokenLengths,
        signatureStart,
        parameterCount,
        10
      ),
      helperParameterType(
        source,
        tokenKinds,
        tokenStarts,
        tokenLengths,
        signatureStart,
        parameterCount,
        11
      ),
      helperParameterType(
        source,
        tokenKinds,
        tokenStarts,
        tokenLengths,
        signatureStart,
        parameterCount,
        12
      ),
      helperParameterType(
        source,
        tokenKinds,
        tokenStarts,
        tokenLengths,
        signatureStart,
        parameterCount,
        13
      ),
      helperParameterType(
        source,
        tokenKinds,
        tokenStarts,
        tokenLengths,
        signatureStart,
        parameterCount,
        14
      ),
      helperParameterType(
        source,
        tokenKinds,
        tokenStarts,
        tokenLengths,
        signatureStart,
        parameterCount,
        15
      )
    );
  }
}
