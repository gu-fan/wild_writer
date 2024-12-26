const _data = {
    'OldSettings':{
        type='res://scenes/settings.tscn',
    },
    'Settings':{
        type='Control',
        preset=UI.PRESET_FULL_RECT,
        # mouse_filter = UI.MOUSE_FILTER_STOP,
        children={
            'Margin':{
                'type':'MarginContainer',
                'preset':UI.PRESET_FULL_RECT,
                'theme_override_constants/margin_left': 80,
                'theme_override_constants/margin_right': 80,
                'theme_override_constants/margin_top': 80,
                'theme_override_constants/margin_bottom': 80,
                'child':{
                    type='ColorRect',
                    color ='333399',
                    # custom_minimum_size = Vector2(80, 80),
                    child={
                        type='TabContainer',
                        custom_minimum_size=Vector2(700, 500),
                        preset=UI.PRESET_CENTER,
                        children={
                            'TAB_BASIC':{
                                type='ColorRect',
                                color='993333',
                            },
                            'TAB_KEY':{
                                type='ColorRect',
                                color='339933',
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
