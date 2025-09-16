class VehicleYearModel {
   String? id;
   String? year;
   bool? enable;

  VehicleYearModel({
     this.id,
     this.year,
     this.enable,
  });

  factory VehicleYearModel.fromJson(Map<String, dynamic> json) {
    return VehicleYearModel(
      id: json['id'] ?? '',
      year: json['year'] ?? '',
      enable: json['enable'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'year': year,
      'enable': enable,
    };
  }
}
