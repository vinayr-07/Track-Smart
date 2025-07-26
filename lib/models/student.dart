class Student {
  final String id;
  final String name;
  final String joiningDate;
  final double fee;
  final String paymentType;
  final int batch;
  final String? contact;
  final String? notes;

  Student({
    required this.id,
    required this.name,
    required this.joiningDate,
    required this.fee,
    required this.paymentType,
    required this.batch,
    this.contact,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'joiningDate': joiningDate,
      'fee': fee,
      'paymentType': paymentType,
      'batch': batch,
      'contact': contact,
      'notes': notes,
    };
  }

  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      id: map['id'],
      name: map['name'],
      joiningDate: map['joiningDate'],
      fee: map['fee'].toDouble(),
      paymentType: map['paymentType'],
      batch: map['batch'],
      contact: map['contact'],
      notes: map['notes'],
    );
  }

  Student copyWith({
    String? id,
    String? name,
    String? joiningDate,
    double? fee,
    String? paymentType,
    int? batch,
    String? contact,
    String? notes,
  }) {
    return Student(
      id: id ?? this.id,
      name: name ?? this.name,
      joiningDate: joiningDate ?? this.joiningDate,
      fee: fee ?? this.fee,
      paymentType: paymentType ?? this.paymentType,
      batch: batch ?? this.batch,
      contact: contact ?? this.contact,
      notes: notes ?? this.notes,
    );
  }
}
