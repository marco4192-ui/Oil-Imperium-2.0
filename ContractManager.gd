extends Node
# ContractManager.gd - Lieferverträge und Futures mit realistischen Hintergründen
# Jeder Vertrag hat einen Auftraggeber mit Geschichte und Motivation

# ==============================================================================
# FIKTIVE FIRMEN - DATENBANK
# ==============================================================================

const COMPANIES = {
	# --- TANKSTELLENKETTEN ---
	"energy_plus": {
		"name": "EnergyPlus Tankstellen GmbH",
		"type": "tankstellen",
		"description": "Europas groesste Tankstellenkette mit ueber 3.000 Stationen.",
		"typical_volume": "high",
		"typical_duration": [6, 12],
		"reliability": 0.9,
		"preferred_regions": ["Texas", "Nordsee", "Saudi-Arabien"],
		"scenarios": [
			"Lieferprobleme mit Hauptlieferant - benoetigen Ueberbrueckung",
			"Raffinerie-Wartung im eigenen Werk - externer Bedarf",
			"Expansion in neue Bundeslaender - zusaetzliche Kapazitaet",
			"Preisschwankungen absichern - Langzeitvertrag gesucht"
		]
	},
	"speed_gas": {
		"name": "SpeedGas International",
		"type": "tankstellen",
		"description": "Aggressive Billigkette, die den Markt unter Druck setzt.",
		"typical_volume": "medium",
		"typical_duration": [3, 6],
		"reliability": 0.7,
		"preferred_regions": ["Texas", "Alaska"],
		"scenarios": [
			"Preiskampf mit Konkurrenz - brauchen guenstiges Oel",
			"Rapid Expansion - viele neue Stationen eroeffnet",
			"Lagerbrand in Hauptdepot - Notfalllieferung noetig",
			"Konkurs eines Konkurrenten - dessen Kunden uebernehmen"
		]
	},
	"auto_stopp": {
		"name": "AutoStopp Tankstellen AG",
		"type": "tankstellen",
		"description": "Deutsche Tankstellenkette mit Fokus auf Autobahnen.",
		"typical_volume": "medium",
		"typical_duration": [6, 9],
		"reliability": 0.85,
		"preferred_regions": ["Texas", "Nordsee"],
		"scenarios": [
			"Urlaubssaison beginnt - Benzinbedarf steigt",
			"Neue Autobahn-Raststaetten eroeffnet",
			"Kooperation mit LKW-Frachtunternehmen",
			"Winter-Diesel-Mehrbedarf"
		]
	},
	
	# --- RAFFINERIEN ---
	"nordlicht_raffinerie": {
		"name": "Nordlicht Raffinerie AG",
		"type": "raffinerie",
		"description": "Groesste deutsche Raffinerie in Hamburg mit 15 Mio. t Jahreskapazitaet.",
		"typical_volume": "very_high",
		"typical_duration": [12, 24],
		"reliability": 0.95,
		"preferred_regions": ["Nordsee", "Texas"],
		"scenarios": [
			"Revision der Crack-Anlage - Kapazitaet reduziert",
			"Hafen-Erweiterung - groessere Tanker moeglich",
			"Umwelt-Auflagen - saubereres Rohoel benoetigt",
			"Pipeline-Anbindung an neues Foerdergebiet",
			"Jahreswartung - externe Versorgung noetig"
		]
	},
	"delta_oil_processing": {
		"name": "Delta Oil Processing Corp.",
		"type": "raffinerie",
		"description": "Amerikanische Raffinerie-Kette mit Standorten an der Golfkueste.",
		"typical_volume": "high",
		"typical_duration": [6, 12],
		"reliability": 0.85,
		"preferred_regions": ["Texas", "Alaska", "Saudi-Arabien"],
		"scenarios": [
			"Hurrikan-Schaden an eigener Foerderanlage",
			"Kapazitaetserweiterung - mehr Input benoetigt",
			"Wartungsarbeiten an Destillationskolonne",
			"Neues Petrochemie-Werk nimmt Betrieb auf"
		]
	},
	"orient_raffinerie": {
		"name": "Orient Raffinerien GmbH",
		"type": "raffinerie",
		"description": "Mittelstaendische Raffinerie mit Spezialisierung auf Spezialoele.",
		"typical_volume": "medium",
		"typical_duration": [3, 6],
		"reliability": 0.8,
		"preferred_regions": ["Saudi-Arabien", "Nordsee"],
		"scenarios": [
			"Spezialauftrag fuer Industrie-Schmieroele",
			"Qualitaetsprobleme mit aktuellem Lieferanten",
			"Neue Produktlinie - anderes Rohoel benoetigt",
			"Saisonale Nachfragespitze bei Heizoele"
		]
	},
	
	# --- ÖLKONZERNE ---
	"deep_oil": {
		"name": "DeepOil Corporation",
		"type": "oelkonzern",
		"description": "Globaler Oelriese mit Foerderung in 15 Laendern.",
		"typical_volume": "very_high",
		"typical_duration": [6, 18],
		"reliability": 0.9,
		"preferred_regions": ["Texas", "Alaska", "Saudi-Arabien", "Nordsee"],
		"scenarios": [
			"Revision aller Offshore-Plattformen - interne Produktion ruht",
			"Uebernahme eines Konkurrenten - Lieferketten neu organisieren",
			"Pipeline-Leck - Transportwege umgeleitet",
			"Bohrung in neuem Feld verzögert sich",
			"Arbeitsstreik in eigenem Foerdergebiet"
		]
	},
	"petro_global": {
		"name": "PetroGlobal Energy",
		"type": "oelkonzern",
		"description": "Britischer Oelmulti mit Focus auf Nordsee und Nahost.",
		"typical_volume": "high",
		"typical_duration": [3, 9],
		"reliability": 0.85,
		"preferred_regions": ["Nordsee", "Saudi-Arabien"],
		"scenarios": [
			"Nordsee-Plattform wegen Sturm evakuiert",
			"Regierungsauflagen in Foerderland verschaeerft",
			"Exploration neue Felder - Ueberbrueckung noetig",
			"CEO-Skandal - Aktienkurs einbrochen, Cash-Knappheit"
		]
	},
	"terra_energy": {
		"name": "Terra Energy Holdings",
		"type": "oelkonzern",
		"description": "Aufsteigender US-Konzern, aggressiv im Schieferoel-Markt.",
		"typical_volume": "medium",
		"typical_duration": [3, 6],
		"reliability": 0.75,
		"preferred_regions": ["Texas", "Alaska"],
		"scenarios": [
			"Fracking-Anlage Umweltauflagen - Produktion gestoppt",
			"Rapid Expansion - mehr Rohoel als verfuegbar",
			"Investoren-Druck - Fertigprodukte benoetigt",
			"Wettbewerb mit grossem Konzern aufgenommen"
		]
	},
	
	# --- AIRLINES ---
	"skynet_airways": {
		"name": "SkyNet Airways",
		"type": "airline",
		"description": "Europas groesste Airline mit 400 Flugzeugen.",
		"typical_volume": "medium",
		"typical_duration": [6, 12],
		"reliability": 0.9,
		"preferred_regions": ["Nordsee", "Texas"],
		"scenarios": [
			"Sommersaison - Kerosin-Bedarf steigt massiv",
			"Neue Langstrecken-Routen aufgenommen",
			"Konkurrent pleite - dessen Strecken uebernommen",
			"Flughafen-Expansion - mehr Starts moeglich",
			"Treitstoff-Hedging fehlgeschlagen"
		]
	},
	"pacific_wings": {
		"name": "Pacific Wings Cargo",
		"type": "airline",
		"description": "Asiatische Fracht-Airline, spezialisiert auf Express-Lieferungen.",
		"typical_volume": "medium",
		"typical_duration": [3, 6],
		"reliability": 0.85,
		"preferred_regions": ["Saudi-Arabien", "Texas"],
		"scenarios": [
			"Online-Handel Boom - Frachtkapazitaet verdoppelt",
			"Weihnachtsgeschaeft beginnt",
			"Neue Hub-Station in Dubai eroeffnet",
			"Wettbewerb mit Maritimen Frachtern"
		]
	},
	"euro_connect": {
		"name": "EuroConnect Airlines",
		"type": "airline",
		"description": "Billig-Airline mit Fokus auf innereuropaeische Fluege.",
		"typical_volume": "low",
		"typical_duration": [3, 6],
		"reliability": 0.7,
		"preferred_regions": ["Nordsee"],
		"scenarios": [
			"Neue Billig-Routen gestartet",
			"Kerosinpreis-Hedge ausgelaufen",
			"Saisonale Urlaubsfluege",
			"Wettbewerbsdruck durch neue Konkurrenz"
		]
	},
	
	# --- SCHIFFFAHRT ---
	"atlantic_shipping": {
		"name": "Atlantic Shipping Lines",
		"type": "schifffahrt",
		"description": "Welts groesste Containerschiff-Reederei mit 200 Schiffen.",
		"typical_volume": "high",
		"typical_duration": [6, 12],
		"reliability": 0.85,
		"preferred_regions": ["Saudi-Arabien", "Texas", "Nordsee"],
		"scenarios": [
			"Suez-Kanal blockiert - lange Routen, mehr Verbrauch",
			"Neue Mega-Schiffe in Dienst gestellt",
			"Weltweiter Handelsboom - Kapazitaet erweitert",
			"Umwelt-Auflagen - saubererer Treibstoff noetig"
		]
	},
	"ocean_logistics": {
		"name": "Ocean Logistics Group",
		"type": "schifffahrt",
		"description": "Mittelstaendische Reederei mit Spezialisierung auf Tanker.",
		"typical_volume": "medium",
		"typical_duration": [3, 9],
		"reliability": 0.8,
		"preferred_regions": ["Nordsee", "Texas"],
		"scenarios": [
			"Tanker-Flotte modernisiert",
			"Neue Routen nach Asien",
			"Piraterie-Probleme - andere Routen benoetigt",
			"Versicherungskosten gestiegen"
		]
	},
	
	# --- INDUSTRIE ---
	"chem_works": {
		"name": "ChemWorks Industries",
		"type": "industrie",
		"description": "Chemiekonzern, der Rohoel als Grundstoff nutzt.",
		"typical_volume": "medium",
		"typical_duration": [6, 12],
		"reliability": 0.85,
		"preferred_regions": ["Nordsee", "Texas"],
		"scenarios": [
			"Neue Kunststoff-Produktlinie gestartet",
			"Umwelt-Auflagen erfuellen - andere Rohstoffe",
			"Industrie-Aufschwung - Mehrbedarf",
			"Werkserweiterung abgeschlossen"
		]
	},
	"steel_corp": {
		"name": "SteelCorp International",
		"type": "industrie",
		"description": "Stahlkonzern mit energieintensiver Produktion.",
		"typical_volume": "medium",
		"typical_duration": [3, 6],
		"reliability": 0.8,
		"preferred_regions": ["Texas", "Alaska"],
		"scenarios": [
			"Neues Stahlwerk geht in Betrieb",
			"Energie-Contract ausgelaufen",
			"Export-Boom nach Asien",
			"Modernisierung der Hochoefen"
		]
	},
	
	# --- STAATLICHE UNTERNEHMEN ---
	"national_energy_board": {
		"name": "National Energy Board (NEB)",
		"type": "staatlich",
		"description": "Staatliche Energie-Agentur - kauft fuer strategische Reserven.",
		"typical_volume": "very_high",
		"typical_duration": [12, 24],
		"reliability": 0.95,
		"preferred_regions": ["Texas", "Saudi-Arabien", "Alaska"],
		"scenarios": [
			"Strategische Reserven aufgestockt",
			"Geopolitische Krise - Vorratssicherung",
			"Nationale Energie-Sicherheit",
			"Regierungswechsel - neue Energiepolitik"
		]
	},
	"defense_fuel_agency": {
		"name": "Defense Fuel Agency",
		"type": "staatlich",
		"description": "Militaerische Treibstoffbeschaffung.",
		"typical_volume": "high",
		"typical_duration": [6, 18],
		"reliability": 0.95,
		"preferred_regions": ["Texas", "Saudi-Arabien"],
		"scenarios": [
			"Militaermanoever angekündigt",
			"Truppenverlegung - mehr Verbrauch",
			"Marine-Operationen erweitert",
			"Langzeit-Liefervertraege erneuert"
		]
	},
	
	# --- KLEINERE KUNDEN ---
	"regional_oil_trader": {
		"name": "Regional Oil Trading Co.",
		"type": "haendler",
		"description": "Unabhaengiger Oelhaendler - kauft und verkauft spekulativ.",
		"typical_volume": "low",
		"typical_duration": [1, 3],
		"reliability": 0.6,
		"preferred_regions": ["Texas"],
		"scenarios": [
			"Arbitrage-Moeglichkeit erkannt",
			"Spekulation auf Preisanstieg",
			"Kurzfristige Nachfrage-Luecke",
			"Konkurrent ausgefallen"
		]
	},
	"independent_power": {
		"name": "Independent Power Corp.",
		"type": "energie",
		"description": "Unabhaengiges Kraftwerk - benoetigt Oel zur Stromerzeugung.",
		"typical_volume": "medium",
		"typical_duration": [3, 6],
		"reliability": 0.75,
		"preferred_regions": ["Texas", "Nordsee"],
		"scenarios": [
			"Spitzenlast im Sommer - mehr Strombedarf",
			"Alternatives Kraftwerk in Wartung",
			"Langzeit-Vertrag ausgelaufen",
			"Preiserhoehung beim Gas - Oel als Alternative"
		]
	}
}

