local _, addon = ...

-- Stable ports consumed by KeyUI. Client-specific code lives in Adapters/.
addon.ports = addon.ports or {}

local required_ports = {
    "actions",
    "addons",
    "events",
    "lifecycle",
    "settings",
    "spells",
    "timers",
    "ui",
}

function addon:InstallGameAdapter(adapter)
    assert(type(adapter) == "table", "KeyUI adapter must be a table")

    for _, port_name in ipairs(required_ports) do
        assert(type(adapter[port_name]) == "table", "KeyUI adapter is missing port: " .. port_name)
        self.ports[port_name] = adapter[port_name]
    end

    self.ports.adapter = adapter.id or "unknown"
end

