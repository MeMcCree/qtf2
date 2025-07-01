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

::PrecacheParticle <- function(name) {
    PrecacheEntityFromTable({classname = "info_particle_system", effect_name = name});
}

DoIncludeScript("qtf2/nades.nut", ROOT);
DoIncludeScript("qtf2/weapons.nut", ROOT);
DoIncludeScript("qtf2/player.nut", ROOT);

::grenade_maker <- GrenadeMaker();
::grenadepack_maker <- GrenadePackMaker();

::gamerules <- Entities.FindByClassname(null, "tf_gamerules");
gamerules.ValidateScriptScope();

::MaxPlayers <- MaxClients().tointeger();

::ClientCommand <- Entities.CreateByClassname("point_clientcommand");
Entities.DispatchSpawn(ClientCommand);

::gren1Text <- SpawnEntityFromTable("game_text", {
    "wide"  : "f0"
    "tall"  : "f0"
    "x"     : "0.9"
    "y"     : "0.5"
    "color" : "255 255 255"
    "holdtime" : "10"
    "channel" : "0"
});

Entities.DispatchSpawn(gren1Text);

::gren2Text <- SpawnEntityFromTable("game_text", {
    "wide"  : "f0"
    "tall"  : "f0"
    "x"     : "0.9"
    "y"     : "0.55"
    "color" : "255 255 255"
    "holdtime" : "10"
    "channel" : "1"
});

Entities.DispatchSpawn(gren2Text);

::IsPlayerValid <- function (player) {
    if (player == null || player.IsPlayer() == false)
        return false;

    if (player.GetTeam() == 0 || player.GetTeam() == 1)
        return false;

    return true;
}


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

::QTF2_HandleGrenadeInput <- function(self, num) {
    local buttons = GetPropInt(self, "m_nButtons");
    local button = IN_GRENADE1;
    if (num == 1) {
        button = IN_GRENADE2;
    }

    if (self.GetScriptScope().waitingToStopInput) {
        if (!(buttons & IN_GRENADE1) && !(buttons & IN_GRENADE2)) {
            self.GetScriptScope().waitingToStopInput = false;
        }
        return;
    }

    if (self.GetScriptScope().isHoldingNade && self.GetScriptScope().heldNadeDetonationTime < Time()) {
        self.GetScriptScope().isHoldingNade = false;
        self.GetScriptScope().waitingToStopInput = true;

        local eyepos = self.EyePosition();
        local idx = grenade_maker.SpawnNade(self.GetScriptScope().heldNadeType, self.GetOrigin() + Vector(0, 0, 40), Vector(), self);
        grenade_maker.grenades[idx].detonation_time = Time() + 0.1;
        return;
    }

    if (buttons & button) {
        if (!self.GetScriptScope().isHoldingNade) {
            if (self.GetScriptScope().nades[num].amount <= 0) return;
            self.GetScriptScope().nades[num].amount--;
            printl("Cooked " + self.GetScriptScope().nades[num].amount + " left");
            self.GetScriptScope().waitingToStopInput = true;
            self.GetScriptScope().isHoldingNade = true;
            self.GetScriptScope().heldNadeType = self.GetScriptScope().nades[num].type;
            self.GetScriptScope().heldNadeDetonationTime <- Time() + NormalGrenade.time_to_detonate;

            StopSoundOn(grenCountSound, self);
            EmitSoundOnClient(grenCountSound, self);
        } else {
            printl("Thrown");
            self.GetScriptScope().isHoldingNade = false;
            self.GetScriptScope().waitingToStopInput = true;

            self.EmitSound(grenThrowSound);

            local eyepos = self.EyePosition();
            local eyedir = self.EyeAngles().Forward();

            local idx = grenade_maker.SpawnNade(self.GetScriptScope().heldNadeType, eyepos + eyedir * 32, eyedir * 600, self);
            grenade_maker.grenades[idx].detonation_time = self.GetScriptScope().heldNadeDetonationTime;
        }
    }
}

