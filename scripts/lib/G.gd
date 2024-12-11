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
    自动打开，自动备份，字数，行号，自动换行，改变字号等
增加内置输入法功能
    拼音: 解决在部分Linux系统中输入法不能正确响应的问题
重新制作了全部特效
    文字特效: 色彩/间距/大小/动画
    音效: 优化音效
    屏幕震动: 稍微降低了强度
        警告:长时间的屏幕震动确实会让人头晕
    删除特效: 重绘动画/增加粒子效果
加入连击特效和连击终结特效
字体
    使用新的字体以提供更好的显示效果
修复导出
    修复了导出到Windows后不工作的问题
    修复了导出到Mac后不工作的问题
按键捕捉
    优化以更好的捕捉按键
    修复了Windows下未知按键的问题
    修复了Mac下部分按键的问题
优化
    一些性能和细节优化
[/color]
""",
"""
0.0.1：
[color=888888]
修改Godot插件
    github.com/jotson/ridiculous_coding
加上文件编辑的基本功能
    打开，新建，保存
[/color]
""",
]

const WRITER_ABOUT = """[center][shake][font s=22]wild writer 0.02[/font][/shake]
by xianrenak[/center]

Web版:
[url]http://xianrenak.itch.io/wildwriter[/url]
[url]http://xianrenak.github.io/wildwriter[/url]

下载（Win, Linux, Mac）:
[url]http://xianrenak.itch.io/wildwriter[/url]
[url]http://github.com/xianrenak/wildwriter[/url]

B站 （会发布更新）:
[url]http://space.bilibili.com/589805968[/url]
"""
