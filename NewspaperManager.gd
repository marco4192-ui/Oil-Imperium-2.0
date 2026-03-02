extends Node
# NewspaperManager.gd - Dynamic news system with era-based evolution
# 1970s-80s: Classic Newspaper | 1990s: TV News "OilNN" | 2000s+: Online Portal
# Includes realistic oil crises with NEGATIVE gameplay effects

signal news_published(headline: String, category: String, is_important: bool)
signal breaking_news(headline: String)
signal market_crash(severity: float)  # New: Signal for severe market crashes

# --- NEWS MEDIA TYPES ---
enum MediaType {
	NEWSPAPER_1970S,
	NEWSPAPER_1980S,
	TV_NEWS_1990S,
	ONLINE_PORTAL_2000S
}

# --- NEWS CATEGORIES ---
enum Category {
	OIL_DISCOVERY,
	OIL_CRISIS,
	OPEC_NEWS,
	COMPANY_NEWS,
	MARKET_NEWS,
	WORLD_POLITICS,
	TECHNOLOGY,
	CULTURE,
	SPORTS,
	DISASTERS,
	ECONOMY,
	SPACE,
	MARKET_CRASH  # New: Severe market crash category
}

# --- CRISIS SEVERITY LEVELS ---
enum CrisisLevel {
	NONE,
	MILD,       # Small price impact
	MODERATE,   # Significant price impact, some sales restrictions
	SEVERE,     # Major price crash, sales heavily restricted
	CATASTROPHIC # Extreme crash, oil nearly unsellable
}

# --- STATE ---
var game_manager = null
var triggered_events: Dictionary = {}
var current_headlines: Array = []
var newspaper_history: Array = []
var pending_news: Array = []
var has_important_news: bool = false
var current_crisis_level: int = CrisisLevel.NONE
var crisis_duration_months: int = 0
var unsellable_oil_percent: float = 0.0  # Percentage of oil that CANNOT be sold

# --- ASSET PATHS ---
const ASSETS = {
	"newspaper_1970s_frame": "res://assets/news/newspaper_1970s.png",
	"newspaper_1980s_frame": "res://assets/news/newspaper_1980s.png",
	"tv_frame": "res://assets/news/oilnn_tv.png",
	"portal_bg": "res://assets/news/oilnn_portal.png",
	"breaking_banner": "res://assets/news/breaking_banner.png"
}

# ==============================================================================
# HISTORICAL OIL CRISES - NEGATIVE EVENTS WITH REAL IMPACTS
# ==============================================================================

