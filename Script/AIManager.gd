extends Node

# --- Configuration ---
const API_KEY: String = "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"
const API_URL: String = "https://api.groq.com/openai/v1/chat/completions"
const MODEL: String = "llama-3.3-70b-versatile"

var http_request: HTTPRequest

func _ready() -> void:
	http_request = HTTPRequest.new()
	http_request.timeout = 10.0
	add_child(http_request)

## Sends conversation history to Groq and awaits AI text response.
func ask(npc_name: String, personality: String, lore: String, memory: Array[Dictionary] = []) -> String:
	if API_KEY.is_empty() or API_KEY == "gsk_YOUR_GROQ_API_KEY_HERE":
		push_error("AIManager: API Key is missing!")
		return "Error: API Key is missing."

	var system_prompt: String = (
		"You are an NPC named %s in a game.\n" % npc_name +
		"Personality:\n%s\n" % personality +
		"Lore:\n%s\n" % lore +
		"Respond naturally to the player's message based on past context.\n" +
		"Keep responses short (under 35 words).\n" +
		"Do NOT use markdown or action descriptions like *smiles*.\n" +
		"Return ONLY spoken dialogue."
	)

	var messages_payload: Array[Dictionary] = [
		{"role": "system", "content": system_prompt}
	]

	# Append conversation history safely
	messages_payload.append_array(memory)

	var payload: Dictionary = {
		"model": MODEL,
		"messages": messages_payload,
		"temperature": 0.7
	}

	var json_body: String = JSON.stringify(payload)
	var headers: PackedStringArray = [
		"Content-Type: application/json",
		"Authorization: Bearer " + API_KEY
	]

	# Cancel any stuck request before starting a new one
	if http_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		http_request.cancel_request()

	var err: Error = http_request.request(API_URL, headers, HTTPClient.METHOD_POST, json_body)
	if err != OK:
		push_error("AIManager: Request failed to initiate. Error code: %d" % err)
		return "[Connection Error]"

	var result: Array = await http_request.request_completed
	var status: int = result[0]
	var response_code: int = result[1]
	var body: PackedByteArray = result[3]

	if status != HTTPRequest.RESULT_SUCCESS:
		return "[Request Timed Out]"

	if response_code != 200:
		push_error("AIManager: HTTP Error Code %d" % response_code)
		return "... (The NPC stays silent)"

	var json: JSON = JSON.new()
	if json.parse(body.get_string_from_utf8()) == OK:
		var data = json.data
		if data is Dictionary and data.has("choices") and data["choices"].size() > 0:
			var message: Dictionary = data["choices"][0].get("message", {})
			if message.has("content"):
				return message["content"].strip_edges()

	return "..."
