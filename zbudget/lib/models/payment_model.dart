/// Payment models for premium subscription payments

enum PaymentStatus {
  pending,
  completed,
  cancelled,
  rejected;

  String get displayName {
    switch (this) {
      case PaymentStatus.pending:
        return 'Chờ duyệt';
      case PaymentStatus.completed:
        return 'Hoàn thành';
      case PaymentStatus.cancelled:
        return 'Đã hủy';
      case PaymentStatus.rejected:
        return 'Bị từ chối';
    }
  }

  static PaymentStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return PaymentStatus.pending;
      case 'completed':
        return PaymentStatus.completed;
      case 'cancelled':
        return PaymentStatus.cancelled;
      case 'rejected':
        return PaymentStatus.rejected;
      default:
        return PaymentStatus.pending;
    }
  }
}

class BankAccount {
  final String accountNumber;
  final String bankName;
  final String accountName;

  BankAccount({
    required this.accountNumber,
    required this.bankName,
    required this.accountName,
  });

  factory BankAccount.fromJson(Map<String, dynamic> json) {
    return BankAccount(
      accountNumber: json['accountNumber'] ?? '',
      bankName: json['bankName'] ?? '',
      accountName: json['accountName'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accountNumber': accountNumber,
      'bankName': bankName,
      'accountName': accountName,
    };
  }
}

class Payment {
  final String id;
  final String referenceCode;
  final int amount;
  final String currency;
  final String planType;
  final String qrCodeUrl;
  final BankAccount bankAccount;
  final PaymentStatus status;
  final DateTime createdAt;
  final DateTime? approvedAt;
  final DateTime? rejectedAt;
  final String? rejectionReason;
  final String? instructions;

  Payment({
    required this.id,
    required this.referenceCode,
    required this.amount,
    this.currency = 'VND',
    required this.planType,
    required this.qrCodeUrl,
    required this.bankAccount,
    required this.status,
    required this.createdAt,
    this.approvedAt,
    this.rejectedAt,
    this.rejectionReason,
    this.instructions,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['_id'] ?? json['id'] ?? '',
      referenceCode: json['referenceCode'] ?? '',
      amount: json['amount'] ?? 0,
      currency: json['currency'] ?? 'VND',
      planType: json['planType'] ?? '',
      qrCodeUrl: json['qrCodeUrl'] ?? '',
      bankAccount: BankAccount.fromJson(json['bankAccount'] ?? {}),
      status: PaymentStatus.fromString(json['status'] ?? 'pending'),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      approvedAt: json['approvedAt'] != null ? DateTime.parse(json['approvedAt']) : null,
      rejectedAt: json['rejectedAt'] != null ? DateTime.parse(json['rejectedAt']) : null,
      rejectionReason: json['rejectionReason'],
      instructions: json['instructions'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'referenceCode': referenceCode,
      'amount': amount,
      'currency': currency,
      'planType': planType,
      'qrCodeUrl': qrCodeUrl,
      'bankAccount': bankAccount.toJson(),
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      if (approvedAt != null) 'approvedAt': approvedAt!.toIso8601String(),
      if (rejectedAt != null) 'rejectedAt': rejectedAt!.toIso8601String(),
      if (rejectionReason != null) 'rejectionReason': rejectionReason,
      if (instructions != null) 'instructions': instructions,
    };
  }

  bool get isPending => status == PaymentStatus.pending;
  bool get isCompleted => status == PaymentStatus.completed;
  bool get canCancel => status == PaymentStatus.pending;

  String get planDisplayName {
    switch (planType) {
      case 'monthly':
        return 'Gói Tháng';
      case 'yearly':
        return 'Gói Năm';
      default:
        return planType;
    }
  }

  String get formattedAmount {
    return '${amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    )} $currency';
  }
}

class PaymentRequest {
  final String paymentId;
  final String referenceCode;
  final int amount;
  final String currency;
  final String planType;
  final String qrCodeUrl;
  final BankAccount bankAccount;
  final PaymentStatus status;
  final DateTime createdAt;
  final String? instructions;

  PaymentRequest({
    required this.paymentId,
    required this.referenceCode,
    required this.amount,
    this.currency = 'VND',
    required this.planType,
    required this.qrCodeUrl,
    required this.bankAccount,
    required this.status,
    required this.createdAt,
    this.instructions,
  });

  factory PaymentRequest.fromJson(Map<String, dynamic> json) {
    return PaymentRequest(
      paymentId: json['paymentId'] ?? '',
      referenceCode: json['referenceCode'] ?? '',
      amount: json['amount'] ?? 0,
      currency: json['currency'] ?? 'VND',
      planType: json['planType'] ?? '',
      qrCodeUrl: json['qrCodeUrl'] ?? '',
      bankAccount: BankAccount.fromJson(json['bankAccount'] ?? {}),
      status: PaymentStatus.fromString(json['status'] ?? 'pending'),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      instructions: json['instructions'],
    );
  }
}
