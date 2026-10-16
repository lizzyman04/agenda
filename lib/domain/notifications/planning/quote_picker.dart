/// Deterministic quote selection (D-07).
///
/// Uses a private linear congruential generator instead of `dart:math`
/// `Random` so the shuffle order is stable across Dart SDK upgrades: the same
/// persisted seed always yields the same order.
library;

const int _lcgMultiplier = 1103515245;
const int _lcgIncrement = 12345;
const int _lcgMask = 0x7fffffff;

/// A permutation of `0..length-1` for [seed] (Fisher-Yates over an LCG).
List<int> seededPermutation(int length, int seed) {
  final result = List<int>.generate(length < 0 ? 0 : length, (i) => i);
  var state = seed & _lcgMask;
  int next() {
    state = (_lcgMultiplier * state + _lcgIncrement) & _lcgMask;
    // The low bits of an LCG are weak, so use the high ones.
    return state >> 8;
  }

  for (var i = result.length - 1; i > 0; i--) {
    final j = next() % (i + 1);
    final tmp = result[i];
    result[i] = result[j];
    result[j] = tmp;
  }
  return result;
}

/// The quote for [slotIndex] under [seed], or null when [quotes] is empty.
///
/// Any `quotes.length` consecutive slot indexes return distinct quotes, so
/// nothing repeats within one cycle of the list. A negative index does not
/// throw.
String? pickQuote(List<String> quotes, int slotIndex, int seed) {
  final n = quotes.length;
  if (n == 0) return null;
  final perm = seededPermutation(n, seed);
  return quotes[perm[((slotIndex % n) + n) % n]];
}
