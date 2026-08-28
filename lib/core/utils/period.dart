/// Sıralama dönemlerinin (ayların) kimliği: "2026-08".
///
/// Tek yerde tutuluyor çünkü hem puan yazan taraf hem sıralamayı okuyan
/// taraf AYNI biçimi üretmek zorunda; iki ayrı yerde hesaplanırsa
/// biçimler sessizce ayrışabilir.
///
/// Cihaz saatinden üretiliyor — mevcut "istemciye güven" modeliyle
/// tutarlı. Sunucu saatine taşımak, puan doğrulamasıyla birlikte
/// Cloud Functions'a geçildiğinde yapılacak.
String suankiDonem([DateTime? now]) => _donem(now ?? DateTime.now());

/// Bir önceki ayın kimliği. Ocak'ta bir önceki yılın Aralık'ına döner.
String oncekiDonem([DateTime? now]) {
  final t = now ?? DateTime.now();
  // Ayın 0. günü = bir önceki ayın son günü; yıl geçişini de doğru yapar.
  return _donem(DateTime(t.year, t.month, 0));
}

String _donem(DateTime t) => '${t.year}-${t.month.toString().padLeft(2, '0')}';

/// Dönem kimliğini insan okunur hale getirir: "2026-08" -> "Ağustos 2026".
String donemAdi(String donem) {
  const aylar = [
    'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
    'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık',
  ];
  final parcalar = donem.split('-');
  if (parcalar.length != 2) return donem;
  final ay = int.tryParse(parcalar[1]);
  if (ay == null || ay < 1 || ay > 12) return donem;
  return '${aylar[ay - 1]} ${parcalar[0]}';
}
