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
	weapon.AddAttribute("damage penalty", 0.5, 0)
	weapon.AddAttribute("spread penalty", 0.6, 0)
	weapon.DispatchSpawn()

	return weapon
}