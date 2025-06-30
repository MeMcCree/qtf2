printl("QTF2: Loaded nades.nut")

::grenCountSound <- "VFX.GrenCount";
PrecacheScriptSound(grenCountSound);

::grenPackPickupSound <- "AmmoPack.Touch";
PrecacheScriptSound(grenPackPickupSound);

::HealGrenHealAmount <- 100;

PrecacheParticle("gasgren_gas");
PrecacheParticle("gasgren_gas_red");
PrecacheParticle("healgren_exp");
PrecacheParticle("healgren_exp_red");

PrecacheParticle("concgren_wave");
PrecacheParticle("concgren_wave_red");

PrecacheParticle("flashgren_exp");

enum GrenadeTypes {
    Normal,
    Conc,
    Napalm,
    Gas,
    Flash,
    Mirv,
    Nail,
    Emp,
    Heal,
    Size
};

enum GrenadePackTypes {
    Small,
    Medium,
    Large
};

::NadeNames <- {
    [GrenadeTypes.Normal] = "Normal",
    [GrenadeTypes.Conc] = "Concussion",
    [GrenadeTypes.Napalm] = "Napalm",
    [GrenadeTypes.Gas] = "Gas",
    [GrenadeTypes.Flash] = "Flash",
    [GrenadeTypes.Mirv] = "Mirv",
    [GrenadeTypes.Nail] = "Nail",
    [GrenadeTypes.Emp] = "EMP",
    [GrenadeTypes.Heal] = "Heal",
};

::NadeSounds <- {
    [GrenadeTypes.Normal] = {
        explode = "weapons/airstrike_small_explosion_01.wav"
    },
    [GrenadeTypes.Conc] = {
        explode = "weapons/cow_mangler_explosion_normal_05.wav"
    },
    [GrenadeTypes.Napalm] = {
        explode = "Ambient.Fireball"
    },
    [GrenadeTypes.Gas] = {
    },
    [GrenadeTypes.Flash] = {
        explode = "weapons/barret_arm_zap.wav"
    },
    [GrenadeTypes.Mirv] = {
        explode = "weapons/airstrike_small_explosion_01.wav"
    },
    [GrenadeTypes.Nail] = {
        explode = "weapons/airstrike_small_explosion_01.wav"
    },
    [GrenadeTypes.Emp] = {
        explode = "weapons/cow_mangler_explode.wav"
    },
    [GrenadeTypes.Heal] = {
        explode = "Halloween.spell_overheal"
        heal = "HealthKit.Touch"
    },
};
//drg_cow_explosioncore_charged_blue emp
::NadeParticles <- {
    [GrenadeTypes.Normal] = {
        explode = "ExplosionCore_MidAir"
    },
    [GrenadeTypes.Conc] = {
        explodeBlue = "concgren_wave",
        explodeRed = "concgren_wave_red"
    },
    [GrenadeTypes.Napalm] = {
        explode = "Explosions_MA_Dustup_2"
    },
    [GrenadeTypes.Gas] = {
        gasBlue = "gasgren_gas",
        gasRed = "gasgren_gas_red"
    },
    [GrenadeTypes.Flash] = {
        explode = "flashgren_exp"
    },
    [GrenadeTypes.Mirv] = {
        explode = "ExplosionCore_MidAir"
    },
    [GrenadeTypes.Nail] = {
        explode = "ExplosionCore_MidAir"
    },
    [GrenadeTypes.Emp] = {
        explodeBlue = "drg_cow_explosioncore_charged_blue",
        explodeRed = "drg_cow_explosioncore_charged"
    },
    [GrenadeTypes.Heal] = {
        explodeBlue = "healgren_exp",
        explodeRed = "healgren_exp_red"
        heal = ""
    },
};

foreach (_, sounds in NadeSounds) {
    foreach (_, sound in sounds) {
        PrecacheScriptSound(sound);
    }
}

enum GrenadeEffects {
    Conc,
    Flash,
    Tranq
    Size
};

::QTF2_DefClassNades <- {
    [TF_CLASS_SCOUT] = [{type = GrenadeTypes.Flash, amount = 2}, {type = GrenadeTypes.Conc, amount = 2}],
    [TF_CLASS_SOLDIER] = [{type = GrenadeTypes.Normal, amount = 2}, {type = GrenadeTypes.Nail, amount = 1}],
    [TF_CLASS_PYRO] = [{type = GrenadeTypes.Normal, amount = 2}, {type = GrenadeTypes.Napalm, amount = 1}],
    [TF_CLASS_DEMOMAN] = [{type = GrenadeTypes.Normal, amount = 3}, {type = GrenadeTypes.Mirv, amount = 1}],
    [TF_CLASS_HEAVYWEAPONS] = [{type = GrenadeTypes.Normal, amount = 2}, {type = GrenadeTypes.Mirv, amount = 1}],
    [TF_CLASS_ENGINEER] = [{type = GrenadeTypes.Normal, amount = 2}, {type = GrenadeTypes.Emp, amount = 1}],
    [TF_CLASS_MEDIC] = [{type = GrenadeTypes.Normal, amount = 2}, {type = GrenadeTypes.Heal, amount = 2}],
    [TF_CLASS_SNIPER] = [{type = GrenadeTypes.Normal, amount = 2}, {type = GrenadeTypes.Normal, amount = 0}],
    [TF_CLASS_SPY] = [{type = GrenadeTypes.Normal, amount = 2}, {type = GrenadeTypes.Gas, amount = 2}],
};