::SpawnNadeOnDeath <- function(self) {
    if (!self.GetScriptScope().isHoldingNade) return;

    self.GetScriptScope().isHoldingNade = false;
    self.GetScriptScope().waitingToStopInput = true;

    local idx = grenade_maker.SpawnNade(self.GetScriptScope().heldNadeType, self.GetOrigin(), Vector(0, 0, 400), self);
    grenade_maker.grenades[idx].detonation_time = self.GetScriptScope().heldNadeDetonationTime + 0.1;
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
    if (!IsPlayerValid(self)) {
        SetPropString(self, "m_iszScriptThinkFunction", "");
        return;
    }

    if (self.IsAlive()) {
        QTF2_HandleGrenadeInput(self, 0);
        QTF2_HandleGrenadeInput(self, 1);
    } else {
        RemoveConcEffect(self);
        RemoveTranqEffect(self);
        RemoveFlashEffect(self);
        return;
    }

    //AutoBhop();
    if (GrenadeEffects.Conc in self.GetScriptScope().effects) {
        if (Time() > self.GetScriptScope().effects[GrenadeEffects.Conc]) {
            RemoveConcEffect(self);
        }
    }

    if (GrenadeEffects.Tranq in self.GetScriptScope().effects) {
        if (Time() > self.GetScriptScope().effects[GrenadeEffects.Tranq]) {
            RemoveTranqEffect(self);
        }
    }
    
    if ("nades" in self.GetScriptScope()) {
        local grens = self.GetScriptScope().nades;
        local val = NadeNames[grens[0].type] + " : " + grens[0].amount;
        gren1Text.KeyValueFromString("message", val);
        EntFireByHandle(gren1Text, "Display", "", 0.0, self, self);
        val = NadeNames[grens[1].type] + " : " + grens[1].amount;
        gren2Text.KeyValueFromString("message", val);
        EntFireByHandle(gren2Text, "Display", "", 0.0, self, self);
    }
    
    return -1;
}

::FilterDeletedNades <- function(key, val) {
    return !val.deleted;
}

::QTF2_Think <- function() {
    grenade_maker.grenades = grenade_maker.grenades.filter(FilterDeletedNades);
    foreach (id, grenade in grenade_maker.grenades) {
        if (!grenade.deleted) {
            grenade.Think();
        }
    }

    foreach (id, pack in grenadepack_maker.packs) {
        pack.Think();
    }

    local flare = null;
    while (flare = Entities.FindByClassname(flare, "tf_projectile_flare")) {
        if (flare.GetCollisionGroup() == COLLISION_GROUP_DEBRIS) {
            flare.Destroy();
        } else {
            flare.SetMoveType(MOVETYPE_FLY, MOVECOLLIDE_DEFAULT);
        }
    }

    local ray = null;
    while (ray = Entities.FindByClassname(ray, "tf_projectile_energy_ring")) {
        local vel = ray.GetAbsVelocity();
        vel.Norm();
        ray.SetAbsVelocity(vel * 2048.0);
    }

    return -1;
}

local EventsID = UniqueString()
getroottable()[EventsID] <- {
    OnGameEvent_scorestats_accumulated_update = function(params) { delete getroottable()[EventsID] }

    OnGameEvent_player_death = function(params) {
        local player = GetPlayerFromUserID(params.userid);
        RemoveDroppedWeapons();
        SpawnNadeOnDeath(player);
    }

    OnGameEvent_player_spawn = function(params) {
        local player = GetPlayerFromUserID(params.userid);
        if (player) {
            player.ValidateScriptScope();
            player.GetScriptScope().isHoldingNade <- false;
            player.GetScriptScope().waitingToStopInput <- false;
            player.GetScriptScope().heldNadeDetonationTime <- 0;
            player.GetScriptScope().heldNadeType <- 0;
            player.GetScriptScope().effects <- {};
            player.GetScriptScope().lastonground <- 0;

            EntFireByHandle(player, "CallScriptFunction", "ApplyPlayerAttributes", 0, null, null);
        }
    }

    OnGameEvent_player_team = function (params) {
        local player = GetPlayerFromUserID(params.userid);
        local team = params.team;
        if (team == TF_TEAM_RED || team == TF_TEAM_BLUE) {
            AddThinkToEnt(player, "QTF2_PlayerThink");
        } else {
            SetPropString(player, "m_iszScriptThinkFunction", "");
        }
    }

    OnGameEvent_teamplay_win_panel = function(params) {
    }

    OnGameEvent_post_inventory_application = function (params) {
        local player = GetPlayerFromUserID(params.userid);
        GivePlayerLoadout(player);
        RemoveConcEffect(player);
        RemoveFlashEffect(player);
        RemoveTranqEffect(player);
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
    printl("Postspawn");

    local pack = null;
    while (pack = Entities.FindByName(pack, "grenadepack_*")) {
        local name = pack.GetName();
        local splited = split(name, "_", true);
        if (splited.len() < 3)
            continue;

        local gren1Amount = splited[1].tointeger();
        local gren2Amount = splited[2].tointeger();
        grenadepack_maker.SpawnPack(pack.GetOrigin(), pack.GetModelName(), pack.GetModelScale(), gren1Amount, gren2Amount);

        pack.Destroy();
    }
}


local EventsTable = getroottable()[EventsID]
foreach (name, callback in EventsTable) EventsTable[name] = callback.bindenv(this)
__CollectGameEventCallbacks(EventsTable)