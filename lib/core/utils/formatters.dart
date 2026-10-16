import 'package:intl/intl.dart';

/// Locale-aware formatting helpers (Arabic-first).
class Formatters {
  Formatters._();

  static final _currency = NumberFormat.currency(
    locale: 'ar',
    symbol: '\$',
    decimalDigits: 0,
  );
  static final _currencyFractional = NumberFormat.currency(
    locale: 'ar',
    symbol: '\$',
    decimalDigits: 2,
  );

  static final _date = DateFormat('yyyy/MM/dd', 'ar');
  static final _dateEnglishDigits = DateFormat('yyyy/MM/dd', 'en');
  static final _dateTime = DateFormat('yyyy/MM/dd – HH:mm', 'ar');
  static final _longDate = DateFormat('d MMMM yyyy', 'ar');
  static final _numberGrouped = NumberFormat.decimalPattern('en');

  static String currency(num value) {
    final hasFraction = (value.toDouble() - value.toInt()).abs() > 0.000001;
    return (hasFraction ? _currencyFractional : _currency).format(value);
  }

  static String date(DateTime d) => _date.format(d);
  static String dateEnglishDigits(DateTime d) => _dateEnglishDigits.format(d);
  static String dateTime(DateTime d) => _dateTime.format(d);
  static String numberGrouped(num value) => _numberGrouped.format(value);

  /// e.g. "10 يونيو 2026" (Arabic month name).
  static String longDate(DateTime d) => _longDate.format(d);
}
