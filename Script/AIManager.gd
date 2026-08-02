extends Node

const API_KEY: String = "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"
const API_URL: String = "https://api.groq.com/openai/v1/chat/completions"
const MODEL: String = "llama-3.3-70b-versatile"

var http_request: HTTPRequest

func _ready() -> void:
	http_request = HTTPRequest.new()
	http_request.timeout = 10.0
	add_child(http_request)

func ask(npc_name: String, personality: String, lore: String, stage_prompt: String, choice_descriptions: Array, memory: Array[Dictionary] = []) -> Dictionary:
	if API_KEY.is_empty():
		return {"dialogue": "Error: API Key missing.", "choices": []}

	var choice_prompt_text := ""
	if not choice_descriptions.is_empty():
		choice_prompt_text = (
			"\nNachiketa has %d possible intents right now. For each one, WRITE the actual line Nachiketa would say — " % choice_descriptions.size() +
			"do not just reword the intent description, invent natural spoken phrasing in his voice (first person, no markdown, under 15 words each). " +
			"Base each line on the CURRENT dialogue history so it responds to what was just said, not a generic template:\n"
		)
		for i in range(choice_descriptions.size()):
			choice_prompt_text += "Intent %d: %s\n" % [i + 1, choice_descriptions[i]]
		choice_prompt_text += (
			"\nThen, AFTER those, improvise ONE extra original follow-up line Nachiketa could plausibly say next, based purely on the " +
			"conversation so far and his personality — something NOT covered by the intents above. This one is fully your own creative addition.\n" +
			"Put all of them, scripted lines first then your improvised one, as one flat list in 'choices' (total %d entries).\n" % (choice_descriptions.size() + 1)
		)

	var system_prompt: String = (
		"You are an NPC named %s in a game based on the Katha Upanishad.\n" % npc_name +
		"Personality:\n%s\n" % personality +
		"Lore:\n%s\n\n" % lore +
		"CURRENT STAGE OBJECTIVE:\n%s\n\n" % stage_prompt +
		"RULES:\n" +
		"1. Keep spoken responses under 30 words. Do NOT use markdown like *smiles*.\n" +
		"2. Speak directly to Nachiketa as your character.\n" +
		"3. The conversation history below already contains everything said so far. Read it before replying.\n" +
		"4. Never repeat a point, question, or line you (or Nachiketa) already made earlier in the history. Always move the conversation forward and directly answer Nachiketa's latest message.\n" +
		"5. If the CURRENT STAGE OBJECTIVE has already been fulfilled earlier in the history, do not restate it — build on it instead.\n" +
		choice_prompt_text + "\n" +
		"Return ONLY a valid JSON object formatted as:\n" +
		"{\n" +
		'  "dialogue": "NPC response string",\n' +
		'  "choices": ["Generated Choice 1", "Generated Choice 2", "..."]\n' +
		"}"
	)

	var messages_payload: Array[Dictionary] = [{"role": "system", "content": system_prompt}]
	messages_payload.append_array(memory)

	var payload: Dictionary = {
		"model": MODEL,
		"messages": messages_payload,
		"temperature": 0.85,
		"response_format": {"type": "json_object"}
	}

	var json_body: String = JSON.stringify(payload)
	var headers: PackedStringArray = [
		"Content-Type: application/json",
		"Authorization: Bearer " + API_KEY
	]

	if http_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		http_request.cancel_request()

	var err: Error = http_request.request(API_URL, headers, HTTPClient.METHOD_POST, json_body)
	if err != OK:
		return {"dialogue": "[Connection Error]", "choices": []}

	var result: Array = await http_request.request_completed
	if result[0] != HTTPRequest.RESULT_SUCCESS or result[1] != 200:
		return {"dialogue": "... (The NPC stays silent)", "choices": []}

	var json: JSON = JSON.new()
	if json.parse(result[3].get_string_from_utf8()) == OK:
		var data = json.data
		if data is Dictionary and data.has("choices") and data["choices"].size() > 0:
			var raw_content: String = data["choices"][0].get("message", {}).get("content", "")
			var parsed_response: JSON = JSON.new()
			if parsed_response.parse(raw_content) == OK and parsed_response.data is Dictionary:
				return parsed_response.data

	return {"dialogue": "...", "choices": []}
