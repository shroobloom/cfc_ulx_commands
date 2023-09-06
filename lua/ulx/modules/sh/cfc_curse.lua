CFCUlxCommands.curse = CFCUlxCommands.curse or {}
local cmd = CFCUlxCommands.curse

CATEGORY_NAME = "Fun"

CFCUlxCurse = CFCUlxCurse or {}

do -- Load curse effects
    AddCSLuaFile( "cfc_ulx_commands/curse/sh_utils.lua" )
    AddCSLuaFile( "cfc_ulx_commands/curse/cl_utils.lua" )

    include( "cfc_ulx_commands/curse/sh_utils.lua" )

    if SERVER then
        include( "cfc_ulx_commands/curse/sv_utils.lua" )
    else
        include( "cfc_ulx_commands/curse/cl_utils.lua" )
    end


    local effects_modules = file.Find( "cfc_ulx_commands/curse/effects/*.lua", "LUA" )

    for _, fileName in ipairs( effects_modules ) do
        AddCSLuaFile( "cfc_ulx_commands/curse/effects/" .. fileName )
        include( "cfc_ulx_commands/curse/effects/" .. fileName )
    end
end


function cmd.curse( ply, effectOverride, shouldUncurse )
    if shouldUncurse then
        CFCUlxCurse.StopCurseEffect( ply )
    else
        local effect = effectOverride or CFCUlxCurse.GetRandomOnetimeEffect()

        CFCUlxCurse.ApplyCurseEffect( ply, effect )
    end
end

function cmd.cursePlayers( callingPlayer, targetPlayers, effectName, shouldUncurse )
    local effectOverride

    if type( effectName ) == "string" and effectName ~= "random" then
        effectOverride = CFCUlxCurse.GetEffectByName( effectName )

        if not effectOverride then
            ULib.tsayError( callingPlayer, "Invalid curse effect name: " .. effectName )

            return
        end
    end

    for _, ply in ipairs( targetPlayers ) do
        cmd.curse( ply, effectOverride, shouldUncurse )
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
            ulx.fancyLogAdmin( callingPlayer, "#A lifted #T's brief curse", onetimeCursedPlayers )
        end

        if not table.IsEmpty( longCursedPlayers ) then
            ulx.fancyLogAdmin( callingPlayer, "#A delayed #T's next curse effect", longCursedPlayers )
        end
    else
        if effectOverride then -- Manually selected effect
            local combinedPlayers = {}
            table.Add( combinedPlayers, onetimeCursedPlayers )
            table.Add( combinedPlayers, longCursedPlayers )

            local effectPrettyName = effectOverride.nameUpper

            if not table.IsEmpty( combinedPlayers ) then
                ulx.fancyLogAdmin( callingPlayer, "#A briefly cursed #T with " .. effectPrettyName, combinedPlayers )
            end
        else -- Random effect
            if not table.IsEmpty( onetimeCursedPlayers ) then
                ulx.fancyLogAdmin( callingPlayer, "#A briefly cursed #T", onetimeCursedPlayers )
            end

            if not table.IsEmpty( longCursedPlayers ) then
                ulx.fancyLogAdmin( callingPlayer, "#A hastened #T's next curse effect", longCursedPlayers )
            end
        end
    end
end

local curseCommand = ulx.command( CATEGORY_NAME, "ulx curse", cmd.cursePlayers, "!curse" )
curseCommand:addParam{ type = ULib.cmds.PlayersArg }
curseCommand:addParam{ type = ULib.cmds.StringArg, default = "random", ULib.cmds.optional, completes = CFCUlxCurse.GetEffectNames() }
curseCommand:addParam{ type = ULib.cmds.BoolArg, invisible = true }
curseCommand:defaultAccess( ULib.ACCESS_ADMIN )
curseCommand:help( "Applies a one-time curse effect to target(s)" )
curseCommand:setOpposite( "ulx uncurse", { _, _, _, true }, "!uncurse" )