const HISTORICAL_OIL_CRISES = [
	# ============================================================================
	# MAJOR PRICE CRASHES (Severe negative impacts)
	# ============================================================================
	
	# 1982-1985: The Creeping Oil Glut (gradual decline)
	{"year": 1982, "month": 3, "title": "OELSCHWEMME BILDET SICH",
	 "text": "Nach Jahren der Krisen senken Industrienationen Energieverbrauch. Autos werden effizienter, Kraftwerke stellen auf Kohle um. Erste Ueberkapazitaeten sichtbar.",
	 "category": Category.MARKET_CRASH, "crisis_level": CrisisLevel.MILD,
	 "effect": {"oil_price_mult": 0.85, "demand": 0.95, "unsellable": 0.05},
	 "duration": 36, "important": true},
	
	{"year": 1983, "month": 6, "title": "NORDSEE-OEL FLUTET MARKT",
	 "text": "Britische und norwegische Nordsee-Felder erreichen Rekordfoerderung. Ueberangebot drueckt Preise weiter. OPEC unter Druck.",
	 "category": Category.MARKET_CRASH, "crisis_level": CrisisLevel.MILD,
	 "effect": {"oil_price_mult": 0.9, "unsellable": 0.08},
	 "duration": 12, "important": true},
	
	{"year": 1985, "month": 1, "title": "OPEC VERLIERT KONTROLLE",
	 "text": "Saudi-Arabien wird zum 'Swing Producer' gedraengt - drosselt Produktion, verliert Marktanteile. Andere OPEC-Mitglieder foerdern wild. Preise fallen weiter.",
	 "category": Category.MARKET_CRASH, "crisis_level": CrisisLevel.MODERATE,
	 "effect": {"oil_price_mult": 0.8, "demand": 0.9, "unsellable": 0.12},
	 "duration": 12, "important": true},
	
	# 1986: The Great Price War Crash
	{"year": 1986, "month": 1, "title": "OELPREIS-KRIEG! SAUDI-ARABIEN FLUTET MARKT",
	 "text": "Saudi-Arabien gibt Swing-Producer-Rolle auf! Um Marktanteile zurueckzugewinnen, verachtfachen sie Foerderung. Preise stuerzen von $30 auf unter $10. KLEINE PRODUZENTEN PLEITE!",
	 "category": Category.MARKET_CRASH, "crisis_level": CrisisLevel.SEVERE,
	 "effect": {"oil_price_mult": 0.33, "demand": 0.85, "unsellable": 0.25, "bankruptcy_wave": true},
	 "duration": 18, "important": true},
	
	{"year": 1986, "month": 6, "title": "SOWJETUNION AM ABGRUND",
	 "text": "Oelpreissturz trifft UdSSR hart. Waehrungsreserven schmelzen. Sowjetische Oelexporte brechen ein. Westliche Oelfirmen melden Insolvenzen.",
	 "category": Category.ECONOMY, "crisis_level": CrisisLevel.MODERATE,
	 "effect": {"oil_price_mult": 0.9, "unsellable": 0.15},
	 "duration": 6},
	
	# 1991-1994: Post-Gulf War Slump
	{"year": 1991, "month": 3, "title": "GOLFKRIEG-ANGST LEGT SICH",
	 "text": "Kuwait-Ölfelder nicht so zerstoert wie befuerchtet. Produktion kehrt schneller zurueck. Ueberangebot bei schwacher Konjunktur.",
	 "category": Category.MARKET_CRASH, "crisis_level": CrisisLevel.MILD,
	 "effect": {"oil_price_mult": 0.75, "demand": 0.95, "unsellable": 0.1},
	 "duration": 36, "important": true},
	
	{"year": 1993, "month": 2, "title": "BENZIN SO BILLIG WIE SEIT JAHREN",
	 "text": "Oelpreis faellt auf $13-14. Tankstellen preisen 'Super-Billig-Benzin' an. Fuer Autofahrer ein Segen - fuer Oelfirmen ein Albtraum.",
	 "category": Category.MARKET_CRASH, "crisis_level": CrisisLevel.MODERATE,
	 "effect": {"oil_price_mult": 0.6, "unsellable": 0.18},
	 "duration": 12, "important": true},
	
	# 1997-1998: Asian Financial Crisis
	{"year": 1997, "month": 7, "title": "ASIEN-KRISE! TIGERSTAATEN BRECHEN EIN",
	 "text": "Waehrungskrise in Asien. Tigerstaaten stuerzen in Rezession. Oel-Nachfrage bricht ein - genau als OPEC Foerderquoten erhoeht hat.",
	 "category": Category.MARKET_CRASH, "crisis_level": CrisisLevel.SEVERE,
	 "effect": {"oil_price_mult": 0.5, "demand": 0.75, "unsellable": 0.3},
	 "duration": 18, "important": true},
	
	{"year": 1998, "month": 3, "title": "OEL SO BILLIG SEIT 1960ERN",
	 "text": "Preis faellt auf unter $10 inflationsbereinigt. Lager weltweit ueberfuellt. OPEC verzweifelt an Produktionskuerzungen.",
	 "category": Category.MARKET_CRASH, "crisis_level": CrisisLevel.SEVERE,
	 "effect": {"oil_price_mult": 0.4, "unsellable": 0.35},
	 "duration": 12, "important": true},
	
	# 2001: Post-9/11 Crash
	{"year": 2001, "month": 9, "title": "NACH 9/11: LUFTFAHRT GROUNDERT",
	 "text": "Nach Terroranschlaegen liegt weltweiter Flugverkehr still. Angst vor globaler Depression. Oel-preis stuerzt von $28 auf $18.",
	 "category": Category.MARKET_CRASH, "crisis_level": CrisisLevel.MODERATE,
	 "effect": {"oil_price_mult": 0.65, "demand": 0.85, "unsellable": 0.2, "aviation_stop": true},
	 "duration": 6, "important": true},
	
	# 2008: Financial Crisis
	{"year": 2008, "month": 7, "title": "OELPREIS ALLZEITHOCH: $147!",
	 "text": "Spekulation treibt Preis auf Rekordniveau. Analysten prophezeien $200. Doch das Unheil naht...",
	 "category": Category.MARKET_NEWS, "effect": {"oil_price_mult": 2.5},
	 "important": true},
	
	{"year": 2008, "month": 9, "title": "LEHMAN BROTHERS PLEITE! WELTFINANZKRISIS",
	 "text": "US-Investmentbank bricht zusammen. Globale Finanzkrise beginnt. Oelpreis stuerzt von $147 auf $33 in wenigen Monaten. SCHNELLSTER ABSTURZ DER GESCHICHTE!",
	 "category": Category.MARKET_CRASH, "crisis_level": CrisisLevel.CATASTROPHIC,
	 "effect": {"oil_price_mult": 0.22, "demand": 0.7, "unsellable": 0.4, "credit_crunch": true},
	 "duration": 18, "important": true},
	
	{"year": 2009, "month": 2, "title": "KEINE KAEUFER FUER OEL",
	 "text": "Weltweite Rezession. Fabriken stillgelegt. Keiner braucht Oel. Tanklager berlaufen. Händler zahlen Geld, um Oel loszuwerden.",
	 "category": Category.MARKET_CRASH, "crisis_level": CrisisLevel.CATASTROPHIC,
	 "effect": {"oil_price_mult": 0.3, "unsellable": 0.45},
	 "duration": 8, "important": true},
	
	# 2012: Euro Crisis
	{"year": 2012, "month": 5, "title": "EURO-SCHULDENKRISE GRIFFT AUF OEL UEBER",
	 "text": "Griechenland, Spanien, Italien am Abgrund. Angst vor Zerfall der Eurozone. Oelpreis faellt von $125 auf unter $90.",
	 "category": Category.MARKET_CRASH, "crisis_level": CrisisLevel.MODERATE,
	 "effect": {"oil_price_mult": 0.7, "demand": 0.9, "unsellable": 0.15, "euro_instability": true},
	 "duration": 8, "important": true},
	
	# 2014-2016: Shale Oil Glut
	{"year": 2014, "month": 6, "title": "FRACKING-BOOM: USA WIRD TOP-PRODUZENT",
	 "text": "Amerikanisches Schieferoel flutet Markt. USA verdraengen Saudi-Arabien als groessten Produzenten. OPEC mit harter Entscheidung.",
	 "category": Category.MARKET_NEWS, "effect": {"oil_price_mult": 0.85},
	 "important": true},
	
	{"year": 2014, "month": 11, "title": "OPEC LEHNT KUERZUNGEN AB - PREISSTURZ!",
	 "text": "OPEC beschliesst: KEINE Produktionskuerzung! Ziel: US-Fracking unrentabel machen. 'Marktbereinigung' durch Billig-Oel. Preis faellt von $100 auf $50.",
	 "category": Category.MARKET_CRASH, "crisis_level": CrisisLevel.SEVERE,
	 "effect": {"oil_price_mult": 0.45, "demand": 0.9, "unsellable": 0.3, "fracking_war": true},
	 "duration": 24, "important": true},
	
	{"year": 2016, "month": 1, "title": "OELPREIS TIEFPUNKT: $27 PRO FASS",
	 "text": "Drei Jahre Preisverfall gipfeln in historischem Tief. US-Fracker gehen pleite. OPEC-Länder bluten. Iran kehrt auf Markt zurueck.",
	 "category": Category.MARKET_CRASH, "crisis_level": CrisisLevel.SEVERE,
	 "effect": {"oil_price_mult": 0.25, "unsellable": 0.35},
	 "duration": 6, "important": true},
	
	# 2018: Christmas Crash
	{"year": 2018, "month": 10, "title": "WEIHNACHTS-STURZ: $86 AUF $50",
	 "text": "Handelskrieg USA-China. Ueberraschende Iran-Sanktions-Ausnahmen von Trump. Markt 'ueberversorgt'. Preis stuerzt 40% in 3 Monaten.",
	 "category": Category.MARKET_CRASH, "crisis_level": CrisisLevel.MODERATE,
	 "effect": {"oil_price_mult": 0.58, "unsellable": 0.2, "trade_war": true},
	 "duration": 4, "important": true},
	
	# 2020: COVID-19 Pandemic
	{"year": 2020, "month": 3, "title": "CORONA-PANDEMIE: WELT STEHT STILL",
	 "text": "Globale Lockdowns. Flugverkehr gestoppt. Autos bleiben in Garagen. Oel-Nachfrage bricht um 30% ein. Saudi-Russland Preiskrieg verschlimmert Lage.",
	 "category": Category.MARKET_CRASH, "crisis_level": CrisisLevel.CATASTROPHIC,
	 "effect": {"oil_price_mult": 0.15, "demand": 0.5, "unsellable": 0.5, "global_lockdown": true},
	 "duration": 6, "important": true},
	
	{"year": 2020, "month": 4, "title": "HISTORISCH: NEGATIVER OELPREIS!",
	 "text": "WTI-Preis faellt auf -$37! Händler ZAHLEN Geld, um Oel loszuwerden. Lager weltweit voll. Noch NIE in der Geschichte passiert!",
	 "category": Category.MARKET_CRASH, "crisis_level": CrisisLevel.CATASTROPHIC,
	 "effect": {"oil_price_mult": -0.37, "demand": 0.4, "unsellable": 0.6, "negative_price": true},
	 "duration": 2, "important": true},
]

