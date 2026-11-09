---@type string, addonMods
local _, addonMods = ...

local unknownRealmPrinted = {}
local REGION_TEXT = {
    ['oce'] = 'Oceanic',
    ['usp'] = 'US Pacific',
    ['usm'] = 'US Mountain',
    ['usc'] = 'US Central',
    ['use'] = 'US East',
    ['mex'] = 'Mexico',
    ['bzl'] = 'Brazil'
}
local REGION_TEXT_META = {}
REGION_TEXT_META.__index = function(table, key) return 'Unknown' end
setmetatable(REGION_TEXT, REGION_TEXT_META)

local REGION_COLORED = {
    ['oce'] = '|cFF009900OCE|r',
    ['usp'] = '|cFF3399FFUSP|r',
    ['usm'] = '|cFF0066FFUSM|r',
    ['usc'] = '|cFFFF9900USC|r',
    ['use'] = '|cFFFF0000USE|r',
    ['mex'] = '|cFF006600M|r|cFFFFFFFFE|r|cFFCC3300X|r',
    ['bzl'] = '|cFF006600B|r|cFFFFFF00Z|r|cFF3333CCL|r'
}
local REGION_COLORED_META = {}
REGION_COLORED_META.__index = function() return '|cFFFFFFFF?|r ' end
setmetatable(REGION_COLORED, REGION_COLORED_META)

local REGION_REALMS = {
    ['oce'] = {
        'Aman\'Thul', 'Barthilas', 'Caelestrasz', 'Dath\'Remar', 'Dreadmaul',
        'Frostmourne', 'Gundrak', 'Jubei\'Thos', 'Khaz\'goroth', 'Nagrand',
        'Saurfang', 'Thaurissan'
    },
    ['usp'] = {
        'Aerie Peak', 'Anvilmar', 'Arathor', 'Antonidas', 'Azuremyst',
        'Baelgun', 'Blade\'s Edge', 'Bladefist', 'Bronzebeard', 'Cenarius',
        'Darrowmere', 'Draenor', 'Dragonblight', 'Echo Isles', 'Galakrond',
        'Gnomeregan', 'Hyjal', 'Kilrogg', 'Korialstrasz', 'Lightbringer',
        'Misha', 'Moonrunner', 'Nordrassil', 'Proudmoore', 'Shadowsong',
        'Shu\'Halo', 'Silvermoon', 'Skywall', 'Suramar', 'Uldum', 'Uther',
        'Velen', 'Windrunner', 'Blackrock', 'Blackwing Lair', 'Bonechewer',
        'Boulderfist', 'Coilfang', 'Crushridge', 'Daggerspine', 'Dark Iron',
        'Destromath', 'Dethecus', 'Dragonmaw', 'Dunemaul', 'Frostwolf',
        'Gorgonnash', 'Gurubashi', 'Kalecgos', 'Kil\'Jaeden', 'Lethon', 'Maiev',
        'Nazjatar', 'Ner\'zhul', 'Onyxia', 'Rivendare', 'Shattered Halls',
        'Spinebreaker', 'Spirestone', 'Stonemaul', 'Stormscale', 'Tichondrius',
        'Ursin', 'Vashj', 'Blackwater Raiders', 'Cenarion Circle',
        'Feathermoon', 'Sentinels', 'Silver Hand', 'The Scryers',
        'Wyrmrest Accord', 'The Venture Co'
    },
    ['usm'] = {
        'Azjol-Nerub', 'AzjolNerub', 'Doomhammer', 'Icecrown', 'Perenolde',
        'Terenas', 'Zangarmarsh', 'Kel\'Thuzad', 'Darkspear', 'Deathwing',
        'Bloodscalp', 'Nathrezim', 'Shadow Council'
    },
    ['usc'] = {
        'Aegwynn', 'Agamaggan', 'Aggramar', 'Akama', 'Alexstrasza', 'Alleria',
        'Archimonde', 'Azgalor', 'Azshara', 'Balnazzar', 'Blackhand',
        'Blood Furnace', 'Borean Tundra', 'Burning Legion', 'Cairne',
        'Cho\'gall', 'Chromaggus', 'Dawnbringer', 'Dentarg', 'Detheroc',
        'Drak\'tharon', 'Drak\'thul', 'Draka', 'Eitrigg', 'Emerald Dream',
        'Farstriders', 'Fizzcrank', 'Frostmane', 'Garithos', 'Garona',
        'Ghostlands', 'Greymane', 'Grizzly Hills', 'Gul\'dan', 'Hakkar',
        'Hellscream', 'Hydraxis', 'Illidan', 'Kael\'thas', 'Khaz Modan',
        'Kirin Tor', 'Korgath', 'Kul Tiras', 'Laughing Skull', 'Lightninghoof',
        'Madoran', 'Maelstrom', 'Mal\'Ganis', 'Malfurion', 'Malorne', 'Malygos',
        'Mok\'Nathal', 'Moon Guard', 'Mug\'thol', 'Muradin', 'Nesingwary',
        'Quel\'Dorei', 'Ravencrest', 'Rexxar', 'Runetotem', 'Sargeras',
        'Scarlet Crusade', 'Sen\'Jin', 'Sisters of Elune', 'Staghelm',
        'Stormreaver', 'Terokkar', 'The Underbog', 'Thorium Brotherhood',
        'Thunderhorn', 'Thunderlord', 'Twisting Nether', 'Vek\'nilash',
        'Whisperwind', 'Wildhammer', 'Winterhoof'
    },
    ['use'] = {
        'Altar of Storms', 'Alterac Mountains', 'Andorhal', 'Anetheron',
        'Anub\'arak', 'Area 52', 'Argent Dawn', 'Arthas', 'Arygos', 'Auchindoun',
        'Black Dragonflight', 'Bleeding Hollow', 'Bloodhoof', 'Burning Blade',
        'Dalaran', 'Dalvengyr', 'Demon Soul', 'Drenden', 'Durotan', 'Duskwood',
        'Earthen Ring', 'Eldre\'Thalas', 'Elune', 'Eonar', 'Eredar', 'Executus',
        'Exodar', 'Fenris', 'Firetree', 'Garrosh', 'Gilneas', 'Gorefiend',
        'Grizzly Hills', 'Haomarush', 'Jaedenar', 'Kargath', 'Khadgar',
        'Lightning\'s Blade', 'Llane', 'Lothar', 'Magtheridon', 'Mannoroth',
        'Medivh', 'Nazgrel', 'Norgannon', 'Ravenholdt', 'Scilla', 'Shadowmoon',
        'Shandris', 'Shattered Hand', 'Skullcrusher', 'Smolderthorn',
        'Steamwheedle Cartel', 'Stormrage', 'Tanaris', 'The Forgotten Coast',
        'Thrall', 'Tortheldrin', 'Trollbane', 'Turalyon', 'Uldaman',
        'Undermine', 'Warsong', 'Ysera', 'Ysondre', 'Zul\'jin', 'Zuluhed'
    },
    ['mex'] = {'Drakkari', 'Quel\'Thalas', 'Ragnaros'},
    ['bzl'] = {'Azralon', 'Gallywix', 'Goldrinn', 'Nemesis', 'Tol Barad'}
}

