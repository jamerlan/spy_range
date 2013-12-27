function widget:GetInfo()
    return {
        name      = "Spy emp and decloack range v1",
        desc      = "Cloacks spy by default and draws a circle that displays spy decloack range (green) and spy emp range (blue)",
        author    = "[teh]decay aka [teh]undertaker",
        date      = "28 dec 2013",
        license   = "The BSD License",
        layer     = 0,
        version   = 1,
        enabled   = true  -- loaded by default
    }
end

-- project page on github: https://github.com/jamerlan/spy_range

--Changelog
-- v2 (for future)

local GetUnitPosition     = Spring.GetUnitPosition
local glDrawGroundCircle  = gl.DrawGroundCircle
local GetUnitDefID = Spring.GetUnitDefID
local lower                 = string.lower
local spGetAllUnits = Spring.GetAllUnits
local spGetSpectatingState = Spring.GetSpectatingState
local spGetMyPlayerID		= Spring.GetMyPlayerID
local spGetPlayerInfo		= Spring.GetPlayerInfo
local spGiveOrderToUnit = Spring.GiveOrderToUnit

local cmdCloack = CMD.CLOAK

local blastCircleDivs = 100
local weapNamTab		  = WeaponDefNames
local weapTab		      = WeaponDefs
local udefTab				= UnitDefs

local selfdTag = "selfDExplosion"
local aoeTag = "damageAreaOfEffect"

local coreSpy = UnitDefNames["corspy"]
local armSpy = UnitDefNames["armspy"]

local coreSpyId = coreSpy.id
local armSpyId = armSpy.id

local spies = {}

local spectatorMode = false
local notInSpecfullmode = false

function cloackSpy(unitID)
    spGiveOrderToUnit(unitID, cmdCloack, { 1 }, {})
end

function isSpy(unitDefID)
    if unitDefID == coreSpyId or armSpyId == unitDefID then
        return true
    end
    return false
end

function widget:UnitFinished(unitID, unitDefID, unitTeam)
    if isSpy(unitDefID) then
        spies[unitID] = true
        cloackSpy(unitID)
    end
end

function widget:UnitDestroyed(unitID, unitDefID, unitTeam)
    if spies[unitID] then
        spies[unitID] = nil
    end
end

function widget:UnitEnteredLos(unitID, unitTeam)
    if not spectatorMode then
        local unitDefID = GetUnitDefID(unitID)
        if isSpy(unitDefID) then
            spies[unitID] = true
        end
    end
end

function widget:UnitCreated(unitID, unitDefID, teamID, builderID)
    if isSpy(unitDefID) then
        spies[unitID] = true
        cloackSpy(unitID)
    end
end

function widget:UnitTaken(unitID, unitDefID, unitTeam, newTeam)
    if isSpy(unitDefID) then
        spies[unitID] = true
        cloackSpy(unitID)
    end
end


function widget:UnitGiven(unitID, unitDefID, unitTeam, oldTeam)
    if isSpy(unitDefID) then
        spies[unitID] = true
        cloackSpy(unitID)
    end
end

function widget:UnitLeftLos(unitID, unitDefID, unitTeam)
    if not spectatorMode then
        if spies[unitID] then
            spies[unitID] = nil
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

    gl.DepthTest(true)

    for unitID in pairs(spies) do
        local x,y,z = GetUnitPosition(unitID)
        local udefId = GetUnitDefID(unitID);
        if udefId ~= nil then
            local udef = udefTab[udefId]

            local selfdBlastId = weapNamTab[lower(udef[selfdTag])].id
            local selfdBlastRadius = weapTab[selfdBlastId][aoeTag]

            gl.Color(1, .6, .3, .8)
            glDrawGroundCircle(x, y, z, udef["decloakDistance"], blastCircleDivs)

            gl.Color(0, 0, 1, .5)
            glDrawGroundCircle(x, y, z, selfdBlastRadius, blastCircleDivs)

        end
    end
    gl.DepthTest(false)
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

    local visibleUnits = spGetAllUnits()
    if visibleUnits ~= nil then
        for _, unitID in ipairs(visibleUnits) do
            local udefId = GetUnitDefID(unitID)
            if udefId ~= nil then
                if isSpy(udefId) then
                    spies[unitID] = true
                end
            end
        end
    end
end
