local addonName, IFX = ...

IFX.SpellEffects = {}
local SpellEffects = IFX.SpellEffects

SpellEffects.Profiles = {}

-- Registers a single spell profile
function SpellEffects:RegisterProfile(spellID, profile)
    self.Profiles[spellID] = profile
end

-- Registers multiple spell profiles in a batch table
function SpellEffects:RegisterProfiles(profiles)
    for spellID, profile in pairs(profiles) do
        self.Profiles[spellID] = profile
    end
end

function SpellEffects:GetProfile(spellID)
    return self.Profiles[spellID]
end