extends Node
# HistoricalDataManager.gd - Real historical oil prices and events
# Provides accurate historical data for immersive gameplay

# --- REAL OIL PRICES (Nominal USD per barrel, monthly averages) ---
# Source: Historical Brent crude prices (simplified to key points)
const HISTORICAL_OIL_PRICES = {
        # 1970s - Pre-crisis stability
        1970: {"avg": 3.18, "months": {1: 3.18, 6: 3.18, 12: 3.18}},
        1971: {"avg": 3.39, "months": {1: 3.18, 6: 3.39, 12: 3.60}},
        1972: {"avg": 3.56, "months": {1: 3.60, 6: 3.56, 12: 3.56}},
        1973: {"avg": 4.75, "months": {1: 3.56, 6: 3.95, 10: 5.12, 11: 5.40, 12: 4.76}},  # Crisis begins
        1974: {"avg": 10.41, "months": {1: 8.32, 6: 12.48, 12: 11.16}},  # Crisis peak
        1975: {"avg": 11.53, "months": {1: 11.16, 6: 12.10, 12: 12.20}},
        1976: {"avg": 12.80, "months": {1: 12.40, 6: 12.80, 12: 12.80}},
        1977: {"avg": 13.92, "months": {1: 13.45, 6: 13.92, 12: 14.20}},
        1978: {"avg": 14.02, "months": {1: 14.20, 6: 13.85, 12: 14.85}},
        
        # 1979-1981 - Iranian Revolution and Iran-Iraq War
        1979: {"avg": 31.61, "months": {1: 15.85, 6: 32.50, 12: 32.50}},
        1980: {"avg": 36.83, "months": {1: 32.50, 6: 35.00, 12: 41.00}},
        1981: {"avg": 37.14, "months": {1: 41.00, 6: 38.00, 12: 35.00}},
        
        # 1982-1985 - Gradual decline
        1982: {"avg": 33.47, "months": {1: 34.00, 6: 33.00, 12: 33.50}},
        1983: {"avg": 30.33, "months": {1: 32.50, 6: 30.00, 12: 29.50}},
        1984: {"avg": 29.39, "months": {1: 29.50, 6: 29.00, 12: 29.50}},
        1985: {"avg": 28.44, "months": {1: 29.50, 6: 28.50, 12: 27.00}},
        
        # 1986 - Price crash
        1986: {"avg": 15.00, "months": {1: 26.00, 3: 15.00, 6: 12.00, 12: 17.00}},
        1987: {"avg": 19.21, "months": {1: 18.00, 6: 19.50, 12: 18.50}},
        1988: {"avg": 15.97, "months": {1: 17.50, 6: 16.00, 12: 15.00}},
        1989: {"avg": 19.68, "months": {1: 16.00, 6: 18.50, 12: 21.00}},
        
        # 1990-1991 - Gulf War
        1990: {"avg": 24.50, "months": {1: 21.00, 7: 18.00, 8: 28.00, 9: 34.00, 12: 28.00}},
        1991: {"avg": 20.45, "months": {1: 24.00, 6: 19.00, 12: 18.00}},
        1992: {"avg": 20.29, "months": {1: 18.50, 6: 20.00, 12: 19.50}},
        1993: {"avg": 17.42, "months": {1: 18.00, 6: 17.00, 12: 14.50}},
        1994: {"avg": 16.21, "months": {1: 14.00, 6: 16.50, 12: 17.00}},
        1995: {"avg": 18.43, "months": {1: 17.50, 6: 18.00, 12: 19.00}},
        1996: {"avg": 21.95, "months": {1: 19.50, 6: 21.00, 12: 24.00}},
        1997: {"avg": 20.36, "months": {1: 24.00, 6: 20.00, 12: 18.00}},  # Asian crisis
        1998: {"avg": 13.79, "months": {1: 17.00, 6: 13.00, 12: 11.00}},  # Price crash
        1999: {"avg": 18.45, "months": {1: 12.00, 6: 16.00, 12: 26.00}},  # Recovery
        2000: {"avg": 28.50, "months": {1: 26.00, 6: 28.00, 12: 25.00}}
}

