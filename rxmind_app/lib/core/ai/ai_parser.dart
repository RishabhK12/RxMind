class AiParser {
  static Map<String, dynamic> validateJson(Map<String, dynamic>? json) {
    if (json == null)
      return {
        'restrictions': [],
        'medications': [],
        'tasks': [],
        'followups': []
      };
    final keys = ['restrictions', 'medications', 'tasks', 'followups'];
    for (final key in keys) {
      if (!json.containsKey(key)) {
        json[key] = [];
      }
    }
    return json;
  }
}
