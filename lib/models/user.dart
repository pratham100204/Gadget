class UserData {
  /// More private userData to store general info about users
  String? uid;
  String? email;
  String? name; // <--- ADDED: Name field
  bool? verified;
  String? targetEmail;
  Map<String, dynamic>? roles;
  bool? checkStock;

  UserData({
    this.uid,
    this.email,
    this.name, // <--- ADDED: In Constructor
    this.targetEmail,
    this.verified,
    this.roles,
    this.checkStock,
  });

  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{};
    map['targetEmail'] = this.targetEmail;
    map['email'] = this.email;
    map['name'] = this.name; // <--- ADDED: Write to database
    map['uid'] = this.uid;
    map['verified'] = this.verified;
    map['roles'] = this.roles;
    map['checkStock'] = this.checkStock;
    return map;
  }

  UserData.fromMapObject(Map<String, dynamic> map) {
    this.uid = map['uid'];
    this.verified = map['verified'];
    this.email = map['email'];
    this.name = map['name']; // <--- ADDED: Read from database
    this.targetEmail = map['targetEmail'];
    this.roles = map['roles'];
    this.checkStock = map['checkStock'];
  }
}