# Historical positive oil events (price spikes)
const HISTORICAL_OIL_EVENTS = [
	# 1970s Oil Shocks
	{"year": 1973, "month": 10, "title": "OELKRISE! OPEC-EMBARGO GEGEN WESTEN",
	 "text": "Arabische Oelproduzenten verkuenden Embargo gegen USA und Westeuropa. Preise vervierfachen sich ueber Nacht! Benzinschlange kilometerlang.",
	 "category": Category.OIL_CRISIS, "effect": {"oil_price_mult": 4.0, "inflation": 1.1, "supply_crisis": true},
	 "important": true},
	
	{"year": 1979, "month": 11, "title": "GEISELN IN TEHERAN - ZWEITE OELKRISE",
	 "text": "Amerikanische Geiseln im Iran. Iranische Oelexporte gestoppt. Globaler Panikkauf beginnt. Preise verdoppeln sich.",
	 "category": Category.OIL_CRISIS, "effect": {"oil_price_mult": 2.0, "volatility": 0.15, "supply_crisis": true},
	 "important": true},
	
	{"year": 1980, "month": 9, "title": "IRAN-IRAK-KRIEG BEGINNT",
	 "text": "Krieg zwischen zwei grossen Oelproduzenten bedroht Golf-Exporte. Preise erreichen Rekordhoehen.",
	 "category": Category.OIL_CRISIS, "effect": {"oil_price_mult": 1.5, "region_blocked": "Saudi-Arabien"},
	 "important": true},
	
	# 1990 Gulf War
	{"year": 1990, "month": 8, "title": "IRAK INVADELT KUWAIT!",
	 "text": "Saddam Husseins Truppen besetzen Kuwait. Oelpreise verdoppeln sich. US-Truppen nach Saudi-Arabien.",
	 "category": Category.OIL_CRISIS, "effect": {"oil_price_mult": 2.0, "region_blocked": "Saudi-Arabien"},
	 "important": true},
	
	# Recovery events
	{"year": 1999, "month": 4, "title": "OPEC EINIG: PRODUKTIONS-KUERZUNG",
	 "text": "OPEC beschliesst Produktionskuerzung um 1,7 Mio. Fass/Tag. Preise erholen sich nach Jahren des Niedergangs.",
	 "category": Category.OPEC_NEWS, "effect": {"oil_price_mult": 1.5, "demand": 1.1},
	 "important": true},
	
	{"year": 2000, "month": 9, "title": "OELPREIS ERHOLT SICH",
	 "text": "Nach Jahren der Krise erreicht Preis wieder $30. Asien erholt sich. Nachfrage steigt.",
	 "category": Category.MARKET_NEWS, "effect": {"oil_price_mult": 1.3, "demand": 1.15}},
]

# World events with mixed effects
const WORLD_EVENTS = [
	# 1970s
	{"year": 1970, "month": 4, "title": "EARTH DAY: UMWELTBEWEGUNG STARTET",
	 "text": "Millionen protestieren fuer Umwelt. Oelindustrie unter Beobachtung. Neue Regulierungen drohen.",
	 "category": Category.WORLD_POLITICS, "effect": {"regulations": 1.1, "reputation_all": -5}},
	
	{"year": 1972, "month": 9, "title": "MUNICHEN: OLYMPIA-ATTENTAT",
	 "text": "Palaestinensische Terrornehmer nehmen israelische Athleten als Geiseln. Tragisches Ende live im TV.",
	 "category": Category.DISASTERS, "effect": {"security_costs": 1.1}, "important": true},
	
	{"year": 1974, "month": 8, "title": "NIXON TRITT ZURUECK - WATERGATE",
	 "text": "Praesident Nixon tritt zurueck. Erster US-Praesident-Ruecktritt. Politische Instabilitaet.",
	 "category": Category.WORLD_POLITICS, "effect": {"inflation": 1.03}, "important": true},
	
	{"year": 1976, "month": 7, "title": "VIKING 1 AUF DEM MARS",
	 "text": "Erste erfolgreiche Marslandung. Technischer Durchbruch fuer Raumfahrt.",
	 "category": Category.SPACE, "effect": {"tech_discount": 0.03}},
	
	{"year": 1979, "month": 3, "title": "THREE MILE ISLAND: REAKTORUNFALL",
	 "text": "Nuklearunfall in Pennsylvania. Oelaktien steigen - Angst vor Atomkraft.",
	 "category": Category.DISASTERS, "effect": {"oil_price_mult": 1.15, "nuclear_fear": true}},
	
	# 1980s
	{"year": 1981, "month": 8, "title": "IBM PC VEROEFFENTLICHT",
	 "text": "IBM stellt ersten Personal Computer vor. Beginn der PC-Revolution. Digitales Zeitalter beginnt.",
	 "category": Category.TECHNOLOGY, "effect": {"tech_discount": 0.05}, "important": true},
	
	{"year": 1984, "month": 1, "title": "APPLE MACINTOSH: '1984'",
	 "text": "Erster Computer mit grafischer Oberflaeche und Maus. Revolutioniert Büroarbeit.",
	 "category": Category.TECHNOLOGY, "effect": {"tech_discount": 0.04}, "important": true},
	
	{"year": 1986, "month": 4, "title": "TSCHERNOBYL: SUPER-GAU",
	 "text": "Reaktorunfall in Tschernobyl. Radioaktive Wolke ueber Europa. Schlimmster Nuklearunfall der Geschichte.",
	 "category": Category.DISASTERS, "effect": {"oil_price_mult": 1.1, "safety_costs": 1.15, "nuclear_fear": true}, "important": true},
	
	{"year": 1987, "month": 10, "title": "SCHWARZER MONTAG: BOERSENCrash",
	 "text": "Dow Jones faellt um 22% an einem Tag. Groesster Börsensturz seit 1929.",
	 "category": Category.ECONOMY, "effect": {"oil_price_mult": 0.85, "demand": 0.95}, "important": true},
	
	{"year": 1989, "month": 11, "title": "BERLINER MAUER FAELLT!",
	 "text": "Grenzuebergaenge geoeffnet. DDR-Buerger stroemen in den Westen. Geschichte wird geschrieben!",
	 "category": Category.WORLD_POLITICS, "effect": {"inflation": 0.98, "demand": 1.05, "new_markets": true}, "important": true},
	
	# 1990s
	{"year": 1990, "month": 10, "title": "DEUTSCHE WIEDERVEREINIGUNG",
	 "text": "DDR tritt der BRD bei. Deutschland nach 45 Jahren wieder vereint.",
	 "category": Category.WORLD_POLITICS, "effect": {"demand": 1.05, "inflation": 0.99}, "important": true},
	
	{"year": 1991, "month": 12, "title": "SOWJETUNION AUFGELOEST",
	 "text": "Gorbatschow tritt zurueck. Sowjetunion zerteilt in 15 Republiken. Kalter Krieg beendet.",
	 "category": Category.WORLD_POLITICS, "effect": {"inflation": 0.98, "new_markets": true}, "important": true},
	
	{"year": 1995, "month": 8, "title": "WINDOWS 95: START-KNOPF AERA",
	 "text": "Microsoft startet Windows 95. 'Start Me Up' von Rolling Stones als Werbesong.",
	 "category": Category.TECHNOLOGY, "effect": {"tech_discount": 0.05}, "important": true},
	
	{"year": 1997, "month": 8, "title": "PRINZESSIN DIANA STIRBT",
	 "text": "Lady Di bei Autounfall in Paris tot. Weltweite Trauerwelle.",
	 "category": Category.CULTURE, "effect": {}, "important": true},
	
	{"year": 1998, "month": 9, "title": "GOOGLE GEGRUENDET",
	 "text": "Larry Page und Sergey Brin gruenden Suchmaschine. Beginn einer neuen Aera.",
	 "category": Category.TECHNOLOGY, "effect": {"tech_discount": 0.03}, "important": true},
	
	{"year": 1999, "month": 1, "title": "EURO EINGEFUEHRT",
	 "text": "Europaeische Waehrung offiziell eingefuehrt. 11 Laender beteiligt.",
	 "category": Category.ECONOMY, "effect": {"inflation": 0.99}},
]

