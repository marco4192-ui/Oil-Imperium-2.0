extends Node

# --- EVENT POOLS ---
var random_events_pool = [
        # Standard
        {"id": "strike", "type": "fine", "title": "STREIK!", "text": "Arbeiter streiken für höhere Löhne.", "base_cost": 50000, "scale_with_wealth": true},
        {"id": "bonus", "type": "bonus", "title": "INVESTOREN", "text": "Neue Investoren glauben an Ihr Projekt.", "base_amount": 100000},
        {"id": "tech", "type": "buff", "stat": "drill_speed", "title": "NEUE TECHNIK", "text": "Neue Legierungen verbessern die Bohrgeschwindigkeit.", "duration": 12},
        
        # Unfälle
        {"id": "well_collapse", "type": "accident_rig", "title": "BOHRLOCH EINGESTÜRZT", "text": "Kritischer Druckverlust! Ein Bohrloch ist kollabiert. Equipment verloren."},
        {"id": "tank_fire", "type": "accident_tank", "title": "FEUER IN TANKANLAGE", "text": "Blitzschlag hat einen Tank entzündet! Kapazität zerstört und Öl verbrannt."},
        {"id": "worker_accident", "type": "accident_worker", "title": "ARBEITSUNFALL", "text": "Ein Arbeiter wurde verletzt! Medizinische Kosten und Anwaltsgebühren.", "base_cost": 80000},
        {"id": "equipment_failure", "type": "accident_equipment", "title": "EQUIPMENT-VERSAGEN", "text": "Ein Pumpenjack ist ausgefallen. Teure Reparatur erforderlich.", "base_cost": 45000},
        {"id": "pipeline_burst", "type": "accident_pipeline", "title": "PIPELINE-BRUCH", "text": "Eine Pipeline ist geborsten! Umweltstrafen und Reparaturkosten."},
        {"id": "rig_explosion", "type": "accident_explosion", "title": "RIG-EXPLOSION", "text": "Gasleck verursacht Explosion! Schwere Schäden und Verletzungen.", "base_cost": 500000},
        
        # Kriminalität & Diebstahl
        {"id": "corruption", "type": "fine", "title": "KORRUPTION", "text": "Lokale Beamte fordern 'Bearbeitungsgebühren' für Ihre Lizenzen.", "base_cost": 75000, "scale_with_wealth": true},
        {"id": "terror_attack", "type": "terror", "title": "TERROR-ANSCHLAG", "text": "Anschlag auf Pipeline-Infrastruktur! Massive Schäden."},
        {"id": "blackmail", "type": "fine", "title": "ERPRESSUNG", "text": "Ein Warlord fordert Schutzgeld für Ihre Anlagen.", "base_cost": 100000, "scale_with_wealth": false},
        {"id": "oil_theft", "type": "theft", "title": "ÖL-DIEBSTAHL", "text": "Piraten haben Öl aus Ihren Tanks gestohlen!", "stolen_percent": 0.08},
        {"id": "equipment_theft", "type": "equipment_theft", "title": "EQUIPMENT-DIEBSTAHL", "text": "Werkzeuge und Ersatzteile wurden gestohlen.", "base_cost": 35000},
        {"id": "embezzlement", "type": "fine", "title": "UNTERSCHLAGUNG", "text": "Ein Buchhalter hat Firmengelder veruntreut!", "base_cost": 150000, "scale_with_wealth": true},
        {"id": "fraud", "type": "fine", "title": "BETRUG", "text": "Ein Lieferant hat Sie überfacturiert.", "base_cost": 60000},
        
        # Öl-Katastrophen
        {"id": "oil_spill_minor", "type": "oil_spill", "title": "ÖLPEST (KLEIN)", "text": "Ein kleineres Ölleck verursacht Umweltschäden.", "cleanup_cost": 100000, "reputation_damage": 0.05},
        {"id": "oil_spill_major", "type": "oil_spill", "title": "ÖLPEST (GROSS)", "text": "Massives Ölleck! Medienaufmerksamkeit und hohe Strafen.", "cleanup_cost": 500000, "reputation_damage": 0.15, "min_year": 1980},
        {"id": "oil_spill_offshore", "type": "oil_spill_offshore", "title": "OFFSHORE-HAVARIE", "text": "Offshore-Plattform leckt! Schwere Umweltschäden.", "cleanup_cost": 2000000, "min_year": 1975},
        
        # Regionale Instabilität
        {"id": "separatists", "type": "region_lock", "title": "SEPARATISTEN", "text": "Rebellen haben die Kontrolle über eine Region übernommen! Zugang gesperrt.", "duration_months": 6},
        {"id": "civil_war", "type": "region_lock", "title": "BÜRGERKRIEG", "text": "Bewaffneter Konflikt in einer Region! Alle Operationen gestoppt.", "duration_months": 12},
        {"id": "coup", "type": "region_lock", "title": "STAATSTREICH", "text": "Militärputsch! Neue Regierung überzieht Lizenzen.", "duration_months": 4},
        {"id": "embargo", "type": "region_lock", "title": "EMBARGO", "text": "Internationale Sanktionen sperren eine Region.", "duration_months": 8, "min_year": 1975},
        {"id": "nationalization", "type": "region_lock", "title": "NATIONALISIERUNG", "text": "Regierung verstaatlicht ausländische Ölfelder!", "duration_months": 6, "min_year": 1975},
        
        # Wirtschaftliche Ereignisse
        {"id": "market_crash", "type": "market_event", "title": "BÖRSENCrash", "text": "Aktienmarkt einbricht! Ihre Investitionen verlieren an Wert.", "cash_loss_percent": 0.05},
        {"id": "bank_crisis", "type": "fine", "title": "BANKENKRISE", "text": "Ihre Bank hat Gebühren erhöht.", "base_cost": 30000},
        {"id": "tax_audit", "type": "fine", "title": "STEUERPRÜFUNG", "text": "Finanzamt prüft Ihre Bücher. Nachzahlungen erforderlich.", "base_cost": 120000},
        {"id": "currency_crisis", "type": "market_event", "title": "WÄHRUNGSKRISE", "text": "Währungsschwankungen treffen Ihre Auslandsinvestitionen.", "cash_loss_percent": 0.03},
        
        # Positive Ereignisse
        {"id": "oil_discovery", "type": "bonus", "title": "NEUES ÖLFELD!", "text": "Geologen haben neue Reserven entdeckt!", "base_amount": 200000},
        {"id": "government_grant", "type": "bonus", "title": "STAATSZUSCHUSS", "text": "Regierung fördert Ihre Bohrprojekte.", "base_amount": 150000},
        {"id": "tax_break", "type": "buff", "stat": "tax_reduction", "title": "STEUERERLEICHTERUNG", "text": "Neue Steuerreform senkt Ihre Belastung.", "duration": 6},
        {"id": "oil_price_spike", "type": "price_buff", "title": "PREIS-ANSTIEG", "text": "Ölpreis steigt temporär!", "price_multiplier": 1.3, "duration": 3},
        
        # Spätere Jahre
        {"id": "activist_blockade", "type": "fine", "title": "UMWELT-BLOCKADE", "text": "Aktivisten blockieren die Zufahrtswege.", "base_cost": 40000, "min_year": 1980},
        {"id": "activist_sabotage", "type": "accident_tank", "title": "ÖKO-TERRORISMUS", "text": "Radikale Umweltschützer haben einen Tank sabotiert.", "min_year": 1995},
        {"id": "cyber_attack", "type": "fine", "title": "CYBER-ANGRIFF", "text": "Hacker haben Ihre Systeme angegriffen!", "base_cost": 200000, "min_year": 1990},
        {"id": "climate_regulation", "type": "fine", "title": "KLIMA-REGULIERUNG", "text": "Neue Umweltgesetze erhöhen Ihre Kosten.", "base_cost": 100000, "min_year": 1995}
]

