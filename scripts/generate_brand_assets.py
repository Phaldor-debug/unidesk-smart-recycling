"""
Ünidesk marka görselleri üretici.
Çalıştırma: python scripts/generate_brand_assets.py
Çıktılar: assets/icon/app_icon.png, assets/icon/app_icon_foreground.png
"""
from PIL import Image, ImageDraw, ImageFont

GREEN = (34, 197, 94, 255)       # #22C55E — ana marka rengi
GOLD = (255, 184, 0, 255)        # #FFB800 — puan/ödül vurgusu
WHITE = (255, 255, 255, 255)

FONT_PATH = r"C:\Windows\Fonts\segoeuib.ttf"  # Segoe UI Bold
SIZE = 1024


def rounded_square(size, color, radius_ratio=0.22):
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    radius = int(size * radius_ratio)
    draw.rounded_rectangle([0, 0, size - 1, size - 1], radius=radius, fill=color)
    return img


def draw_mark(canvas, center, ring_radius, ring_width, letter_box):
    """Ortak marka işareti: altın halka + ortada beyaz 'Ü' harfi."""
    draw = ImageDraw.Draw(canvas)
    cx, cy = center

    # Altın halka (rozet/ödül hissi)
    draw.ellipse(
        [cx - ring_radius, cy - ring_radius, cx + ring_radius, cy + ring_radius],
        outline=GOLD,
        width=ring_width,
    )

    # Beyaz "Ü" harfi — kutuya sığacak en büyük font boyutunu bulup ortala.
    font_size = 10
    font = ImageFont.truetype(FONT_PATH, font_size)
    target_w, target_h = letter_box
    while True:
        test_font = ImageFont.truetype(FONT_PATH, font_size + 10)
        bbox = draw.textbbox((0, 0), "Ü", font=test_font)
        w, h = bbox[2] - bbox[0], bbox[3] - bbox[1]
        if w > target_w or h > target_h:
            break
        font = test_font
        font_size += 10

    bbox = draw.textbbox((0, 0), "Ü", font=font)
    w, h = bbox[2] - bbox[0], bbox[3] - bbox[1]
    pos = (cx - w / 2 - bbox[0], cy - h / 2 - bbox[1])
    draw.text(pos, "Ü", font=font, fill=WHITE)