# Random world events
const RANDOM_WORLD_EVENTS = [
	{"title": "HURRIKAN BEDROHT GOLFPLATTFORMEN", "text": "Sturm erzwingt Evakuierung. Produktion gestoppt.", "category": Category.DISASTERS, "effect": {"production": 0.7, "oil_price_mult": 1.05}},
	{"title": "NEUE OELFELDENTDECKUNG IN DER NORDSEE", "text": "Massive Reserven entdeckt.", "category": Category.OIL_DISCOVERY, "effect": {"oil_price_mult": 0.95}},
	{"title": "GEWERKSCHAFT STREIKT IN HAFEN", "text": "Hafenarbeiter legen Arbeit nieder. Exporte verzoegert.", "category": Category.ECONOMY, "effect": {"transport": 1.15}},
	{"title": "UMWELTGRUPPEN PROTESTIEREN", "text": "Greenpeace bei Oelterminal. Negative Schlagzeilen.", "category": Category.DISASTERS, "effect": {"reputation_all": -5}},
	{"title": "TECHNOLOGIE-DURCHBRUCH BEIM BOHREN", "text": "Neue Technik verspricht tiefere Bohrungen.", "category": Category.TECHNOLOGY, "effect": {"drill_cost": 0.9}},
	{"title": "NEUE UMWELTVORSCHRIFTEN", "text": "Regierung verschaeft Gesetze.", "category": Category.WORLD_POLITICS, "effect": {"safety_costs": 1.08}},
	{"title": "AUTO-MESSE: NEUE BENZINFRESSER", "text": "SUV-Boom koennte Nachfrage steigern.", "category": Category.ECONOMY, "effect": {"demand": 1.02}},
	{"title": "ERDKUNDUNGSSATELLIT GESTARTET", "text": "Neuer Satellit verbessert geologische Daten.", "category": Category.SPACE, "effect": {"survey_accuracy": 0.05}},
	{"title": "PIPELINE-LECK ENTDECKT", "text": "Leck in Hauptleitung. Lieferungen unterbrochen.", "category": Category.DISASTERS, "effect": {"transport": 1.2, "oil_price_mult": 1.03}},
	{"title": "REFINERY FIRE IN TEXAS", "text": "Raffinerie-Brand in Houston. Kapazitaet reduziert.", "category": Category.DISASTERS, "effect": {"refining_capacity": 0.85, "oil_price_mult": 1.08}},
	# Negative demand events
	{"title": "MILDER WINTER IN EUROPA", "text": "Heizoel-Nachfrage sinkt deutlich.", "category": Category.ECONOMY, "effect": {"demand": 0.95}},
	{"title": "ELEKTROAUTO-BOOM BEDROHT OEL", "text": "Mehr Elektroautos auf Strassen. Benzinverbrauch sinkt.", "category": Category.TECHNOLOGY, "effect": {"demand": 0.97, "oil_price_mult": 0.98}},
	{"title": "REZESSION IN JAPAN", "text": "Japanische Wirtschaft schrumpft. Importe sinken.", "category": Category.ECONOMY, "effect": {"demand": 0.96}},
	{"title": "LAGER WELTWEIT GEFUELLT", "text": "Ueberangebot. Lager fast voll.", "category": Category.MARKET_NEWS, "effect": {"unsellable": 0.05, "oil_price_mult": 0.97}},
]

# Company news templates
const COMPANY_FAILURE_TEMPLATES = [
	{"title": "TROCKENES BOHRLOCH KATASTROPHE FUER %s", "text": "%s verschwendet Millionen an unproduktivem Brunnen. Investoren besorgt."},
	{"title": "%s OELPEST-UNTERSUCHUNG", "text": "Umweltbehoerden untersuchen %s wegen Verschmutzung. Geldstrafen drohen."},
	{"title": "%s MIT SICHERHEITSVERSTOESSEN", "text": "Behoerden zitieren %s. Anlagen muessen nachgeruestet werden."},
	{"title": "INVESTOREN VERKLAGEN %s", "text": "Aktionaere werfen %s Fehlmanagement vor. Aktienkurs stuerzt."},
	{"title": "%s MUSS RIGS ABSTELLEN", "text": "Bei niedrigen Preisen schreibt %s Verluste. Foerderung wird gedrosselt."},
]

const COMPANY_SUCCESS_TEMPLATES = [
	{"title": "GROSSER OELFUND FUER %s!", "text": "%s kuendet Entdeckung massiver Reserven an. Aktienkurs steigt!"},
	{"title": "%s UNTERSCHREIBT MEGA-VERTRAG", "text": "%s sichert Milliardendeal mit grossem Abnehmer."},
	{"title": "%s SCHLAEGT ERWARTUNGEN", "text": "Analysten ueberrascht: %s meldet bessere Gewinne als erwartet."},
]

func _ready():
	await get_tree().create_timer(0.5).timeout
	if has_node("/root/GameManager"):
		game_manager = get_node("/root/GameManager")

# ==============================================================================
# CRISIS MANAGEMENT
# ==============================================================================

func get_crisis_level() -> int:
	return current_crisis_level

func get_unsellable_percent() -> float:
	return unsellable_oil_percent

func is_in_crisis() -> bool:
	return current_crisis_level > CrisisLevel.NONE

func can_sell_oil(amount: float) -> float:
	# Returns how much of the requested amount can actually be sold
	if unsellable_oil_percent <= 0:
		return amount
	var sellable_percent = 1.0 - unsellable_oil_percent
	return amount * sellable_percent

func process_crisis_duration():
	# Called monthly to reduce crisis effects over time
	if crisis_duration_months > 0:
		crisis_duration_months -= 1
		if crisis_duration_months <= 0:
			_end_crisis()

func _end_crisis():
	current_crisis_level = CrisisLevel.NONE
	unsellable_oil_percent = 0.0
	# Emit recovery signal
	if game_manager:
		game_manager.set_meta("crisis_active", false)

# ==============================================================================
# MONTHLY NEWS GENERATION
# ==============================================================================

