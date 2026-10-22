extends Node
# Autoload « Clock » : temps Epoch UTC, gel doux si l'horloge recule.

const BalanceAScript = preload("res://balance/balance_a.gd")
const BalanceBScript = preload("res://balance/balance_b.gd")

static func now_utc() -> int:
	return int(Time.get_unix_time_from_system())

# `now` : injectable pour les tests (-1 = horloge système).
static func offline_hours(last_save_utc: int, now: int = -1) -> float:
	var delta: int = (now if now >= 0 else now_utc()) - last_save_utc
	if delta < -BalanceBScript.CLOCK_DRIFT_TOLERANCE_SEC:
		return 0.0
	return minf(maxf(float(delta), 0.0) / 3600.0, BalanceBScript.OFFLINE_MAX_HOURS)

static func day_index(unix_utc: int, tz_offset_sec: int) -> int:
	return BalanceAScript.get_daily_reset_day_index(unix_utc, tz_offset_sec)
