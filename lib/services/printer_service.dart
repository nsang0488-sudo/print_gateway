import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_pos_printer_platform/flutter_pos_printer_platform.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrinterService {
  int? vendorId;
  int? productId;
  String printerName = '';
  bool isConnected = false;
  
  PrinterService({this.vendorId, this.productId, this.printerName = ''}) {
    loadSavedPrinterConfig();
  }

  /// Load saved USB printer configuration from SharedPreferences
  Future<void> loadSavedPrinterConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      vendorId = prefs.getInt('uc_printer_vid');
      productId = prefs.getInt('uc_printer_pid');
      printerName = prefs.getString('uc_printer_name') ?? '';
      if (vendorId != null && productId != null && Platform.isAndroid) {
        await connectUsb(vendorId!, productId!, printerName: printerName);
      }
    } catch (_) {}
  }

  /// Save USB printer configuration to SharedPreferences
  Future<void> savePrinterConfig(int vId, int pId, {String name = ''}) async {
    try {
      vendorId = vId;
      productId = pId;
      printerName = name;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('uc_printer_vid', vId);
      await prefs.setInt('uc_printer_pid', pId);
      await prefs.setString('uc_printer_name', name);
    } catch (_) {}
  }

  /// Get list of connected USB printer devices
  Future<List<Map<String, dynamic>>> getUsbDeviceList() async {
    try {
      if (Platform.isAndroid) {
        // Quét danh sách thiết bị USB qua package mới
        List<PrinterDevice> devices = [];
        final completer = Completer<List<PrinterDevice>>();
        
        PrinterManager.instance.discovery(type: PrinterType.usb).listen((device) {
          devices.add(device);
        }, onDone: () {
          if (!completer.isCompleted) completer.complete(devices);
        });

        // Đợi tối đa 2 giây quét thiết bị
        final scannedDevices = await completer.future.timeout(const Duration(seconds: 2), onTimeout: () => devices);

        return scannedDevices.map((d) {
          final vid = d.vendorId;
          final pid = d.productId;
          final name = d.name;
          return {
            'deviceName': name.isNotEmpty ? name : 'USB Printer',
            'vendorId': vid != null ? int.tryParse(vid) ?? 0 : 0,
            'productId': pid != null ? int.tryParse(pid) ?? 0 : 0,
            'printerName': name,
          };
        }).toList();
      } else if (Platform.isWindows) {
        return [
          {'deviceName': 'Xprinter K80 (USB)', 'vendorId': 1001, 'productId': 2002, 'printerName': 'Xprinter'},
          {'deviceName': 'Windows POS USB Printer', 'vendorId': 1002, 'productId': 2003, 'printerName': 'POS-80'}
        ];
      }
    } catch (_) {}
    return [];
  }

  /// Connect to USB printer using vendor ID and product ID
  Future<bool> connectUsb(int vId, int pId, {String printerName = ''}) async {
    await savePrinterConfig(vId, pId, name: printerName);
    if (Platform.isAndroid) {
      try {
        UsbPrinterInput selectedDevice = UsbPrinterInput(
          name: printerName,
          vendorId: vId.toString(),
          productId: pId.toString(),
        );
        await PrinterManager.instance.connect(type: PrinterType.usb, model: selectedDevice);
        isConnected = true;
        return true;
      } catch (_) {
        isConnected = false;
        return false;
    
      }
      
    } else {
      isConnected = true;
      return true;
    }
  }

  /// Convert Vietnamese accents to non-accented string for 80mm ESC/POS compatibility
  static String removeAccents(String str) {
    const vietnamese = [
      'aàáảãạâầấẩẫậăằắẳẵặ',
      'AÀÁẢÃẠÂẦẤẨẪẬĂẰẮẲẴẶ',
      'dđ',
      'DĐ',
      'eèéẻẽẹêềếểễệ',
      'EÈÉẺẼẸÊỀẾỂỄỆ',
      'iìíỉĩị',
      'IÌÍỈĨỊ',
      'oòóỏõọôồốổỗộơờớởỡợ',
      'OÒÓỎÕỌÔỒỐỔỖỘƠỜỚỞỠỢ',
      'uùúủũụưừứửữự',
      'UÙÚỦŨỤƯỪỨỬỮỰ',
      'yỳýỷỹỵ',
      'YỲÝỶỸỴ'
    ];
    String result = str;
    for (var group in vietnamese) {
      final firstChar = group[0];
      for (int i = 1; i < group.length; i++) {
        result = result.replaceAll(group[i], firstChar);
      }
    }
    return result;
  }

  /// Safe ASCII encoder converting any leftover non-ascii char to '?'
  static List<int> safeAsciiEncode(String text) {
    final String cleanText = removeAccents(text);
    final List<int> codeUnits = [];
    for (int i = 0; i < cleanText.length; i++) {
      int code = cleanText.codeUnitAt(i);
      if (code > 127) {
        codeUnits.add(63); // '?'
      } else {
        codeUnits.add(code);
      }
    }
    return codeUnits;
  }

 
  /// Format a bill item row into 48 chars line width for 80mm printer
 
  static String formatLine(String left, String right, {int width = 48}) {
    int spaceCount = width - left.length - right.length;
    if (spaceCount < 1) {
      int maxLeft = width - right.length - 1;
      if (maxLeft > 0) {
        left = left.substring(0, maxLeft);
      }
      spaceCount = 1;
    }
    // Sửa lỗi cú pháp string interpolation cũ
    return '$left${' ' * spaceCount}$right';
  }

  /// Generate raw ESC/POS byte commands for standard K80 (80mm) receipt
  static Uint8List buildReceiptBytes({
    required String storeName,
    required String tableName,
    required String time,
    required String staffName,
    required List<Map<String, dynamic>> items,
    required double total,
    required String payMethod,
  }) {
    final List<int> bytes = [];

    // Initialize printer
    bytes.addAll([0x1B, 0x40]);
   bytes.addAll([0x1B, 0x32]);
    bytes.addAll([0x1B, 0x61, 0x01]); // Center

    // Store Name
    bytes.addAll([0x1D, 0x21, 0x11]);
    bytes.addAll(safeAsciiEncode('${removeAccents(storeName)}\n'));

   bytes.addAll([0x1D, 0x21, 0x00]);
    bytes.addAll(safeAsciiEncode('HOA DON THANH TOAN\n'));
    bytes.addAll(safeAsciiEncode('------------------------------------------------\n'));

    // Left alignment for bill metadata
    bytes.addAll([0x1B, 0x61, 0x00]);
    bytes.addAll(safeAsciiEncode('Ban: ${removeAccents(tableName)}\n'));
    bytes.addAll(safeAsciiEncode('Thoi gian: $time\n'));
    if (staffName.isNotEmpty) {
      bytes.addAll(safeAsciiEncode('Nhan vien: ${removeAccents(staffName)}\n'));
    }
    bytes.addAll(safeAsciiEncode('------------------------------------------------\n'));

    // Column header
    bytes.addAll(safeAsciiEncode('${formatLine('MON AN / SL', 'THANH TIEN')}\n'));
    bytes.addAll(safeAsciiEncode('------------------------------------------------\n'));

    // Items list
    for (var item in items) {
      final String fName = removeAccents(item['fName'] ?? item['name'] ?? 'Mon');
      final int qty = (item['qty'] ?? 1) as int;
      final double price = ((item['price'] ?? 0) as num).toDouble();
      final double subTotal = price * qty;

      final String left = '${qty}x $fName';
      final String right = '${formatCurrency(subTotal)}d';

      bytes.addAll(safeAsciiEncode('${formatLine(left, right)}\n'));

      final String? note = item['note'];
      if (note != null && note.isNotEmpty) {
        bytes.addAll(safeAsciiEncode('   * Ghi chu: ${removeAccents(note)}\n'));
      }
    }

    bytes.addAll(safeAsciiEncode('------------------------------------------------\n'));

    // Right alignment for Total
    bytes.addAll([0x1B, 0x61, 0x02]);

    bytes.addAll([0x1B, 0x45, 0x01]);
    bytes.addAll([0x1D, 0x21, 0x01]);
    bytes.addAll(safeAsciiEncode('TONG CONG: ${formatCurrency(total)}d\n'));
    bytes.addAll([0x1D, 0x21, 0x00]);
    bytes.addAll([0x1B, 0x45, 0x00]);

    if (payMethod.isNotEmpty) {
      final String methodText = payMethod.toLowerCase() == 'transfer' ? 'Chuyen khoan' : 'Tien mat';
      bytes.addAll(safeAsciiEncode('Hinh thuc TT: $methodText\n'));
    }

    bytes.addAll(safeAsciiEncode('------------------------------------------------\n'));

    // Center alignment footer
    bytes.addAll([0x1B, 0x61, 0x01]);
    bytes.addAll(safeAsciiEncode('Cam on Quy khach & Hen gap lai!\n\n\n\n'));
    bytes.addAll([0x1D, 0x56, 0x42, 0x00]); // Cut paper

    return Uint8List.fromList(bytes);
  }

  /// Helper to format currency number e.g. 25000 -> "25,000"
  static String formatCurrency(double amount) {
    final String s = amount.toInt().toString();
    final StringBuffer result = StringBuffer();
    int count = 0;
    for (int i = s.length - 1; i >= 0; i--) {
      result.write(s[i]);
      count++;
      if (count % 3 == 0 && i != 0) {
        result.write(',');
      }
    }
    return result.toString().split('').reversed.join('');
  }

  /// Print receipt bytes to USB printer
  Future<bool> printReceipt({
    required String storeName,
    required String tableName,
    required String time,
    required String staffName,
    required List<Map<String, dynamic>> items,
    required double total,
    required String payMethod,
  }) async {
    final Uint8List data = buildReceiptBytes(
      storeName: storeName,
      tableName: tableName,
      time: time,
      staffName: staffName,
      items: items,
      total: total,
      payMethod: payMethod,
    );

    return await sendRawBytes(data);
  }

  /// Send raw bytes to connected USB printer device
  Future<bool> sendRawBytes(Uint8List data) async {
    if (Platform.isAndroid) {
      try {
        if (vendorId != null && productId != null) {
          UsbPrinterInput device = UsbPrinterInput(
            name: printerName,
            vendorId: vendorId.toString(),
            productId: productId.toString(),
          );
          await PrinterManager.instance.connect(type: PrinterType.usb, model: device);
        }
        await PrinterManager.instance.send(type: PrinterType.usb, bytes: data);
        return true;
      } catch (_) {
        return false;
      }
    } else if (Platform.isWindows) {
      try 
      {
        final tempDir = Directory.systemTemp;
        final tempFile = File('${tempDir.path}\\receipt_${DateTime.now().millisecondsSinceEpoch}.bin');
        await tempFile.writeAsBytes(data);

        final String pName = printerName.isNotEmpty ? printerName : 'Xprinter';
        final result = await Process.run('cmd', ['/c', 'copy /b "${tempFile.path}" "$pName"']);
        if (tempFile.existsSync()) {
          await tempFile.delete();
        }
        return result.exitCode == 0;
      } catch (_) {
        return false;
      }
    }
    return false;
  }

  /// Test connection & print test receipt to USB printer
  Future<bool> testPrinter() async {
    final List<int> bytes = [];
    bytes.addAll([0x1B, 0x40]);
    bytes.addAll([0x1B, 0x61, 0x01]);
    bytes.addAll(safeAsciiEncode('UYEN COFFEE - KET NOI IN USB SUCCESS!\n\n\n'));
    bytes.addAll([0x1D, 0x56, 0x42, 0x00]);
    return await sendRawBytes(Uint8List.fromList(bytes));
  }
}
