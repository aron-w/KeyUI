local _, addon = ...

-- Optional external-addon port. Keeping OneRingLib access here prevents the
-- context-menu code from depending on OPie's private tables or proxy frames.
local opie = {}

local function get_library()
    local library = _G.OneRingLib
    if type(library) == "table"
        and type(library.GetNumRings) == "function"
        and type(library.GetRingInfo) == "function"
        and type(library.SetRingBinding) == "function" then
        return library
    end
end

function opie:IsAvailable()
    return get_library() ~= nil
end

function opie:VisitRings(visitor)
    local library = get_library()
    if not library then return false end

    local ok, count = pcall(library.GetNumRings, library)
    if not ok or type(count) ~= "number" then return false end

    for index = 1, count do
        local info_ok, name, key, slices, ring_id, macro, internal = pcall(library.GetRingInfo, library, index)
        if info_ok and key and not internal then
            visitor(index, name or key, slices or 0)
        end
    end
    return true
end

function opie:BindRing(index, key)
    local library = get_library()
    if not library then return false, "OPie is not available." end
    if InCombatLockdown and InCombatLockdown() then
        return false, "OPie ring bindings cannot be changed during combat."
    end
    if type(index) ~= "number" or type(key) ~= "string" or key == "" then
        return false, "Invalid OPie ring binding."
    end

    local ok, err = pcall(library.SetRingBinding, library, index, key)
    if not ok then return false, tostring(err) end
    return true
end

function opie:GetIcon()
    return "Interface\\AddOns\\OPie\\gfx\\icon.tga"
end

addon.ports.opie = opie
