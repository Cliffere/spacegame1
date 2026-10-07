extends Control

const SIZE := Vector2(1280.0, 720.0)
const FIELD := Rect2(80.0, 150.0, 1120.0, 470.0)
const LANES := [275.0, 385.0, 495.0]
const PLAYER_X := 210.0

var mode := "title"
var best_score := 0
var score := 0.0
var target_lane := 1
var player_y := LANES[1]
var speed := 380.0
var spawn_timer := 0.0
var elapsed := 0.0
var obstacles: Array = []
var pickups: Array = []
var rng := RandomNumberGenerator.new()

var title_panel: Panel
var title_status: Label
var score_label: Label
var best_label: Label
var run_label: Label
var hint_label: Label
var touch_left: Button
var touch_right: Button
var pause_panel: Panel
var result_panel: Panel
var result_score: Label
var result_best: Label
var comic_regular: Font
var comic_bold: Font

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    rng.randomize()
    comic_regular = load("res://assets/fonts/comic_neue_regular.ttf") as Font
    comic_bold = load("res://assets/fonts/comic_neue_bold.ttf") as Font
    _load_best()
    _build_ui()
    queue_redraw()

func _process(delta: float) -> void:
    elapsed += delta
    if mode == "play":
        _tick_game(delta)
    queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_LEFT or event.keycode == KEY_A:
            _shift_lane(-1)
        elif event.keycode == KEY_RIGHT or event.keycode == KEY_D:
            _shift_lane(1)
        elif event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
            if mode == "title" or mode == "game_over":
                _start_run()
            elif mode == "paused":
                _toggle_pause()
        elif event.keycode == KEY_ESCAPE and (mode == "play" or mode == "paused"):
            _toggle_pause()

func _build_ui() -> void:
    title_panel = Panel.new()
    title_panel.position = Vector2(420.0, 190.0)
    title_panel.size = Vector2(440.0, 300.0)
    title_panel.add_theme_stylebox_override("panel", _box(Color.WHITE, Color.BLACK, 1))
    add_child(title_panel)

    var title := _label("SPACE SHIP GAME", 26, Color.BLACK)
    title.position = Vector2(32.0, 32.0)
    title.size = Vector2(370.0, 42.0)
    title_panel.add_child(title)

    var copy := _label("A-D to move up or down.\nAvoid the blocks", 16, Color("333333"))
    copy.position = Vector2(34.0, 92.0)
    copy.size = Vector2(370.0, 60.0)
    title_panel.add_child(copy)

    var play := _button("START", Vector2(34.0, 182.0), Vector2(170.0, 46.0))
    play.pressed.connect(_start_run)
    title_panel.add_child(play)

    title_status = _label("", 14, Color("333333"))
    title_status.position = Vector2(34.0, 246.0)
    title_status.size = Vector2(300.0, 24.0)
    title_panel.add_child(title_status)

    score_label = _label("0000", 22, Color.BLACK)
    score_label.position = Vector2(84.0, 48.0)
    score_label.size = Vector2(130.0, 32.0)
    score_label.visible = false
    add_child(score_label)

    var score_caption := _label("SCORE", 11, Color("555555"))
    score_caption.position = Vector2(86.0, 78.0)
    score_caption.size = Vector2(100.0, 18.0)
    score_caption.visible = false
    add_child(score_caption)

    best_label = _label("", 14, Color("333333"))
    best_label.position = Vector2(1040.0, 55.0)
    best_label.size = Vector2(140.0, 24.0)
    best_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    best_label.visible = false
    add_child(best_label)

    run_label = _label("", 12, Color("555555"))
    run_label.position = Vector2(84.0, 112.0)
    run_label.size = Vector2(140.0, 20.0)
    run_label.visible = false
    add_child(run_label)

    hint_label = _label("A-D TO MOVE UP OR DOWN", 12, Color("555555"))
    hint_label.position = Vector2(84.0, 645.0)
    hint_label.size = Vector2(260.0, 20.0)
    hint_label.visible = false
    add_child(hint_label)

    touch_left = _button("UP", Vector2(100.0, 560.0), Vector2(100.0, 42.0))
    touch_left.pressed.connect(func() -> void: _shift_lane(-1))
    touch_left.visible = false
    add_child(touch_left)

    touch_right = _button("DOWN", Vector2(1080.0, 560.0), Vector2(100.0, 42.0))
    touch_right.pressed.connect(func() -> void: _shift_lane(1))
    touch_right.visible = false
    add_child(touch_right)

    pause_panel = Panel.new()
    pause_panel.position = Vector2(470.0, 250.0)
    pause_panel.size = Vector2(340.0, 190.0)
    pause_panel.add_theme_stylebox_override("panel", _box(Color.WHITE, Color.BLACK, 1))
    pause_panel.visible = false
    add_child(pause_panel)
    var pause_text := _label("PAUSED", 24, Color.BLACK)
    pause_text.position = Vector2(28.0, 26.0)
    pause_text.size = Vector2(280.0, 34.0)
    pause_panel.add_child(pause_text)
    var resume := _button("RESUME", Vector2(28.0, 92.0), Vector2(130.0, 42.0))
    resume.pressed.connect(_toggle_pause)
    pause_panel.add_child(resume)
    var quit := _button("TITLE", Vector2(182.0, 92.0), Vector2(130.0, 42.0))
    quit.pressed.connect(_show_title)
    pause_panel.add_child(quit)

    result_panel = Panel.new()
    result_panel.position = Vector2(430.0, 210.0)
    result_panel.size = Vector2(420.0, 280.0)
    result_panel.add_theme_stylebox_override("panel", _box(Color.WHITE, Color.BLACK, 1))
    result_panel.visible = false
    add_child(result_panel)
    var result_title := _label("TRY AGAIN", 26, Color.BLACK)
    result_title.position = Vector2(30.0, 28.0)
    result_title.size = Vector2(350.0, 38.0)
    result_panel.add_child(result_title)
    result_score = _label("", 42, Color.BLACK)
    result_score.position = Vector2(30.0, 88.0)
    result_score.size = Vector2(180.0, 54.0)
    result_panel.add_child(result_score)
    result_best = _label("", 14, Color("333333"))
    result_best.position = Vector2(30.0, 150.0)
    result_best.size = Vector2(240.0, 24.0)
    result_panel.add_child(result_best)
    var again := _button("RESTART", Vector2(30.0, 204.0), Vector2(160.0, 42.0))
    again.pressed.connect(_start_run)
    result_panel.add_child(again)
    var title_button := _button("TITLE", Vector2(210.0, 204.0), Vector2(160.0, 42.0))
    title_button.pressed.connect(_show_title)
    result_panel.add_child(title_button)

