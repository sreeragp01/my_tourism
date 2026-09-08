class CompanionMessage {
  final String id;
  final String sender; // 'user' or 'ai'
  final String text;
  final String timestamp;
  final String? toolInvoked;
  final Map<String, dynamic>? toolResult;
  final List<String> suggestions;
  final bool safetyVerified;

  const CompanionMessage({
    required this.id,
    required this.sender,
    required this.text,
    required this.timestamp,
    this.toolInvoked,
    this.toolResult,
    this.suggestions = const [],
    this.safetyVerified = true,
  });

  factory CompanionMessage.fromJson(Map<String, dynamic> json) {
    final rawSuggestions = json['suggestions'] as List<dynamic>? ?? [];
    return CompanionMessage(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      sender: json['sender'] as String? ?? 'ai',
      text: json['content'] as String? ?? json['text'] as String? ?? '',
      timestamp: json['timestamp'] as String? ?? 'Just now',
      toolInvoked: json['tool_invoked'] as String?,
      toolResult: json['tool_result'] as Map<String, dynamic>?,
      suggestions: rawSuggestions.map((s) => s.toString()).toList(),
      safetyVerified: json['safety_verified'] as bool? ?? true,
    );
  }
}
