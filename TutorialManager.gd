extends Node

# --- TUTORIAL SYSTEM ---
# Optional help system for new players. Can be enabled/disabled at any time.

signal tutorial_step_shown(step_id: String)
signal tutorial_completed

var tutorial_enabled: bool = false
var current_step: String = ""
var completed_steps: Array = []

# --- TUTORIAL STEPS ---
const TUTORIAL_STEPS = {
        "welcome": {
                "title": "Willkommen bei Oil Imperium!",
                "text": "Sie sind nun Besitzer einer Ölfirma! Ihr Ziel ist es, ein Ölimperium aufzubauen.\n\nDieses Tutorial führt Sie durch die Grundlagen. Sie können es jederzeit im Büro deaktivieren.",
                "trigger": "game_start",
                "next": "office_intro"
        },
        "office_intro": {
                "title": "Ihr Büro",
                "text": "Dies ist Ihr Hauptquartier. Von hier aus steuern Sie alles:\n\n• COMPUTER: Finanzberichte, Tanks, Verträge\n• KARTE: Weltkarte und Bohrgebiete\n• KALENDER: Zeit voranschreiten lassen\n• AKTENKOFFER: Spiel speichern\n• TELEFON: Notrufe empfangen",
                "trigger": "office_enter",
                "next": "first_region"
        },
        "first_region": {
                "title": "Texas - Ihr erstes Ölfeld",
                "text": "Texas ist Ihr Startgebiet. Klicken Sie auf die KARTE, um zu den Bohrgebieten zu gelangen.\n\nDort können Sie:\n• Lizenzen für Regionen kaufen\n• Landparzellen erwerben\n• Bohrungen starten",
                "trigger": "map_enter",
                "next": "buy_license"
        },
        "buy_license": {
                "title": "Lizenz kaufen",
                "text": "Bevor Sie bohren können, benötigen Sie eine Förderlizenz.\n\nKlicken Sie auf eine Region und kaufen Sie die Lizenz. Die Kosten variieren je nach Region.\n\nTexas ist am günstigsten und ein guter Startpunkt.",
                "trigger": "region_locked",
                "next": "buy_claim"
        },
        "buy_claim": {
                "title": "Land erwerben",
                "text": "Nach dem Lizenzkauf können Sie Parzellen (Claims) erwerben.\n\n• Graue Felder sind verfügbar\n• Klicken Sie auf ein Feld für Details\n• Der Preis hängt von Lage und Größe ab",
                "trigger": "license_bought",
                "next": "expertise"
        },
        "expertise": {
                "title": "Expertise durchführen",
                "text": "Sie können eine Expertise (geologische Untersuchung) durchführen lassen.\n\nWICHTIG: Expertisen sind nie 100% genau! Die Qualität der Schätzung wird angezeigt.\n\nManchmal zeigen sie Öl an, wo keines ist - und umgekehrt!",
                "trigger": "claim_selected",
                "next": "drilling"
        },
        "drilling": {
                "title": "Bohrung starten",
                "text": "Wenn Sie bereit sind, starten Sie eine Bohrung!\n\n• EIGENE BOHRUNG: Günstiger, aber Sie müssen das Minispiel spielen\n• EXPERTEN-BOHRUNG: Teurer, aber sofortiges Ergebnis\n\nDas Bohr-Minispiel erfordert Geschick: Halten Sie den Bohrer in der Mitte!",
                "trigger": "claim_owned",
                "next": "oil_production"
        },
        "oil_production": {
                "title": "Ölproduktion",
                "text": "Glückwunsch! Wenn Sie Öl gefunden haben, beginnt die Produktion.\n\n• Das Öl wird automatisch gefördert und gelagert\n• Sie brauchen Tanks, um das Öl zu speichern\n• Verkaufen Sie das Öl über den COMPUTER > Öl-Verkauf",
                "trigger": "drilling_complete",
                "next": "contracts"
        },
        "contracts": {
                "title": "Verträge abschließen",
                "text": "Über den COMPUTER können Sie Lieferverträge abschließen.\n\n• SUPPLY VERTRÄGE: Regelmäßige Lieferungen gegen feste Bezahlung\n• FUTURES: Wette auf zukünftige Preise\n\nVerträge bringen stabiles Einkommen, aber Strafen bei Nichterfüllung!",
                "trigger": "first_oil_sale",
                "next": "economy"
        },
        "economy": {
                "title": "Wirtschaft & Markt",
                "text": "Der Ölpreis schwankt! Beachten Sie:\n\n• Historische Ereignisse beeinflussen den Preis (Ölkrise 1973!)\n• Inflation erhöht Ihre Kosten über die Jahre\n• Forschung kann Ihre Effizienz verbessern\n\nPassen Sie Ihre Strategie an die Marktbedingungen an!",
                "trigger": "month_end",
                "next": "sabotage"
        },
        "sabotage": {
                "title": "Wettbewerb & Sabotage",
                "text": "Sie sind nicht allein! KI-Gegner konkurrieren mit Ihnen.\n\nÜber die SCHUBLADE (im Büro) können Sie Sabotageaktionen planen.\n\nACHTUNG: Sabotage ist teuer und riskant. Wenn Sie erwischt werden, zahlen Sie hohe Strafen!",
                "trigger": "competitor_action",
                "next": "tutorial_end"
        },
        "tutorial_end": {
                "title": "Tutorial abgeschlossen!",
                "text": "Sie kennen nun die Grundlagen!\n\nTipps für den Erfolg:\n• Diversifizieren Sie Ihre Fördergebiete\n• Behalten Sie Ihre Finanzen im Auge\n• Investieren Sie in Forschung\n• Passen Sie sich an Marktveränderungen an\n\nViel Erfolg beim Aufbau Ihres Ölimperiums!",
                "trigger": "tutorial_complete",
                "next": ""
        }
}

