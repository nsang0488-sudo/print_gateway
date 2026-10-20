import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/firebase_service.dart';

class StoreView extends StatefulWidget {
  final FirebaseService firebaseService;
  final ShiftModel? activeShift;
  final List<EditLogModel> editLogs;
  final Map<String, ShiftLogModel> shiftLogs;
  final Map<String, MenuItemModel> menuMap;

  const StoreView({
    super.key,
    required this.firebaseService,
    required this.activeShift,
    required this.editLogs,
    required this.shiftLogs,
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
                    Text('💵 TM: ${currencyFormat.format(widget.activeShift!.revenueCash)}đ | 💳 CK: ${currencyFormat.format(widget.activeShift!.revenueTransfer)}đ'),
                    const SizedBox(height: 8),
                    const Text('Doanh thu theo nhân viên:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 4),
                    _buildStaffRevenueBreakdown(),
                    const SizedBox(height: 8),
                    Text(
                      'Tổng doanh thu: ${currencyFormat.format(widget.activeShift!.revenue)}đ',
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 18),
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

          // Active Bills in Current Shift
          if (widget.activeShift != null && widget.activeShift!.history.isNotEmpty) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('🧾 Bill Trong Ca Hiện Tại', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 8),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: widget.activeShift!.history.length,
                      itemBuilder: (context, index) {
                        final historyKeys = widget.activeShift!.history.keys.toList().reversed.toList();
                        final billKey = historyKeys[index];
                        final bill = widget.activeShift!.history[billKey]!;
                        return _buildActiveBillCard(billKey, bill);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Shift Logs History Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('📜 Lịch Sử Ca Đã Chốt', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 8),
                  if (widget.shiftLogs.isEmpty)
                    const Text('Chưa có ca nào được chốt', style: TextStyle(color: Colors.grey))
                  else
                    SizedBox(
                      height: 220,
                      child: ListView(
                        children: widget.shiftLogs.values.toList().reversed.map((log) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9F9F9),
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('📅 ${log.date}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2C3E50))),
                                Text('🕒 ${log.start} - ${log.end}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                const SizedBox(height: 4),
                                Text('💵 TM: ${currencyFormat.format(log.revenueCash)}đ | 💳 CK: ${currencyFormat.format(log.revenueTransfer)}đ', style: const TextStyle(fontSize: 12)),
                                const SizedBox(height: 4),
                                Text('Tổng doanh thu: ${currencyFormat.format(log.revenue)}đ', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13)),
                              ],
                            ),
                          );
                        }).toList(),
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
                      height: 220,
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
                      final hcText = item.hasHotCold ? ' (Có Nóng/Đá)' : ' (Không Nóng/Đá)';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(item.name, style: TextStyle(fontWeight: FontWeight.bold, color: item.soldOut ? Colors.grey : Colors.black)),
                                      if (item.soldOut)
                                        const Padding(
                                          padding: EdgeInsets.only(left: 6),
                                          child: Text('(Đã báo hết)', style: TextStyle(color: Colors.red, fontSize: 11)),
                                        ),
                                    ],
                                  ),
                                  Text(
                                    'Nhóm: ${item.category} - ${currencyFormat.format(item.price)}đ$hcText',
                                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: item.soldOut ? const Color(0xFF28A745) : const Color(0xFFCCA352),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    minimumSize: Size.zero,
                                  ),
                                  onPressed: () => widget.firebaseService.updateMenuItem(key, {'soldOut': !item.soldOut}),
                                  child: Text(item.soldOut ? 'Mở lại' : 'Báo hết', style: const TextStyle(color: Colors.white, fontSize: 11)),
                                ),
                                const SizedBox(width: 4),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2C3E50),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    minimumSize: Size.zero,
                                  ),
                                  onPressed: () => _openEditMenuModal(key, item),
                                  child: const Text('Sửa', style: TextStyle(color: Colors.white, fontSize: 11)),
                                ),
                                const SizedBox(width: 4),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                  onPressed: () => widget.firebaseService.removeMenuItem(key),
                                ),
                              ],
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

  Widget _buildStaffRevenueBreakdown() {
    if (widget.activeShift == null || widget.activeShift!.history.isEmpty) {
      return const Text('Chưa có doanh thu theo nhân viên', style: TextStyle(color: Colors.grey, fontSize: 12));
    }

    Map<String, double> staffRevenue = {};
    for (var bill in widget.activeShift!.history.values) {
      final staff = (bill.payStaff ?? '').isNotEmpty ? bill.payStaff! : 'Chưa xác định';
      staffRevenue[staff] = (staffRevenue[staff] ?? 0) + bill.total;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: staffRevenue.entries.map((entry) {
        return Text(
          '• ${entry.key}: ${currencyFormat.format(entry.value)}đ',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2C3E50)),
        );
      }).toList(),
    );
  }

  Widget _buildActiveBillCard(String billKey, BillHistoryModel bill) {
    final staffDisplay = (bill.payStaff ?? '').isNotEmpty ? bill.payStaff! : 'N/A';
    final methodText = bill.method == 'transfer' ? '💳 CK' : '💵 TM';
    final methodColor = bill.method == 'transfer' ? const Color(0xFF5D3FD3) : const Color(0xFF28A745);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Bàn ${bill.table} (Vào: ${bill.startTime} - Ra: ${bill.payTime}) | 👤 $staffDisplay - $methodText',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: methodColor),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  minimumSize: Size.zero,
                ),
                onPressed: () => _deleteActiveBill(billKey, bill),
                child: const Text('XÓA', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const Divider(),
          ...bill.items.asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;
            final subTotal = item.price * item.qty;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${item.qty}x ${item.fName}', style: const TextStyle(fontSize: 12)),
                  Row(
                    children: [
                      Text('${currencyFormat.format(subTotal)}đ', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 4),
                      InkWell(
                        onTap: () => _deleteItemInActiveBill(billKey, bill, idx, item),
                        child: const Text(' (X)', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 11)),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
          const Divider(),
          Text(
            'Tổng: ${currencyFormat.format(bill.total)}đ',
            style: const TextStyle(color: Color(0xFF5D3FD3), fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }

  void _deleteActiveBill(String billKey, BillHistoryModel bill) async {
    final reason = await _promptReason('Nhập lý do xóa bill đã thanh toán (Bàn ${bill.table} - ${currencyFormat.format(bill.total)}đ):');
    if (reason == null || reason.isEmpty) return;

    widget.firebaseService.logEditHistory(EditLogModel(
      action: 'Xóa bill đã thanh toán',
      details: 'Xóa bill Bàn ${bill.table} (Tổng tiền: ${currencyFormat.format(bill.total)}đ)',
      reason: reason,
      table: bill.table,
      staff: 'Admin',
    ));

    if (widget.activeShift != null) {
      await widget.firebaseService.deleteBillFromShift(
        billKey: billKey,
        bill: bill,
        shift: widget.activeShift!,
      );
    }
  }

  void _deleteItemInActiveBill(String billKey, BillHistoryModel bill, int itemIdx, TableItemModel item) async {
    final subTotal = item.price * item.qty;
    final reason = await _promptReason('Nhập lý do xóa món ${item.fName} khỏi bill đã thanh toán (Bàn ${bill.table}):');
    if (reason == null || reason.isEmpty) return;

    widget.firebaseService.logEditHistory(EditLogModel(
      action: 'Xóa món khỏi bill đã thanh toán',
      details: 'Xóa món ${item.fName} (${item.qty}x, ${currencyFormat.format(subTotal)}đ) khỏi bill Bàn ${bill.table}',
      reason: reason,
      table: bill.table,
      staff: 'Admin',
    ));

    if (widget.activeShift != null) {
      await widget.firebaseService.deleteItemFromBillInShift(
        billKey: billKey,
        itemIndex: itemIdx,
        bill: bill,
        shift: widget.activeShift!,
      );
    }
  }

  void _openEditMenuModal(String key, MenuItemModel item) {
    final editNameController = TextEditingController(text: item.name);
    final editPriceController = TextEditingController(text: item.price.toInt().toString());
    final editCatController = TextEditingController(text: item.category);
    bool editHasHotCold = item.hasHotCold;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: const Text('Sửa thông tin món'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: editCatController, decoration: const InputDecoration(labelText: 'Nhóm món', border: OutlineInputBorder())),
                  const SizedBox(height: 8),
                  TextField(controller: editNameController, decoration: const InputDecoration(labelText: 'Tên món', border: OutlineInputBorder())),
                  const SizedBox(height: 8),
                  TextField(controller: editPriceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Giá', border: OutlineInputBorder())),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    title: const Text('Có chọn Nóng / Đá'),
                    value: editHasHotCold,
                    onChanged: (v) => setModalState(() => editHasHotCold = v == true),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Hủy')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5D3FD3)),
                  onPressed: () {
                    final name = editNameController.text.trim();
                    final price = double.tryParse(editPriceController.text.trim()) ?? 0;
                    final cat = editCatController.text.trim();

                    if (name.isNotEmpty && price > 0) {
                      widget.firebaseService.updateMenuItem(key, {
                        'name': name,
                        'price': price,
                        'category': cat.isEmpty ? 'Khác' : cat,
                        'hasHotCold': editHasHotCold,
                      });
                      Navigator.pop(dialogContext);
                    }
                  },
                  child: const Text('LƯU THAY ĐỔI', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
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
          content: const Text('Toàn bộ bàn sẽ được dọn trống và dữ liệu sẽ được xuất ra báo cáo ca.'),
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

  Future<String?> _promptReason(String message) async {
    String reason = '';
    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(message, style: const TextStyle(fontSize: 14)),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Nhập lý do...'),
            onChanged: (v) => reason = v,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, null), child: const Text('Hủy')),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, reason.trim()),
              child: const Text('Xác nhận'),
            ),
          ],
        );
      },
    );
  }
}
