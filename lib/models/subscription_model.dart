class SubscriptionModel {
  final String status;
  final String startDate;
  final String endDate;

  SubscriptionModel({
    required this.status,
    required this.startDate,
    required this.endDate,
  });

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionModel(
      status:    json['status'],
      startDate: json['startDate'],
      endDate:   json['endDate'],
    );
  }
}