# --- FUTURES-SPEZIALISIERTE KUNDEN ---
const FUTURES_CLIENTS = {
	"speculators": [
		{"name": "Goldman Commodities Desk", "description": "Investmentbank mit aggressiver Oel-Spekulation."},
		{"name": "Morgan Energy Trading", "description": "Hedge-Fund spezialisiert auf Energierohstoffe."},
		{"name": "Vitol Trading BV", "description": "Weltgroesster unabhaengiger Oelhaendler."},
		{"name": "Glencore Energy", "description": "Rohstoffriese mit globaler Praesenz."},
		{"name": "Trafigura Group", "description": "Schweizer Handelsunternehmen fuer Rohstoffe."},
		{"name": "Gunvor Group", "description": "Energie-Trader mit Focus auf Russland und Nahost."}
	],
	"hedgers": [
		{"name": "Lufthansa Fuel Hedging", "description": "Airline sichert Kerosinpreise ab."},
		{"name": "Maersk Oil Trading", "description": "Reederei hedgt Bunkerkosten."},
		{"name": "Delta Airlines Fuel Desk", "description": "US-Airline sichert Treibstoff ab."},
		{"name": "AP Moller Risk Management", "description": "Konglomerat sichert Energiekosten ab."}
	],
	"producers": [
		{"name": "Shell Trading International", "description": "Konzern-Tochter fuer Oel-Handel."},
		{"name": "BP Oil Trading", "description": "Britischer Oelriese am Terminmarkt."},
		{"name": "ExxonMobil Trading", "description": "US-Konzern sichert Produktion ab."},
		{"name": "Chevron Trading Corp.", "description": "Kalifornischer Oelmulti."}
	]
}