var historical_events = [
        { "year": 1971, "month": 2, "unlock_region": "Nigeria", "title": "NIGERIA OPEC", "text": "Nigeria öffnet Markt." },
        { "year": 1973, "month": 10, "effect_type": "price_shock", "value": 4.0, "title": "ÖLKRISE", "text": "Der Preis explodiert durch das Embargo!" },
        { "year": 1974, "month": 5, "unlock_region": "Indonesien", "title": "ASIEN BOOMT", "text": "Indonesien steigert seine Förderung massiv." },
        { "year": 1979, "month": 2, "effect_type": "price_shock", "value": 2.5, "title": "REVOLUTION IM IRAN", "text": "Unsicherheit treibt den Preis." }
]

var random_event_chance = 0.15

# --- LOGIK ---
func check_historical_events(gm): 
        for e in historical_events: 
                if e["year"] == gm.date["year"] and e["month"] == gm.date["month"]: 
                        trigger_event(gm, e)

func check_random_events(gm): 
        if randf() <= random_event_chance: 
                trigger_random_event(gm, random_events_pool.pick_random())

func trigger_event(gm, e):
        gm.unread_news.append({"title":e["title"],"text":e["text"],"date_str":"%02d/%d"%[gm.date["month"],gm.date["year"]]})
        if e.has("unlock_region") and e["unlock_region"] in gm.regions: 
                gm.regions[e["unlock_region"]]["visible"] = true
        if e.has("effect_type"):
                if e["effect_type"]=="price_shock": gm.price_multiplier = e["value"]
                elif e["effect_type"]=="cost_increase_offshore": gm.offshore_cost_multiplier = e["value"]
                elif e["effect_type"]=="cost_increase_global": gm.global_cost_multiplier = e["value"]
        gm.notify_update()