func check_monthly_events():
	if game_manager == null:
		return []
	
	current_headlines.clear()
	has_important_news = false
	var year = game_manager.date["year"]
	var month = game_manager.date["month"]
	
	# Process ongoing crisis duration
	process_crisis_duration()
	
	# 1. Check oil crises (most important - can override other effects)
	for event in HISTORICAL_OIL_CRISES:
		var event_key = "crisis_%d_%d" % [event["year"], event["month"]]
		if not triggered_events.has(event_key):
			if year == event["year"] and month == event["month"]:
				triggered_events[event_key] = true
				var headline = _create_headline_from_event(event)
				current_headlines.append(headline)
				if event.get("important", false):
					has_important_news = true
					pending_news.append(headline)
				_apply_crisis_effect(event)
	
	# 2. Check historical oil events
	for event in HISTORICAL_OIL_EVENTS:
		var event_key = "oil_%d_%d" % [event["year"], event["month"]]
		if not triggered_events.has(event_key):
			if year == event["year"] and month == event["month"]:
				triggered_events[event_key] = true
				var headline = _create_headline_from_event(event)
				current_headlines.append(headline)
				if event.get("important", false):
					has_important_news = true
				_apply_event_effect(event.get("effect", {}))
	
	# 3. Check world events
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
	
	# 4. Generate random world event (20% chance)
	if randf() < 0.20:
		var event = RANDOM_WORLD_EVENTS.pick_random()
		var headline = _create_headline_from_event(event)
		current_headlines.append(headline)
		_apply_event_effect(event.get("effect", {}))
	
	# 5. Generate company-specific news
	current_headlines.append_array(_generate_company_news())
	
	# 6. Store headlines with date
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
		"important": event.get("important", false),
		"crisis_level": event.get("crisis_level", CrisisLevel.NONE)
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
		Category.DISASTERS: return "Katastrophe"
		Category.ECONOMY: return "Wirtschaft"
		Category.SPACE: return "Weltraum"
		Category.MARKET_CRASH: return "MARKTCRASH"
		_: return "Allgemein"

# ==============================================================================
# CRISIS EFFECT APPLICATION
# ==============================================================================

func _apply_crisis_effect(event: Dictionary):
	if game_manager == null:
		return
	
	var effect = event.get("effect", {})
	var crisis_level = event.get("crisis_level", CrisisLevel.NONE)
	var duration = event.get("duration", 6)
	
	# Set crisis state
	current_crisis_level = crisis_level
	crisis_duration_months = duration
	game_manager.set_meta("crisis_active", true)
	
	# Apply price effect
	if effect.has("oil_price_mult"):
		var mult = effect["oil_price_mult"]
		# Handle negative prices (2020 event)
		if mult < 0:
			# Negative price - you have to PAY to get rid of oil!
			game_manager.price_multiplier = 0.01  # Almost zero
			unsellable_oil_percent = 0.7  # 70% unsellable
		else:
			game_manager.price_multiplier *= mult
	
	# Apply demand effect
	if effect.has("demand"):
		game_manager.set_meta("demand_modifier", effect["demand"])
	
	# Apply unsellable oil percentage
	if effect.has("unsellable"):
		unsellable_oil_percent = max(unsellable_oil_percent, effect["unsellable"])
	
	# Emit market crash signal for severe events
	if crisis_level >= CrisisLevel.SEVERE:
		market_crash.emit(mult if effect.has("oil_price_mult") else 0.5)
	
	# Apply additional effects
	_apply_event_effect(effect)

func _apply_event_effect(effect: Dictionary):
	if game_manager == null:
		return
	
	# Oil price multiplier
	if effect.has("oil_price_mult"):
		var mult = effect["oil_price_mult"]
		if mult > 0:
			game_manager.price_multiplier *= mult
	
	# Inflation
	if effect.has("inflation"):
		game_manager.inflation_rate *= effect["inflation"]
	
	# Region blocked
	if effect.has("region_blocked"):
		if game_manager.regions.has(effect["region_blocked"]):
			game_manager.regions[effect["region_blocked"]]["block_timer"] = 6
	
	# Tech discount
	if effect.has("tech_discount"):
		var current = game_manager.get_meta("temp_tech_discount", 0.0)
		game_manager.set_meta("temp_tech_discount", current + effect["tech_discount"])
	
	# Demand modifier
	if effect.has("demand"):
		var current = game_manager.get_meta("demand_modifier", 1.0)
		game_manager.set_meta("demand_modifier", current * effect["demand"])
	
	# Safety costs
	if effect.has("safety_costs"):
		var current = game_manager.get_meta("safety_cost_mult", 1.0)
		game_manager.set_meta("safety_cost_mult", current * effect["safety_costs"])
	
	# Unsellable oil (can be from non-crisis events too)
	if effect.has("unsellable"):
		unsellable_oil_percent = max(unsellable_oil_percent, effect["unsellable"])
	
	# Production modifier
	if effect.has("production"):
		var current = game_manager.get_meta("production_mult", 1.0)
		game_manager.set_meta("production_mult", current * effect["production"])
	
	# Transport costs
	if effect.has("transport"):
		var current = game_manager.get_meta("transport_mult", 1.0)
		game_manager.set_meta("transport_mult", current * effect["transport"])

# ==============================================================================
# COMPANY NEWS GENERATION
# ==============================================================================

func _generate_company_news() -> Array:
	var news = []
	if game_manager == null:
		return news
	
	var company = game_manager.company_name
	if company == "":
		company = "Ihre Firma"
	
	# Crisis-specific company news
	if current_crisis_level >= CrisisLevel.SEVERE:
		if randf() < 0.5:
			var template = COMPANY_FAILURE_TEMPLATES[4]  # "MUSS RIGS ABSTELLEN"
			news.append({
				"title": template["title"] % company,
				"text": template["text"] % company,
				"category": Category.COMPANY_NEWS,
				"important": false
			})
	
	# Success news based on performance
	if game_manager.cash > 10000000 and randf() < 0.3:
		var template = COMPANY_SUCCESS_TEMPLATES[0]
		news.append({
			"title": template["title"] % company,
			"text": template["text"] % company,
			"category": Category.COMPANY_NEWS,
			"important": false
		})
	
	# Failure news if things are going badly
	if game_manager.cash < 500000 and game_manager.cash > 0:
		var template = COMPANY_FAILURE_TEMPLATES.pick_random()
		news.append({
			"title": template["title"] % company,
			"text": template["text"] % company,
			"category": Category.COMPANY_NEWS,
			"important": false
		})
	
	return news

# ==============================================================================
# AUTO-SHOW AND GETTERS
# ==============================================================================

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

func get_current_headlines() -> Array:
	return current_headlines

func get_history_headlines(count: int = 20) -> Array:
	var start = max(0, newspaper_history.size() - count)
	return newspaper_history.slice(start)

# ==============================================================================
# MEDIA TYPE DETECTION
# ==============================================================================

func get_current_media_type() -> int:
	if game_manager == null:
		return MediaType.NEWSPAPER_1970S
	
	var year = game_manager.date["year"]
	var era = game_manager.current_era
	
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

# ==============================================================================
# NEWS DISPLAY CREATION
# ==============================================================================

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