# ==============================================================================
# DATEN
# ==============================================================================

var active_supply_contracts = []
var active_futures = []
var available_contract_offers = []
var available_future_offers = []

# Referenz
var game_manager = null

func _ready():
	await get_tree().create_timer(0.5).timeout
	if has_node("/root/GameManager"):
		game_manager = get_node("/root/GameManager")

# ==============================================================================
# VERTRAGS-GENERIERUNG
# ==============================================================================

func generate_new_contract_offers(gm):
	available_contract_offers.clear()
	available_future_offers.clear()
	
	var unlocked_regions = []
	for r in gm.regions:
		if gm.regions[r]["unlocked"]:
			unlocked_regions.append(r)
	
	if unlocked_regions.is_empty():
		return
	
	# 1. LIEFERVERTRÄGE GENERIEREN
	var num_supply_contracts = randi_range(3, 5)
	for i in range(num_supply_contracts):
		var contract = _generate_supply_contract(gm, unlocked_regions)
		available_contract_offers.append(contract)
	
	# 2. FUTURES GENERIEREN
	if randf() < 0.7:
		var future = _generate_future_contract(gm, unlocked_regions)
		available_future_offers.append(future)
	
	# Bei höherem Jahr/Marktaktivität mehr Futures
	if gm.date["year"] >= 1985 and randf() < 0.4:
		var future2 = _generate_future_contract(gm, unlocked_regions)
		available_future_offers.append(future2)

