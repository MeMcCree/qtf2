
::GivePlayerLoadout <- function(player) {
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
}

::GiveScoutLoadout <- function(player) {
	GivePlayerWeapon(player, CreateNailGun(), true)
	GivePlayerWeapon(player, CreateShotgun())
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