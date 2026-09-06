/// Pure-Dart parsers for the BLE payloads consumer scales actually emit.
///
/// Why this exists when the factory ships an SDK: the Lefu/Shenzhen Unique
/// Scales SDK (`PPBluetoothKit`) is a closed binary that needs an appKey, an
/// appSecret and an encrypted `lefu.config` licence blob before it will
/// initialise. That is a hard dependency on the vendor for something as basic as
/// reading a number off a scale. Owning the frame layer means:
///
///   * development can start before the credentials arrive
///   * the app keeps working if a licence lapses or is revoked
///   * a second-source scale can be added without rewriting the app
///   * the parsing can be unit-tested, which a vendor binary cannot be
///
/// Every parser here is transcribed from published reverse-engineering or from
/// the Bluetooth SIG specification, with the source named on each class. None of
/// it is derived from decompiling the vendor SDK.
///
/// All of this is byte-level and deterministic, so it is covered by tests in
/// test/frames_test.dart against captured ground-truth frames.
library;

import 'dart:typed_data';

/// Whether the scale considers the reading settled.
enum WeightStability {
  /// Still moving. Show it live, never log it.
  live,

  /// Locked. This is the reading to store.
  stable,

  /// The scale reported the load was removed.
  removed,
}

/// One decoded measurement frame.
class ScaleFrame {
  const ScaleFrame({
    required this.weightKg,
    required this.stability,
    this.impedanceOhm,
    this.secondaryImpedanceOhm,
    this.heartRateBpm,
    this.deviceTimestamp,
    this.protocol,
  });

  final double weightKg;
  final WeightStability stability;

  /// Whole-body resistance in ohms, when the frame carried one.
  final double? impedanceOhm;

  /// Second impedance channel, present on dual-frequency hardware.
  final double? secondaryImpedanceOhm;

  final int? heartRateBpm;
  final DateTime? deviceTimestamp;

  /// Which parser produced this, for diagnostics and for the support inbox.
  final String? protocol;

  bool get isStable => stability == WeightStability.stable;
  bool get hasImpedance => impedanceOhm != null && impedanceOhm! > 0;

  @override
  String toString() => 'ScaleFrame(${weightKg.toStringAsFixed(2)} kg, '
      '${stability.name}, z=${impedanceOhm?.toStringAsFixed(0) ?? '-'}, '
      '$protocol)';
}

/// Thrown when bytes do not belong to the parser they were handed to. Callers
/// try parsers in order and move on; this is control flow, not an error worth
/// surfacing.
class FrameFormatException implements Exception {
  const FrameFormatException(this.message);
  final String message;
  @override
  String toString() => 'FrameFormatException: $message';
}

/// Interface every protocol adapter implements.
abstract class FrameParser {
  const FrameParser();

  String get name;

  /// Cheap check before attempting a parse.
  bool canParse(Uint8List data);

  /// Decode, or throw [FrameFormatException].
  ScaleFrame parse(Uint8List data);
}

// ---------------------------------------------------------------------------
// Lefu / Fitdays 0xFFB0 "AC02"
// ---------------------------------------------------------------------------

/// The protocol used by Lefu-built scales that expose GATT service 0xFFB0.
///
/// Source: public reverse-engineering in ble-scale-sync issue #254, which
/// decoded a Lefu/Fitdays OEM unit (Hutbit 218008 / WL292).
///
/// Layout — fixed 8-byte frames:
///
///     AC 02 | D0 D1 D2 D3 | STATUS | CKSUM
///     CKSUM = (D0 + D1 + D2 + D3 + STATUS) & 0xFF
///
/// For a weight notification D0..D1 are the weight as a big-endian uint16 in
/// tenths of a kilogram and D2..D3 are zero:
///
///     AC 02 [weight_hi] [weight_lo] 00 00 [STATUS] [CKSUM]
///     STATUS 0xCE = measuring   0xCA = stable
///
/// Ground truth from the capture: `ac 02 03 49 00 00 ca 16` decodes to
/// 0x0349 = 841 -> 84.1 kg, stable, checksum 0x16.
///
/// Body composition arrives separately in a 40-byte type-0xFF result frame
/// split across two notifications. The impedance offsets inside that frame are
/// NOT publicly decoded, so [LefuFfb0Parser] handles weight only and the
/// impedance path goes through the vendor SDK until the factory supplies the
/// frame map. See docs/01-factory-questions.md, question 6.
class LefuFfb0Parser extends FrameParser {
  const LefuFfb0Parser();

