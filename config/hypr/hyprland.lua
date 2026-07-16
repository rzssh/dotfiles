local mainMod     = "SUPER"
local terminal    = "ghostty"
local fileManager = "dolphin"

hl.monitor({ output = "", mode = "1920x1080@360", position = "auto", scale = "auto" })

hl.env("__GL_MaxFramesAllowed", "1")
hl.env("__GL_GSYNC_ALLOWED", "0")
hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("NVD_BACKEND", "direct")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
hl.env("XCURSOR_THEME", "Bibata-Modern-Ice")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_THEME", "Bibata-Modern-Ice")
hl.env("HYPRCURSOR_SIZE", "24")


hl.on("hyprland.start", function()
    hl.exec_cmd("dbus-update-activation-environment --systemd --all")
end)

local function matugenBorders()
    local f = io.open(os.getenv("HOME") .. "/.cache/matugen/colors.json")
    if not f then return nil end
    local json = f:read("*all")
    f:close()
    local active = json:match('"cursor":%s*"#(%x+)"')
    local inactive = json:match('"color8":%s*"#(%x+)"')
    if active and inactive then
        return { active = "rgb(" .. active .. ")", inactive = "rgb(" .. inactive .. ")" }
    end
end

local borders = matugenBorders() or { active = "rgba(33ccffee)", inactive = "rgba(595959aa)" }

hl.device({ name = "nordic-2.4g-wireless-receiver-mouse", sensitivity = -0.5 })

hl.config({
    cursor = {
        no_hardware_cursors = false,
        no_warps = true,
        zoom_detached_camera = false,
    },
    general = {
        gaps_in  = 8,
        gaps_out = 15,
        border_size = 2,
        col = {
            active_border = borders.active,
            inactive_border = borders.inactive,
        },
        resize_on_border = true,
        allow_tearing = false,
        layout = "dwindle",
    },
    input = {
        kb_layout  = "us,ru,ua",
        kb_options = "grp:win_space_toggle",
        repeat_rate  = 40,
        repeat_delay = 300,
        follow_mouse = 1,
        float_switch_override_focus = 0,
        sensitivity  = 0,
        touchpad = { natural_scroll = false },
    },
    decoration = {
        rounding = 10,
        active_opacity   = 1.0,
        inactive_opacity = 0.9,
        shadow = { enabled = true, range = 4, render_power = 3, color = 0xee1a1a1a },
        blur   = { enabled = true, size = 3, passes = 1, vibrancy = 0.1696 },
    },
    dwindle = {
        preserve_split = true,
        force_split = 2,
    },
    master = {
        new_status = "master",
    },
    scrolling = {
        fullscreen_on_one_column = true,
    },
    misc = {
        render_unfocused_fps = 5,
        disable_hyprland_logo = false,
        focus_on_activate = true,
        mouse_move_focuses_monitor = true,
    },
    animations = {
        enabled = true,
    },
})

hl.curve("easeOutQuint", { type = "bezier", points = { {0.23, 1}, {0.32, 1} } })
hl.curve("linear",       { type = "bezier", points = { {0, 0}, {1, 1} } })

