import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/models.dart';
import 'services/firebase_service.dart';
import 'services/printer_service.dart';
import 'views/tables_view.dart';
import 'views/tasks_view.dart';
import 'views/store_view.dart';
import 'views/admin_view.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UYÊN COFFEE POS PRO',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5D3FD3),
          primary: const Color(0xFF5D3FD3),
        ),
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentTabIndex = 0; // 0: Bàn, 1: Việc, 2: Cửa hàng, 3: Admin/Cài đặt

  final FirebaseService _firebaseService = FirebaseService();
  final PrinterService _printerService = PrinterService();

  String _currentDeviceId = '';
  String _currentDevicePass = '';
  String _currentStaffName = 'Admin';
  String _currentUserRole = 'Phục vụ';

  bool _isAdminLoggedIn = false;
  bool _isDeviceRegistered = false;

  Map<String, DeviceModel> _allDevices = {};
  ShiftModel? _activeShift;
  String _regCode = '';
  String _qrUrl = '';
  List<EditLogModel> _editLogs = [];
  Map<String, ShiftLogModel> _shiftLogs = {};
  Map<String, MenuItemModel> _menuMap = {};

  // Controllers for registration screen persistent state
  final TextEditingController _regNameController = TextEditingController();
  final TextEditingController _regPassController = TextEditingController();
  final TextEditingController _regCodeController = TextEditingController();

  // Track printed items/tables to avoid duplicate prints
  final Set<String> _printedItemKeys = {};

  @override
  void initState() {
    super.initState();
    _loadDeviceCredentials();
    _firebaseService.startListening();

    _firebaseService.devicesStream.listen((devices) {
      if (mounted) {
        setState(() {
          _allDevices = devices;
          _checkAuthStatus();
        });
      }
    });

    _firebaseService.tablesStream.listen((tables) {
      _handleRealtimePrintForTables(tables);
    });

    _firebaseService.shiftStream.listen((shift) {
      if (mounted) setState(() => _activeShift = shift);
    });

    _firebaseService.regCodeStream.listen((code) {
      if (mounted) setState(() => _regCode = code);
    });

    _firebaseService.qrUrlStream.listen((url) {
      if (mounted) setState(() => _qrUrl = url);
    });

    _firebaseService.editLogsStream.listen((logs) {
      if (mounted) setState(() => _editLogs = logs);
    });

    _firebaseService.shiftLogsStream.listen((logs) {
      if (mounted) setState(() => _shiftLogs = logs);
    });

    _firebaseService.menuStream.listen((menu) {
      if (mounted) setState(() => _menuMap = menu);
    });
  }

  /// Automatically print kitchen ticket/bill when a table status changes or new items confirmed
  void _handleRealtimePrintForTables(Map<int, TableModel> tables) {
    for (var table in tables.values) {
      if (table.status == 'red' && !table.printed && table.items.isNotEmpty) {
        final printKey = 'table_${table.id}_${table.items.length}_${table.total}';
        if (!_printedItemKeys.contains(printKey)) {
          _printedItemKeys.add(printKey);

          // Trigger print via USB Printer
          _printerService.printReceipt(
            storeName: 'UYÊN COFFEE',
            tableName: 'Bàn ${table.id}',
            time: table.startTime ?? 'N/A',
            staffName: _currentStaffName,
            items: table.items.map((e) => e.toJson()).toList(),
            total: table.total,
            payMethod: '',
          );

          // Mark printed on Firebase
          _firebaseService.updateTable(table.id, {'printed': true});
        }
      }
    }
  }

  Future<void> _loadDeviceCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentDeviceId = prefs.getString('uc_dev_id') ?? '';
      _currentDevicePass = prefs.getString('uc_dev_pass') ?? '';
    });
    _checkAuthStatus();
  }

  void _checkAuthStatus() {
    if (_isAdminLoggedIn) {
      _isDeviceRegistered = true;
      _currentUserRole = 'Quản lý';
      return;
    }

    if (_currentDeviceId.isNotEmpty && _allDevices.containsKey(_currentDeviceId)) {
      final dev = _allDevices[_currentDeviceId]!;
      if (dev.password == _currentDevicePass) {
        _isDeviceRegistered = true;
        _currentStaffName = dev.name;
        _currentUserRole = dev.role;
        return;
      }
    }

    _isDeviceRegistered = false;
  }

  @override
  void dispose() {
    _regNameController.dispose();
    _regPassController.dispose();
    _regCodeController.dispose();
    _firebaseService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isDeviceRegistered) {
      return _buildRegistrationScreen();
    }

    // Map BottomNavigationBar index (0: Bàn, 1: Cửa hàng) to Stack index (0, 2)
    int bottomNavIndex = 0;
    if (_currentTabIndex == 2) {
      bottomNavIndex = 1;
    } else if (_currentTabIndex == 1 || _currentTabIndex == 3) {
      bottomNavIndex = 0;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('UYÊN COFFEE', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF5D3FD3), letterSpacing: 1)),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.assignment_outlined, size: 18),
            label: const Text('📋 VIỆC', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            onPressed: () => setState(() => _currentTabIndex = 1),
          ),
          TextButton.icon(
            icon: const Icon(Icons.settings_outlined, size: 18),
            label: const Text('⚙️ QUẢN LÝ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            onPressed: _accessAdmin,
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentTabIndex,
        children: [
          TablesView(
            firebaseService: _firebaseService,
            printerService: _printerService,
            currentUserRole: _currentUserRole,
            currentStaffName: _currentStaffName,
            activeShift: _activeShift,
            qrUrl: _qrUrl,
          ),
          TasksView(
            firebaseService: _firebaseService,
            currentUserRole: _currentUserRole,
            currentDeviceId: _currentDeviceId,
            devices: _allDevices,
          ),
          StoreView(
            firebaseService: _firebaseService,
            activeShift: _activeShift,
            editLogs: _editLogs,
            shiftLogs: _shiftLogs,
            menuMap: _menuMap,
          ),
          AdminView(
            firebaseService: _firebaseService,
            printerService: _printerService,
            devices: _allDevices,
            currentRegCode: _regCode,
            shiftLogs: _shiftLogs,
            qrUrl: _qrUrl,
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: bottomNavIndex,
        selectedItemColor: const Color(0xFF5D3FD3),
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _currentTabIndex = index == 0 ? 0 : 2;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.table_restaurant), label: 'BÀN'),
          BottomNavigationBarItem(icon: Icon(Icons.store), label: 'CỬA HÀNG'),
        ],
      ),
    );
  }

  Widget _buildRegistrationScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('KÍCH HOẠT THIẾT BỊ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF5D3FD3))),
                const SizedBox(height: 6),
                const Text('Vui lòng nhập mã đăng ký do quản lý cấp để sử dụng hệ thống.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 20),
                TextField(controller: _regNameController, decoration: const InputDecoration(labelText: 'Tên nhân viên (VD: Lan Anh)', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: _regPassController, obscureText: true, decoration: const InputDecoration(labelText: 'Tạo mật khẩu cá nhân', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: _regCodeController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Mã đăng ký (5 số)', border: OutlineInputBorder())),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5D3FD3), padding: const EdgeInsets.symmetric(vertical: 14)),
                    onPressed: () async {
                      final name = _regNameController.text.trim();
                      final pass = _regPassController.text.trim();
                      final code = _regCodeController.text.trim();

                      if (name.isEmpty || pass.isEmpty || code.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng điền đầy đủ thông tin!')));
                        return;
                      }

                      if (code != _regCode) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mã đăng ký không chính xác hoặc đã hết hạn!')));
                        return;
                      }

                      final newDevId = 'DEV_${DateTime.now().millisecondsSinceEpoch}';
                      final newDev = DeviceModel(
                        id: newDevId,
                        name: name,
                        password: pass,
                        role: 'Phục vụ',
                        createdAt: DateTime.now().toString(),
                      );

                      await _firebaseService.registerDevice(newDev);

                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString('uc_dev_id', newDevId);
                      await prefs.setString('uc_dev_pass', pass);

                      setState(() {
                        _currentDeviceId = newDevId;
                        _currentDevicePass = pass;
                        _isDeviceRegistered = true;
                        _currentStaffName = name;
                        _currentUserRole = 'Phục vụ';
                      });
                    },
                    child: const Text('ĐĂNG KÝ VÀ VÀO CA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _accessAdmin() {
    final passController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Nhập mật khẩu quản lý:'),
          content: TextField(
            controller: passController,
            obscureText: true,
            autofocus: true,
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Hủy')),
            ElevatedButton(
              onPressed: () {
                if (passController.text.trim() == '1905') {
                  setState(() {
                    _isAdminLoggedIn = true;
                    _currentUserRole = 'Quản lý';
                    _currentTabIndex = 3;
                  });
                  Navigator.pop(dialogContext);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sai mật khẩu!')));
                }
              },
              child: const Text('Xác nhận'),
            ),
          ],
        );
      },
    );
  }
}
