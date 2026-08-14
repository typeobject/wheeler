//! Encodes, validates, decodes, and reverses one bounded packet frame.
classical class ReversiblePacketCodec {
  record Packet(long version, long kind, long payload) {}

  variant DecodeResult {
    case Malformed(long code);
    case Value(Packet packet);
  }

  state long packet = 0;
  state long observed = 0;
  state long decodedVersion = 0;
  state long decodedKind = 0;
  state long decodedPayload = 0;
  state long malformedLength = 0;
  state long malformedChecksum = 0;

  /// Encodes the version, kind, payload, and checksum into four bytes.
  void encode(Packet value, borrow mut bytes output) {
    setByte(output, 0, value.version);
    setByte(output, 1, value.kind);
    setByte(output, 2, value.payload);
    setByte(output, 3, (value.version + value.kind + value.payload) % 256);
  }

  /// Decodes one canonical four-byte frame or returns a typed diagnostic.
  DecodeResult decode(borrow mut bytes source) {
    if (bufferLength(source) == 4) {
      long checksum = (source[0] + source[1] + source[2]) % 256;
      if (checksum == source[3]) {
        return new DecodeResult.Value(new Packet(source[0], source[1], source[2]));
      }

      return new DecodeResult.Malformed(2);
    }

    return new DecodeResult.Malformed(1);
  }

  /// Encodes the fixed frame fields into disjoint byte positions of one word.
  ///
  /// - Inverse: Subtracts the fields in reverse order and restores an empty word.
  rev void encodeWord() {
    packet += 3;
    packet += 1280;
    packet += 2752512;
  }

  /// Checks the generated word decoder.
  theorem packetDecoder proves inverse(encodeWord);

  /// Executes typed frame round trips and malformed-input paths.
  ///
  /// - Effects: Mutates fixture state and bounded region-owned byte buffers.
  entry void main() {
    region arena = new region(16, 3);
    long frameLength = 4;
    bytes frame = allocateBytes(arena, frameLength);
    bytes reencoded = allocateBytes(arena, frameLength);
    Packet input = new Packet(3, 5, 42);
    encode(input, frame);
    assert(frame[0] == 3);
    assert(frame[1] == 5);
    assert(frame[2] == 42);
    assert(frame[3] == 50);
    DecodeResult decoded = decode(frame);
    match (decoded) {
      case DecodeResult.Malformed(long initialCode) {
        malformedChecksum = initialCode;
      }
      case DecodeResult.Value(Packet decodedValue) {
        decodedVersion = decodedValue.version;
        decodedKind = decodedValue.kind;
        decodedPayload = decodedValue.payload;
        encode(decodedValue, reencoded);
      }
    }

    assert(reencoded[0] == frame[0]);
    assert(reencoded[1] == frame[1]);
    assert(reencoded[2] == frame[2]);
    assert(reencoded[3] == frame[3]);
    setByte(frame, 3, 0);
    DecodeResult damaged = decode(frame);
    match (damaged) {
      case DecodeResult.Malformed(long checksumCode) {
        malformedChecksum = checksumCode;
      }
      case DecodeResult.Value(Packet damagedValue) {
        decodedPayload = damagedValue.payload + 1;
      }
    }

    long shortLength = 3;
    bytes shortFrame = allocateBytes(arena, shortLength);
    DecodeResult short = decode(shortFrame);
    match (short) {
      case DecodeResult.Malformed(long lengthCode) {
        malformedLength = lengthCode;
      }
      case DecodeResult.Value(Packet shortValue) {
        decodedVersion = shortValue.version + 1;
      }
    }

    assert(decodedVersion == 3);
    assert(decodedKind == 5);
    assert(decodedPayload == 42);
    assert(malformedLength == 1);
    assert(malformedChecksum == 2);
    encodeWord();
    observed = packet;
    assert(observed == 2753795);

    reverse {
      encodeWord();
    }

    assert(packet == 0);
    drop(shortFrame);
    drop(reencoded);
    drop(frame);
    drop(arena);
  }
}
