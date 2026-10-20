import 'dart:io';
import 'dart:typed_data';

class PrinterService {
  String ip;
  int port;

  PrinterService({this.ip = '192.168.1.200', this.port = 9100});

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
  /// Example: "1x Ca phe sua da             25,000"
  static String formatLine(String left, String right, {int width = 48}) {
    int spaceCount = width - left.length - right.length;
    if (spaceCount < 1) {
      int maxLeft = width - right.length - 1;
      if (maxLeft > 0) {
        left = left.substring(0, maxLeft);
      }
      spaceCount = 1;
    }
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

    // Set line spacing default
    bytes.addAll([0x1B, 0x32]);

    // Center alignment
    bytes.addAll([0x1B, 0x61, 0x01]);

    // Double height & double width for Store Name
    bytes.addAll([0x1D, 0x21, 0x11]);
    bytes.addAll(safeAsciiEncode('${removeAccents(storeName)}\n'));

    // Normal text size
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

      // If item has separate note
      final String? note = item['note'];
      if (note != null && note.isNotEmpty) {
        bytes.addAll(safeAsciiEncode('   * Ghi chu: ${removeAccents(note)}\n'));
      }
    }

    bytes.addAll(safeAsciiEncode('------------------------------------------------\n'));

    // Right alignment for Total
    bytes.addAll([0x1B, 0x61, 0x02]);
    // Bold total
    bytes.addAll([0x1B, 0x45, 0x01]);
    bytes.addAll([0x1D, 0x21, 0x01]); // Double height
    bytes.addAll(safeAsciiEncode('TONG CONG: ${formatCurrency(total)}d\n'));
    bytes.addAll([0x1D, 0x21, 0x00]); // Normal
    bytes.addAll([0x1B, 0x45, 0x00]); // Bold off

    if (payMethod.isNotEmpty) {
      final String methodText = payMethod.toLowerCase() == 'transfer' ? 'Chuyen khoan' : 'Tien mat';
      bytes.addAll(safeAsciiEncode('Hinh thuc TT: $methodText\n'));
    }

    bytes.addAll(safeAsciiEncode('------------------------------------------------\n'));

    // Center alignment footer
    bytes.addAll([0x1B, 0x61, 0x01]);
    bytes.addAll(safeAsciiEncode('Cam on Quy khach & Hen gap lai!\n\n\n\n'));

    // GS V 66 0 (Cut paper command)
    bytes.addAll([0x1D, 0x56, 0x42, 0x00]);

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

  /// Print receipt bytes to LAN printer via TCP Socket
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

  /// Send raw bytes to TCP socket at IP:Port
  Future<bool> sendRawBytes(Uint8List data) async {
    try {
      final socket = await Socket.connect(ip, port, timeout: const Duration(seconds: 4));
      socket.add(data);
      await socket.flush();
      await socket.close();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Test connection to printer
  Future<bool> testPrinter() async {
    final List<int> bytes = [];
    bytes.addAll([0x1B, 0x40]); // Reset
    bytes.addAll([0x1B, 0x61, 0x01]); // Center
    bytes.addAll(safeAsciiEncode('UYEN COFFEE - KET NOI IN THU SUCCESS!\n\n\n'));
    bytes.addAll([0x1D, 0x56, 0x42, 0x00]); // Cut
    return await sendRawBytes(Uint8List.fromList(bytes));
  }
}
