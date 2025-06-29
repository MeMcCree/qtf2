printl("QTF2: Loaded nades.nut")

::grenCountSound <- "VFX.GrenCount";
PrecacheScriptSound(grenCountSound);

::HealGrenHealAmount <- 100;

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
        explode = ""
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
}

::QTF2_DefClassNades <- {
    [TF_CLASS_SCOUT] = [{type = GrenadeTypes.Flash, amount = 4}, {type = GrenadeTypes.Conc, amount = 4}],
    [TF_CLASS_SOLDIER] = [{type = GrenadeTypes.Normal, amount = 4}, {type = GrenadeTypes.Nail, amount = 4}],
    [TF_CLASS_PYRO] = [{type = GrenadeTypes.Napalm, amount = 444}, {type = GrenadeTypes.Normal, amount = 444}],
    [TF_CLASS_DEMOMAN] = [{type = GrenadeTypes.Mirv, amount = 444}, {type = GrenadeTypes.Normal, amount = 0}],
    [TF_CLASS_HEAVYWEAPONS] = [{type = GrenadeTypes.Conc, amount = 44444}, {type = GrenadeTypes.Normal, amount = 44444}],
    [TF_CLASS_ENGINEER] = [{type = GrenadeTypes.Normal, amount = 0}, {type = GrenadeTypes.Normal, amount = 0}],
    [TF_CLASS_MEDIC] = [{type = GrenadeTypes.Normal, amount = 44444}, {type = GrenadeTypes.Heal, amount = 44444}],
    [TF_CLASS_SNIPER] = [{type = GrenadeTypes.Normal, amount = 0}, {type = GrenadeTypes.Normal, amount = 0}],
    [TF_CLASS_SPY] = [{type = GrenadeTypes.Normal, amount = 0}, {type = GrenadeTypes.Normal, amount = 0}],
};

::ApplyConcEffect <- function(ply) {
    ply.GetScriptScope().effects[GrenadeEffects.Conc] <- Time() + 10.0;
}

::RemoveConcEffect <- function(ply) {
    if (GrenadeEffects.Conc in ply.GetScriptScope().effects) {
        delete ply.GetScriptScope().effects[GrenadeEffects.Conc];
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
            nade.SetTeam(_owner.GetTeam());
            nade.SetOwner(_owner);
            owner = _owner;
        }
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
        SetPropString(explosion, "m_strExplodeParticleName", "ExplosionCore_MidAir");
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
        SetPropString(explosion, "m_strExplodeParticleName", "ExplosionCore_MidAir");
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
        SetPropString(explosion, "m_strExplodeParticleName", "ExplosionCore_MidAir");
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
        SetPropString(explosion, "m_strExplodeParticleName", "ExplosionCore_MidAir");
        SetPropString(explosion, "m_strExplodeSoundName", NadeSounds[GrenadeTypes.Normal].explode);
        SetPropInt(explosion, "m_nHealth", 999);

        Entities.DispatchSpawn(explosion);

        explosion.TakeDamage(1000.0, 0, owner);

        DebugDrawCircle(entity.GetOrigin(), Vector(255, 0, 0), 1.0, 128, false, 2.0);

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
        SetPropString(explosion, "m_strExplodeParticleName", "drg_cow_explosion_sparks_blue");
        SetPropString(explosion, "m_strExplodeSoundName", NadeSounds[GrenadeTypes.Conc].explode);
        SetPropInt(explosion, "m_nHealth", 999);

        Entities.DispatchSpawn(explosion);

        explosion.TakeDamage(1000.0, 0, owner);

        local radius = 240;
        DebugDrawCircle(entity.GetOrigin(), Vector(255, 0, 255), 1.0, radius, false, 2.0);
        DebugDrawCircle(entity.GetOrigin(), Vector(0, 255, 0), 1.0, radius + 40, false, 2.0);
        local ent = null;
        while (ent = Entities.FindInSphere(ent, entity.GetOrigin(), radius + 40)) {
            if (IsPlayerValid(ent) && ent.IsAlive()) {
                local dir = entity.GetOrigin() - ent.GetOrigin();
                local points = dir.Length() * 0.5;
                points = radius - points;
                local pushforce = dir.Scale(-points / 20.0);
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
        SetPropString(explosion, "m_strExplodeParticleName", "drg_cow_explosion_sparks_blue");
        SetPropString(explosion, "m_strExplodeSoundName", NadeSounds[GrenadeTypes.Heal].explode);
        SetPropInt(explosion, "m_nHealth", 999);

        Entities.DispatchSpawn(explosion);

        explosion.TakeDamage(1000.0, 0, owner);

        local radius = 256;
        DebugDrawCircle(entity.GetOrigin(), Vector(255, 0, 0), 1.0, radius, false, 2.0);
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

class FlashGrenade extends BaseGrenade {
    model = "models/weapons/w_models/w_cannonball.mdl";

    function Detonate() {
        local explosion = Entities.CreateByClassname("tf_generic_bomb");
        
        explosion.SetOrigin(entity.GetOrigin());
        SetPropFloat(explosion, "m_flRadius", 0.0);
        SetPropFloat(explosion, "m_flDamage", 0.0);
        SetPropString(explosion, "m_strExplodeParticleName", "drg_cow_explosion_sparks_blue");
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
        DebugDrawCircle(entity.GetOrigin(), Vector(255, 0, 0), 1.0, radius, false, 2.0);
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
        SetPropString(explosion, "m_strExplodeParticleName", "Explosions_MA_Dustup_2");
        SetPropString(explosion, "m_strExplodeSoundName", NadeSounds[GrenadeTypes.Napalm].explode);
        SetPropInt(explosion, "m_nHealth", 999);

        Entities.DispatchSpawn(explosion);

        explosion.TakeDamage(1000.0, 0, owner);

        local radius = 256;
        DebugDrawCircle(entity.GetOrigin(), Vector(255, 0, 0), 1.0, radius, false, 2.0);
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
        SetPropString(explosion, "m_strExplodeParticleName", "ExplosionCore_MidAir");
        SetPropString(explosion, "m_strExplodeSoundName", NadeSounds[GrenadeTypes.Normal].explode);
        SetPropInt(explosion, "m_nHealth", 999);
        Entities.DispatchSpawn(explosion);
        explosion.TakeDamage(1000.0, 0, owner);

        deleted = true;
        entity.Destroy();
        nailLauncher.Destroy();
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
            default:
        }
        new_idx += 1;
        return new_idx - 1;
    }
};

::GiveClassNades <- function(ply) {
    local pc = ply.GetPlayerClass();
    if (pc < TF_CLASS_SCOUT || pc > TF_CLASS_SPY) return;

    ply.GetScriptScope().nades <- [clone QTF2_DefClassNades[pc][0], clone QTF2_DefClassNades[pc][1]];
}