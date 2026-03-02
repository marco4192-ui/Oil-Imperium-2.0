extends Node
# NewspaperManager.gd - Dynamic news system with era-based evolution
# 1970s-80s: Classic Newspaper | 1990s: TV News "OilNN" | 2000s+: Online Portal

signal news_published(headline: String, category: String, is_important: bool)
signal breaking_news(headline: String)

# --- NEWS MEDIA TYPES ---
enum MediaType {
	NEWSPAPER_1970S,	# Classic black & white newspaper
	NEWSPAPER_1980S,	# Color newspaper with photos
	TV_NEWS_1990S,		# OilNN TV news channel
	ONLINE_PORTAL_2000S	# OilNN.com website
}

# --- NEWS CATEGORIES ---
enum Category {
	# Oil-specific news
	OIL_DISCOVERY,
	OIL_CRISIS,
	OPEC_NEWS,
	COMPANY_NEWS,
	MARKET_NEWS,
	# World news (non-oil)
	WORLD_POLITICS,
	TECHNOLOGY,
	CULTURE,
	SPORTS,
	DISASTERS,
	ECONOMY,
	SPACE
}

# --- HISTORICAL OIL EVENTS (Real world 1970-2000) ---
const HISTORICAL_OIL_EVENTS = [
	# 1970s
	{"year": 1970, "month": 4, "title": "EARTH DAY BEGRUENDET UMWELTBEWEGUNG",
	 "text": "Millionen Amerikaner protestieren fuer Umweltbewusstsein. Oelindustrie unter neuer Beobachtung.",
	 "category": Category.OIL_CRISIS, "effect": {"reputation": -5}, "important": true},
	{"year": 1973, "month": 10, "title": "OELKRISE BEGINNT - OPEC-EMBARGO",
	 "text": "Arabische Oelproduzenten verkuenden Embargo gegen USA. Preise vervierfachen sich ueber Nacht!",
	 "category": Category.OIL_CRISIS, "effect": {"oil_price_mult": 4.0, "inflation": 1.1}, "important": true},
	{"year": 1974, "month": 3, "title": "TEMPO 100 ZUR TREIBSTOFFSPARUNG",
	 "text": "Bundesregierung fuehrt Tempolimit auf Autobahnen ein, um Benzin zu sparen.",
	 "category": Category.MARKET_NEWS, "effect": {"demand": 0.95}},
	{"year": 1979, "month": 3, "title": "REAKTORUNFALL IN THREE MILE ISLAND",
	 "text": "Nuklearunfall in Pennsylvania. Oelaktien steigen durch Angst vor Alternativenergie.",
	 "category": Category.OIL_CRISIS, "effect": {"oil_price_mult": 1.15}},
	{"year": 1979, "month": 11, "title": "GEISELN IN TEHERAN - OELPREIS EXPLODIERT",
	 "text": "Amerikanische Geiseln im Iran. Iranische Oelexporte gestoppt. Globaler Panikkauf beginnt.",
	 "category": Category.OIL_CRISIS, "effect": {"oil_price_mult": 2.0, "volatility": 0.1}, "important": true},
	# 1980s
	{"year": 1980, "month": 9, "title": "IRAN-IRAK-KRIEG BEGINNT",
	 "text": "Krieg zwischen zwei grossen Oelproduzenten bedroht Golf-Exporte. Preise erreichen Rekordhoehen.",
	 "category": Category.OIL_CRISIS, "effect": {"oil_price_mult": 1.5, "region_blocked": "Saudi-Arabien"}, "important": true},
	{"year": 1986, "month": 1, "title": "OELPREISSTURZ - $10 PRO FASS",
	 "text": "OPEC-Preiskrieg ueberschwemmt Markt mit Oel. Preise stuerzen von $30 auf $10. Kleine Produzenten pleite.",
	 "category": Category.MARKET_NEWS, "effect": {"oil_price_mult": 0.4}, "important": true},
	{"year": 1988, "month": 7, "title": "PIPER ALPHA KATASTROPHE",
	 "text": "Nordsee-Oelplattform explodiert, 167 Tote. Sicherheitsvorschriften weltweit verschaerft.",
	 "category": Category.OIL_CRISIS, "effect": {"safety_costs": 1.2}},
	{"year": 1989, "month": 3, "title": "EXXON VALDEZ OELPEST",
	 "text": "Tanker verschüttet 11 Mio. Gallonen vor Alaska. Umweltkatastrophe loest Empoerung aus.",
	 "category": Category.OIL_CRISIS, "effect": {"reputation_all": -10, "enviro_regs": true}, "important": true},
	# 1990s
	{"year": 1990, "month": 8, "title": "IRAK INVADELT KUWAIT - GOLFKRIEG",
	 "text": "Saddam Husseins Truppen besetzen Kuwait. Oelpreise verdoppeln sich. US-Truppen nach Saudi-Arabien.",
	 "category": Category.OIL_CRISIS, "effect": {"oil_price_mult": 2.0, "region_blocked": "Saudi-Arabien"}, "important": true},
	{"year": 1991, "month": 1, "title": "OPERATION WUESTENSTURM",
	 "text": "US-geführte Koalition startet Luftkrieg gegen Irak. 'Smarte Bomben' live auf CNN.",
	 "category": Category.OIL_CRISIS, "effect": {"oil_price_mult": 1.3}},
	{"year": 1997, "month": 7, "title": "ASIATISCHE FINANZKRISE",
	 "text": "Waehrungszusammenbruch breitet sich in Asien aus. Oelnachfrage sinkt drastisch.",
	 "category": Category.ECONOMY, "effect": {"oil_price_mult": 0.8, "demand": 0.9}},
	{"year": 1999, "month": 4, "title": "OPEC PRODUKTIONS-KUERZUNGEN",
	 "text": "OPEC beschliesst Produktionskuerzung um 1,7 Mio. Fass/Tag. Preise erholen sich.",
	 "category": Category.OPEC_NEWS, "effect": {"oil_price_mult": 1.3}}
]

