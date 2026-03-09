import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class Student {
  final String id;
  final String name;
  final String grade;
  final int stars;
  final int level;
  final String pin;

  Student({
    required this.id,
    required this.name,
    required this.grade,
    this.stars = 0,
    this.level = 1,
    this.pin = '',
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      grade: json['grade'] ?? '',
      stars: json['stars'] ?? 0,
      level: json['level'] ?? 1,
      pin: json['pin'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'grade': grade,
        'stars': stars,
        'level': level,
        'pin': pin,
      };
}

class StudentProvider extends ChangeNotifier {
  static const _baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:3001',
  );
  static const _idleTimeoutMinutes = 5;

  Student? _student;
  int? _sessionId;
  Timer? _idleTimer;

  Student? get student => _student;
  bool get isLoggedIn => _student != null;

  /// PIN-based login: calls the server, stores result locally
  Future<String?> loginWithPin(String pin) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'pin': pin}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _student = Student.fromJson(data['student']);
        _sessionId = data['session_id'];
        await _saveToDisk();
        _resetIdleTimer();
        notifyListeners();
        return null; // success
      } else if (response.statusCode == 401) {
        return 'PIN salah, coba lagi ya!';
      } else {
        return 'Login gagal, coba lagi.';
      }
    } catch (e) {
      return 'Tidak bisa terhubung ke server.';
    }
  }

  /// Legacy login kept for backward compatibility
  Future<void> login(String name, String grade) async {
    final id = '${name.toLowerCase().replaceAll(' ', '_')}_${grade.replaceAll(' ', '')}';
    _student = Student(
      id: id,
      name: name,
      grade: grade,
    );
    await _saveToDisk();
    _resetIdleTimer();
    notifyListeners();
  }

  Future<void> loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('student_json');
    if (json != null) {
      try {
        _student = Student.fromJson(jsonDecode(json));
        _sessionId = prefs.getInt('session_id');
        _resetIdleTimer();
        notifyListeners();
      } catch (_) {
        // Fallback: try legacy format
        final name = prefs.getString('student_name');
        final grade = prefs.getString('student_grade');
        if (name != null && grade != null) {
          final stars = prefs.getInt('student_stars') ?? 0;
          _student = Student(
            id: '${name.toLowerCase().replaceAll(' ', '_')}_${grade.replaceAll(' ', '')}',
            name: name,
            grade: grade,
            stars: stars,
          );
          notifyListeners();
        }
      }
    } else {
      // Try legacy format
      final name = prefs.getString('student_name');
      final grade = prefs.getString('student_grade');
      if (name != null && grade != null) {
        final stars = prefs.getInt('student_stars') ?? 0;
        _student = Student(
          id: '${name.toLowerCase().replaceAll(' ', '_')}_${grade.replaceAll(' ', '')}',
          name: name,
          grade: grade,
          stars: stars,
        );
        notifyListeners();
      }
    }
  }

  void addStars(int count) async {
    if (_student != null) {
      final newStars = _student!.stars + count;
      _student = Student(
        id: _student!.id,
        name: _student!.name,
        grade: _student!.grade,
        stars: newStars,
        level: (newStars ~/ 50) + 1,
        pin: _student!.pin,
      );
      await _saveToDisk();
      notifyListeners();
    }
  }

  /// Reset the idle timer. Call this on any user interaction.
  void resetIdleTimer() => _resetIdleTimer();

  void _resetIdleTimer() {
    _idleTimer?.cancel();
    _idleTimer = Timer(
      const Duration(minutes: _idleTimeoutMinutes),
      () => logout(),
    );
  }

  Future<void> logout() async {
    _idleTimer?.cancel();
    _idleTimer = null;

    // Notify server of session end
    if (_sessionId != null) {
      try {
        await http.post(
          Uri.parse('$_baseUrl/api/auth/logout'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'session_id': _sessionId}),
        );
      } catch (_) {}
    }

    _student = null;
    _sessionId = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('student_json');
    await prefs.remove('session_id');
    // Clean legacy keys too
    await prefs.remove('student_name');
    await prefs.remove('student_grade');
    await prefs.remove('student_stars');
    notifyListeners();
  }

  Future<void> _saveToDisk() async {
    final prefs = await SharedPreferences.getInstance();
    if (_student != null) {
      await prefs.setString('student_json', jsonEncode(_student!.toJson()));
      // Also save legacy keys for backward compat
      await prefs.setString('student_name', _student!.name);
      await prefs.setString('student_grade', _student!.grade);
      await prefs.setInt('student_stars', _student!.stars);
    }
    if (_sessionId != null) {
      await prefs.setInt('session_id', _sessionId!);
    }
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    super.dispose();
  }
}
