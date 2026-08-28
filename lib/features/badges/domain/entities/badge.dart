import '../../../recycling/domain/entities/waste_type.dart';
import 'badge_stats.dart';

/// Rozetin hangi grupta gösterileceği.
enum BadgeGroup { kilometre, tur, sureklilik, siralama, ozel }

extension BadgeGroupX on BadgeGroup {
  String get label => switch (this) {
        BadgeGroup.kilometre => 'Kilometre Taşları',
        BadgeGroup.tur => 'Tür Uzmanlığı',
        BadgeGroup.sureklilik => 'Süreklilik',
        BadgeGroup.siralama => 'Sıralama',
        BadgeGroup.ozel => 'Özel',
      };
}

/// Tek bir rozet tanımı.
///
/// Tüm rozetler bu dosyadaki [tumRozetler] listesinde. Yeni rozet eklemek
/// ya da koşul değiştirmek için sadece burası düzenlenir — veri katmanına
/// veya arayüze dokunmak gerekmez.
class Achievement {
  const Achievement({
    required this.id,
    required this.emoji,
    required this.name,
    required this.description,
    required this.bonusPoints,
    required this.group,
    required this.kazanildiMi,
    this.ilerleme,
  });

  /// Firestore'da saklanan sabit kimlik. DEĞİŞTİRME — değişirse
  /// kullanıcıların kazandığı rozetler kaybolur.
  final String id;

  final String emoji;
  final String name;
  final String description;

  /// Rozet kazanılınca verilen bonus puan.
  ///
  /// Bu puan harcanabilir bakiyeye eklenir ama AYLIK SIRALAMAYA
  /// SAYILMAZ — sıralama saf olarak "bu ay ne kadar atık attın"ı
  /// ölçmeye devam etsin diye.
  final int bonusPoints;

  final BadgeGroup group;

  /// Koşul sağlandı mı?
  final bool Function(BadgeStats stats) kazanildiMi;

  /// 0..1 arası ilerleme (kilitliyken çubuk göstermek için).
  /// Ölçülebilir bir hedefi yoksa null.
  final double Function(BadgeStats stats)? ilerleme;

  double ilerlemeOrani(BadgeStats stats) {
    if (kazanildiMi(stats)) return 1;
    final f = ilerleme;
    if (f == null) return 0;
    return f(stats).clamp(0.0, 1.0);
  }
}

double _oran(num mevcut, num hedef) => hedef <= 0 ? 0 : mevcut / hedef;

/// Uygulamadaki TÜM rozetler.
const _kilometreHedefleri = <String, (String, String, int, int)>{
  // id: (emoji, ad, hedef adet, bonus puan)
  'ilk_adim': ('🌱', 'İlk Adım', 1, 10),
  'onluk': ('♻️', 'Onluk', 10, 25),
  'yarim_yuz': ('🏅', 'Yarım Yüz', 50, 75),
  'yuzler_kulubu': ('💯', 'Yüzler Kulübü', 100, 150),
};