func _label(text: String, font_size: int, color: Color) -> Label:
    var label := Label.new()
    label.text = text
    label.add_theme_font_override("font", comic_regular)
    label.add_theme_font_size_override("font_size", font_size)
    label.add_theme_color_override("font_color", color)
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    return label

func _button(text: String, pos: Vector2, button_size: Vector2) -> Button:
    var button := Button.new()
    button.text = text
    button.position = pos
    button.size = button_size
    button.add_theme_font_size_override("font_size", 14)
    button.add_theme_font_override("font", comic_bold)
    button.add_theme_color_override("font_color", Color.BLACK)
    button.add_theme_stylebox_override("normal", _box(Color.WHITE, Color.BLACK, 1))
    button.add_theme_stylebox_override("hover", _box(Color("eeeeee"), Color.BLACK, 1))
    button.add_theme_stylebox_override("pressed", _box(Color("dddddd"), Color.BLACK, 1))
    return button

func _box(fill: Color, border: Color, width: int) -> StyleBoxFlat:
    var box := StyleBoxFlat.new()
    box.bg_color = fill
    box.border_color = border
    box.set_border_width_all(width)
    box.content_margin_left = 12.0
    box.content_margin_right = 12.0
    box.content_margin_top = 8.0
    box.content_margin_bottom = 8.0
    return box

func _start_run() -> void:
    mode = "play"
    score = 0.0
    target_lane = 1
    player_y = LANES[1]
    speed = 380.0
    spawn_timer = 0.25
    obstacles.clear()
    pickups.clear()
    title_panel.visible = false
    pause_panel.visible = false
    result_panel.visible = false
    score_label.visible = false
    best_label.visible = false
    run_label.visible = true
    hint_label.visible = true
    touch_left.visible = true
    touch_right.visible = true

