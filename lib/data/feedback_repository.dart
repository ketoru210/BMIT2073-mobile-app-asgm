import 'package:supabase_flutter/supabase_flutter.dart';

class FeedbackRepository {
  FeedbackRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<void> submit({
    required String category,
    required String subject,
    required String message,
  }) async {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw StateError('You must be signed in.');
    }

    final email = user.email;
    if (email == null || email.isEmpty) {
      throw StateError('Your account does not have an email address.');
    }

    await _client.from('feedback').insert({
      'user_id': user.id,
      'submitter_email': email,
      'category': category,
      'subject': subject.trim(),
      'message': message.trim(),
    });
  }

  Future<List<Map<String, dynamic>>> getAll() async {
    return _client
        .from('feedback')
        .select()
        .order('created_at', ascending: false);
  }

  Future<void> updateStatus({
    required String id,
    required String status,
    String? adminNote,
  }) async {
    await _client.from('feedback').update({
      'status': status,
      'admin_note': adminNote,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }
}