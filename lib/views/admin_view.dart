import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/firebase_service.dart';
import '../services/printer_service.dart';

class AdminView extends StatefulWidget {
  final FirebaseService firebaseService;
  final PrinterService printerService;
  final Map<String, DeviceModel> devices;
  final String currentRegCode;
  final Map<String, ShiftLogModel> shiftLogs;
  final String qrUrl;

  const AdminView({
    super.key,
    required this.firebaseService,
    required this.printerService,
    required this.devices,
    required this.currentRegCode,
    required this.shiftLogs,
    required this.qrUrl,
  });

  @override
  State<AdminView> createState() => _AdminViewState();
}

class _AdminViewState extends State<AdminView> {
  final currencyFormat = NumberFormat('#,###', 'vi_VN');

  late TextEditingController _qrUrlController;
  List<Map<String, dynamic>> _usbDevices = [];
  bool _isLoadingDevices = false;
  Map<String, dynamic>? _selectedUsbDevice;

  @override
  void initState() {
    super.initState();
    _qrUrlController = TextEditingController(text: widget.qrUrl);
    _scanUsbPrinters();
  }

  Future<void> _scanUsbPrinters() async {
    setState(() => _isLoadingDevices = true);
    final devices = await widget.printerService.getUsbDeviceList();
    if (mounted) {
      setState(() {
        _usbDevices = devices;
        _isLoadingDevices = false;
        if (devices.isNotEmpty) {
          _selectedUsbDevice = devices.first;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('⚙️ Khu Vực Quản Lý & Cài Đặt Máy Trạm In USB', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
          const SizedBox(height: 12),

          // USB Printer Settings Card
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('🖨️ Cài Đặt Máy In USB (Xprinter / POS K80)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF5D3FD3))),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Color(0xFF5D3FD3)),
                        onPressed: _scanUsbPrinters,
                        tooltip: 'Quét lại thiết bị USB',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_isLoadingDevices)
                    const Center(child: CircularProgressIndicator())
                  else if (_usbDevices.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Không tìm thấy thiết bị máy in USB. Vui lòng cắm cáp USB máy in Xprinter vào máy tính / thiết bị và nhấn nút làm mới.',
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    )
                  else
                    DropdownButtonFormField<Map<String, dynamic>>(
                      initialValue: _selectedUsbDevice,
                      decoration: const InputDecoration(
                        labelText: 'Chọn máy in USB',
                        border: OutlineInputBorder(),
                      ),
                      items: _usbDevices.map((dev) {
                        final name = dev['deviceName'] ?? dev['productName'] ?? 'USB Printer';
                        final vendor = dev['vendorId'] ?? '';
                        final product = dev['productId'] ?? '';
                        return DropdownMenuItem(
                          value: dev,
                          child: Text('$name (VID: $vendor, PID: $product)'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() => _selectedUsbDevice = val);
                      },
                    ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5D3FD3)),
                          onPressed: () async {
                            if (_selectedUsbDevice != null) {
                              final int vId = int.tryParse(_selectedUsbDevice!['vendorId'].toString()) ?? 0;
                              final int pId = int.tryParse(_selectedUsbDevice!['productId'].toString()) ?? 0;
                              final success = await widget.printerService.connectUsb(vId, pId);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(success ? 'Kết nối máy in USB thành công!' : 'Kết nối máy in USB thất bại!'),
                                    backgroundColor: success ? Colors.green : Colors.red,
                                  ),
                                );
                              }
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chưa chọn máy in USB!')));
                            }
                          },
                          child: const Text('KẾT NỐI USB', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF28A745)),
                          onPressed: () async {
                            if (_selectedUsbDevice != null) {
                              final int vId = int.tryParse(_selectedUsbDevice!['vendorId'].toString()) ?? 0;
                              final int pId = int.tryParse(_selectedUsbDevice!['productId'].toString()) ?? 0;
                              await widget.printerService.connectUsb(vId, pId);
                            }
                            final success = await widget.printerService.testPrinter();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(success ? 'In thử qua USB thành công!' : 'Không thể gửi lệnh in tới máy in USB. Kiểm tra lại kết nối cáp USB.'),
                                  backgroundColor: success ? Colors.green : Colors.red,
                                ),
                              );
                            }
                          },
                          child: const Text('IN THỬ (TEST)', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Devices & Registration Code
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('📱 Thiết Bị & Phân Quyền', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 8),
                  ListView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: widget.devices.entries.map((entry) {
                      final key = entry.key;
                      final dev = entry.value;
                      return ListTile(
                        title: Text('👤 ${dev.name}'),
                        subtitle: Text('Role: ${dev.role} | Tạo: ${dev.createdAt}'),
                        trailing: DropdownButton<String>(
                          value: dev.role,
                          items: const [
                            DropdownMenuItem(value: 'Phục vụ', child: Text('Phục vụ')),
                            DropdownMenuItem(value: 'Thu ngân', child: Text('Thu ngân')),
                            DropdownMenuItem(value: 'Quản lý', child: Text('Quản lý')),
                          ],
                          onChanged: (newRole) {
                            if (newRole != null) {
                              widget.firebaseService.updateDeviceRole(key, newRole);
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                  const Divider(),
                  Center(
                    child: Column(
                      children: [
                        const Text('Mã đăng ký cấp cho nhân viên:', style: TextStyle(color: Colors.grey)),
                        Text(widget.currentRegCode, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF5D3FD3), letterSpacing: 4)),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            final newCode = (10000 + (DateTime.now().millisecondsSinceEpoch % 90000)).toString();
                            widget.firebaseService.setRegCode(newCode);
                          },
                          child: const Text('TẠO MÃ MỚI'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // QR Code Settings
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🖼️ Cài Đặt Link Ảnh QR Thanh Toán', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _qrUrlController,
                    decoration: const InputDecoration(hintText: 'Link ảnh QR...', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2C3E50)),
                      onPressed: () {
                        widget.firebaseService.setQrUrl(_qrUrlController.text.trim());
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã lưu URL QR!')));
                      },
                      child: const Text('LƯU LINK QR', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Shift Logs History
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('📜 Lịch Sử Ca Đã Chốt', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 8),
                  ListView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: widget.shiftLogs.values.toList().reversed.map((log) {
                      return Card(
                        child: ListTile(
                          title: Text('📅 ${log.date} (${log.start} - ${log.end})'),
                          subtitle: Text('TM: ${currencyFormat.format(log.revenueCash)}đ | CK: ${currencyFormat.format(log.revenueTransfer)}đ'),
                          trailing: Text('${currencyFormat.format(log.revenue)}đ', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
