extends Node2D


func _ready():
    # 运行基准测试
    var benchmark = TrieBenchmark.new()
    benchmark.run_benchmark()
    print(benchmark.generate_report())
