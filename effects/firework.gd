extends Control

const PackedFireworkProjectile: PackedScene = preload("res://effects/firework_projectile.tscn")

# 发射配置
var launch_configs := [
    # 每个配置包含：起点、终点、延迟时间
    {
        "from": Vector2(100, 600),
        "to": Vector2(200, 100),
        "delay": 0.0,
        "color": Color(1, 0, 0)  # 红色
    },
    {
        "from": Vector2(300, 600),
        "to": Vector2(400, 150),
        "delay": 0.3,
        "color": Color(0, 1, 0)  # 绿色
    },
    {
        "from": Vector2(500, 600),
        "to": Vector2(600, 200),
        "delay": 0.6,
        "color": Color(0, 0, 1)  # 蓝色
    },
    {
        "from": Vector2(900, 600),
        "to": Vector2(200, 100),
        "delay": 0.0
    },
    {
        "from": Vector2(1100, 600),
        "to": Vector2(400, 150),
        "delay": 0.5
    },
    {
        "from": Vector2(1000, 600),
        "to": Vector2(600, 200),
        "delay": 0.9
    }
]

# func _ready() -> void:
    # 根据配置创建多个烟花
    # for config in launch_configs:
    #     launch_firework(config)

func launch_firework(config: Dictionary) -> void:
    if config.delay > 0:
        # 如果有延迟，创建一个计时器
        var timer := get_tree().create_timer(config.delay)
        await timer.timeout
    
    # 创建烟花发射物
    var projectile = FireworkProjectile.create(
        PackedFireworkProjectile,
        config.from,
        config.to,
        config.get("color", Color.WHITE),  # 使用默认白色如果没有指定颜色
        config.get('char', ''),
    )
    add_child(projectile)

# 便捷方法：添加新的烟花配置
func add_firework(from: Vector2, to: Vector2, delay: float = 0.0, custom_color: Color = Color.WHITE) -> void:
    var config := {
        "from": from,
        "to": to,
        "delay": delay,
        "color": custom_color
    }
    launch_firework(config)

# 随机生成一组烟花
func create_random_fireworks(count: int, base_delay: float = 0.2) -> void:
    for i in range(count):
        var from := Vector2(
            randf_range(100, get_viewport_rect().size.x - 100),
            get_viewport_rect().size.y - 100
        )
        var to := Vector2(
            from.x + randf_range(-200, 200),
            randf_range(100, 300)
        )
        var random_color = Color(randf(), randf(), randf())
        add_firework(from, to, base_delay * i, random_color)


func start_drops():
    $Drop1.emitting = true
    $Drop2.emitting = true
    $Drop3.emitting = true

func stop_drops():
    $Drop1.emitting = false
    $Drop2.emitting = false
    $Drop3.emitting = false


func start_spray():
    $BL/SprayL.emitting = true
    $BR/SprayR.emitting = true

func stop_spray():
    $BL/SprayL.emitting = false
    $BR/SprayR.emitting = false
