import 'package:klcn_app/network/api_client.dart';

class PaymentService {
  PaymentService._();
  static final PaymentService instance = PaymentService._();

  final _api = ApiClient.instance;

  Future<String> createVnPayPayment(int bookingId) async {
    final res = await _api.post(
      '/api/payments/vnpay/create/$bookingId?platform=mobile',
    );
    return res.raw<String>();
  }
}