---@param realm string
local function printRealmNotFound(realm)
  if realm and not unknownRealmPrinted[realm] then
    print('LFG Regions: the realm ' .. realm .. ' could not be matched to a region.')
    unknownRealmPrinted[realm] = true
  end
end

---@param name string
local function getRegion(name)
  if not name then return end

  local leaderRealm = name:match('%-(.+)')
  if leaderRealm then
    leaderRealm = leaderRealm:lower():gsub(' ', '')
  else
    leaderRealm = GetRealmName():lower():gsub(' ', '')
  end
  for region, regionRealms in pairs(REGION_REALMS) do
    for _, realm in pairs(regionRealms) do
      if realm:lower():gsub(' ', '') == leaderRealm then return region end
    end
  end
  printRealmNotFound(leaderRealm)
end

---@param name string
---@return string?
local function getRegionText(name)
  return REGION_TEXT[getRegion(name)]
end

---@param name string
---@return string?
local function getRegionColored(name)
  return REGION_COLORED[getRegion(name)]
end

---@param self table<string, any>
local function onLFGListSearchEntryUpdate(self)
  local searchResultInfo = C_LFGList.GetSearchResultInfo(self.resultID)
  local region           = getRegionColored(searchResultInfo.leaderName)
  self.ActivityName:SetFormattedText('%s %s', region, self.ActivityName:GetText())
end

---@param member table<string, any>
---@param appID number
---@param memberIdx number
local function onLFGListApplicationViewerUpdateApplicantMember(member, appID, memberIdx)
  local name   = C_LFGList.GetApplicantMemberInfo(appID, memberIdx)
  local region = getRegionColored(name)
  member.Name:SetFormattedText('%s %s', region, member.Name:GetText())
end

-- Export functions and make them global for other addons like Premade Groups Filter
PremadeRegions = {}
PremadeRegions.GetRegion        = getRegion
PremadeRegions.GetRegionText    = getRegionText
PremadeRegions.GetRegionColored = getRegionColored

hooksecurefunc('LFGListSearchEntry_Update', onLFGListSearchEntryUpdate)
hooksecurefunc('LFGListApplicationViewer_UpdateApplicantMember', onLFGListApplicationViewerUpdateApplicantMember)