func _generate_supply_contract(gm, unlocked_regions: Array) -> Dictionary:
	# Zufällige Firma auswählen
	var company_keys = COMPANIES.keys()
	var company_key = company_keys.pick_random()
	var company = COMPANIES[company_key]
	
	# Passende Region finden
	var region = _find_matching_region(company, unlocked_regions)
	
	# Szenario auswählen
	var scenario = company["scenarios"].pick_random()
	
	# Vertragsparameter basierend auf Firmengröße
	var duration = company["typical_duration"].pick_random()
	
	var prod_capacity = gm.get_region_daily_production(region) * 30.0
	if prod_capacity == 0:
		prod_capacity = 1000.0
	
	# Volume basierend auf Firmengröße
	var volume_multiplier = _get_volume_multiplier(company["typical_volume"])
	var volume = int(randf_range(0.5, 1.2) * prod_capacity * volume_multiplier)
	volume = int(volume / 100.0) * 100
	if volume < 500:
		volume = 500
	
	# Preis basierend auf Zuverlässigkeit
	var base_price = gm.oil_price * gm.tech_bonus_oil_price
	var reliability_bonus = (company["reliability"] - 0.8) * 0.1  # Zuverlässige Firmen zahlen etwas mehr
	var price_offer = base_price * randf_range(0.88, 1.08) * (1.0 + reliability_bonus)
	
	# Strafe
	var penalty = int(volume * price_offer * (1.5 + (1.0 - company["reliability"]) * 0.5))
	
	# Firma gibt Bonus bei guter Reputation?
	var bonus_text = ""
	if company["reliability"] >= 0.9:
		bonus_text = "\n\n[Vertrauenswuerdiger Partner - puenktliche Zahlung garantiert]"
	elif company["reliability"] < 0.7:
		bonus_text = "\n\n[WARNUNG: Risiko-Kunde - Zahlungsschwierigkeiten moeglich!]"
	
	return {
		"id": randi(),
		"company_key": company_key,
		"company_name": company["name"],
		"company_type": company["type"],
		"company_desc": company["description"],
		"scenario": scenario,
		"region": region,
		"months_total": duration,
		"volume_monthly": volume,
		"price_per_bbl": snapped(price_offer, 0.01),
		"penalty": penalty,
		"reliability": company["reliability"],
		"bonus_text": bonus_text
	}