::ApplyConcEffect <- function(ply) {
    local firstTime = true;
    if (GrenadeEffects.Tranq in ply.GetScriptScope().effects)
        firstTime = false;

    ply.GetScriptScope().effects[GrenadeEffects.Conc] <- Time() + 10.0;

    if (!firstTime)
        return;

    if (ClientCommand) {
        ClientCommand.AcceptInput("Command", "r_screenoverlay \"effects/conc\"", ply, null);
    }

    for (local i = 0; i < 8; i++) {
        local wpn = NetProps.GetPropEntityArray(ply, "m_hMyWeapons", i);
        if (wpn == null)
            continue;

        local projSpread = wpn.GetAttribute("projectile spread angle penalty", 1.0);
        local spread = wpn.GetAttribute("spread penalty", 1.0);
        wpn.ValidateScriptScope();
        wpn.GetScriptScope().projSpread <- projSpread;
        wpn.GetScriptScope().spread <- spread;
        wpn.AddAttribute("projectile spread angle penalty", 5.0, 0);
        wpn.AddAttribute("spread penalty", spread * 2, 0);
    }
}

::RemoveConcEffect <- function(ply) {
    if (GrenadeEffects.Conc in ply.GetScriptScope().effects) {
        delete ply.GetScriptScope().effects[GrenadeEffects.Conc];

        if (ClientCommand) {
            ClientCommand.AcceptInput("Command", "r_screenoverlay \"off\"", ply, null);
        }

        for (local i = 0; i < 8; i++) {
            local wpn = NetProps.GetPropEntityArray(ply, "m_hMyWeapons", i);
            if (wpn == null)
                continue;

            if ("projSpread" in wpn.GetScriptScope())
                wpn.AddAttribute("projectile spread angle penalty", wpn.GetScriptScope().projSpread, 0);

            if ("spread" in wpn.GetScriptScope())
                wpn.AddAttribute("spread penalty", wpn.GetScriptScope().spread, 0);
        }
    }
}

::ApplyTranqEffect <- function(ply) {
    local firstTime = true;
    if (GrenadeEffects.Tranq in ply.GetScriptScope().effects)
        firstTime = false;

    ply.GetScriptScope().effects[GrenadeEffects.Tranq] <- Time() + 10.0;

    if (!firstTime)
        return;

    for (local i = 0; i < 8; i++) {
        local wpn = NetProps.GetPropEntityArray(ply, "m_hMyWeapons", i);
        if (wpn == null)
            continue;

        local fireRatePenalty = wpn.GetAttribute("fire rate penalty", 1.0);
        local reloadTimePenalty = wpn.GetAttribute("reload time increased", 1.0);
        local spinupTimePenalty = wpn.GetAttribute("minigun spinup time increased", 1.0);
        
        wpn.ValidateScriptScope();
        wpn.GetScriptScope().fireRatePenalty <- fireRatePenalty;
        wpn.GetScriptScope().reloadTimePenalty <- reloadTimePenalty;
        wpn.GetScriptScope().spinupTimePenalty <- spinupTimePenalty;
        wpn.AddAttribute("fire rate penalty", fireRatePenalty * 1.5, 0);
        wpn.AddAttribute("reload time increased", reloadTimePenalty * 1.5, 0);
        wpn.AddAttribute("minigun spinup time increased", spinupTimePenalty * 1.5, 0);
    }
}

::RemoveTranqEffect <- function(ply) {
    if (GrenadeEffects.Tranq in ply.GetScriptScope().effects) {
        delete ply.GetScriptScope().effects[GrenadeEffects.Tranq];
        DumpObject(ply.GetScriptScope().effects);
        for (local i = 0; i < 8; i++) {
            local wpn = NetProps.GetPropEntityArray(ply, "m_hMyWeapons", i);
            if (wpn == null)
                continue;

            if ("fireRatePenalty" in wpn.GetScriptScope())
                wpn.AddAttribute("fire rate penalty", wpn.GetScriptScope().fireRatePenalty, 0);

            if ("reloadTimePenalty" in wpn.GetScriptScope())
                wpn.AddAttribute("reload time increased", wpn.GetScriptScope().reloadTimePenalty, 0);

            if ("spinupTimePenalty" in wpn.GetScriptScope())
                wpn.AddAttribute("minigun spinup time increased", wpn.GetScriptScope().spinupTimePenalty, 0);
        }
    }
}

