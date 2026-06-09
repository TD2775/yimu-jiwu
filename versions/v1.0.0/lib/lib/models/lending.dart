/// 借出状态枚举
enum LendStatus { borrowed, returned, renewed, lost }

/// 借出记录模型
class Lending {
  final String id;
  final String itemId;
  final String borrowerName;
  final String? borrowerContact;
  final DateTime borrowDate;
  final DateTime? expectedReturnDate;
  final DateTime? actualReturnDate;
  final LendStatus status;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Lending({
    required this.id,
    required this.itemId,
    required this.borrowerName,
    this.borrowerContact,
    required this.borrowDate,
    this.expectedReturnDate,
    this.actualReturnDate,
    this.status = LendStatus.borrowed,
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  String get statusLabel {
    switch (status) {
      case LendStatus.borrowed:
        return '借出中';
      case LendStatus.returned:
        return '已归还';
      case LendStatus.renewed:
        return '已续借';
      case LendStatus.lost:
        return '已丢失';
    }
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'itemId': itemId,
        'borrowerName': borrowerName,
        'borrowerContact': borrowerContact,
        'borrowDate': borrowDate.toIso8601String(),
        'expectedReturnDate': expectedReturnDate?.toIso8601String(),
        'actualReturnDate': actualReturnDate?.toIso8601String(),
        'status': status.index,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Lending.fromMap(Map<String, dynamic> map) => Lending(
        id: map['id'],
        itemId: map['itemId'],
        borrowerName: map['borrowerName'],
        borrowerContact: map['borrowerContact'],
        borrowDate: DateTime.parse(map['borrowDate']),
        expectedReturnDate: map['expectedReturnDate'] != null
            ? DateTime.parse(map['expectedReturnDate'])
            : null,
        actualReturnDate: map['actualReturnDate'] != null
            ? DateTime.parse(map['actualReturnDate'])
            : null,
        status: LendStatus.values[map['status'] ?? 0],
        notes: map['notes'],
        createdAt: DateTime.parse(map['createdAt']),
        updatedAt: DateTime.parse(map['updatedAt']),
      );

  Lending copyWith({
    String? borrowerName,
    String? borrowerContact,
    DateTime? expectedReturnDate,
    DateTime? actualReturnDate,
    LendStatus? status,
    String? notes,
  }) =>
      Lending(
        id: id,
        itemId: itemId,
        borrowerName: borrowerName ?? this.borrowerName,
        borrowerContact: borrowerContact ?? this.borrowerContact,
        borrowDate: borrowDate,
        expectedReturnDate: expectedReturnDate ?? this.expectedReturnDate,
        actualReturnDate: actualReturnDate ?? this.actualReturnDate,
        status: status ?? this.status,
        notes: notes ?? this.notes,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );
}
