class TableItemModel {
  final String fName;
  final double price;
  final int qty;
  final bool done;
  final String? note;
  final String? orderStaff;

  TableItemModel({
    required this.fName,
    required this.price,
    required this.qty,
    this.done = false,
    this.note,
    this.orderStaff,
  });

  factory TableItemModel.fromJson(Map<String, dynamic> json) {
    return TableItemModel(
      fName: json['fName'] ?? json['name'] ?? '',
      price: ((json['price'] ?? 0) as num).toDouble(),
      qty: (json['qty'] ?? 1) as int,
      done: json['done'] == true,
      note: json['note'],
      orderStaff: json['orderStaff'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fName': fName,
      'price': price,
      'qty': qty,
      'done': done,
      if (note != null) 'note': note,
      if (orderStaff != null) 'orderStaff': orderStaff,
    };
  }
}

class TableModel {
  final int id;
  final String status; // 'white', 'red', 'green'
  final String? startTime;
  final bool needsServing;
  final bool printed;
  final List<TableItemModel> items;

  TableModel({
    required this.id,
    this.status = 'white',
    this.startTime,
    this.needsServing = false,
    this.printed = false,
    this.items = const [],
  });

  double get total {
    double sum = 0;
    for (var item in items) {
      sum += item.price * item.qty;
    }
    return sum;
  }

  factory TableModel.fromJson(int id, Map<String, dynamic> json) {
    List<TableItemModel> itemsList = [];
    if (json['items'] != null) {
      if (json['items'] is List) {
        for (var item in json['items']) {
          if (item != null && item is Map) {
            itemsList.add(TableItemModel.fromJson(Map<String, dynamic>.from(item)));
          }
        }
      } else if (json['items'] is Map) {
        (json['items'] as Map).forEach((k, v) {
          if (v != null && v is Map) {
            itemsList.add(TableItemModel.fromJson(Map<String, dynamic>.from(v)));
          }
        });
      }
    }

    return TableModel(
      id: id,
      status: json['status'] ?? 'white',
      startTime: json['startTime'],
      needsServing: json['needsServing'] == true,
      printed: json['printed'] == true,
      items: itemsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      if (startTime != null) 'startTime': startTime,
      'needsServing': needsServing,
      'printed': printed,
      'items': items.map((e) => e.toJson()).toList(),
    };
  }
}

class MenuItemModel {
  final String key;
  final String name;
  final double price;
  final String category;
  final bool hasHotCold;
  final bool soldOut;

  MenuItemModel({
    required this.key,
    required this.name,
    required this.price,
    this.category = 'Khác',
    this.hasHotCold = true,
    this.soldOut = false,
  });

  factory MenuItemModel.fromJson(String key, Map<String, dynamic> json) {
    return MenuItemModel(
      key: key,
      name: json['name'] ?? '',
      price: ((json['price'] ?? 0) as num).toDouble(),
      category: json['category'] ?? 'Khác',
      hasHotCold: json['hasHotCold'] != false,
      soldOut: json['soldOut'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price': price,
      'category': category,
      'hasHotCold': hasHotCold,
      'soldOut': soldOut,
    };
  }
}

class BillHistoryModel {
  final String key;
  final String time;
  final String? startTime;
  final String? payTime;
  final dynamic table;
  final double total;
  final String method; // 'cash' or 'transfer'
  final String? staff;
  final String? payStaff;
  final bool printed;
  final List<TableItemModel> items;

  BillHistoryModel({
    required this.key,
    required this.time,
    this.startTime,
    this.payTime,
    required this.table,
    required this.total,
    this.method = 'cash',
    this.staff,
    this.payStaff,
    this.printed = false,
    this.items = const [],
  });