::ApplyFlashEffect <- function(ply) {
    local FlashFade = SpawnEntityFromTable("env_fade", {
        renderamt = 255
        holdtime = 4.0
        duration = 0.1
        rendercolor = "255 255 255"
    });
    FlashFade.DispatchSpawn();

    FlashFade.AcceptInput("Alpha", "255", null, null);
    FlashFade.AcceptInput("Fade", "", null, null);

    FlashFade.Destroy();
    ply.GetScriptScope().effects[GrenadeEffects.Flash] <- Time() + 4.0;
}

::RemoveFlashEffect <- function(ply) {
    if (GrenadeEffects.Flash in ply.GetScriptScope().effects) {
        local FlashFade = SpawnEntityFromTable("env_fade", {
            renderamt = 0
            holdtime = 0.0
            duration = 0.0
            rendercolor = "255 255 255"
        });
        FlashFade.DispatchSpawn();

        FlashFade.AcceptInput("Alpha", "0", null, null);
        FlashFade.AcceptInput("Fade", "", null, null);

        FlashFade.Destroy();
        delete ply.GetScriptScope().effects[GrenadeEffects.Flash];
    }
}
class BaseGrenade {
    model = "models/weapons/w_models/w_cannonball.mdl";
    entity = null;
    owner = null;
    time_to_detonate = 3.8;
    detonation_time = null;
    deleted = false;

    constructor(pos, vel, _owner = null) {
        local nade = Entities.CreateByClassname("prop_physics_override");

        nade.SetOrigin(pos);
        nade.SetModelSimple(model);
        if (_owner) {
            if (_owner.GetTeam() == TF_TEAM_BLUE)
                nade.SetSkin(1);
            //nade.SetTeam(_owner.GetTeam());
            nade.SetOwner(_owner);
            owner = _owner;
        }
        nade.AddFlag(FL_GRENADE);
        nade.SetCollisionGroup(COLLISION_GROUP_DEBRIS);
        nade.ValidateScriptScope();
        nade.GetScriptScope().isGrenade <- true;

        Entities.DispatchSpawn(nade);
        nade.ApplyAbsVelocityImpulse(vel);
        local angvel = Vector(RandomFloat(0, 1), RandomFloat(0, 1), RandomFloat(0, 1));
        angvel.Norm();
        angvel = angvel.Scale(512);
        nade.ApplyLocalAngularVelocityImpulse(angvel);
        
        entity = nade;

        OnSpawn();
    }

    function OnSpawn() {
    }

    function Think() {
        if (detonation_time && Time() > detonation_time) {
            Detonate();
        }
    }

    function Detonate() {
        local explosion = Entities.CreateByClassname("tf_generic_bomb");
        
        explosion.SetOrigin(entity.GetOrigin());
        SetPropFloat(explosion, "m_flRadius", 256.0);
        SetPropFloat(explosion, "m_flDamage", 100.0);
        SetPropString(explosion, "m_strExplodeParticleName", NadeParticles[GrenadeTypes.Normal].explode);
        SetPropString(explosion, "m_strExplodeSoundName", NadeSounds[GrenadeTypes.Normal].explode);
        SetPropInt(explosion, "m_nHealth", 999);

        Entities.DispatchSpawn(explosion);

        explosion.TakeDamage(1000.0, 0, owner);

        deleted = true;
        entity.Destroy();
    }
};

class NormalGrenade extends BaseGrenade {
    model = "models/weapons/w_models/w_cannonball.mdl";

    function Detonate() {
        local explosion = Entities.CreateByClassname("tf_generic_bomb");
        
        explosion.SetOrigin(entity.GetOrigin());
        SetPropFloat(explosion, "m_flRadius", 256.0);
        SetPropFloat(explosion, "m_flDamage", 100.0);
        SetPropString(explosion, "m_strExplodeParticleName", NadeParticles[GrenadeTypes.Normal].explode);
        SetPropString(explosion, "m_strExplodeSoundName", NadeSounds[GrenadeTypes.Normal].explode);
        SetPropInt(explosion, "m_nHealth", 999);

        Entities.DispatchSpawn(explosion);

        explosion.TakeDamage(1000.0, 0, owner);

        deleted = true;
        entity.Destroy();
    }
};

class MirvGrenade extends BaseGrenade {
    model = "models/weapons/w_models/w_cannonball.mdl";
    isClaster = false

    function Think() {
        if (detonation_time && Time() > detonation_time) {
            if (!isClaster) {
                DetonateMain();
            } else {
                DetonateCluster();
            }
        }
    }

