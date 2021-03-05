--[[

    Espace config

--]]

local time_per_event = 8 -- En minutes
local wait_before_next_event = 30 -- En minutes
local wait_before_first_event = 10 -- En secondes

local activePlayers = {}

local selectedEvent = nil

local events = {
    --[[

        Pour les "reward", trois types possibles :
        • black
        • cash
        • bank

    ]]

    {
        name = "assassin",
        reward = {ammount = 1000},
        display = {
            title = "Assassine les cibles",
            description = "Assessine toutes les cibles marquées dans le temps imparti"
        },
        args = {
            targetPossibleLocations = {
                vector3(523.05, 6663.55, 10.31)
            }
        }
    }
}

--[[

    Espace code

]]

-- Récupération de la libraire ESX

ESX = nil

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

-- Création et définition d'un timer qui se répetera indéfininiment

Citizen.CreateThread(function()
    Wait(1000*wait_before_first_event) -- On attends X secondes avant de démarrer le premier event sur le serveur
    while true do -- Lancement de la boucle infinie

        local onlinePlayers = ESX.GetPlayers() -- On récupère la liste des joueurs actifs 
        for k, v in pairs(onlinePlayers) do -- On lance une boucle sur les joueurs connecté"s
            activePlayers[v] = v -- On ajoute l'id des joueurs dans une table activePlayers
        end

        selectedEvent = math.random(1,#events) -- On sélectionne un event aléatoire entre 1 et le nombre de possibilités de la table "events"

        local eventInfos = events[selectedEvent] -- On initialise une variable "eventInfos" avec les données de l'event sélectionné
        local trigger = "esx_autoevents:startevent_"..eventInfos.name -- On défini le trigger approprié à l'event pour le déclencher chez le joueur
        TriggerClientEvent("esx_autoevents:notify", -1, eventInfos.display) -- On envoie une notification au joueur avec les informations "display"
        TriggerClientEvent(trigger, -1, eventInfos.args, eventInfos.reward.ammount) -- On démarre l'évent en question chez le joueur
        print("^2[AUTOEVENTS] ^7Starting event ^3"..eventInfos.name.."^7")

        Citizen.Wait(1000*60*time_per_event) -- On attends avant de stopper l'event

        TriggerClientEvent("esx_autoevents:stopEvent", true)
        print("^2[AUTOEVENTS] ^7Stopping event ^3"..eventInfos.name.."^7")
        activePlayres = {}
        selectedEvent = nil

        Citizen.Wait(1000*60*wait_before_next_event) -- On attends X minutes pour le prochain event

    end
end)

-- Système de récompense

RegisterNetEvent("esx_autoevents:reward")
AddEventHandler("esx_autoevents:reward", function()
    local _src = source
    if not selectedEvent or not activePlayers[_src] then
        DropPlayer(_src, "Expulsé pour avoir tenté de vous récompenser au travers du système des auto_events")
        return 
    end
    activePlayers[_src] = nil
    local xPlayer = ESX.GetPlayerFromId(_src)
    local reward = events[selectedEvent].reward
    local ammount = reward.ammount
    xPlayer.addMoney(reward.ammount)
    print("^2[AUTOEVENTS] ^7Player "..GetPlayerName(_src).." was rewarded by ^2"..reward.ammount.."$^7")
end) 