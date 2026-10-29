extends Node3D

@export var dialouge_status: int = 0

# voice values here
var sherif_voice: Array = [92.0, 0.55, 0.10, 0.55, -9.0]

var lines: Array = [

	# ==================== SCENE 1: PROLOGUE ====================

	# Detective (inner monologue) - after sitting down at the table.
	# 0 The lens-jingle sound plays before the last phrase; player then gets control.
	[
		"A complete renovation.",
		"Everything sparkles, squeaky clean, modern...",
		"Nothing like the old Sables de Mars that burned down to the ground.",
		"Better double-check that everything is in working order."
	],

	# 1 Detective (inner monologue) - tutorial, no lens (base mode).
	[
		"The ordinary physical world.",
		"Clean, neat, completely unremarkable.",
		"Time to switch lenses."
	],

	# 2 Detective (inner monologue) - tutorial, green lens enabled.
	[
		"Green filter.",
		"Excellent for highlighting mechanical parts, object structures, and signs of wear.",
		"Perfect for spotting recent repairs or forced break-ins."
	],

	# 3 Detective (inner monologue) - tutorial, red lens enabled.
	[
		"Red filter.",
		"Organic traces, blood, biological tissues.",
		"Clean for now... hopefully."
	],

	# 4 Detective (inner monologue) - tutorial, blue lens enabled (Waiter #1 approaches).
	[
		"Blue filter.",
		"Information networks and connections.",
		"Looks like someone on the staff wants to talk to me."
	],

	# ==================== SCENE 2: SETUP ====================

	# 5 Waiter #1 (panicking) - runs up to the table while the blue lens is on.
	[
		"I'm sorry, I'm sorry!",
		"You're... you're that detective from the news, right?",
		"Mercier?"
	],

	# 6 Detective (calmly)
	[
		"Suppose I am.",
		"What happened?",
		"You look like you've seen a ghost."
	],

	# 7 Waiter #1 (lowering his voice)
	[
		"Some shady character just slipped into the back rooms,",
		"and a minute later, he bolted out of the manager's office like a bat out of hell,",
		"heading straight for the park!",
		"I think he stole something!"
	],

	# 8 Detective
	[
		"Call the police, or tell the manager."
	],

	# 9 Waiter #1
	[
		"The manager strictly forbids anyone near his office!",
		"Even calling the cops has to go through him.",
		"But he's not picking up his phone.",
		"Regular staff aren't even allowed within ten feet of the door,",
		"we'd get fired on the spot.",
		"But you... you're a professional.",
		"Can you just take a quick look before the boss gets back?",
		"Otherwise, we're all screwed."
	],

	# 10 Detective (standing up from the table with a faint smirk)
	[
		"The manager's office...",
		"Lead the way."
	],

	# ==================== SCENE 3: MANAGER'S OFFICE ====================

	# 11 Waiter #1 (turning to face the detective) - at the office door by the counter.
	[
		"You're on your own from here.",
		"Please, try to figure out what was stolen as fast as you can!"
	],

	# 12 Detective (stepping into the office) - music changes after this line.
	[
		"I'll do what I can."
	],

	# --- Storage room (found behind the wall) ---

	# 13 Detective - the moment the body is revealed (music stops / white noise).
	[
		"…"
	],

	# 14 Detective - green lens, clicks the safe.
	[
		"Nothing inside.",
		"The killer might have taken something from it."
	],

	# 15 Detective - green lens, picks up the keys.
	[
		"The keys are probably from the restaurant's lock."
	],

	# 16 Detective - red lens, clicks the blood stains.
	[
		"The blow was struck in a hurry.",
		"The wallpaper and shelves are splattered.",
		"He was trying to defend himself or grabbing at the racks before falling.",
		"The killer acted in a panic."
	],

	# 17 Detective - blue lens, clicks the body (laughter is heard first).
	[
		"...",
		"It's the manager himself.",
		"He was killed just a moment ago.",
		"There's no pulse."
	],

	# --- Back in the office ---

	# 18 Detective - green lens, clicks the window.
	[
		"The window was opened from the inside, but someone used it to climb out.",
		"Into the courtyard."
	],

	# 19 Detective - green lens, clicks the computer.
	[
		"The manager was doing routine work up until the incident."
	],

	# 20 Detective - green lens, clicks the shelves on the left.
	[
		"The personnel files were out of order.",
		"Someone was digging around for a specific paper and left a mess behind."
	],

	# 21 Detective - red lens, clicks the blood stains in the office.
	[
		"The manager's blood."
	],

	# --- Back in the main hall (restaurant music returns) ---

	# 22 Waiter #1 (standing near the door)
	[
		"So?",
		"Did you find anything?",
		"Is everything okay?",
		"The manager usually comes around this time!"
	],

	# 23 Detective (calmly)
	[
		"Some documents are missing.",
		"But don't panic.",
		"It'll be easier to continue the investigation if everyone stays calm.",
		"Which staff members should I talk to?"
	],

	# 24 Waiter #1
	[
		"Well, if you're looking for a thief...",
		"you'd better ask our regular customer.",
		"He's been sitting here since this morning,",
		"so he might have seen someone.",
		"And you can also drop by the kitchen to check on the chef.",
		"He's always keeping an eye on everything and everyone."
	],

	# 25 Detective (inner monologue) - end of scene 3.
	[
		"Better play along and act like I'm hunting a common thief while I question them all.",
		"I need to dig deeper into their relationship with the manager and uncover more about the killer."
	],

	# ==================== SCENE 4: QUESTIONING STAFF ====================

	# --- Waiter #1 (blue lens, by the manager's door) ---

	# 26 Detective
	[
		"The guy who ran out.",
		"Have you seen him among the guests before?"
	],

	# 27 Waiter #1
	[
		"No.",
		"A total stranger.",
		"Honestly, I didn't see anyone lurking around the office.",
		"You'd better ask our regular guest."
	],

	# --- Regular Guest (blue lens, table by the window) ---

	# 28 Detective
	[
		"Good afternoon.",
		"They say you're a big fan of the local cuisine.",
		"Did you notice anything out of the ordinary this morning?"
	],

	# 29 Regular Guest
	[
		"Oh, son...",
		"Something out of the ordinary?",
		"You know the manager around here.",
		"A real beast of a man, always yelling at the staff and threatening to fire people.",
		"And today, I didn't see him at all.",
		"But I did see one of the new waiters, such a quiet lad, walking around looking pale,",
		"like he was sick or something happened to him.",
		"Ah, poor boy, the manager probably gave it to him good...",
		"Oh, what a disaster."
	],

	# --- Chef (blue lens, kitchen) ---

	# 30 Detective
	[
		"Chef, how's the atmosphere among the staff?",
		"Was the manager pressing the team hard?"
	],

	# 31 Chef (angrily)
	[
		"Pressure?",
		"The man didn't view us as human beings.",
		"Yesterday he was screaming at everyone again, threatening to slash bonuses over some inventory shortfall.",
		"But our poor rookie, Arthur, got the worst of it.",
		"He's been walking on eggshells since yesterday",
		"…",
		"Wonder where he ran off to anyway...",
		"whatever."
	],

	# --- Scared Cook (blue lens, far corner of the kitchen; appears after talking to the Chef) ---

	# 32 Cook (scared)
	[
		"Sorry!",
		"It was an accident, I'll fix everything!"
	],

	# 33 Detective
	[
		"Pardon?"
	],

	# 34 Cook
	[
		"Oh... sorry.",
		"I thought you were the manag...",
		"...",
		"Sorry, I need to get back to work."
	],

	# ==================== SCENE 5: COURTYARD ====================
	# (no spoken dialogue in this scene)

	# ==================== SCENE 6: FINALE (park) ====================

	# 35 Waiter #2 (whispering) - found hiding behind the tree.
	[
		"Stay back!",
		"Please!",
		"I didn't want to!",
		"He... he brought this on himself!",
		"That bastard was blackmailing me, threatening to kill my family over debts, forcing me to run his damn illegal trade!",
		"When I tried to walk away, he... he grabbed the knife himself!",
		"I was just defending myself..."
	],

	# 36 Detective
	[
		"..."
	],

	# 37 Waiter #2
	[
		"Detective... Mercier... you used to... you used to work at this place too!",
		"Before the incident.",
		"I saw your personal file.",
		"You understand me...",
		"you knew what that tyrant was like."
	],

	# 38 Detective - reveals his backstory; leads into the ending choice.
	[
		"...",
		"That was years ago.",
		"...",
		"That scum decided other people's lives meant nothing and rigged a gas explosion in the kitchen.",
		"He took my sight just for being in the wrong place at the wrong time.",
		"I came here to put him behind bars the legal way...",
		"...",
		"But you beat me to it."
	],

	# --- ENDING 1: Hand Over the Criminal ---

	# 39 Detective - after choosing option 1.
	[
		"Enough excuses.",
		"The law is the law."
	],

	# 40 Detective - on the phone with the police, walking out of the park.
	[
		"Restaurant Sables de Mars.",
		"A manager was murdered an hour ago.",
		"The killer is in custody.",
		"Send a unit."
	],

	# --- ENDING 2: Help the Killer ---

	# 41 Detective - after choosing option 2, in the park.
	[
		"...",
		"Sit here.",
		"Don't go anywhere."
	],

	# 42 Waiter #2 (surprised)
	[
		"You...",
		"you're not turning me in?"
	],

	# 43 Detective
	[
		"I said sit tight.",
		"I'm going to help you."
	],

	# 44 Waiter #1 - detective is back in the restaurant.
	[
		"Did you find the thief?"
	],

	# 45 Detective
	[
		"Not yet.",
		"The thief slipped away into the park.",
		"However, I'll brief your manager and take full responsibility for it."
	],

	# 46 Waiter #1
	[
		"Maybe... maybe we shouldn't tell the manager?"
	],

	# 47 Detective (stepping closer) - last line before the clock sequence.
	[
		"I said I'm taking full responsibility.",
		"None of this will touch you or the rest of the staff.",
		"And keep your voice down.",
		"No panic, and don't breathe a word of what happened today to anyone."
	]
]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	await _dialouge_talk(sherif_voice, "Detective", lines[0])
	await _dialouge_talk(sherif_voice, "Detective", lines[1])
	await _dialouge_talk(sherif_voice, "#%$^!", ["Press 1, 2, 3 and 4 to change lenses."])
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(_delta: float) -> void:

		
	
func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().paused = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _dialouge_talk(voice: Array, speaker: String, line: Array):
	VoiceSynth.set_voice.callv(voice)
	await Dialogue.say(line, speaker)