# --- WORLD EVENTS (Non-oil historical events 1970-2000) ---
const WORLD_EVENTS = [
	# 1970s - Politics & Culture
	{"year": 1970, "month": 9, "title": "TOD JIMI HENDRIX",
	 "text": "Rocklegende Jimi Hendrix mit 27 Jahren gestorben. Eine Aera endet.",
	 "category": Category.CULTURE, "effect": {}},
	{"year": 1971, "month": 10, "title": "DISNEY WORLD EROEFFNET",
	 "text": "Walt Disney World in Florida eroeffnet. Groesster Freizeitpark der Welt.",
	 "category": Category.CULTURE, "effect": {}},
	{"year": 1972, "month": 9, "title": "MUNICHEN OLYMPIA-ATTENTAT",
	 "text": "Palaestinensische Terrornehmer nehmen israelische Athleten als Geiseln. Tragisches Ende.",
	 "category": Category.DISASTERS, "effect": {"reputation": -3}, "important": true},
	{"year": 1972, "month": 11, "title": "ATARI VEROEFFENTLICHT PONG",
	 "text": "Erstes kommerziell erfolgreiche Videospiel. Beginn der Gaming-Industrie.",
	 "category": Category.TECHNOLOGY, "effect": {"tech_discount": 0.02}},
	{"year": 1974, "month": 8, "title": "NIXON TRITT ZURUECK",
	 "text": "Präsident Nixon tritt wegen Watergate-Skandal zurueck. Erster US-Praesident-Ruecktritt.",
	 "category": Category.WORLD_POLITICS, "effect": {"inflation": 1.02}, "important": true},
	{"year": 1975, "month": 4, "title": "VIETNAM-KRIEG ENDET",
	 "text": "Saigon faellt. Vietnam-Krieg nach 20 Jahren beendet. Tausende fliehen.",
	 "category": Category.WORLD_POLITICS, "effect": {"demand": 0.98}, "important": true},
	{"year": 1976, "month": 7, "title": "VIKING 1 LANDET AUF MARS",
	 "text": "Erste erfolgreiche Marslandung einer US-Sonde. Historischer Moment fuer die Raumfahrt.",
	 "category": Category.SPACE, "effect": {"tech_discount": 0.03}},
	{"year": 1977, "month": 5, "title": "STAR WARS KOMMT IN DIE KINOS",
	 "text": "George Lucas' Weltraumepos veroeffentlicht. Beginn einer neuen Film-Aera.",
	 "category": Category.CULTURE, "effect": {}},
	{"year": 1977, "month": 8, "title": "ELVIS PRESLEY STIRBT",
	 "text": "King of Rock'n'Roll tot mit 42 Jahren. Weltweite Trauer.",
	 "category": Category.CULTURE, "effect": {}},
	{"year": 1978, "month": 7, "title": "ERSTES 'TESTTUBE-BABY' GEBOREN",
	 "text": "Louise Brown in England geboren - erstes Kind durch kuenstliche Befruchtung.",
	 "category": Category.TECHNOLOGY, "effect": {}},
	{"year": 1979, "month": 2, "title": "AYATOLLAH KHOMAINI UEBERNIMMT MACHT",
	 "text": "Islamische Revolution im Iran. Schah gestuerzt. Fundamentalistisches Regime errichtet.",
	 "category": Category.WORLD_POLITICS, "effect": {"oil_price_mult": 1.3}, "important": true},
	# 1980s - Technology & Politics
	{"year": 1980, "month": 5, "title": "PAC-MAN VEROEFFENTLICHT",
	 "text": "Das beruehmteste Videospiel aller Zeiten kommt in die Arcades.",
	 "category": Category.TECHNOLOGY, "effect": {}},
	{"year": 1980, "month": 12, "title": "JOHN LENNON ERMORDET",
	 "text": "Ex-Beatle John Lennon vor seiner Wohnung in New York erschossen. Weltweite Bestuerzung.",
	 "category": Category.CULTURE, "effect": {}, "important": true},
	{"year": 1981, "month": 8, "title": "IBM PC VEROEFFENTLICHT",
	 "text": "IBM stellt ersten Personal Computer vor. Beginn der PC-Revolution.",
	 "category": Category.TECHNOLOGY, "effect": {"tech_discount": 0.05}, "important": true},
	{"year": 1981, "month": 8, "title": "MTV GEHT ON AIR",
	 "text": "'Video Killed the Radio Star' - Musikfernsehen startet. Neue Aera der Popkultur.",
	 "category": Category.CULTURE, "effect": {}},
	{"year": 1982, "month": 6, "title": "E.T. IM KINO",
	 "text": "Steven Spielbergs E.T. wird zum erfolgreichsten Film aller Zeiten.",
	 "category": Category.CULTURE, "effect": {}},
	{"year": 1983, "month": 3, "title": "STRATEGIC DEFENSE INITIATIVE",
	 "text": "Reagan kuendigt 'Star Wars'-Raketenabwehr an. Wettruesten erreicht neuen Hoehepunkt.",
	 "category": Category.WORLD_POLITICS, "effect": {"inflation": 1.02}},
	{"year": 1984, "month": 1, "title": "APPLE MACINTOSH VORGESTELLT",
	 "text": "Erster erfolgreicher Computer mit grafischer Oberflaeche und Maus. '1984' Super-Bowl-Werbespot.",
	 "category": Category.TECHNOLOGY, "effect": {"tech_discount": 0.04}, "important": true},
	{"year": 1985, "month": 7, "title": "LIVE AID KONZERTE",
	 "text": "Bob Geldof organisiert weltweite Konzerte fuer Aethiopien. 1,5 Mrd. Zuschauer.",
	 "category": Category.CULTURE, "effect": {}},
	{"year": 1986, "month": 1, "title": "CHALLENGER EXPLODIERT",
	 "text": "Spaceshutter Challenger explodiert 73 Sekunden nach Start. Alle 7 Astronauten tot.",
	 "category": Category.DISASTERS, "effect": {"tech_discount": -0.02}, "important": true},
	{"year": 1986, "month": 4, "title": "TSCHERNOBYL KATASTROPHE",
	 "text": "Reaktorunfall in Tschernobyl. Radioaktive Wolke ueber Europa. Schlimmster Nuklearunfall.",
	 "category": Category.DISASTERS, "effect": {"oil_price_mult": 1.1, "safety_costs": 1.15}, "important": true},
	{"year": 1987, "month": 10, "title": "SCHWARZER MONTAG AN DER BOERSE",
	 "text": "Dow Jones faellt um 22% an einem Tag. Groesster Börsensturz seit 1929.",
	 "category": Category.ECONOMY, "effect": {"oil_price_mult": 0.9}, "important": true},
	{"year": 1988, "month": 11, "title": "BUSH SENIOR GEWAEHLT",
	 "text": "George H.W. Bush wird 41. US-Praesident. Verspricht 'sanftere, nettere Nation'.",
	 "category": Category.WORLD_POLITICS, "effect": {}},
	{"year": 1989, "month": 3, "title": "EXXON VALDEZ UMWELTKATASTROPHE",
	 "text": "Oeltanker laeuft vor Alaska auf Grund. 40.000 Tonnen Rohöl verschüttet.",
	 "category": Category.DISASTERS, "effect": {"reputation_all": -5}, "important": true},
	{"year": 1989, "month": 6, "title": "TIANANMEN-PLATZ MASSAKER",
	 "text": "Chinesische Armee beendet Demos gewaltsam. Bilder eines Mannes vor Panzer gehen um die Welt.",
	 "category": Category.WORLD_POLITICS, "effect": {}, "important": true},
	{"year": 1989, "month": 11, "title": "BERLINER MAUER FAELLT",
	 "text": "Grenzuebergaenge in Berlin geoeffnet. DDR-Buerger strömen in den Westen. Historischer Moment!",
	 "category": Category.WORLD_POLITICS, "effect": {"inflation": 0.98, "demand": 1.02}, "important": true},
	# 1990s - The Digital Age
	{"year": 1990, "month": 4, "title": "HUBBLE TELESKOP IM ALL",
	 "text": "Space Shuttle Discovery bringt Hubble in die Umlaufbahn. Neuer Blick ins Universum.",
	 "category": Category.SPACE, "effect": {"tech_discount": 0.02}},
	{"year": 1990, "month": 10, "title": "DEUTSCHE WIEDERVEREINIGUNG",
	 "text": "DDR tritt der BRD bei. Deutschland nach 45 Jahren wieder vereint.",
	 "category": Category.WORLD_POLITICS, "effect": {"demand": 1.03, "inflation": 0.99}, "important": true},
	{"year": 1991, "month": 12, "title": "SOWJETUNION AUFGELOEST",
	 "text": "Gorbatschow tritt zurueck. Sowjetunion zerteilt in 15 Republiken. Kalter Krieg beendet.",
	 "category": Category.WORLD_POLITICS, "effect": {"inflation": 0.98}, "important": true},
	{"year": 1992, "month": 2, "title": "MAASTRICHT-VERTRAG",
	 "text": "Europaeische Union gegruendet. Gemeinsame Waehrung geplant.",
	 "category": Category.WORLD_POLITICS, "effect": {"inflation": 0.99}},
	{"year": 1993, "month": 2, "title": "WTC-BOMBENANSCHLAG",
	 "text": "Bombenanschlag auf World Trade Center in New York. 6 Tote, ueber 1000 Verletzte.",
	 "category": Category.DISASTERS, "effect": {"reputation": -2}},
	{"year": 1994, "month": 4, "title": "MANDELA WIRD PRAESIDENT",
	 "text": "Nelson Mandela erster schwarzer Praesident Suedafrikas. Apartheid endgueltig beendet.",
	 "category": Category.WORLD_POLITICS, "effect": {}, "important": true},
	{"year": 1994, "month": 6, "title": "O.J. SIMPSON AUTOVERFOLGUNG",
	 "text": "O.J. Simpson flieht in weissem Ford Bronco. Meistgesehene Live-Verfolgungsjagd.",
	 "category": Category.CULTURE, "effect": {}},
	{"year": 1995, "month": 8, "title": "WINDOWS 95 VEROEFFENTLICHT",
	 "text": "Microsoft startet Windows 95 mit 'Start'-Button. Rolling Stones 'Start Me Up' als Werbesong.",
	 "category": Category.TECHNOLOGY, "effect": {"tech_discount": 0.05}, "important": true},
	{"year": 1996, "month": 7, "title": "DOLLY DAS KLONSCHAF",
	 "text": "Erstes erfolgreich geklontes Saeugetier aus erwachsener Zelle. Ethik-Debatte entsteht.",
	 "category": Category.TECHNOLOGY, "effect": {}},
	{"year": 1997, "month": 2, "title": "DOLLY PARTON SUPER BOWL",
	 "text": "Super Bowl XXXI: Packers schlagen Patriots. Prince performs halftime.",
	 "category": Category.SPORTS, "effect": {}},
	{"year": 1997, "month": 8, "title": "PRINZESSIN DIANA STIRBT",
	 "text": "Lady Di bei Autounfall in Paris tot. Weltweite Trauerwelle. Millionen auf den Strassen.",
	 "category": Category.CULTURE, "effect": {}, "important": true},
	{"year": 1998, "month": 1, "title": "LEWINSKY-SKANDAL",
	 "text": "Bill Clinton leugnet Affaere mit Praktikantin. 'I did not have sexual relations...'",
	 "category": Category.WORLD_POLITICS, "effect": {}},
	{"year": 1998, "month": 9, "title": "GOOGLE GEGRUENDET",
	 "text": "Larry Page und Sergey Brin gruenden Google. Beginn einer Suchmaschinen-Dominanz.",
	 "category": Category.TECHNOLOGY, "effect": {"tech_discount": 0.03}, "important": true},
	{"year": 1999, "month": 1, "title": "EURO EINGEFUEHRT",
	 "text": "Europaeische Waehrung offiziell eingefuehrt. 11 Laender beteiligt.",
	 "category": Category.ECONOMY, "effect": {"inflation": 0.99}},
	{"year": 1999, "month": 3, "title": "MATRIX IM KINO",
	 "text": "'The Matrix' revolutioniert Science-Fiction-Filme. 'Bullet Time' wird ikonisch.",
	 "category": Category.CULTURE, "effect": {}},
	{"year": 1999, "month": 12, "title": "Y2K-ANGST VOR JAHRESWECHSEL",
	 "text": "Welt bereitet sich auf moeglichen Computer-Crash vor. 'Millennium-Bug' Panik.",
	 "category": Category.TECHNOLOGY, "effect": {}}
]

