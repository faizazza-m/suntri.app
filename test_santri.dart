import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  const url = 'https://ncwafymkpxogbjzcpoya.supabase.co/rest/v1/santri?select=id,nama';
  final headers = {
    'apikey':
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5jd2FmeW1rcHhvZ2JqemNwb3lhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODYzMzQ1MTgsImV4cCI6MjEwMTkxMDUxOH0.lPZkCRmrAXV5FuRw0b-j_uJLw-2Hx6mLSFOGZ4oq4SI',
    'Authorization':
        'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5jd2FmeW1rcHhvZ2JqemNwb3lhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODYzMzQ1MTgsImV4cCI6MjEwMTkxMDUxOH0.lPZkCRmrAXV5FuRw0b-j_uJLw-2Hx6mLSFOGZ4oq4SI',
  };

  try {
    final response = await http.get(Uri.parse(url), headers: headers);
    print('Santri: ${response.body}');
  } catch (e) {
    print('Error: $e');
  }
}