# 1) Tam ikon: yeşil yuvarlak kare zemin + işaret (iOS / web / genel kullanım)
full_icon = rounded_square(SIZE, GREEN)
draw_mark(
    full_icon,
    center=(SIZE // 2, SIZE // 2),
    ring_radius=int(SIZE * 0.34),
    ring_width=int(SIZE * 0.022),
    letter_box=(SIZE * 0.42, SIZE * 0.42),
)
full_icon.save("assets/icon/app_icon.png")

# 2) SADECE ön yüz: şeffaf zemin + işaret (Android adaptif ikon — arka planı
# ayrı bir düz renk olarak ayarlanacak, telefon bunu kendi şekline göre kesecek).
# Adaptif ikonlarda güvenli alan kenarlardan geniş boşluk ister, o yüzden
# işareti tam ikondakinden daha küçük ve ortalı çiziyoruz.
foreground = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
draw_mark(
    foreground,
    center=(SIZE // 2, SIZE // 2),
    ring_radius=int(SIZE * 0.24),
    ring_width=int(SIZE * 0.018),
    letter_box=(SIZE * 0.30, SIZE * 0.30),
)
foreground.save("assets/icon/app_icon_foreground.png")

print("Üretildi: assets/icon/app_icon.png, assets/icon/app_icon_foreground.png")


# ---------------------------------------------------------------------------
# Atık türü ikonları — SelectWastePage'in büyük kartlarında kullanılacak.
# Hepsi beyaz, şeffaf zeminli (kartın kendi rengi üzerine bindirilecek).
# ---------------------------------------------------------------------------
ICON_SIZE = 512


def bottle(size, neck_ratio, body_ratio, shoulder_y_ratio, cap_h_ratio):
    """Basit, düz-tasarım bir şişe silüeti. Plastik/cam için oran farklı verilir."""
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx = size / 2
    top_y = size * 0.06
    cap_h = size * cap_h_ratio
    neck_w = size * neck_ratio
    body_w = size * body_ratio
    shoulder_y = size * shoulder_y_ratio
    bottom_y = size * 0.94

    draw.rounded_rectangle(
        [cx - neck_w / 2 - size * 0.015, top_y, cx + neck_w / 2 + size * 0.015, top_y + cap_h],
        radius=int(size * 0.02),
        fill=WHITE,
    )
    neck_top = top_y + cap_h
    points = [
        (cx - neck_w / 2, neck_top),
        (cx + neck_w / 2, neck_top),
        (cx + neck_w / 2, shoulder_y),
        (cx + body_w / 2, shoulder_y + size * 0.06),
        (cx + body_w / 2, bottom_y - size * 0.05),
        (cx, bottom_y),
        (cx - body_w / 2, bottom_y - size * 0.05),
        (cx - body_w / 2, shoulder_y + size * 0.06),
        (cx - neck_w / 2, shoulder_y),
    ]
    draw.polygon(points, fill=WHITE)
    return img


# Plastik: ince/uzun, dar boyunlu tipik pet şişe + gövdede birkaç ince
# "kaburga" çizgisi (pet şişelerin tipik sıkıştırma oluğu hissi).
plastik_icon = bottle(ICON_SIZE, neck_ratio=0.16, body_ratio=0.5, shoulder_y_ratio=0.28, cap_h_ratio=0.08)
pdraw = ImageDraw.Draw(plastik_icon)
for ratio in (0.62, 0.72, 0.82):
    y = ICON_SIZE * ratio
    pdraw.rectangle(
        [ICON_SIZE * 0.30, y, ICON_SIZE * 0.70, y + ICON_SIZE * 0.014],
        fill=(0, 0, 0, 0),
    )
plastik_icon.save("assets/icons/plastik.png")

# Cam: daha bombeli/geniş gövdeli klasik cam şişe + gövdede çapraz bir
# "parlama/yansıma" çizgisi (cam malzemesini hemen ayırt ettiren detay).
cam_icon = bottle(ICON_SIZE, neck_ratio=0.20, body_ratio=0.64, shoulder_y_ratio=0.34, cap_h_ratio=0.06)
cdraw = ImageDraw.Draw(cam_icon)
cdraw.polygon(
    [
        (ICON_SIZE * 0.30, ICON_SIZE * 0.40),
        (ICON_SIZE * 0.38, ICON_SIZE * 0.40),
        (ICON_SIZE * 0.30, ICON_SIZE * 0.82),
        (ICON_SIZE * 0.22, ICON_SIZE * 0.82),
    ],
    fill=(0, 0, 0, 0),
)
cam_icon.save("assets/icons/cam.png")

# Kağıt: köşesi kıvrık bir kâğıt/döküman + üzerinde birkaç "yazı satırı"
# (satırlar şeffaf oyuk olarak açılıyor, tek renkli silüette detay katıyor).
paper = Image.new("RGBA", (ICON_SIZE, ICON_SIZE), (0, 0, 0, 0))
draw = ImageDraw.Draw(paper)
margin_x = ICON_SIZE * 0.22
top = ICON_SIZE * 0.08
bottom = ICON_SIZE * 0.92
right = ICON_SIZE - margin_x
left = margin_x
fold = ICON_SIZE * 0.16
draw.polygon(
    [
        (left, top),
        (right - fold, top),
        (right, top + fold),
        (right, bottom),
        (left, bottom),
    ],
    fill=WHITE,
)
# Yazı satırları: dolu alanın içine şeffaf ince dikdörtgenler "oyuyoruz".
line_y_positions = [0.45, 0.58, 0.71]
for ratio in line_y_positions:
    y = ICON_SIZE * ratio
    draw.rectangle(
        [left + ICON_SIZE * 0.10, y, right - ICON_SIZE * 0.10, y + ICON_SIZE * 0.035],
        fill=(0, 0, 0, 0),
    )
paper.save("assets/icons/kagit.png")

print("Üretildi: assets/icons/plastik.png, assets/icons/cam.png, assets/icons/kagit.png")
