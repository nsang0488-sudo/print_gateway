import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/firebase_service.dart';

class TasksView extends StatefulWidget {
  final FirebaseService firebaseService;
  final String currentUserRole;
  final String currentDeviceId;
  final Map<String, DeviceModel> devices;

  const TasksView({
    super.key,
    required this.firebaseService,
    required this.currentUserRole,
    required this.currentDeviceId,
    required this.devices,
  });

  @override
  State<TasksView> createState() => _TasksViewState();
}

class _TasksViewState extends State<TasksView> {
  String? _selectedEmployeeKey;
  final _taskContentController = TextEditingController();
  bool _isImportant = false;
  int _frequency = 0;

  @override
  void initState() {
    super.initState();
    if (widget.devices.isNotEmpty) {
      _selectedEmployeeKey = widget.devices.keys.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.currentUserRole == 'Quản lý') {
      return _buildManagerTaskArea();
    } else {
      return _buildEmployeeTaskArea();
    }
  }

  Widget _buildManagerTaskArea() {
    final deviceKeys = widget.devices.keys.toList();
    if (_selectedEmployeeKey == null && deviceKeys.isNotEmpty) {
      _selectedEmployeeKey = deviceKeys.first;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📋 Quản Lý Giao Việc',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
          ),
          const SizedBox(height: 12),

          // Employee Select
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Chọn nhân viên:', style: TextStyle(fontWeight: FontWeight.bold)),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5D3FD3),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        ),
                        onPressed: _openTransferTaskModal,
                        child: const Text('🔄 NHẬN VIỆC TỪ...', style: TextStyle(color: Colors.white, fontSize: 11)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedEmployeeKey,
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                    items: deviceKeys.map((key) {
                      final dev = widget.devices[key]!;
                      return DropdownMenuItem(
                        value: key,
                        child: Text('👤 ${dev.name} (${dev.role})'),
                      );
                    }).toList(),
                    onChanged: (v) => setState(() => _selectedEmployeeKey = v),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Add Task Form
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Thêm công việc mới', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _taskContentController,
                    decoration: const InputDecoration(
                      hintText: 'Nhập tên việc cần làm...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<int>(
                    initialValue: _frequency,
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 0, child: Text('Tần suất: Một lần (Không lặp lại)')),
                      DropdownMenuItem(value: 1, child: Text('Tần suất: Hằng ngày')),
                      DropdownMenuItem(value: 2, child: Text('Tần suất: 2 ngày / lần')),
                      DropdownMenuItem(value: 7, child: Text('Tần suất: Hàng tuần')),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _frequency = v);
                    },
                  ),
                  const SizedBox(height: 10),
                  CheckboxListTile(
                    title: const Text('Việc quan trọng (Luôn đỏ)', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13)),
                    value: _isImportant,
                    onChanged: (v) => setState(() => _isImportant = v == true),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5D3FD3), padding: const EdgeInsets.symmetric(vertical: 12)),
                      onPressed: _addTaskByManager,
                      child: const Text('PHÂN VIỆC', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Task List for Selected Employee
          const Text('Danh sách công việc đang giao', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 8),
          if (_selectedEmployeeKey != null)
            FutureBuilder<Map<String, TaskModel>>(
              future: widget.firebaseService.getTasksForEmployee(_selectedEmployeeKey!),
              builder: (context, snapshot) {
                final tasksMap = snapshot.data ?? {};
                if (tasksMap.isEmpty) {
                  return const Text('Nhân viên này chưa có việc nào được giao.', style: TextStyle(color: Colors.grey));
                }

                return ListView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: tasksMap.entries.map((entry) {
                    final task = entry.value;
                    return Card(
                      child: ListTile(
                        leading: Checkbox(value: task.done, onChanged: null),
                        title: Text(
                          task.text,
                          style: TextStyle(
                            color: task.important ? Colors.red : Colors.black,
                            fontWeight: task.important ? FontWeight.bold : FontWeight.normal,
                            decoration: task.done ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            await widget.firebaseService.deleteTask(_selectedEmployeeKey!, task.id);
                            setState(() {});
                          },
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildEmployeeTaskArea() {
    return FutureBuilder<Map<String, TaskModel>>(
      future: widget.firebaseService.getTasksForEmployee(widget.currentDeviceId),
      builder: (context, snapshot) {
        final tasksMap = snapshot.data ?? {};

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('📋 Công Việc Của Bạn', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
              const SizedBox(height: 4),
              const Text('Tích chọn vào ô vuông bên cạnh khi bạn đã hoàn thành công việc.', style: TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 16),
              if (tasksMap.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: const Column(
                    children: [
                      Text('🎉 Tuyệt vời!', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 18)),
                      SizedBox(height: 6),
                      Text('Bạn không có việc nào cần xử lý lúc này.', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              else
                ListView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: tasksMap.entries.map((entry) {
                    final task = entry.value;
                    return Card(
                      child: CheckboxListTile(
                        value: task.done,
                        title: Text(
                          task.text,
                          style: TextStyle(
                            color: task.important ? Colors.red : Colors.black,
                            fontWeight: task.important ? FontWeight.bold : FontWeight.normal,
                            decoration: task.done ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        onChanged: (v) async {
                          await widget.firebaseService.updateTaskStatus(widget.currentDeviceId, task.id, v == true);
                          setState(() {});
                        },
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        );
      },
    );
  }

  void _addTaskByManager() async {
    final text = _taskContentController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng điền nội dung công việc!')));
      return;
    }
    if (_selectedEmployeeKey == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chưa chọn nhân viên nhận việc!')));
      return;
    }

    final task = TaskModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      important: _isImportant,
      frequency: _frequency,
      assignedAt: DateTime.now().toString(),
    );

    await widget.firebaseService.addTask(_selectedEmployeeKey!, task);
    _taskContentController.clear();
    setState(() {
      _isImportant = false;
      _frequency = 0;
    });
  }

  void _openTransferTaskModal() {
    String? sourceId;
    final otherDevices = widget.devices.keys.where((k) => k != _selectedEmployeeKey).toList();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: const Text('Nhận việc từ nhân viên khác'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Nhân viên nguồn', border: OutlineInputBorder()),
                    items: otherDevices.map((k) {
                      return DropdownMenuItem(value: k, child: Text(widget.devices[k]!.name));
                    }).toList(),
                    onChanged: (v) => setModalState(() => sourceId = v),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Hủy')),
                ElevatedButton(
                  onPressed: () async {
                    if (sourceId == null || _selectedEmployeeKey == null) return;
                    final sourceTasks = await widget.firebaseService.getTasksForEmployee(sourceId!);
                    for (var task in sourceTasks.values) {
                      await widget.firebaseService.addTask(_selectedEmployeeKey!, task);
                      await widget.firebaseService.deleteTask(sourceId!, task.id);
                    }
                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                    }
                    if (mounted) {
                      setState(() {});
                    }
                  },
                  child: const Text('XÁC NHẬN CHUYỂN'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
