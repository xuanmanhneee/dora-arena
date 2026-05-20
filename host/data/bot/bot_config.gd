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

# ── ĐỘ KHÓ CAO ─────────────────────────────────────────────────────────────
@export var consider_explosion: bool = false
## Bật ở độ khó HARD trở lên
## Bot sẽ tính đến vùng nổ của đạn nổ khi quyết định dodge/retreat
