#if !defined _fakemeta_included
	#include <fakemeta>
#endif

#if defined _sczs_stocks_included
	#endinput
#endif
#define _sczs_stocks_included


#define ZS_DefaultMonsterClassname "monster_zombie_soldier"


enum {
	ZS_SURVIVAL_ENABLED = pev_skin,
	ZS_DELAY_TIME = pev_fuser1,
	ZS_SURVIVAL_STATUS = pev_iuser1,
	ZS_ROUND_NUMBER = pev_iuser2,
	ZS_FORCE_SPAWN_PLAYER = pev_iuser4,
	ZS_NEXT_MAP = pev_viewmodel
}

enum {
	ZS_TERMINATE_KILL = 0,
	ZS_TERMINATE_REMOVE
}

enum {
	ZS_STATUS_INACTIVE = -1,
	ZS_STATUS_FREEZE,
	ZS_STATUS_RUNNING
}

// Func_Breakable spawnflags
#define SF_BREAK_REPAIRABLE 8
#define SF_BREAK_SHOW_HUD 32
#define SF_BREAK_IMMUNE_CLIENT 64
#define SF_BREAK_EXPLOSIVE_ONLY 512



stock zs_spawn_all_players()
{
	// Located at func_buyzone.as ( BuyZoneThink() )
	new ent = -1;
	while( (ent = find_ent_by_class(ent, "func_buyzone")) )
	{
		set_pev(ent, ZS_FORCE_SPAWN_PLAYER, 1);
		break;
	}
	
	
}



stock zs_get_zombie_classname(classname[], len)
{
	static value[32]; 
	get_cvar_string("cso_zombie_ent", value, charsmax(value));
	strtolower(value);
	
	if(strfind(value, "monster_") == 0 && strlen(value) > 8)
	{
		formatex(classname, len, value);
	}
	else
	{
		formatex(classname, len, ZS_DefaultMonsterClassname);
	}
}



stock zs_get_zombie_counts()
{
	new ent = -1, counts = -1; static value[32];
	zs_get_zombie_classname(value, charsmax(value));
	while( (ent = find_ent_by_class(ent, value)) )
	{
		if(entity_get_int(ent, EV_INT_deadflag) < 2)
			counts++;
	}	
	return counts;
}



stock zs_terminate_zombies(mode = ZS_TERMINATE_KILL)
{
	new ent = -1; static value[32];
	zs_get_zombie_classname(value, charsmax(value));
	while( (ent = find_ent_by_class(ent, value)) )
	{
		switch (mode)
		{
			case ZS_TERMINATE_KILL : {
				set_pev(ent, pev_health, 1.0);
				fakedamage(ent, "zs_terminate_zombies", 1.0, DMG_NERVEGAS);
			}
			case ZS_TERMINATE_REMOVE : remove_entity(ent);
		}
	}
}




stock zs_set_round_number(round = 0)
{
	// Handled by this plugin
	new ent = -1;
	while( (ent = find_ent_by_class(ent, "func_buyzone")) ) set_pev(ent, ZS_ROUND_NUMBER, round);
}




stock zs_get_round_number()
{
	// Handled by this plugin
	new ent = -1;
	while( (ent = find_ent_by_class(ent, "func_buyzone")) )
		return pev(ent, ZS_ROUND_NUMBER);
	
	return -1;
}




stock zs_is_survival_mode_enabled()
{
	// Located at Survival.as ( CheckIfActivationNeeded() )
	// Triggered when player count is enough
	new ent = -1;
	while( (ent = find_ent_by_class(ent, "func_buyzone")) )
		return pev(ent, ZS_SURVIVAL_ENABLED);
	
	return -1;
}



// Return true when survival mode activated
stock zs_get_survival_status()
{
	if(zs_is_survival_mode_enabled() == 1)
	{
		// Located at Survival.as ( m_fIsActive )
		new ent = -1;
		while( (ent = find_ent_by_class(ent, "func_buyzone")) )
			return pev(ent, ZS_SURVIVAL_STATUS);
	}
	return -1;
}



// Set survival mode status
stock zs_set_survival_status(status = 0)
{
	if(status == 1)
	{
		// Disable Player Spawn on Join
		set_cvar_float( "mp_observer_mode",	1.0 );
		set_cvar_float( "mp_observer_cyclic",	1.0 );
	}
	else if (status == 0)
	{
		// Enable Player Spawn on Join
		set_cvar_float( "mp_observer_mode",	0.0 );
		set_cvar_float( "mp_observer_cyclic",	0.0 );
	}
	
	// Located at cso_survival.as ( SetBuyzoneValue() )
	new ent = -1;
	while( (ent = find_ent_by_class(ent, "func_buyzone")) )
		set_pev(ent, ZS_SURVIVAL_STATUS, status);
}


stock UTIL_RoundTimeFormat(output[], len, seconds)
{
	new hours, minutes;
	hours = seconds / 3600;
	minutes = (seconds / 60) % 60;
	seconds = seconds % 60;
	
	formatex(output, len, "%02d:%02d:%02d", hours, minutes, seconds);
}

/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
