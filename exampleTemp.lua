package.path = FileMgr.GetMenuRootPath() .. "\\Lua\\?.lua;"
local script_name = "exampleTemp.lua"
local update_url = "https://raw.githubusercontent.com/ares-lp/test/main/exampleTemp.lua"  -- URL dove si trova la nuova versione dello script
local lock_file = "exampleTemp.lock"

-- Funzione per scaricare un file utilizzando Curl
function download_file(url, dest)
    print("primissima")
    local curl = Curl.Easy()
    --local file = io.open(FileMgr.GetMenuRootPath() .. "/" .. "Lua/" .. dest, "wb")

    --if not file then
    --    error("Impossibile aprire il file per la scrittura: " .. "/" .. "Lua/" .. dest)
    --end

    -- Imposta l'URL da cui scaricare il file
    curl:Setopt(eCurlOption.CURLOPT_URL, url)

    -- Imposta la funzione di scrittura personalizzata per Curl
    

    -- Esegui l'operazione di download
    print("path prima prima ")
    curl:Perform()
    print("path prima")
    while not curl:GetFinished() do
        Script.Yield(1)
    end
    print("path dopo")
    -- Verifica se il download è stato completato con successo
    local success, response = curl:GetResponse()
    if success == eCurlCode.CURLE_OK then
        print("path dopo ancora")
        
        local path = FileMgr.GetMenuRootPath() .. "/" .. "Lua/" .. "exampleTemp.lua" 
        --print("path ciao: ".. path)
        FileMgr.WriteFileContent(path, response)
        
    end
    --file:close()

    -- Restituisci true se il download è stato completato con successo
    
end

-- Funzione per verificare se c'è un nuovo aggiornamento
function check_for_updates()
    -- Se il file di lock esiste, un aggiornamento è già in corso
    local file = io.open(FileMgr.GetMenuRootPath() .. "/" .. "Lua/" .. lock_file, "r")
    if file then
        file:close()
        print("Aggiornamento già in corso da un'altra istanza. Attendere...")
        return false
    end

    -- Creare un file di lock per indicare che l'aggiornamento è in corso
    file = io.open(FileMgr.GetMenuRootPath() .. "/" .. "Lua/" .. lock_file, "w")
    file:write("Aggiornamento in corso")
    file:close()

    -- Scarica la nuova versione in un file temporaneo
    local temp_file = "temp_" .. script_name
    Script.QueueJob(function ()
        download_file(update_url, temp_file)
    end)
    print("dopo queue")
    if 1 then
        local path = FileMgr.GetMenuRootPath() .. "/" .. "Lua/" .. "exampleTemp2.lua" 
      
        -- Sostituisce il file attuale con il nuovo
        --os.remove(FileMgr.GetMenuRootPath() .. "/" .. "Lua/" .. script_name)
        --FileMgr.WriteFileContent(path, response)
        --os.rename(FileMgr.GetMenuRootPath() .. "/" .. "Lua/" .. temp_file, FileMgr.GetMenuRootPath() .. "/" .. "Lua/" .. script_name)
        
        print("Aggiornamento completato. Riavvio...")
        
        -- Rimuove il file di lock
        os.remove(FileMgr.GetMenuRootPath() .. "/" .. "Lua/" .. lock_file)

        -- Riavvia lo script aggiornato
        --os.execute("lua " .. script_name)
        --os.exit()
    else
        print("Nessun aggiornamento disponibile o errore nel download.")
        
        -- Rimuove il file di lock in caso di errore
        os.remove(lock_file)
    end
end

-- Avvio dell'auto-updater
check_for_updates()

-- Codice principale del tuo script qui
print("Esecuzione del codice principale...")



-- Aggiungi qui il resto del codice del tuo script
require("natives/natives")

local MAXN_PLAYERS = 32
local INVALID_PLAYER_INDEX = -1

local playerExplodeLoopTimer = {} ---@type integer[]
for playerId = 0, MAXN_PLAYERS - 1 do
    playerExplodeLoopTimer[playerId] = Time.GetEpocheMs()
end

---@param playerId integer
---@param time integer
---@return boolean
local function hasPlayerExplodeLoopTimerElapsedWithReset(playerId, time)
    if playerExplodeLoopTimer[playerId] > Utils.GetTimeEpocheMs() - time then
        return false
    end

    playerExplodeLoopTimer[playerId] = Utils.GetTimeEpocheMs()
    return true
end

---@param playerId integer
local function explodePlayer(playerId)
    local pedHnd = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(playerId)

    if ENTITY.DOES_ENTITY_EXIST(pedHnd) then
        local coords = ENTITY.GET_ENTITY_COORDS(pedHnd, true)
        FIRE.ADD_EXPLOSION(coords.x, coords.y, coords.z, 4, 1.0, true, false, 1.0, false)
    end
end

FeatureMgr.AddPlayerFeature(Utils.Joaat("LUA_BlockSEs"), "Block Incoming SEs", eFeatureType.Toggle)