# --- COMPANY NEWS TEMPLATES ---
const COMPANY_SUCCESS_TEMPLATES = [
	{"title": "GROSSER OELFUND FUER %s!", "text": "%s kuendet Entdeckung massiver Oelreserven an. Aktienkurse steigen!", "min_cash": 10000000},
	{"title": "%s UNTERSCHREIBT MEGA-VERTRAG", "text": "%s sichert Milliardendeal mit grossem Abnehmer.", "min_cash": 5000000},
	{"title": "%s ERWEITERT OPERATIONEN", "text": "%s eroeffnet neue Bohrungen in vielversprechendem Gebiet.", "min_cash": 2000000},
	{"title": "%s SCHLAEGT QUARTALSERWARTUNGEN", "text": "Analysten ueberrascht: %s meldet bessere Gewinne als erwartet.", "min_cash": 1000000}
]

const COMPANY_FAILURE_TEMPLATES = [
	{"title": "TROCKENES BOHRLOCH KATASTROPHE FUER %s", "text": "%s verschwendet Millionen an unproduktivem Brunnen. Investoren besorgt.", "cash_loss": 500000},
	{"title": "%s MIT SICHERHEITSVERSTOESSEN KONFRONTIERT", "text": "Behoerden zitieren %s wegen Arbeitsplatzsicherheitsverstössen.", "reputation_max": 50},
	{"title": "%s OELPEST-UNTERSUCHUNG", "text": "Umweltbehoerden untersuchen %s wegen angeblicher Verschmutzung.", "reputation_max": 60}
]

