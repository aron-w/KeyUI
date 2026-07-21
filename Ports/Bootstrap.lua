local _, addon = ...

local version = addon.VERSION or {}
local adapter
if version.isWotLK335 then
    adapter = addon.adapters and addon.adapters.wotlk_ascension
else
    adapter = addon.adapters and addon.adapters.modern
end

addon:InstallGameAdapter(assert(adapter, "KeyUI could not select a game adapter"))

