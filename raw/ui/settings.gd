const _data = {
    'OldSettings':{
        type='res://scenes/settings.tscn',
    },
    'Settings':{
        type='Control',
        preset=UI.PRESET_FULL_RECT,
        # mouse_filter = UI.MOUSE_FILTER_STOP,
        children={
            'Close':{
                type='Button',
                custom_minimum_size = Vector2(30, 30),
                flat = true,
                focus_mode=0,
                preset=UI.PRESET_BOTTOM_RIGHT,
            },
            'Margin':{
                'type':'MarginContainer',
                'preset':UI.PRESET_FULL_RECT,
                # 'mouse_filter': UI.MOUSE_FILTER_IGNORE,
                'margin':{
                    left=20,
                    right=20,
                    top=20,
                    bottom=20,
                },
                'transition_in': {
                    'prop': 'scale:x',
                    'from': 0,
                    'to': 1,
                    'dur': 0.3,
                },
                'transition_out': {
                    'prop': 'scale:x',
                    'from': 1,
                    'to': 0,
                    'dur': 0.3,
                },
                'child':{
                    name='Background',
                    type='Control',
                    # mouse_filter = UI.MOUSE_FILTER_STOP,
                    # color ='333399',
                    # custom_minimum_size = Vector2(80, 80),
                    # on_pressed='self:hide',
                    child={
                        name='TabContainer',
                        type='TabContainer',
                        custom_minimum_size=Vector2(700, 600),
                        preset=UI.PRESET_CENTER,
                        children={
                            'TAB_BASIC':{
                                type = 'Control',
                                child={
                                    name='Scroll',
                                    type='ScrollContainer',
                                    horizontal_scroll_mode = 0,
                                    preset=UI.PRESET_FULL_RECT,
                                    child={
                                        name='Margin',
                                        type='MarginContainer',
                                        size_flags_vertical = Control.SIZE_EXPAND_FILL,
                                        margin={
                                            left=20,
                                            right=20,
                                            top=20,
                                            bottom=5,
                                        },
                                        child={
                                            name='VBox',
                                            type='VBoxContainer',
                                        },
                                    }
                                },
                            },
                            'TAB_INTERFACE':{
                                type = 'Control',
                                child={
                                    name='Scroll',
                                    type='ScrollContainer',
                                    horizontal_scroll_mode = 0,
                                    preset=UI.PRESET_FULL_RECT,
                                    child={
                                        name='Margin',
                                        type='MarginContainer',
                                        size_flags_vertical = Control.SIZE_EXPAND_FILL,
                                        margin={
                                            left=20,
                                            right=20,
                                            top=20,
                                            bottom=5,
                                        },
                                        child={
                                            name='VBox',
                                            type='VBoxContainer',
                                        },
                                    }
                                },
                            },
                            'TAB_EFFECT':{
                                type = 'Control',
                                child={
                                    name='Scroll',
                                    type='ScrollContainer',
                                    horizontal_scroll_mode = 0,
                                    preset=UI.PRESET_FULL_RECT,
                                    child={
                                        name='Margin',
                                        type='MarginContainer',
                                        size_flags_vertical = Control.SIZE_EXPAND_FILL,
                                        margin={
                                            left=20,
                                            right=20,
                                            top=20,
                                            bottom=5,
                                        },
                                        child={
                                            name='VBox',
                                            type='VBoxContainer',
                                        },
                                    }
                                },
                            },
                            'TAB_SHORTCUT':{
                                type = 'Control',
                                child={
                                    name='Scroll',
                                    type='ScrollContainer',
                                    horizontal_scroll_mode = 0,
                                    preset=UI.PRESET_FULL_RECT,
                                    child={
                                        name='Margin',
                                        type='MarginContainer',
                                        size_flags_vertical = Control.SIZE_EXPAND_FILL,
                                        margin={
                                            left=20,
                                            right=20,
                                            top=20,
                                            bottom=5,
                                        },
                                        child={
                                            name='VBox',
                                            type='VBoxContainer',
                                        },
                                    }
                                },
                            },
                            'TAB_IME': {
                                type = 'Control',
                                child={
                                    name='Scroll',
                                    type='ScrollContainer',
                                    horizontal_scroll_mode = 0,
                                    preset=UI.PRESET_FULL_RECT,
                                    child={
                                        name='Margin',
                                        type='MarginContainer',
                                        size_flags_vertical = Control.SIZE_EXPAND_FILL,
                                        margin={
                                            left=20,
                                            right=20,
                                            top=20,
                                            bottom=5,
                                        },
                                        child={
                                            name='VBox',
                                            type='VBoxContainer',
                                        },
                                    }
                                },
                            },
                            'TAB_ABOUT': {
                                type = 'Control',
                                child={
                                    name='Scroll',
                                    type='ScrollContainer',
                                    horizontal_scroll_mode = 0,
                                    preset=UI.PRESET_FULL_RECT,
                                    child={
                                        name='Margin',
                                        type='MarginContainer',
                                        size_flags_vertical = Control.SIZE_EXPAND_FILL,
                                        margin={
                                            left=20,
                                            right=20,
                                            top=20,
                                            bottom=5,
                                        },
                                        child={
                                            name='VBox',
                                            type='VBoxContainer',
                                        },
                                    }
                                },
                            },
                        },
                    },
                },
            },
        },
    },
    'Node':{
        type='ColorRect',
        custom_minimum_size = Vector2(80, 80),
        color = '00FF00',
        preset=UI.PRESET_TOP_RIGHT,
        pre_offset= Vector2(50, 50),
    },
}


static func data():
    return _data
