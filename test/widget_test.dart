// Bu proje Firebase'e bağımlı olduğu için (FirebaseAuth.instance, main.dart'ta
// Firebase.initializeApp çağrılmadan çalışmaz), gerçek widget testleri Firebase
// sahte (mock) servisleri kurulana kadar burada tutulmuyor. Şimdilik sadece test
// altyapısının çalıştığını doğrulayan bir sağlık kontrolü var.
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('test altyapisi calisiyor', () {
    expect(1 + 1, 2);
  });
}