local features = FeatureMgr.AddPlayerFeature(Utils.Joaat("LUA_ExplodeLoop"), "Explode Loop", eFeatureType.SliderIntToggle, "Use slider to set explosions delay",
    function(f)
        local playerId = f:GetPlayerIndex()
        local delay = f:GetIntValue()

        if f:IsToggled() and
            hasPlayerExplodeLoopTimerElapsedWithReset(playerId, delay)
        then
            explodePlayer(playerId)
        end
    end)

for _, hash in ipairs(features) do
    FeatureMgr.GetFeature(hash)
        :RegisterCallbackTrigger(eCallbackTrigger.OnTick)
        :SetNoCallbackOnPress(true)
        :SetDefaultValue(100)
        :SetLimitValues(100, 1000)
        :SetSaveable(false)
        :Reset()
end

FeatureMgr.AddFeature(Utils.Joaat("LUA_CrashAll"), "Crash All", eFeatureType.Button, "Removes all players from the lobby",
    function(f)
        for playerId = 0, MAXN_PLAYERS - 1 do
            if playerId ~= Utils.GetLocalPlayerId() then
                FeatureMgr.TriggerFeatureCallback(Utils.Joaat("CrashPlayer"), playerId)
            end
        end
    end)

FeatureMgr.AddFeature(Utils.Joaat("LUA_Button"), "Button", eFeatureType.Button)

FeatureMgr.AddFeature(Utils.Joaat("LUA_Toggle"), "Toggle", eFeatureType.Toggle)
    :SetDefaultValue(true)
    :Reset()

FeatureMgr.AddFeature(Utils.Joaat("LUA_SliderInt"), "SliderInt", eFeatureType.SliderInt)
    :SetLimitValues(0, 10)

FeatureMgr.AddFeature(Utils.Joaat("LUA_SliderFloat"), "SliderFloat", eFeatureType.SliderFloat)
    :SetLimitValues(-1.0, 1.0)

FeatureMgr.AddFeature(Utils.Joaat("LUA_SliderIntToggle"), "SliderIntToggle", eFeatureType.SliderIntToggle)
    :SetLimitValues(0, 10)

FeatureMgr.AddFeature(Utils.Joaat("LUA_SliderFloatToggle"), "SliderFloatToggle", eFeatureType.SliderFloatToggle)
    :SetLimitValues(-1.0, 1.0)

FeatureMgr.AddFeature(Utils.Joaat("LUA_InputInt"), "InputInt", eFeatureType.InputInt)
    :SetLimitValues(0, 10)
    :SetStepSize(1)
    :SetFastStepSize(10)

FeatureMgr.AddFeature(Utils.Joaat("LUA_InputFloat"), "InputFloat", eFeatureType.InputFloat)
    :SetLimitValues(-1.0, 1.0)
    :SetStepSize(0.1)
    :SetFastStepSize(10.0)

FeatureMgr.AddFeature(Utils.Joaat("LUA_InputText"), "InputText", eFeatureType.InputText)
    :SetStringValue("InputText")

FeatureMgr.AddFeature(Utils.Joaat("LUA_InputColor3"), "InputColor3", eFeatureType.InputColor3)
    :SetDefaultValue(0xFFCCAA)
    :Reset()

FeatureMgr.AddFeature(Utils.Joaat("LUA_InputColor4"), "InputColor4", eFeatureType.InputColor4)
    :SetDefaultValue(0xFFFFCCAA)
    :Reset()

FeatureMgr.AddFeature(Utils.Joaat("LUA_List"), "List", eFeatureType.List)
    :SetList({"Eins", "Zwei", "Drei"})

FeatureMgr.AddFeature(Utils.Joaat("LUA_ListWithInfo"), "ListWithInfo", eFeatureType.ListWithInfo)
    :SetList({"Eins", "Zwei", "Drei"})
    :AddInfoContentFeature(Utils.Joaat("LUA_Button"))

FeatureMgr.AddFeature(Utils.Joaat("LUA_Combo"), "Combo", eFeatureType.Combo)
    :SetList({"Eins", "Zwei", "Drei"})

FeatureMgr.AddFeature(Utils.Joaat("LUA_ComboToggles"), "ComboToggles", eFeatureType.ComboToggles)
    :SetList({"Eins", "Zwei", "Drei"})
    :ToggleListIndex(0, true)

---@param sender? CNetGamePlayer
---@param args integer[]
---@return boolean # return true to block
local function scriptedGameEvent(sender, args)
    if sender then
        local eventId = args[1]

        if FeatureMgr.IsFeatureEnabled(Utils.Joaat("LUA_BlockSEs"), sender.PlayerId) then
            Logger.LogInfo(("Blocked EventId: %i from %s"):format(eventId, sender:GetName()))
            return true
        end
    end

    return false
end