    function DetonateMain() {
        local explosion = Entities.CreateByClassname("tf_generic_bomb");
        
        explosion.SetOrigin(entity.GetOrigin());
        SetPropFloat(explosion, "m_flRadius", 256.0);
        SetPropFloat(explosion, "m_flDamage", 30.0);
        SetPropString(explosion, "m_strExplodeParticleName", NadeParticles[GrenadeTypes.Mirv].explode);
        SetPropString(explosion, "m_strExplodeSoundName", NadeSounds[GrenadeTypes.Normal].explode);
        SetPropInt(explosion, "m_nHealth", 999);

        Entities.DispatchSpawn(explosion);

        explosion.TakeDamage(1000.0, 0, owner);

        local pos = entity.GetOrigin();
        deleted = true;
        entity.Destroy();

        local ang = QAngle(-60, 0, 0);
        local i = 0;
        while (i < 4) {
            local vel = ang.Forward() * 256;
            local idx = grenade_maker.SpawnNade(GrenadeTypes.Mirv, pos, vel, owner);
            grenade_maker.grenades[idx].isClaster = true;
            grenade_maker.grenades[idx].detonation_time = Time() + 1.5 + RandomFloat(0.0, 0.25);
            grenade_maker.grenades[idx].entity.SetModelScale(0.8, 0.0);

            ang.y += 90;
            i++;
        }
    }

    function DetonateCluster() {
        local explosion = Entities.CreateByClassname("tf_generic_bomb");
        
        explosion.SetOrigin(entity.GetOrigin());
        SetPropFloat(explosion, "m_flRadius", 128.0);
        SetPropFloat(explosion, "m_flDamage", 60.0);
        SetPropString(explosion, "m_strExplodeParticleName", NadeParticles[GrenadeTypes.Mirv].explode);
        SetPropString(explosion, "m_strExplodeSoundName", NadeSounds[GrenadeTypes.Normal].explode);
        SetPropInt(explosion, "m_nHealth", 999);

        Entities.DispatchSpawn(explosion);

        explosion.TakeDamage(1000.0, 0, owner);

        deleted = true;
        entity.Destroy();
    }
};

class ConcGrenade extends BaseGrenade {
    model = "models/weapons/w_models/w_cannonball.mdl";

    function Detonate() {
        local explosion = Entities.CreateByClassname("tf_generic_bomb");
        
        explosion.SetOrigin(entity.GetOrigin());
        SetPropFloat(explosion, "m_flRadius", 0.0);
        SetPropFloat(explosion, "m_flDamage", 0.0);
        local particle = owner.GetTeam() == TF_TEAM_BLUE ? NadeParticles[GrenadeTypes.Conc].explodeBlue : NadeParticles[GrenadeTypes.Conc].explodeRed;
        SetPropString(explosion, "m_strExplodeParticleName", particle);
        SetPropString(explosion, "m_strExplodeSoundName", NadeSounds[GrenadeTypes.Conc].explode);
        SetPropInt(explosion, "m_nHealth", 999);

        Entities.DispatchSpawn(explosion);

        explosion.TakeDamage(1000.0, 0, owner);

        local radius = 240;
        local ent = null;
        while (ent = Entities.FindInSphere(ent, entity.GetOrigin(), radius + 40)) {
            if (IsPlayerValid(ent) && ent.IsAlive()) {
                local dir = entity.GetOrigin() - ent.GetOrigin();
                local points = dir.Length() * 0.5;
                points = radius - points;
                local pushforce = dir.Scale(-points / 20.0);
                ent.RemoveFlag(FL_ONGROUND)
                ent.SetAbsVelocity(pushforce);

                ApplyConcEffect(ent);
            }
        }

        deleted = true;
        entity.Destroy();
    }
};

class HealGrenade extends BaseGrenade {
    model = "models/weapons/w_models/w_cannonball.mdl";

    function Detonate() {
        local explosion = Entities.CreateByClassname("tf_generic_bomb");
        
        explosion.SetOrigin(entity.GetOrigin());
        SetPropFloat(explosion, "m_flRadius", 0.0);
        SetPropFloat(explosion, "m_flDamage", 0.0);
        local particle = owner.GetTeam() == TF_TEAM_BLUE ? NadeParticles[GrenadeTypes.Heal].explodeBlue : NadeParticles[GrenadeTypes.Heal].explodeRed;
        SetPropString(explosion, "m_strExplodeParticleName", particle);
        SetPropString(explosion, "m_strExplodeSoundName", NadeSounds[GrenadeTypes.Heal].explode);
        SetPropInt(explosion, "m_nHealth", 999);

        Entities.DispatchSpawn(explosion);

        explosion.TakeDamage(1000.0, 0, owner);

        local radius = 256;
        local ent = null;
        while (ent = Entities.FindInSphere(ent, entity.GetOrigin(), radius)) {
            if (IsPlayerValid(ent) && ent.IsAlive() && (!owner || ent.GetTeam() == owner.GetTeam())) {
                local health = ent.GetHealth();
                local maxHealth = ent.GetMaxHealth();
                if (health == maxHealth) {
                    continue;
                }
                local healAmount = HealGrenHealAmount;
                if (IsPlayerValid(owner) && owner.GetPlayerClass() == TF_CLASS_MEDIC) {
                    healAmount /= 4;
                }
                health += healAmount;
                if (health > maxHealth) {
                    health = maxHealth;
                }
                ent.SetHealth(health);
                EmitSoundOn(NadeSounds[GrenadeTypes.Heal].heal, ent);
            }
        }

        deleted = true;
        entity.Destroy();
    }
};

