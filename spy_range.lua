function widget:GetInfo()
    return {
        name      = "Spy emp and decloack range v3",
        desc      = "Cloacks spy by default and draws a circle that displays spy(and gremlin) decloack range (orange) and spy emp range (blue)",
        author    = "[teh]decay aka [teh]undertaker",
        date      = "28 dec 2013",
        license   = "The BSD License",
        layer     = 0,
        version   = 3,
        enabled   = true  -- loaded by default
    }
end

-- project page on github: https://github.com/jamerlan/spy_range

--Changelog
-- v2 [teh]decay Don't draw circles when GUI is hidden
-- v3 [teh]decay Added gremlin decloack range + set them on hold fire and hold pos

local GetUnitPosition     = Spring.GetUnitPosition
local glColor = gl.Color
local glDepthTest = gl.DepthTest
local glDrawGroundCircle  = gl.DrawGroundCircle
local GetUnitDefID = Spring.GetUnitDefID
local lower                 = string.lower
local spGetAllUnits = Spring.GetAllUnits
local spGetSpectatingState = Spring.GetSpectatingState
local spGetMyPlayerID		= Spring.GetMyPlayerID
local spGetPlayerInfo		= Spring.GetPlayerInfo
local spGiveOrderToUnit = Spring.GiveOrderToUnit
local spIsGUIHidden = Spring.IsGUIHidden

local CMD_MOVE_STATE    = CMD.MOVE_STATE
local cmdCloack = CMD.CLOAK
local cmdFireState = CMD.FIRE_STATE

local blastCircleDivs = 100
local weapNamTab		  = WeaponDefNames
local weapTab		      = WeaponDefs
local udefTab				= UnitDefs

local selfdTag = "selfDExplosion"
local aoeTag = "damageAreaOfEffect"

local coreSpy = UnitDefNames["corspy"]
local armSpy = UnitDefNames["armspy"]
local armGremlin = UnitDefNames["armst"]

local coreSpyId = coreSpy.id
local armSpyId = armSpy.id
local armGremlinId = armGremlin.id

local spies = {}
local gremlins = {}

local spectatorMode = false
local notInSpecfullmode = false

function cloackSpy(unitID)
    spGiveOrderToUnit(unitID, cmdCloack, { 1 }, {})
end

function processGremlin(unitID)
    spGiveOrderToUnit(unitID, cmdCloack, { 1 }, {})
    spGiveOrderToUnit(unitID, CMD_MOVE_STATE, { 0 }, {}) -- 0 == hold pos
    spGiveOrderToUnit(unitID, cmdFireState, { 0 }, {}) -- hold fire
end

function isSpy(unitDefID)
    if unitDefID == coreSpyId or armSpyId == unitDefID then
        return true
    end
    return false
end

function isGremlin(unitDefID)
    if unitDefID == armGremlinId then
        return true
    end
    return false
end

function widget:UnitFinished(unitID, unitDefID, unitTeam)
    if isSpy(unitDefID) then
        spies[unitID] = true
        cloackSpy(unitID)
    end

    if isGremlin(unitDefID) then
        gremlins[unitID] = true
        processGremlin(unitID)
    end
end

function widget:UnitDestroyed(unitID, unitDefID, unitTeam)
    if spies[unitID] then
        spies[unitID] = nil
    end

    if gremlins[unitID] then
        gremlins[unitID] = nil
    end
end

function widget:UnitEnteredLos(unitID, unitTeam)
    if not spectatorMode then
        local unitDefID = GetUnitDefID(unitID)
        if isSpy(unitDefID) then
            spies[unitID] = true
        end

        if isGremlin(unitDefID) then
            gremlins[unitID] = true
        end
    end
end

function widget:UnitCreated(unitID, unitDefID, teamID, builderID)
    if isSpy(unitDefID) then
        spies[unitID] = true
        cloackSpy(unitID)
    end

    if isGremlin(unitDefID) then
        gremlins[unitID] = true
        processGremlin(unitID)
    end
end

function widget:UnitTaken(unitID, unitDefID, unitTeam, newTeam)
    if isSpy(unitDefID) then
        spies[unitID] = true
        cloackSpy(unitID)
    end

    if isGremlin(unitDefID) then
        gremlins[unitID] = true
        processGremlin(unitID)
    end
end


function widget:UnitGiven(unitID, unitDefID, unitTeam, oldTeam)
    if isSpy(unitDefID) then
        spies[unitID] = true
        cloackSpy(unitID)
    end

    if isGremlin(unitDefID) then
        gremlins[unitID] = true
        processGremlin(unitID)
    end
end

function widget:UnitLeftLos(unitID, unitDefID, unitTeam)
    if not spectatorMode then
        if spies[unitID] then
            spies[unitID] = nil
        end

        if gremlins[unitID] then
            gremlins[unitID] = nil
        end
    end
end

function widget:DrawWorldPreUnit()
    local _, specFullView, _ = spGetSpectatingState()

    if not specFullView then
        notInSpecfullmode = true
    else
        if notInSpecfullmode then
            detectSpectatorView()
        end
        notInSpecfullmode = false
    end

    if spIsGUIHidden() then return end

    glDepthTest(true)

    for unitID in pairs(spies) do
        local x,y,z = GetUnitPosition(unitID)
        local udefId = GetUnitDefID(unitID);
        if udefId ~= nil then
            local udef = udefTab[udefId]

            local selfdBlastId = weapNamTab[lower(udef[selfdTag])].id
            local selfdBlastRadius = weapTab[selfdBlastId][aoeTag]

            glColor(1, .6, .3, .8)
            glDrawGroundCircle(x, y, z, udef["decloakDistance"], blastCircleDivs)

            glColor(0, 0, 1, .5)
            glDrawGroundCircle(x, y, z, selfdBlastRadius, blastCircleDivs)

        end
    end

    for unitID in pairs(gremlins) do
        local x,y,z = GetUnitPosition(unitID)
        local udefId = GetUnitDefID(unitID);
        if udefId ~= nil then
            local udef = udefTab[udefId]

            local selfdBlastId = weapNamTab[lower(udef[selfdTag])].id
            local selfdBlastRadius = weapTab[selfdBlastId][aoeTag]

            glColor(1, .6, .3, .8)
            glDrawGroundCircle(x, y, z, udef["decloakDistance"], blastCircleDivs)
        end
    end

    glDepthTest(false)
end

function widget:PlayerChanged(playerID)
    detectSpectatorView()
    return true
end

function widget:Initialize()
    detectSpectatorView()
    return true
end

function detectSpectatorView()
    local _, _, spec, teamId = spGetPlayerInfo(spGetMyPlayerID())

    if spec then
        spectatorMode = true
    end

    spies = {}
    gremlins = {}

    local visibleUnits = spGetAllUnits()
    if visibleUnits ~= nil then
        for _, unitID in ipairs(visibleUnits) do
            local udefId = GetUnitDefID(unitID)
            if udefId ~= nil then
                if isSpy(udefId) then
                    spies[unitID] = true
                end

                if isGremlin(unitDefID) then
                    gremlins[unitID] = true
                end
            end
        end
    end
end
