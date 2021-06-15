extends Control

var res : TimeTrackResource
var time_tracks_array : Array
var cancel : = false

var total_secs : int

func _ready() -> void:
	res = load(Defaults.TIMETRACKS_SAVE_PATH + Defaults.TIMETRACKS_SAVE_NAME)
	load_time_tracks()
	update_total_time()


func entering_view() -> void:
	print(res.tracks)
	
	
func leaving_view() -> void:
	save()
	
	
func load_time_tracks() -> void:
	for i in res.tracks:
		var item = res.tracks[i]
		
		item["id"] = i
		time_tracks_array.append(item)
		
	for i in time_tracks_array:
		total_secs += i["length"]
		create_track_visual(i["name"], i["date"], i["length"], i["id"])
	
	
func create_track_visual(_name : String, _date : Dictionary, _time : int, _id : int) -> void:
	var new : HBoxContainer = $VBoxContainer/ScrollContainer/VBoxContainer/TrackedItem.duplicate()
	new.id = _id
	
	var time = get_hours_minutes_seconds(_time)
	new.connect("delete_pressed", self, "_on_delete_pressed")
	
	new.get_child(0).text = Defaults.get_date_with_time_string(_date)
	new.get_child(1).text = time[2] + ":" + time[1] + ":" + time[0]
	new.get_child(2).text = _name
	
	new.show()
	$VBoxContainer/ScrollContainer/VBoxContainer.add_child(new)
	$VBoxContainer/ScrollContainer/VBoxContainer.move_child(new, 1)
	new.show_up()
	
	
func get_hours_minutes_seconds(_time : int) -> Array:
	# calculate
	var seconds : = str(_time % 60)
	var temp_hours : int = (_time / 60) / 60
	var minutes : int = (_time / 60) - (60 * temp_hours)
	var hours : = str(temp_hours)
	#stylize
	seconds = ("%02d" % int(seconds))
	var temp_minutes : String = ("%02d" % minutes)
	hours = "%02d" % int(hours)
	
	return [seconds, temp_minutes, hours]
	
	
func add_time_track(_length : int, _name : String, _date : Dictionary) -> void:
	total_secs += _length
	update_total_time()
	res.tracks[res.tracks.size() + 1] = {
		"date" : _date,
		"length" : _length,
		"name" : _name
	}
	create_track_visual(_name, _date, _length, res.tracks.size())
	
	
func save() -> void:
	print("saving time tracking resource")
	Defaults.save_timetrack_resource(res)


func change_title(_final : String = "00:00:00") -> void:
	$Tween.interpolate_property($VBoxContainer/Title, 'percent_visible', 1.0, 0.0, 0.5, Tween.TRANS_QUAD, Tween.EASE_OUT, 0.0)
	$Tween.interpolate_property($VBoxContainer/Title, 'percent_visible', 0.0, 1.0, 0.5, Tween.TRANS_QUAD, Tween.EASE_OUT, 0.5)
	$Tween.start()
	yield(get_tree().create_timer(0.5), "timeout")
	$VBoxContainer/Title.text = _final


func update_total_time() -> void:
	var _time : Array = get_hours_minutes_seconds(total_secs)
	$VBoxContainer/Title/Total.text = "total " + _time[2] + ":" + _time[1] + ":" + _time[0]


func remove_time_track(idx : int) -> void:
	total_secs -= res.tracks[idx].length
	res.tracks.erase(idx)
	update_total_time()


func _on_TrackButton_toggled(button_pressed: bool) -> void:
	if cancel:
		cancel = false
		return
	if button_pressed:
		$Timer.start()
		$Timer2.start()
		change_title()
		$VBoxContainer/Panel/HBoxContainer/CancelButton.show()
		$VBoxContainer/Panel/HBoxContainer/PauseButton.show()
		$VBoxContainer/Panel/Label.editable = false
	else:
		add_time_track(86400 - $Timer.time_left, $VBoxContainer/Panel/Label.text, OS.get_datetime())
		change_title("TIME TRACKING")
		$VBoxContainer/Panel/Label.editable = true
		$Timer.stop()
		$Timer2.stop()
		$VBoxContainer/Panel/HBoxContainer/CancelButton.hide()
		$VBoxContainer/Panel/HBoxContainer/PauseButton.hide()
		save()


func _on_Timer2_timeout() -> void:
	var _time : Array = get_hours_minutes_seconds(86400 - $Timer.time_left)
	$VBoxContainer/Title.text = _time[2] + ":" + _time[1] + ":" + _time[0]


func _on_CancelButton_pressed() -> void:
	cancel = true
	change_title("TIME TRACKING")
	$VBoxContainer/Panel/HBoxContainer/TrackButton.pressed = false
	$VBoxContainer/Panel/Label.editable = true
	$Timer.stop()
	$Timer2.stop()
	$VBoxContainer/Panel/HBoxContainer/CancelButton.hide()
	$VBoxContainer/Panel/HBoxContainer/PauseButton.hide()


func _on_PauseButton_toggled(button_pressed: bool) -> void:
	if button_pressed:
		$Timer.paused = true
		$Timer2.paused = true
	else:
		$Timer.paused = false
		$Timer2.paused = false
		
		
func _on_delete_pressed(idx : int) -> void:
	remove_time_track(idx)