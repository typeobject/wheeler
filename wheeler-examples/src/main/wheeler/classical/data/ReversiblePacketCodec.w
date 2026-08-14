//! Encodes and decodes one fixed-width packet through a generated inverse.
classical class ReversiblePacketCodec {
  state long packet = 0;
  state long observed = 0;

  /// Encodes the version, kind, and payload fields into disjoint byte positions.
  ///
  /// - Inverse: Subtracts the fields in reverse order and restores an empty packet.
  rev void encodePacket() {
    // Version 3 occupies bits 0 through 7.
    packet += 3;
    // Kind 5 occupies bits 8 through 15.
    packet += 1280;
    // Payload 42 occupies bits 16 through 23.
    packet += 2752512;
  }

  /// Checks the generated packet decoder.
  theorem packetDecoder proves inverse(encodePacket);

  /// Executes the exact packet round trip.
  ///
  /// - Effects: Mutates only fixture state and leaves `packet` empty.
  entry void main() {
    encodePacket();
    observed = packet;
    assert(observed == 2753795);

    reverse {
      encodePacket();
    }

    assert(packet == 0);
  }
}
