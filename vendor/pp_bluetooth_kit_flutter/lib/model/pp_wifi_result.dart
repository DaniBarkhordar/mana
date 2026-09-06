

class PPWifiResult {
  bool success;
  String? sn;
  int? errorCode;

  PPWifiResult(
      {
        required this.success,
        this.sn,
        this.errorCode}
      );
}