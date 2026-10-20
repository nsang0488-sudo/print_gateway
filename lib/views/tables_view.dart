import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/firebase_service.dart';
import '../services/printer_service.dart';

class TablesView extends StatefulWidget {
  final FirebaseService firebaseService;
  final PrinterService printerService;
  final String currentUserRole;
  final String currentStaffName;
  final ShiftModel? activeShift;
  final String qrUrl;

  const TablesView({
    super.key,
    required this.firebaseService,
    required this.printerService,
    required this.currentUserRole,
    required this.currentStaffName,
    required this.activeShift,
    required this.qrUrl,
  });

  @override
  State<TablesView> createState() => _TablesViewState();
}

class _TablesViewState extends State<TablesView> {
  String _activeSubTab = 'tables'; // 'tables' or 'bills'
  int? _selectedTableId;
  String _orderSubView = 'menu'; // 'menu' or 'bill'
  String? _selectedCategory;
  String _selectedTemperature = 'Đá';

  final currencyFormat = NumberFormat('#,###', 'vi_VN');

  bool _checkShiftRequired() {
    if (widget.activeShift == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Phải MỞ CA MỚI trong mục 'Cửa Hàng' thì mới có thể thực hiện gọi món và thanh toán!"),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<int, TableModel>>(
      stream: widget.firebaseService.tablesStream,
      builder: (context, tablesSnapshot) {
        final tablesData = tablesSnapshot.data ?? {};

        if (_selectedTableId != null) {
          final currentTable = tablesData[_selectedTableId!] ?? TableModel(id: _selectedTableId!);
          return _buildOrderView(currentTable, tablesData);
        }

        return Column(
          children: [
            // Subtabs
            Container(
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _activeSubTab = 'tables'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: _activeSubTab == 'tables' ? const Color(0xFF5D3FD3) : Colors.transparent,
                              width: 3,
                            ),
                          ),
                        ),
                        child: Text(
                          '🪑 Tất cả bàn',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: _activeSubTab == 'tables' ? const Color(0xFF5D3FD3) : Colors.grey[700],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _activeSubTab = 'bills'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: _activeSubTab == 'bills' ? const Color(0xFF5D3FD3) : Colors.transparent,
                              width: 3,
                            ),
                          ),
                        ),
                        child: Text(
                          '🧾 Hóa đơn chưa thanh toán',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: _activeSubTab == 'bills' ? const Color(0xFF5D3FD3) : Colors.grey[700],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Grid view
            Expanded(
              child: _buildTablesGrid(tablesData),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTablesGrid(Map<int, TableModel> tablesData) {
    List<int> visibleTableIds = [];

    for (int i = 1; i <= 40; i++) {
      final t = tablesData[i] ?? TableModel(id: i);
      if (_activeSubTab == 'bills' && t.total == 0) {
        continue;
      }
      visibleTableIds.add(i);
    }

    if (_activeSubTab == 'bills' && visibleTableIds.isEmpty) {
      return const Center(
        child: Text(
          'Không có bàn nào đang có hóa đơn chưa thanh toán.',
          style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.85,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: visibleTableIds.length,
      itemBuilder: (context, index) {
        final tableId = visibleTableIds[index];
        final table = tablesData[tableId] ?? TableModel(id: tableId);
        return _buildTableCard(table);
      },
    );
  }

  Widget _buildTableCard(TableModel table) {
    Color cardBg = Colors.white;
    Color borderBg = const Color(0xFF2C3E50);

    if (table.status == 'red') {
      cardBg = const Color(0xFFFFB8C0);
      borderBg = const Color(0xFFDC3545);
    } else if (table.status == 'green') {
      cardBg = const Color(0xFFB8E6C1);
      borderBg = const Color(0xFF28A745);
    }

    return InkWell(
      onTap: () {
        setState(() {
          _selectedTableId = table.id;
          _orderSubView = _activeSubTab == 'bills' ? 'bill' : 'menu';
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderBg, width: table.status != 'white' ? 2 : 1),
        ),
        padding: const EdgeInsets.all(6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🖨️', style: TextStyle(fontSize: 16)),
            Text(
              'Bàn ${table.id}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            if (table.total > 0)
              Text(
                '${currencyFormat.format(table.total)}đ',
                style: const TextStyle(color: Color(0xFFDC3545), fontWeight: FontWeight.bold, fontSize: 11),
              ),
            Text(
              table.total > 0 ? '' : 'Trống',
              style: const TextStyle(color: Colors.grey, fontSize: 10),
            ),
            const SizedBox(height: 4),
            InkWell(
              onTap: () => _openServeModal(table),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 3),
                decoration: BoxDecoration(
                  color: table.needsServing ? const Color(0xFFDC3545) : Colors.white.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: table.needsServing ? Colors.transparent : Colors.grey.shade300,
                  ),
                ),
                child: Text(
                  table.needsServing ? 'CẦN BƯNG NƯỚC' : 'TRỐNG',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: table.needsServing ? Colors.white : Colors.grey,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderView(TableModel currentTable, Map<int, TableModel> allTables) {
    return Column(
      children: [
        // Top Header
        Container(
          color: const Color(0xFF5D3FD3),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => setState(() => _selectedTableId = null),
                  ),
                  Text(
                    _orderSubView == 'menu' ? 'BÀN ${currentTable.id} - MENU' : 'BÀN ${currentTable.id} - HOÁ ĐƠN',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.white),
                    onPressed: () => _deleteActiveTableBill(currentTable),
                    tooltip: 'Xóa bill',
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white24,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                    ),
                    onPressed: () => _openMoveTableModal(currentTable, allTables),
                    child: const Text('CHUYỂN', style: TextStyle(fontSize: 11)),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      setState(() {
                        _orderSubView = _orderSubView == 'menu' ? 'bill' : 'menu';
                      });
                    },
                    child: const Icon(Icons.swap_horiz, color: Colors.white, size: 24),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Order Summary Bar
        Container(
          color: const Color(0xFF2C3E50),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: const BoxDecoration(
                      color: Color(0xFF5D3FD3),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(child: Text('🛒', style: TextStyle(fontSize: 14))),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BÀN ${currentTable.id} (${currentTable.items.length} món)',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      Text(
                        '${currencyFormat.format(currentTable.total)}đ',
                        style: const TextStyle(color: Color(0xFFF39C12), fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _orderSubView = _orderSubView == 'menu' ? 'bill' : 'menu';
                  });
                },
                child: Text(
                  _orderSubView == 'menu' ? 'Xem đơn >' : '← CHỌN MÓN',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
        ),

        // Main body content
        Expanded(
          child: _orderSubView == 'menu'
              ? _buildMenuSection(currentTable)
              : _buildBillSection(currentTable),
        ),
      ],
    );
  }

  Widget _buildMenuSection(TableModel currentTable) {
    return StreamBuilder<Map<String, MenuItemModel>>(
      stream: widget.firebaseService.menuStream,
      builder: (context, snapshot) {
        final menuMap = snapshot.data ?? {};
        if (menuMap.isEmpty) {
          return const Center(child: Text('Chưa có món ăn trong menu.'));
        }

        // Group by category
        Map<String, List<MenuItemModel>> categories = {};
        for (var item in menuMap.values) {
          categories.putIfAbsent(item.category, () => []).add(item);
        }

        final categoryKeys = categories.keys.toList();
        if (_selectedCategory == null && categoryKeys.isNotEmpty) {
          _selectedCategory = categoryKeys.first;
        }

        final displayedItems = categories[_selectedCategory] ?? [];

        return Row(
          children: [
            // Category Sidebar
            Container(
              width: 90,
              color: Colors.white,
              child: ListView.builder(
                itemCount: categoryKeys.length,
                itemBuilder: (context, index) {
                  final cat = categoryKeys[index];
                  final isSelected = cat == _selectedCategory;
                  return InkWell(
                    onTap: () => setState(() => _selectedCategory = cat),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF5D3FD3) : Colors.transparent,
                        border: const Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
                      ),
                      child: Text(
                        cat,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : const Color(0xFF2C3E50),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Menu Items Grid
            Expanded(
              child: Container(
                color: const Color(0xFFF4F6F8),
                padding: const EdgeInsets.all(8),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.1,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: displayedItems.length,
                  itemBuilder: (context, index) {
                    final item = displayedItems[index];
                    return InkWell(
                      onTap: () => _onSelectItem(currentTable, item),
                      child: Container(
                        decoration: BoxDecoration(
                          color: item.soldOut ? const Color(0xFFE9ECEF) : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: item.soldOut ? Colors.grey.shade400 : const Color(0xFFC8D6E5)),
                        ),
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              item.name,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: item.soldOut ? Colors.grey : const Color(0xFF2C3E50),
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (item.soldOut)
                              const Text('HẾT MÓN', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 10))
                            else
                              Text(
                                '${(item.price / 1000).toStringAsFixed(0)}k',
                                style: const TextStyle(color: Color(0xFF5D3FD3), fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _onSelectItem(TableModel table, MenuItemModel item) {
    if (item.soldOut) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Món này đã hết!')));
      return;
    }
    if (!_checkShiftRequired()) return;

    if (!item.hasHotCold) {
      // Add directly
      final newItem = TableItemModel(
        fName: item.name,
        price: item.price,
        qty: 1,
        done: false,
        orderStaff: widget.currentStaffName,
      );
      final updatedItems = [newItem, ...table.items];
      widget.firebaseService.updateTable(table.id, {
        'items': updatedItems.map((e) => e.toJson()).toList(),
        'startTime': table.startTime ?? DateFormat('HH:mm').format(DateTime.now()),
      });
      return;
    }

    // Show Option Modal (Nóng / Đá + Ghi chú)
    _showTemperatureOptionModal(table, item);
  }

  void _showTemperatureOptionModal(TableModel table, MenuItemModel item) {
    String note = '';
    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: Text(item.name, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _selectedTemperature == 'Nóng' ? const Color(0xFF5D3FD3) : Colors.white,
                            foregroundColor: _selectedTemperature == 'Nóng' ? Colors.white : Colors.black,
                          ),
                          onPressed: () => setModalState(() => _selectedTemperature = 'Nóng'),
                          child: const Text('NÓNG'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _selectedTemperature == 'Đá' ? const Color(0xFF5D3FD3) : Colors.white,
                            foregroundColor: _selectedTemperature == 'Đá' ? Colors.white : Colors.black,
                          ),
                          onPressed: () => setModalState(() => _selectedTemperature = 'Đá'),
                          child: const Text('ĐÁ'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: const InputDecoration(
                      hintText: 'Ghi chú...',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => note = v.trim(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5D3FD3)),
                  onPressed: () {
                    final String fullName = '${item.name} ($_selectedTemperature)${note.isNotEmpty ? ': $note' : ''}';
                    final newItem = TableItemModel(
                      fName: fullName,
                      price: item.price,
                      qty: 1,
                      done: false,
                      note: note.isNotEmpty ? note : null,
                      orderStaff: widget.currentStaffName,
                    );
                    final updatedItems = [newItem, ...table.items];
                    widget.firebaseService.updateTable(table.id, {
                      'items': updatedItems.map((e) => e.toJson()).toList(),
                      'startTime': table.startTime ?? DateFormat('HH:mm').format(DateTime.now()),
                    });
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('THÊM VÀO ĐƠN', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildBillSection(TableModel currentTable) {
    return Column(
      children: [
        // Items list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: currentTable.items.length,
            itemBuilder: (context, index) {
              final item = currentTable.items[index];
              return Card(
                child: ListTile(
                  title: Text(
                    '${item.qty}x ${item.fName}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: !item.done ? const Color(0xFFDC3545) : Colors.black,
                    ),
                  ),
                  trailing: Text(
                    '${currencyFormat.format(item.price * item.qty)}đ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onTap: () => _openItemQtyModal(currentTable, index),
                ),
              );
            },
          ),
        ),

        // Controls
        Container(
          padding: const EdgeInsets.all(12),
          color: const Color(0xFFF9F9F9),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC3545)),
                      onPressed: () {
                        widget.firebaseService.updateTable(currentTable.id, {'status': 'red'});
                        setState(() => _selectedTableId = null);
                      },
                      child: const Text('XÁC NHẬN', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF28A745)),
                      onPressed: () {
                        final updated = currentTable.items.map((it) {
                          return TableItemModel(
                            fName: it.fName,
                            price: it.price,
                            qty: it.qty,
                            done: true,
                            note: it.note,
                            orderStaff: it.orderStaff,
                          );
                        }).toList();
                        widget.firebaseService.updateTable(currentTable.id, {
                          'items': updated.map((e) => e.toJson()).toList(),
                          'status': 'green',
                        });
                        setState(() => _selectedTableId = null);
                      },
                      child: const Text('XONG HẾT', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    style: IconButton.styleFrom(backgroundColor: Colors.red),
                    icon: const Icon(Icons.delete, color: Colors.white),
                    onPressed: () => _deleteActiveTableBill(currentTable),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2C3E50), padding: const EdgeInsets.symmetric(vertical: 12)),
                  onPressed: () => _openPayModal(currentTable),
                  child: const Text('THANH TOÁN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _openItemQtyModal(TableModel table, int index) {
    final item = table.items[index];
    int qty = item.qty;
    final noteController = TextEditingController(text: item.note ?? '');

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: Text('Sửa món\n${item.fName}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, size: 30),
                        onPressed: () {
                          if (qty > 0) setModalState(() => qty--);
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text('$qty', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, size: 30),
                        onPressed: () => setModalState(() => qty++),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: noteController,
                    decoration: const InputDecoration(hintText: 'Ghi chú món...'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Đóng'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5D3FD3)),
                  onPressed: () async {
                      final updatedNote = noteController.text.trim();
                    if (qty < item.qty) {
                      final reason = await _promptReason('Nhập lý do giảm/xóa món ${item.fName}:');
                      if (reason == null || reason.isEmpty) return;
                      widget.firebaseService.logEditHistory(EditLogModel(
                        action: qty == 0 ? 'Xóa món' : 'Giảm số lượng món',
                        details: qty == 0
                            ? 'Xóa món ${item.fName} khỏi Bàn ${table.id}'
                            : 'Giảm món ${item.fName} từ ${item.qty}x -> ${qty}x',
                        reason: reason,
                        table: table.id,
                        staff: widget.currentStaffName,
                      ));
                    }

                    List<TableItemModel> updated = List.from(table.items);
                    if (qty == 0) {
                      updated.removeAt(index);
                    } else {
                      updated[index] = TableItemModel(
                        fName: item.fName,
                        price: item.price,
                        qty: qty,
                        done: item.done,
                        note: updatedNote.isNotEmpty ? updatedNote : null,
                        orderStaff: item.orderStaff,
                      );
                    }

                    if (updated.isEmpty) {
                      widget.firebaseService.removeTable(table.id);
                    } else {
                      widget.firebaseService.updateTable(table.id, {
                        'items': updated.map((e) => e.toJson()).toList(),
                      });
                    }

                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                    }
                  },
                  child: const Text('LƯU', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _openPayModal(TableModel table) {
    if (widget.currentUserRole == 'Phục vụ') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tài khoản của bạn có quyền phục vụ, không thể thực hiện chức năng thanh toán!')),
      );
      return;
    }

    String payMethod = 'cash';
    double cashIn = 0;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            double change = cashIn - table.total;

            return AlertDialog(
              title: Text('Thanh toán Bàn ${table.id}', textAlign: TextAlign.center),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Tổng: ${currencyFormat.format(table.total)}đ',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: payMethod == 'cash' ? const Color(0xFF5D3FD3) : Colors.grey.shade200,
                            foregroundColor: payMethod == 'cash' ? Colors.white : Colors.black,
                          ),
                          onPressed: () => setModalState(() => payMethod = 'cash'),
                          child: const Text('TIỀN MẶT'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: payMethod == 'transfer' ? const Color(0xFF5D3FD3) : Colors.grey.shade200,
                            foregroundColor: payMethod == 'transfer' ? Colors.white : Colors.black,
                          ),
                          onPressed: () => setModalState(() => payMethod = 'transfer'),
                          child: const Text('CHUYỂN KHOẢN'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (payMethod == 'cash') ...[
                    TextField(
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Khách đưa...',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (v) {
                        setModalState(() {
                          cashIn = double.tryParse(v) ?? 0;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Thối: ${change > 0 ? currencyFormat.format(change) : 0}đ',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                  ] else ...[
                    if (widget.qrUrl.isNotEmpty)
                      Image.network(widget.qrUrl, height: 180, errorBuilder: (_, __, ___) => const Text('Không tải được ảnh QR'))
                    else
                      const Text('Chưa cài đặt ảnh QR thanh toán'),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2C3E50)),
                  onPressed: () async {
                    final payTime = DateFormat('HH:mm').format(DateTime.now());
                    final bill = BillHistoryModel(
                      key: DateTime.now().millisecondsSinceEpoch.toString(),
                      time: payTime,
                      startTime: table.startTime ?? payTime,
                      payTime: payTime,
                      table: table.id,
                      total: table.total,
                      method: payMethod,
                      payStaff: widget.currentStaffName,
                      items: table.items,
                    );

                    await widget.firebaseService.addBillToShift(
                      bill: bill,
                      currentRevenue: widget.activeShift?.revenue ?? 0,
                      currentCash: widget.activeShift?.revenueCash ?? 0,
                      currentTransfer: widget.activeShift?.revenueTransfer ?? 0,
                    );

                    // Print receipt automatically if printer connected
                    widget.printerService.printReceipt(
                      storeName: 'UYÊN COFFEE',
                      tableName: 'Bàn ${table.id}',
                      time: payTime,
                      staffName: widget.currentStaffName,
                      items: table.items.map((e) => e.toJson()).toList(),
                      total: table.total,
                      payMethod: payMethod,
                    );

                    widget.firebaseService.removeTable(table.id);
                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                    }
                    if (mounted) {
                      setState(() => _selectedTableId = null);
                    }
                  },
                  child: const Text('HOÀN TẤT', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deleteActiveTableBill(TableModel table) async {
    if (table.items.isEmpty) return;

    final reason = await _promptReason('Nhập lý do xóa toàn bộ hóa đơn Bàn ${table.id}:');
    if (reason == null || reason.isEmpty) return;

    widget.firebaseService.logEditHistory(EditLogModel(
      action: 'Xóa toàn bộ hóa đơn',
      details: 'Xóa hóa đơn Bàn ${table.id} (${table.items.length} món, tổng ${currencyFormat.format(table.total)}đ)',
      reason: reason,
      table: table.id,
      staff: widget.currentStaffName,
    ));

    widget.firebaseService.removeTable(table.id);
    if (mounted) {
      setState(() => _selectedTableId = null);
    }
  }

  void _openMoveTableModal(TableModel currentTable, Map<int, TableModel> allTables) {
    int targetTableId = currentTable.id == 1 ? 2 : 1;
    String mode = 'move'; // 'move' or 'merge'

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: Text('Chuyển / Gộp Bàn ${currentTable.id}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: mode == 'move' ? const Color(0xFF5D3FD3) : Colors.grey.shade200,
                            foregroundColor: mode == 'move' ? Colors.white : Colors.black,
                          ),
                          onPressed: () => setModalState(() => mode = 'move'),
                          child: const Text('CHUYỂN BÀN'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: mode == 'merge' ? const Color(0xFF5D3FD3) : Colors.grey.shade200,
                            foregroundColor: mode == 'merge' ? Colors.white : Colors.black,
                          ),
                          onPressed: () => setModalState(() => mode = 'merge'),
                          child: const Text('GỘP BÀN'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: targetTableId,
                    decoration: const InputDecoration(labelText: 'Đến bàn', border: OutlineInputBorder()),
                    items: List.generate(40, (index) => index + 1)
                        .where((id) => id != currentTable.id)
                        .map((id) => DropdownMenuItem(value: id, child: Text('Bàn $id')))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setModalState(() => targetTableId = v);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Hủy')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5D3FD3)),
                  onPressed: () {
                    final targetTable = allTables[targetTableId] ?? TableModel(id: targetTableId);

                    if (mode == 'move') {
                      widget.firebaseService.setTable(targetTableId, currentTable.toJson());
                      widget.firebaseService.removeTable(currentTable.id);
                    } else {
                      final mergedItems = [...targetTable.items, ...currentTable.items];
                      widget.firebaseService.setTable(targetTableId, {
                        'items': mergedItems.map((e) => e.toJson()).toList(),
                        'startTime': targetTable.startTime ?? currentTable.startTime,
                        'status': currentTable.status == 'red' || targetTable.status == 'red' ? 'red' : 'white',
                      });
                      widget.firebaseService.removeTable(currentTable.id);
                    }

                    Navigator.pop(dialogContext);
                    setState(() => _selectedTableId = targetTableId);
                  },
                  child: const Text('XÁC NHẬN', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _openServeModal(TableModel table) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Báo Bưng Nước Bàn ${table.id}', textAlign: TextAlign.center),
          content: Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC3545)),
                  onPressed: () {
                    widget.firebaseService.updateTable(table.id, {'needsServing': true});
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('RA MÓN', style: TextStyle(color: Colors.white)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                  onPressed: () {
                    widget.firebaseService.updateTable(table.id, {'needsServing': false});
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('TRỐNG', style: TextStyle(color: Colors.black)),
                ),
              ),
            ],
          ),
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
