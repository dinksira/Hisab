import 'package:decimal/decimal.dart';
import 'package:intl/intl.dart';

/// Centralized immutable money domain model with exact decimal representation.
/// Guarantees financial correctness and prevents floating-point inaccuracies.
class Money implements Comparable<Money> {
  final Decimal amount;
  final String currency;

  const Money._({required this.amount, required this.currency});

  factory Money.fromDecimal(Decimal amount, [String currency = 'USD']) {
    return Money._(
      amount: amount,
      currency: currency.toUpperCase().trim(),
    );
  }

  factory Money.fromNum(num value, [String currency = 'USD']) {
    return Money._(
      amount: Decimal.parse(value.toString()),
      currency: currency.toUpperCase().trim(),
    );
  }

  factory Money.fromMinorUnits(int minorUnits, [String currency = 'USD']) {
    final cur = currency.toUpperCase().trim();
    final factor = _currencyMinorFactors[cur] ?? 100;
    final dec = (Decimal.fromInt(minorUnits) / Decimal.fromInt(factor)).toDecimal();
    return Money._(amount: dec, currency: cur);
  }

  factory Money.zero([String currency = 'USD']) {
    return Money._(
      amount: Decimal.zero,
      currency: currency.toUpperCase().trim(),
    );
  }

  factory Money.parse(String value, [String currency = 'USD']) {
    final cleanValue = value.replaceAll(',', '').trim();
    return Money._(
      amount: Decimal.parse(cleanValue.isEmpty ? '0' : cleanValue),
      currency: currency.toUpperCase().trim(),
    );
  }

  static Money? tryParse(String value, [String currency = 'USD']) {
    try {
      return Money.parse(value, currency);
    } catch (_) {
      return null;
    }
  }

  // Currency decimal minor unit factors
  static const Map<String, int> _currencyMinorFactors = {
    'BHD': 1000,
    'KWD': 1000,
    'OMR': 1000,
    'JOD': 1000,
    'JPY': 1,
    'KRW': 1,
    'VND': 1,
    'CLP': 1,
    'USD': 100,
    'EUR': 100,
    'GBP': 100,
    'SAR': 100,
    'AED': 100,
    'BDT': 100,
    'INR': 100,
    'CAD': 100,
    'AUD': 100,
  };

  int get minorUnits {
    final factor = _currencyMinorFactors[currency] ?? 100;
    return (amount * Decimal.fromInt(factor)).toBigInt().toInt();
  }

  bool get isZero => amount == Decimal.zero;
  bool get isPositive => amount > Decimal.zero;
  bool get isNegative => amount < Decimal.zero;

  Money abs() => Money._(amount: amount.abs(), currency: currency);

  Money operator -() => Money._(amount: -amount, currency: currency);

  void _assertSameCurrency(Money other) {
    if (currency != other.currency) {
      throw ArgumentError(
        'Cannot perform arithmetic between incompatible currencies: $currency and ${other.currency}. '
        'Convert to matching currency with explicit exchange rate first.',
      );
    }
  }

  Money operator +(Money other) {
    _assertSameCurrency(other);
    return Money._(amount: amount + other.amount, currency: currency);
  }

  Money operator -(Money other) {
    _assertSameCurrency(other);
    return Money._(amount: amount - other.amount, currency: currency);
  }

  Money multiply(num multiplier) {
    final multDecimal = Decimal.parse(multiplier.toString());
    return Money._(amount: amount * multDecimal, currency: currency);
  }

  Money divide(num divisor) {
    if (divisor == 0) {
      throw ArgumentError('Division by zero is not allowed.');
    }
    final divDecimal = Decimal.parse(divisor.toString());
    return Money._(
      amount: (amount / divDecimal).toDecimal(),
      currency: currency,
    );
  }

  @override
  int compareTo(Money other) {
    _assertSameCurrency(other);
    return amount.compareTo(other.amount);
  }

  bool operator <(Money other) => compareTo(other) < 0;
  bool operator <=(Money other) => compareTo(other) <= 0;
  bool operator >(Money other) => compareTo(other) > 0;
  bool operator >=(Money other) => compareTo(other) >= 0;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Money && other.currency == currency && other.amount == amount;
  }

  @override
  int get hashCode => Object.hash(amount, currency);

  double toDouble() => amount.toDouble();

  /// Formatted representation with proper currency symbol or code
  String formatted({bool includeSymbol = true, bool compact = false, String? locale}) {
    final dValue = amount.toDouble();
    if (compact && dValue.abs() >= 10000) {
      final compactFormat = NumberFormat.compactCurrency(
        symbol: includeSymbol ? null : '',
        name: currency,
        locale: locale,
      );
      return compactFormat.format(dValue).trim();
    }

    final format = NumberFormat.currency(
      symbol: includeSymbol ? null : '',
      name: currency,
      locale: locale,
    );
    return format.format(dValue).trim();
  }

  /// Compact representation with +/- sign for net flow / transaction lists
  String formattedWithSign({bool includeSymbol = true, String? locale}) {
    final prefix = isPositive ? '+' : (isNegative ? '-' : '');
    final absFormatted = abs().formatted(includeSymbol: includeSymbol, locale: locale);
    return '$prefix$absFormatted';
  }

  Map<String, dynamic> toJson() => {
        'amount': amount.toString(),
        'currency': currency,
      };

  factory Money.fromJson(Map<String, dynamic> json) {
    return Money._(
      amount: Decimal.parse(json['amount'].toString()),
      currency: json['currency'] as String? ?? 'USD',
    );
  }

  @override
  String toString() => '$amount $currency';
}
