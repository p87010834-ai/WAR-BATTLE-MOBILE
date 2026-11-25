extends CanvasLayer
class_name WbmUIManager

var game_manager: Node
var overlay: ColorRect
var panel: PanelContainer
var page_title: Label
var content_box: VBoxContainer
var current_page := "Главное меню"
var compact_layout := false
var local_data := ConfigFile.new()
var local_data_path := "user://interface_data.cfg"

const ACCENT := Color(1.0, 0.58, 0.22)
const PAGES := [
	"Главное меню", "Ангар", "Профиль", "Миссии", "Достижения",
	"Друзья", "Отряды", "Кланы", "Магазин", "Боевой пропуск",
	"Рейтинг", "События", "Обучение", "Повторы", "Настройки",
	"Управление", "Графика", "Звук", "Интерфейс", "Аккаунт", "Безопасность"
]

func _ready() -> void:
	game_manager = get_tree().get_first_node_in_group("game_manager")
	add_to_group("game_ui_manager")
	compact_layout = get_viewport().get_visible_rect().size.x < 760.0
	local_data.load(local_data_path)
	_build_interface()

func _build_interface() -> void:
	var open_button := Button.new()
	open_button.text = "МЕНЮ"
	open_button.focus_mode = Control.FOCUS_NONE
	open_button.position = Vector2(18, 142)
	open_button.size = Vector2(114, 46)
	open_button.add_theme_font_size_override("font_size", 16)
	_style_button(open_button, Color(0.43, 0.20, 0.08, 0.96))
	add_child(open_button)
	open_button.pressed.connect(_show_menu)

	overlay = ColorRect.new()
	overlay.color = Color(0.008, 0.014, 0.02, 0.91)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.visible = false
	add_child(overlay)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	overlay.add_child(margin)

	panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size = Vector2(300, 380)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.045, 0.065, 0.075, 0.99)
	panel_style.border_color = Color(0.88, 0.39, 0.12, 1)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(10)
	panel_style.content_margin_left = 12
	panel_style.content_margin_right = 12
	panel_style.content_margin_top = 12
	panel_style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", panel_style)
	margin.add_child(panel)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 8)
	panel.add_child(layout)

	var header := HBoxContainer.new()
	layout.add_child(header)
	page_title = Label.new()
	page_title.text = "WAR BATTLE MOBILE"
	page_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page_title.add_theme_font_size_override("font_size", 19 if compact_layout else 25)
	page_title.add_theme_color_override("font_color", ACCENT)
	header.add_child(page_title)
	var close := Button.new()
	close.text = "✕"
	close.custom_minimum_size = Vector2(42, 38)
	_style_button(close, Color(0.35, 0.12, 0.08, 1))
	header.add_child(close)
	close.pressed.connect(_hide_menu)

	var body_column := VBoxContainer.new()
	body_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_column.add_theme_constant_override("separation", 8)
	layout.add_child(body_column)

	var nav_scroll := ScrollContainer.new()
	nav_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nav_scroll.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	if compact_layout:
		nav_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
		nav_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		nav_scroll.custom_minimum_size.y = 46
		body_column.add_child(nav_scroll)
		var nav_row := HBoxContainer.new()
		nav_row.add_theme_constant_override("separation", 5)
		nav_scroll.add_child(nav_row)
		for page in PAGES:
			var nav_button := Button.new()
			nav_button.text = page
			nav_button.custom_minimum_size = Vector2(92, 40)
			nav_button.focus_mode = Control.FOCUS_NONE
			nav_button.add_theme_font_size_override("font_size", 11)
			_style_button(nav_button, Color(0.12, 0.17, 0.19, 1))
			nav_row.add_child(nav_button)
			nav_button.pressed.connect(_open_page.bind(page))
	else:
		var body_row := HBoxContainer.new()
		body_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
		body_row.add_theme_constant_override("separation", 8)
		body_column.add_child(body_row)
		nav_scroll.custom_minimum_size.x = 178
		nav_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		body_row.add_child(nav_scroll)
		var nav := VBoxContainer.new()
		nav.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nav.add_theme_constant_override("separation", 5)
		nav_scroll.add_child(nav)
		for page in PAGES:
			var nav_button := Button.new()
			nav_button.text = page
			nav_button.custom_minimum_size.y = 40
			nav_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			nav_button.focus_mode = Control.FOCUS_NONE
			nav_button.add_theme_font_size_override("font_size", 14)
			_style_button(nav_button, Color(0.12, 0.17, 0.19, 1))
			nav.add_child(nav_button)
			nav_button.pressed.connect(_open_page.bind(page))
		body_row.add_child(VSeparator.new())

	var page_scroll := ScrollContainer.new()
	page_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_column.add_child(page_scroll)
	content_box = VBoxContainer.new()
	content_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_box.add_theme_constant_override("separation", 10)
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
	page_title.text = "WBM / " + page.to_upper()
	for child in content_box.get_children():
		child.queue_free()
	match page:
		"Главное меню":
			_add_heading("КОМАНДОВАНИЕ")
			_add_text("WAR BATTLE MOBILE — ранний прототип объединённых боёв. Выберите раздел или вернитесь в сражение.")
			_add_action("ПРОДОЛЖИТЬ БОЙ", _hide_menu)
			_add_action("ПЕРЕЗАПУСТИТЬ БОЙ", _restart_match)
			_add_text("Текущий режим: локальная тестовая арена с ботами. Полноценный сетевой сервис ещё не подключён.")
		"Ангар":
			_build_hangar_page()
		"Профиль":
			_build_profile_page()
		"Миссии":
			_build_missions_page()
		"Достижения":
			_build_achievements_page()
		"Настройки":
			_build_settings_page()
		"Управление":
			_build_control_settings()
		"Графика":
			_build_graphics_settings()
		"Звук":
			_build_audio_settings()
		"Интерфейс":
			_build_interface_settings()
		"Аккаунт":
			_build_account_page()
		"Безопасность":
			_build_security_page()
		"Обучение":
			_add_heading("УЧЕБНЫЙ ПОЛИГОН")
			_add_text("ТАНК: виртуальный джойстик — движение и поворот; кнопка ОГОНЬ — выстрел; РЕМОНТ — восстановление модулей.")
			_add_text("САМОЛЁТ: джойстик — тангаж и рыскание; отдельные кнопки — крен и тяга; ОГОНЬ — пушка.")
			_add_text("КОРАБЛЬ: джойстик — курс и скорость; ОГОНЬ — корабельные орудия.")
			_add_text("Захватывайте три контрольные точки. Удержание точек приносит команде очки.")
			_add_action("НАЧАТЬ ЗАНОВО", _restart_match)
		"Повторы":
			_build_replays_page()
		"Друзья":
			_build_friends_page()
		"Отряды":
			_build_squad_page()
		"Кланы":
			_build_clan_page()
		"Магазин":
			_build_shop_page()
		"Рейтинг":
			_build_rating_page()
		"События":
			_build_events_page()
		"Боевой пропуск":
			_build_season_page()

