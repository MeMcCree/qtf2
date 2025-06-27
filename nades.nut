enum GrenadeTypes {
    Normal,
    Conc,
    Napalm,
    Size
};

class BaseGrenade {
    model = "models/weapons/w_models/w_cannonball.mdl";
    entity = null;
    time_to_detonate = 2.2;
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
        SetPropFloat(explosion, "m_flRadius", 10.0);
        SetPropFloat(explosion, "m_flDamage", 25.0);
        SetPropString(explosion, "m_strExplodeParticleName", "ExplosionCore_MidAir");
        SetPropString(explosion, "m_strExplodeSoundName", "weapons/airstrike_small_explosion_01.wav");
        SetPropBool(explosion, m_bPassActivator, true);

        Entities.DispatchSpawn(explosion);

        explosion.AcceptInput("Detonate", "", entity.GetOwner(), null);

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

        local radius = 300;
        DebugDrawCircle(entity.GetOrigin(), Vector(1, 0, 1), 1.0, radius, false, 2.0);
        local ent = null;
        while (ent = Entities.FindInSphere(ent, entity.GetOrigin(), radius)) {
            if (ent.IsPlayer()) {
                local dir = entity.GetOrigin() - ent.GetOrigin();
                local pushforce = dir.Length() / radius;
                dir.Norm();
                pushforce = pushforce * pushforce;
                dir = dir.Scale(-pushforce * 1024.0);
                ent.SetAbsVelocity(ent.GetAbsVelocity() + dir);
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