  factory BillHistoryModel.fromJson(String key, Map<String, dynamic> json) {
    List<TableItemModel> itemsList = [];
    if (json['items'] != null && json['items'] is List) {
      for (var item in json['items']) {
        if (item != null && item is Map) {
          itemsList.add(TableItemModel.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }
    return BillHistoryModel(
      key: key,
      time: json['time'] ?? '',
      startTime: json['startTime'],
      payTime: json['payTime'],
      table: json['table'] ?? 'N/A',
      total: ((json['total'] ?? 0) as num).toDouble(),
      method: json['method'] ?? 'cash',
      staff: json['staff'],
      payStaff: json['payStaff'],
      printed: json['printed'] == true,
      items: itemsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'time': time,
      if (startTime != null) 'startTime': startTime,
      if (payTime != null) 'payTime': payTime,
      'table': table,
      'total': total,
      'method': method,
      if (staff != null) 'staff': staff,
      if (payStaff != null) 'payStaff': payStaff,
      'printed': printed,
      'items': items.map((e) => e.toJson()).toList(),
    };
  }
}

class ShiftModel {
  final String start;
  final double revenue;
  final double revenueCash;
  final double revenueTransfer;
  final Map<String, BillHistoryModel> history;

  ShiftModel({
    required this.start,
    this.revenue = 0,
    this.revenueCash = 0,
    this.revenueTransfer = 0,
    this.history = const {},
  });

  factory ShiftModel.fromJson(Map<String, dynamic> json) {
    Map<String, BillHistoryModel> historyMap = {};
    if (json['history'] != null && json['history'] is Map) {
      (json['history'] as Map).forEach((k, v) {
        if (v != null && v is Map) {
          historyMap[k.toString()] = BillHistoryModel.fromJson(k.toString(), Map<String, dynamic>.from(v));
        }
      });
    }
    return ShiftModel(
      start: json['start'] ?? '',
      revenue: ((json['revenue'] ?? 0) as num).toDouble(),
      revenueCash: ((json['revenueCash'] ?? 0) as num).toDouble(),
      revenueTransfer: ((json['revenueTransfer'] ?? 0) as num).toDouble(),
      history: historyMap,
    );
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> histJson = {};
    history.forEach((k, v) {
      histJson[k] = v.toJson();
    });
    return {
      'start': start,
      'revenue': revenue,
      'revenueCash': revenueCash,
      'revenueTransfer': revenueTransfer,
      'history': histJson,
    };
  }
}

class TaskModel {
  final String id;
  final String text;
  final bool important;
  final int frequency; // 0: Once, 1: Daily, 2: Every 2 days, 7: Weekly
  final int dueDate;
  final bool done;
  final String? assignedAt;

  TaskModel({
    required this.id,
    required this.text,
    this.important = false,
    this.frequency = 0,
    this.dueDate = 0,
    this.done = false,
    this.assignedAt,
  });

  factory TaskModel.fromJson(String id, Map<String, dynamic> json) {
    return TaskModel(
      id: id,
      text: json['text'] ?? '',
      important: json['important'] == true,
      frequency: (json['frequency'] ?? 0) as int,
      dueDate: (json['dueDate'] ?? 0) as int,
      done: json['done'] == true,
      assignedAt: json['assignedAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'important': important,
      'frequency': frequency,
      'dueDate': dueDate,
      'done': done,
      if (assignedAt != null) 'assignedAt': assignedAt,
    };
  }
}

class DeviceModel {
  final String id;
  final String name;
  final String password;
  final String role; // 'Phục vụ', 'Thu ngân', 'Quản lý'
  final String createdAt;

  DeviceModel({
    required this.id,
    required this.name,
    required this.password,
    this.role = 'Phục vụ',
    required this.createdAt,
  });

  factory DeviceModel.fromJson(String id, Map<String, dynamic> json) {
    return DeviceModel(
      id: id,
      name: json['name'] ?? '',
      password: json['password'] ?? '',
      role: json['role'] ?? 'Phục vụ',
      createdAt: json['createdAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'password': password,
      'role': role,
      'createdAt': createdAt,
    };
  }
}

class EditLogModel {
  final String? timestamp;
  final String? time;
  final String? date;
  final String action;
  final String details;
  final String reason;
  final dynamic table;
  final String staff;

  EditLogModel({
    this.timestamp,
    this.time,
    this.date,
    required this.action,
    required this.details,
    required this.reason,
    this.table,
    required this.staff,
  });

  factory EditLogModel.fromJson(Map<String, dynamic> json) {
    return EditLogModel(
      timestamp: json['timestamp'],
      time: json['time'],
      date: json['date'],
      action: json['action'] ?? '',
      details: json['details'] ?? '',
      reason: json['reason'] ?? '',
      table: json['table'],
      staff: json['staff'] ?? 'N/A',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (timestamp != null) 'timestamp': timestamp,
      if (time != null) 'time': time,
      if (date != null) 'date': date,
      'action': action,
      'details': details,
      'reason': reason,
      'table': table ?? 'N/A',
      'staff': staff,
    };
  }
}

class ShiftLogModel {
  final String id;
  final String start;
  final String end;
  final String date;
  final double revenue;
  final double revenueCash;
  final double revenueTransfer;
  final int timestamp;

  ShiftLogModel({
    required this.id,
    required this.start,
    required this.end,
    required this.date,
    required this.revenue,
    required this.revenueCash,
    required this.revenueTransfer,
    required this.timestamp,
  });

  factory ShiftLogModel.fromJson(String id, Map<String, dynamic> json) {
    return ShiftLogModel(
      id: id,
      start: json['start'] ?? '',
      end: json['end'] ?? '',
      date: json['date'] ?? '',
      revenue: ((json['revenue'] ?? 0) as num).toDouble(),
      revenueCash: ((json['revenueCash'] ?? 0) as num).toDouble(),
      revenueTransfer: ((json['revenueTransfer'] ?? 0) as num).toDouble(),
      timestamp: (json['timestamp'] ?? 0) as int,
    );
  }
}
