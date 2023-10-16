--[[
    - Utilities and main setup for CFC ULX curse.
    - Some brief terminology:
        - A player is 'cursed' if they have an active ulx timedcurse punishment.
        - A 'curse effect' is an effect that periodically occurs while cursed.
        - ulx curse can be used to apply a one-time effect to a player.
            - The player receives a curse effect, but they are not considered 'cursed'.
                - As such, they will not automatically receive a new effect after the first one.
            - These one-time effects often last longer than normal effects.
--]]

CFCUlxCurse = CFCUlxCurse or {}
CFCUlxCurse.EffectGlobals = CFCUlxCurse.EffectGlobals or {} -- Effects can store global vars here, preferably in a subtable indexed by the effect's lowercase name.
CFCUlxCurse.Effects = {}

local effectNameToID = {}
local onetimeEffectIDs = {}


--[[
    - Registers a curse effect.

    effectData should be a table with the following fields:
        name: (string)
            - The name of the effect. Must be unique, and is case-insensitive.
            - The name must not be "random" as it is reserved for manual selection via ulx.
        onStart: (function)
            - Function to call when the effect starts.
            - Has the form   function( ply )  end
        onEnd: (function)
            - Function to call when the effect ends.
            - Has the form   function( ply )  end
        minDuration: (optional) (number)
            - The minimum duration of the effect in seconds.
            - If not specified, defaults to CFCUlxCurse.EFFECT_DURATION_MIN.
        maxDuration: (optional) (number)
            - The maximum duration of the effect in seconds.
            - If not specified, defaults to CFCUlxCurse.EFFECT_DURATION_MAX.
        onetimeDurationMult: (optional)
            - Duration multiplier for if this effect is applied as a one-time effect.
            - If not specified, defaults to CFCUlxCurse.EFFECT_DURATION_ONETIME_MULT.
        excludeFromOnetime: (optional) (boolean)
            - If true, this effect will be excluded from the one-time effect draw pool (i.e. ulx curse command)
                - They can still be called manually with CFCUlxCurse.ApplyCurseEffect().
            - If not specified, defaults to false.
        blockCustomDuration: (optional) (boolean)
            - If true, the duration of this effect cannot be manually overridden by the ulx curse command.
            - If not specified, defaults to false.
--]]
function CFCUlxCurse.RegisterEffect( effectData )
    local nameUpper = effectData.name
    if not nameUpper then return ErrorNoHaltWithStack( "Effect must have a name" ) end

    local name = string.lower( nameUpper )
    if name == "random" then return ErrorNoHaltWithStack( "Effect name cannot be \"random\"" ) end
    if effectNameToID[name] then return ErrorNoHaltWithStack( "Already registered an effect with the name \"" .. nameUpper .. "\"" ) end

    local id = table.insert( CFCUlxCurse.Effects, effectData )

    effectNameToID[name] = id
    effectData.nameUpper = nameUpper

    if effectData.excludeFromOnetime ~= true then
        table.insert( onetimeEffectIDs, id )
    end
end

function CFCUlxCurse.GetEffectByName( name )
    return CFCUlxCurse.Effects[effectNameToID[string.lower( name )]]
end

function CFCUlxCurse.GetEffectNames()
    local names = {}

    for _, effect in ipairs( CFCUlxCurse.Effects ) do
        table.insert( names, effect.nameUpper )
    end

    return names
end

--[[
    - Get a random curse effect.
    - This is the draw pool used by the ulx timedcurse command.
--]]
function CFCUlxCurse.GetRandomEffect()
    local id = math.random( #CFCUlxCurse.Effects )

    return CFCUlxCurse.Effects[id]
end

--[[
    - Get a random one-time curse effect.
    - This is the draw pool used by the ulx curse command.
--]]
function CFCUlxCurse.GetRandomOnetimeEffect()
    local id = onetimeEffectIDs[math.random( #onetimeEffectIDs )]

    return CFCUlxCurse.Effects[id]
end

function CFCUlxCurse.GetCurrentEffect( ply )
    return ply.CFCUlxCurseEffect
end

function CFCUlxCurse.GetCurrentEffectName( ply )
    local effect = CFCUlxCurse.GetCurrentEffect( ply )

    return effect and effect.name
end