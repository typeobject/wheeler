//! Classifies short source words through exact length-bearing ASCII lanes.

module wheeler.compiler.source_short_words;

import wheeler.compiler.boolean_tokens;
import wheeler.compiler.keyword_tokens;

classical class SourceShortWords {
  private const long WORD_RADIX = 128;
  private const long WORD_SENTINEL = 1;
  private const long ASCII_E = 101;
  private const long ASCII_N = 110;
  private const long ASCII_U = 117;
  private const long ASCII_M = 109;
  private const long ENUM_HEAD = (
    ((WORD_SENTINEL * WORD_RADIX + ASCII_E) * WORD_RADIX + ASCII_N) * WORD_RADIX + ASCII_U
  ) * WORD_RADIX + ASCII_M;

  private long shortestSourceWord(long head) {
    // The sentinel and four base-128 bytes occupy at most 29 bits.
    long maximumHead = 536870911;
    if (maximumHead < head) {
      return 0;
    }

    if (head == 412874597) {
      return TOKEN_DONE;
    }

    if (head == 477657573) {
      return TOKEN_CASE;
    }

    if (head == 480032752) {
      return TOKEN_DROP;
    }

    if (head == ENUM_HEAD) {
      return TOKEN_ENUM;
    }

    if (head == 29926) {
      return TOKEN_IF;
    }

    if (head == 496760679) {
      return TOKEN_LONG;
    }

    if (head == 498627822) {
      return TOKEN_MAIN;
    }

    if (head == 3898100) {
      return TOKEN_MUT;
    }

    if (head == 3912439) {
      return TOKEN_NEW;
    }

    if (head == 3947252) {
      return TOKEN_PUT;
    }

    if (head == 3977974) {
      return TOKEN_REV;
    }

    if (head == 3994356) {
      return TOKEN_SET;
    }

    if (head == 513307635) {
      return TOKEN_TAGS;
    }

    if (head == 513374708) {
      return TOKEN_TEST;
    }

    if (head == 513587941) {
      return TOKEN_TRUE;
    }

    if (head == 515715896) {
      return TOKEN_UTF8;
    }

    if (head == 517731556) {
      return TOKEN_VOID;
    }

    return 0;
  }

  private long middleSourceWord(long head) {
    // Five through six bytes place the sentinel at bit 35 or bit 42.
    if (head < 34359738368) {
      return 0;
    }

    long maximumHead = 562949953421311;
    if (maximumHead < head) {
      return 0;
    }

    if (head == 7762054052212) {
      return TOKEN_ASSERT;
    }

    if (head == 7795338164215) {
      return TOKEN_BORROW;
    }

    if (head == 60922082035) {
      return TOKEN_BYTES;
    }

    if (head == 61140169459) {
      return TOKEN_CASES;
    }

    if (head == 61162945011) {
      return TOKEN_CLASS;
    }

    if (head == 61169449460) {
      return TOKEN_CONST;
    }

    if (head == 61704321401) {
      return TOKEN_ENTRY;
    }

    if (head == 61945362917) {
      return TOKEN_FALSE;
    }

    if (head == 8035315218804) {
      return TOKEN_IMPORT;
    }

    if (head == 63572767988) {
      return TOKEN_LIMIT;
    }

    if (head == 8137314302579) {
      return TOKEN_LIMITS;
    }

    if (head == 8169532289780) {
      return TOKEN_MAP_GET;
    }

    if (head == 8169532305651) {
      return TOKEN_MAP_HAS;
    }

    if (head == 8173265974885) {
      return TOKEN_MODULE;
    }

    if (head == 8277173580531) {
      return TOKEN_PROVES;
    }

    if (head == 8277951460579) {
      return TOKEN_PUBLIC;
    }

    if (head == 8342378117476) {
      return TOKEN_RECORD;
    }

    if (head == 8342386407406) {
      return TOKEN_REGION;
    }

    if (head == 8342413867374) {
      return TOKEN_RETURN;
    }

    if (head == 65458041317) {
      return TOKEN_SLICE;
    }

    if (head == 65474689637) {
      return TOKEN_STATE;
    }

    if (head == 65474754675) {
      return TOKEN_STEPS;
    }

    if (head == 66523395685) {
      return TOKEN_WHILE;
    }

    if (head == 66538222195) {
      return TOKEN_WORDS;
    }

    return 0;
  }

  private long longerSourceWord(long head) {
    // Seven through eight bytes place the sentinel at bit 49 or bit 56.
    if (head < 562949953421312) {
      return 0;
    }

    long maximumHead = 144115188075855871;
    if (maximumHead < head) {
      return 0;
    }

    if (head == 997802466963694) {
      return TOKEN_BOOLEAN;
    }

    if (head == 127762866191889143) {
      return TOKEN_BYTEVIEW;
    }

    if (head == 128281423354886004) {
      return TOKEN_COHERENT;
    }

    if (head == 1023985678285177) {
      return TOKEN_HISTORY;
    }

    if (head == 1028556297386469) {
      return TOKEN_INVERSE;
    }

    if (head == 1041782653284592) {
      return TOKEN_LONGMAP;
    }

    if (head == 1059476607629925) {
      return TOKEN_PRIVATE;
    }

    if (head == 1067829478341093) {
      return TOKEN_REVERSE;
    }

    if (head == 1072226914695781) {
      return TOKEN_SET_BYTE;
    }

    if (head == 1076724108145389) {
      return TOKEN_THEOREM;
    }

    if (head == 1085283159799668) {
      return TOKEN_VARIANT;
    }

    return 0;
  }

  /// Classifies sentinel-prefixed source words of two through eight ASCII bytes.
  public long sourceShortWordCode(long head, long tail) {
    boolean emptyTail = tail == 1;
    if (emptyTail == false) {
      return 0;
    }

    long unknown = 0;
    long shortest = shortestSourceWord(head);
    if (unknown < shortest) {
      return shortest;
    }

    long middle = middleSourceWord(head);
    if (unknown < middle) {
      return middle;
    }

    long longer = longerSourceWord(head);
    return longer;
  }
}