func _generate_future_contract(gm, unlocked_regions: Array) -> Dictionary:
	# Futures-Typ bestimmen
	var futures_type = randf()
	var client = {}
	var scenario = ""
	
	if futures_type < 0.4:
		# Spekulanten
		client = FUTURES_CLIENTS["speculators"].pick_random()
		scenario = _generate_speculator_scenario()
	elif futures_type < 0.7:
		# Hedger (Absicherung)
		client = FUTURES_CLIENTS["hedgers"].pick_random()
		scenario = _generate_hedger_scenario()
	else:
		# Produzenten
		client = FUTURES_CLIENTS["producers"].pick_random()
		scenario = _generate_producer_scenario()
	
	var region = unlocked_regions.pick_random()
	var months_ahead = randi_range(2, 4)
	
	var volume = int(gm.tank_capacity.get(region, 0) * randf_range(0.3, 0.7))
	if volume < 2000:
		volume = 2000
	volume = int(volume / 500.0) * 500
	
	var base_price = gm.oil_price * gm.tech_bonus_oil_price
	
	# Futures-Preis je nach Marktlage
	var price_offer = base_price * randf_range(0.80, 1.40)
	var penalty = int(volume * price_offer * 2.0)
	
	var due_month = gm.date["month"] + months_ahead
	var due_year = gm.date["year"]
	while due_month > 12:
		due_month -= 12
		due_year += 1
	
	return {
		"id": randi(),
		"client_name": client["name"],
		"client_desc": client["description"],
		"scenario": scenario,
		"region": region,
		"volume": volume,
		"price_per_bbl": snapped(price_offer, 0.01),
		"due_month": due_month,
		"due_year": due_year,
		"penalty": penalty,
		"months_wait": months_ahead
	}

