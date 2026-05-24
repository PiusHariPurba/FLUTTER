import 'package:flutter/foundation.dart';
import '../services/task_service.dart';

/// Provider task/proyek — mengelola state list task, create, update, delete.
/// Data diambil dari Laravel API via TaskService.
class TaskProvider extends ChangeNotifier {
  final TaskService _svc = TaskService();

  List<Map<String, dynamic>> _tasks = [];
  Map<String, dynamic>? _currentTask;
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMore = true;

  // Getters
  List<Map<String, dynamic>> get tasks => _tasks;
  Map<String, dynamic>? get currentTask => _currentTask;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMore => _hasMore;

  /// Load task list (halaman pertama)
  Future<void> loadTasks({String? status, String? category, String? search}) async {
    _isLoading = true;
    _currentPage = 1;
    _error = null;
    notifyListeners();

    final res = await _svc.getTasks(
      status: status, category: category, search: search, page: 1);

    if (res.success) {
      final paginated = res['data'];
      _tasks = List<Map<String, dynamic>>.from(paginated?['data'] ?? []);
      _hasMore = paginated?['next_page_url'] != null;
    } else {
      _error = res.message;
    }
    _isLoading = false;
    notifyListeners();
  }

  /// Load more (halaman berikutnya — infinite scroll)
  Future<void> loadMore({String? status, String? category, String? search}) async {
    if (!_hasMore || _isLoading) return;
    _currentPage++;
    _isLoading = true;
    notifyListeners();

    final res = await _svc.getTasks(
      status: status, category: category, search: search, page: _currentPage);

    if (res.success) {
      final paginated = res['data'];
      _tasks.addAll(List<Map<String, dynamic>>.from(paginated?['data'] ?? []));
      _hasMore = paginated?['next_page_url'] != null;
    }
    _isLoading = false;
    notifyListeners();
  }

  /// Load detail satu task
  Future<void> loadTask(int id) async {
    _isLoading = true;
    notifyListeners();

    final res = await _svc.getTask(id);
    if (res.success) {
      _currentTask = Map<String, dynamic>.from(res['data'] ?? {});
    } else {
      _error = res.message;
    }
    _isLoading = false;
    notifyListeners();
  }

  /// Create task baru (client)
  Future<bool> createTask({
    required String title,
    required String description,
    String? category,
    double? budgetMin,
    double? budgetMax,
    String? deadline,
    List<String>? skills,
  }) async {
    final res = await _svc.createTask(
      title: title, description: description, category: category,
      budgetMin: budgetMin, budgetMax: budgetMax, deadline: deadline,
      requiredSkills: skills);

    if (res.success) {
      await loadTasks(); // Refresh list
      return true;
    }
    _error = res.message;
    notifyListeners();
    return false;
  }

  /// Update task (client, pemilik)
  Future<bool> updateTask(int id, {String? title, String? status}) async {
    final res = await _svc.updateTask(id, title: title, status: status);
    if (res.success) {
      await loadTasks();
      return true;
    }
    _error = res.message;
    notifyListeners();
    return false;
  }

  /// Delete task
  Future<bool> deleteTask(int id) async {
    final res = await _svc.deleteTask(id);
    if (res.success) {
      _tasks.removeWhere((t) => t['id'] == id);
      notifyListeners();
      return true;
    }
    _error = res.message;
    notifyListeners();
    return false;
  }
}
