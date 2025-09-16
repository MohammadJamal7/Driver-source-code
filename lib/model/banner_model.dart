class BannerModel {
  String? image;
  bool? enable;
  String? id;
  String? forWho;
  bool? isDeleted;
  int? positionDriver;
  int? positionCustomer;

  BannerModel({
    this.image,
    this.enable,
    this.id,
    this.forWho,
    this.isDeleted,
    this.positionDriver,
    this.positionCustomer,
  });

  BannerModel.fromJson(Map<String, dynamic> json) {
    image = json['image'];
    enable = json['enable'];
    id = json['id'];
    forWho = json['forWho'];
    isDeleted = json['isDeleted'];
    positionDriver = _toInt(json['position_driver']);
    positionCustomer = _toInt(json['position_customer']);
  }

  Map<String, dynamic> toJson() {
    return {
      'image': image,
      'enable': enable,
      'id': id,
      'forWho': forWho,
      'isDeleted': isDeleted,
      'position_driver': positionDriver,
      'position_customer': positionCustomer,
    };
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }
}

class OtherBannerModel {
  String? image;

  OtherBannerModel({
    this.image,
  });

  OtherBannerModel.fromJson(Map<String, dynamic> json) {
    image = json['image'];
  }
}