local function onPresent()
    local flags = ImGuiWindowFlags.AlwaysAutoResize
        | ImGuiWindowFlags.NoCollapse
        | ImGuiWindowFlags.NoDecoration

    if GUI.IsOpen() then
        ImGui.Begin("Window", true, flags)

        ImGui.BeginGroup()
        ImGui.Text("Some text")
        ImGui.Text(("FPS %0.1f"):format(ImGui.GetFrameRate()))
        ImGui.EndGroup()

        ImGui.SameLine()

        ImGui.BeginGroup()
        ClickGUI.RenderFeature(Utils.Joaat("LUA_Button"))
        ClickGUI.RenderFeature(Utils.Joaat("LUA_Toggle"))
        ImGui.EndGroup()

        ImGui.End()
    end
end

---@param playerId integer
local function onPlayerJoin(playerId)
    if playerId ~= INVALID_PLAYER_INDEX then
        local name = PLAYER.GET_PLAYER_NAME(playerId)
        GUI.AddToast("onPlayerJoin", ("Player %s joined"):format(name), 3000)
    end
end

local function childWindowCrashes()
    if ClickGUI.BeginCustomChildWindow("Crashes") then
        ClickGUI.RenderFeature(Utils.Joaat("LUA_CrashAll"))

        ClickGUI.EndCustomChildWindow()
    end
end

local function childWindow()
    if ClickGUI.BeginCustomChildWindow("Window") then
        ClickGUI.RenderFeature(Utils.Joaat("LUA_Button"))
        ClickGUI.RenderFeature(Utils.Joaat("LUA_Toggle"))
        ClickGUI.RenderFeature(Utils.Joaat("LUA_SliderInt"))
        ClickGUI.RenderFeature(Utils.Joaat("LUA_SliderFloat"))
        ClickGUI.RenderFeature(Utils.Joaat("LUA_SliderIntToggle"))
        ClickGUI.RenderFeature(Utils.Joaat("LUA_SliderFloatToggle"))
        ClickGUI.RenderFeature(Utils.Joaat("LUA_InputInt"))
        ClickGUI.RenderFeature(Utils.Joaat("LUA_InputFloat"))
        ClickGUI.RenderFeature(Utils.Joaat("LUA_InputText"))
        ClickGUI.RenderFeature(Utils.Joaat("LUA_InputColor3"))
        ClickGUI.RenderFeature(Utils.Joaat("LUA_InputColor4"))
        ClickGUI.RenderFeature(Utils.Joaat("LUA_Combo"))
        ClickGUI.RenderFeature(Utils.Joaat("LUA_ComboToggles"))

        ClickGUI.EndCustomChildWindow()
    end

    if ClickGUI.BeginCustomChildWindow("List") then
        ClickGUI.RenderFeature(Utils.Joaat("LUA_List"))

        ClickGUI.EndCustomChildWindow()
    end

    if ClickGUI.BeginCustomChildWindow("ListWithInfo") then
        ClickGUI.RenderFeature(Utils.Joaat("LUA_ListWithInfo"))

        ClickGUI.EndCustomChildWindow()
    end
end

local function renderTab()
    local NUM_COLUMNS = 2
    local flags = ImGuiTableFlags.SizingStretchSame
    if ImGui.BeginTable("My Lua Tab Table", NUM_COLUMNS, flags) then
        ImGui.TableNextRow()

        for column = 0, NUM_COLUMNS - 1 do
            ImGui.TableSetColumnIndex(column)

            if column == 0 then
                childWindowCrashes()
            end

            if column == 1 then
                childWindow()
            end
        end

        ImGui.EndTable()
    end
end

local function childWindowBlockStuff()
    local playerId = Utils.GetSelectedPlayer()

    if ClickGUI.BeginCustomChildWindow("Block Stuff") then
        ClickGUI.RenderFeature(Utils.Joaat("LUA_BlockSEs"), playerId)

        ClickGUI.EndCustomChildWindow()
    end
end

local function childWindowGriefing()
    local playerId = Utils.GetSelectedPlayer()

    if ClickGUI.BeginCustomChildWindow("Griefing") then
        ClickGUI.RenderFeature(Utils.Joaat("LUA_ExplodeLoop"), playerId)

        ClickGUI.EndCustomChildWindow()
    end
end

local function renderPlayerTab()
    local NUM_COLUMNS = 2
    local flags = ImGuiTableFlags.SizingStretchSame
    if ImGui.BeginTable("My Player Lua Tab Table", NUM_COLUMNS, flags) then
        ImGui.TableNextRow()

        for column = 0, NUM_COLUMNS - 1 do
            ImGui.TableSetColumnIndex(column)

            if column == 0 then
                childWindowBlockStuff()
            end

            if column == 1 then
                childWindowGriefing()
            end
        end

        ImGui.EndTable()
    end
end

EventMgr.RegisterHandler(eLuaEvent.SCRIPTED_GAME_EVENT, scriptedGameEvent)
EventMgr.RegisterHandler(eLuaEvent.ON_PRESENT, onPresent)
EventMgr.RegisterHandler(eLuaEvent.ON_PLAYER_JOIN, onPlayerJoin)

ClickGUI.AddTab("Tab", renderTab)
ClickGUI.AddPlayerTab("PlayerTab", renderPlayerTab)
