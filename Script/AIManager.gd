extends Node

const API_KEY: String = "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"
const API_URL: String = "https://api.groq.com/openai/v1/chat/completions"
const MODEL: String = "llama-3.3-70b-versatile"

var http_request: HTTPRequest

func _ready() -> void:
	http_request = HTTPRequest.new()
	http_request.timeout = 10.0
	add_child(http_request)

func ask(npc_name: String, personality: String, lore: String, story_goal: String, memory: Array[Dictionary] = []) -> Dictionary:
	if API_KEY.is_empty():
		return {"dialogue": "Error: API Key missing.", "choices": ["Goodbye."], "is_concluded": true}

	var system_prompt: String = (
		"You are an NPC named %s in a game based on the Katha Upanishad.\n" % npc_name +
		"Personality:\n%s\n" % personality +
		"Lore:\n%s\n\n" % lore +
		"STORY OBJECTIVE (Steer conversation toward this goal):\n%s\n\n" % story_goal +
		"RULES:\n" +
		"1. Keep spoken responses under 30 words. Do NOT use markdown like *smiles*.\n" +
		"2. If the story goal has been fully expressed/achieved, set \"is_concluded\" to true and provide NO choices.\n" +
		"3. If the conversation is ongoing, generate 2 to 3 concise player reply choices.\n\n" +
		"Return ONLY a valid JSON object formatted as:\n" +
		"{\n" +
		'  "dialogue": "NPC response string",\n' +
		'  "choices": ["Choice 1", "Choice 2"],\n' +
		'  "is_concluded": false\n' +
		"}"
	)

	var messages_payload: Array[Dictionary] = [{"role": "system", "content": system_prompt}]
	messages_payload.append_array(memory)

	var payload: Dictionary = {
		"model": MODEL,
		"messages": messages_payload,
		"temperature": 0.7,
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
		return {"dialogue": "[Connection Error]", "choices": ["Goodbye."], "is_concluded": true}

	var result: Array = await http_request.request_completed
	if result[0] != HTTPRequest.RESULT_SUCCESS or result[1] != 200:
		return {"dialogue": "... (The NPC stays silent)", "choices": ["Goodbye."], "is_concluded": true}

	var json: JSON = JSON.new()
	if json.parse(result[3].get_string_from_utf8()) == OK:
		var data = json.data
		if data is Dictionary and data.has("choices") and data["choices"].size() > 0:
			var raw_content: String = data["choices"][0].get("message", {}).get("content", "")
			var parsed_response: JSON = JSON.new()
			if parsed_response.parse(raw_content) == OK and parsed_response.data is Dictionary:
				return parsed_response.data

	return {"dialogue": "...", "choices": ["Goodbye."], "is_concluded": true}