# ==============================================================================
# 1970s NEWSPAPER LAYOUT
# ==============================================================================

func _create_newspaper_1970s() -> Control:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(700, 900)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.95, 0.92, 0.85)
	style.border_color = Color(0.3, 0.25, 0.2)
	style.set_border_width_all(4)
	style.set_corner_radius_all(2)
	panel.add_theme_stylebox_override("panel", style)
	
	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 8)
	panel.add_child(main_vbox)
	
	# Crisis warning banner if in crisis
	if current_crisis_level >= CrisisLevel.SEVERE:
		var crisis_banner = _create_crisis_banner()
		main_vbox.add_child(crisis_banner)
	
	# Masthead
	var masthead = Label.new()
	masthead.text = "═══════ THE DAILY BARREL ═══════"
	masthead.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	masthead.add_theme_font_size_override("font_size", 32)
	masthead.add_theme_color_override("font_color", Color(0.15, 0.1, 0.05))
	main_vbox.add_child(masthead)
	
	# Date line with crisis indicator
	var date_line = Label.new()
	if game_manager:
		var crisis_text = ""
		if current_crisis_level >= CrisisLevel.MODERATE:
			crisis_text = " | !!! MARKTKRISE !!!"
		date_line.text = "Vol. %d | %s %d | Oel: $%.2f%s" % [
			game_manager.date["year"] - 1969,
			_get_month_name(game_manager.date["month"]),
			game_manager.date["year"],
			game_manager.oil_price,
			crisis_text
		]
	date_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	date_line.add_theme_font_size_override("font_size", 11)
	date_line.add_theme_color_override("font_color", Color(0.3, 0.25, 0.2))
	main_vbox.add_child(date_line)
	
	# Separator
	var sep1 = HSeparator.new()
	sep1.add_theme_stylebox_override("separator", _create_black_line())
	main_vbox.add_child(sep1)
	
	# Important headlines
	var important_headlines = current_headlines.filter(func(h): return h.get("important", false))
	if important_headlines.size() > 0:
		for headline in important_headlines:
			var banner = _create_headline_banner(headline)
			main_vbox.add_child(banner)
			var sep = HSeparator.new()
			sep.add_theme_stylebox_override("separator", _create_black_line())
			main_vbox.add_child(sep)
	
	# Scrollable content
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size.y = 500
	main_vbox.add_child(scroll)
	
	var content_vbox = VBoxContainer.new()
	content_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_vbox.add_theme_constant_override("separation", 10)
	scroll.add_child(content_vbox)
	
	# Regular headlines
	var regular_headlines = current_headlines.filter(func(h): return not h.get("important", false))
	for headline in regular_headlines:
		var item = _create_headline_item_newspaper(headline)
		content_vbox.add_child(item)
	
	return panel

func _create_crisis_banner() -> Control:
	var banner = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.6, 0.1, 0.1)
	banner.add_theme_stylebox_override("panel", style)
	
	var label = Label.new()
	match current_crisis_level:
		CrisisLevel.SEVERE:
			label.text = "!!! SCHWERE MARKTKRISE - ÖL KAUM VERKÄUFLICH !!!"
		CrisisLevel.CATASTROPHIC:
			label.text = "!!! MARKTZUSAMMENBRUCH - NEGATIVE PREISE !!!"
		_:
			label.text = "!!! MARKTTURBULENZEN !!!"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color.WHITE)
	banner.add_child(label)
	
	return banner

func _create_headline_banner(headline: Dictionary) -> Control:
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	
	# Crisis indicator for crash headlines
	if headline.get("crisis_level", CrisisLevel.NONE) >= CrisisLevel.SEVERE:
		var crisis_label = Label.new()
		crisis_label.text = "【 MARKTCRASH 】"
		crisis_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		crisis_label.add_theme_font_size_override("font_size", 14)
		crisis_label.add_theme_color_override("font_color", Color(0.7, 0.1, 0.1))
		vbox.add_child(crisis_label)
	
	var cat_label = Label.new()
	cat_label.text = "[ " + _category_to_string(headline["category"]).to_upper() + " ]"
	cat_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cat_label.add_theme_font_size_override("font_size", 12)
	cat_label.add_theme_color_override("font_color", Color(0.6, 0.1, 0.1))
	vbox.add_child(cat_label)
	
	var title = Label.new()
	title.text = headline["title"]
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0.1, 0.05, 0.0))
	vbox.add_child(title)
	
	var text = Label.new()
	text.text = headline["text"]
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.autowrap_mode = TextServer.AUTOWRAP_WORD
	text.add_theme_font_size_override("font_size", 13)
	text.add_theme_color_override("font_color", Color(0.2, 0.15, 0.1))
	vbox.add_child(text)
	
	return vbox

func _create_headline_item_newspaper(headline: Dictionary) -> Control:
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 3)
	
	var title = Label.new()
	title.text = headline["title"]
	title.autowrap_mode = TextServer.AUTOWRAP_WORD
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", _get_category_color(headline["category"]))
	vbox.add_child(title)
	
	var text = Label.new()
	text.text = headline["text"]
	text.autowrap_mode = TextServer.AUTOWRAP_WORD
	text.add_theme_font_size_override("font_size", 11)
	text.add_theme_color_override("font_color", Color(0.25, 0.2, 0.15))
	vbox.add_child(text)
	
	var sep = HSeparator.new()
	sep.add_theme_stylebox_override("separator", _create_thin_line())
	vbox.add_child(sep)
	
	return vbox

# ==============================================================================
# 1980s NEWSPAPER LAYOUT
# ==============================================================================

func _create_newspaper_1980s() -> Control:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(750, 950)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.98, 0.96, 0.92)
	style.border_color = Color(0.2, 0.2, 0.3)
	style.set_border_width_all(3)
	panel.add_theme_stylebox_override("panel", style)
	
	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 10)
	panel.add_child(main_vbox)
	
	# Crisis warning
	if current_crisis_level >= CrisisLevel.SEVERE:
		var crisis_banner = _create_80s_crisis_banner()
		main_vbox.add_child(crisis_banner)
	
	# Masthead
	var masthead_bg = PanelContainer.new()
	var masthead_style = StyleBoxFlat.new()
	masthead_style.bg_color = Color(0.1, 0.15, 0.35)
	masthead_bg.add_theme_stylebox_override("panel", masthead_style)
	main_vbox.add_child(masthead_bg)
	
	var masthead = Label.new()
	masthead.text = "★ THE DAILY BARREL ★"
	masthead.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	masthead.add_theme_font_size_override("font_size", 36)
	masthead.add_theme_color_override("font_color", Color(1, 0.9, 0.2))
	masthead_bg.add_child(masthead)
	
	# Date line
	var date_box = PanelContainer.new()
	var date_style = StyleBoxFlat.new()
	date_style.bg_color = Color(0.8, 0.1, 0.1) if current_crisis_level >= CrisisLevel.MODERATE else Color(0.7, 0.1, 0.1)
	date_box.add_theme_stylebox_override("panel", date_style)
	main_vbox.add_child(date_box)
	
	var date_line = Label.new()
	if game_manager:
		date_line.text = "  %s %d | OEL: $%.2f | KRISE: %d%%  " % [
			_get_month_name(game_manager.date["month"]),
			game_manager.date["year"],
			game_manager.oil_price,
			int(unsellable_oil_percent * 100)
		]
	date_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	date_line.add_theme_font_size_override("font_size", 13)
	date_line.add_theme_color_override("font_color", Color.WHITE)
	date_box.add_child(date_line)
	
	# Content
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(scroll)
	
	var content_vbox = VBoxContainer.new()
	content_vbox.add_theme_constant_override("separation", 12)
	scroll.add_child(content_vbox)
	
	# Breaking news
	var important_headlines = current_headlines.filter(func(h): return h.get("important", false))
	if important_headlines.size() > 0:
		for headline in important_headlines:
			var breaking_box = _create_80s_breaking_box(headline)
			content_vbox.add_child(breaking_box)
	
	for headline in current_headlines:
		if not headline.get("important", false):
			var item = _create_headline_item_80s(headline)
			content_vbox.add_child(item)
	
	return panel