func trigger_random_event(gm, e):
        if e.has("min_year") and gm.date["year"] < e["min_year"]: return
        
        var msg = e["text"]
        
        if e["type"] == "fine":
                var c = e["base_cost"]
                if e.get("scale_with_wealth"): c = max(c, int(gm.cash * 0.02))
                c *= gm.inflation_rate
                gm.cash -= c
                gm.current_month_stats["expenses"] += c
                msg += "\n\nKOSTEN: -$" + str(int(c))
                gm.current_month_breakdown["events"] += c
                
        elif e["type"] == "bonus":
                var b = e["base_amount"] * gm.inflation_rate
                gm.cash += b
                gm.current_month_stats["revenue"] += b
                msg += "\n\nEINNAHME: +$" + str(int(b))
                
        elif e["type"] == "buff" and e["stat"] == "drill_speed":
                gm.global_drill_speed_modifier = 0.8
                msg += "\n(Bohr-Boost aktiv!)"
        
        # === NEW EVENT TYPES ===
        
        elif e["type"] == "accident_worker":
                # Worker accident - costs and potential legal issues
                var cost = e["base_cost"] * gm.inflation_rate
                gm.cash -= cost
                gm.current_month_breakdown["events"] += cost
                msg += "\n\nMedizinische Kosten: -$" + str(int(cost))
                msg += "\n(Anwaltliche Beratung eingeschaltet)"
        
        elif e["type"] == "accident_equipment":
                # Equipment failure - repair costs
                var cost = e["base_cost"] * gm.inflation_rate
                gm.cash -= cost
                gm.current_month_breakdown["events"] += cost
                msg += "\n\nReparaturkosten: -$" + str(int(cost))
        
        elif e["type"] == "accident_pipeline":
                # Pipeline burst - oil spill + cleanup + fines
                var valid_regions = []
                for r_name in gm.regions:
                        if gm.tank_capacity[r_name] > 0 or gm.oil_stored[r_name] > 0:
                                valid_regions.append(r_name)
                if valid_regions.is_empty(): return
                
                var r_name = valid_regions.pick_random()
                var lost_oil = int(gm.oil_stored[r_name] * 0.1)
                var cleanup = 80000 * gm.inflation_rate
                var fine = lost_oil * 3.0 * gm.inflation_rate
                
                gm.oil_stored[r_name] -= lost_oil
                gm.cash -= (cleanup + fine)
                gm.current_month_breakdown["events"] += (cleanup + fine)
                
                msg += "\nREGION: " + r_name
                msg += "\nVerlorenes Öl: " + str(lost_oil) + " bbl"
                msg += "\nReinigungskosten: -$" + str(int(cleanup))
                msg += "\nUmweltstrafe: -$" + str(int(fine))
        
        elif e["type"] == "accident_explosion":
                # Rig explosion - major disaster
                var victims = []
                for r_name in gm.regions:
                        for claim in gm.regions[r_name]["claims"]:
                                if claim.get("owned", false) and claim.get("drilled", false):
                                        victims.append({"claim": claim, "region": r_name})
                
                if victims.is_empty():
                        # No rigs to explode, just financial impact
                        var cost = e["base_cost"] * 0.5 * gm.inflation_rate
                        gm.cash -= cost
                        msg += "\n\nSicherheits-Upgrade Kosten: -$" + str(int(cost))
                else:
                        var victim = victims.pick_random()
                        var claim = victim["claim"]
                        claim["drilled"] = false
                        
                        var cost = e["base_cost"] * gm.inflation_rate
                        gm.cash -= cost
                        gm.current_month_breakdown["events"] += cost
                        
                        msg += "\nREGION: " + victim["region"]
                        msg += "\nEin Rig wurde zerstört!"
                        msg += "\nVersicherung/Strafen: -$" + str(int(cost))
        
        elif e["type"] == "equipment_theft":
                var cost = e["base_cost"] * gm.inflation_rate
                gm.cash -= cost
                gm.current_month_breakdown["events"] += cost
                msg += "\n\nVerlust: -$" + str(int(cost))
                msg += "\n(Sicherheit wird überprüft)"
        
        elif e["type"] == "oil_spill":
                # Oil spill - environmental disaster
                var cleanup = e["cleanup_cost"] * gm.inflation_rate
                var valid_regions = []
                for r_name in gm.regions:
                        if gm.oil_stored[r_name] > 1000:
                                valid_regions.append(r_name)
                if valid_regions.is_empty():
                        gm.cash -= cleanup
                        msg += "\n\nReinigungskosten: -$" + str(int(cleanup))
                else:
                        var r_name = valid_regions.pick_random()
                        var spilled = int(gm.oil_stored[r_name] * 0.05)
                        gm.oil_stored[r_name] -= spilled
                        gm.cash -= cleanup
                        
                        msg += "\nREGION: " + r_name
                        msg += "\nVerschüttet: " + str(spilled) + " bbl"
                        msg += "\nReinigungskosten: -$" + str(int(cleanup))
                        msg += "\n(Reputation geschädigt!)"
        
        elif e["type"] == "oil_spill_offshore":
                # Major offshore disaster
                var cleanup = e["cleanup_cost"] * gm.inflation_rate
                var offshore_regions = []
                for r_name in gm.regions:
                        if gm.regions[r_name].get("offshore_ratio", 0) > 0 and gm.oil_stored[r_name] > 0:
                                offshore_regions.append(r_name)
                
                if offshore_regions.is_empty():
                        gm.cash -= cleanup * 0.3  # Less if no offshore
                else:
                        var r_name = offshore_regions.pick_random()
                        var spilled = int(gm.oil_stored[r_name] * 0.15)
                        gm.oil_stored[r_name] -= spilled
                        gm.cash -= cleanup
                        
                        msg += "\nREGION: " + r_name
                        msg += "\nVerschüttet: " + str(spilled) + " bbl"
                        msg += "\nReinigungskosten: -$" + str(int(cleanup))
                        msg += "\n(MEDIEN-AUFMERKSAMKEIT!)"
        
        elif e["type"] == "market_event":
                # Economic events affecting cash
                var loss_percent = e.get("cash_loss_percent", 0.03)
                var loss = int(gm.cash * loss_percent)
                gm.cash -= loss
                gm.current_month_breakdown["events"] += loss
                msg += "\n\nVerlust: -$" + str(int(loss))
        
        elif e["type"] == "price_buff":
                # Temporary oil price boost
                var multiplier = e.get("price_multiplier", 1.2)
                gm.price_multiplier = multiplier
                msg += "\n\nÖlpreis-Multiplikator: " + str(multiplier) + "x"
                msg += "\n(Vorübergehend!)"
                
        # === EXISTING EVENT TYPES ===
                
        elif e["type"] == "accident_rig":
                var victims = []
                for r_name in gm.regions:
                        for claim in gm.regions[r_name]["claims"]:
                                if claim["owned"] and claim["drilled"] and claim["has_oil"]:
                                        victims.append(claim)
                if victims.is_empty(): return 
                var target = victims.pick_random()
                target["drilled"] = false 
                msg += "\n(Ein aktives Bohrloch ist verloren!)"
                
        elif e["type"] == "accident_tank":
                var valid_regions = []
                for r_name in gm.regions:
                        if gm.tank_capacity[r_name] > 0: valid_regions.append(r_name)
                if valid_regions.is_empty(): return 
                var r_name = valid_regions.pick_random()
                var dmg_percent = randf_range(0.1, 0.5) 
                var lost_cap = int(gm.tank_capacity[r_name] * dmg_percent)
                var lost_oil = int(gm.oil_stored[r_name] * dmg_percent)
                gm.tank_capacity[r_name] -= lost_cap
                gm.oil_stored[r_name] -= lost_oil
                var fine = lost_oil * 5.0 * gm.inflation_rate
                gm.cash -= fine
                msg += "\nREGION: " + r_name
                msg += "\nVerlust Kapazität: " + str(lost_cap) + " bbl"
                msg += "\nVerbranntes Öl: " + str(lost_oil) + " bbl"
                msg += "\nUmweltstrafe: -$" + str(int(fine))
                
        elif e["type"] == "theft":
                var valid_regions = []
                for r_name in gm.regions:
                        if gm.oil_stored[r_name] > 1000: valid_regions.append(r_name)
                if valid_regions.is_empty(): return
                var r_name = valid_regions.pick_random()
                var stolen_percent = e.get("stolen_percent", 0.08)
                var stolen = int(gm.oil_stored[r_name] * stolen_percent) 
                gm.oil_stored[r_name] -= stolen
                msg += "\nREGION: " + r_name
                msg += "\nGestohlen: " + str(stolen) + " bbl"

        elif e["type"] == "terror":
                var valid_regions = []
                for r_name in gm.regions:
                        if gm.regions[r_name]["unlocked"]: valid_regions.append(r_name)
                if valid_regions.is_empty(): return
                var r_name = valid_regions.pick_random()
                
                # Schaden: Tank Kapazität
                var dmg_cap = int(gm.tank_capacity[r_name] * 0.3)
                gm.tank_capacity[r_name] -= dmg_cap
                
                var repair_cost = 250000 * gm.inflation_rate
                gm.cash -= repair_cost
                
                msg += "\nREGION: " + r_name
                msg += "\nInfrastruktur schwer beschädigt."
                msg += "\nReparaturkosten: -$" + str(int(repair_cost))
                
        elif e["type"] == "region_lock":
                var valid_regions = []
                for r_name in gm.regions:
                        if gm.regions[r_name]["unlocked"]: valid_regions.append(r_name)
                if valid_regions.is_empty(): return
                var r_name = valid_regions.pick_random()
                
                # Region sperren (Timer setzen)
                gm.regions[r_name]["block_timer"] = e["duration_months"] * 30 # Ca. in Tagen
                
                msg += "\nREGION: " + r_name
                msg += "\nStatus: BESETZT / GESPERRT"
                msg += "\nDauer: ca. " + str(e["duration_months"]) + " Monate"

        # Notify achievement manager if present
        if gm.achievement_manager and (e["type"].begins_with("accident") or e["type"] == "fine" or e["type"] == "terror" or e["type"] == "region_lock"):
                gm.achievement_manager.on_negative_event()

        gm.unread_news.append({"title": "EILMELDUNG: " + e["title"], "text": msg, "date_str": "%02d/%d" % [gm.date["month"], gm.date["year"]]})
        gm.notify_update()
