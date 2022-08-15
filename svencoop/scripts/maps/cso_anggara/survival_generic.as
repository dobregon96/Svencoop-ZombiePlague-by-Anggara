/*
* This script implements HLSP survival mode for sc_another
*/

#include "cso_survival"
#include "zombiespawn"
#include "func_buyzone"

Survival g_Survival;

void MapInit()
{	
	RegisterZombieSpawnEntity();
	RegisterPointBuyzoneEntity();
	
	//Uncomment this to test survival mode in single player mode
	g_Survival.MinPlayersRequired = 1;
	g_Survival.DelayBeforeStart = 180;
	g_Survival.DelayBeforeEnd = 6;
	g_Survival.VoteTime = 10.0;				// increase it a bit
	g_Survival.DelayBeforeChangeLevel = 0.0;
	
	g_Survival.MapInit();
	
	// Thanks Zergeant ! ( "Zaerg @ Svencoop.com Forums" )
	// Long list of initializing monsters
	const array<CBaseEntity@> p_Precacher = 
	{
		g_EntityFuncs.Create( "monster_alien_babyvoltigore",  g_vecZero, g_vecZero, false ),
		g_EntityFuncs.Create( "monster_alien_controller",  g_vecZero, g_vecZero, false ),
		g_EntityFuncs.Create( "monster_alien_grunt",  g_vecZero, g_vecZero, false ),
		g_EntityFuncs.Create( "monster_alien_slave",  g_vecZero, g_vecZero, false ),
		g_EntityFuncs.Create( "monster_alien_tor",  g_vecZero, g_vecZero, false ),
		g_EntityFuncs.Create( "monster_alien_voltigore",  g_vecZero, g_vecZero, false ),
		g_EntityFuncs.Create( "monster_apache",  g_vecZero, g_vecZero, false ),
		g_EntityFuncs.Create( "monster_babycrab",  g_vecZero, g_vecZero, false ),
		g_EntityFuncs.Create( "monster_babygarg",  g_vecZero, g_vecZero, false ),
		g_EntityFuncs.Create( "monster_barnacle",  g_vecZero, g_vecZero, false ),
		g_EntityFuncs.Create( "monster_barney",  g_vecZero, g_vecZero, false ),
		g_EntityFuncs.Create( "monster_bigmomma",  g_vecZero, g_vecZero, false ),
		g_EntityFuncs.Create( "monster_blkop_apache",  g_vecZero, g_vecZero, false ),
		g_EntityFuncs.Create( "monster_blkop_osprey",  g_vecZero, g_vecZero, false ),
		g_EntityFuncs.Create( "monster_bloater",  g_vecZero, g_vecZero, false ),
		g_EntityFuncs.Create( "monster_bodyguard",  g_vecZero, g_vecZero, false ),
		g_EntityFuncs.Create( "monster_bullchicken",  g_vecZero, g_vecZero, false ),
		g_EntityFuncs.Create( "monster_chumtoad",  g_vecZero, g_vecZero, false ),
		g_EntityFuncs.Create( "monster_cleansuit_scientist",  g_vecZero, g_vecZero, false ),
		g_EntityFuncs.Create( "monster_cockroach",  g_vecZero, g_vecZero, false ),
		g_EntityFuncs.Create( "monster_flyer_flock",  g_vecZero, g_vecZero, false ),
		g_EntityFuncs.Create( "monster_gargantua",  g_vecZero, g_vecZero, false ),
		g_EntityFuncs.Create( "monster_gman",  g_vecZero, g_vecZero, false ),
		g_EntityFuncs.Create( "monster_gonome",  g_vecZero, g_vecZero, false ),
		g_EntityFuncs.Create( "monster_headcrab",  g_vecZero, g_vecZero, false ),
		g_EntityFuncs.Create( "monster_houndeye",  g_vecZero, g_vecZero, false ),
		g_EntityFuncs.Create( "monster_human_assassin",  g_vecZero, g_vecZero, false ),
		g_EntityFuncs.Create( "monster_human_grunt",  g_vecZero, g_vecZero, false ),
		g_EntityFuncs.Create( "monster_human_grunt_ally",  g_vecZero, g_vecZero, false ),
		g_EntityFuncs.Create( "monster_human_medic_ally",  g_vecZero, g_vecZero, false ),
		g_EntityFuncs.Create( "monster_human_torch_ally",  g_vecZero, g_vecZero, false ),
		g_EntityFuncs.Create( "monster_hwgrunt",  g_vecZero, g_vecZero, false ),
		g_EntityFuncs.Create( "monster_ichthyosaur",  g_vecZero, g_vecZero, false ),
		g_EntityFuncs.Create( "monster_kingpin",  g_vecZero, g_vecZero, false ),
		g_EntityFuncs.Create( "monster_leech",  g_vecZero, g_vecZero, false ),
		g_EntityFuncs.Create( "monster_male_assassin",  g_vecZero, g_vecZero, false ),
		g_EntityFuncs.Create( "monster_miniturret",  g_vecZero, g_vecZero, false ),
		g_EntityFuncs.Create( "monster_nihilanth",  g_vecZero, g_vecZero, false ),
		g_EntityFuncs.Create( "monster_osprey",  g_vecZero, g_vecZero, false ),
		g_EntityFuncs.Create( "monster_otis",  g_vecZero, g_vecZero, false ),
		g_EntityFuncs.Create( "monster_pitdrone",  g_vecZero, g_vecZero, false ),
		g_EntityFuncs.Create( "monster_rat",  g_vecZero, g_vecZero, false ),
		g_EntityFuncs.Create( "monster_robogrunt",  g_vecZero, g_vecZero, false ),
		g_EntityFuncs.Create( "monster_scientist",  g_vecZero, g_vecZero, false ),
		g_EntityFuncs.Create( "monster_sentry",  g_vecZero, g_vecZero, false ),
		g_EntityFuncs.Create( "monster_shockroach",  g_vecZero, g_vecZero, false ),
		g_EntityFuncs.Create( "monster_shocktrooper",  g_vecZero, g_vecZero, false ),
		g_EntityFuncs.Create( "monster_stukabat",  g_vecZero, g_vecZero, false ),
		g_EntityFuncs.Create( "monster_tentacle",  g_vecZero, g_vecZero, false ),
		g_EntityFuncs.Create( "monster_turret",  g_vecZero, g_vecZero, false ),
		g_EntityFuncs.Create( "monster_zombie",  g_vecZero, g_vecZero, false ),
		g_EntityFuncs.Create( "monster_zombie_barney",  g_vecZero, g_vecZero, false ),
		g_EntityFuncs.Create( "monster_zombie_soldier",  g_vecZero, g_vecZero, false )
	};
	for( uint i = 0; i < p_Precacher.length(); i++ ) // A loop for removing them all (get it? FOR-loop?)
	{
		g_EntityFuncs.Remove( p_Precacher[i] );
	}
	// Additional friendly skins
	g_Game.PrecacheModel( "models/agruntf.mdl" );
	g_Game.PrecacheModel( "models/apachef.mdl" );
	g_Game.PrecacheModel( "models/babygargf.mdl" ); // Not actually default for friendly babygargs, but preloaded anyway
	g_Game.PrecacheModel( "models/barnabus.mdl" );
	g_Game.PrecacheModel( "models/hassassinf.mdl" );
	g_Game.PrecacheModel( "models/hgrunt_medic.mdl" );
	g_Game.PrecacheModel( "models/hgrunt_opfor.mdl" );
	g_Game.PrecacheModel( "models/hgrunt_torch.mdl" );
	g_Game.PrecacheModel( "models/hgruntf.mdl" );
	g_Game.PrecacheModel( "models/hwgruntf.mdl" );
	g_Game.PrecacheModel( "models/islavef.mdl" );
	g_Game.PrecacheModel( "models/massnf.mdl" );
	g_Game.PrecacheModel( "models/ospreyf.mdl" );
	g_Game.PrecacheModel( "models/otisf.mdl" );
	g_Game.PrecacheModel( "models/rgruntf.mdl" );
}

void MapActivate()
{
	g_Survival.MapActivate();
}