# ==============================================================================
# SZENARIO-GENERIERUNG
# ==============================================================================

func _generate_speculator_scenario() -> String:
	var scenarios = [
		"Analysten erwarten Preisanstieg - bauen Long-Position auf",
		"Markt-Volatilitaet genutzt - Arbitrage-Moeglichkeit gesehen",
		"Algorithmischer Handel hat Signal erkannt",
		"Geo-Politische Spannungen erwartet - vorsorglich gekauft",
		"Technische Analyse zeigt Aufwaerts-Trend",
		"Institutionelle Kunden drängen auf Absicherung",
		"Q4-Earnings-Season - Positionierung vor Quartalszahlen",
		"Wettwette auf OPEC-Entscheidung"
	]
	return scenarios.pick_random()

func _generate_hedger_scenario() -> String:
	var scenarios = [
		"Kerosin-Preisschwankungen absichern - Saisonale Planung",
		"Bunkerkosten fuer Flotte fixieren - Budget-Sicherheit",
		"Waehrungsrisiko und Oelpreis kombiniert absichern",
		"Lieferkette stabilisieren - Feste Kosten kalkulierbar machen",
		"Jahresbudget-Planung - Kosten verlässlich kalkulieren",
		"Risk-Management-Richtlinien erfuellen",
		"Shareholder-Forderung nach Preis-Sicherheit",
		"Konkurrenz drückt Preise - Kostensenkung noetig"
	]
	return scenarios.pick_random()

func _generate_producer_scenario() -> String:
	var scenarios = [
		"Produktions-Abrechnung vorzeitig sichern",
		"Bohrungs-Erlöse festgeschrieben - Investorensicherheit",
		"Projekt-Finanzierung erfordert Preis-Garantie",
		"Quartalsziele erfuellen - Verkauf vorzeitig buchen",
		"Lagerkapazitaet begrenzt - Verkauf auf Termin",
		"Wartungsphase kommend - Produktion sichern",
		"Steueroptimierung durch Timing",
		"Portfolio-Rebalancing - Risikostreuung"
	]
	return scenarios.pick_random()

# ==============================================================================
# HELPER-FUNKTIONEN
# ==============================================================================

func _find_matching_region(company: Dictionary, unlocked_regions: Array) -> String:
	var preferred = company.get("preferred_regions", [])
	
	for pref in preferred:
		if pref in unlocked_regions:
			return pref
	
	return unlocked_regions.pick_random()

func _get_volume_multiplier(volume_type: String) -> float:
	match volume_type:
		"very_high": return randf_range(1.5, 2.5)
		"high": return randf_range(1.0, 1.5)
		"medium": return randf_range(0.7, 1.0)
		"low": return randf_range(0.3, 0.7)
		_: return 1.0

