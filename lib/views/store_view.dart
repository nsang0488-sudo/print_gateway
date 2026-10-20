import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/firebase_service.dart';

class StoreView extends StatefulWidget {
  final FirebaseService firebaseService;
  final ShiftModel? activeShift;
  final List<EditLogModel> editLogs;
  final Map<String, MenuItemModel> menuMap;

  const StoreView({
    super.key,
    required this.firebaseService,
    required this.activeShift,
    required this.editLogs,
    required this.menuMap,
  });

  @override
  State<StoreView> createState() => _StoreViewState();
}

class _StoreViewState extends State<StoreView> {
  final currencyFormat = NumberFormat('#,###', 'vi_VN');

  final _categoryController = TextEditingController();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  bool _hasHotCold = true;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🏪 Quản Lý Cửa Hàng', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
          const SizedBox(height: 12),

          // Shift Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('📦 Trạng Thái Ca Trong Ngày', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 8),
                  if (widget.activeShift == null)
                    const Text('Chưa mở ca', style: TextStyle(color: Colors.grey))
                  else ...[
                    Text('Mở lúc: ${widget.activeShift!.start}'),
                    const SizedBox(height: 4),
                    Text('TM: ${currencyFormat.format(widget.activeShift!.revenueCash)}đ | CK: ${currencyFormat.format(widget.activeShift!.revenueTransfer)}đ'),
                    const SizedBox(height: 4),
                    Text(
                      'Tổng doanh thu: ${currencyFormat.format(widget.activeShift!.revenue)}đ',
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: widget.activeShift == null
                        ? ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF28A745), padding: const EdgeInsets.symmetric(vertical: 12)),
                            onPressed: () => widget.firebaseService.startShift(),
                            child: const Text('MỞ CA MỚI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          )
                        : ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC3545), padding: const EdgeInsets.symmetric(vertical: 12)),
                            onPressed: _endShiftPrompt,
                            child: const Text('CHỐT CA (ĐÓNG CA)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Edit History Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('📝 Lịch Sử Sửa / Xóa Hóa Đơn & Món', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 8),
                  if (widget.editLogs.isEmpty)
                    const Text('Chưa có lịch sử thay đổi', style: TextStyle(color: Colors.grey))
                  else
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        itemCount: widget.editLogs.length,
                        itemBuilder: (context, index) {
                          final log = widget.editLogs[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('⚠️ ${log.action} (Bàn ${log.table})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                Text(log.details, style: const TextStyle(fontSize: 11)),
                                Text('💬 Lý do: ${log.reason}', style: const TextStyle(color: Colors.brown, fontSize: 11, fontWeight: FontWeight.bold)),
                                Text('👤 Thao tác: ${log.staff}', style: const TextStyle(color: Colors.grey, fontSize: 10)),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Menu Management Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('📝 Quản Lý Menu Món', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 8),
                  TextField(controller: _categoryController, decoration: const InputDecoration(hintText: 'Nhóm món (VD: Cà phê, Sinh tố...)', border: OutlineInputBorder())),
                  const SizedBox(height: 6),
                  TextField(controller: _nameController, decoration: const InputDecoration(hintText: 'Tên món', border: OutlineInputBorder())),
                  const SizedBox(height: 6),
                  TextField(controller: _priceController, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'Giá', border: OutlineInputBorder())),
                  const SizedBox(height: 6),
                  CheckboxListTile(
                    title: const Text('Có chọn Nóng / Đá'),
                    value: _hasHotCold,
                    onChanged: (v) => setState(() => _hasHotCold = v == true),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5D3FD3)),
                      onPressed: _addMenu,
                      child: const Text('THÊM MÓN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const Divider(height: 20),
                  ListView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: widget.menuMap.entries.map((entry) {
                      final key = entry.key;
                      final item = entry.value;
                      return ListTile(
                        title: Text(item.name, style: TextStyle(color: item.soldOut ? Colors.grey : Colors.black)),
                        subtitle: Text('${item.category} - ${currencyFormat.format(item.price)}đ'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextButton(
                              onPressed: () => widget.firebaseService.updateMenuItem(key, {'soldOut': !item.soldOut}),
                              child: Text(item.soldOut ? 'Mở lại' : 'Báo hết', style: TextStyle(color: item.soldOut ? Colors.green : Colors.orange)),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => widget.firebaseService.removeMenuItem(key),
                            ),
                          ],
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

  void _addMenu() {
    final name = _nameController.text.trim();
    final price = double.tryParse(_priceController.text.trim()) ?? 0;
    final cat = _categoryController.text.trim();

    if (name.isNotEmpty && price > 0) {
      widget.firebaseService.addMenuItem(MenuItemModel(
        key: '',
        name: name,
        price: price,
        category: cat.isEmpty ? 'Khác' : cat,
        hasHotCold: _hasHotCold,
      ));
      _nameController.clear();
      _priceController.clear();
      _categoryController.clear();
    }
  }

  void _endShiftPrompt() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Xác nhận CHỐT CA?'),
          content: const Text('Toàn bộ bàn sẽ được dọn trống và dữ liệu sẽ được lưu vào lịch sử ca.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Hủy')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                if (widget.activeShift != null) {
                  widget.firebaseService.endShift(widget.activeShift!);
                }
                Navigator.pop(dialogContext);
              },
              child: const Text('XÁC NHẬN CHỐT CA', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
