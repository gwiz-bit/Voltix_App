import 'package:intl/intl.dart';

final _vnd = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
final _compact = NumberFormat.compact(locale: 'vi');
final _dateTime = DateFormat('dd/MM/yyyy HH:mm');
final _time = DateFormat('HH:mm');

String formatVnd(num value) => _vnd.format(value);

String formatCompact(num value) => _compact.format(value);

String formatDateTime(DateTime value) => _dateTime.format(value.toLocal());

String formatTime(DateTime value) => _time.format(value.toLocal());

/// Server trả thời gian giờ Việt Nam không kèm múi giờ -> parse như giờ địa phương.
DateTime parseServerTime(String value) => DateTime.parse(value);
