::ApplyPlayerAttributes <- function() {
    self.AddCustomAttribute("no double jump", 1, -1);
}

::RemoveDroppedWeapons <- function() {
    local weapon = null 
    while (weapon = Entities.FindByClassname(weapon, "tf_dropped_weapon")) {
        weapon.Destroy();
    }
}

::GivePlayerLoadout <- function(player) {
    GiveClassNades(player);
    
	switch (player.GetPlayerClass()) {
		case TF_CLASS_SCOUT:
			GiveScoutLoadout(player)
			break;
		case TF_CLASS_SOLDIER:
			GiveSoldierLoadout(player)
			break;
		case TF_CLASS_PYRO:
			GivePyroLoadout(player)
			break;
		case TF_CLASS_DEMOMAN:
			GiveDemomanLoadout(player)
			break;
		case TF_CLASS_HEAVYWEAPONS:
			GiveHeavyLoadout(player)
			break;
		case TF_CLASS_ENGINEER:
			GiveEngineerLoadout(player)
			break;
		case TF_CLASS_MEDIC:
			GiveMedicLoadout(player)
			break;
		case TF_CLASS_SNIPER:
			GiveSniperLoadout(player)
			break;
		case TF_CLASS_SPY:
			GiveSpyLoadout(player)
			break;
		default:
			break;
	}
	GivePlayerWeapon(player, CreateClassMelee(player.GetPlayerClass()))

    RemoveDroppedWeapons();
}

::GiveScoutLoadout <- function(player) {
    local syrgun = CreateNailGun()
	GivePlayerWeapon(player, syrgun, true)
    local shotty = CreateShotgun();
    GivePlayerWeapon(player, shotty)
    
    local sollyHands = "models/weapons/c_models/c_soldier_arms.mdl";
    local medicHands = "models/weapons/c_models/c_medic_arms.mdl";
    PrecacheModel(sollyHands);
    PrecacheModel(medicHands);

    local modelIndex = GetModelIndex(sollyHands);
    shotty.SetModelSimple(sollyHands);
    shotty.SetCustomViewModelModelIndex(modelIndex);
    NetProps.SetPropInt(shotty, "m_iViewModelIndex", modelIndex);

    modelIndex = GetModelIndex(medicHands);
    syrgun.SetModelSimple(medicHands);
    syrgun.SetCustomViewModelModelIndex(modelIndex);
    NetProps.SetPropInt(syrgun, "m_iViewModelIndex", modelIndex);
}

::GiveSoldierLoadout <- function(player) {
	local rocketLauncher = CreateWeapon("tf_weapon_rocketlauncher", 513)
	rocketLauncher.DispatchSpawn()
	GivePlayerWeapon(player, rocketLauncher, true)
	GivePlayerWeapon(player, CreateSuperShotgun())

	//Removing Gunboats and Manntreads
	if(!RemoveCosmetic(player, 133))
		RemoveCosmetic(player, 444)
}

::GivePyroLoadout <- function(player) {

}

::GiveDemomanLoadout <- function(player) {
	//TODO: Remove Shields and booties
}

::GiveHeavyLoadout <- function(player) {

}

::GiveEngineerLoadout <- function(player) {

}

::GiveMedicLoadout <- function(player) {

}

::GiveSniperLoadout <- function(player) {

}

::GiveSpyLoadout <- function(player) {

}