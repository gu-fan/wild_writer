WILD WRITER
===========

user dir

Linux ~/.local/share/godot/app_userdata/wild_writer/
Linux ~/.local/share/Steam/steamapps/common/wildwriter_demo/linux/wild_writer/wild_writer.x86_64

Mac '~/Library/Application\ Support/Godot/app_userdata/'
Windows: %APPDATA%\Godot\app_userdata\[project_name]

TODO LIST:
==========

0.0.3 :

    1. deleting large text
    2. DONE blip font need add size to avoid blur | use msdf
    3. DONE c-e shortcut
    4. DONE scoring system
    5. DONE speed run test system

* shuangpin
* more chaos vfxs

TODO
-----

- FIXED 当输入input的时候，应该清掉之前的ime_compose,有时会残留 (when reset ime, clear compose)
- FIXED 当使用gfcp的时候，如果是TinyIME，其在0 col时位置会上移半格，OS IME则正常 (not used gfcp)
- ?ime compose bonus使用glitch text. seems not good
- FIXED is delete (incr_error) duplicated?
- DONE line number gutter
- DONE on_text_changed: Ctrl+V should consider Command+V
- FIXED Option key in Key Capture (Option seems is Alt)
- DONE Big Boom for big delete
- DONE laser effect
- DONE animated text anim fix
- DONE rating final
- settings
- font vari
- effect vari
- toast

WISHLIST
========

1. record all actions,as replay.dat, and play it in editor
2. save version each pub, and if updated new version, show changelog on startup

# egg

make me mad
热手运动
狂打

fullscreen mode

mini pad mode -> borderless, minimal screen, c+enter to send to other application


---------

CHECKED TODO MAC

1. DONE preload all effect scenes: boom, bigboom, blip, dust, laser, newline
2. DONE boom char fly offset reduce bit
3. XXX xl font will miss the caret pos? hint redraw
4. DONE add interface hint to tell user redraw if linewrap now shown correctly
5. DONE audio option should also effect the rating final window
6. DONE combo not break if newline effect off
7. add text edit default placeholder
8. DONE when tiny ime showing candidate, prev/next page should not pop to key
9. XXX mac OS input at col 0 the input bar pos is not correct
10. DONE use OS lang is OS lang is en or zh, else use en

CHECKED TODO LINUX

1. DONE preload effects not loading particles, which will be slow
2. DONE increase blip font move distance, increase a bit (30)
3. DONE misc placeholder title name
4. DONE misc option desc

CHECKED TODO WINDOWS

1. DONE intial Windows is too big will make it looks like fullscreen
2. DONE internal fullwidth punc will produce multi chars
3. DONE change default ime toggle to a key that on all OS (Alt+Escape not work on windows)
4. FIXED the Ctrl+HJKL not working
5. FIXED combo finish effect not working
6. DONE padding line will make input errorness, so use pad size only
7. DONE add next_tip button

CHECKED TODO WEB

1. the Ctrl+HJKL should set as handled as it will input keys
2. add some text

-----------------

CHECKLIST TEST_OVERVIEW

1. open, new, save
2. autosave, open recent
3. document directory
4. file line number / lines / ....
5. fonts ...  (check the padding and redraw betweeing settings)
6. effects
7. speed mode, start, finish
7. shortcut
8. input method
   OS input method
9. debug?
10. language

DEBUG 
1. DONE MAC
2. DONE Linux
3. DONE Windows
4. DONE Web

ENCRYPTED

1. MAC
2. Linux
3. Windows
4. Web
5. Decrypt

PUBLISH VIDEO