func get_company_type_name(type: String) -> String:
	match type:
		"tankstellen": return "Tankstellenkette"
		"raffinerie": return "Raffinerie"
		"oelkonzern": return "Oelkonzern"
		"airline": return "Airline"
		"schifffahrt": return "Reederei"
		"industrie": return "Industrie"
		"staatlich": return "Staatlich"
		"haendler": return "Haendler"
		"energie": return "Energieversorger"
		_: return "Unternehmen"

func get_company_type_icon(type: String) -> String:
	match type:
		"tankstellen": return "⛽"
		"raffinerie": return "🏭"
		"oelkonzern": return "🛢️"
		"airline": return "✈️"
		"schifffahrt": return "🚢"
		"industrie": return "⚙️"
		"staatlich": return "🏛️"
		"haendler": return "📊"
		"energie": return "⚡"
		_: return "🏢"

# ==============================================================================
# INTERAKTION
# ==============================================================================

func sign_supply_contract(gm, index):
	if index < 0 or index >= available_contract_offers.size():
		return
	
	var offer = available_contract_offers[index]
	
	# Vertrag mit allen Details speichern
	active_supply_contracts.append({
		"company_name": offer["company_name"],
		"company_type": offer["company_type"],
		"scenario": offer["scenario"],
		"region": offer["region"],
		"volume_monthly": offer["volume_monthly"],
		"price_per_bbl": offer["price_per_bbl"],
		"months_left": offer["months_total"],
		"months_total": offer["months_total"],
		"penalty": offer["penalty"],
		"reliability": offer.get("reliability", 0.8),
		"signed_month": gm.date["month"],
		"signed_year": gm.date["year"]
	})
	
	available_contract_offers.remove_at(index)
	gm.emit_contract_signed("supply", offer)
	gm.notify_update()
	
	# Feedback-Nachricht
	if gm.has_node("/root/FeedbackOverlay"):
		var msg = "VERTRAG UNTERSCHRIEBEN!\n"
		msg += "%s\n" % offer["company_name"]
		msg += "%d Monate @ %d bbl/Monat" % [offer["months_total"], offer["volume_monthly"]]
		gm.get_node("/root/FeedbackOverlay").show_msg(msg, Color.GREEN)

func sign_future_contract(gm, index):
	if index < 0 or index >= available_future_offers.size():
		return
	
	var offer = available_future_offers[index]
	
	active_futures.append({
		"client_name": offer["client_name"],
		"client_desc": offer["client_desc"],
		"scenario": offer["scenario"],
		"region": offer["region"],
		"volume": offer["volume"],
		"price_per_bbl": offer["price_per_bbl"],
		"due_month": offer["due_month"],
		"due_year": offer["due_year"],
		"penalty": offer["penalty"],
		"months_wait": offer["months_wait"],
		"signed_month": gm.date["month"],
		"signed_year": gm.date["year"]
	})
	
	available_future_offers.remove_at(index)
	gm.emit_contract_signed("future", offer)
	gm.notify_update()
	
	# Feedback
	if gm.has_node("/root/FeedbackOverlay"):
		var msg = "FUTURE GEZEICHNET!\n"
		msg += "%s\n" % offer["client_name"]
		msg += "Faellig: %02d/%d | %d bbl" % [offer["due_month"], offer["due_year"], offer["volume"]]
		gm.get_node("/root/FeedbackOverlay").show_msg(msg, Color.CYAN)

# ==============================================================================
# VERARBEITUNG AM MONATSENDE
# ==============================================================================

