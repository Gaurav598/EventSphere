import 'dart:convert';
import 'dart:io';

void main() async {
  final url = Uri.parse('http://localhost:8000/api/v1/events/6a4ba7325948037e2c9d98dd');
  final request = await HttpClient().getUrl(url);
  final response = await request.close();
  final responseBody = await response.transform(utf8.decoder).join();
  print(responseBody);
}
