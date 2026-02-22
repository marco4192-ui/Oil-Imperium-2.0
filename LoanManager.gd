extends Node
# LoanManager.gd - Handles borrowing money with interest and bankruptcy risk

signal loan_taken(loan: Dictionary)
signal loan_repaid(loan_id: String)
signal bankruptcy_warning(risk_level: float)

# --- LOAN CONFIGURATION ---
const MAX_ACTIVE_LOANS = 3
const BASE_INTEREST_RATE = 0.08  # 8% annual interest
const BANKRUPTCY_THRESHOLD = -1000000  # Negative cash threshold

# --- LOAN OFFERS ---
const LOAN_OFFERS = [
	{
		"id": "small",
		"name": "Kleinkredit",
		"principal": 500000,
		"interest_rate": 0.10,
		"duration_months": 12,
		"description": "Kleiner Überbrückungskredit"
	},
	{
		"id": "medium",
		"name": "Geschäftskredit",
		"principal": 2000000,
		"interest_rate": 0.08,
		"duration_months": 24,
		"description": "Mittelfristige Finanzierung"
	},
	{
		"id": "large",
		"name": "Großinvestition",
		"principal": 10000000,
		"interest_rate": 0.06,
		"duration_months": 36,
		"description": "Große Expansionsfinanzierung"
	},
	{
		"id": "emergency",
		"name": "Notfallkredit",
		"principal": 1000000,
		"interest_rate": 0.15,  # High interest!
		"duration_months": 6,
		"description": "Schnelle Liquidität (hohe Zinsen!)"
	}
]

# --- ACTIVE LOANS ---
var active_loans: Array = []
var credit_rating: float = 1.0  # 0.0 = bad, 1.0 = excellent
var total_debt: float = 0.0

# --- BANKRUPTCY TRACKING ---
var months_in_debt: int = 0
var bankruptcy_risk: float = 0.0

# --- REFERENCE ---
var game_manager = null

func _ready():
	await get_tree().create_timer(0.5).timeout
	if has_node("/root/GameManager"):
		game_manager = get_node("/root/GameManager")

# --- TAKE LOAN ---
func take_loan(offer_id: String) -> Dictionary:
	if game_manager == null:
		return {"success": false, "message": "Systemfehler"}
	
	# Find the offer
	var offer = null
	for o in LOAN_OFFERS:
		if o["id"] == offer_id:
			offer = o
			break
	
	if offer == null:
		return {"success": false, "message": "Kreditangebot nicht gefunden"}
	
	# Check max loans
	if active_loans.size() >= MAX_ACTIVE_LOANS:
		return {"success": false, "message": "Maximale Anzahl aktiver Kredite erreicht"}
	
	# Calculate actual terms based on credit rating
	var adjusted_rate = offer["interest_rate"] * (2.0 - credit_rating)  # Worse rating = higher rate
	var principal = offer["principal"] * game_manager.inflation_rate
	
	# Create loan
	var loan = {
		"id": str(Time.get_ticks_msec()),
		"name": offer["name"],
		"principal": principal,
		"remaining": principal,
		"interest_rate": adjusted_rate,
		"monthly_payment": _calculate_monthly_payment(principal, adjusted_rate, offer["duration_months"]),
		"months_remaining": offer["duration_months"],
		"total_interest": 0.0,
		"start_year": game_manager.date["year"],
		"start_month": game_manager.date["month"]
	}
	
	# Apply loan
	active_loans.append(loan)
	total_debt += principal
	game_manager.cash += principal
	
	# Update credit rating
	_update_credit_rating()
	
	loan_taken.emit(loan)
	
	return {
		"success": true, 
		"message": "Kredit aufgenommen: $%s\nMonatliche Rate: $%s\nZinssatz: %.1f%%" % [
			_fmt(principal), _fmt(loan["monthly_payment"]), adjusted_rate * 100
		],
		"loan": loan
	}

func _calculate_monthly_payment(principal: float, annual_rate: float, months: int) -> float:
	var monthly_rate = annual_rate / 12.0
	if monthly_rate == 0:
		return principal / months
	
	# Amortization formula
	var payment = principal * (monthly_rate * pow(1 + monthly_rate, months)) / (pow(1 + monthly_rate, months) - 1)
	return payment

# --- PROCESS MONTHLY ---
func process_monthly_payments():
	if game_manager == null:
		return
	
	var total_payment = 0.0
	var loans_to_remove = []
	
	for loan in active_loans:
		var payment = min(loan["monthly_payment"], loan["remaining"])
		
		if game_manager.cash >= payment:
			game_manager.cash -= payment
			loan["remaining"] -= payment
			total_payment += payment
			
			# Calculate interest portion
			var interest_portion = loan["remaining"] * (loan["interest_rate"] / 12.0)
			loan["total_interest"] += interest_portion
			
			loan["months_remaining"] -= 1
			
			if loan["months_remaining"] <= 0 or loan["remaining"] <= 0:
				loans_to_remove.append(loan)
		else:
			# Missed payment - penalty
			var penalty = payment * 0.05
			loan["remaining"] += penalty  # Add penalty to remaining debt
			credit_rating = max(0.1, credit_rating - 0.1)
			
			if has_node("/root/FeedbackOverlay"):
				get_node("/root/FeedbackOverlay").show_msg(
					"KREDITRATENZAHLUNG VERPASST!\nStrafe: +$%s\nKreditrating gesunken" % _fmt(penalty),
					Color.RED
				)
	
	# Remove paid off loans
	for loan in loans_to_remove:
		active_loans.erase(loan)
		total_debt -= loan["principal"]
		loan_repaid.emit(loan["id"])
		
		if has_node("/root/FeedbackOverlay"):
			get_node("/root/FeedbackOverlay").show_msg(
				"Kredit abbezahlt: %s" % loan["name"],
				Color.GREEN
			)
	
	# Book transaction
	if total_payment > 0:
		game_manager.book_transaction("Global", -total_payment, "Loan Payments")
	
	# Update credit rating
	_update_credit_rating()
	
	# Check bankruptcy
	_check_bankruptcy()

