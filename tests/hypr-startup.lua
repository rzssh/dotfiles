local events, launches, rules = {}, {}, {}
local noop = setmetatable({}, {
    __index = function(self) return self end,
    __call = function() end,
})
hl = setmetatable({
    on = function(name, callback) events[name] = callback end,
    exec_cmd = function(command, effects) launches[#launches + 1] = { command, effects } end,
    window_rule = function(rule) rules[#rules + 1] = rule end,
    define_submap = function(_, callback) callback() end,
}, { __index = function() return noop end })
assert(loadfile("config/hypr/hyprland.lua"))()
assert(#launches == 0, "Config reload must not launch applications")
events["hyprland.start"]()
assert(#launches == 7, "Login must launch six apps and import the environment")
assert(launches[2][1] == "wezterm" and launches[2][2].workspace == "1 silent")
local expected = { "org.telegram.desktop", "vesktop", "zen-beta", "youtube-music-webapp", "mailspring" }
for i, app in ipairs(expected) do assert(launches[i + 2][1] == "gtk-launch " .. app) end
local destinations = {}
for _, rule in ipairs(rules) do
    if rule.workspace then
        destinations[rule.match.class] = rule.workspace
        if rule.workspace == "2 silent" then assert(rule.group == "set lock invade") end
    end
end
assert(destinations["^org\\.telegram\\.desktop$"] == "2 silent")
assert(destinations["^(vesktop|discord)$"] == "2 silent")
assert(destinations["^zen$"] == "3 silent")
assert(destinations["^youtube-music$"] == "4 silent")
assert(destinations["^Mailspring$"] == "5 silent")
assert(not destinations["^org.wezfurlong.wezterm$"], "New terminals must stay on the current workspace")
print("Hyprland startup checks passed")
