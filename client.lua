-- Récupération de la libraire ESX

ESX = nil

Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0)
	end
end)

function notification(msg)
    local mugshot, mugshotStr = ESX.Game.GetPedMugshot(PlayerPedId())
    ESX.ShowAdvancedNotification('title', 'subject', 'msg', mugshotStr, 1)
    UnregisterPedheadshot(mugshot)
end

-- Recevoir la notification de lancement d'un event

local isEventAvaible = false

RegisterNetEvent("esx_autoevents:notify")
AddEventHandler("esx_autoevents:notify", function(display) -- On récupère la sous-table "display"
    eventTerminatedBySelf = false
    isEventAvaible = true
    PlaySoundFrontend(-1, "Boss_Message_Orange", "GTAO_Boss_Goons_FM_Soundset", 0)
    ESX.ShowAdvancedNotification('Événement journalier', "~y~"..display.title, "~b~Description: ~s~"..display.description, "CHAR_CHAT_CALL", 1)
end)

--[[

    Events

]]

local eventEntities = {}
local eventBlips = {}
local eventWay = nil
local eventTerminatedBySelf = false

RegisterNetEvent("esx_autoevents:stopEvent")
AddEventHandler("esx_autoevents:stopEvent", function(fromsrv)
    if not isEventAvaible then return end
    isEventAvaible = false
    for k, v in pairs(eventBlips) do
        if v ~= nil then RemoveBlip(v) end
    end
    for k, v in pairs(eventEntities) do
        if v ~= nil then DeleteEntity(v) end
    end
    if eventWay ~= nil then RemoveBlip(eventWay) end
    if fromsrv then ESX.ShowAdvancedNotification('Événement journalier', "~r~Événement terminé", "Si tu n'as pas eu le temps de venir, c'est ton problème, à la prochaine !", "CHAR_CHAT_CALL", 1) end 
end)

-- Event "assassin"

RegisterNetEvent("esx_autoevents:startevent_assassin")
AddEventHandler("esx_autoevents:startevent_assassin", function(args, reward)
    local possibleTargetsPosition = args.targetPossibleLocations
    local selectedTargetCoords = possibleTargetsPosition[math.random(1,#possibleTargetsPosition)]

    local way = AddBlipForCoord(selectedTargetCoords)
    SetBlipColour(way, 75)
    SetBlipRoute(way, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName('Cible à neutraliser')
    EndTextCommandSetBlipName(way)
    eventWay = way

    local closeToPed = false
    while not closeToPed and isEventAvaible do
        Wait(100)
        local position = GetEntityCoords(PlayerPedId())
        if GetDistanceBetweenCoords(position, selectedTargetCoords, true) <= 100.0 then
            closeToPed = true
        end
    end

    if not isEventAvaible then -- On détecte si l'event est toujours actif après la boucle et si il est à l'orogine de son arrêt
        return
    end

    local pedHash = GetHashKey("a_f_m_tramp_01")
    RequestModel(pedHash)
    while not HasModelLoaded(pedHash) do Wait(1) print("LOADING MODEL") end 

    local weaponHash = GetHashKey("weapon_snspistol")

    local ped = CreatePed(9, pedHash, selectedTargetCoords, 90.0, false, false)
    SetEntityAsMissionEntity(ped, 1, 1)
    GiveWeaponToPed(ped, weaponHash, 9000, false, true)
    closeToPed = false
    while not closeToPed and isEventAvaible do
        Wait(100)
        local position = GetEntityCoords(PlayerPedId())
        if GetDistanceBetweenCoords(position, selectedTargetCoords, true) <= 60.0 then
            if way ~= nil then RemoveBlip(way) end
            if ped ~= nil then TaskCombatPed(ped, PlayerPedId(), 0, 0) end

            local pedBlip = AddBlipForEntity(ped)
            SetBlipAsShortRange(pedBlip, false)
            SetBlipColour(pedBlip, 75)
            SetBlipSprite(pedBlip, 119)

            table.insert(eventBlips, pedBlip)

            SetPedKeepTask(ped, true)
            closeToPed = true
        end
    end

    if not isEventAvaible then -- On détecte si l'event est toujours actif après la boucle et si il est à l'orogine de son arrêt
        return
    end
    
    while ped ~= nil and GetEntityHealth(ped) > 0 and isEventAvaible do
        Wait(50)
    end

    if not isEventAvaible then -- On détecte si l'event est toujours actif après la boucle et si il est à l'orogine de son arrêt
        return
    end

    PlaySoundFrontend(-1, "BASE_JUMP_PASSED", "HUD_AWARDS", 1)
    ESX.ShowAdvancedNotification('Événement journalier', "~g~Rapport d'événement", "Vous avez complété votre tâche, félicitations ! Vous empochez un total de ~g~"..reward.."$ ~s~!", "CHAR_CHAT_CALL", 1)
    TriggerServerEvent("esx_autoevents:reward")
    TriggerEvent("esx_autoevents:stopEvent")
end)