# --- RANDOM WORLD EVENTS (Generated dynamically) ---
const RANDOM_WORLD_EVENTS = [
	{"title": "NEUE OELFELDENTDECKUNG IN DER NORDSEE", "text": "Massive Reserven entdeckt. Europaeische Produktion steigt.", "category": Category.OIL_DISCOVERY, "effect": {"oil_price_mult": 0.95}},
	{"title": "HURRIKAN BEDROHT GOLFPLATTFORMEN", "text": "Sturm erzwingt Evakuierung von Offshore-Rigs. Produktion gestoppt.", "category": Category.DISASTERS, "effect": {"production": 0.8}},
	{"title": "TECHNOLOGISCHER DURCHBRUCH BEIM BOHREN", "text": "Neue Techniken versprechen tiefere, guenstigere Bohrungen.", "category": Category.TECHNOLOGY, "effect": {"drill_cost": 0.9}},
	{"title": "UMWELTGRUPPEN PROTESTIEREN", "text": "Greenpeace inszeniert Protest an grossem Oelterminal.", "category": Category.DISASTERS, "effect": {"reputation_all": -5}},
	{"title": "NEUE PIPELINE EROEFFNET", "text": "Grosse Pipeline fertiggestellt, Transportkosten gesenkt.", "category": Category.OIL_DISCOVERY, "effect": {"transport": 0.95}},
	{"title": "FINANZMINISTER TREFFEN", "text": "G7-Finanzminister diskutieren globale Wirtschaftspolitik.", "category": Category.ECONOMY, "effect": {}},
	{"title": "NEUE AUTOMODELLS VORGESTELLT", "text": "Automesse zeigt Benzinfresser. Oelnachfrage koennte steigen.", "category": Category.ECONOMY, "effect": {"demand": 1.01}},
	{"title": "ERDKUNDUNGSSATELLIT GESTARTET", "text": "Neuer Satellit wird geologische Daten verbessern.", "category": Category.SPACE, "effect": {"survey_accuracy": 0.05}},
	{"title": "GEWERKSCHAFT STREIKT", "text": "Hafenarbeiter legen Arbeit nieder. Oel-Exporte verzoegert.", "category": Category.ECONOMY, "effect": {"transport": 1.1}},
	{"title": "NEUE UMWELTVORSCHRIFTEN", "text": "Regierung verschaeft Umweltschutzgesetze.", "category": Category.WORLD_POLITICS, "effect": {"safety_costs": 1.05}}
]

# --- STATE ---
var game_manager = null
var triggered_events: Dictionary = {}
var current_headlines: Array = []
var newspaper_history: Array = []
var pending_news: Array = []  # News that should auto-show
var has_important_news: bool = false

# --- ASSET PATHS (To be replaced with real assets) ---
const ASSETS = {
	"newspaper_1970s_frame": "res://assets/news/newspaper_1970s.png",
	"newspaper_1980s_frame": "res://assets/news/newspaper_1980s.png",
	"tv_frame": "res://assets/news/oilnn_tv.png",
	"portal_bg": "res://assets/news/oilnn_portal.png",
	"breaking_banner": "res://assets/news/breaking_banner.png"
}

func _ready():
	await get_tree().create_timer(0.5).timeout
	if has_node("/root/GameManager"):
		game_manager = get_node("/root/GameManager")

# --- GET CURRENT MEDIA TYPE ---
func get_current_media_type() -> int:
	if game_manager == null:
		return MediaType.NEWSPAPER_1970S
	
	var year = game_manager.date["year"]
	var era = game_manager.current_era
	
	# Check by era first (for upgraded systems)
	match era:
		0: return MediaType.NEWSPAPER_1970S
		1: return MediaType.NEWSPAPER_1980S
		2:
			if year >= 2000:
				return MediaType.ONLINE_PORTAL_2000S
			return MediaType.TV_NEWS_1990S
		_:
			if year >= 2000:
				return MediaType.ONLINE_PORTAL_2000S
			elif year >= 1995:
				return MediaType.TV_NEWS_1990S
			elif year >= 1982:
				return MediaType.NEWSPAPER_1980S
			else:
				return MediaType.NEWSPAPER_1970S

func get_media_type_name() -> String:
	match get_current_media_type():
		MediaType.NEWSPAPER_1970S: return "THE DAILY BARREL"
		MediaType.NEWSPAPER_1980S: return "THE DAILY BARREL"
		MediaType.TV_NEWS_1990S: return "OilNN"
		MediaType.ONLINE_PORTAL_2000S: return "OilNN.com"
		_: return "NEWS"

# --- MONTHLY NEWS GENERATION ---
func check_monthly_events():
	if game_manager == null:
		return []
	
	current_headlines.clear()
	has_important_news = false
	var year = game_manager.date["year"]
	var month = game_manager.date["month"]
	
	# 1. Check historical oil events
	for event in HISTORICAL_OIL_EVENTS:
		var event_key = "oil_%d_%d" % [event["year"], event["month"]]
		if not triggered_events.has(event_key):
			if year == event["year"] and month == event["month"]:
				triggered_events[event_key] = true
				var headline = _create_headline_from_event(event)
				current_headlines.append(headline)
				if event.get("important", false):
					has_important_news = true
					pending_news.append(headline)
				_apply_event_effect(event.get("effect", {}))
	
	# 2. Check world events
	for event in WORLD_EVENTS:
		var event_key = "world_%d_%d" % [event["year"], event["month"]]
		if not triggered_events.has(event_key):
			if year == event["year"] and month == event["month"]:
				triggered_events[event_key] = true
				var headline = _create_headline_from_event(event)
				current_headlines.append(headline)
				if event.get("important", false):
					has_important_news = true
				_apply_event_effect(event.get("effect", {}))
	
	# 3. Generate random world event (15% chance)
	if randf() < 0.15:
		var event = RANDOM_WORLD_EVENTS.pick_random()
		var headline = _create_headline_from_event(event)
		current_headlines.append(headline)
		_apply_event_effect(event.get("effect", {}))
	
	# 4. Generate company-specific news
	current_headlines.append_array(_generate_company_news())
	
	# 5. Store headlines with date
	for headline in current_headlines:
		headline["date"] = "%02d/%d" % [month, year]
		newspaper_history.append(headline)
		news_published.emit(headline["title"], _category_to_string(headline["category"]), headline.get("important", false))
	
	return current_headlines

func _create_headline_from_event(event: Dictionary) -> Dictionary:
	return {
		"title": event["title"],
		"text": event["text"],
		"category": event["category"],
		"effect": event.get("effect", {}),
		"important": event.get("important", false)
	}

func _category_to_string(cat: int) -> String:
	match cat:
		Category.OIL_DISCOVERY: return "Oel-Entdeckung"
		Category.OIL_CRISIS: return "Oelkrise"
		Category.OPEC_NEWS: return "OPEC"
		Category.COMPANY_NEWS: return "Firmen-News"
		Category.MARKET_NEWS: return "Markt"
		Category.WORLD_POLITICS: return "Weltpolitik"
		Category.TECHNOLOGY: return "Technologie"
		Category.CULTURE: return "Kultur"
		Category.SPORTS: return "Sport"
		Category.DISASTERS: return "Katastrophen"
		Category.ECONOMY: return "Wirtschaft"
		Category.SPACE: return "Weltraum"
		_: return "Allgemein"

