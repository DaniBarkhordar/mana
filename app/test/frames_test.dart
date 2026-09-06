import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mananu/core/scale/frames.dart';
import 'package:mananu/core/scale/scale_driver.dart';

Uint8List hex(String s) {
  final clean = s.replaceAll(' ', '');
  return Uint8List.fromList([
    for (var i = 0; i < clean.length; i += 2)
      int.parse(clean.substring(i, i + 2), radix: 16),
  ]);
}

void main() {
  group('Lefu / Shenzhen Unique Scales FFB0 "AC02"', () {
    const parser = LefuFfb0Parser();

    test('decodes the captured ground-truth frame', () {
      // From the published reverse-engineering capture:
      //   ac 02 03 49 00 00 ca 16
      // 0x0349 = 841 -> 84.1 kg, status 0xCA = stable.
      final frame = parser.parse(hex('ac02034900 00ca16'.replaceAll(' ', '')));
      expect(frame.weightKg, closeTo(84.1, 1e-9));
      expect(frame.stability, WeightStability.stable);
      expect(frame.protocol, 'lefu-ffb0');
    });

    test('checksum is the sum of D0..D3 plus status, masked to a byte', () {
      // 0x03 + 0x49 + 0x00 + 0x00 + 0xCA = 0x116 -> 0x16
      expect(
        LefuFfb0Parser.checksum(
          hex(
            'ac02034900 00ca16'.replaceAll(' ', ''),
          ),
        ),
        0x16,
      );
    });

    test('rejects a corrupted frame rather than reporting a wrong weight', () {
      expect(
        () => parser.parse(hex('ac0203490000ca17')),
        throwsA(isA<FrameFormatException>()),
      );
    });

    test('0xCE marks a live, still-settling reading', () {
      // 0x03 + 0x47 + 0 + 0 + 0xCE = 0x118 -> 0x18
      final frame = parser.parse(hex('ac0203470000ce18'));
      expect(frame.weightKg, closeTo(83.9, 1e-9));
      expect(frame.stability, WeightStability.live);
      expect(frame.isStable, isFalse);
    });

    test('does not claim frames that are not its own', () {
      expect(parser.canParse(hex('1000000349010200')), isFalse);
      expect(parser.canParse(hex('ac02')), isFalse);
    });

    test('builds handshake commands with valid checksums', () {
      for (final cmd in LefuFfb0Parser.handshake()) {
        expect(cmd.length, 8);
        expect(cmd[0], 0xAC);
        expect(cmd[1], 0x02);
        expect(LefuFfb0Parser.checksum(cmd), cmd[7]);
      }
    });

    test('first handshake frame matches the captured bytes', () {
      // ac02 fa01 0000 cc c7
      final cmd = LefuFfb0Parser.command(d0: 0xFA, d1: 0x01, d2: 0, d3: 0);
      expect(cmd, hex('ac02fa010000ccc7'));
    });
  });

  group('Qingniu / QN', () {
    const parser = QingniuParser();

    test('decodes weight, stability and both impedance channels', () {
      // opcode 0x10, weight 0x1F40 = 8000 -> 80.00 kg at divisor 100,
      // stable 0x01, R1 0x01F4 = 500, R2 0x0258 = 600.
      final frame = parser.parse(
        hex(
          '1000001f4001 01f40258'.replaceAll(' ', ''),
        ),
      );
      expect(frame.weightKg, closeTo(80.0, 1e-9));
      expect(frame.stability, WeightStability.stable);
      expect(frame.impedanceOhm, 500);
      expect(frame.secondaryImpedanceOhm, 600);
    });

    test('stable flag 0x00 means still live', () {
      final frame = parser.parse(hex('1000001f400001f40258'));
      expect(frame.stability, WeightStability.live);
    });

    test('applies the sanity fallback when the divisor was wrong', () {
      // 0x7530 = 30000. At divisor 100 that is 300 kg, which is not a person,
      // so the parser drops another order of magnitude.
      final frame = parser.parse(hex('10000075300101f40258'));
      expect(frame.weightKg, closeTo(30.0, 1e-9));
    });

    test('reports no impedance rather than zero when the field is empty', () {
      final frame = parser.parse(
        hex(
          '1000001f40010000 0000'.replaceAll(' ', ''),
        ),
      );
      expect(frame.impedanceOhm, isNull);
      expect(frame.hasImpedance, isFalse);
    });
  });

  group('Xiaomi MIBFS advertisement', () {
    const parser = XiaomiMibfsParser();

    test('decodes weight and impedance from a stabilised payload', () {
      // [0] 0x02 kg
      // [1] flags 0x22 = bit1 (impedance present) + bit5 (stabilised)
      // [2:4] year 2026 = 0x07EA LE -> ea 07
      // [4] month 8, [5] day 25, [6] 7h, [7] 15m, [8] 0s
      // [9:11] impedance 500 = 0x01F4 LE -> f4 01
      // [11:13] weight 16000 = 0x3E80 LE -> 80 3e  -> 16000/200 = 80.0 kg
      final frame = parser.parse(
        hex(
          '0222ea07081907 0f00f401803e'.replaceAll(' ', ''),
        ),
      );
      expect(frame.weightKg, closeTo(80.0, 1e-9));
      expect(frame.impedanceOhm, 500);
      expect(frame.stability, WeightStability.stable);
      expect(frame.deviceTimestamp, DateTime(2026, 8, 25, 7, 15));
    });

    test('bit7 means the load was removed, whatever else is set', () {
      final frame = parser.parse(hex('02a2ea070819070f00f401803e'));
      expect(frame.stability, WeightStability.removed);
    });

    test('ignores an implausible impedance instead of feeding an equation', () {
      // 0x0BB8 = 3000, at the rejection threshold.
      final frame = parser.parse(hex('0222ea070819070f00b80b803e'));
      expect(frame.impedanceOhm, isNull);
    });

    test('does not treat a live reading as final', () {
      // flags 0x02: impedance present, not stabilised.
      final frame = parser.parse(hex('0202ea070819070f00f401803e'));
      expect(frame.stability, WeightStability.live);
    });
  });

  group('Bluetooth SIG weight measurement', () {
    const parser = SigWeightMeasurementParser();

    test('decodes SI weight at the standard 0.005 kg resolution', () {
      // flags 0x00 = SI, no optional fields. 16000 * 0.005 = 80.0 kg
      final frame = parser.parse(hex('00803e'));
      expect(frame.weightKg, closeTo(80.0, 1e-9));
      expect(frame.stability, WeightStability.stable);
    });

    test('decodes imperial when the unit bit is set', () {
      // flags 0x01, raw 17637 -> 176.37 lb -> 80.0 kg
      final frame = parser.parse(hex('01e544'));
      expect(frame.weightKg, closeTo(80.0, 0.01));
    });

    test('reads the optional timestamp when the flag announces it', () {
      final frame = parser.parse(hex('02803eea070819070f00'));
      expect(frame.deviceTimestamp, DateTime(2026, 8, 25, 7, 15));
    });
  });

  group('FrameParserRegistry', () {
    const registry = FrameParserRegistry();

    test('routes each payload to the right parser', () {
      expect(registry.tryParse(hex('ac0203490000ca16'))!.protocol, 'lefu-ffb0');
      expect(
        registry
            .tryParse(
              hex(
                '0222ea07081907 0f00f401803e'.replaceAll(' ', ''),
              ),
            )!
            .protocol,
        'xiaomi-mibfs',
      );
      expect(
        registry.tryParse(hex('1000001f400101f40258'))!.protocol,
        'qingniu',
      );
    });

    test('returns null for the housekeeping frames scales also emit', () {
      // Battery, time sync and keep-alive traffic is normal and must not be
      // mistaken for a measurement.
      expect(registry.tryParse(hex('ff')), isNull);
    });

    test('a corrupted AC02 frame is not silently re-parsed as something else',
        () {
      // The registry must not fall through to a looser parser and invent a
      // weight from bytes that failed their own checksum.
      final result = registry.tryParse(hex('ac0203490000ca17'));
      expect(result?.protocol, isNot('lefu-ffb0'));
    });
  });

  group('MeasurementAggregator', () {
    test('ignores an empty platform', () {
      final agg = MeasurementAggregator();
      final sample = agg.accept(
        const ScaleFrame(weightKg: 0.4, stability: WeightStability.live),
      );
      expect(sample, isNull);
    });

    test('emits a stable sample exactly once per measurement', () {
      final agg = MeasurementAggregator();
      const stable = ScaleFrame(
        weightKg: 80.0,
        stability: WeightStability.stable,
      );
      expect(agg.accept(stable)!.isStable, isTrue);
      // A scale repeats its final frame several times; the app must log once.
      expect(agg.accept(stable), isNull);
    });

    test('detects settling by value when the protocol has no stability flag',
        () {
      final agg = MeasurementAggregator(
        stabilityWindow: const Duration(milliseconds: 500),
        stabilityToleranceKg: 0.05,
      );
      final t0 = DateTime(2026, 8, 25, 7, 0, 0);
      const live = ScaleFrame(weightKg: 80.0, stability: WeightStability.live);

      expect(agg.accept(live, now: t0)!.isStable, isFalse);
      expect(
        agg
            .accept(live, now: t0.add(const Duration(milliseconds: 200)))!
            .isStable,
        isFalse,
      );
      expect(
        agg
            .accept(live, now: t0.add(const Duration(milliseconds: 400)))!
            .isStable,
        isFalse,
      );
      // Fourth sample, more than the window after the first, all within
      // tolerance -> settled.
      final settled =
          agg.accept(live, now: t0.add(const Duration(milliseconds: 600)));
      expect(settled!.isStable, isTrue);
    });

    test('resets when the load comes off', () {
      final agg = MeasurementAggregator();
      agg.accept(
        const ScaleFrame(
          weightKg: 80,
          stability: WeightStability.stable,
        ),
      );
      agg.accept(
        const ScaleFrame(
          weightKg: 0,
          stability: WeightStability.removed,
        ),
      );
      // Next person on the scale gets their own stable event.
      final next = agg.accept(
        const ScaleFrame(
          weightKg: 64,
          stability: WeightStability.stable,
        ),
      );
      expect(next!.isStable, isTrue);
    });
  });
}