class EmpGrenade extends BaseGrenade {
    model = "models/weapons/w_models/w_cannonball.mdl";

    function ExplodeBuilding(building) {
        local explosion = Entities.CreateByClassname("tf_generic_bomb");
        
        local buildingExploded = false;
        local buildingPos = building.GetOrigin();
        explosion.SetOrigin(buildingPos);
        
        if (building.GetHealth() < 100) {
            buildingExploded = true;
        }

        SetPropFloat(explosion, "m_flRadius", 1.0);
        SetPropFloat(explosion, "m_flDamage", 200);
        local particle = owner.GetTeam() == TF_TEAM_BLUE ? NadeParticles[GrenadeTypes.Emp].explodeBlue : NadeParticles[GrenadeTypes.Emp].explodeRed;
        SetPropString(explosion, "m_strExplodeParticleName", particle);
        SetPropInt(explosion, "m_nHealth", 999);

        Entities.DispatchSpawn(explosion);

        explosion.TakeDamage(1000.0, 0, owner);

        if (!buildingExploded)
            return;

        explosion = Entities.CreateByClassname("tf_generic_bomb");
        explosion.SetOrigin(buildingPos);

        SetPropFloat(explosion, "m_flRadius", 256.0);
        SetPropFloat(explosion, "m_flDamage", 100);
        SetPropInt(explosion, "m_nHealth", 999);

        Entities.DispatchSpawn(explosion);

        explosion.TakeDamage(1000.0, 0, owner);
    }

    function ExplodePlayer(ply) {
        local explosion = Entities.CreateByClassname("tf_generic_bomb");
        
        explosion.SetOrigin(ply.GetOrigin() + Vector(0, 0, 48));
        SetPropFloat(explosion, "m_flRadius", 1.0);
        SetPropFloat(explosion, "m_flDamage", 75);
        local particle = owner.GetTeam() == TF_TEAM_BLUE ? NadeParticles[GrenadeTypes.Emp].explodeBlue : NadeParticles[GrenadeTypes.Emp].explodeRed;
        SetPropString(explosion, "m_strExplodeParticleName", particle);
        SetPropInt(explosion, "m_nHealth", 999);

        Entities.DispatchSpawn(explosion);

        explosion.TakeDamage(1000.0, 0, owner);

        for (local i = 0; i < 8; i++) {
            local wpn = NetProps.GetPropEntityArray(ply, "m_hMyWeapons", i);
            if (wpn == null)
                continue;

            local ammoType = GetPropInt(wpn, "m_iPrimaryAmmoType");
            if (ammoType > 0)
                local amount = GetPropIntArray(ply, "m_iAmmo", ammoType);
                SetPropIntArray(ply, "m_iAmmo", floor(amount / 2), ammoType);
        }
    }


    function Detonate() {
        local explosion = Entities.CreateByClassname("tf_generic_bomb");
        
        explosion.SetOrigin(entity.GetOrigin());
        SetPropFloat(explosion, "m_flRadius", 0.0);
        SetPropFloat(explosion, "m_flDamage", 0.0);
        local particle = owner.GetTeam() == TF_TEAM_BLUE ? NadeParticles[GrenadeTypes.Emp].explodeBlue : NadeParticles[GrenadeTypes.Emp].explodeRed;
        SetPropString(explosion, "m_strExplodeParticleName", particle);
        SetPropString(explosion, "m_strExplodeSoundName", NadeSounds[GrenadeTypes.Emp].explode);
        SetPropInt(explosion, "m_nHealth", 999);

        Entities.DispatchSpawn(explosion);

        explosion.TakeDamage(1000.0, 0, owner);

        local radius = 256;
        local ent = null;
        while (ent = Entities.FindInSphere(ent, entity.GetOrigin(), radius)) {
            if (IsPlayerValid(ent) && ent.IsAlive() && (!owner || ent.GetTeam() != owner.GetTeam())) {
                ExplodePlayer(ent);
            } else if ((ent.GetClassname() == "obj_sentrygun" || ent.GetClassname() == "obj_dispenser") && (!owner || ent.GetTeam() != owner.GetTeam())) {
                ExplodeBuilding(ent);
            }
        }

        deleted = true;
        entity.Destroy();
    }
};

class FlashGrenade extends BaseGrenade {
    model = "models/weapons/w_models/w_cannonball.mdl";