final List<Achievement> tumRozetler = [
  // --- Kilometre taşları ---
  for (final giris in _kilometreHedefleri.entries)
    Achievement(
      id: giris.key,
      emoji: giris.value.$1,
      name: giris.value.$2,
      description: '${giris.value.$3} atık geri dönüşüme kazandır',
      bonusPoints: giris.value.$4,
      group: BadgeGroup.kilometre,
      kazanildiMi: (s) => s.totalItems >= giris.value.$3,
      ilerleme: (s) => _oran(s.totalItems, giris.value.$3),
    ),

  // --- Tür uzmanlığı ---
  Achievement(
    id: 'plastik_avcisi',
    emoji: '🧴',
    name: 'Plastik Avcısı',
    description: '25 plastik atık at',
    bonusPoints: 50,
    group: BadgeGroup.tur,
    kazanildiMi: (s) => s.tur(WasteType.plastik) >= 25,
    ilerleme: (s) => _oran(s.tur(WasteType.plastik), 25),
  ),
  Achievement(
    id: 'kagit_koruyucu',
    emoji: '📄',
    name: 'Kağıt Koruyucu',
    description: '25 kağıt atık at',
    bonusPoints: 50,
    group: BadgeGroup.tur,
    kazanildiMi: (s) => s.tur(WasteType.kagit) >= 25,
    ilerleme: (s) => _oran(s.tur(WasteType.kagit), 25),
  ),
  Achievement(
    id: 'cam_ustasi',
    emoji: '🍾',
    name: 'Cam Ustası',
    description: '25 cam atık at',
    bonusPoints: 50,
    group: BadgeGroup.tur,
    kazanildiMi: (s) => s.tur(WasteType.cam) >= 25,
    ilerleme: (s) => _oran(s.tur(WasteType.cam), 25),
  ),
  Achievement(
    id: 'ucleme',
    emoji: '🎯',
    name: 'Üçleme',
    description: 'Her türden en az 10 atık at',
    bonusPoints: 100,
    group: BadgeGroup.tur,
    kazanildiMi: (s) => WasteType.values.every((t) => s.tur(t) >= 10),
    // İlerleme: en geride kalan türe göre — hepsi tamamlanmadan dolmaz.
    ilerleme: (s) => _oran(
      WasteType.values.map((t) => s.tur(t).clamp(0, 10)).reduce((a, b) => a + b),
      WasteType.values.length * 10,
    ),
  ),

  // --- Süreklilik ---
  Achievement(
    id: 'duzenli',
    emoji: '📅',
    name: 'Düzenli',
    description: '3 gün üst üste atık at',
    bonusPoints: 30,
    group: BadgeGroup.sureklilik,
    kazanildiMi: (s) => s.currentStreak >= 3,
    ilerleme: (s) => _oran(s.currentStreak, 3),
  ),
  Achievement(
    id: 'haftalik_kahraman',
    emoji: '🔥',
    name: 'Haftalık Kahraman',
    description: '7 gün üst üste atık at',
    bonusPoints: 100,
    group: BadgeGroup.sureklilik,
    kazanildiMi: (s) => s.currentStreak >= 7,
    ilerleme: (s) => _oran(s.currentStreak, 7),
  ),
  Achievement(
    id: 'donem_boyu',
    emoji: '📚',
    name: 'Dönem Boyu',
    description: 'Bir ayda 15 farklı gün atık at',
    bonusPoints: 120,
    group: BadgeGroup.sureklilik,
    kazanildiMi: (s) => s.activeDaysThisMonth >= 15,
    ilerleme: (s) => _oran(s.activeDaysThisMonth, 15),
  ),

  // --- Sıralama ---
  Achievement(
    id: 'podyum',
    emoji: '🥉',
    name: 'Podyum',
    description: 'Bir ayı ilk 3\'te bitir',
    bonusPoints: 100,
    group: BadgeGroup.siralama,
    kazanildiMi: (s) => s.podiumFinishes >= 1,
  ),
  Achievement(
    id: 'sampiyon',
    emoji: '👑',
    name: 'Şampiyon',
    description: 'Bir ayı 1. sırada bitir',
    bonusPoints: 200,
    group: BadgeGroup.siralama,
    kazanildiMi: (s) => s.championFinishes >= 1,
  ),

  // --- Özel ---
  Achievement(
    id: 'cevre_dostu',
    emoji: '🌍',
    name: 'Çevre Dostu',
    description: '1 kg CO₂ salımını önle',
    bonusPoints: 80,
    group: BadgeGroup.ozel,
    kazanildiMi: (s) => s.co2Kg >= 1.0,
    ilerleme: (s) => _oran(s.co2Kg, 1.0),
  ),
  Achievement(
    id: 'oncu',
    emoji: '🤝',
    name: 'Öncü',
    description: 'İlk 50 kullanıcıdan biri ol',
    bonusPoints: 50,
    group: BadgeGroup.ozel,
    // registrationNo 0 ise bilinmiyor demektir (bu alan eklenmeden önce
    // kaydolmuş kullanıcılar) — rozeti vermiyoruz.
    kazanildiMi: (s) => s.registrationNo > 0 && s.registrationNo <= 50,
  ),
];

Achievement? rozetBul(String id) {
  for (final r in tumRozetler) {
    if (r.id == id) return r;
  }
  return null;
}