hl.animation({ leaf = "windows",    enabled = true,  speed = 4,   bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsIn",  enabled = true,  speed = 4,   bezier = "easeOutQuint", style = "popin 87%" })
hl.animation({ leaf = "windowsOut", enabled = true,  speed = 1.5, bezier = "linear",       style = "popin 87%" })
hl.animation({ leaf = "fade",       enabled = true,  speed = 3,   bezier = "easeOutQuint" })
hl.animation({ leaf = "border",     enabled = true,  speed = 5,   bezier = "easeOutQuint" })
hl.animation({ leaf = "workspaces", enabled = false })

hl.layer_rule({ name = "dms-blur", match = { namespace = "^dms:.*$" }, blur = true, ignore_alpha = 0 })

hl.window_rule({ match = { class = "^(org.kde.dolphin|org.kde.ark)$" }, float = true, size = "(monitor_w*0.5) (monitor_h*0.6)" })
hl.window_rule({ match = { class = "^qimgv$" }, float = true, size = "(monitor_w*0.6) (monitor_h*0.8)" })
hl.window_rule({ match = { class = "^vlc$" }, float = true, size = "(monitor_w*0.5) (monitor_h*0.6)" })
hl.window_rule({ match = { class = "^org.pulseaudio.pavucontrol$" }, float = true, center = true, size = "(monitor_w*0.5) (monitor_h*0.4)" })
hl.window_rule({ match = { class = "^1password$" }, float = true, center = true, size = "(monitor_w*0.4) (monitor_h*0.5)" })
hl.window_rule({ match = { class = "^com.mitchellh.ghostty$", title = "^(btop|htop)$" }, float = true, center = true, size = "(monitor_w*0.7) (monitor_h*0.8)" })
hl.window_rule({ match = { class = "^com.mitchellh.ghostty$", title = "^nmtui$" }, float = true, center = true, size = "(monitor_w*0.7) (monitor_h*0.8)" })
hl.window_rule({ match = { class = "^ghostty.nvim$" }, float = true, center = true, size = "(monitor_w*0.7) (monitor_h*0.8)" })
hl.window_rule({ match = { class = "^org.qbittorrent.qBittorrent$" }, float = true, size = "(monitor_w*0.7) (monitor_h*0.8)" })
hl.window_rule({ match = { class = "^nm-connection-editor$" }, float = true })
hl.window_rule({ match = { class = "^xdg-desktop-portal.*" }, float = true, size = "68% 65%" })
hl.window_rule({ match = { class = "^zen$" }, render_unfocused = true })
hl.window_rule({ match = { class = "^com.mitchellh.ghostty$" }, no_blur = true })

hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + C", hl.dsp.window.close())
hl.bind(mainMod .. " + P", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + K", hl.dsp.exec_cmd("1password"))
hl.bind(mainMod .. " + CTRL + SHIFT + Q", hl.dsp.exec_cmd("systemctl poweroff"))

hl.bind(mainMod .. " + R",       hl.dsp.exec_cmd("dms ipc call spotlight toggle"))
hl.bind(mainMod .. " + N",       hl.dsp.exec_cmd("dms ipc call notifications toggle"))
hl.bind(mainMod .. " + V",       hl.dsp.exec_cmd("dms ipc call clipboard toggle"))
hl.bind(mainMod .. " + comma",   hl.dsp.exec_cmd("dms ipc call settings toggle"))
hl.bind(mainMod .. " + M",       hl.dsp.exec_cmd("dms ipc call processlist toggle"))
hl.bind(mainMod .. " + ALT + L", hl.dsp.exec_cmd("dms ipc call lock lock"))
hl.bind(mainMod .. " + X",       hl.dsp.exec_cmd("dms ipc call powermenu toggle"))

hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))

hl.bind(mainMod .. " + SHIFT + left",  hl.dsp.window.swap({ direction = "l" }))
hl.bind(mainMod .. " + SHIFT + down",  hl.dsp.window.swap({ direction = "d" }))
hl.bind(mainMod .. " + SHIFT + up",    hl.dsp.window.swap({ direction = "u" }))
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.swap({ direction = "r" }))

