-- This work is licensed under a Creative Commons Attribution-NonCommercial 4.0 International License.
-- https://creativecommons.org/licenses/by-nc/4.0/

_addon.author = 'ababyduck';
_addon.name = 'ticklish';
_addon.version = '0.1';

require 'common'

----------------------------------------------------------------------------------------------------
-- Variables
----------------------------------------------------------------------------------------------------
local playerIsResting = false
local currentTick = 0

----------------------------------------------------------------------------------------------------
-- Configurations
----------------------------------------------------------------------------------------------------
local default_config = 
{
    font =
    {
        family      = 'Arial',
        size        = 14,
        color       = 0xFFFFFFFF,
        position    = { -155, -210 },
    },
    show_ticks   = false
};
local ticklish_config = default_config;

----------------------------------------------------------------------------------------------------
-- func: msg
-- desc: Prints out a message with the Nomad tag at the front.
----------------------------------------------------------------------------------------------------
local function msg(s)
    local txt = '\31\200[\31\05' .. _addon.name .. '\31\200]\31\130 ' .. s;
    print(txt);
end

----------------------------------------------------------------------------------------------------
-- func: load
-- desc: Event called when the addon is being loaded.
----------------------------------------------------------------------------------------------------
ashita.register_event('load', function()
    -- Load the configuration file..
    --ticklish_config = ashita.settings.load_merged(_addon.path .. '/settings/settings.json', ticklish_config);

    -- Create the font object..
    local f = AshitaCore:GetFontManager():Create('__ticklish_addon');
    f:SetColor(ticklish_config.font.color);
    f:SetFontFamily(ticklish_config.font.family);
    f:SetFontHeight(ticklish_config.font.size);
    f:SetBold(true);
    f:SetPositionX(ticklish_config.font.position[1]);
    f:SetPositionY(ticklish_config.font.position[2]);
    f:SetText('R');
    f:SetVisibility(true);
end);

----------------------------------------------------------------------------------------------------
-- func: unload
-- desc: Event called when the addon is being unloaded.
----------------------------------------------------------------------------------------------------
ashita.register_event('unload', function()
    -- Get the font object..
    local f = AshitaCore:GetFontManager():Get('__ticklish_addon');

    -- Update the configuration position..
    ticklish_config.font.position = { f:GetPositionX(), f:GetPositionY() };

    -- Save the configuration file..
    ashita.settings.save(_addon.path .. '/settings/settings.json', ticklish_config);

    -- Delete the font object..
    AshitaCore:GetFontManager():Delete('__ticklish_addon');
end);

---------------------------------------------------------------------------------------------------
-- func: incoming_packet
-- desc: Called when our addon receives an incoming packet.
---------------------------------------------------------------------------------------------------
ashita.register_event('incoming_packet', function(id, size, data)
    -- Listen for char update packet and read the player status
    if (id == 0x037) then
        local packet = data:totable()
        local playerStatus = packet[0x31];

        -- for k, v in pairs(packet) do
        --     print(k .. ': ' .. v);
        -- end

        if (playerStatus == 33) then
            playerIsResting = true;
        else
            playerIsResting = false;
        end

    end

    return false;
end);

----------------------------------------------------------------------------------------------------
-- func: render
-- desc: Event called when the addon is being rendered.
----------------------------------------------------------------------------------------------------
ashita.register_event('render', function()
    -- Get the font object..
    local f = AshitaCore:GetFontManager():Get('__ticklish_addon');
    if (f == nil) then return; end

    -- If we're resting, start the timer
    if (playerIsResting) then
        -- TODO: Start the timer
        f:SetText('20');
    else
        -- TODO: Stop the timer
        f:SetText('');
    end

end);
