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
                                children={
                                    'RECT':{
                                        type='ColorRect',
                                        custom_minimum_size = Vector2(100, 100),
                                        preset=UI.PRESET_CENTER,
                                        transition_in={
                                            'prop': 'modulate:a',
                                            'from': 0,
                                            'to': 1,
                                            'dur': 0.3,
                                        },
                                        transition_out= {
                                            'prop': 'modulate:a',
                                            'from': 1,
                                            'to': 0,
                                            'dur': 0.3,
                                        },
                                        children={
                                            'RECT2':{
                                                type='ColorRect',
                                                custom_minimum_size = Vector2(100, 100),
                                                preset=UI.PRESET_CENTER,
                                                pre_offset = Vector2(0, 200),
                                                transition_in={
                                                    'prop': 'modulate',
                                                    'from': Color('339933'),
                                                    'to': Color('993399'),
                                                    'dur': 0.3,
                                                },
                                                transition_out= {
                                                    'prop': 'modulate',
                                                    'to': Color('339933'),
                                                    'from': Color('993399'),
                                                    'dur': 0.3,
                                                },
                                            },
                                        },
                                    },
                                },
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
