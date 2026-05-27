class_name Utils extends Node

static func get_lan_ip() -> String:
	# Lấy danh sách tất cả các địa chỉ IP của máy
	var addresses = IP.get_local_addresses()
	
	for ip in addresses:
		# 1. Kiểm tra xem có phải IPv4 không (có dấu chấm)
		# 2. Kiểm tra xem có phải địa chỉ nội bộ (localhost) không
		if "." in ip and not ip.begins_with("127.") and not ip.begins_with("169.254."):
			return ip
			
	return "127.0.0.1" # Trả về localhost nếu không thấy mạng LAN