func _create_80s_crisis_banner() -> Control:
	var banner = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.8, 0.2, 0.1)
	banner.add_theme_stylebox_override("panel", style)
	
	var hbox = HBoxContainer.new()
	banner.add_child(hbox)
	
	var icon = Label.new()
	icon.text = "⚠️"
	icon.add_theme_font_size_override("font_size", 20)
	hbox.add_child(icon)
	
	var label = Label.new()
	label.text = "MARKTKRISE! %d%% IHRES ÖLS IST AKTUELL UNVERKÄUFLICH!" % int(unsellable_oil_percent * 100)
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color.WHITE)
	hbox.add_child(label)
	
	return banner

func _create_80s_breaking_box(headline: Dictionary) -> Control:
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	
	var is_crisis = headline.get("crisis_level", CrisisLevel.NONE) >= CrisisLevel.SEVERE
	
	var banner_bg = PanelContainer.new()
	var banner_style = StyleBoxFlat.new()
	banner_style.bg_color = Color(0.9, 0.2, 0.1) if is_crisis else Color(0.9, 0.2, 0.1)
	banner_bg.add_theme_stylebox_override("panel", banner_style)
	vbox.add_child(banner_bg)
	
	var banner = Label.new()
	banner.text = "⚡ BREAKING: " + _category_to_string(headline["category"]).to_upper() + " ⚡"
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.add_theme_font_size_override("font_size", 16)
	banner.add_theme_color_override("font_color", Color.WHITE)
	banner_bg.add_child(banner)
	
	var content_bg = PanelContainer.new()
	var content_style = StyleBoxFlat.new()
	content_style.bg_color = Color(0.95, 0.95, 0.9)
	content_style.set_border_width_all(2)
	content_style.border_color = Color(0.9, 0.2, 0.1) if is_crisis else Color(0.9, 0.2, 0.1)
	content_bg.add_theme_stylebox_override("panel", content_style)
	vbox.add_child(content_bg)
	
	var content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 5)
	content_bg.add_child(content)
	
	var title = Label.new()
	title.text = headline["title"]
	title.autowrap_mode = TextServer.AUTOWRAP_WORD
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.1, 0.1, 0.2))
	content.add_child(title)
	
	var text = Label.new()
	text.text = headline["text"]
	text.autowrap_mode = TextServer.AUTOWRAP_WORD
	text.add_theme_font_size_override("font_size", 12)
	text.add_theme_color_override("font_color", Color(0.2, 0.2, 0.25))
	content.add_child(text)
	
	return vbox

func _create_headline_item_80s(headline: Dictionary) -> Control:
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	
	var indicator = PanelContainer.new()
	indicator.custom_minimum_size = Vector2(5, 50)
	var ind_style = StyleBoxFlat.new()
	ind_style.bg_color = _get_category_color(headline["category"])
	indicator.add_theme_stylebox_override("panel", ind_style)
	hbox.add_child(indicator)
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 3)
	hbox.add_child(vbox)
	
	var title = Label.new()
	title.text = headline["title"]
	title.autowrap_mode = TextServer.AUTOWRAP_WORD
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(0.1, 0.1, 0.15))
	vbox.add_child(title)
	
	var text = Label.new()
	text.text = headline["text"]
	text.autowrap_mode = TextServer.AUTOWRAP_WORD
	text.add_theme_font_size_override("font_size", 11)
	text.add_theme_color_override("font_color", Color(0.3, 0.3, 0.35))
	vbox.add_child(text)
	
	return hbox

# ==============================================================================
# 1990s TV NEWS LAYOUT
# ==============================================================================

func _create_tv_news() -> Control:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(800, 600)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.1)
	style.border_color = Color(0.3, 0.3, 0.3)
	style.set_border_width_all(8)
	panel.add_theme_stylebox_override("panel", style)
	
	var main_vbox = VBoxContainer.new()
	panel.add_child(main_vbox)
	
	# OilNN Header
	var header_bg = PanelContainer.new()
	var header_style = StyleBoxFlat.new()
	header_style.bg_color = Color(0.8, 0.1, 0.1) if current_crisis_level >= CrisisLevel.MODERATE else Color(0.8, 0.1, 0.1)
	header_bg.add_theme_stylebox_override("panel", header_style)
	main_vbox.add_child(header_bg)
	
	var header_hbox = HBoxContainer.new()
	header_bg.add_child(header_hbox)
	
	var logo = Label.new()
	logo.text = " OilNN "
	logo.add_theme_font_size_override("font_size", 28)
	logo.add_theme_color_override("font_color", Color.WHITE)
	header_hbox.add_child(logo)
	
	if current_crisis_level >= CrisisLevel.SEVERE:
		var breaking = Label.new()
		breaking.text = " ● MARKTCRISE LIVE"
		breaking.add_theme_font_size_override("font_size", 18)
		breaking.add_theme_color_override("font_color", Color.YELLOW)
		header_hbox.add_child(breaking)
	else:
		var live = Label.new()
		live.text = " ● LIVE"
		live.add_theme_font_size_override("font_size", 18)
		live.add_theme_color_override("font_color", Color.RED)
		header_hbox.add_child(live)
	
	# Content area
	var content_area = PanelContainer.new()
	var content_style = StyleBoxFlat.new()
	content_style.bg_color = Color(0.1, 0.1, 0.15)
	content_area.add_theme_stylebox_override("panel", content_style)
	content_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(content_area)
	
	var content_vbox = VBoxContainer.new()
	content_vbox.add_theme_constant_override("separation", 10)
	content_area.add_child(content_vbox)
	
	# Breaking ticker
	var important_headlines = current_headlines.filter(func(h): return h.get("important", false))
	if important_headlines.size() > 0:
		var ticker = _create_tv_ticker(important_headlines[0])
		content_vbox.add_child(ticker)
	
	# News items
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_vbox.add_child(scroll)
	
	var news_list = VBoxContainer.new()
	news_list.add_theme_constant_override("separation", 10)
	scroll.add_child(news_list)
	
	for headline in current_headlines:
		var item = _create_tv_news_item(headline)
		news_list.add_child(item)
	
	# Bottom ticker
	var ticker_bg = PanelContainer.new()
	var ticker_style = StyleBoxFlat.new()
	ticker_style.bg_color = Color(0.1, 0.2, 0.4)
	ticker_bg.add_theme_stylebox_override("panel", ticker_style)
	main_vbox.add_child(ticker_bg)
	
	var ticker_text = Label.new()
	if game_manager:
		ticker_text.text = "OEL: $%.2f | UNVERKÄUFLICH: %d%% | DOW: %d | $" % [
			game_manager.oil_price,
			int(unsellable_oil_percent * 100),
			2000 + randi() % 8000
		]
	ticker_text.add_theme_color_override("font_color", Color.WHITE)
	ticker_text.add_theme_font_size_override("font_size", 12)
	ticker_bg.add_child(ticker_text)
	
	return panel