# --- APPLY GAMEPLAY EFFECTS ---
func _apply_event_effect(effect: Dictionary):
	if game_manager == null:
		return
	
	# Oil price multiplier
	if effect.has("oil_price_mult"):
		game_manager.price_multiplier *= effect["oil_price_mult"]
	
	# Inflation
	if effect.has("inflation"):
		game_manager.inflation_rate *= effect["inflation"]
	
	# Region blocked
	if effect.has("region_blocked"):
		if game_manager.regions.has(effect["region_blocked"]):
			game_manager.regions[effect["region_blocked"]]["block_timer"] = 6
	
	# Tech discount (temporary, stored in game_manager)
	if effect.has("tech_discount"):
		if not game_manager.has("temp_tech_discount"):
			game_manager.set_meta("temp_tech_discount", 0.0)
		var current = game_manager.get_meta("temp_tech_discount", 0.0)
		game_manager.set_meta("temp_tech_discount", current + effect["tech_discount"])
	
	# Demand modifier
	if effect.has("demand"):
		if not game_manager.has("demand_modifier"):
			game_manager.set_meta("demand_modifier", 1.0)
		var current = game_manager.get_meta("demand_modifier", 1.0)
		game_manager.set_meta("demand_modifier", current * effect["demand"])
	
	# Safety costs
	if effect.has("safety_costs"):
		if not game_manager.has("safety_cost_mult"):
			game_manager.set_meta("safety_cost_mult", 1.0)
		var current = game_manager.get_meta("safety_cost_mult", 1.0)
		game_manager.set_meta("safety_cost_mult", current * effect["safety_costs"])

# --- COMPANY NEWS GENERATION ---
func _generate_company_news() -> Array:
	var news = []
	if game_manager == null:
		return news
	
	var company = game_manager.company_name
	if company == "":
		company = "Ihre Firma"
	
	# Success news based on performance
	if game_manager.cash > 5000000:
		var template = COMPANY_SUCCESS_TEMPLATES[0]
		news.append({
			"title": template["title"] % company,
			"text": template["text"] % company,
			"category": Category.COMPANY_NEWS,
			"important": false
		})
	
	# Failure news if things are going badly
	if game_manager.cash < 1000000 and game_manager.cash > 0:
		var template = COMPANY_FAILURE_TEMPLATES[4] if COMPANY_FAILURE_TEMPLATES.size() > 4 else COMPANY_FAILURE_TEMPLATES[0]
		news.append({
			"title": template["title"] % company,
			"text": template["text"] % company,
			"category": Category.COMPANY_NEWS,
			"important": false
		})
	
	return news

# --- CHECK IF SHOULD AUTO-SHOW ---
func should_auto_show_news() -> bool:
	return has_important_news or pending_news.size() > 0

func get_pending_news() -> Array:
	var news = pending_news.duplicate()
	pending_news.clear()
	has_important_news = false
	return news

func clear_pending_news():
	pending_news.clear()
	has_important_news = false

# --- CREATE NEWS DISPLAY ---
func create_news_display() -> Control:
	var media_type = get_current_media_type()
	
	match media_type:
		MediaType.NEWSPAPER_1970S:
			return _create_newspaper_1970s()
		MediaType.NEWSPAPER_1980S:
			return _create_newspaper_1980s()
		MediaType.TV_NEWS_1990S:
			return _create_tv_news()
		MediaType.ONLINE_PORTAL_2000S:
			return _create_online_portal()
		_:
			return _create_newspaper_1970s()

# --- 1970s NEWSPAPER LAYOUT ---
func _create_newspaper_1970s() -> Control:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(700, 900)
	
	# Old paper style
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.95, 0.92, 0.85)  # Aged paper
	style.border_color = Color(0.3, 0.25, 0.2)
	style.set_border_width_all(4)
	style.set_corner_radius_all(2)
	panel.add_theme_stylebox_override("panel", style)
	
	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 8)
	panel.add_child(main_vbox)
	
	# Masthead
	var masthead_box = HBoxContainer.new()
	main_vbox.add_child(masthead_box)
	
	var masthead = Label.new()
	masthead.text = "═══════ THE DAILY BARREL ═══════"
	masthead.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	masthead.add_theme_font_size_override("font_size", 32)
	masthead.add_theme_color_override("font_color", Color(0.15, 0.1, 0.05))
	masthead.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	masthead_box.add_child(masthead)
	
	# Date line
	var date_line = Label.new()
	if game_manager:
		date_line.text = "Vol. %d  |  %s %d  |  Oel: $%.2f/Fass  |  Preis: $%.0f" % [
			game_manager.date["year"] - 1969,
			_get_month_name(game_manager.date["month"]),
			game_manager.date["year"],
			game_manager.oil_price,
			game_manager.cash
		]
	date_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	date_line.add_theme_font_size_override("font_size", 11)
	date_line.add_theme_color_override("font_color", Color(0.3, 0.25, 0.2))
	main_vbox.add_child(date_line)
	
	# Separator line
	var sep1 = HSeparator.new()
	sep1.add_theme_stylebox_override("separator", _create_black_line())
	main_vbox.add_child(sep1)
	
	# Important news banner (if any)
	var important_headlines = current_headlines.filter(func(h): return h.get("important", false))
	if important_headlines.size() > 0:
		var banner = _create_headline_banner(important_headlines[0])
		main_vbox.add_child(banner)
		
		var sep2 = HSeparator.new()
		sep2.add_theme_stylebox_override("separator", _create_black_line())
		main_vbox.add_child(sep2)
	
	# Scrollable content
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size.y = 600
	main_vbox.add_child(scroll)
	
	var content_vbox = VBoxContainer.new()
	content_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_vbox.add_theme_constant_override("separation", 12)
	scroll.add_child(content_vbox)
	
	# Two-column layout for regular news
	var columns = HBoxContainer.new()
	columns.add_theme_constant_override("separation", 15)
	content_vbox.add_child(columns)
	
	var left_col = VBoxContainer.new()
	left_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_col.add_theme_constant_override("separation", 10)
	columns.add_child(left_col)
	
	var right_col = VBoxContainer.new()
	right_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_col.add_theme_constant_override("separation", 10)
	columns.add_child(right_col)
	
	# Add headlines to columns
	var regular_headlines = current_headlines.filter(func(h): return not h.get("important", false))
	for i in range(regular_headlines.size()):
		var item = _create_headline_item_newspaper(regular_headlines[i])
		if i % 2 == 0:
			left_col.add_child(item)
		else:
			right_col.add_child(item)
	
	# Footer
	var footer = Label.new()
	footer.text = "═══════════════════════════════════════════════════════════════"
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.add_theme_color_override("font_color", Color(0.3, 0.25, 0.2))
	main_vbox.add_child(footer)
	
	# Copyright
	var copyright = Label.new()
	copyright.text = "© 1970s The Daily Barrel - Alle Rechte vorbehalten"
	copyright.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	copyright.add_theme_font_size_override("font_size", 9)
	copyright.add_theme_color_override("font_color", Color(0.4, 0.35, 0.3))
	main_vbox.add_child(copyright)
	
	return panel

