import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  const url = 'https://ncwafymkpxogbjzcpoya.supabase.co/rest/v1/konsultasi';
  final headers = {
    'apikey':
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5jd2FmeW1rcHhvZ2JqemNwb3lhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODYzMzQ1MTgsImV4cCI6MjEwMTkxMDUxOH0.lPZkCRmrAXV5FuRw0b-j_uJLw-2Hx6mLSFOGZ4oq4SI',
    'Authorization':
        'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5jd2FmeW1rcHhvZ2JqemNwb3lhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODYzMzQ1MTgsImV4cCI6MjEwMTkxMDUxOH0.lPZkCRmrAXV5FuRw0b-j_uJLw-2Hx6mLSFOGZ4oq4SI',
    'Content-Type': 'application/json',
    'Prefer': 'return=representation'
  };

  final data = {
    'santri_id': 1,
    'musyrif_id': 1, // Admin ID
    'wali_id': 2,    // Wali ID
    'topik': 'Konsultasi',
    'status': 'aktif',
  };

  try {
    final response = await http.post(Uri.parse(url), headers: headers, body: jsonEncode(data));
    print('Status: ${response.statusCode}');
    print('Body: ${response.body}');
  } catch (e) {
    print('Error: $e');
  }
}
