import 'package:flutter_test/flutter_test.dart';
import 'package:print_gateway/models/models.dart';
import 'package:print_gateway/services/printer_service.dart';

void main() {
  group('PrinterService Unit Tests', () {
    test('removeAccents converts Vietnamese characters correctly', () {
      expect(PrinterService.removeAccents('Cà phê sữa đá'), equals('Ca phe sua da'));
      expect(PrinterService.removeAccents('UYÊN COFFEE POS PRO'), equals('UYEN COFFEE POS PRO'));
      expect(PrinterService.removeAccents('Bàn 1: Nóng/Đá'), equals('Ban 1: Nong/Da'));
    });

    test('formatLine formats 48 chars wide line properly', () {
      final line = PrinterService.formatLine('1x Ca phe sua da', '25,000d', width: 48);
      expect(line.length, equals(48));
      expect(line.startsWith('1x Ca phe sua da'), isTrue);
      expect(line.endsWith('25,000d'), isTrue);
    });

    test('buildReceiptBytes produces raw ESC/POS byte array with cut command', () {
      final bytes = PrinterService.buildReceiptBytes(
        storeName: 'UYÊN COFFEE',
        tableName: 'Bàn 1',
        time: '12:30',
        staffName: 'Lan Anh',
        items: [
          {'fName': 'Cà phê sữa đá (Đá)', 'qty': 2, 'price': 25000.0},
        ],
        total: 50000.0,
        payMethod: 'cash',
      );

      expect(bytes, isNotEmpty);
      // Ends with GS V 66 0 cut command (0x1D, 0x56, 0x42, 0x00)
      expect(bytes.sublist(bytes.length - 4), equals([0x1D, 0x56, 0x42, 0x00]));
    });
  });

  group('Model Serialization Tests', () {
    test('TableModel json roundtrip', () {
      final tableJson = {
        'status': 'red',
        'startTime': '10:00',
        'needsServing': true,
        'printed': false,
        'items': [
          {'fName': 'Bạc xỉu (Đá)', 'price': 30000, 'qty': 1, 'done': false}
        ]
      };

      final table = TableModel.fromJson(1, tableJson);
      expect(table.id, equals(1));
      expect(table.status, equals('red'));
      expect(table.total, equals(30000.0));
      expect(table.items.length, equals(1));
      expect(table.items.first.fName, equals('Bạc xỉu (Đá)'));
    });
  });
}