  static const int magic0 = 0xAC;
  static const int magic1 = 0x02;
  static const int statusMeasuring = 0xCE;
  static const int statusStable = 0xCA;

  /// GATT identifiers for this family.
  static const String serviceUuid = 'ffb0';
  static const String notifyCharacteristicUuid = 'ffb2';
  static const String writeCharacteristicUuid = 'ffb1';

  /// Manufacturer ID seen in the advertisement: 0x02AC, the frame magic read
  /// little-endian.
  static const int manufacturerId = 0x02AC;

  @override
  String get name => 'lefu-ffb0';

  @override
  bool canParse(Uint8List data) =>
      data.length == 8 && data[0] == magic0 && data[1] == magic1;

  static int checksum(Uint8List data) {
    var sum = 0;
    for (var i = 2; i <= 6; i++) {
      sum += data[i];
    }
    return sum & 0xFF;
  }

  @override
  ScaleFrame parse(Uint8List data) {
    if (!canParse(data)) {
      throw const FrameFormatException('not an AC02 frame');
    }
    final expected = checksum(data);
    if (expected != data[7]) {
      throw FrameFormatException(
        'checksum mismatch: expected 0x${expected.toRadixString(16)}, '
        'got 0x${data[7].toRadixString(16)}',
      );
    }

    final status = data[6];
    final raw = (data[2] << 8) | data[3];
    final weightKg = raw / 10.0;

    final stability = switch (status) {
      statusStable => WeightStability.stable,
      statusMeasuring => WeightStability.live,
      _ => WeightStability.live,
    };

    return ScaleFrame(
      weightKg: weightKg,
      stability: stability,
      protocol: 'lefu-ffb0',
    );
  }

  /// Build a command frame with a correct checksum.
  static Uint8List command({
    required int d0,
    required int d1,
    required int d2,
    required int d3,
    int status = 0xCC,
  }) {
    final f = Uint8List(8)
      ..[0] = magic0
      ..[1] = magic1
      ..[2] = d0 & 0xFF
      ..[3] = d1 & 0xFF
      ..[4] = d2 & 0xFF
      ..[5] = d3 & 0xFF
      ..[6] = status & 0xFF;
    f[7] = checksum(f);
    return f;
  }

  /// The handshake captured from a working session: enable notifications on
  /// FFB2, then write these to FFB1 in order.
  static List<Uint8List> handshake() => [
        command(d0: 0xFA, d1: 0x01, d2: 0x00, d3: 0x00),
        command(d0: 0xFB, d1: 0x02, d2: 0x1F, d3: 0xA5),
        command(d0: 0xFD, d1: 0xE2, d2: 0x01, d3: 0x01),
        command(d0: 0xFC, d1: 0x01, d2: 0x00, d3: 0x00),
        command(d0: 0xFE, d1: 0x06, d2: 0x00, d3: 0x00),
      ];
}

// ---------------------------------------------------------------------------
// Qingniu / QN / Yolanda
// ---------------------------------------------------------------------------

/// Qingniu ("QN-Scale") notify protocol, the most widely deployed Chinese BIA
/// stack after Lefu's. Included as a second-source adapter so a different
/// factory's hardware can be supported without touching the app.
///
/// Live-weight frame, opcode 0x10:
///   [0]    0x10
///   [3:5]  weight, uint16 big-endian
///   [5]    stable flag: 0x00 live, 0x01 final
///   [6:8]  R1 primary impedance, uint16 BE
///   [8:10] R2 secondary impedance, uint16 BE
///
/// The weight divisor is negotiated rather than fixed: frame 0x12 byte[10] == 1
/// means divide by 100, otherwise by 10. [divisor] carries that negotiated
/// value.
class QingniuParser extends FrameParser {
  const QingniuParser({this.divisor = 100});

