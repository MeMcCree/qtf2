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
    
	/*switch (player.GetPlayerClass()) {
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
	GivePlayerWeapon(player, CreateClassMelee(player.GetPlayerClass()))*/

    RemoveDroppedWeapons();
}

::GiveScoutLoadout <- function(player) {
    GivePlayerWeaponWithArms(player, CreateNailGun(), true, "models/weapons/c_models/c_medic_arms.mdl");
    GivePlayerWeaponWithArms(player, CreateShotgun(), false, "models/weapons/c_models/c_soldier_arms.mdl");
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
    //GivePlayerWeapon(player, CreateWeapon("tf_weapon_flamethrower", 21), true);
    GivePlayerWeapon(player, CreatePyroRocketLauncher(), true);
}

::GiveDemomanLoadout <- function(player) {
    // RemoveCosmetic(player, 405);
    // RemoveCosmetic(player, 608);
    // RemoveCosmetic(player, 1101);

    // RemoveCosmetic(player, 131);
    // RemoveCosmetic(player, 406);
    // RemoveCosmetic(player, 1099);
    // RemoveCosmetic(player, 1144);

    GivePlayerWeapon(player, CreateWeapon("tf_weapon_grenadelauncher", 19), true);
    GivePlayerWeapon(player, CreateWeapon("tf_weapon_pipebomblauncher", 20));
}

::GiveHeavyLoadout <- function(player) {
    GivePlayerWeapon(player, CreateWeapon("tf_weapon_minigun", 15), true);
    GivePlayerWeaponWithArms(player, CreateSuperShotgun(), false, "models/weapons/c_models/c_soldier_arms.mdl");
}

::GiveEngineerLoadout <- function(player) {
    GivePlayerWeapon(player, CreateRailgun(), true);
    GivePlayerWeaponWithArms(player, CreateSuperShotgun(), false, "models/weapons/c_models/c_soldier_arms.mdl");
}

::GiveMedicLoadout <- function(player) {
    GivePlayerWeapon(player, CreateSuperNailGun(), true);
    GivePlayerWeaponWithArms(player, CreateSuperShotgun(), false, "models/weapons/c_models/c_soldier_arms.mdl");
}

::GiveSniperLoadout <- function(player) {
    GivePlayerWeapon(player, CreateClassic(), true);
}

::GiveSpyLoadout <- function(player) {
    GivePlayerWeaponWithArms(player, CreateSuperShotgun(), false, "models/weapons/c_models/c_soldier_arms.mdl");
}