import 'package:stawi_api/finance_v1.dart' as finance;

/// A room's dues calendar, worked out the way the RulesEngine does
/// (CalendarLib.periodStart, DuesMath.dueTime and isDue; Go pkg/rules
/// calendar.go): when each period begins and when a dues product next falls
/// due. Whole seconds only; no floating point.

const int _day = 86400;

/// When period [i] of [c] begins, in unix seconds; null when the calendar is
/// not one the engine accepts.
int? periodStart(finance.RoomCalendar c, int i) {
  if (c.length == 0 || !c.hasAnchor()) return null;
  final anchor = c.anchor.seconds.toInt();
  final step = switch (c.unit) {
    finance.PeriodUnit.PERIOD_UNIT_SECONDS => c.length,
    finance.PeriodUnit.PERIOD_UNIT_DAY => _day * c.length,
    finance.PeriodUnit.PERIOD_UNIT_WEEK => 7 * _day * c.length,
    finance.PeriodUnit.PERIOD_UNIT_MONTH => null,
    _ => -1,
  };
  if (step == -1) return null;
  if (step != null) return anchor + i * step;
  // Months: the anchor's day of month (clamped to the month's length) and
  // time of day, in the room's time zone.
  final local = anchor + c.tzOffsetSeconds;
  if (local < 0) return null;
  final (y0, m0, d0) = civilFromDays(local ~/ _day);
  final tod = local % _day;
  final total = y0 * 12 + (m0 - 1) + i * c.length;
  final y = total ~/ 12;
  final m = total % 12 + 1;
  final d = d0 < daysInMonth(y, m) ? d0 : daysInMonth(y, m);
  return daysFromCivil(y, m, d) * _day + tod - c.tzOffsetSeconds;
}

/// Whether [p] is due in period [x] (DuesMath.isDue from its first period).
bool _dueIn(finance.RoomDuesProduct p, int x) {
  if (x < p.firstPeriod || (p.lastPeriod != 0 && x > p.lastPeriod)) {
    return false;
  }
  if (p.everyPeriods == 0) return x == p.firstPeriod;
  return (x - p.firstPeriod) % p.everyPeriods == 0;
}

/// When a room's dues next fall due, as far as its calendar tells.
final class NextDue {
  const NextDue._(this.at, {this.unknown = false});

  /// It falls due at [at] (UTC).
  const NextDue.at(DateTime at) : this._(at);

  /// Nothing more falls due.
  static const NextDue none = NextDue._(null);

  /// It could not be worked out: the calendar's current period is behind
  /// (every candidate has already passed), or the calendar is not one the
  /// engine accepts.
  static const NextDue notWorkedOut = NextDue._(null, unknown: true);

  final DateTime? at;
  final bool unknown;
}

/// Seconds of [p]'s next due after [now] (unix seconds), from the calendar's
/// current period on: null when it falls due no more, -1 when it could not
/// be worked out.
int? nextDueOf(finance.RoomDuesProduct p, finance.RoomCalendar c, int now) {
  if (!p.active) return null;
  var x = c.currentPeriod > p.firstPeriod ? c.currentPeriod : p.firstPeriod;
  if (p.everyPeriods > 0) {
    final off = (x - p.firstPeriod) % p.everyPeriods;
    if (off != 0) x += p.everyPeriods - off;
  }
  // Two candidates: this one, or the next when this one has passed. When
  // both have passed the calendar's current period is behind the chain's
  // time, and the next due cannot be worked out from it.
  for (var tries = 0; tries < 2; tries++) {
    if (!_dueIn(p, x)) return null;
    final start = periodStart(c, x);
    if (start == null) return -1;
    final due = start + p.dueOffsetSeconds;
    if (due > now) return due;
    if (p.everyPeriods == 0) return null;
    x += p.everyPeriods;
  }
  return -1;
}

/// When any of the room's active dues next falls due after [now]: none when
/// nothing does (or the room has no rules yet), not worked out when any
/// product's could not be (an earlier date might be missed).
NextDue nextDuesDate(finance.ListRoomProductsResponse products, DateTime now) {
  if (!products.rulesConfigured || !products.hasCalendar()) {
    return NextDue.none;
  }
  final t = now.toUtc().millisecondsSinceEpoch ~/ 1000;
  int? best;
  for (final p in products.duesProducts) {
    final due = nextDueOf(p, products.calendar, t);
    if (due == -1) return NextDue.notWorkedOut;
    if (due != null && (best == null || due < best)) best = due;
  }
  return best == null
      ? NextDue.none
      : NextDue.at(
          DateTime.fromMillisecondsSinceEpoch(best * 1000, isUtc: true),
        );
}

/// Howard Hinnant's days_from_civil: days since 1970-01-01.
int daysFromCivil(int y, int m, int d) {
  final yy = m <= 2 ? y - 1 : y;
  final era = (yy >= 0 ? yy : yy - 399) ~/ 400;
  final yoe = yy - era * 400;
  final mm = m > 2 ? m - 3 : m + 9;
  final doy = (153 * mm + 2) ~/ 5 + d - 1;
  final doe = yoe * 365 + yoe ~/ 4 - yoe ~/ 100 + doy;
  return era * 146097 + doe - 719468;
}

/// Howard Hinnant's civil_from_days.
(int, int, int) civilFromDays(int z) {
  final zz = z + 719468;
  final era = (zz >= 0 ? zz : zz - 146096) ~/ 146097;
  final doe = zz - era * 146097;
  final yoe = (doe - doe ~/ 1460 + doe ~/ 36524 - doe ~/ 146096) ~/ 365;
  final doy = doe - (365 * yoe + yoe ~/ 4 - yoe ~/ 100);
  final mp = (5 * doy + 2) ~/ 153;
  final d = doy - (153 * mp + 2) ~/ 5 + 1;
  final m = mp < 10 ? mp + 3 : mp - 9;
  return (yoe + era * 400 + (m <= 2 ? 1 : 0), m, d);
}

int daysInMonth(int y, int m) => switch (m) {
  2 => (y % 4 == 0 && (y % 100 != 0 || y % 400 == 0)) ? 29 : 28,
  4 || 6 || 9 || 11 => 30,
  _ => 31,
};
