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

## Sends conversation history to Groq and expects JSON containing dialogue & generated player choices.
func ask(npc_name: String, personality: String, lore: String, memory: Array[Dictionary] = []) -> Dictionary:
	if API_KEY.is_empty() or API_KEY == "gsk_YOUR_GROQ_API_KEY_HERE":
		push_error("AIManager: API Key is missing!")
		return {"dialogue": "Error: API Key is missing.", "choices": ["Goodbye."]}

	var system_prompt: String = (
		"You are an NPC named %s in a video game.\n" % npc_name +
		"Personality:\n%s\n" % personality +
		"Lore:\n%s\n\n" % lore +
		"Respond naturally in character. Keep responses under 35 words. Do NOT use markdown like *smiles*.\n" +
		"Generate 3 natural, concise response/question choices the player could say back to you.\n\n" +
		"CRITICAL: You MUST respond ONLY with a valid JSON object formatted EXACTLY as follows:\n" +
		"{\n" +
		'  "dialogue": "NPC spoken response here",\n' +
		'  "choices": ["Choice option 1", "Choice option 2", "Choice option 3"]\n' +
		"}"
	)

	var messages_payload: Array[Dictionary] = [
		{"role": "system", "content": system_prompt}
	]

	messages_payload.append_array(memory)

	var payload: Dictionary = {
		"model": MODEL,
		"messages": messages_payload,
		"temperature": 0.7,
		"response_format": {"type": "json_object"} # Forces strict JSON format
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
		push_error("AIManager: Request failed to initiate. Error code: %d" % err)
		return {"dialogue": "[Connection Error]", "choices": ["Goodbye."]}

	var result: Array = await http_request.request_completed
	var status: int = result[0]
	var response_code: int = result[1]
	var body: PackedByteArray = result[3]

	if status != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		push_error("AIManager: Request error %d" % response_code)
		return {"dialogue": "... (The NPC stays silent)", "choices": ["Goodbye."]}

	var json: JSON = JSON.new()
	if json.parse(body.get_string_from_utf8()) == OK:
		var data = json.data
		if data is Dictionary and data.has("choices") and data["choices"].size() > 0:
			var raw_content: String = data["choices"][0].get("message", {}).get("content", "")
			
			# Parse inner JSON returned by Llama
			var parsed_response: JSON = JSON.new()
			if parsed_response.parse(raw_content) == OK and parsed_response.data is Dictionary:
				return parsed_response.data

	return {"dialogue": "...", "choices": ["Goodbye."]}
