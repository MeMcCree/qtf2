printl("QTF2: Loaded nades.nut")

::grenCountSound <- "VFX.GrenCount";
PrecacheScriptSound(grenCountSound);

enum GrenadeTypes {
    Normal,
    Conc,
    Napalm,
    Size
};

enum GrenadeEffects {
    Conc,
    Flash,
    Tranq,
    Size
}

::QTF2_DefClassNades <- {
    [TF_CLASS_SCOUT] = [{type = GrenadeTypes.Conc, amount = 2}, {type = GrenadeTypes.Normal, amount = 0}],
    [TF_CLASS_SOLDIER] = [{type = GrenadeTypes.Normal, amount = 4}, {type = GrenadeTypes.Conc, amount = 4}],
    [TF_CLASS_PYRO] = [{type = GrenadeTypes.Normal, amount = 0}, {type = GrenadeTypes.Normal, amount = 0}],
    [TF_CLASS_DEMOMAN] = [{type = GrenadeTypes.Conc, amount = 2}, {type = GrenadeTypes.Normal, amount = 0}],
    [TF_CLASS_HEAVYWEAPONS] = [{type = GrenadeTypes.Conc, amount = 44444}, {type = GrenadeTypes.Normal, amount = 44444}],
    [TF_CLASS_ENGINEER] = [{type = GrenadeTypes.Normal, amount = 0}, {type = GrenadeTypes.Normal, amount = 0}],
    [TF_CLASS_MEDIC] = [{type = GrenadeTypes.Normal, amount = 44444}, {type = GrenadeTypes.Conc, amount = 44444}],
    [TF_CLASS_SNIPER] = [{type = GrenadeTypes.Normal, amount = 0}, {type = GrenadeTypes.Normal, amount = 0}],
    [TF_CLASS_SPY] = [{type = GrenadeTypes.Normal, amount = 0}, {type = GrenadeTypes.Normal, amount = 0}],
};

::ApplyConcEffect <- function(ply) {
    ply.GetScriptScope().effects[GrenadeEffects.Conc] <- Time() + 4.0;
}

::RemoveConcEffect <- function(ply) {
    if (GrenadeEffects.Conc in ply.GetScriptScope().effects) {
        delete ply.GetScriptScope().effects[GrenadeEffects.Conc];
    }
}

class BaseGrenade {
    model = "models/weapons/w_models/w_cannonball.mdl";
    entity = null;
    time_to_detonate = 3.8;
    detonation_time = null;
    deleted = false;

    constructor(pos, vel, owner = null) {
        local nade = Entities.CreateByClassname("prop_physics_override");

        nade.SetOrigin(pos);
        nade.SetModelSimple(model);
        if (owner) {
            nade.SetTeam(owner.GetTeam());
            nade.SetOwner(owner);
        }
        nade.SetCollisionGroup(COLLISION_GROUP_DEBRIS);
        nade.ValidateScriptScope();
        nade.GetScriptScope().isGrenade <- true;

        Entities.DispatchSpawn(nade);
        nade.ApplyAbsVelocityImpulse(vel);
        
        entity = nade; 
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
        SetPropString(explosion, "m_strExplodeSoundName", "weapons/airstrike_small_explosion_01.wav");
        SetPropInt(explosion, "m_nHealth", 999);

        Entities.DispatchSpawn(explosion);

        explosion.TakeDamage(1000.0, 0, entity.GetOwner());

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
        SetPropString(explosion, "m_strExplodeSoundName", "weapons/airstrike_small_explosion_01.wav");
        SetPropInt(explosion, "m_nHealth", 999);

        Entities.DispatchSpawn(explosion);

        explosion.TakeDamage(1000.0, 0, entity.GetOwner());

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
        SetPropString(explosion, "m_strExplodeSoundName", "weapons/cow_mangler_explosion_normal_05.wav");
        SetPropInt(explosion, "m_nHealth", 999);

        Entities.DispatchSpawn(explosion);

        explosion.TakeDamage(1000.0, 0, entity.GetOwner());

        local radius = 240;
        DebugDrawCircle(entity.GetOrigin(), Vector(255, 0, 255), 1.0, radius, false, 2.0);
        DebugDrawCircle(entity.GetOrigin(), Vector(0, 255, 0), 1.0, radius + 40, false, 2.0);
        local ent = null;
        while (ent = Entities.FindInSphere(ent, entity.GetOrigin(), radius + 40)) {
            if (ent.IsPlayer()) {
                local dir = entity.GetOrigin() - ent.GetOrigin();
                //local pushforce = dir.Length() / radius;
                local points = dir.Length() * 0.5;
                points = radius - points;
                local pushforce = dir.Scale(-points / 20.0);
                //dir.Norm();
                //dir = dir.Scale(-pushforce * 1024.0);
                //ent.SetAbsVelocity(ent.GetAbsVelocity() + dir);
                ent.SetAbsVelocity(pushforce);

                ApplyConcEffect(ent);
            }
        }

        deleted = true;
        entity.Destroy();
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