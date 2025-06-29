printl("QTF2: Loaded nades.nut")

::normalGrenExplodeSound <- "weapons/airstrike_small_explosion_01.wav";
PrecacheSound(normalGrenExplodeSound);
::ConcGrenExplodeSound <- "weapons/cow_mangler_explosion_normal_05.wav";
PrecacheSound(ConcGrenExplodeSound);

::grenCountSound <- "VFX.GrenCount";
PrecacheScriptSound(grenCountSound);

::healGrenExplodeSound <- "Halloween.spell_overheal";
::healGrenHealSound <- "HealthKit.Touch";
PrecacheScriptSound(healGrenExplodeSound);
PrecacheScriptSound(healGrenHealSound);

::NapalmNadeExplodeSound <- "Ambient.Fireball";
PrecacheScriptSound(NapalmNadeExplodeSound);

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

enum GrenadeEffects {
    Conc,
    Flash,
    Tranq,
    Slow,
    Size
}

::QTF2_DefClassNades <- {
    [TF_CLASS_SCOUT] = [{type = GrenadeTypes.Conc, amount = 2}, {type = GrenadeTypes.Normal, amount = 0}],
    [TF_CLASS_SOLDIER] = [{type = GrenadeTypes.Normal, amount = 4}, {type = GrenadeTypes.Conc, amount = 4}],
    [TF_CLASS_PYRO] = [{type = GrenadeTypes.Napalm, amount = 444}, {type = GrenadeTypes.Normal, amount = 444}],
    [TF_CLASS_DEMOMAN] = [{type = GrenadeTypes.Napalm, amount = 444}, {type = GrenadeTypes.Normal, amount = 0}],
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
        SetPropString(explosion, "m_strExplodeSoundName", normalGrenExplodeSound);
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
        SetPropString(explosion, "m_strExplodeSoundName", normalGrenExplodeSound);
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
        SetPropString(explosion, "m_strExplodeParticleName", "drg_cow_explosion_sparks_blue");
        SetPropString(explosion, "m_strExplodeSoundName", ConcGrenExplodeSound);
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
        SetPropString(explosion, "m_strExplodeSoundName", healGrenExplodeSound);
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
                EmitSoundOn(healGrenHealSound, ent);
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
        SetPropString(explosion, "m_strExplodeSoundName", NapalmNadeExplodeSound);
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

    function Think() {
        if (detonation_time && Time() > detonation_time) {
        }
    }

    function Detonate() {
        local explosion = Entities.CreateByClassname("tf_generic_bomb");
        
        explosion.SetOrigin(entity.GetOrigin());
        SetPropFloat(explosion, "m_flRadius", 128.0);
        SetPropFloat(explosion, "m_flDamage", 40.0);
        SetPropString(explosion, "m_strExplodeParticleName", "ExplosionCore_MidAir");
        SetPropString(explosion, "m_strExplodeSoundName", normalGrenExplodeSound);
        SetPropInt(explosion, "m_nHealth", 999);
        Entities.DispatchSpawn(explosion);
        explosion.TakeDamage(1000.0, 0, owner);
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