func _create_headline_banner(headline: Dictionary) -> Control:
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	
	# Category tag
	var cat_label = Label.new()
	cat_label.text = "[ " + _category_to_string(headline["category"]).to_upper() + " ]"
	cat_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cat_label.add_theme_font_size_override("font_size", 12)
	cat_label.add_theme_color_override("font_color", Color(0.6, 0.1, 0.1))
	vbox.add_child(cat_label)
	
	# Main headline
	var title = Label.new()
	title.text = headline["title"]
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.1, 0.05, 0.0))
	title.add_theme_font_size_override("outline_size", 1)
	title.add_theme_color_override("font_outline_color", Color(0.8, 0.75, 0.7))
	vbox.add_child(title)
	
	# Story text
	var text = Label.new()
	text.text = headline["text"]
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.autowrap_mode = TextServer.AUTOWRAP_WORD
	text.add_theme_font_size_override("font_size", 14)
	text.add_theme_color_override("font_color", Color(0.2, 0.15, 0.1))
	vbox.add_child(text)
	
	return vbox

func _create_headline_item_newspaper(headline: Dictionary) -> Control:
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 3)
	
	# Title
	var title = Label.new()
	title.text = headline["title"]
	title.autowrap_mode = TextServer.AUTOWRAP_WORD
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", _get_category_color(headline["category"]))
	vbox.add_child(title)
	
	# Text
	var text = Label.new()
	text.text = headline["text"]
	text.autowrap_mode = TextServer.AUTOWRAP_WORD
	text.add_theme_font_size_override("font_size", 11)
	text.add_theme_color_override("font_color", Color(0.25, 0.2, 0.15))
	vbox.add_child(text)
	
	# Thin separator
	var sep = HSeparator.new()
	sep.add_theme_stylebox_override("separator", _create_thin_line())
	vbox.add_child(sep)
	
	return vbox

# --- 1980s NEWSPAPER LAYOUT (Color version) ---
func _create_newspaper_1980s() -> Control:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(750, 950)
	
	# Brighter paper style
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.98, 0.96, 0.92)  # Brighter paper
	style.border_color = Color(0.2, 0.2, 0.3)
	style.set_border_width_all(3)
	style.set_corner_radius_all(3)
	panel.add_theme_stylebox_override("panel", style)
	
	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 10)
	panel.add_child(main_vbox)
	
	# Colorful masthead
	var masthead_bg = PanelContainer.new()
	var masthead_style = StyleBoxFlat.new()
	masthead_style.bg_color = Color(0.1, 0.15, 0.35)  # Dark blue
	masthead_bg.add_theme_stylebox_override("panel", masthead_style)
	main_vbox.add_child(masthead_bg)
	
	var masthead = Label.new()
	masthead.text = "★ THE DAILY BARREL ★"
	masthead.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	masthead.add_theme_font_size_override("font_size", 36)
	masthead.add_theme_color_override("font_color", Color(1, 0.9, 0.2))  # Gold
	masthead_bg.add_child(masthead)
	
	# Date with colored background
	var date_box = PanelContainer.new()
	var date_style = StyleBoxFlat.new()
	date_style.bg_color = Color(0.8, 0.1, 0.1)  # Red
	date_box.add_theme_stylebox_override("panel", date_style)
	main_vbox.add_child(date_box)
	
	var date_line = Label.new()
	if game_manager:
		date_line.text = "  %s %d | OELPREIS: $%.2f | IHRE KASSE: $%.0f  " % [
			_get_month_name(game_manager.date["month"]),
			game_manager.date["year"],
			game_manager.oil_price,
			game_manager.cash
		]
	date_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	date_line.add_theme_font_size_override("font_size", 13)
	date_line.add_theme_color_override("font_color", Color.WHITE)
	date_box.add_child(date_line)
	
	# Scrollable content
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size.y = 700
	main_vbox.add_child(scroll)
	
	var content_vbox = VBoxContainer.new()
	content_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_vbox.add_theme_constant_override("separation", 15)
	scroll.add_child(content_vbox)
	
	# Breaking news box
	var important_headlines = current_headlines.filter(func(h): return h.get("important", false))
	if important_headlines.size() > 0:
		var breaking_box = _create_80s_breaking_box(important_headlines[0])
		content_vbox.add_child(breaking_box)
	
	# Headlines with photos placeholder
	for headline in current_headlines:
		if not headline.get("important", false):
			var item = _create_headline_item_80s(headline)
			content_vbox.add_child(item)
	
	return panel

func _create_80s_breaking_box(headline: Dictionary) -> Control:
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	
	# Breaking banner
	var banner_bg = PanelContainer.new()
	var banner_style = StyleBoxFlat.new()
	banner_style.bg_color = Color(0.9, 0.2, 0.1)
	banner_bg.add_theme_stylebox_override("panel", banner_style)
	vbox.add_child(banner_bg)
	
	var banner = Label.new()
	banner.text = "⚡ BREAKING NEWS ⚡"
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.add_theme_font_size_override("font_size", 18)
	banner.add_theme_color_override("font_color", Color.WHITE)
	banner_bg.add_child(banner)
	
	# Content box
	var content_bg = PanelContainer.new()
	var content_style = StyleBoxFlat.new()
	content_style.bg_color = Color(0.95, 0.95, 0.9)
	content_style.set_border_width_all(2)
	content_style.border_color = Color(0.9, 0.2, 0.1)
	content_bg.add_theme_stylebox_override("panel", content_style)
	vbox.add_child(content_bg)
	
	var content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 5)
	content_bg.add_child(content)
	
	var title = Label.new()
	title.text = headline["title"]
	title.autowrap_mode = TextServer.AUTOWRAP_WORD
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(0.1, 0.1, 0.2))
	content.add_child(title)
	
	var text = Label.new()
	text.text = headline["text"]
	text.autowrap_mode = TextServer.AUTOWRAP_WORD
	text.add_theme_font_size_override("font_size", 13)
	text.add_theme_color_override("font_color", Color(0.2, 0.2, 0.25))
	content.add_child(text)
	
	return vbox

func _create_headline_item_80s(headline: Dictionary) -> Control:
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	
	# Color indicator
	var indicator = PanelContainer.new()
	indicator.custom_minimum_size = Vector2(5, 60)
	var ind_style = StyleBoxFlat.new()
	ind_style.bg_color = _get_category_color(headline["category"])
	indicator.add_theme_stylebox_override("panel", ind_style)
	hbox.add_child(indicator)
	
	# Content
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 3)
	hbox.add_child(vbox)
	
	var title = Label.new()
	title.text = headline["title"]
	title.autowrap_mode = TextServer.AUTOWRAP_WORD
	title.add_theme_font_size_override("font_size", 15)
	title.add_theme_color_override("font_color", Color(0.1, 0.1, 0.15))
	vbox.add_child(title)
	
	var text = Label.new()
	text.text = headline["text"]
	text.autowrap_mode = TextServer.AUTOWRAP_WORD
	text.add_theme_font_size_override("font_size", 11)
	text.add_theme_color_override("font_color", Color(0.3, 0.3, 0.35))
	vbox.add_child(text)
	
	# Category tag
	var cat = Label.new()
	cat.text = _category_to_string(headline["category"])
	cat.add_theme_font_size_override("font_size", 9)
	cat.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
	vbox.add_child(cat)
	
	return hbox

