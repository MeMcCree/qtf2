::CONST <- getconsttable()
::ROOT <- getroottable()
if (!("ConstantNamingConvention" in ROOT)) {
    foreach (enum_table in Constants) {
        foreach (name, value in enum_table) {
            if (value == null)
                value = 0

            CONST[name] <- value
            ROOT[name] <- value
        }
    }
}

foreach (name, method in ::NetProps.getclass())
    if (name != "IsValid")
        getroottable()[name] <- method.bindenv(::NetProps)

DoIncludeScript("qtf2/nades.nut", ROOT);
DoIncludeScript("qtf2/weapons.nut", ROOT);
DoIncludeScript("qtf2/player.nut", ROOT);

::grenade_maker <- GrenadeMaker();

::gamerules <- Entities.FindByClassname(null, "tf_gamerules");
gamerules.ValidateScriptScope();

PrecacheSound("weapons/airstrike_small_explosion_01.wav");
PrecacheSound("weapons/cow_mangler_explosion_normal_05.wav");

::SetData <- function(name, value) {
    local data = gamerules.GetScriptScope();
    data[name] <- value;
}

::GetData <- function(name) {
    local data = gamerules.GetScriptScope();
    if (name in data)
        return data[name];
    else
        return null;
}

const BLUE = 3;
const RED = 2;

::MaxPlayers <- MaxClients().tointeger()

//---- Stats Varibles ----
const STAT_LENGTH = 0;

::playerTable <- {}

::GetPlayersInTeam <- function (team) {
    local numb = 0;
    for (local i = 1; i <= MaxPlayers; i++) {
        local player = PlayerInstanceFromIndex(i);
        if (player == null || player.IsPlayer() == false)
            continue;

        if (player.GetTeam() == team)
            numb++;
    }
    return numb++;
}

::SetStat <- function(playerIndex, stat, val) {
    if (!(playerIndex in playerTable)) {
        playerTable[playerIndex] <- {};
        for (local i = 0; i < STAT_LENGTH; i++)
            playerTable[playerIndex][i] <- 0;
    }

    playerTable[playerIndex][stat] = val;
}

::IncStat <- function(playerIndex, stat, by=1) {
    if (!(playerIndex in playerTable)) {
        playerTable[playerIndex] <- {};
        for (local i = 0; i < STAT_LENGTH; i++)
            playerTable[playerIndex][i] <- 0;
    }

    playerTable[playerIndex][stat] += by;
}

::GetStat <- function (playerIndex, stat) {
    if (!(playerIndex in playerTable)) {
        playerTable[playerIndex] <- {};
        for (local i = 0; i < STAT_LENGTH; i++)
            playerTable[playerIndex][i] <- 0;
    }

    return playerTable[playerIndex][stat];
}

::QTF2_HandleGrenadeInput <- function(self) {
    local buttons = GetPropInt(self, "m_nButtons");
    
    if (self.GetScriptScope().waitingToStopInput) {
        if (!(buttons & IN_GRENADE1)) {
            self.GetScriptScope().waitingToStopInput = false;
        }
        return;
    }

    if (self.GetScriptScope().isHoldingNade && self.GetScriptScope().heldNadeDetonationTime < Time()) {
        printl("Selfdet");
        self.GetScriptScope().isHoldingNade = false;
        self.GetScriptScope().waitingToStopInput = true;

        local eyepos = self.EyePosition();
        local idx = grenade_maker.SpawnNade(self.GetScriptScope().heldNadeType, eyepos, Vector(), self);
        grenade_maker.grenades[idx].detonation_time = Time() + 0.1;
        return;
    }

    if (buttons & IN_GRENADE1) {
        if (!self.GetScriptScope().isHoldingNade) {
            if (self.GetScriptScope().nades[0].amount <= 0) return;
            self.GetScriptScope().nades[0].amount--;
            printl("Cooked " + self.GetScriptScope().nades[0].amount + " left");
            self.GetScriptScope().waitingToStopInput = true;
            self.GetScriptScope().isHoldingNade = true;
            self.GetScriptScope().heldNadeType = self.GetScriptScope().nades[0].type;
            self.GetScriptScope().heldNadeDetonationTime <- Time() + NormalGrenade.time_to_detonate;
        } else {
            printl("Thrown");
            self.GetScriptScope().isHoldingNade = false;
            self.GetScriptScope().waitingToStopInput = true;

            local eyepos = self.EyePosition();
            local eyedir = self.EyeAngles().Forward();

            local idx = grenade_maker.SpawnNade(self.GetScriptScope().heldNadeType, eyepos + eyedir * 32, eyedir * 600, self);
            grenade_maker.grenades[idx].detonation_time = self.GetScriptScope().heldNadeDetonationTime;
        }
    }
}

