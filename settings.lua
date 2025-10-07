defaultSettingsRaw = love.filesystem.read("defaults/settings.json");
defaultSettings = json.decode(defaultSettingsRaw);
SETTINGS = deepcopy(defaultSettings);