# --- REFERENCE TO GAME MANAGER ---
var game_manager = null

func _ready():
        # Try to find GameManager
        await get_tree().create_timer(0.5).timeout
        if has_node("/root/GameManager"):
                game_manager = get_node("/root/GameManager")

func enable_tutorial():
        tutorial_enabled = true
        completed_steps.clear()
        save_tutorial_state()
        print("Tutorial aktiviert")

func disable_tutorial():
        tutorial_enabled = false
        print("Tutorial deaktiviert")

func toggle_tutorial():
        if tutorial_enabled:
                disable_tutorial()
        else:
                enable_tutorial()

func check_trigger(trigger_name: String, _context: Dictionary = {}):
        if not tutorial_enabled:
                return
        
        # Find the step for this trigger
        for step_id in TUTORIAL_STEPS:
                if TUTORIAL_STEPS[step_id]["trigger"] == trigger_name:
                        # Skip if already completed
                        if step_id in completed_steps:
                                continue
                        
                        # Check if this step's previous is completed (or it's the first)
                        if should_show_step(step_id):
                                show_step(step_id)
                                break

func should_show_step(step_id: String) -> bool:
        # First step is always showable
        if step_id == "welcome":
                return true
        
        # Check if previous step was completed
        var _step = TUTORIAL_STEPS[step_id]
        for prev_id in TUTORIAL_STEPS:
                if TUTORIAL_STEPS[prev_id]["next"] == step_id:
                        return prev_id in completed_steps
        
        return false

func show_step(step_id: String):
        if not TUTORIAL_STEPS.has(step_id):
                return
        
        current_step = step_id
        var step = TUTORIAL_STEPS[step_id]
        
        # Emit signal for UI to handle
        tutorial_step_shown.emit(step_id)
        
        # Show via FeedbackOverlay if available
        if has_node("/root/FeedbackOverlay"):
                var msg = "=== " + step["title"] + " ===\n\n" + step["text"]
                get_node("/root/FeedbackOverlay").show_msg(msg, Color.CYAN)
        
        print("[TUTORIAL] " + step["title"])

func complete_current_step():
        if current_step == "" or current_step in completed_steps:
                return
        
        completed_steps.append(current_step)
        save_tutorial_state()
        
        # Check if this was the last step
        if current_step == "tutorial_end":
                tutorial_completed.emit()
                tutorial_enabled = false
                print("Tutorial vollständig abgeschlossen!")
        
        current_step = ""

func skip_to_next():
        complete_current_step()
        
        # Show next step if available
        if current_step != "" and TUTORIAL_STEPS.has(current_step):
                var next_id = TUTORIAL_STEPS[current_step].get("next", "")
                if next_id != "" and TUTORIAL_STEPS.has(next_id):
                        show_step(next_id)

# --- PERSISTENCE ---
func save_tutorial_state():
        if game_manager:
                # Could save to game_manager's save system
                pass

func load_tutorial_state():
        if game_manager:
                # Could load from game_manager's save system
                pass

# --- HELPER FOR UI ---
func get_current_step_data() -> Dictionary:
        if current_step == "" or not TUTORIAL_STEPS.has(current_step):
                return {}
        return TUTORIAL_STEPS[current_step]

func get_progress() -> Dictionary:
        return {
                "enabled": tutorial_enabled,
                "completed_count": completed_steps.size(),
                "total_steps": TUTORIAL_STEPS.size(),
                "current_step": current_step
        }

func reset_tutorial():
        completed_steps.clear()
        current_step = ""
        tutorial_enabled = true
        print("Tutorial zurückgesetzt")