::AutoBhop <- function() {
    local vel = self.GetAbsVelocity();
    local buttons = NetProps.GetPropInt(self, "m_nButtons");

    local flags = self.GetFlags();
    //they were just grounded, do a vanilla jump
    if (lastonground) {
        lastonground = flags & Constants.FPlayer.FL_ONGROUND;
        return;
    }
    lastonground = flags & FL_ONGROUND;
    //they just landed, do a bhop
    if ((flags & FL_ONGROUND) && (buttons & IN_JUMP)) {
        //800 refers to gravity, if you care about being 1:1 with vanilla and differing gravities go ahead and change it
        vel.z = 289 - ((800 * FrameTime()) / 2);
        self.SetAbsVelocity(vel);
    }
}

::QTF2_PlayerThink <- function() {
    QTF2_HandleGrenadeInput(self);
    AutoBhop();
    return -1;
}

::FilterDeletedNades <- function(key, val) {
    return !val.deleted;
}

::QTF2_Think <- function() {
    grenade_maker.grenades = grenade_maker.grenades.filter(FilterDeletedNades);
    foreach (id, grenade in grenade_maker.grenades) {
        grenade.Think();
    }

    return -1;
}

local EventsID = UniqueString()
getroottable()[EventsID] <- {
    OnGameEvent_scorestats_accumulated_update = function(params) { delete getroottable()[EventsID] }

    OnGameEvent_player_death = function(params) {
    }

    OnGameEvent_player_spawn = function(params) {
        local player = GetPlayerFromUserID(params.userid);
        player.ValidateScriptScope();
        player.GetScriptScope().isHoldingNade <- false;
        player.GetScriptScope().waitingToStopInput <- false;
        player.GetScriptScope().heldNadeDetonationTime <- 0;
        player.GetScriptScope().heldNadeType <- 0;
        player.GetScriptScope().lastonground <- 0;
        AddThinkToEnt(player, "QTF2_PlayerThink");
    }

    OnGameEvent_player_team = function (params) {
    }

    OnGameEvent_teamplay_win_panel = function(params) {
    }

    OnGameEvent_post_inventory_application = function (params) {
        local player = GetPlayerFromUserID(params.userid);
        GivePlayerLoadout(player)
    }

    OnGameEvent_tf_game_over = function(params) {
    }

    OnGameEvent_recalculate_holidays = function(params) {
    }

    OnGameEvent_teamplay_restart_round = function(params) {
    }

    OnScriptHook_OnTakeDamage = function(params) {
        local victim = params.const_entity;
        local attacker = params.attacker;

        if (victim && "isGrenade" in victim.GetScriptScope()) {
            params.damage = 0;
            params.const_base_damage = 0;
            params.damage_force = Vector();
            params.damage_position = Vector();
            params.early_out = true;
            return;
        }
    }
}

function OnPostSpawn() {
    AddThinkToEnt(gamerules, "QTF2_Think");
    printl("Postspawn")
}

local EventsTable = getroottable()[EventsID]
foreach (name, callback in EventsTable) EventsTable[name] = callback.bindenv(this)
__CollectGameEventCallbacks(EventsTable)