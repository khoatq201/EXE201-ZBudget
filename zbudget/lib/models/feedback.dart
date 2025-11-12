class Feedback {
  final String id;
  final String? userId; // null nếu feedback anonymous
  final String name;
  final String email;
  final String type; // suggestion, bug, compliment, complaint
  final int rating;
  final String content;
  final String status; // pending, reviewed, resolved, archived
  final DeviceInfo? deviceInfo;
  final List<Attachment> attachments;
  final AdminResponse? adminResponse;
  final DateTime createdAt;
  final DateTime updatedAt;

  Feedback({
    required this.id,
    this.userId,
    required this.name,
    required this.email,
    required this.type,
    required this.rating,
    required this.content,
    required this.status,
    this.deviceInfo,
    required this.attachments,
    this.adminResponse,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Feedback.fromJson(Map<String, dynamic> json) {
    return Feedback(
      id: json['_id'] is Map ? json['_id']['\$oid'] as String : json['_id'] as String,
      userId: json['userId'] is Map
          ? json['userId']['\$oid'] as String?
          : json['userId'] as String?,
      name: json['name'] as String,
      email: json['email'] as String,
      type: json['type'] as String,
      rating: json['rating'] as int,
      content: json['content'] as String,
      status: json['status'] as String,
      deviceInfo: json['deviceInfo'] != null
          ? DeviceInfo.fromJson(json['deviceInfo'] as Map<String, dynamic>)
          : null,
      attachments: json['attachments'] != null
          ? (json['attachments'] as List)
              .map((e) => Attachment.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
      adminResponse: json['adminResponse'] != null
          ? AdminResponse.fromJson(json['adminResponse'] as Map<String, dynamic>)
          : null,
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();

    // Handle MongoDB date format: {"$date": "2025-11-12T04:55:16.458Z"}
    if (value is Map && value.containsKey('\$date')) {
      return DateTime.parse(value['\$date'] as String);
    }

    // Handle ISO string format
    if (value is String) {
      return DateTime.parse(value);
    }

    return DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userId': userId,
      'name': name,
      'email': email,
      'type': type,
      'rating': rating,
      'content': content,
      'status': status,
      'deviceInfo': deviceInfo?.toJson(),
      'attachments': attachments.map((e) => e.toJson()).toList(),
      'adminResponse': adminResponse?.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  String getTypeLabel() {
    const labels = {
      'suggestion': 'Đề xuất',
      'bug': 'Báo lỗi',
      'compliment': 'Khen ngợi',
      'complaint': 'Phàn nàn',
    };
    return labels[type] ?? type;
  }

  String getStatusLabel() {
    const labels = {
      'pending': 'Đang chờ',
      'reviewed': 'Đã xem',
      'resolved': 'Đã giải quyết',
      'archived': 'Lưu trữ',
    };
    return labels[status] ?? status;
  }
}

class DeviceInfo {
  final String platform;
  final String version;
  final String osVersion;

  DeviceInfo({
    required this.platform,
    required this.version,
    required this.osVersion,
  });

  factory DeviceInfo.fromJson(Map<String, dynamic> json) {
    return DeviceInfo(
      platform: json['platform'] as String? ?? '',
      version: json['version'] as String? ?? '',
      osVersion: json['osVersion'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'platform': platform,
      'version': version,
      'osVersion': osVersion,
    };
  }
}

class Attachment {
  final String url;
  final String type;
  final String name;

  Attachment({
    required this.url,
    required this.type,
    required this.name,
  });

  factory Attachment.fromJson(Map<String, dynamic> json) {
    return Attachment(
      url: json['url'] as String,
      type: json['type'] as String,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'type': type,
      'name': name,
    };
  }
}

class AdminResponse {
  final String message;
  final String? respondedBy;
  final DateTime? respondedAt;

  AdminResponse({
    required this.message,
    this.respondedBy,
    this.respondedAt,
  });

  factory AdminResponse.fromJson(Map<String, dynamic> json) {
    return AdminResponse(
      message: json['message'] as String,
      respondedBy: json['respondedBy'] is Map
          ? json['respondedBy']['\$oid'] as String?
          : json['respondedBy'] as String?,
      respondedAt: json['respondedAt'] != null
          ? (json['respondedAt'] is Map
              ? DateTime.parse(json['respondedAt']['\$date'] as String)
              : DateTime.parse(json['respondedAt'] as String))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'respondedBy': respondedBy,
      'respondedAt': respondedAt?.toIso8601String(),
    };
  }
}
