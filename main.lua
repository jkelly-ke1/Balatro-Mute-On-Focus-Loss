local mod = SMODS.current_mod

mod.config = mod.config or {}

if mod.config.mute_on_focus_loss == nil then
    mod.config.mute_on_focus_loss = true
end

local original_update = love.update
local original_settings_tab = G.UIDEF.settings_tab

local muted = false
local saved_volume = nil


local function get_sound_settings()
    if not G or not G.SETTINGS then
        return nil
    end

    return G.SETTINGS.SOUND
end


local function restore_volume()
    if not muted then
        return
    end

    local sound = get_sound_settings()

    if sound and saved_volume ~= nil then
        -- avoid volume overwriting when changed externally
        if sound.volume == 0 then
            sound.volume = saved_volume
        end
    end

    muted = false
    saved_volume = nil
end

local function update_mute()
    local sound = get_sound_settings()

    if not sound then
        return
    end

    if not mod.config.mute_on_focus_loss then
        restore_volume()
        return
    end

    local focused = love.window.hasFocus()

    if not focused then
        if not muted then
            saved_volume = sound.volume

            if saved_volume ~= 0 then
                sound.volume = 0
                muted = true
            end
        end
    else
        restore_volume()
    end
end


function love.update(dt)
    if original_update then
        original_update(dt)
    end

    update_mute()
end

-- settings toggle
if original_settings_tab then
    G.UIDEF.settings_tab = function(tab)
        local result = original_settings_tab(tab)

        if tab ~= "Audio" then
            return result
        end

        if not result or not result.nodes then
            return result
        end

        table.insert(result.nodes, {
            n = G.UIT.R,
            config = {
                align = "cm",
                padding = 0.05
            },
            nodes = {
                create_toggle({
                    label = localize("mofl_toggle"),
                    ref_table = mod.config,
                    ref_value = "mute_on_focus_loss",

                    callback = function()
                        if not mod.config.mute_on_focus_loss then
                            restore_volume()
                        end

                        if SMODS.save_mod_config then
                            SMODS.save_mod_config(mod)
                        end
                    end
                })
            }
        })

        return result
    end
end