extends Path2D
class_name FireworkProjectile

@onready var path_follow_2d: PathFollow2D = $PathFollow2D
var path_2d: Path2D = self
@onready var gpu_particles_2d: GPUParticles2D = $PathFollow2D/GPUParticles2D
@onready var tail: GPUParticles2D = $PathFollow2D/Tail
@onready var sprite_2d: Sprite2D = $PathFollow2D/Sprite2D
@onready var audio_stream_player: AudioStreamPlayer2D = $AudioStreamPlayer
@onready var audio_stream_player2: AudioStreamPlayer2D = $AudioStreamPlayer2

var char = ''

var speed := 900.0
var is_exploded := false

var firework_expl = load('res://temp/sfx/firework_expl.ogg')

# 颜色属性
var color: Color = Color.WHITE : set = set_color

func set_color(value: Color) -> void:
    color = value
    if not is_node_ready():
        await ready
    
    # 更新爆炸粒子颜色
    var explosion_material = gpu_particles_2d.process_material as ParticleProcessMaterial
    if explosion_material:
        explosion_material = explosion_material.duplicate()  # 创建材质副本
        explosion_material.color = color
        gpu_particles_2d.process_material = explosion_material
    
    # 更新尾巴粒子颜色
    var tail_material = tail.process_material as ParticleProcessMaterial
    if tail_material:
        tail_material = tail_material.duplicate()
        tail_material.color = color
        tail.process_material = tail_material
    
    # 可选：更新精灵颜色
    sprite_2d.modulate = color

static func curve2(from:Vector2, to:Vector2, mid_h=-10):
    var curve = Curve2D.new()
    var fdis = from.distance_to(to)
    var spline = from.direction_to(to) * fdis * 0.4
    var t_spline = from.direction_to(to) * fdis * 0.3
    var mid = from.lerp(to, 0.6) + Vector2(0, mid_h)
    curve.add_point(from)
    curve.add_point(mid, -spline, t_spline)
    curve.add_point(to)
    return curve
# 创建曲线路径
func create_curve(from: Vector2, to: Vector2) -> void:
    var curve = curve2(from, to, -Rnd.rangef(10, 40))
    
    # # 计算控制点
    # var distance := from.distance_to(to)
    # var mid_height := (to.y + from.y) / 2.0
    
    # # 计算中间控制点
    # var mid_point := from.lerp(to, 0.5)  # 中点
    # var control_point := mid_point + Vector2(0, -30)  # 上方的控制点
    
    # # 添加贝塞尔曲线的点
    # curve.add_point(from, Vector2.ZERO, mid_point)
    # curve.add_point(to, mid_point, to)
    # print('from, to', from, to, control_point)
    
    # 设置路径
    path_2d.curve = curve
    path_2d.position = Vector2.ZERO
    $PathFollow2D.progress_ratio = 0.0
    
    # 重置状态
    is_exploded = false

# 静态方法创建烟花实例，添加颜色参数
static func create(scene: PackedScene, from: Vector2, to: Vector2, custom_color: Color = Color.WHITE, char = '') -> Node:
    var instance := scene.instantiate() as FireworkProjectile
    instance.position = Vector2.ZERO
    instance.create_curve(from, to)
    instance.color = custom_color  # 设置颜色
    instance.char = char
    return instance


func _ready():
    audio_stream_player.pitch_scale = 1.0 + Rnd.rangef(0.0, 0.10)
    audio_stream_player2.pitch_scale = 1.0 + Rnd.rangef(0.0, 0.10)
    audio_stream_player.play()


func _process(delta: float) -> void:
    if is_exploded:
        return
        
    # 更新路径位置
    path_follow_2d.progress += speed * delta
    tail.rotation = path_follow_2d.rotation + PI
    
    # 当到达路径末端时
    if path_follow_2d.progress_ratio >= 1.0 and not is_exploded:
        explode()

func explode():
    is_exploded = true
    gpu_particles_2d.emitting = true
    sprite_2d.hide()
    tail.emitting = false

    audio_stream_player2.play()
    audio_stream_player.stop()
    if char:
        var lb = Label.new()
        lb.text = char
        add_child(lb)
        UI.set_font(lb, 'res://effects/font.tres')
        UI.set_font_size(lb, 256)
        lb.position = sprite_2d.global_position + Vector2(-128, -128)
        var orig_pos = lb.position
        lb.pivot_offset = Vector2(128, 128)

        # var clr_to =Color.from_hsv(0.4 + Rnd.rangef(0.2), 0.8, 1.0)
        var clr_to = color
        TwnLite.at(lb).tween({
            prop='modulate',
            from=clr_to.lightened(0.3),
            to=clr_to,
            dur=1.0,
            parallel=true,
        }).tween({
            prop='scale',
            from=Vector2(.5, .5),
            to=Vector2(1, 1),
            dur=0.5,
            parallel=true,
        }).tween({
            prop='position',
            from=orig_pos,
            to=orig_pos + Vector2(0, -Rnd.rangef(60, 140)),
            dur=3.0,
            parallel=true,
            ease=Tween.EASE_OUT,
            trans=Tween.TRANS_SINE,
        }).tween({
            prop='modulate',
            from=clr_to,
            to=Color('FFFFFF00'),
            dur=1.2,
            parallel=true,
            delay=1.5,
        })

        await get_tree().create_timer(gpu_particles_2d.lifetime + 4.1).timeout
        queue_free()
    else:
        await get_tree().create_timer(gpu_particles_2d.lifetime + 0.1).timeout
        queue_free()
