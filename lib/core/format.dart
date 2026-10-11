import 'package:intl/intl.dart';

// Dates from the API carry a UTC offset; always show them in the device's local time.
// Thai Buddhist year is added by hand (year + 543) so it does not depend on locale data.

String baht(int value) => '฿${NumberFormat('#,##0').format(value)}';

String timeHm(DateTime d) => DateFormat('HH:mm').format(d.toLocal());

String dateTimeThai(DateTime d) {
  final l = d.toLocal();
  return '${DateFormat('d MMM', 'th').format(l)} ${l.year + 543}  ${timeHm(l)} น.';
}