# --- INFLATION RATES (Historical US CPI-based) ---
const HISTORICAL_INFLATION = {
        1970: 1.057,  # 5.7% annual
        1971: 1.044,
        1972: 1.034,
        1973: 1.087,  # Inflation accelerating
        1974: 1.125,  # 12.5% - post oil crisis
        1975: 1.091,
        1976: 1.057,
        1977: 1.065,
        1978: 1.076,
        1979: 1.113,  # 11.3% - second oil crisis
        1980: 1.135,  # 13.5% - peak inflation
        1981: 1.103,
        1982: 1.062,
        1983: 1.032,
        1984: 1.043,
        1985: 1.036,
        1986: 1.019,
        1987: 1.036,
        1988: 1.041,
        1989: 1.048,
        1990: 1.054,
        1991: 1.042,
        1992: 1.030,
        1993: 1.030,
        1994: 1.026,
        1995: 1.028,
        1996: 1.029,
        1997: 1.023,
        1998: 1.016,
        1999: 1.022,
        2000: 1.034
}

# --- HISTORICAL EVENTS TIMELINE ---
const HISTORICAL_TIMELINE = [
        {"year": 1970, "month": 4, "event": "Earth Day", "description": "First Earth Day marks beginning of modern environmental movement."},
        {"year": 1970, "month": 12, "event": "EPA Created", "description": "US Environmental Protection Agency established."},
        {"year": 1971, "month": 8, "event": "Nixon Shock", "description": "US ends gold standard, currencies begin floating."},
        {"year": 1972, "month": 6, "event": "Watergate Break-in", "description": "Five men arrested at Democratic headquarters."},
        {"year": 1973, "month": 1, "event": "Paris Peace Accords", "description": "US withdraws from Vietnam."},
        {"year": 1973, "month": 10, "event": "OPEC Embargo", "description": "Arab oil embargo begins. Prices quadruple.", "type": "crisis"},
        {"year": 1974, "month": 8, "event": "Nixon Resigns", "description": "President Nixon resigns over Watergate scandal."},
        {"year": 1975, "month": 11, "event": "Offshore Drilling", "description": "North Sea oil production begins in earnest."},
        {"year": 1976, "month": 4, "event": "Piper Alpha Online", "description": "Major North Sea platform begins production."},
        {"year": 1978, "month": 11, "event": "Jonestown Massacre", "description": "Cult mass suicide shocks world."},
        {"year": 1979, "month": 1, "event": "Iranian Revolution", "description": "Shah flees Iran. Oil exports halt.", "type": "crisis"},
        {"year": 1979, "month": 3, "event": "Three Mile Island", "description": "Nuclear accident increases demand for oil."},
        {"year": 1979, "month": 11, "event": "Iran Hostage Crisis", "description": "52 Americans held hostage in Tehran.", "type": "crisis"},
        {"year": 1980, "month": 9, "event": "Iran-Iraq War", "description": "War begins, threatening Gulf oil.", "type": "crisis"},
        {"year": 1981, "month": 1, "event": "Reagan Inauguration", "description": "Reagan becomes President. Deregulation era begins."},
        {"year": 1982, "month": 2, "event": "Oil Glut Begins", "description": "Worldwide oil surplus starts building."},
        {"year": 1986, "month": 1, "event": "Price War", "description": "Saudi Arabia floods market. Prices crash to $10.", "type": "crisis"},
        {"year": 1988, "month": 7, "event": "Piper Alpha Disaster", "description": "Platform explosion kills 167 workers."},
        {"year": 1989, "month": 3, "event": "Exxon Valdez", "description": "Massive oil spill in Alaska.", "type": "disaster"},
        {"year": 1989, "month": 11, "event": "Berlin Wall Falls", "description": "Cold War ending. New markets opening."},
        {"year": 1990, "month": 8, "event": "Iraq Invades Kuwait", "description": "Gulf War begins. Oil prices double.", "type": "crisis"},
        {"year": 1991, "month": 1, "event": "Desert Storm", "description": "US-led coalition attacks Iraq."},
        {"year": 1991, "month": 2, "event": "Kuwait Fires", "description": "Retreating Iraqis torch Kuwaiti oil fields.", "type": "disaster"},
        {"year": 1993, "month": 2, "event": "WTC Bombing", "description": "Terrorist attack on World Trade Center."},
        {"year": 1997, "month": 7, "event": "Asian Crisis", "description": "Financial crisis reduces oil demand.", "type": "crisis"},
        {"year": 1998, "month": 8, "event": "Oil Price Crash", "description": "Oil falls below $12/barrel.", "type": "crisis"},
        {"year": 1999, "month": 3, "event": "OPEC Cuts", "description": "OPEC production cuts begin working."}
]

