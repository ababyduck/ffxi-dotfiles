-- This work is licensed under a Creative Commons Attribution-NonCommercial 4.0 International License.
-- https://creativecommons.org/licenses/by-nc/4.0/

_addon.author = 'Zuri';
_addon.name = 'ticklish';
_addon.version = '0.1';

require 'common'

----------------------------------------------------------------------------------------------------
-- Config
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
    show_ticks        = false,
    show_hp_recovered = false,
    show_mp_recovered = false,
    debug             = false
};
local ticklish_config = default_config;

----------------------------------------------------------------------------------------------------
-- func: load
-- desc: Event called when the addon is being loaded.
----------------------------------------------------------------------------------------------------
ashita.register_event('load', function()
    -- Set up initial vars
    playerIsResting = false;
    currentTick = 0;
    currentDelay = 20;
    restPacket = 
    {
        call     = false,
        response = false
    }
    restTimer = 
    {
        last      = {},
        delta     = {},
        deltaText = ''
    };

    -- Load the configuration file..
    ticklish_config = ashita.settings.load_merged(_addon.path .. '/settings/settings.json', ticklish_config);

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

----------------------------------------------------------------------------------------------------
-- func: msg
-- desc: Prints out a message with the Nomad tag at the front.
----------------------------------------------------------------------------------------------------
local function msg(s)
    local timestamp = os.date(string.format('\31\%c[%s]\30\01 ', 200, '%H:%M:%S'));
    local txt = timestamp .. '\31\200[\31\05' .. _addon.name .. '\31\200]\31\130 ' .. s;
    print(txt);
end

----------------------------------------------------------------------------------------------------
-- func: command
-- desc: Event called when a command was entered.
----------------------------------------------------------------------------------------------------
ashita.register_event('command', function(command, ntype)
    -- Get the arguments of the command..
    local args = command:args();
    if (args[1] ~= '/ticklish') then
        return false;
    end

    -- Toggle debug mode
    if (args[2] == 'debug') then
        ticklish_config.debug = not ticklish_config.debug;
        if ticklish_config.debug == false then
            msg('Debug output disabled')
        else
            msg('Debug output enabled')
        end
        return true;
    end

end);

---------------------------------------------------------------------------------------------------
-- func: outgoing_packet
-- desc: Called when our addon receives an outgoing packet.
---------------------------------------------------------------------------------------------------
ashita.register_event('outgoing_packet', function(id, size, data)
    -- Listen for heal toggle packet
    if (id == 0x0E8) then
        restPacket.call = true;
        if (ticklish_config.debug) then msg('DEBUG: Detected outgoing heal toggle packet [0x0E8]') end;
    end

    return false;
end);

---------------------------------------------------------------------------------------------------
-- func: incoming_packet
-- desc: Called when our addon receives an incoming packet.
---------------------------------------------------------------------------------------------------
ashita.register_event('incoming_packet', function(id, size, data)
    -- Listen for character update packet and read the address that contains player status
    if (id == 0x037) then
        if (ticklish_config.debug) then msg('DEBUG: Detected incoming character update packet [0x037]') end;
        local packet = data:totable()
        local playerStatus = packet[0x31];

        -- If the server tells us we're resting, we're resting.
        playerIsResting = (playerStatus == 33);

        if (playerIsResting) then

            -- Keep track of how many ticks we've rested
            currentTick = currentTick + 1;

            if (ticklish_config.debug) then
                msg('DEBUG: currentTick is ' .. currentTick);
            end

            -- Set time since last resting update to now
            restTimer.last = os.time();
        else
            -- When we're no longer resting, reset tick counter to 0
            currentTick = 0;
        end

        -- Uncomment to show full packet data
        -- for k, v in pairs(packet) do
        --     print(k .. ': ' .. v);
        -- end

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

    if (playerIsResting) then
        -- Update the time since our last resting tick
        restTimer.delta = (os.time() - restTimer.last);
        restTimer.deltaText = os.date('%S', restTimer.delta)

        -- Determine delay in seconds for the current resting tick
        if currentTick > 1 then
            currentDelay = 10;
        elseif currentTick == 1 then
            currentDelay = 20;
        end

        -- And finally, update the text
        restTimer.deltaText = tostring(currentDelay - restTimer.deltaText);

        f:SetText(restTimer.deltaText);
    else
        -- If we're not resting, blank out the timer
        f:SetText('');
    end

end);
