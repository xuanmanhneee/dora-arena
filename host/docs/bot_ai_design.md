# Thiết kế Bot AI - Platformer Shooter

## Tổng quan

Bot và người chơi đều dùng chung `PlayerInput`. Bot được điều khiển bởi `BotController` thay vì input từ bàn phím. Cùng một logic, khác config → scalable, dễ tune.

---

## Kiến trúc

```
GameManager
    │
    ├─ Player (Human) ──→ PlayerInput ←── _input() / _process()
    │
    └─ Player (Bot) ────→ PlayerInput ←── BotController.think(delta)
                                │
                            BotConfig (Resource)
                            BotPerception (quét môi trường)
```

### BotConfig — Resource, chỉnh trong editor
```gdscript
class_name BotConfig
extends Resource

@export var reaction_delay: float
@export var shoot_rate: float
@export var dodge_rate: float
@export var bullet_detect_range: float
@export var item_seek_range: float
@export var item_priority: float
@export var scan_bullets: bool
@export var check_enemy_buffs: bool
@export var use_platform_navigation: bool
@export var platform_seek_range: float
```

### BotPerception
Tách riêng, chịu trách nhiệm quét môi trường:
- Địch ở đâu
- Đạn nào đang nguy hiểm (trong range, đang tiến về phía bot)
- Địch đang có buff gì (reflect, explosive bullet)
- Item nào gần nhất
- Platform nào có thể nhảy tới

### BotController
Nhận percept + config → ghi vào PlayerInput:
```gdscript
func think(delta: float) -> void:
    var percept := perception.perceive()
    # xử lý theo thứ tự ưu tiên → ghi vào player_input
```

---

## Bảng config theo độ khó

| Thuộc tính             | Easy      | Normal    | Hard      | Asian          |
|------------------------|-----------|-----------|-----------|----------------|
| reaction_delay         | 0.8s      | 0.4s      | 0.15s     | 0.0s           |
| shoot_rate             | 30%       | 60%       | 85%       | 100%           |
| dodge_rate             | 0%        | 30%       | 70%       | 100%           |
| bullet_detect_range    | 0         | 0         | ~150px    | toàn màn hình  |
| scan_bullets           | ❌        | ❌        | ✅        | ✅             |
| check_enemy_buffs      | ❌        | ❌        | ❌        | ✅             |
| use_platform_navigation| ❌        | ❌        | ✅        | ✅             |
| item_seek_range        | ~100px    | ~200px    | ~350px    | toàn màn hình  |

---

## Thứ tự ưu tiên hành động

```
1. Né đạn nguy hiểm              ← cao nhất
2. Không bắn nếu địch có reflect
3. Giữ khoảng cách hợp lý
4. Nhặt item
5. Áp sát và bắn địch            ← thấp nhất
```

---

## Chi tiết từng tính năng

### Né đạn
- Quét đạn trong `bullet_detect_range`
- Tính trajectory (đạn bay thẳng: phép chia đơn giản)
- Nếu đạn tiến về phía bot và đủ gần → nhảy hoặc đổi hướng
- Nếu địch có buff explosive bullet → canh thêm bán kính nổ

### Check buff địch
- `effect_manager.has_effect(Enums.Effect.REFLECT)` → không bắn
- `effect_manager.has_effect(Enums.Effect.EXPLOSIVE_BULLET)` → giữ khoảng cách

### Navigation platform
- Map expose danh sách platform (vị trí, độ cao, chiều rộng)
- Nếu địch ở platform cao hơn → tìm platform gần có thể nhảy tới → di chuyển bên dưới → nhảy
- Cần handle timeout/fallback tránh bot nhảy tại chỗ mãi

### Nhặt item
- Chỉ tìm item khi không có đạn nguy hiểm gần
- Asian: ưu tiên item theo giá trị (đang khỏe → bỏ qua máu, ưu tiên buff tấn công)

---

## Ghi chú

- **Asian là cheat mode hợp pháp** — mục tiêu là gây cay cú, không cần cân bằng
- Cần EffectManager expose API `has_effect()` để bot query được
- Cần bullet expose `velocity` để tính trajectory
- Xây dựng theo thứ tự Easy → Normal → Hard → Asian, không làm tất cả một lúc
