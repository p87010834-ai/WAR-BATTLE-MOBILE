extends CanvasLayer
class_name WbmUIManager

var game_manager: Node
var overlay: ColorRect
var panel: PanelContainer
var page_title: Label
var page_body: RichTextLabel
var content_box: VBoxContainer
var current_page := "Главное меню"

const PAGES := [
	"Главное меню", "Ангар", "Профиль", "Миссии", "Достижения",
	"Друзья", "Отряды", "Кланы", "Магазин", "Боевой пропуск",
	"Рейтинг", "События", "Обучение", "Повторы", "Настройки"
]

func _ready() -> void:
	game_manager = get_tree().get_first_node_in_group("game_manager")
	_build_interface()

func _build_interface() -> void:
	var open_button := Button.new()
	open_button.text = "МЕНЮ"
	open_button.focus_mode = Control.FOCUS_NONE
	open_button.anchor_left = 0.0
	open_button.anchor_top = 0.0
	open_button.offset_left = 18
	open_button.offset_top = 142
	open_button.offset_right = 132
	open_button.offset_bottom = 190
	open_button.add_theme_font_size_override("font_size", 17)
	_style_button(open_button, Color(0.43, 0.20, 0.08, 0.96))
	add_child(open_button)
	open_button.pressed.connect(_show_menu)

	overlay = ColorRect.new()
	overlay.color = Color(0.008, 0.014, 0.02, 0.88)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.visible = false
	add_child(overlay)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(720, 560)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.045, 0.065, 0.075, 0.98)
	panel_style.border_color = Color(0.88, 0.39, 0.12, 1)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(12)
	panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(panel)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 10)
	panel.add_child(layout)

	var header := HBoxContainer.new()
	layout.add_child(header)
	page_title = Label.new()
	page_title.text = "WAR BATTLE MOBILE"
	page_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page_title.add_theme_font_size_override("font_size", 25)
	page_title.add_theme_color_override("font_color", Color(1.0, 0.58, 0.22))
	header.add_child(page_title)
	var close := Button.new()
	close.text = "ЗАКРЫТЬ"
	_style_button(close, Color(0.35, 0.12, 0.08, 1))
	header.add_child(close)
	close.pressed.connect(_hide_menu)

	var body_row := HBoxContainer.new()
	body_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(body_row)

	var nav_scroll := ScrollContainer.new()
	nav_scroll.custom_minimum_size.x = 190
	nav_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_row.add_child(nav_scroll)
	var nav := VBoxContainer.new()
	nav.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nav_scroll.add_child(nav)
	for page in PAGES:
		var nav_button := Button.new()
		nav_button.text = page
		nav_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nav_button.focus_mode = Control.FOCUS_NONE
		_style_button(nav_button, Color(0.12, 0.17, 0.19, 1))
		nav.add_child(nav_button)
		nav_button.pressed.connect(_open_page.bind(page))

	var separator := VSeparator.new()
	body_row.add_child(separator)
	var page_scroll := ScrollContainer.new()
	page_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_row.add_child(page_scroll)
	content_box = VBoxContainer.new()
	content_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page_scroll.add_child(content_box)
	_open_page("Главное меню")

func _style_button(button: Button, color: Color) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color(0.88, 0.42, 0.16, 0.95)
	style.set_border_width_all(1)
	style.set_corner_radius_all(7)
	button.add_theme_stylebox_override("normal", style)
	var hover := style.duplicate()
	hover.bg_color = color.lightened(0.16)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_color_override("font_color", Color(0.96, 0.94, 0.9))

func _show_menu() -> void:
	overlay.visible = true
	_open_page("Главное меню")

func _hide_menu() -> void:
	overlay.visible = false