# --- STATE ---
var historical_mode_enabled: bool = true
var game_manager = null

func _ready():
        await get_tree().create_timer(0.5).timeout
        if has_node("/root/GameManager"):
                game_manager = get_node("/root/GameManager")

# --- GET OIL PRICE FOR DATE ---
func get_oil_price(year: int, month: int = 1) -> float:
        if not historical_mode_enabled:
                return 0.0
        
        # Get year data
        if not HISTORICAL_OIL_PRICES.has(year):
                # Interpolate or use nearest
                return _get_nearest_price(year, month)
        
        var year_data = HISTORICAL_OIL_PRICES[year]
        
        # Get exact month if available
        if year_data["months"].has(month):
                return year_data["months"][month]
        
        # Interpolate between available months
        return _interpolate_monthly_price(year, month, year_data)

func _get_nearest_price(year: int, _month: int) -> float:
        # Find nearest year with data
        var years = HISTORICAL_OIL_PRICES.keys()
        years.sort()
        
        for y in years:
                if y >= year:
                        return HISTORICAL_OIL_PRICES[y]["avg"]
        
        # Default to last known price
        return HISTORICAL_OIL_PRICES[years[-1]]["avg"]

func _interpolate_monthly_price(_year: int, month: int, year_data: Dictionary) -> float:
        var months = year_data["months"].keys()
        months.sort()
        
        # Find surrounding months
        var prev_month = months[0]
        var next_month = months[-1]
        
        for m in months:
                if m < month:
                        prev_month = m
                if m > month and next_month == months[-1]:
                        next_month = m
                        break
        
        if prev_month == next_month:
                return year_data["months"][prev_month]
        
        # Linear interpolation
        var prev_price = year_data["months"][prev_month]
        var next_price = year_data["months"][next_month]
        var t = float(month - prev_month) / float(next_month - prev_month)
        
        return lerp(prev_price, next_price, t)

# --- GET INFLATION RATE ---
func get_inflation_rate(year: int) -> float:
        if HISTORICAL_INFLATION.has(year):
                return HISTORICAL_INFLATION[year]
        return 1.03  # Default 3%

# --- GET EVENTS FOR DATE ---
func get_events_for_date(year: int, month: int) -> Array:
        var events = []
        for event in HISTORICAL_TIMELINE:
                if event["year"] == year and event["month"] == month:
                        events.append(event)
        return events

# --- GET EVENTS FOR YEAR ---
func get_events_for_year(year: int) -> Array:
        var events = []
        for event in HISTORICAL_TIMELINE:
                if event["year"] == year:
                        events.append(event)
        return events

# --- GET CRISIS EVENTS ---
func get_crisis_events() -> Array:
        return HISTORICAL_TIMELINE.filter(func(e): return e.has("type") and e["type"] == "crisis")

# --- APPLY HISTORICAL PRICES ---
func apply_historical_prices():
        if game_manager == null or not historical_mode_enabled:
                return
        
        var year = game_manager.date["year"]
        var month = game_manager.date["month"]
        
        # Set oil price to historical value
        var historical_price = get_oil_price(year, month)
        game_manager.oil_price = historical_price
        
        # Apply inflation rate
        if game_manager.date["month"] == 1 and game_manager.date["day"] == 1:
                game_manager.inflation_rate *= get_inflation_rate(year)

# --- CALCULATE ACCURACY SCORE ---
func calculate_accuracy_score() -> Dictionary:
        if game_manager == null:
                return {"score": 0, "events_matched": 0, "total_events": 0}
        
        # Check how many historical events were triggered at correct times
        var events_matched = 0
        var total_events = HISTORICAL_TIMELINE.size()
        
        # Would compare with triggered events from NewspaperManager
        # For now, return basic structure
        
        return {
                "score": 100,  # Would be calculated
                "events_matched": events_matched,
                "total_events": total_events
        }

# --- TOGGLE HISTORICAL MODE ---
func set_historical_mode(enabled: bool):
        historical_mode_enabled = enabled

# --- GET PRICE VOLATILITY FOR ERA ---
func get_era_volatility(year: int) -> float:
        if year < 1973:
                return 0.02  # Stable pre-crisis
        elif year < 1980:
                return 0.08  # High volatility during crises
        elif year < 1986:
                return 0.05  # Moderate
        elif year < 1990:
                return 0.06  # Price war era
        elif year < 2000:
                return 0.04  # More stable modern era
        else:
                return 0.05
