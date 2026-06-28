class ReportModel {
  final int id;
  final int userId;
  final String reportType;
  final String title;
  final String category;
  final String description;
  final String location;
  final String reportDate;
  final String status;
  final String image;
  final String createdAt;
  final String updatedAt;
  final String userName;
  final String userEmail;
  final String userPhone;

  const ReportModel({
    required this.id,
    required this.userId,
    required this.reportType,
    required this.title,
    required this.category,
    required this.description,
    required this.location,
    required this.reportDate,
    required this.status,
    required this.image,
    required this.createdAt,
    required this.updatedAt,
    required this.userName,
    required this.userEmail,
    required this.userPhone,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      userId: int.tryParse(json['user_id'].toString()) ?? 0,
      reportType: (json['report_type'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      location: (json['location'] ?? '').toString(),
      reportDate: (json['report_date'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      image: (json['image'] ?? '').toString(),
      createdAt: (json['created_at'] ?? '').toString(),
      updatedAt: (json['updated_at'] ?? '').toString(),
      userName: (json['user_name'] ?? '').toString(),
      userEmail: (json['user_email'] ?? '').toString(),
      userPhone: (json['user_phone'] ?? '').toString(),
    );
  }
}