func _update_credit_rating():
	if game_manager == null:
		return
	
	var cash = game_manager.cash
	var net_worth = cash - total_debt
	
	# Credit rating based on net worth and loan history
	if net_worth > 50000000:
		credit_rating = 1.0
	elif net_worth > 10000000:
		credit_rating = 0.9
	elif net_worth > 5000000:
		credit_rating = 0.7
	elif net_worth > 0:
		credit_rating = 0.5
	elif net_worth > -500000:
		credit_rating = 0.3
	else:
		credit_rating = 0.1

func _check_bankruptcy():
	if game_manager == null:
		return
	
	var net_worth = game_manager.cash - total_debt
	
	if net_worth < 0:
		months_in_debt += 1
		
		# Bankruptcy risk increases with time in debt
		bankruptcy_risk = min(1.0, months_in_debt / 12.0 * abs(net_worth) / 1000000.0)
		
		if bankruptcy_risk > 0.5:
			bankruptcy_warning.emit(bankruptcy_risk)
		
		if bankruptcy_risk >= 1.0:
			_trigger_bankruptcy()
	else:
		months_in_debt = 0
		bankruptcy_risk = 0.0

func _trigger_bankruptcy():
	if game_manager == null:
		return
	
	var msg = "=== BANKROTT ===\n\n"
	msg += "Sie sind bankrott!\n"
	msg += "Schulden: $%s\n" % _fmt(total_debt)
	msg += "Vermögen: $%s\n\n" % _fmt(game_manager.cash)
	msg += "Das Spiel ist vorbei."
	
	if has_node("/root/FeedbackOverlay"):
		get_node("/root/FeedbackOverlay").show_msg(msg, Color.RED)
	
	# Could trigger game over screen here
	print("BANKRUPTCY TRIGGERED!")

# --- GET AVAILABLE OFFERS ---
func get_available_offers() -> Array:
	var offers = []
	
	for offer in LOAN_OFFERS:
		var adjusted_rate = offer["interest_rate"] * (2.0 - credit_rating)
		var principal = offer["principal"] * game_manager.inflation_rate
		
		offers.append({
			"id": offer["id"],
			"name": offer["name"],
			"principal": principal,
			"interest_rate": adjusted_rate,
			"duration_months": offer["duration_months"],
			"monthly_payment": _calculate_monthly_payment(principal, adjusted_rate, offer["duration_months"]),
			"description": offer["description"],
			"can_afford": active_loans.size() < MAX_ACTIVE_LOANS
		})
	
	return offers

# --- EARLY REPAYMENT ---
func early_repay(loan_id: String) -> Dictionary:
	for i in range(active_loans.size()):
		if active_loans[i]["id"] == loan_id:
			var loan = active_loans[i]
			var remaining = loan["remaining"]
			
			# 5% early repayment fee
			var fee = remaining * 0.05
			var total = remaining + fee
			
			if game_manager.cash >= total:
				game_manager.cash -= total
				active_loans.remove_at(i)
				total_debt -= loan["principal"]
				
				# Credit rating bonus for early repayment
				credit_rating = min(1.0, credit_rating + 0.1)
				
				loan_repaid.emit(loan_id)
				
				return {
					"success": true,
					"message": "Kredit vorzeitig getilgt!\nFrühzahlungsgebühr: $%s" % _fmt(fee)
				}
			else:
				return {
					"success": false,
					"message": "Nicht genug Geld für vorzeitige Tilgung"
				}
	
	return {"success": false, "message": "Kredit nicht gefunden"}

# --- GETTERS ---
func get_total_monthly_payments() -> float:
	var total = 0.0
	for loan in active_loans:
		total += loan["monthly_payment"]
	return total

func get_total_debt() -> float:
	return total_debt

func get_net_worth() -> float:
	if game_manager:
		return game_manager.cash - total_debt
	return -total_debt

func get_credit_rating_text() -> String:
	if credit_rating >= 0.9:
		return "Ausgezeichnet"
	elif credit_rating >= 0.7:
		return "Gut"
	elif credit_rating >= 0.5:
		return "Mittel"
	elif credit_rating >= 0.3:
		return "Schlecht"
	else:
		return "Sehr schlecht"

func get_bankruptcy_risk_text() -> String:
	if bankruptcy_risk >= 0.9:
		return "KRITISCH!"
	elif bankruptcy_risk >= 0.7:
		return "Sehr hoch"
	elif bankruptcy_risk >= 0.5:
		return "Hoch"
	elif bankruptcy_risk >= 0.3:
		return "Mittel"
	else:
		return "Niedrig"

func _fmt(value) -> String:
	var s = str(int(value))
	var res = ""
	var counter = 0
	for i in range(s.length() - 1, -1, -1):
		res = s[i] + res
		counter += 1
		if counter % 3 == 0 and i > 0:
			res = "." + res
	return res

# --- SAVE/LOAD ---
func get_save_data() -> Dictionary:
	return {
		"loans": active_loans,
		"credit_rating": credit_rating,
		"total_debt": total_debt,
		"months_in_debt": months_in_debt,
		"bankruptcy_risk": bankruptcy_risk
	}

func load_save_data(data: Dictionary):
	active_loans = data.get("loans", [])
	credit_rating = data.get("credit_rating", 1.0)
	total_debt = data.get("total_debt", 0.0)
	months_in_debt = data.get("months_in_debt", 0)
	bankruptcy_risk = data.get("bankruptcy_risk", 0.0)