# --- 1990s TV NEWS LAYOUT ---
func _create_tv_news() -> Control:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(800, 600)
	
	# Dark TV style
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.1)
	style.border_color = Color(0.3, 0.3, 0.3)
	style.set_border_width_all(8)
	panel.add_theme_stylebox_override("panel", style)
	
	var main_vbox = VBoxContainer.new()
	panel.add_child(main_vbox)
	
	# OilNN Header bar
	var header_bg = PanelContainer.new()
	var header_style = StyleBoxFlat.new()
	header_style.bg_color = Color(0.8, 0.1, 0.1)  # Red news banner
	header_bg.add_theme_stylebox_override("panel", header_style)
	main_vbox.add_child(header_bg)
	
	var header_hbox = HBoxContainer.new()
	header_bg.add_child(header_hbox)
	
	var logo = Label.new()
	logo.text = " OilNN "
	logo.add_theme_font_size_override("font_size", 28)
	logo.add_theme_color_override("font_color", Color.WHITE)
	logo.add_theme_font_size_override("outline_size", 2)
	logo.add_theme_color_override("font_outline_color", Color(0.2, 0.2, 0.8))
	header_hbox.add_child(logo)
	
	var live = Label.new()
	live.text = " ● LIVE"
	live.add_theme_font_size_override("font_size", 18)
	live.add_theme_color_override("font_color", Color.RED)
	header_hbox.add_child(live)
	
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_hbox.add_child(spacer)
	
	var time_label = Label.new()
	if game_manager:
		time_label.text = " %s %d " % [_get_month_name(game_manager.date["month"]), game_manager.date["year"]]
	time_label.add_theme_font_size_override("font_size", 16)
	time_label.add_theme_color_override("font_color", Color.WHITE)
	header_hbox.add_child(time_label)
	
	# Main content area
	var content_area = PanelContainer.new()
	var content_style = StyleBoxFlat.new()
	content_style.bg_color = Color(0.1, 0.1, 0.15)
	content_area.add_theme_stylebox_override("panel", content_style)
	content_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(content_area)
	
	var content_vbox = VBoxContainer.new()
	content_vbox.add_theme_constant_override("separation", 15)
	content_area.add_child(content_vbox)
	
	# Breaking news ticker (animated)
	if current_headlines.size() > 0 and current_headlines[0].get("important", false):
		var ticker = _create_ticker(current_headlines[0])
		content_vbox.add_child(ticker)
	
	# News items in TV style
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_vbox.add_child(scroll)
	
	var news_list = VBoxContainer.new()
	news_list.add_theme_constant_override("separation", 12)
	scroll.add_child(news_list)
	
	for headline in current_headlines:
		var item = _create_tv_news_item(headline)
		news_list.add_child(item)
	
	# Bottom ticker bar
	var ticker_bg = PanelContainer.new()
	var ticker_style = StyleBoxFlat.new()
	ticker_style.bg_color = Color(0.1, 0.2, 0.4)
	ticker_bg.add_theme_stylebox_override("panel", ticker_style)
	main_vbox.add_child(ticker_bg)
	
	var ticker_text = Label.new()
	if game_manager:
		ticker_text.text = "OELPREIS: $%.2f/bbl  |  DOW JONES: %d  |  DOLLAR: %.2f DM  |  GOLDCHECK  |  WETTER: %s" % [
			game_manager.oil_price,
			2000 + randi() % 8000,
			2.5 + randf() * 0.5,
			["SONNIG", "BEWOELKT", "REGEN", "STURM"].pick_random()
		]
	ticker_text.add_theme_color_override("font_color", Color.WHITE)
	ticker_text.add_theme_font_size_override("font_size", 12)
	ticker_bg.add_child(ticker_text)
	
	return panel

func _create_ticker(headline: Dictionary) -> Control:
	var ticker_bg = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.9, 0.1, 0.1)
	ticker_bg.add_theme_stylebox_override("panel", style)
	
	var hbox = HBoxContainer.new()
	ticker_bg.add_child(hbox)
	
	var breaking = Label.new()
	breaking.text = " BREAKING: "
	breaking.add_theme_font_size_override("font_size", 16)
	breaking.add_theme_color_override("font_color", Color.YELLOW)
	hbox.add_child(breaking)
	
	var title = Label.new()
	title.text = headline["title"]
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color.WHITE)
	hbox.add_child(title)
	
	return ticker_bg

func _create_tv_news_item(headline: Dictionary) -> Control:
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 15)
	
	# Left indicator
	var indicator = PanelContainer.new()
	indicator.custom_minimum_size = Vector2(8, 50)
	var ind_style = StyleBoxFlat.new()
	ind_style.bg_color = _get_category_color(headline["category"])
	indicator.add_theme_stylebox_override("panel", ind_style)
	hbox.add_child(indicator)
	
	# Content
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 4)
	hbox.add_child(vbox)
	
	var title = Label.new()
	title.text = headline["title"]
	title.autowrap_mode = TextServer.AUTOWRAP_WORD
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(title)
	
	var text = Label.new()
	text.text = headline["text"]
	text.autowrap_mode = TextServer.AUTOWRAP_WORD
	text.add_theme_font_size_override("font_size", 12)
	text.add_theme_color_override("font_color", Color(0.8, 0.8, 0.85))
	vbox.add_child(text)
	
	# Category and time
	var meta = Label.new()
	meta.text = _category_to_string(headline["category"]) + " | " + headline.get("date", "")
	meta.add_theme_font_size_override("font_size", 10)
	meta.add_theme_color_override("font_color", Color(0.5, 0.6, 0.7))
	vbox.add_child(meta)
	
	return hbox

