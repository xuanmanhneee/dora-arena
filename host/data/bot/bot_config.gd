class_name BotConfig
extends Resource

# ── NHẬN BIẾT ──────────────────────────────────────────────────────────────
@export var detect_radius: float = 200.0
## Bán kính phát hiện đạn địch (dùng cho dodge và cảnh giác)

# ── PHẢN XẠ ────────────────────────────────────────────────────────────────
@export var reaction_delay: float = 0.5
## Thời gian giữa mỗi lần bot "suy nghĩ" (giây)
## Thấp = phản xạ nhanh, cao = chậm chạp hơn
## Thực tế sẽ bị jitter ±30% để trông tự nhiên hơn

# ── KHOẢNG CÁCH ────────────────────────────────────────────────────────────
@export var preferred_dist_min: float = 180.0
## Khoảng cách tối thiểu bot muốn giữ với enemy
## Gần hơn → chuyển sang RETREAT

@export var preferred_dist_max: float = 300.0
## Khoảng cách tối đa bot chịu đứng yên
## Xa hơn → chuyển sang CHASE
## Nên đặt gần với bullet max_distance để bot không tiến vào rồi lùi ra liên tục

# ── BẮN ────────────────────────────────────────────────────────────────────
@export var shoot_hesitate_chance: float = 0.35
## Xác suất bot "bỏ lỡ" cơ hội bắn dù đang trong tầm (0.0 = luôn bắn, 1.0 = không bao giờ bắn)
## Giúp bot trông ít robot hơn ở độ khó thấp

# ── WANDER ─────────────────────────────────────────────────────────────────
@export var wander_chance: float = 0.2
## Xác suất bot đi lạc ngẫu nhiên thay vì đứng yên khi đang ở state HOLD
## Giúp bot không đứng một chỗ quá lâu trông như tượng

@export var wander_duration: float = 0.6
## Bao lâu bot di chuyển theo hướng wander trước khi re-evaluate (giây)

# ── NÉ ĐẠN ─────────────────────────────────────────────────────────────────
@export var scan_bullets: bool = false
## Bật để bot phân tích trajectory đạn và né
## Easy/Normal: tắt. Hard/Asian: bật

@export var dodge_rate: float = 0.0
## Xác suất bot thực sự né khi phát hiện đạn nguy hiểm (0.0 = không bao giờ, 1.0 = luôn luôn)

# ── ĐỘ KHÓ CAO ─────────────────────────────────────────────────────────────
@export var consider_explosion: bool = false
## Bật ở độ khó HARD trở lên
## Bot sẽ tính đến vùng nổ của đạn nổ khi quyết định dodge/retreat

@export var check_enemy_buffs: bool = false
## Bật ở độ khó ASIAN
## Bot kiểm tra reflect / explosive_bullet của địch trước khi bắn

# ── NHẶT ITEM ──────────────────────────────────────────────────────────────
@export var item_seek_range: float = 100.0
## Bán kính tìm item (px). Asian = toàn màn hình

@export var item_priority: float = 0.5
## 0.0 = bỏ qua item, 1.0 = ưu tiên cao nhất
## Asian: tính thêm giá trị item theo HP hiện tại

# ── PLATFORM NAVIGATION ────────────────────────────────────────────────────
@export var use_platform_navigation: bool = false
## Bật để bot cố nhảy lên platform cao hơn để theo địch

@export var platform_seek_range: float = 0.0
## Bán kính tìm platform có thể nhảy tới (0 = tắt)