func _show_title() -> void:
    mode = "title"
    title_panel.visible = true
    pause_panel.visible = false
    result_panel.visible = false
    score_label.visible = false
    best_label.visible = false
    run_label.visible = false
    hint_label.visible = false
    touch_left.visible = false
    touch_right.visible = false
    title_status.text = ""

func _toggle_pause() -> void:
    if mode == "play":
        mode = "paused"
        pause_panel.visible = true
        touch_left.visible = false
        touch_right.visible = false
    elif mode == "paused":
        mode = "play"
        pause_panel.visible = false
        touch_left.visible = true
        touch_right.visible = true

func _shift_lane(direction: int) -> void:
    if mode == "play":
        target_lane = clampi(target_lane + direction, 0, 2)

func _tick_game(delta: float) -> void:
    score += delta * 10.0
    speed = minf(620.0, speed + delta * 3.0)
    player_y = lerpf(player_y, float(LANES[target_lane]), minf(1.0, delta * 12.0))
    spawn_timer -= delta
    if spawn_timer <= 0.0:
        obstacles.append({"x": 1240.0, "lane": rng.randi_range(0, 2)})
        if rng.randf() < 0.5:
            pickups.append({"x": 1380.0, "lane": rng.randi_range(0, 2)})
        spawn_timer = maxf(0.62, 1.08 - score * 0.0005)
    for i in range(obstacles.size() - 1, -1, -1):
        var obstacle: Dictionary = obstacles[i]
        obstacle.x -= speed * delta
        obstacles[i] = obstacle
        if obstacle.x < 100.0:
            obstacles.remove_at(i)
        elif absf(obstacle.x - PLAYER_X) < 42.0 and obstacle.lane == target_lane:
            _end_run()
            return
    for i in range(pickups.size() - 1, -1, -1):
        var pickup: Dictionary = pickups[i]
        pickup.x -= speed * delta
        pickups[i] = pickup
        if pickup.x < 100.0:
            pickups.remove_at(i)
        elif absf(pickup.x - PLAYER_X) < 42.0 and pickup.lane == target_lane:
            score += 25.0
            pickups.remove_at(i)
    score_label.text = "%04d" % int(score)
    best_label.text = "BEST %04d" % best_score

func _end_run() -> void:
    mode = "game_over"
    var final_score := int(score)
    if final_score > best_score:
        best_score = final_score
        _save_best()
    result_score.text = ""
    result_best.text = ""
    result_panel.visible = true
    touch_left.visible = false
    touch_right.visible = false
    hint_label.visible = false

func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, SIZE), Color.WHITE)
    if mode == "title":
        draw_line(Vector2(80.0, 125.0), Vector2(1200.0, 125.0), Color("bbbbbb"), 1.0)
        return
    draw_line(Vector2(80.0, 125.0), Vector2(1200.0, 125.0), Color("bbbbbb"), 1.0)
    draw_rect(FIELD, Color("fafafa"), true)
    draw_rect(FIELD, Color.BLACK, false, 1.0)
    for lane in LANES:
        draw_line(Vector2(FIELD.position.x, lane), Vector2(FIELD.end.x, lane), Color("dddddd"), 1.0)
    for pickup in pickups:
        var p := Vector2(pickup.x, LANES[pickup.lane])
        draw_circle(p, 13.0, Color("bbbbbb"))
        draw_circle(p, 6.0, Color.BLACK)
    for obstacle in obstacles:
        var o := Vector2(obstacle.x, LANES[obstacle.lane])
        draw_rect(Rect2(o - Vector2(22.0, 22.0), Vector2(44.0, 44.0)), Color.BLACK)
    var player := Vector2(PLAYER_X, player_y)
    draw_rect(Rect2(player - Vector2(20.0, 20.0), Vector2(40.0, 40.0)), Color.BLACK)
    draw_rect(Rect2(player - Vector2(12.0, 12.0), Vector2(24.0, 24.0)), Color.WHITE)

func _load_best() -> void:
    var store := ConfigFile.new()
    if store.load("user://neon_nibble.cfg") == OK:
        best_score = int(store.get_value("score", "best", 0))

func _save_best() -> void:
    var store := ConfigFile.new()
    store.set_value("score", "best", best_score)
    store.save("user://neon_nibble.cfg")