# --- 2000s ONLINE PORTAL LAYOUT ---
func _create_online_portal() -> Control:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(850, 700)
	
	# Modern web style
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.98, 0.98, 1.0)
	style.border_color = Color(0.8, 0.8, 0.85)
	style.set_border_width_all(1)
	panel.add_theme_stylebox_override("panel", style)
	
	var main_vbox = VBoxContainer.new()
	panel.add_child(main_vbox)
	
	# Header bar
	var header_bg = PanelContainer.new()
	var header_style = StyleBoxFlat.new()
	header_style.bg_color = Color(0.1, 0.15, 0.35)
	header_style.set_content_margin_all(10)
	header_bg.add_theme_stylebox_override("panel", header_style)
	main_vbox.add_child(header_bg)
	
	var header_hbox = HBoxContainer.new()
	header_hbox.add_theme_constant_override("separation", 20)
	header_bg.add_child(header_hbox)
	
	var logo = Label.new()
	logo.text = "OilNN.com"
	logo.add_theme_font_size_override("font_size", 28)
	logo.add_theme_color_override("font_color", Color.WHITE)
	header_hbox.add_child(logo)
	
	var nav1 = Label.new()
	nav1.text = "OEL  |  WELT  |  TECH  |  WIRTSCHAFT"
	nav1.add_theme_font_size_override("font_size", 14)
	nav1.add_theme_color_override("font_color", Color(0.7, 0.75, 0.9))
	header_hbox.add_child(nav1)
	
	# Search bar placeholder
	var search = Label.new()
	search.text = "🔍 Suchen..."
	search.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	search.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	search.add_theme_font_size_override("font_size", 13)
	search.add_theme_color_override("font_color", Color(0.6, 0.65, 0.8))
	header_hbox.add_child(search)
	
	# Content grid
	var grid = GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 15)
	grid.add_theme_constant_override("v_separation", 15)
	main_vbox.add_child(grid)
	
	# Featured story (spans 2 columns)
	if current_headlines.size() > 0:
		var featured = current_headlines[0] if current_headlines[0].get("important", false) else current_headlines.pick_random()
		var featured_box = _create_web_featured(featured)
		featured_box.custom_minimum_size = Vector2(500, 250)
		grid.add_child(featured_box)
		
		# Trending sidebar
		var trending = _create_trending_sidebar()
		trending.custom_minimum_size = Vector2(200, 250)
		grid.add_child(trending)
	
	# Regular news cards
	for i in range(min(current_headlines.size() - 1, 6)):
		var card = _create_news_card(current_headlines[i + 1])
		card.custom_minimum_size = Vector2(250, 150)
		grid.add_child(card)
	
	# Footer
	var footer = PanelContainer.new()
	var footer_style = StyleBoxFlat.new()
	footer_style.bg_color = Color(0.15, 0.15, 0.2)
	footer.add_theme_stylebox_override("panel", footer_style)
	main_vbox.add_child(footer)
	
	var footer_text = Label.new()
	footer_text.text = "© 2000+ OilNN.com | Alle Rechte vorbehalten | Impressum | Datenschutz"
	footer_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer_text.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	footer.add_child(footer_text)
	
	return panel

func _create_web_featured(headline: Dictionary) -> Control:
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.95, 0.95, 0.98)
	style.set_border_width_all(2)
	style.border_color = _get_category_color(headline["category"])
	panel.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)
	
	# Category badge
	var badge = Label.new()
	badge.text = " " + _category_to_string(headline["category"]).to_upper() + " "
	badge.add_theme_font_size_override("font_size", 11)
	badge.add_theme_color_override("font_color", Color.WHITE)
	badge.add_theme_font_size_override("outline_size", 1)
	badge.add_theme_color_override("font_outline_color", _get_category_color(headline["category"]))
	vbox.add_child(badge)
	
	# Title
	var title = Label.new()
	title.text = headline["title"]
	title.autowrap_mode = TextServer.AUTOWRAP_WORD
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0.1, 0.1, 0.15))
	vbox.add_child(title)
	
	# Text
	var text = Label.new()
	text.text = headline["text"]
	text.autowrap_mode = TextServer.AUTOWRAP_WORD
	text.add_theme_font_size_override("font_size", 13)
	text.add_theme_color_override("font_color", Color(0.3, 0.3, 0.4))
	vbox.add_child(text)
	
	# Meta
	var meta = Label.new()
	meta.text = headline.get("date", "") + " | 5 Min. Lesezeit"
	meta.add_theme_font_size_override("font_size", 10)
	meta.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	vbox.add_child(meta)
	
	return panel

func _create_news_card(headline: Dictionary) -> Control:
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color.WHITE
	style.set_border_width_all(1)
	style.border_color = Color(0.85, 0.85, 0.9)
	style.set_corner_radius_all(5)
	panel.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	panel.add_child(vbox)
	
	# Color bar
	var bar = PanelContainer.new()
	bar.custom_minimum_size.y = 4
	var bar_style = StyleBoxFlat.new()
	bar_style.bg_color = _get_category_color(headline["category"])
	bar.add_theme_stylebox_override("panel", bar_style)
	vbox.add_child(bar)
	
	var title = Label.new()
	title.text = headline["title"]
	title.autowrap_mode = TextServer.AUTOWRAP_WORD
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(0.15, 0.15, 0.2))
	vbox.add_child(title)
	
	var cat = Label.new()
	cat.text = _category_to_string(headline["category"])
	cat.add_theme_font_size_override("font_size", 9)
	cat.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	vbox.add_child(cat)
	
	return panel

func _create_trending_sidebar() -> Control:
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.15, 0.35)
	panel.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)
	
	var trending_label = Label.new()
	trending_label.text = "🔥 TRENDING"
	trending_label.add_theme_font_size_override("font_size", 14)
	trending_label.add_theme_color_override("font_color", Color.YELLOW)
	vbox.add_child(trending_label)
	
	var topics = ["Oelpreis steigt", "Neue Bohrtechnik", "OPEC-Tagung", "Umweltauflagen", "Tech-Boom"]
	for i in range(topics.size()):
		var topic = Label.new()
		topic.text = "%d. %s" % [i + 1, topics[i]]
		topic.add_theme_font_size_override("font_size", 11)
		topic.add_theme_color_override("font_color", Color(0.8, 0.85, 0.95))
		vbox.add_child(topic)
	
	return panel

# --- HELPER FUNCTIONS ---
func _get_category_color(category: int) -> Color:
	match category:
		Category.OIL_DISCOVERY: return Color(0.1, 0.5, 0.2)
		Category.OIL_CRISIS: return Color(0.7, 0.1, 0.1)
		Category.OPEC_NEWS: return Color(0.6, 0.5, 0.1)
		Category.COMPANY_NEWS: return Color(0.2, 0.4, 0.7)
		Category.MARKET_NEWS: return Color(0.3, 0.3, 0.6)
		Category.WORLD_POLITICS: return Color(0.5, 0.2, 0.2)
		Category.TECHNOLOGY: return Color(0.2, 0.5, 0.7)
		Category.CULTURE: return Color(0.6, 0.3, 0.6)
		Category.SPORTS: return Color(0.2, 0.6, 0.3)
		Category.DISASTERS: return Color(0.6, 0.3, 0.1)
		Category.ECONOMY: return Color(0.3, 0.5, 0.3)
		Category.SPACE: return Color(0.3, 0.3, 0.6)
		_: return Color(0.3, 0.3, 0.3)

func _get_month_name(month: int) -> String:
	var months = ["Januar", "Februar", "Maerz", "April", "Mai", "Juni",
				  "Juli", "August", "September", "Oktober", "November", "Dezember"]
	return months[month - 1] if month >= 1 and month <= 12 else "Unbekannt"

func _create_black_line() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.15, 0.1)
	style.content_margin_top = 2
	return style

func _create_thin_line() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.6, 0.55, 0.5)
	style.content_margin_top = 1
	return style

# --- GETTERS ---
func get_current_headlines() -> Array:
	return current_headlines

func get_history_headlines(count: int = 20) -> Array:
	var start = max(0, newspaper_history.size() - count)
	return newspaper_history.slice(start)

# --- SAVE/LOAD ---
func get_save_data() -> Dictionary:
	return {
		"history": newspaper_history,
		"triggered_events": triggered_events
	}

func load_save_data(data: Dictionary):
	newspaper_history = data.get("history", [])
	triggered_events = data.get("triggered_events", {})
