extends Label

func setup(start_pos: Vector2, value: String):
	# Thiết lập nội dung và vị trí ban đầu
	text = value
	global_position = start_pos
	
	# Tạo một Tween mới
	var tween = get_tree().create_tween()
	
	# Cho phép các hiệu ứng chạy song song (bay lên và mờ dần cùng lúc)
	tween.set_parallel(true)
	
	# 1. Hiệu ứng bay lên: Giảm trục Y đi 100 pixel trong 1 giây
	# set_trans và set_ease giúp chuyển động mượt hơn (chậm dần về cuối)
	tween.tween_property(self, "global_position:y", global_position.y - 100, 1.0)\
		.set_trans(Tween.TRANS_QUART)\
		.set_ease(Tween.EASE_OUT)
		
	# 2. Hiệu ứng mờ dần: Chỉnh Alpha (độ trong suốt) về 0
	tween.tween_property(self, "modulate:a", 0.0, 1.0)
	
	# 3. Sau khi chạy xong các hiệu ứng trên, tự giải phóng (xóa) node này
	tween.chain().tween_callback(queue_free)