    function Detonate() {
        local explosion = Entities.CreateByClassname("tf_generic_bomb");
        
        explosion.SetOrigin(entity.GetOrigin());
        SetPropFloat(explosion, "m_flRadius", 0.0);
        SetPropFloat(explosion, "m_flDamage", 0.0);
        SetPropString(explosion, "m_strExplodeParticleName", NadeParticles[GrenadeTypes.Flash].explode);
        //SetPropString(explosion, "m_strExplodeSoundName", NadeSounds[GrenadeTypes.Flash].explode);
        SetPropInt(explosion, "m_nHealth", 999);

        Entities.DispatchSpawn(explosion);
        //Weapon_BarretsArm.Zap
        EmitSoundEx({
            sound_name = NadeSounds[GrenadeTypes.Flash].explode
            pitch = 75
            origin = entity.GetOrigin()
            enitity = explosion
        });
        explosion.TakeDamage(1000.0, 0, owner);

        local radius = 256;
        local ent = null;
        while (ent = Entities.FindInSphere(ent, entity.GetOrigin(), radius)) {
            if (IsPlayerValid(ent) && ent.IsAlive() && (!owner || owner == ent || ent.GetTeam() != owner.GetTeam())) {
                ApplyFlashEffect(ent);
            }
        }

        deleted = true;
        entity.Destroy();
    }
};

class NapalmGrenade extends BaseGrenade {
    model = "models/weapons/w_models/w_cannonball.mdl";
    pulseTickInterval = 1.0;
    maxPulseAmount = 4;
    npulse = 0;
    nextPulse = 0;

    function Think() {
        if (npulse == maxPulseAmount) {
            deleted = true;
            entity.Destroy();
            return;
        }

        if (detonation_time && Time() > detonation_time) {
            if (Time() > nextPulse) {
                Detonate();
                npulse++;
                nextPulse = Time() + pulseTickInterval;
            }
        }
    }

    function Detonate() {
        local explosion = Entities.CreateByClassname("tf_generic_bomb");
        
        explosion.SetOrigin(entity.GetOrigin());
        SetPropFloat(explosion, "m_flRadius", 0.0);
        SetPropFloat(explosion, "m_flDamage", 0.0);
        SetPropString(explosion, "m_strExplodeParticleName", NadeParticles[GrenadeTypes.Napalm].explode);
        SetPropString(explosion, "m_strExplodeSoundName", NadeSounds[GrenadeTypes.Napalm].explode);
        SetPropInt(explosion, "m_nHealth", 999);

        Entities.DispatchSpawn(explosion);

        explosion.TakeDamage(1000.0, 0, owner);

        local radius = 256;
        local ent = null;
        while (ent = Entities.FindInSphere(ent, entity.GetOrigin(), radius)) {
            if (IsPlayerValid(ent) && ent.IsAlive()) {
                if (ent.GetPlayerClass() != TF_CLASS_PYRO) {
                    ent.AddCondEx(TF_COND_GAS, 999, owner);
                }
                ent.TakeDamageEx(entity, owner, null, Vector(), Vector(), 20.0, DMG_PLASMA);
            }
        }
    }
};

class NailGrenade extends BaseGrenade {
    model = "models/weapons/w_models/w_cannonball.mdl";
    thinks = [
        function(self) {
            if (Time() > self.detonation_time) {
                self.entity.SetMoveType(MOVETYPE_FLY, MOVECOLLIDE_FLY_BOUNCE);
                self.entity.SetAbsAngles(QAngle(0, 0, 0));
                self.entity.SetAbsVelocity(Vector(0, 0, 16));
                self.stopFlightTime = Time() + 1.0;
                self.curThink++;
            }
        },
        function(self) {
            if (Time() > self.stopFlightTime) {
                self.entity.SetAbsVelocity(Vector());
                self.stopSpinTime = Time() + 6.0;
                self.curThink++;
            }
        },
        function(self) {
            if (Time() > self.stopSpinTime) {
                self.Detonate();
                return;
            }

            if (Time() > self.nextNailTime) {
                self.FireNails();
                self.nextNailTime = Time() + 0.1;
            }
        }
    ];
    curThink = 0;
    stopFlightTime = 0;
    stopSpinTime = 0;
    nextNailTime = 0;
    nailLauncher = null;

    function OnSpawn() {
        PrecacheModel("models/weapons/w_models/w_syringe_proj.mdl");
        nailLauncher = SpawnEntityFromTable("tf_point_weapon_mimic", {
            damage = 15.0
            WeaponType = 2
            modelscale = 1
            SpeedMin = 1024.0
            SpeedMax = 1024.0
            origin = entity.GetOrigin()
            "ModelOverride" : "models/weapons/w_models/w_syringe_proj.mdl"
        });
        nailLauncher.AcceptInput("SetTeam", owner.GetTeam().tostring(), null, null);
    }

    function Think() {
        thinks[curThink](this);
    }

