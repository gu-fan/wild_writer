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
                'margin':{
                    left=80,
                    right=80,
                    top=80,
                    bottom=80,
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
                    type='ColorRect',
                    color ='333399',
                    # custom_minimum_size = Vector2(80, 80),
                    child={
                        name='TabContainer',
                        type='TabContainer',
                        custom_minimum_size=Vector2(700, 500),
                        preset=UI.PRESET_CENTER,
                        children={
                            'TAB_BASIC':{
                                type='ColorRect',
                                color='993333',
                                child={
                                    name='Margin',
                                    type='MarginContainer',
                                    preset=UI.PRESET_FULL_RECT,
                                    margin={
                                        left=20,
                                        right=20,
                                        top=20,
                                        bottom=20,
                                    },
                                    child={
                                        name='VBox',
                                        type='VBoxContainer',
                                        preset=UI.PRESET_FULL_RECT,
                                    }
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