func _create_tv_ticker(headline: Dictionary) -> Control:
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
	
	var indicator = PanelContainer.new()
	indicator.custom_minimum_size = Vector2(8, 50)
	var ind_style = StyleBoxFlat.new()
	ind_style.bg_color = _get_category_color(headline["category"])
	indicator.add_theme_stylebox_override("panel", ind_style)
	hbox.add_child(indicator)
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 4)
	hbox.add_child(vbox)
	
	var title = Label.new()
	title.text = headline["title"]
	title.autowrap_mode = TextServer.AUTOWRAP_WORD
	title.add_theme_font_size_override("font_size", 15)
	title.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(title)
	
	var text = Label.new()
	text.text = headline["text"]
	text.autowrap_mode = TextServer.AUTOWRAP_WORD
	text.add_theme_font_size_override("font_size", 11)
	text.add_theme_color_override("font_color", Color(0.8, 0.8, 0.85))
	vbox.add_child(text)
	
	return hbox

# ==============================================================================
# 2000s ONLINE PORTAL LAYOUT
# ==============================================================================

func _create_online_portal() -> Control:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(850, 700)
	
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
	
	if current_crisis_level >= CrisisLevel.SEVERE:
		var crisis = Label.new()
		crisis.text = "🔴 MARKTCRISE"
		crisis.add_theme_font_size_override("font_size", 16)
		crisis.add_theme_color_override("font_color", Color.RED)
		header_hbox.add_child(crisis)
	
	# Crisis alert bar
	if current_crisis_level >= CrisisLevel.MODERATE:
		var alert_bar = PanelContainer.new()
		var alert_style = StyleBoxFlat.new()
		alert_style.bg_color = Color(0.9, 0.2, 0.1)
		alert_bar.add_theme_stylebox_override("panel", alert_style)
		main_vbox.add_child(alert_bar)
		
		var alert_text = Label.new()
		alert_text.text = "⚠️ ACHTUNG: %d%% Ihres Öls ist aktuell unverkäuflich! Preise auf Tiefststand!" % int(unsellable_oil_percent * 100)
		alert_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		alert_text.add_theme_color_override("font_color", Color.WHITE)
		alert_bar.add_child(alert_text)
	
	# Content grid
	var grid = GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 15)
	grid.add_theme_constant_override("v_separation", 15)
	main_vbox.add_child(grid)
	
	# Featured story
	if current_headlines.size() > 0:
		var featured = current_headlines[0] if current_headlines[0].get("important", false) else current_headlines.pick_random()
		var featured_box = _create_web_featured(featured)
		featured_box.custom_minimum_size = Vector2(500, 250)
		grid.add_child(featured_box)
		
		var trending = _create_trending_sidebar()
		trending.custom_minimum_size = Vector2(200, 250)
		grid.add_child(trending)
	
	for i in range(min(current_headlines.size() - 1, 6)):
		var card = _create_news_card(current_headlines[i + 1])
		card.custom_minimum_size = Vector2(250, 150)
		grid.add_child(card)
	
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
	
	var badge = Label.new()
	badge.text = " " + _category_to_string(headline["category"]).to_upper() + " "
	badge.add_theme_font_size_override("font_size", 11)
	badge.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(badge)
	
	var title = Label.new()
	title.text = headline["title"]
	title.autowrap_mode = TextServer.AUTOWRAP_WORD
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(0.1, 0.1, 0.15))
	vbox.add_child(title)
	
	var text = Label.new()
	text.text = headline["text"]
	text.autowrap_mode = TextServer.AUTOWRAP_WORD
	text.add_theme_font_size_override("font_size", 12)
	text.add_theme_color_override("font_color", Color(0.3, 0.3, 0.4))
	vbox.add_child(text)
	
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
	
	var bar = PanelContainer.new()
	bar.custom_minimum_size.y = 4
	var bar_style = StyleBoxFlat.new()
	bar_style.bg_color = _get_category_color(headline["category"])
	bar.add_theme_stylebox_override("panel", bar_style)
	vbox.add_child(bar)
	
	var title = Label.new()
	title.text = headline["title"]
	title.autowrap_mode = TextServer.AUTOWRAP_WORD
	title.add_theme_font_size_override("font_size", 13)
	title.add_theme_color_override("font_color", Color(0.15, 0.15, 0.2))
	vbox.add_child(title)
	
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
	
	if current_crisis_level >= CrisisLevel.MODERATE:
		var crisis_topic = Label.new()
		crisis_topic.text = "1. Oelpreis-Crash"
		crisis_topic.add_theme_font_size_override("font_size", 11)
		crisis_topic.add_theme_color_override("font_color", Color.RED)
		vbox.add_child(crisis_topic)
	
	var topics = ["OPEC-Tagung", "Boersen-Crash", "Umwelt-Gesetze", "Tech-Boom", "Elektroautos"]
	var start = 2 if current_crisis_level >= CrisisLevel.MODERATE else 1
	for i in range(topics.size()):
		var topic = Label.new()
		topic.text = "%d. %s" % [start + i, topics[i]]
		topic.add_theme_font_size_override("font_size", 11)
		topic.add_theme_color_override("font_color", Color(0.8, 0.85, 0.95))
		vbox.add_child(topic)
	
	return panel

# ==============================================================================
# HELPER FUNCTIONS
# ==============================================================================

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
		Category.MARKET_CRASH: return Color(0.8, 0.1, 0.1)
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

# ==============================================================================
# SAVE/LOAD
# ==============================================================================

func get_save_data() -> Dictionary:
	return {
		"history": newspaper_history,
		"triggered_events": triggered_events,
		"crisis_level": current_crisis_level,
		"crisis_duration": crisis_duration_months,
		"unsellable_percent": unsellable_oil_percent
	}

func load_save_data(data: Dictionary):
	newspaper_history = data.get("history", [])
	triggered_events = data.get("triggered_events", {})
	current_crisis_level = data.get("crisis_level", CrisisLevel.NONE)
	crisis_duration_months = data.get("crisis_duration", 0)
	unsellable_oil_percent = data.get("unsellable_percent", 0.0)