func _add_heading(value: String) -> void:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 18 if compact_layout else 22)
	label.add_theme_color_override("font_color", ACCENT)
	content_box.add_child(label)

func _add_text(value: String) -> void:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", 13 if compact_layout else 16)
	label.add_theme_color_override("font_color", Color(0.86, 0.89, 0.89))
	content_box.add_child(label)

func _add_action(caption: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size.y = 42
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_button(button, Color(0.46, 0.20, 0.08, 1))
	content_box.add_child(button)
	button.pressed.connect(callback)


func _build_control_settings() -> void:
	_add_heading("УПРАВЛЕНИЕ ТЕХНИКОЙ")
	if not is_instance_valid(game_manager):
		_add_text("Настройки управления недоступны.")
		return
	var settings = game_manager.settings
	_add_text("Чувствительность виртуального джойстика")
	var sensitivity := HSlider.new()
	sensitivity.min_value = 0.25
	sensitivity.max_value = 2.5
	sensitivity.step = 0.05
	sensitivity.value = settings.sensitivity
	content_box.add_child(sensitivity)
	sensitivity.value_changed.connect(func(value: float):
		settings.sensitivity = value
		settings.save_settings()
	)
	var vibration := CheckButton.new()
	vibration.text = "Вибрация при попадании (если поддерживается устройством)"
	vibration.button_pressed = settings.vibration_enabled
	content_box.add_child(vibration)
	vibration.toggled.connect(func(value: bool):
		settings.vibration_enabled = value
		settings.save_settings()
	)
	var aim := CheckButton.new()
	aim.text = "Помощь в прицеливании"
	aim.button_pressed = settings.aim_assist_enabled
	content_box.add_child(aim)
	aim.toggled.connect(func(value: bool):
		settings.aim_assist_enabled = value
		settings.save_settings()
	)
	_add_text("Раскладка кнопок и переназначение клавиш пока не реализованы.")

func _build_graphics_settings() -> void:
	_add_heading("ГРАФИКА И ПРОИЗВОДИТЕЛЬНОСТЬ")
	if not is_instance_valid(game_manager):
		_add_text("Графические настройки недоступны.")
		return
	var settings = game_manager.settings
	var quality := OptionButton.new()
	quality.add_item("Производительность", 0)
	quality.add_item("Сбалансированно", 1)
	quality.add_item("Качество", 2)
	quality.select(clampi(settings.graphics_quality, 0, 2))
	content_box.add_child(quality)
	quality.item_selected.connect(func(index: int):
		settings.graphics_quality = index
		settings.save_settings()
	)
	_add_text("Выбранный профиль сохраняется. Полное применение профилей к теням, LOD, эффектам и разрешению ещё требует графического менеджера.")

func _build_audio_settings() -> void:
	_add_heading("ЗВУК")
	if not is_instance_valid(game_manager):
		_add_text("Настройки звука недоступны.")
		return
	var settings = game_manager.settings
	for entry in [["Общая громкость", "master_volume"], ["Музыка", "music_volume"], ["Эффекты", "effects_volume"]]:
		_add_text(str(entry[0]))
		var slider := HSlider.new()
		slider.min_value = 0.0
		slider.max_value = 1.0
		slider.step = 0.05
		slider.value = float(settings.get(entry[1]))
		content_box.add_child(slider)
		var property_name := str(entry[1])
		slider.value_changed.connect(func(value: float):
			settings.set(property_name, value)
			settings.apply_audio()
			settings.save_settings()
		)

func _build_interface_settings() -> void:
	_add_heading("ИНТЕРФЕЙС БОЯ")
	if not is_instance_valid(game_manager):
		_add_text("Настройки интерфейса недоступны.")
		return
	var settings = game_manager.settings
	var language := OptionButton.new()
	language.add_item("Русский", 0)
	language.add_item("English", 1)
	language.select(0 if settings.language == "ru" else 1)
	content_box.add_child(language)
	language.item_selected.connect(func(index: int):
		settings.language = "ru" if index == 0 else "en"
		settings.save_settings()
		_add_text("Язык сохранён. Перевод всех игровых сообщений будет подключаться по мере локализации.")
	)
	_add_text("Основной стиль: тёмная тактическая панель с оранжевыми акцентами.")
	_add_text("HUD: индикаторы техники, прочности и телеметрия. Персональная настройка расположения HUD пока не реализована.")

func _build_account_page() -> void:
	_add_heading("АККАУНТ И ПРОФИЛЬ")
	if not is_instance_valid(game_manager):
		_add_text("Локальный профиль недоступен.")
		return
	var profile = game_manager.profile
	_add_text("Позывной: %s" % profile.username)
	_add_text("Уровень: %d / 100" % profile.account_level)
	_add_text("Опыт: %d XP" % profile.experience)
	_add_text("Это локальный профиль данного устройства. Регистрация, облачная синхронизация и перенос прогресса пока не подключены.")
	_add_action("ОТКРЫТЬ ЛИЧНОЕ ДЕЛО", _open_page.bind("Профиль"))

func _build_security_page() -> void:
	_add_heading("БЕЗОПАСНОСТЬ И ПРАВИЛА")
	_add_text("В прототипе нет регистрации, платежей или сетевого чата. Не вводите пароли и платёжные данные.")
	_add_text("Планируемые меры: серверная проверка матчей, фильтрация оскорблений, жалобы на игроков, защита сессии и инструменты модерации.")
	_add_text("Важно: эти серверные меры ещё не подключены; локальный фильтр текста не является полноценной защитой.")
	_add_text("Голосовой чат не предусмотрен. Текстовый онлайн-чат появится только после реализации серверной инфраструктуры.")

func _build_hangar_page() -> void:
	_add_heading("АНГАР / ВЫБОР ТЕХНИКИ")
	if not is_instance_valid(game_manager):
		_add_text("Игровая сессия ещё не готова.")
		return
	var catalog := WbmVehicleCatalog.get_available(int(game_manager.profile.account_level))
	var selected := str(local_data.get_value("hangar", "selected_class", "tank"))
	_add_text("Выберите класс техники для управления в текущем бою. Доступность зависит от уровня профиля.")
	for item in catalog:
		var vehicle_class := str(item.get("class", "tank"))
		_add_heading(str(item.name).to_upper())
		_add_text("%s • открытие с %d уровня" % [str(item.role), int(item.unlock_level)])
		_add_text("Статус: %s" % ("ВЫБРАНО" if selected == vehicle_class else "доступно"))
		_add_action("ВЫБРАТЬ: " + str(item.name).to_upper(), _select_hangar_vehicle.bind(vehicle_class))
	_add_text("Модели и характеристики каталога пока демонстрационные; выбор переключает управление на доступный союзный экземпляр.")
	_add_action("ЦИКЛИЧЕСКИ ПЕРЕКЛЮЧИТЬ ТЕХНИКУ", Callable(game_manager, "switch_player_vehicle"))

func _select_hangar_vehicle(vehicle_class: String) -> void:
	if not is_instance_valid(game_manager):
		return
	if game_manager.select_vehicle_from_hangar(vehicle_class):
		local_data.set_value("hangar", "selected_class", vehicle_class)
		_save_local_data()
		_open_page("Ангар")
	else:
		_add_text("Техника этого класса сейчас недоступна. Попробуйте после её возрождения.")

func _build_profile_page() -> void:
	_add_heading("ЛИЧНОЕ ДЕЛО")
	if not is_instance_valid(game_manager):
		_add_text("Профиль пока недоступен.")
		return
	var p = game_manager.profile
	_add_text("Позывной: %s" % p.username)
	var nickname_input := LineEdit.new()
	nickname_input.placeholder_text = "Новый позывной (3–16 символов)"
	nickname_input.text = p.username
	content_box.add_child(nickname_input)
	_add_action("СОХРАНИТЬ ПОЗЫВНОЙ", func():
		var validation := WbmPlayerIdentity.validate_username(nickname_input.text)
		if bool(validation.valid):
			p.username = nickname_input.text.strip_edges()
			p.save_profile()
			_open_page("Профиль")
		else:
			_add_text(str(validation.reason))
	)
	_add_text("Уровень аккаунта: %d / 100" % p.account_level)
	_add_text("Опыт: %d XP" % p.experience)
	_add_text("Боёв: %d" % p.total_battles)
	_add_text("Побед: %d" % p.total_wins)
	var win_rate := 0.0 if p.total_battles == 0 else float(p.total_wins) * 100.0 / float(p.total_battles)
	_add_text("Процент побед: %.1f%%" % win_rate)
	_add_action("ПОЛУЧИТЬ ЕЖЕДНЕВНУЮ НАГРАДУ", _claim_daily_reward)

func _claim_daily_reward() -> void:
	if not is_instance_valid(game_manager):
		return
	var date_key := Time.get_date_string_from_system()
	if game_manager.profile.claim_daily_reward(date_key):
		_open_page("Профиль")
	else:
		_add_text("Ежедневная награда на сегодня уже получена.")

func _build_missions_page() -> void:
	_add_heading("БОЕВЫЕ ЗАДАНИЯ")
	if not is_instance_valid(game_manager):
		_add_text("Миссии недоступны.")
		return
	var missions = game_manager.missions
	for mission_id in missions.definitions.keys():
		var definition: Dictionary = missions.definitions[mission_id]
		var current := int(missions.progress.get(mission_id, 0))
		var target := int(definition.target)
		_add_text("%s — %d / %d" % [str(definition.title), current, target])
		var progress_bar := ProgressBar.new()
		progress_bar.max_value = target
		progress_bar.value = current
		progress_bar.show_percentage = false
		content_box.add_child(progress_bar)
		if missions.is_complete(mission_id):
			var claimed: Array = missions.progress.get("_claimed", [])
			if mission_id in claimed:
				_add_text("Награда получена")
			else:
				_add_action("ЗАБРАТЬ %d XP" % int(definition.reward_xp), _claim_mission.bind(str(mission_id)))

func _claim_mission(mission_id: String) -> void:
	if is_instance_valid(game_manager):
		game_manager.missions.claim_reward(mission_id, game_manager.profile)
	_open_page("Миссии")

func _build_achievements_page() -> void:
	_add_heading("НАГРАДЫ И ДОСТИЖЕНИЯ")
	if not is_instance_valid(game_manager):
		_add_text("Достижения недоступны.")
		return
	var achievements = game_manager.achievements
	for achievement_id in WbmAchievementSystem.DEFINITIONS.keys():
		var definition: Dictionary = WbmAchievementSystem.DEFINITIONS[achievement_id]
		var unlocked: bool = achievements.unlocked.has(achievement_id)
		_add_text("%s — %s" % [("✓" if unlocked else "🔒"), str(definition.title)])
		_add_text(str(definition.description))
	_add_text("Открыто: %d / %d" % [achievements.get_unlocked_count(), WbmAchievementSystem.DEFINITIONS.size()])

func _build_season_page() -> void:
	_add_heading("СЕЗОННЫЙ ПРОПУСК")
	if not is_instance_valid(game_manager):
		_add_text("Сезонные данные недоступны.")
		return
	var season = game_manager.season
	_add_text("Сезон: %s" % season.season_id)
	_add_text("Уровень пропуска: %d / %d" % [season.get_tier(), season.MAX_TIERS])
	_add_text("Сезонный опыт: %d XP" % season.season_xp)
	var bar := ProgressBar.new()
	bar.max_value = 1000
	bar.value = season.season_xp % 1000
	bar.show_percentage = false
	content_box.add_child(bar)
	_add_text("Награды и премиальная ветка пока не подключены к серверу.")

func _build_online_placeholder(page: String) -> void:
	_add_heading(page.to_upper())
	match page:
		"Друзья":
			_add_text("Список друзей, приглашения и статусы появятся после подключения аккаунтов и серверного API.")
		"Отряды":
			_add_text("Создание отрядов и совместный поиск боя требуют серверного лобби и матчмейкинга.")
		"Кланы":
			_add_text("Планируются создание клана, роли, состав, клановый чат и глобальная война за территории.")
		"Магазин":
			_add_text("Планируются техника, косметика и наборы. Покупки не активированы; платёжная система отсутствует.")
		"Рейтинг":
			_add_text("Рейтинговые матчи, дивизионы и таблицы лидеров требуют серверной статистики.")
		"События":
			_add_text("Сезонные события и временные режимы пока представлены только разделом интерфейса.")
	_add_text("Это экран-заготовка, а не работающая онлайн-функция. Мы не показываем фиктивные аккаунты или товары.")

func _build_settings_page() -> void:
	_add_heading("ПАРАМЕТРЫ ИГРЫ")
	if not is_instance_valid(game_manager):
		_add_text("Настройки временно недоступны.")
		return
	var settings = game_manager.settings
	_add_text("Общая громкость")
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
	_add_text("Чувствительность управления")
	var sensitivity := HSlider.new()
	sensitivity.min_value = 0.25
	sensitivity.max_value = 2.5
	sensitivity.step = 0.05
	sensitivity.value = settings.sensitivity
	content_box.add_child(sensitivity)
	sensitivity.value_changed.connect(func(value: float):
		settings.sensitivity = value
		settings.save_settings()
	)
	var vibration := CheckButton.new()
	vibration.text = "Вибрация"
	vibration.button_pressed = settings.vibration_enabled
	content_box.add_child(vibration)
	vibration.toggled.connect(func(value: bool):
		settings.vibration_enabled = value
		settings.save_settings()
	)
	var aim := CheckButton.new()
	aim.text = "Помощь в прицеливании"
	aim.button_pressed = settings.aim_assist_enabled
	content_box.add_child(aim)
	aim.toggled.connect(func(value: bool):
		settings.aim_assist_enabled = value
		settings.save_settings()
	)

func _restart_match() -> void:
	get_tree().reload_current_scene()


func _save_local_data() -> void:
	local_data.save(local_data_path)

func _build_friends_page() -> void:
	_add_heading("СПИСОК ДРУЗЕЙ")
	_add_text("Локальный список контактов на этом устройстве. Онлайн-приглашения появятся после запуска серверов.")
	var friends: Array = local_data.get_value("social", "friends", [])
	for friend in friends:
		_add_text("● " + str(friend))
	var field := LineEdit.new()
	field.placeholder_text = "Позывной друга"
	content_box.add_child(field)
	_add_action("ДОБАВИТЬ КОНТАКТ", func():
		var nick := field.text.strip_edges()
		var validation := WbmPlayerIdentity.validate_username(nick)
		if bool(validation.valid) and not nick in friends:
			friends.append(nick)
			local_data.set_value("social", "friends", friends)
			_save_local_data()
			_open_page("Друзья")
		else:
			_add_text(str(validation.reason) if not bool(validation.valid) else "Этот контакт уже добавлен.")
	)

func _build_squad_page() -> void:
	_add_heading("ОТРЯД")
	var created := bool(local_data.get_value("squad", "created", false))
	_add_text("Статус: " + ("отряд создан локально" if created else "вы не состоите в отряде"))
	_add_text("Размер отряда: до 4 игроков. Совместный онлайн-поиск пока не подключён.")
	_add_action("СОЗДАТЬ ОТРЯД", func():
		local_data.set_value("squad", "created", true)
		local_data.set_value("squad", "created_at", Time.get_datetime_string_from_system())
		_save_local_data()
		_open_page("Отряды")
	)
	_add_action("РАСПУСТИТЬ ОТРЯД", func():
		local_data.set_value("squad", "created", false)
		_save_local_data()
		_open_page("Отряды")
	)

func _build_clan_page() -> void:
	_add_heading("КЛАНОВЫЙ ЦЕНТР")
	var clan := str(local_data.get_value("clan", "name", ""))
	_add_text("Ваш клан: " + (clan if not clan.is_empty() else "не создан"))
	var field := LineEdit.new()
	field.placeholder_text = "Название клана"
	field.text = clan
	content_box.add_child(field)
	_add_action("СОЗДАТЬ / ПЕРЕИМЕНОВАТЬ", func():
		var value := field.text.strip_edges()
		if value.length() >= 3 and value.length() <= 20:
			local_data.set_value("clan", "name", value)
			_save_local_data()
			_open_page("Кланы")
		else:
			_add_text("Название должно содержать 3–20 символов.")
	)
	_add_text("Участники, роли, чат и война за территории требуют серверной версии.")

func _build_shop_page() -> void:
	_add_heading("АРСЕНАЛ / ВНЕШНИЙ ВИД")
	_add_text("Демонстрационные бесплатные варианты оформления. Реальных платежей и покупок за деньги здесь нет.")
	var owned: Array = local_data.get_value("shop", "unlocked", ["Стандартный камуфляж"])
	for skin in ["Песчаный камуфляж", "Лесной камуфляж", "Зимний камуфляж"]:
		var is_owned: bool = owned.has(skin)
		_add_text(skin + (" — открыт" if is_owned else " — доступен в демо"))
		if not is_owned:
			_add_action("ОТКРЫТЬ БЕСПЛАТНО: " + skin.to_upper(), func():
				owned.append(skin)
				local_data.set_value("shop", "unlocked", owned)
				_save_local_data()
				_open_page("Магазин")
			)

func _build_rating_page() -> void:
	_add_heading("ЛИЧНАЯ СТАТИСТИКА")
	if not is_instance_valid(game_manager):
		_add_text("Статистика пока недоступна.")
		return
	var p = game_manager.profile
	var rate := 0.0 if p.total_battles == 0 else 100.0 * float(p.total_wins) / float(p.total_battles)
	_add_text("Боёв: %d" % p.total_battles)
	_add_text("Побед: %d" % p.total_wins)
	_add_text("Поражений: %d" % maxi(0, p.total_battles - p.total_wins))
	_add_text("Доля побед: %.1f%%" % rate)
	_add_text("Глобальная таблица лидеров и рейтинговый подбор требуют серверной статистики.")

func _build_events_page() -> void:
	_add_heading("ТЕКУЩЕЕ СОБЫТИЕ")
	_add_text("Операция «Стальной рубеж» — локальное демонстрационное событие.")
	var claimed := bool(local_data.get_value("events", "steel_claimed", false))
	_add_text("Награда за участие: 150 XP профиля (один раз на устройстве).")
	if not claimed:
		_add_action("ПОЛУЧИТЬ НАГРАДУ СОБЫТИЯ", func():
			if is_instance_valid(game_manager):
				game_manager.profile.add_experience(150)
				game_manager.profile.save_profile()
			local_data.set_value("events", "steel_claimed", true)
			_save_local_data()
			_open_page("События")
		)
	else:
		_add_text("Награда уже получена.")
	_add_text("Сезонные сетевые события и глобальные таблицы появятся после подключения сервера.")

func show_match_results(won: bool, blue_score: int, red_score: int) -> void:
	overlay.visible = true
	current_page = "Результаты боя"
	page_title.text = "WBM / РЕЗУЛЬТАТЫ"
	for child in content_box.get_children():
		child.queue_free()
	_add_heading("ПОБЕДА" if won else ("НИЧЬЯ" if blue_score == red_score else "ПОРАЖЕНИЕ"))
	_add_text("СИНИЕ  %d  :  %d  КРАСНЫЕ" % [blue_score, red_score])
	if is_instance_valid(game_manager):
		_add_text("Всего боёв: %d" % game_manager.profile.total_battles)
		_add_text("Побед: %d" % game_manager.profile.total_wins)
		_add_text("Уровень аккаунта: %d / 100" % game_manager.profile.account_level)
	_add_text("Телеметрия матча сохранена локально. Повтор пока нельзя воспроизвести.")
	_add_action("НОВЫЙ БОЙ", _restart_match)
	_add_action("В АНГАР / ГЛАВНОЕ МЕНЮ", func():
		_open_page("Главное меню")
	)


func _build_replays_page() -> void:
	_add_heading("АРХИВ СРАЖЕНИЙ")
	_add_text("Локальные записи на этом устройстве. Выберите бой, чтобы просмотреть сводку и временные отметки телеметрии.")
	if not is_instance_valid(game_manager) or not is_instance_valid(game_manager.replay_recorder):
		_add_text("Архив пока недоступен.")
		return
	var recorder = game_manager.replay_recorder
	var replays: Array[Dictionary] = recorder.list_replays()
	if replays.is_empty():
		_add_text("Сохранённых повторов пока нет. Запись текущего боя сохранится после его завершения.")
		return
	for replay_info in replays:
		var file_name := str(replay_info.get("name", ""))
		var duration := float(replay_info.get("duration", 0.0))
		var count := int(replay_info.get("sample_count", 0))
		_add_heading(file_name)
		_add_text("Длительность: %s  •  записей телеметрии: %d" % [_format_replay_time(duration), count])
		if bool(replay_info.get("valid", false)):
			_add_action("ОТКРЫТЬ СВОДКУ", _inspect_replay.bind(file_name))
		_add_action("УДАЛИТЬ ПОВТОР", _delete_replay.bind(file_name))
	_add_text("Важно: здесь доступен просмотр сохранённых данных и временных отметок. Полноценное 3D-воспроизведение и свободная камера ещё не реализованы.")

func _inspect_replay(file_name: String) -> void:
	if not is_instance_valid(game_manager) or not is_instance_valid(game_manager.replay_recorder):
		return
	var data: Dictionary = game_manager.replay_recorder.load_replay(file_name)
	if data.is_empty():
		_add_text("Не удалось прочитать этот файл повтора.")
		return
	_open_page("Повторы")
	_add_heading("СВОДКА: " + file_name)
	var entries: Array = data.get("samples", [])
	_add_text("Длительность: %s" % _format_replay_time(float(data.get("duration", 0.0))))
	_add_text("Всего точек телеметрии: %d" % entries.size())
	var first_by_vehicle: Dictionary = {}
	var last_by_vehicle: Dictionary = {}
	for sample in entries:
		if not sample is Dictionary:
			continue
		var vehicle_id := str(sample.get("id", "unknown"))
		if not first_by_vehicle.has(vehicle_id):
			first_by_vehicle[vehicle_id] = sample
		last_by_vehicle[vehicle_id] = sample
	_add_heading("УЧАСТНИКИ ЗАПИСИ")
	for vehicle_id in first_by_vehicle.keys():
		var first: Dictionary = first_by_vehicle[vehicle_id]
		var last: Dictionary = last_by_vehicle[vehicle_id]
		var team_label := "Синие" if int(first.get("team", 0)) == 0 else "Красные"
		var hp := float(last.get("hp", 0.0))
		_add_text("%s — %s; последняя записанная прочность: %.0f" % [str(vehicle_id), team_label, hp])
	_add_heading("ВРЕМЕННЫЕ ОТМЕТКИ")
	var step := maxi(1, int(entries.size() / 8))
	for index in range(0, entries.size(), step):
		var sample = entries[index]
		if sample is Dictionary:
			_add_text("%s  •  %s  •  HP %.0f" % [_format_replay_time(float(sample.get("t", 0.0))), str(sample.get("id", "—")), float(sample.get("hp", 0.0))])
	_add_action("НАЗАД К АРХИВУ", _open_page.bind("Повторы"))

func _delete_replay(file_name: String) -> void:
	if not is_instance_valid(game_manager) or not is_instance_valid(game_manager.replay_recorder):
		return
	var result: Error = game_manager.replay_recorder.delete_replay(file_name)
	_open_page("Повторы")
	if result != OK:
		_add_text("Не удалось удалить файл: %s" % error_string(result))

func _format_replay_time(seconds: float) -> String:
	var total := maxi(0, int(seconds))
	return "%02d:%02d" % [total / 60, total % 60]
