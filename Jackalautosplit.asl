//Jackal Autosplitter made by ye 7/21/2026
//added Mesen2.1.1, Mesen0.9.9, MesenRTA and FCEUX 2.6.6 support

//MesenRTA
state("Mesen", "0.0.7")
{
	byte gamestate : "MesenCore.dll", 0x42F99D0, 0xB8, 0x58, 0x18;
	byte stage     : "MesenCore.dll", 0x42F99D0, 0xB8, 0x58, 0x30;
	byte lives     : "MesenCore.dll", 0x42F99D0, 0xB8, 0x58, 0x31;
	byte bosshp    : "MesenCore.dll", 0x42F99D0, 0xB8, 0x58, 0x74F;
	byte bossflag  : "MesenCore.dll", 0x42F99D0, 0xB8, 0x58, 0x73F;
}

//Mesen0.9.9
state("Mesen", "0.9.9")
{
	byte gamestate : "MesenCore.dll", 0x42E0F30, 0xB8, 0x58, 0x18;
	byte stage     : "MesenCore.dll", 0x42E0F30, 0xB8, 0x58, 0x30;
	byte lives     : "MesenCore.dll", 0x42E0F30, 0xB8, 0x58, 0x31;
	byte bosshp    : "MesenCore.dll", 0x42E0F30, 0xB8, 0x58, 0x74F;
	byte bossflag  : "MesenCore.dll", 0x42E0F30, 0xB8, 0x58, 0x73F;
}

//Mesen2 (2.1.1)
state("Mesen", "2.1.1")
{
	byte gamestate : "MesenCore.dll", 0x046C95B8, 0x18, 0x40, 0x28, 0x18;
	byte stage     : "MesenCore.dll", 0x046C95B8, 0x18, 0x40, 0x28, 0x30;
	byte lives     : "MesenCore.dll", 0x046C95B8, 0x18, 0x40, 0x28, 0x31;
	byte bosshp    : "MesenCore.dll", 0x046C95B8, 0x18, 0x40, 0x28, 0x74F;
	byte bossflag  : "MesenCore.dll", 0x046C95B8, 0x18, 0x40, 0x28, 0x73F;
}

//FCEUX 2.6.6 (64-bit)
state("fceux64", "2.6.6")
{
	byte gamestate : "fceux64.exe", 0x6c75d0, 0x18;
	byte stage     : "fceux64.exe", 0x6c75d0, 0x30;
	byte lives     : "fceux64.exe", 0x6c75d0, 0x31;
	byte bosshp    : "fceux64.exe", 0x6c75d0, 0x74F;
	byte bossflag  : "fceux64.exe", 0x6c75d0, 0x73F;
}

startup
{
	settings.Add("infosection", true, "---Info---");
	settings.Add("info", true, "Jackal Autosplitter made by ye 7/21/2026", "infosection");
	settings.Add("info0", true, "- Emulators: Mesen2.1.1, Mesen0.9.9, MesenRTA, FCEUX2.6.6", "infosection");
	settings.Add("info1", true, "- Splits on each STAGE CLEAR screen", "infosection");
	settings.Add("info2", true, "- Final split on boss kill (Stage 6 tank dies)", "infosection");
	settings.Add("info3", true, "- Bilibili: https://space.bilibili.com/388291446", "infosection");

}

init
{
	refreshRate = 60;
	vars.bossFightActive = 0;

	if (modules.First().ModuleMemorySize == 0x934000)
		version = "2.6.6";

	if(game.ProcessName == "Mesen")
	{
		var coreDLL = Array.Find(modules, x => x.ModuleName == "MesenCore.dll");
		if (coreDLL == null)
		{
			print("MesenCore.dll isn't loaded?");
			throw new Exception("Couldn't find MesenCore.dll");
		}

		string hashStr;
		using (var sha1 = System.Security.Cryptography.SHA1.Create())
			using (var fs = File.OpenRead(coreDLL.FileName))
				hashStr = string.Concat(sha1.ComputeHash(fs).Select(b => b.ToString("X2")));

		switch (hashStr)
		{
			case "3D5571326AAF55B17663EE0D6C828D4D0782941A":
				version = "0.9.9";
				break;
			case "12BFF659191984F011E0F4FC5AC2900C929D5991":
				version = "0.0.7";
				break;
			case "2B03F4392B9EC26F2CAE02201A7EF23B6BFF8C30":
				version = "2.1.1";
				break;
			default:
				print("Unrecognized Mesen version! SHA1 = " + hashStr);
				version = "";
				break;
		}
	}


}

start {
	// New run always starts clean (clear any stale flag from previous run)
	vars.bossFightActive = 0;
	// Title screen (1) -> pre-stage animation (3)
	return old.gamestate == 1 && current.gamestate == 3;
}

reset {
	// Return to title screen
	if (current.gamestate == 1 && old.gamestate != 1) {
		vars.bossFightActive = 0;
		return true;
	}
	return false;
}

split
{
	// Clear boss flag whenever not on the final stage (Stage 6 / stage 5)
	// Only keep the flag during the Stage 6 boss fight. Prevents a stale
	// flag from a previous run triggering a false final split.
	if (current.stage != 5)
		vars.bossFightActive = 0;

	// Clear boss flag on continue screen (gamestate = 8); stage may still be 5 there
	if (current.gamestate == 8)
		vars.bossFightActive = 0;

	// Detect big tank appearance: bosshp transitions to 255
	if (current.stage == 5 && current.bosshp == 255 && old.bosshp != 255)
		vars.bossFightActive = 1;

	// Stages 0-4: STAGE CLEAR screen (gamestate -> 7)
	// Stage 5 big tank killed: bossflag -> 240
	return (current.stage < 5 && current.gamestate == 7 && old.gamestate != 7) ||
	       (current.stage == 5 && vars.bossFightActive == 1 && current.bossflag == 240 && old.bossflag != 240);
}