func _open_page(page: String) -> void:
	current_page = page
	page_title.text = "WAR BATTLE MOBILE  /  " + page.to_upper()
	for child in content_box.get_children():
		child.queue_free()
	match page:
		"Главное меню":
			_add_heading("КОМАНДОВАНИЕ")
			_add_text("Добро пожаловать на поле боя. Выберите раздел или вернитесь в бой.")
			_add_action("ПРОДОЛЖИТЬ БОЙ", _hide_menu)
			_add_action("ПЕРЕЗАПУСТИТЬ БОЙ", _restart_match)
			_add_text("Текущая сборка — ранний игровой прототип. Сетевые функции и часть метасистем ещё требуют серверной реализации.")
		"Ангар":
			_add_heading("ВЫБОР ТЕХНИКИ")
			_add_vehicle_card("ТАНКИ", "Наземная техника. Доступно управление танком в тестовом бою.")
			_add_vehicle_card("АВИАЦИЯ", "Самолёты поддержки. Прототип полёта и воздушного боя.")
			_add_vehicle_card("ФЛОТ", "Корабли поддержки. Прототип управления и морского боя.")
			_add_text("Полноценная коллекция машин, экипировка и покупка техники будут подключены отдельно.")
		"Профиль":
			_add_heading("ЛИЧНОЕ ДЕЛО")
			_add_text("Профиль игрока, уровень аккаунта, статистика боёв и награды.")
			_add_text("Локальная система профиля уже существует; синхронизация аккаунта и серверная статистика ещё не подключены.")
		"Миссии":
			_add_heading("БОЕВЫЕ ЗАДАНИЯ")
			_add_text("Ежедневные и еженедельные задания: участие в боях, уничтожение техники и захват точек.")
			_add_text("В текущем прототипе подключены базовые локальные счётчики миссий.")
		"Достижения":
			_add_heading("НАГРАДЫ И ДОСТИЖЕНИЯ")
			_add_text("Список достижений и прогресс открытий. Локальная система достижений подключена к тестовому бою.")
		"Настройки":
			_build_settings_page()
		"Обучение":
			_add_heading("УЧЕБНЫЙ ПОЛИГОН")
			_add_text("Освойте движение, поворот, стрельбу, ремонт, захват точек и переключение между классами техники.")
			_add_text("Подробные пошаговые учебные сценарии ещё предстоит реализовать.")
		"Повторы":
			_add_heading("АРХИВ СРАЖЕНИЙ")
			_add_text("Запись локальных телеметрических данных боя предусмотрена. Просмотр и перемотка повторов ещё не реализованы.")
		"Друзья", "Отряды", "Кланы", "Магазин", "Боевой пропуск", "Рейтинг", "События":
			_add_heading(page.to_upper())
			_add_text("Экран раздела добавлен в интерфейс проекта.")
			_add_text("Для полноценной работы нужны серверные данные, авторизация и соответствующая игровая логика. Сейчас этот раздел является интерфейсной заготовкой, а не работающей онлайн-функцией.")
			if page == "Кланы":
				_add_text("Планируемые функции: создание клана, состав, роли, чат и глобальная война за территории.")
			elif page == "Магазин":
				_add_text("Планируемые категории: техника, косметика, наборы и внутриигровые предложения.")
			elif page == "Боевой пропуск":
				_add_text("Планируемые функции: сезонный прогресс, бесплатная и премиальная ветки наград.")
			elif page == "Рейтинг":
				_add_text("Планируемые функции: рейтинговые матчи, дивизионы и таблицы лидеров.")
			elif page == "События":
				_add_text("Планируемые функции: временные режимы, сезонные задачи и специальные награды.")

func _add_heading(value: String) -> void:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", Color(1.0, 0.58, 0.22))
	content_box.add_child(label)

func _add_text(value: String) -> void:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = 390
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(0.86, 0.89, 0.89))
	content_box.add_child(label)

func _add_action(caption: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size.y = 48
	_style_button(button, Color(0.46, 0.20, 0.08, 1))
	content_box.add_child(button)
	button.pressed.connect(callback)

func _add_vehicle_card(title: String, description: String) -> void:
	_add_heading(title)
	_add_text(description)

func _build_settings_page() -> void:
	_add_heading("ПАРАМЕТРЫ ИГРЫ")
	if not is_instance_valid(game_manager):
		_add_text("Настройки временно недоступны.")
		return
	var settings = game_manager.get("settings")
	if settings == null:
		_add_text("Настройки не найдены.")
		return
	_add_text("Громкость")
	var volume := HSlider.new()
	volume.min_value = 0.0
	volume.max_value = 1.0
	volume.step = 0.05
	volume.value = settings.master_volume
	content_box.add_child(volume)
	volume.value_changed.connect(func(value: float):
		settings.master_volume = value
		settings.apply_audio()
		settings.save_settings()
	)
	_add_text("Качество графики")
	var quality := OptionButton.new()
	quality.add_item("Низкое", 0)
	quality.add_item("Среднее", 1)
	quality.add_item("Высокое", 2)
	quality.select(clampi(settings.graphics_quality, 0, 2))
	content_box.add_child(quality)
	quality.item_selected.connect(func(index: int):
		settings.graphics_quality = index
		settings.save_settings()
	)
	_add_text("Язык интерфейса")
	var language := OptionButton.new()
	language.add_item("Русский", 0)
	language.add_item("English", 1)
	language.select(0 if settings.language == "ru" else 1)
	content_box.add_child(language)
	language.item_selected.connect(func(index: int):
		settings.language = "ru" if index == 0 else "en"
		settings.save_settings()
	)
	_add_text("Дополнительные параметры управления и графики будут расширены.")

func _restart_match() -> void:
	get_tree().reload_current_scene()