  final int divisor;

  static const int opcodeLiveWeight = 0x10;
  static const String serviceUuidTypeA = 'ffe0';
  static const String serviceUuidTypeB = 'fff0';

  /// Vendor service 0xAE00 is a Qingniu-only tell and is the reliable way to
  /// identify one, since the advertised name is freely rebranded.
  static const String vendorServiceUuid = 'ae00';

  @override
  String get name => 'qingniu';

  @override
  bool canParse(Uint8List data) =>
      data.length >= 10 && data[0] == opcodeLiveWeight;

  @override
  ScaleFrame parse(Uint8List data) {
    if (!canParse(data)) {
      throw const FrameFormatException('not a QN 0x10 frame');
    }
    var weight = ((data[3] << 8) | data[4]) / divisor;

    // openScale's sanity fallback: an implausible result means the divisor was
    // wrong, so drop it by an order of magnitude.
    if (weight >= 250.0) weight /= 10.0;

    final r1 = ((data[6] << 8) | data[7]).toDouble();
    final r2 = ((data[8] << 8) | data[9]).toDouble();

    return ScaleFrame(
      weightKg: weight,
      stability:
          data[5] == 0x00 ? WeightStability.live : WeightStability.stable,
      impedanceOhm: r1 > 0 ? r1 : null,
      secondaryImpedanceOhm: r2 > 0 ? r2 : null,
      protocol: 'qingniu',
    );
  }
}

// ---------------------------------------------------------------------------
// Xiaomi MIBFS advertisement
// ---------------------------------------------------------------------------

/// Xiaomi Mi Body Composition Scale v2, decoded from advertisement service data
/// with no connection required.
///
/// Note the trap this parser exists to avoid: Xiaomi re-uses the Bluetooth SIG
/// service UUIDs 0x181B and 0x181D as advertisement service-data identifiers
/// while carrying an entirely non-SIG payload. Sniffing the UUID alone will
/// route these bytes into the SIG parser and produce garbage.
///
/// 13-byte payload under service data 0x181B:
///   [0]     unit: 0x02 kg, 0x03 lb
///   [1]     flags: bit1 impedance present, bit5 stabilised, bit7 load removed
///   [2:4]   year, uint16 LE      [4] month  [5] day
///   [6] hour [7] minute [8] second
///   [9:11]  impedance, uint16 LE, ohms
///   [11:13] weight, uint16 LE
///
/// Weight in kg is raw / 200.
class XiaomiMibfsParser extends FrameParser {
  const XiaomiMibfsParser();

  static const int payloadLength = 13;

  @override
  String get name => 'xiaomi-mibfs';

  @override
  bool canParse(Uint8List data) => data.length == payloadLength;

  @override
  ScaleFrame parse(Uint8List data) {
    if (!canParse(data)) {
      throw const FrameFormatException('not a 13-byte MIBFS payload');
    }
    final unit = data[0];
    final flags = data[1];
    final impedancePresent = (flags & 0x02) != 0;
    final stabilised = (flags & 0x20) != 0;
    final loadRemoved = (flags & 0x80) != 0;

    final rawWeight = data[11] | (data[12] << 8);
    final weightKg = switch (unit) {
      0x03 => rawWeight * 0.01 * 0.453592,
      _ => rawWeight / 200.0,
    };

    double? impedance;
    if (impedancePresent) {
      final z = (data[9] | (data[10] << 8)).toDouble();
      // The scale emits 0 before contact and saturates implausibly high on a
      // bad reading; both are rejected rather than passed to an equation.
      if (z > 0 && z < 3000) impedance = z;
    }

    DateTime? timestamp;
    final year = data[2] | (data[3] << 8);
    if (year > 2000 && year < 2100) {
      try {
        timestamp = DateTime(year, data[4], data[5], data[6], data[7], data[8]);
      } on ArgumentError {
        timestamp = null;
      }
    }

    final stability = loadRemoved
        ? WeightStability.removed
        : (stabilised ? WeightStability.stable : WeightStability.live);

    return ScaleFrame(
      weightKg: weightKg,
      stability: stability,
      impedanceOhm: impedance,
      deviceTimestamp: timestamp,
      protocol: 'xiaomi-mibfs',
    );
  }
}