hl.bind(mainMod .. " + CTRL + left",  hl.dsp.window.resize({ x = -20, y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + down",  hl.dsp.window.resize({ x = 0, y = 20, relative = true }),  { repeating = true })
hl.bind(mainMod .. " + CTRL + up",    hl.dsp.window.resize({ x = 0, y = -20, relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + right", hl.dsp.window.resize({ x = 20, y = 0, relative = true }),  { repeating = true })

hl.bind(mainMod .. " + CTRL + ALT + up",   hl.dsp.group.prev())
hl.bind(mainMod .. " + CTRL + ALT + down", hl.dsp.group.next())

hl.bind(mainMod .. " + SHIFT + C", hl.dsp.window.center())
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.window.fullscreen({ mode = 0 }))
hl.bind(mainMod .. " + F",         hl.dsp.window.fullscreen({ mode = 1 }))
hl.bind(mainMod .. " + T", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + Y", hl.dsp.layout("togglesplit"))
hl.bind(mainMod .. " + CTRL + G", hl.dsp.group.toggle())

local hintBase = "wl-kbptr -o mode_floating.source=detect"
local function hintAction(command)
    return function()
        hl.dispatch(hl.dsp.submap("reset"))
        hl.dispatch(hl.dsp.exec_cmd(command))
    end
end

hl.bind(mainMod .. " + G", hl.dsp.submap("pointer"), { description = "Pointer hints" })
hl.define_submap("pointer", function()
    hl.bind("C", hintAction(hintBase .. " -o modes=floating,click"))
    hl.bind("2", hintAction(hintBase .. " -o modes=floating,click -o click_count=2"))
    hl.bind("3", hintAction(hintBase .. " -o modes=floating,click -o click_count=3"))
    hl.bind("R", hintAction(hintBase .. " -o modes=floating,click -o mode_click.button=right"))
    hl.bind("M", hintAction(hintBase .. " -o modes=floating,click -o mode_click.button=middle"))
    hl.bind("H", hintAction(hintBase .. " -o modes=floating"))
    hl.bind("G", hintAction(hintBase .. " -o modes=floating,click --drag"))
    hl.bind("P", hintAction("wl-kbptr -o modes=tile,bisect,click"))
    hl.bind("escape", hl.dsp.submap("reset"))
    hl.bind("catchall", hl.dsp.submap("reset"))
end)

hl.bind(mainMod .. " + ALT + SHIFT + M", hl.dsp.exec_cmd([[fish -c "wallpaper toggle"]]))
hl.bind(mainMod .. " + ALT + SHIFT + R", hl.dsp.exec_cmd([[fish -c "wallpaper random"]]))
hl.bind(mainMod .. " + ALT + SHIFT + P", hl.dsp.exec_cmd([[fish -c "wallpaper undo"]]))
hl.bind(mainMod .. " + ALT + SHIFT + bracketleft",  hl.dsp.exec_cmd([[fish -c "wallpaper prev"]]))
hl.bind(mainMod .. " + ALT + SHIFT + bracketright", hl.dsp.exec_cmd([[fish -c "wallpaper next"]]))
hl.bind(mainMod .. " + ALT + SHIFT + W", hl.dsp.exec_cmd([[fish -c "wallpaper toggle-nsfw"]]))
hl.bind(mainMod .. " + ALT + SHIFT + T", hl.dsp.exec_cmd([[fish -c "wallpaper toggle-restricted"]]))
hl.bind(mainMod .. " + ALT + SHIFT + E", hl.dsp.exec_cmd([[fish -c "wallpaper toggle-explicit"]]))
hl.bind(mainMod .. " + ALT + SHIFT + D", hl.dsp.exec_cmd([[fish -c "wallpaper toggle-default"]]))
hl.bind(mainMod .. " + ALT + SHIFT + I", hl.dsp.exec_cmd([[fish -c "wallpaper show"]]))
hl.bind(mainMod .. " + ALT + SHIFT + C", hl.dsp.exec_cmd([[fish -c "wallpaper reload"]]))


hl.bind(mainMod .. " + ALT + 1", function() hl.config({ general = { layout = "dwindle" } }) end)
hl.bind(mainMod .. " + ALT + 2", function() hl.config({ general = { layout = "master" } }) end)
hl.bind(mainMod .. " + ALT + 3", function() hl.config({ general = { layout = "scrolling" } }) end)

hl.bind(mainMod .. " + tab", hl.dsp.focus({ workspace = "previous" }))
hl.bind(mainMod .. " + O",   hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mainMod .. " + U",   hl.dsp.focus({ workspace = "e+1" }))

for i = 1, 9 do
    hl.bind(mainMod .. " + " .. i,         hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = i }))
end

hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

hl.bind(mainMod .. " + mouse_right", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_left",  hl.dsp.focus({ workspace = "e-1" }))

hl.bind(mainMod .. " + mouse:275", hl.dsp.exec_cmd("ydotool click 0xC4"))

hl.bind(mainMod .. " + SHIFT + Q", hl.dsp.exec_cmd([[sh -c 'kill $(hyprctl activewindow -j | jq .pid)']]))

hl.bind(mainMod .. " + Z", function() hl.config({ cursor = { zoom_factor = 4 } }) end)
hl.bind("Z", function()
    local z = hl.get_config("cursor.zoom_factor")
    if z and z ~= 1 then hl.config({ cursor = { zoom_factor = 1 } }) end
end, { release = true, ignore_mods = true, non_consuming = true, transparent = true })

hl.bind(mainMod .. " + ALT + S", hl.dsp.exec_cmd("hyprwhspr record toggle"))

hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd("dms screenshot region"))
hl.bind(mainMod .. " + SHIFT + P", hl.dsp.exec_cmd("dms screenshot full"))
hl.bind(mainMod .. " + SHIFT + A", hl.dsp.exec_cmd([[sh -c 'dms screenshot region --stdout --no-file --no-clipboard | satty -f - --copy-command wl-copy']]))
hl.bind(mainMod .. " + SHIFT + X", hl.dsp.exec_cmd("~/.config/hypr/scripts/color-picker.sh"))
hl.bind(mainMod .. " + CTRL + F10", hl.dsp.exec_cmd("~/.config/hypr/scripts/toggle_opacity.sh"))

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true })
