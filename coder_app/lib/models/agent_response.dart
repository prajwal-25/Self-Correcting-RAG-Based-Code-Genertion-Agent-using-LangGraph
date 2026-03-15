// Model for the agent API response
class AgentResponse {
  final String prefix;
  final String imports;
  final String code;
  final int iterations;
  final String error;
  final String threadId;

  const AgentResponse({
    required this.prefix,
    required this.imports,
    required this.code,
    required this.iterations,
    required this.error,
    required this.threadId,
  });

  factory AgentResponse.fromJson(Map<String, dynamic> json) {
    return AgentResponse(
      prefix: json['prefix'] as String? ?? '',
      imports: json['imports'] as String? ?? '',
      code: json['code'] as String? ?? '',
      iterations: json['iterations'] as int? ?? 0,
      error: json['error'] as String? ?? 'none',
      threadId: json['thread_id'] as String? ?? '',
    );
  }

  bool get hasError => error != 'none' && error.isNotEmpty;
}
