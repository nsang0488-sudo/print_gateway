import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class FirebaseService {
  static const String databaseUrl =
      'https://uyencoffeepos-default-rtdb.asia-southeast1.firebasedatabase.app';

  Timer? _pollingTimer;

  // Stream controllers
  final _tablesController = StreamController<Map<int, TableModel>>.broadcast();
  final _menuController = StreamController<Map<String, MenuItemModel>>.broadcast();
  final _shiftController = StreamController<ShiftModel?>.broadcast();
  final _devicesController = StreamController<Map<String, DeviceModel>>.broadcast();
  final _regCodeController = StreamController<String>.broadcast();
  final _qrUrlController = StreamController<String>.broadcast();
  final _editLogsController = StreamController<List<EditLogModel>>.broadcast();
  final _shiftLogsController = StreamController<Map<String, ShiftLogModel>>.broadcast();

  Stream<Map<int, TableModel>> get tablesStream => _tablesController.stream;
  Stream<Map<String, MenuItemModel>> get menuStream => _menuController.stream;
  Stream<ShiftModel?> get shiftStream => _shiftController.stream;
  Stream<Map<String, DeviceModel>> get devicesStream => _devicesController.stream;
  Stream<String> get regCodeStream => _regCodeController.stream;
  Stream<String> get qrUrlStream => _qrUrlController.stream;
  Stream<List<EditLogModel>> get editLogsStream => _editLogsController.stream;
  Stream<Map<String, ShiftLogModel>> get shiftLogsStream => _shiftLogsController.stream;

  void startListening() {
    _fetchData();
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _fetchData();
    });
  }

  void stopListening() {
    _pollingTimer?.cancel();
  }

  Future<void> _fetchData() async {
    try {
      final res = await http.get(Uri.parse('$databaseUrl/.json'));
      if (res.statusCode == 200 && res.body.isNotEmpty && res.body != 'null') {
        final data = json.decode(res.body) as Map<String, dynamic>;

        // Parse tables
        Map<int, TableModel> tables = {};
        if (data['tables'] != null && data['tables'] is Map) {
          (data['tables'] as Map).forEach((k, v) {
            int? id = int.tryParse(k.toString());
            if (id != null && v is Map) {
              tables[id] = TableModel.fromJson(id, Map<String, dynamic>.from(v));
            }
          });
        }
        _tablesController.add(tables);

        // Parse menu
        Map<String, MenuItemModel> menu = {};
        if (data['menu'] != null && data['menu'] is Map) {
          (data['menu'] as Map).forEach((k, v) {
            if (v is Map) {
              menu[k.toString()] = MenuItemModel.fromJson(k.toString(), Map<String, dynamic>.from(v));
            }
          });
        }
        _menuController.add(menu);

        // Parse active shift
        if (data['active_shift'] != null && data['active_shift'] is Map) {
          _shiftController.add(ShiftModel.fromJson(Map<String, dynamic>.from(data['active_shift'])));
        } else {
          _shiftController.add(null);
        }

        // Parse devices
        Map<String, DeviceModel> devices = {};
        if (data['devices'] != null && data['devices'] is Map) {
          (data['devices'] as Map).forEach((k, v) {
            if (v is Map) {
              devices[k.toString()] = DeviceModel.fromJson(k.toString(), Map<String, dynamic>.from(v));
            }
          });
        }
        _devicesController.add(devices);

        // Parse settings
        if (data['settings'] != null && data['settings'] is Map) {
          _regCodeController.add(data['settings']['regCode']?.toString() ?? 'Chưa có');
          _qrUrlController.add(data['settings']['qrUrl']?.toString() ?? '');
        }

        // Parse edit logs
        List<EditLogModel> logs = [];
        if (data['edit_logs'] != null && data['edit_logs'] is Map) {
          for (var v in (data['edit_logs'] as Map).values) {
            if (v is Map) {
              logs.add(EditLogModel.fromJson(Map<String, dynamic>.from(v)));
            }
          }
        }
        _editLogsController.add(logs.reversed.toList());

        // Parse shift logs
        Map<String, ShiftLogModel> shiftLogs = {};
        if (data['shift_logs'] != null && data['shift_logs'] is Map) {
          (data['shift_logs'] as Map).forEach((k, v) {
            if (v is Map) {
              shiftLogs[k.toString()] = ShiftLogModel.fromJson(k.toString(), Map<String, dynamic>.from(v));
            }
          });
        }
        _shiftLogsController.add(shiftLogs);
      }
    } catch (_) {
      // Network/parse error ignored during polling
    }
  }

  // Database operations via REST API
  Future<void> updateTable(int tableId, Map<String, dynamic> data) async {
    await http.patch(
      Uri.parse('$databaseUrl/tables/$tableId.json'),
      body: json.encode(data),
    );
    _fetchData();
  }

  Future<void> setTable(int tableId, Map<String, dynamic> data) async {
    await http.put(
      Uri.parse('$databaseUrl/tables/$tableId.json'),
      body: json.encode(data),
    );
    _fetchData();
  }

  Future<void> removeTable(int tableId) async {
    await http.delete(Uri.parse('$databaseUrl/tables/$tableId.json'));
    _fetchData();
  }

  Future<void> addMenuItem(MenuItemModel item) async {
    await http.post(
      Uri.parse('$databaseUrl/menu.json'),
      body: json.encode(item.toJson()),
    );
    _fetchData();
  }

  Future<void> updateMenuItem(String key, Map<String, dynamic> data) async {
    await http.patch(
      Uri.parse('$databaseUrl/menu/$key.json'),
      body: json.encode(data),
    );
    _fetchData();
  }

  Future<void> removeMenuItem(String key) async {
    await http.delete(Uri.parse('$databaseUrl/menu/$key.json'));
    _fetchData();
  }

  Future<void> startShift() async {
    final now = DateTime.now();
    final timeStr = '${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute.toString().padLeft(2, '0')}';
    await http.put(
      Uri.parse('$databaseUrl/active_shift.json'),
      body: json.encode({
        'start': timeStr,
        'revenue': 0,
        'revenueCash': 0,
        'revenueTransfer': 0,
      }),
    );
    _fetchData();
  }

  Future<void> endShift(ShiftModel shift) async {
    final now = DateTime.now();
    final endStr = '${now.hour}:${now.minute.toString().padLeft(2, '0')}';
    final dateStr = '${now.day}/${now.month}/${now.year}';

    final shiftLog = {
      'start': shift.start,
      'end': endStr,
      'date': dateStr,
      'revenue': shift.revenue,
      'revenueCash': shift.revenueCash,
      'revenueTransfer': shift.revenueTransfer,
      'timestamp': now.millisecondsSinceEpoch,
    };

    await http.post(
      Uri.parse('$databaseUrl/shift_logs.json'),
      body: json.encode(shiftLog),
    );
    await http.delete(Uri.parse('$databaseUrl/active_shift.json'));
    await http.delete(Uri.parse('$databaseUrl/tables.json'));
    _fetchData();
  }

  Future<void> addBillToShift({
    required BillHistoryModel bill,
    required double currentRevenue,
    required double currentCash,
    required double currentTransfer,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final isCash = bill.method == 'cash';

    Map<String, dynamic> updates = {
      'active_shift/history/$timestamp': bill.toJson(),
      'active_shift/revenue': currentRevenue + bill.total,
      if (isCash) 'active_shift/revenueCash': currentCash + bill.total,
      if (!isCash) 'active_shift/revenueTransfer': currentTransfer + bill.total,
    };

    await http.patch(
      Uri.parse('$databaseUrl/.json'),
      body: json.encode(updates),
    );
    _fetchData();
  }

  Future<void> logEditHistory(EditLogModel log) async {
    await http.post(
      Uri.parse('$databaseUrl/edit_logs.json'),
      body: json.encode(log.toJson()),
    );
    await http.post(
      Uri.parse('$databaseUrl/active_shift/edit_history.json'),
      body: json.encode(log.toJson()),
    );
    _fetchData();
  }

  Future<void> registerDevice(DeviceModel device) async {
    await http.put(
      Uri.parse('$databaseUrl/devices/${device.id}.json'),
      body: json.encode(device.toJson()),
    );
    _fetchData();
  }

  Future<void> updateDeviceRole(String key, String newRole) async {
    await http.patch(
      Uri.parse('$databaseUrl/devices/$key.json'),
      body: json.encode({'role': newRole}),
    );
    _fetchData();
  }

  Future<void> removeDevice(String key) async {
    await http.delete(Uri.parse('$databaseUrl/devices/$key.json'));
    _fetchData();
  }

  Future<void> setRegCode(String code) async {
    await http.put(
      Uri.parse('$databaseUrl/settings/regCode.json'),
      body: json.encode(code),
    );
    _fetchData();
  }

  Future<void> setQrUrl(String url) async {
    await http.put(
      Uri.parse('$databaseUrl/settings/qrUrl.json'),
      body: json.encode(url),
    );
    _fetchData();
  }

  Future<void> addTask(String employeeKey, TaskModel task) async {
    await http.post(
      Uri.parse('$databaseUrl/tasks/$employeeKey.json'),
      body: json.encode(task.toJson()),
    );
    _fetchData();
  }

  Future<void> deleteTask(String employeeKey, String taskId) async {
    await http.delete(Uri.parse('$databaseUrl/tasks/$employeeKey/$taskId.json'));
    _fetchData();
  }

  Future<void> updateTaskStatus(String employeeKey, String taskId, bool done) async {
    await http.patch(
      Uri.parse('$databaseUrl/tasks/$employeeKey/$taskId.json'),
      body: json.encode({'done': done}),
    );
    _fetchData();
  }

  Future<Map<String, TaskModel>> getTasksForEmployee(String employeeKey) async {
    try {
      final res = await http.get(Uri.parse('$databaseUrl/tasks/$employeeKey.json'));
      if (res.statusCode == 200 && res.body.isNotEmpty && res.body != 'null') {
        final Map<String, dynamic> data = json.decode(res.body);
        Map<String, TaskModel> tasks = {};
        data.forEach((k, v) {
          if (v is Map) {
            tasks[k] = TaskModel.fromJson(k, Map<String, dynamic>.from(v));
          }
        });
        return tasks;
      }
    } catch (_) {}
    return {};
  }

  void dispose() {
    _pollingTimer?.cancel();
    _tablesController.close();
    _menuController.close();
    _shiftController.close();
    _devicesController.close();
    _regCodeController.close();
    _qrUrlController.close();
    _editLogsController.close();
    _shiftLogsController.close();
  }
}