// ---------------------------------------------------------------------------
// Bluetooth SIG Weight Scale / Body Composition
// ---------------------------------------------------------------------------

/// The Bluetooth SIG standard Weight Measurement characteristic (0x2A9D under
/// Weight Scale Service 0x181D).
///
/// Worth supporting properly: a well-behaved scale may simply implement the
/// standard, and if the factory's firmware can be asked to, that is by far the
/// best outcome — no vendor SDK, no licence blob, no reverse engineering.
///
///   [0]     flags:
///             bit0  0 = SI (kg), 1 = Imperial (lb)
///             bit1  timestamp present
///             bit2  user ID present
///             bit3  BMI and height present
///   [1:3]   weight, uint16 LE. SI resolution 0.005 kg; imperial 0.01 lb.
///   then, in order, the optional fields the flags announced.
class SigWeightMeasurementParser extends FrameParser {
  const SigWeightMeasurementParser();

  static const String weightScaleService = '181d';
  static const String bodyCompositionService = '181b';
  static const String weightMeasurementCharacteristic = '2a9d';
  static const String bodyCompositionMeasurementCharacteristic = '2a9c';

  @override
  String get name => 'sig-weight';

  @override
  bool canParse(Uint8List data) => data.length >= 3;

  @override
  ScaleFrame parse(Uint8List data) {
    if (!canParse(data)) {
      throw const FrameFormatException('too short for a weight measurement');
    }
    final flags = data[0];
    final imperial = (flags & 0x01) != 0;
    final hasTimestamp = (flags & 0x02) != 0;

    final raw = data[1] | (data[2] << 8);
    final weightKg = imperial ? raw * 0.01 * 0.45359237 : raw * 0.005;

    DateTime? timestamp;
    if (hasTimestamp && data.length >= 10) {
      final year = data[3] | (data[4] << 8);
      if (year > 2000 && year < 2100) {
        try {
          timestamp =
              DateTime(year, data[5], data[6], data[7], data[8], data[9]);
        } on ArgumentError {
          timestamp = null;
        }
      }
    }

    return ScaleFrame(
      weightKg: weightKg,
      // The standard characteristic is only sent once the reading has settled.
      stability: WeightStability.stable,
      deviceTimestamp: timestamp,
      protocol: 'sig-weight',
    );
  }
}

// ---------------------------------------------------------------------------
// Registry
// ---------------------------------------------------------------------------

/// Tries each known parser in turn.
///
/// Order matters: the strictest signatures go first so a loose parser cannot
/// claim bytes that belong to a specific one. The SIG parser is last because
/// its `canParse` is only a length check.
class FrameParserRegistry {
  const FrameParserRegistry([this.parsers = defaultParsers]);

  static const defaultParsers = <FrameParser>[
    LefuFfb0Parser(),
    XiaomiMibfsParser(),
    QingniuParser(),
    SigWeightMeasurementParser(),
  ];

  final List<FrameParser> parsers;

  /// Returns null when nothing recognised the bytes, which is normal — scales
  /// emit battery, time-sync and keep-alive frames alongside measurements.
  ScaleFrame? tryParse(Uint8List data) {
    for (final p in parsers) {
      if (!p.canParse(data)) continue;
      try {
        return p.parse(data);
      } on FrameFormatException {
        continue;
      }
    }
    return null;
  }
}
