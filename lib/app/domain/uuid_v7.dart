import 'dart:math';

String createUuidV7([DateTime? now]) {
  final millis = BigInt.from((now ?? DateTime.now()).millisecondsSinceEpoch);
  final random = Random.secure();
  final randomHex = List<String>.generate(
    10,
    (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();

  final timeHex = millis.toRadixString(16).padLeft(12, '0');

  final segment1 = timeHex.substring(0, 8);
  final segment2 = timeHex.substring(8, 12);
  final segment3 = '7${randomHex.substring(0, 3)}';

  final variantNibble = (int.parse(randomHex.substring(3, 4), radix: 16) & 0x3) | 0x8;
  final segment4 = '${variantNibble.toRadixString(16)}${randomHex.substring(4, 7)}';
  final segment5 = randomHex.substring(7, 19);

  return '$segment1-$segment2-$segment3-$segment4-$segment5';
}
