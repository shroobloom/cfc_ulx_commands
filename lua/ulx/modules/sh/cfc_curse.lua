CFCUlxCommands.curse = CFCUlxCommands.curse or {}
local cmd = CFCUlxCommands.curse

CATEGORY_NAME = "Fun"

do -- Load curse effects
    AddCSLuaFile( "cfc_ulx_commands/curse/sh_loader.lua" )
    include( "cfc_ulx_commands/curse/sh_loader.lua" )
end


function cmd.curse( ply, effectOverride, durationSeconds, shouldUncurse )
    if shouldUncurse then
        CFCUlxCurse.StopCurseEffect( ply )
    else
        local effect = effectOverride or CFCUlxCurse.GetRandomOnetimeEffect()

        CFCUlxCurse.ApplyCurseEffect( ply, effect, durationSeconds )
    end
end

function cmd.cursePlayers( callingPlayer, targetPlayers, effectName, durationMinutes, shouldUncurse, isSilent )
    local effectOverride
    isSilent = isSilent or false

    if type( effectName ) == "string" and effectName ~= "random" then
        effectOverride = CFCUlxCurse.GetEffectByName( effectName )

        if not effectOverride then
            ULib.tsayError( callingPlayer, "Invalid curse effect name: " .. effectName )

            return
        end
    end

    local durationSeconds = durationMinutes and durationMinutes * 60 or 0

    for _, ply in ipairs( targetPlayers ) do
        cmd.curse( ply, effectOverride, durationSeconds, shouldUncurse )
    end

    local onetimeCursedPlayers = {}
    local longCursedPlayers = {}

    for _, ply in ipairs( targetPlayers ) do
        if CFCUlxCurse.IsCursed( ply ) then
            table.insert( longCursedPlayers, ply )
        else
            table.insert( onetimeCursedPlayers, ply )
        end
    end

    if shouldUncurse then -- Uncurse
        if not table.IsEmpty( onetimeCursedPlayers ) then
            ulx.fancyLogAdmin( callingPlayer, isSilent, "#A lifted #T's brief curse", onetimeCursedPlayers )
        end

        if not table.IsEmpty( longCursedPlayers ) then
            ulx.fancyLogAdmin( callingPlayer, isSilent, "#A delayed #T's next curse effect", longCursedPlayers )
        end
    else
        local hasCustomDuration = durationSeconds > 0 and ( not effectOverride or not effectOverride.blockCustomDuration )
        local durationAppend = ""
        local briefly = " briefly"

        if hasCustomDuration then
            local durationStr = durationSeconds >= 60 and
                ULib.secondsToStringTime( durationSeconds ) or
                math.Round( durationSeconds ) .. " seconds"

            durationAppend = " for " .. durationStr
            briefly = ""
        end

        if effectOverride then -- Manually selected effect
            local combinedPlayers = {}
            table.Add( combinedPlayers, onetimeCursedPlayers )
            table.Add( combinedPlayers, longCursedPlayers )

            local effectPrettyName = effectOverride.nameUpper

            if not table.IsEmpty( combinedPlayers ) then
                ulx.fancyLogAdmin( callingPlayer, isSilent, "#A" .. briefly .. " cursed #T with " .. effectPrettyName .. durationAppend, combinedPlayers )
            end
        else -- Random effect
            if not table.IsEmpty( onetimeCursedPlayers ) then
                ulx.fancyLogAdmin( callingPlayer, isSilent, "#A" .. briefly .. " cursed #T" .. durationAppend, onetimeCursedPlayers )
            end

            if not table.IsEmpty( longCursedPlayers ) then
                ulx.fancyLogAdmin( callingPlayer, isSilent, "#A hastened #T's next curse effect", longCursedPlayers )
            end
        end
    end
end


local function silentCursePlayers( callingPlayer, targetPlayers, effectName, durationMinutes, shouldUncurse )
    cmd.cursePlayers( callingPlayer, targetPlayers, effectName, durationMinutes, shouldUncurse, true )
end


local curseCommand = ulx.command( CATEGORY_NAME, "ulx curse", cmd.cursePlayers, "!curse" )
curseCommand:addParam{ type = ULib.cmds.PlayersArg }
curseCommand:addParam{ type = ULib.cmds.StringArg, default = "random", ULib.cmds.optional, completes = CFCUlxCurse.GetEffectNames() }
curseCommand:addParam{ type = ULib.cmds.NumArg, min = 0, max = 24 * 60, default = 0, ULib.cmds.optional, ULib.cmds.allowTimeString, hint = "duration" }
curseCommand:addParam{ type = ULib.cmds.BoolArg, invisible = true }
curseCommand:defaultAccess( ULib.ACCESS_ADMIN )
curseCommand:help( "Applies a one-time curse effect to target(s)" )
curseCommand:setOpposite( "ulx uncurse", { _, _, _, _, true }, "!uncurse" )

local silentCurseCommand = ulx.command( CATEGORY_NAME, "ulx scurse", silentCursePlayers, "!scurse" )
silentCurseCommand:addParam{ type = ULib.cmds.PlayersArg }
silentCurseCommand:addParam{ type = ULib.cmds.StringArg, default = "random", ULib.cmds.optional, completes = CFCUlxCurse.GetEffectNames() }
silentCurseCommand:addParam{ type = ULib.cmds.NumArg, min = 0, max = 24 * 60, default = 0, ULib.cmds.optional, ULib.cmds.allowTimeString, hint = "duration" }
silentCurseCommand:addParam{ type = ULib.cmds.BoolArg, invisible = true }
silentCurseCommand:defaultAccess( ULib.ACCESS_ADMIN )
silentCurseCommand:help( "Silently applies a one-time curse effect to target(s)" )
silentCurseCommand:setOpposite( "ulx unscurse", { _, _, _, _, true }, "!unscurse" )