    function FireNail() {
        local ang = entity.GetAbsAngles();
        local vel = ang.Forward();
        vel *= 1024;

        nailLauncher.SetOrigin(entity.GetOrigin());
        nailLauncher.SetAbsAngles(ang);

        nailLauncher.AcceptInput("FireOnce", "", owner, owner);

        local proj = null
        while (proj = Entities.FindByClassname(proj, "tf_projectile_arrow")) {
            if (GetPropEntity(proj, "m_hOwnerEntity") == nailLauncher) {
                proj.SetTeam(owner.GetTeam());
                proj.SetOwner(owner);
                proj.SetMoveType(MOVETYPE_FLY, MOVECOLLIDE_DEFAULT);
                SetPropInt(proj, "m_iProjectileType", 11);
                SetPropInt(proj, "m_nModelIndexOverrides", GetModelIndex("models/weapons/w_models/w_syringe_proj.mdl"));
            }
        }

        ang = RotateOrientation(ang, QAngle(0, 5, 0));
        entity.SetAbsAngles(ang);
    }

    function FireNails() {
        local i = 0;
        while (i < 3) {
            FireNail();
            i++;
        }
    }

    function Detonate() {
        local explosion = Entities.CreateByClassname("tf_generic_bomb");
        
        explosion.SetOrigin(entity.GetOrigin());
        SetPropFloat(explosion, "m_flRadius", 128.0);
        SetPropFloat(explosion, "m_flDamage", 40.0);
        SetPropString(explosion, "m_strExplodeParticleName", NadeParticles[GrenadeTypes.Nail].explode);
        SetPropString(explosion, "m_strExplodeSoundName", NadeSounds[GrenadeTypes.Nail].explode);
        SetPropInt(explosion, "m_nHealth", 999);
        Entities.DispatchSpawn(explosion);
        explosion.TakeDamage(1000.0, 0, owner);

        deleted = true;
        entity.Destroy();
        nailLauncher.Destroy();
    }
};

class GasGrenade extends BaseGrenade {
    model = "models/weapons/w_models/w_cannonball.mdl";
    thinks = [
        function(self) {
            if (Time() > self.detonation_time) {
                self.entity.SetMoveType(MOVETYPE_FLY, MOVECOLLIDE_FLY_BOUNCE);
                self.entity.SetAbsVelocity(Vector(0, 0, 0));
                self.gasStopTime = Time() + 6.0;

                self.curThink++;
            }
        },
        function(self) {
            if (Time() > self.gasStopTime) {
                self.deleted = true;
                self.entity.Destroy();
                return;
            }

            if (Time() > self.nextEffectTime) {
                local explosion = Entities.CreateByClassname("tf_generic_bomb");
        
                explosion.SetOrigin(self.entity.GetOrigin());
                SetPropFloat(explosion, "m_flRadius", 0.0);
                SetPropFloat(explosion, "m_flDamage", 0.0);
                local particle = self.owner.GetTeam() == TF_TEAM_BLUE ? NadeParticles[GrenadeTypes.Gas].gasBlue : NadeParticles[GrenadeTypes.Gas].gasRed;
                SetPropString(explosion, "m_strExplodeParticleName", particle);
                SetPropInt(explosion, "m_nHealth", 999);
                Entities.DispatchSpawn(explosion);

                explosion.TakeDamage(1000.0, 0, self.owner);

                self.nextEffectTime = Time() + 0.5;
            }

            if (Time() > self.nextHurtTime) {
                local ent = null;
                while (ent = Entities.FindInSphere(ent, self.entity.GetOrigin(), self.radius)) {
                    if (IsPlayerValid(ent) && ent.IsAlive() && (!self.owner || ent.GetTeam() != self.owner.GetTeam())) {
                        ent.TakeDamageEx(self.entity, self.owner, null, Vector(), Vector(), 5.0, DMG_POISON);
                        ApplyTranqEffect(ent);
                    }
                }
                self.nextHurtTime = Time() + 0.5;
            }
        }
    ];

    curThink = 0;
    gasStopTime = 0;
    nextHurtTime = 0;
    nextEffectTime = 0;
    gasParticles = null;
    radius = 256;

    function Think() {
        thinks[curThink](this);
    }
};

class GrenadeMaker {
    grenades = {};
    new_idx = 0;

    function SpawnNade(type, pos, vel, owner = null) {
        switch (type) {
            case GrenadeTypes.Normal: {
                grenades[new_idx] <- NormalGrenade(pos, vel, owner);
                break;
            }
            case GrenadeTypes.Conc: {
                grenades[new_idx] <- ConcGrenade(pos, vel, owner);
                break;
            }
            case GrenadeTypes.Heal: {
                grenades[new_idx] <- HealGrenade(pos, vel, owner);
                break;
            }
            case GrenadeTypes.Napalm: {
                grenades[new_idx] <- NapalmGrenade(pos, vel, owner);
                break;
            }
            case GrenadeTypes.Nail: {
                grenades[new_idx] <- NailGrenade(pos, vel, owner);
                break;
            }
            case GrenadeTypes.Flash: {
                grenades[new_idx] <- FlashGrenade(pos, vel, owner);
                break;
            }
            case GrenadeTypes.Mirv: {
                grenades[new_idx] <- MirvGrenade(pos, vel, owner);
                break;
            }
            case GrenadeTypes.Emp: {
                grenades[new_idx] <- EmpGrenade(pos, vel, owner);
                break;
            }
            case GrenadeTypes.Gas: {
                grenades[new_idx] <- GasGrenade(pos, vel, owner);
                break;
            }
            default:
        }
        new_idx += 1;
        return new_idx - 1;
    }
};

