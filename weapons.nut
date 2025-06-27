const MAX_WEAPONS = 8;
printl("QTF2: Loaded weapons.nut")
//TODO: remove droped weapons on resup

::CreateWeapon <- function(classname, item_id)
{
	local weapon = Entities.CreateByClassname(classname)
	NetProps.SetPropInt(weapon, "m_AttributeManager.m_Item.m_iItemDefinitionIndex", item_id)
	NetProps.SetPropBool(weapon, "m_AttributeManager.m_Item.m_bInitialized", true)
	NetProps.SetPropBool(weapon, "m_bValidatedAttachedEntity", true)

	return weapon
}

::GivePlayerWeapon <- function(player, weapon, switchTo = false)
{
	weapon.SetTeam(player.GetTeam())

	for (local i = 0; i < MAX_WEAPONS; i++)
	{
		local held_weapon = NetProps.GetPropEntityArray(player, "m_hMyWeapons", i)
		if (held_weapon == null)
			continue
		if (held_weapon.GetSlot() != weapon.GetSlot())
			continue
		held_weapon.Destroy()
		NetProps.SetPropEntityArray(player, "m_hMyWeapons", null, i)
		break
	}

	player.Weapon_Equip(weapon)

	if(switchTo)
		player.Weapon_Switch(weapon)
}

::RemoveCosmetic <- function(player, item_id) {
	for (local wearable = player.FirstMoveChild(); wearable != null; wearable = wearable.NextMovePeer())
	{
		if (wearable.GetClassname() != "tf_wearable")
			continue;

		local id = NetProps.GetPropInt(wearable, "m_AttributeManager.m_Item.m_iItemDefinitionIndex")
		if(id == item_id)
		{
			wearable.Destroy()
			return true;
		}
	}

	return false;
}

// --- MULTI CLASS ---
::CreateSuperShotgun <- function() {
	local weapon = CreateWeapon("tf_weapon_shotgun_soldier", 10)
	weapon.AddAttribute("clip size bonus", 1.34, 0)
	weapon.AddAttribute("maxammo secondary increased", 1.25, 0)
	weapon.DispatchSpawn()

	return weapon
}

::CreateShotgun <- function() {
	local weapon = CreateWeapon("tf_weapon_shotgun_soldier", 10)
	weapon.AddAttribute("clip size bonus", 1.34, 0)
	weapon.AddAttribute("maxammo secondary increased", 1.12, 0)
	weapon.AddAttribute("damage penalty", 0.5, 0)
	weapon.AddAttribute("spread penalty", 0.4, 0)
    
	weapon.ValidateScriptScope();
    weapon.GetScriptScope().prevSpreadPenalty <- 0.6;
    weapon.DispatchSpawn()

	return weapon
}

//TODO: Give scout melee the same numbers as normal melees
::CreateClassMelee <- function (playerClass) {
	local weapon = null
	switch (playerClass) {
		case TF_CLASS_SCOUT:
			weapon = CreateWeapon("tf_weapon_bat", 0);
            weapon.AddAttribute("fire rate penalty", 1.6, 0);
            weapon.AddAttribute("damage penalty", 1.8571428571428571, 0);
			break;
		case TF_CLASS_SOLDIER:
			weapon = CreateWeapon("tf_weapon_shovel", 6)
			break;
		case TF_CLASS_PYRO:
			weapon = CreateWeapon("tf_weapon_fireaxe", 2)
			break;
		case TF_CLASS_DEMOMAN:
			weapon = CreateWeapon("tf_weapon_bottle", 1)
			break;
		case TF_CLASS_HEAVYWEAPONS:
			weapon = CreateWeapon("tf_weapon_fists", 5)
			break;
		case TF_CLASS_ENGINEER:
			weapon = CreateWeapon("tf_weapon_wrench", 7)
			break;
		case TF_CLASS_MEDIC:
			weapon = CreateWeapon("tf_weapon_bonesaw", 8)
			break;
		case TF_CLASS_SNIPER:
			weapon = CreateWeapon("tf_weapon_club", 3)
			break;
		case TF_CLASS_SPY:
			weapon = CreateWeapon("tf_weapon_knife", 4)
			break;
		default:
			return null;
	}

	weapon.DispatchSpawn()
	return weapon;
}

// --- SCOUT ---
::CreateNailGun <- function() {
	local weapon = CreateWeapon("tf_weapon_syringegun_medic", 17)
	weapon.AddAttribute("clip size bonus", 2.5, 0)
	weapon.AddAttribute("maxammo primary increased", 3.12, 0)
    weapon.AddAttribute("Projectile speed increased", 2.0, 0)
    
	weapon.DispatchSpawn()

	return weapon
}