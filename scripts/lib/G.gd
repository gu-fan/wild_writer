class_name G

const WRITER_PLACEHOLDER = """
                        Wild Writer         0.0.2

                        你可以直接开始打字， 也可以
                        新建文件    {new}
                        打开文件    {open}
                        保存文件    {save}
                        打开设置    {setting}
"""

const WRITER_TIPS = [
"""[color=888888]小提示：
连续打字不要超过一个小时，
如果感到头晕目眩或不适，可以停下来休息一下[/color]
""",
"""[color=888888]小提示： 
如果需要居中显示当前行，可以在当前行下插入空行[/color]
""",
"""[color=888888]小提示：
Ctrl+A全选，Ctrl+C复制，Ctrl+V粘贴
Ctrl+Z撤销，Ctrl+Y重做[/color]
""",
"""[color=888888]小提示：
可以将文本文件拖拽到窗口里来打开[/color]
""",
"""[color=888888]小提示：
自动打开文件会保留上一次未保存的编辑
如果想撤销这些编辑可以直接打开一次该文件
""",
]

const WRITER_LOGS = [
"""[center][color=888888][font s=18]更新日志[/font][/color][/center]""",
"""
0.0.2：
[color=888888]
增加基本的编辑器功能
    设置面板，快捷键
增加基本的文本编辑功能
    自动打开，自动保存，字数，行号，自动换行，改变字号等
加入内置输入法功能
    解决在部分Linux系统中输入法不能正确响应的问题
    目前只有拼音，并且不支持全角符号
    目前词库使用的是GooglePinyin的默认词库
    需要扩充常用词组的请在
        github.com/xianrenak/wildwriter/issues里提交
重新制作了全部特效
    音效: 优化了所有音效，优化了连续打字的音效
    屏幕震动: 稍微降低了强度
        [color=ff3333]警告:[/color]长时间的屏幕震动确实会让人头晕
        并导致开发中断了一天
    文字特效: 色彩/间距/大小/动画
    回车特效: 重绘动画
    删除特效: 重绘动画/增加粒子效果
    加入连击特效和连击终结特效
字体
    使用新的字体以提供更好的显示效果
修复导出
    修复了导出到Windows后不工作的问题
    增加了Mac的导出
        注意： 因为开发者身份已过期所以没有签名，会被Gatekeeper阻止
    目前没有Android/iOS上的版本的计划，但是可以使用Web版进行体验
按键捕捉
    优化以更好的捕捉按键
    加入方向键上下左右的显示
    修复了Windows下未知按键的问题
    修复了Mac下部分按键的问题(cmd+c/cmd+v)
优化
    一些性能和细节优化
其他
    一些视觉效果的建议：
        连击: Digita1Extremes 的高赞评论，很多用户也提出类似建议
        连击终结: My_SSR， 很多用户也提出类似建议
        透明 Yzl_烟雨 离散度 L0very 
        色彩 无端艺想 动画 NnWinter冬
        分散文字 朋克洛德银狼/iiiieee 
    一些文本编辑的建议： 
        自动保存 GALZY素夜
        字体大小 Venlac
[/color]
""",
"""
0.0.1：
[color=888888]
修改Godot插件
    github.com/jotson/ridiculous_coding
加入文件编辑的基本功能
    打开，新建，保存
其他
    开发本版本的原因来自莫浪等用户的评论，
    因此让不用Godot编辑器的用户也体验一下
[/color]
""",
]

const WRITER_ABOUT = """[center][shake][font s=22]wild writer 0.02[/font][/shake]
by xianrenak[/center]

下载（Win, Linux, Mac, Web）:
[url]http://xianrenak.itch.io/wildwriter[/url]
[url]http://github.com/xianrenak/wildwriter[/url]

B站 （发布更新）:
[url]http://space.bilibili.com/589805968[/url]

Bug反馈
[url]http://github.com/xianrenak/wildwriter/issues[/url]
"""