//! Classifies exact words in the closed canonical-manifest vocabulary.

module wheeler.compiler.packages.manifest_words;

classical class PackageManifestWords {
  /// Exact schema key.
  public const long WORD_SCHEMA = 1;
  /// Exact package key.
  public const long WORD_PACKAGE = 2;
  /// Exact name key.
  public const long WORD_NAME = 3;
  /// Exact version key.
  public const long WORD_VERSION = 4;
  /// Exact profile key.
  public const long WORD_PROFILE = 5;
  /// Exact targets key.
  public const long WORD_TARGETS = 6;
  /// Exact kind key.
  public const long WORD_KIND = 7;
  /// Exact root key.
  public const long WORD_ROOT = 8;
  /// Exact module key.
  public const long WORD_MODULE = 9;
  /// Exact sources key.
  public const long WORD_SOURCES = 10;
  /// Exact test key.
  public const long WORD_TEST = 11;
  /// Exact dependencies key.
  public const long WORD_DEPENDENCIES = 12;
  /// Exact capabilities key.
  public const long WORD_CAPABILITIES = 13;
  /// Exact path key.
  public const long WORD_PATH = 14;
  /// Exact true scalar.
  public const long WORD_TRUE = 15;
  /// Exact false scalar.
  public const long WORD_FALSE = 16;
  /// Exact deployable kind.
  public const long WORD_DEPLOYABLE = 17;
  /// Exact library kind.
  public const long WORD_LIBRARY = 18;
  /// Exact tool kind.
  public const long WORD_TOOL = 19;
  /// Exact normal dependency kind.
  public const long WORD_NORMAL = 20;
  /// Exact development dependency kind.
  public const long WORD_DEVELOPMENT = 21;
  /// Exact build dependency kind.
  public const long WORD_BUILD = 22;
  /// Exact schema-version scalar 1.
  public const long WORD_SCHEMA_VERSION = 23;

  /// Recognizes only the closed manifest vocabulary at a scalar boundary.
  /// Length and both base-128 lanes are exact, not hashes. The first lane holds
  /// eight ASCII bytes and the second holds four. Neither lane can overflow.
  public long manifestRangeWord(borrow utf8 source, long start, long length) {
    if (start < 0) {
      return 0;
    }
    if (length < 1) {
      return 0;
    }
    long maximumWordLength = 12;
    if (maximumWordLength < length) {
      return 0;
    }
    long capacity = bufferLength(source);
    long lastStart = capacity - length;
    if (lastStart < start) {
      return 0;
    }

    long head = 0;
    long tail = 0;
    long offset = 0;
    boolean ascii = true;
    long lastAscii = 127;
    while (offset < length) limit 12 {
      long index = start + offset;
      long scalar = utf8Scalar(source, index);
      long nextHead = appendWordHead(head, scalar, offset);
      head = nextHead;
      long nextTail = appendWordTail(tail, scalar, offset);
      tail = nextTail;
      offset += 1;
      if (lastAscii < scalar) {
        ascii = false;
        offset = length;
      }
    }

    long word = completedManifestWord(length, head, tail, ascii);
    return word;
  }

  private long appendWordHead(long head, long scalar, long offset) {
    long lastHeadOffset = 7;
    if (lastHeadOffset < offset) {
      return head;
    }
    long prefix = head * 128;
    return prefix + scalar;
  }

  private long appendWordTail(long tail, long scalar, long offset) {
    if (offset < 8) {
      return tail;
    }
    long prefix = tail * 128;
    return prefix + scalar;
  }

  private long completedManifestWord(long length, long head, long tail, boolean ascii) {
    if (ascii == false) {
      return 0;
    }
    long unknownWord = 0;
    long header = headerAndTargetWord(length, head, tail);
    if (unknownWord < header) {
      return header;
    }
    long collection = collectionAndTestWord(length, head, tail);
    if (unknownWord < collection) {
      return collection;
    }
    long value = kindAndVersionWord(length, head, tail);
    return value;
  }

  // Match length and both lanes before returning a word code.
  // The three groups keep each retained frame within its existing 255-local limit.
  private long headerAndTargetWord(long length, long head, long tail) {
    long schemaLength = 6;
    long schemaHead = 3978164795105;
    long schemaTail = 0;
    boolean schema = matchesManifestWord(length, head, tail, schemaLength, schemaHead, schemaTail);
    if (schema == true) {
      return WORD_SCHEMA;
    }
    long packageLength = 7;
    long packageHead = 495940904973285;
    long packageTail = 0;
    boolean package = matchesManifestWord(length, head, tail, packageLength, packageHead, packageTail);
    if (package == true) {
      return WORD_PACKAGE;
    }
    long nameLength = 4;
    long nameHead = 232290021;
    long nameTail = 0;
    boolean name = matchesManifestWord(length, head, tail, nameLength, nameHead, nameTail);
    if (name == true) {
      return WORD_NAME;
    }
    long versionLength = 7;
    long versionHead = 522470666434542;
    long versionTail = 0;
    boolean version = matchesManifestWord(length, head, tail, versionLength, versionHead, versionTail);
    if (version == true) {
      return WORD_VERSION;
    }
    long profileLength = 7;
    long profileHead = 496528231396965;
    long profileTail = 0;
    boolean profile = matchesManifestWord(length, head, tail, profileLength, profileHead, profileTail);
    if (profile == true) {
      return WORD_PROFILE;
    }
    long targetsLength = 7;
    long targetsHead = 513537109228147;
    long targetsTail = 0;
    boolean targets = matchesManifestWord(length, head, tail, targetsLength, targetsHead, targetsTail);
    if (targets == true) {
      return WORD_TARGETS;
    }
    long kindLength = 4;
    long kindHead = 226129764;
    long kindTail = 0;
    boolean kind = matchesManifestWord(length, head, tail, kindLength, kindHead, kindTail);
    if (kind == true) {
      return WORD_KIND;
    }
    long rootLength = 4;
    long rootHead = 240908276;
    long rootTail = 0;
    boolean root = matchesManifestWord(length, head, tail, rootLength, rootHead, rootTail);
    if (root == true) {
      return WORD_ROOT;
    }
    return 0;
  }

  private long collectionAndTestWord(long length, long head, long tail) {
    long moduleLength = 6;
    long moduleHead = 3775219463781;
    long moduleTail = 0;
    boolean module = matchesManifestWord(length, head, tail, moduleLength, moduleHead, moduleTail);
    if (module == true) {
      return WORD_MODULE;
    }
    long sourcesLength = 7;
    long sourcesHead = 509620927394547;
    long sourcesTail = 0;
    boolean sources = matchesManifestWord(length, head, tail, sourcesLength, sourcesHead, sourcesTail);
    if (sources == true) {
      return WORD_SOURCES;
    }
    long testLength = 4;
    long testHead = 244939252;
    long testTail = 0;
    boolean test = matchesManifestWord(length, head, tail, testLength, testHead, testTail);
    if (test == true) {
      return WORD_TEST;
    }
    long dependenciesLength = 12;
    long dependenciesHead = 56743073674769134;
    long dependenciesTail = 209351411;
    boolean dependencies = matchesManifestWord(
      length, head, tail, dependenciesLength, dependenciesHead, dependenciesTail
    );
    if (dependencies == true) {
      return WORD_DEPENDENCIES;
    }
    long capabilitiesLength = 12;
    long capabilitiesHead = 56162530436478569;
    long capabilitiesTail = 245002995;
    boolean capabilities = matchesManifestWord(
      length, head, tail, capabilitiesLength, capabilitiesHead, capabilitiesTail
    );
    if (capabilities == true) {
      return WORD_CAPABILITIES;
    }
    long pathLength = 4;
    long pathHead = 236485224;
    long pathTail = 0;
    boolean path = matchesManifestWord(length, head, tail, pathLength, pathHead, pathTail);
    if (path == true) {
      return WORD_PATH;
    }
    long trueLength = 4;
    long trueHead = 245152485;
    long trueTail = 0;
    boolean trueValue = matchesManifestWord(length, head, tail, trueLength, trueHead, trueTail);
    if (trueValue == true) {
      return WORD_TRUE;
    }
    long falseLength = 5;
    long falseHead = 27585624549;
    long falseTail = 0;
    boolean falseValue = matchesManifestWord(length, head, tail, falseLength, falseHead, falseTail);
    if (falseValue == true) {
      return WORD_FALSE;
    }
    return 0;
  }

  private long kindAndVersionWord(long length, long head, long tail) {
    long deployableLength = 10;
    long deployableHead = 56743075556258018;
    long deployableTail = 13925;
    boolean deployable = matchesManifestWord(
      length, head, tail, deployableLength, deployableHead, deployableTail
    );
    if (deployable == true) {
      return WORD_DEPLOYABLE;
    }
    long libraryLength = 7;
    long libraryHead = 478623343081849;
    long libraryTail = 0;
    boolean library = matchesManifestWord(length, head, tail, libraryLength, libraryHead, libraryTail);
    if (library == true) {
      return WORD_LIBRARY;
    }
    long toolLength = 4;
    long toolHead = 245102572;
    long toolTail = 0;
    boolean tool = matchesManifestWord(length, head, tail, toolLength, toolHead, toolTail);
    if (tool == true) {
      return WORD_TOOL;
    }
    long normalLength = 6;
    long normalHead = 3809608429804;
    long normalTail = 0;
    boolean normal = matchesManifestWord(length, head, tail, normalLength, normalHead, normalTail);
    if (normal == true) {
      return WORD_NORMAL;
    }
    long developmentLength = 11;
    long developmentHead = 56743279829186669;
    long developmentTail = 1668980;
    boolean development = matchesManifestWord(
      length, head, tail, developmentLength, developmentHead, developmentTail
    );
    if (development == true) {
      return WORD_DEVELOPMENT;
    }
    long buildLength = 5;
    long buildHead = 26553775716;
    long buildTail = 0;
    boolean build = matchesManifestWord(length, head, tail, buildLength, buildHead, buildTail);
    if (build == true) {
      return WORD_BUILD;
    }
    long schemaVersionLength = 1;
    long schemaVersionHead = 49;
    long schemaVersionTail = 0;
    boolean schemaVersion = matchesManifestWord(
      length, head, tail, schemaVersionLength, schemaVersionHead, schemaVersionTail
    );
    if (schemaVersion == true) {
      return WORD_SCHEMA_VERSION;
    }
    return 0;
  }

  private boolean matchesManifestWord(
    long length, long head, long tail, long expectedLength, long expectedHead, long expectedTail
  ) {
    boolean sameLength = length == expectedLength;
    if (sameLength == false) {
      return false;
    }
    boolean sameHead = head == expectedHead;
    if (sameHead == false) {
      return false;
    }
    return tail == expectedTail;
  }

}