::GiveClassNades <- function(ply) {
    local pc = ply.GetPlayerClass();

    if (pc < TF_CLASS_SCOUT || pc > TF_CLASS_ENGINEER) return;

    ply.GetScriptScope().nades <- [clone QTF2_DefClassNades[pc][0], clone QTF2_DefClassNades[pc][1]];
}

::min <- function(a, b) {
    return (a < b) ? a : b;
}

::max <- function(a, b) {
    return (a > b) ? a : b;
}

::BoxVsBox <- function(mins1, maxs1, mins2, maxs2) {
    local x = max(mins1.x, mins2.x);
    local xx = min(maxs1.x, maxs2.x);
    local y = max(mins1.y, mins2.y);
    local yy = min(maxs1.y, maxs2.y);
    local z = max(mins1.z, mins2.z);
    local zz = min(maxs1.z, maxs2.z);

    if (zz < z || yy < y || xx < x)
        return false;
    return true;
}

class GrenadePack {
    model = "";
    modelScale = 1.0;
    entity = null;
    startpos = Vector();
    ang = 0;
    packSpawned = true;
    packSpawnTime = 0;
    gren1Amount = 0;
    gren2Amount = 0;

    constructor(pos, _model, _modelScale, _gren1Amount, _gren2Amount) {
        model = _model;
        gren1Amount = _gren1Amount;
        gren2Amount = _gren2Amount;
        startpos = pos;
        modelScale = _modelScale;
        SpawnPack();
    }

    function SpawnPack() {
        local pack = Entities.CreateByClassname("prop_dynamic_override");

        pack.SetOrigin(startpos);
        pack.SetModelSimple(model);
        pack.SetCollisionGroup(COLLISION_GROUP_DEBRIS);
        pack.SetMoveType(MOVETYPE_FLY, MOVECOLLIDE_FLY_BOUNCE);
        pack.SetAbsVelocity(Vector(0, 0, 0));
        pack.SetModelScale(modelScale, 0.0);

        Entities.DispatchSpawn(pack);
        entity = pack;

        ang = 0;
        packSpawned = true;
    }

    function Think() {
        if (!packSpawned) {
            if (Time() > packSpawnTime) {
                SpawnPack();
            }
            return;
        }

        local zOffset = sin(Time()) * 4;
        local newPos = startpos + Vector(0, 0, zOffset);
        entity.SetOrigin(newPos);
        entity.SetAbsAngles(QAngle(0, ang, 0));
        ang += 0.5;
        
        local trmins = startpos + Vector(-16, -16, -16);
        local trmaxs = startpos + Vector(16, 16, 16);

        for (local i = 1; i <= MaxPlayers; i++) {
            local player = PlayerInstanceFromIndex(i);
            if (!IsPlayerValid(player))
                continue;

            local plmins = player.GetOrigin() + player.GetPlayerMins();
            local plmaxs = player.GetOrigin() + player.GetPlayerMaxs();

            if (BoxVsBox(trmins, trmaxs, plmins, plmaxs)) {
                if (GiveNades(player)) {
                    entity.Destroy();
                    entity = null;
                    packSpawnTime = Time() + 10.0;
                    packSpawned = false;
                }
            }
        }
    }

    function GiveNades(ply) {
        local pc = ply.GetPlayerClass();

        if (ply.GetScriptScope().nades[0].amount == QTF2_DefClassNades[pc][0].amount &&
            ply.GetScriptScope().nades[1].amount == QTF2_DefClassNades[pc][1].amount) {
            return false;
        }
        ply.GetScriptScope().nades[0].amount = min(ply.GetScriptScope().nades[0].amount + gren1Amount, QTF2_DefClassNades[pc][0].amount);
        ply.GetScriptScope().nades[1].amount = min(ply.GetScriptScope().nades[1].amount + gren2Amount, QTF2_DefClassNades[pc][1].amount);
        
        entity.EmitSound(grenPackPickupSound);

        return true;
    }
};

class GrenadePackMaker {
    packs = {};
    new_idx = 0;

    function SpawnPack(type, pos) {
        switch (type) {
            case GrenadePackTypes.Small: {
                packs[new_idx] <- GrenadePack(pos, "models/props_halloween/bombonomicon.mdl", 0.4, 4, 4);
                break;
            }
            default:
        }
        new_idx += 1;
        return new_idx - 1;
    }
};