func process_contracts_end_of_month(gm):
	# 1. LIEFERVERTRÄGE
	for i in range(active_supply_contracts.size() - 1, -1, -1):
		var contract = active_supply_contracts[i]
		var reg = contract["region"]
		var stored = gm.oil_stored.get(reg, 0.0)
		
		# Zuverlässigkeits-Check: Zahlt der Kunde pünktlich?
		var pays_on_time = randf() < contract.get("reliability", 0.8)
		
		if stored >= contract["volume_monthly"]:
			gm.oil_stored[reg] -= contract["volume_monthly"]
			var revenue = contract["volume_monthly"] * contract["price_per_bbl"]
			
			if pays_on_time:
				gm.book_transaction(reg, revenue, "Contracts")
				gm.emit_contract_fulfilled("supply", revenue)
				
				if gm.has_node("/root/FeedbackOverlay"):
					var msg = "LIEFERVERTRAG ERFUELLT\n%s\n+$%.0f" % [contract["company_name"], revenue]
					gm.get_node("/root/FeedbackOverlay").show_msg(msg, Color.GREEN)
			else:
				# Verspätete Zahlung (wird nächstes Monat gezahlt)
				gm.book_transaction(reg, revenue * 0.9, "Contracts (Late)")  # 10% Strafabzug
				var penalty_msg = "VERSPAETETE ZAHLUNG!\n%s zahlt erst spaet.\n-10% Verzugsstrafe" % contract["company_name"]
				if gm.has_node("/root/FeedbackOverlay"):
					gm.get_node("/root/FeedbackOverlay").show_msg(penalty_msg, Color.ORANGE)
		else:
			# Nicht genug Öl
			gm.oil_stored[reg] = 0
			var penalty = contract["penalty"] * gm.inflation_rate
			gm.book_transaction(reg, -penalty, "Penalties")
			gm.emit_contract_failed("supply", penalty)
			
			if gm.has_node("/root/FeedbackOverlay"):
				var msg = "VERTRAG NICHT ERFUELLBAR!\n%s\nStrafe: -$%.0f" % [contract["company_name"], penalty]
				gm.get_node("/root/FeedbackOverlay").show_msg(msg, Color.RED)
		
		contract["months_left"] -= 1
		if contract["months_left"] <= 0:
			active_supply_contracts.remove_at(i)
	
	# 2. TERMINGESCHÄFTE
	for i in range(active_futures.size() - 1, -1, -1):
		var future = active_futures[i]
		if future["due_month"] == gm.date["month"] and future["due_year"] == gm.date["year"]:
			var reg = future["region"]
			var stored = gm.oil_stored.get(reg, 0.0)
			
			if stored >= future["volume"]:
				gm.oil_stored[reg] -= future["volume"]
				var revenue = future["volume"] * future["price_per_bbl"]
				gm.book_transaction(reg, revenue, "Futures")
				gm.emit_contract_fulfilled("future", revenue)
				
				if gm.has_node("/root/FeedbackOverlay"):
					var msg = "FUTURE FAELLIG!\n%s\nGewinn: +$%.0f" % [future["client_name"], revenue]
					gm.get_node("/root/FeedbackOverlay").show_msg(msg, Color.GREEN)
			else:
				var missing = future["volume"] - stored
				gm.oil_stored[reg] = 0
				
				var revenue_part = stored * future["price_per_bbl"]
				var buy_price = gm.oil_price * 1.05
				var buy_cost = missing * buy_price
				var revenue_total = revenue_part + (missing * future["price_per_bbl"])
				var net_result = revenue_total - buy_cost
				
				gm.book_transaction(reg, net_result, "Futures (Failed)")
				
				if gm.has_node("/root/FeedbackOverlay"):
					var result_color = Color.ORANGE if net_result < 0 else Color.WHITE
					var msg = "FUTURE FAELLIG - TEILWEISE LIEFERUNG!\n%s\nFehlt: %d bbl @ $%.2f\nErgebnis: $%.0f" % [
						future["client_name"], missing, buy_price, net_result
					]
					gm.get_node("/root/FeedbackOverlay").show_msg(msg, result_color)
			
			active_futures.remove_at(i)

# ==============================================================================
# SAVE/LOAD
# ==============================================================================

func get_save_data() -> Dictionary:
	return {
		"active_supply_contracts": active_supply_contracts,
		"active_futures": active_futures,
		"available_contract_offers": available_contract_offers,
		"available_future_offers": available_future_offers
	}

func load_save_data(data: Dictionary):
	active_supply_contracts = data.get("active_supply_contracts", [])
	active_futures = data.get("active_futures", [])
	available_contract_offers = data.get("available_contract_offers", [])
	available_future_offers = data.get("available_future_offers", [])
