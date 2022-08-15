#include <amxmodx>
#include <fun>
#include <engine>
#include <sczs_stocks>

#define PLUGIN_VERSION "1.0.3"


#define NEXT_THINK 0.1
#define TASKID_BUYZONE 300

#define INFO_MAIN "main"
#define INFO_SEC "secwep"
#define INFO_SHOT "shotwep"
#define INFO_SMG "smgwep"
#define INFO_RIF "rifwep"
#define INFO_MG "mgwep"
#define INFO_SR "srwep"
#define INFO_EQ "eqwep"
#define INFO_BACK "backbutton"

//#define SEC_POS 0
#define SG_POS sizeof(SC_WP_Pistols)
#define SMG_POS SG_POS+sizeof(SC_WP_Shotguns)
#define LR_POS SMG_POS+sizeof(SC_WP_SMG)
#define MG_POS LR_POS+sizeof(SC_WP_Rifles)
#define SR_POS MG_POS+sizeof(SC_WP_MG)
#define EQ_POS SR_POS+sizeof(SC_WP_MELEE)
#define HA_POS EQ_POS+sizeof(SC_WP_EQ)

#define ItemPrice(%1) get_pcvar_num(CvarPointer_Weapon[%1])

new sprite_line
new Float:InBuyzone[33]
//new DamageMessage

new const SC_AmmoEntities[][] = {
	"",			// NONE
	"",			// Crowbar (it is used for m16a2)
	"ammo_9mmclip",		// Glock
	"ammo_357",		// Python
	"ammo_9mmAR",		// 9mmAR
	"",
	"ammo_crossbow",	// Crossbow
	"ammo_buckshot",	// Shotgun 
	"ammo_rpgclip",		// RPG 
	"ammo_gaussclip",	// Gauss
	"ammo_egonclip",	// Egon/Gluon
	"",			// Hornetgun
	"",			// Handgrenade 
	"",			// Tripmine
	"",			// Satchel
	"",			// Snark
	"",
	"ammo_uziclip",		// UZI / DUAL_UZI
	"",			// MEDKIT
	"",
	"",			// PIPEWRENCH
	"ammo_556",		// MINIGUN
	"",			// Grapple
	"ammo_762",		// SNIPERRIFLE
	"ammo_556",		// M249
	"ammo_556clip",		// M16A2
	"ammo_sporeclip",	// SPORELAUNCHER
	"ammo_357",		// Eagle
	"",			// SHOCKRIFLE
	"ammo_gaussclip"	// DISPLACER
}

new const SC_MaxBackPackAmmo[] = {
	0,			// NONE
	0,			// Crowbar (it is used for m16a2)
	250,			// Glock
	36,			// Python
	250,			// 9mmAR
	0,
	50,			// Crossbow
	125,			// Shotgun 
	5,			// RPG 
	100,			// Gauss	(no bp)
	100,			// Egon/Gluon	(no bp)
	0,			// Hornetgun
	10,			// Handgrenade	(no bp)
	5,			// Tripmine	(no bp)
	5,			// Satchel	(no bp)
	15,			// Snark	(no bp)
	0,
	250,			// UZI / DUAL_UZI
	0,			// MEDKIT
	0,
	0,			// PIPEWRENCH
	600,			// MINIGUN	(no bp)
	0,			// Grapple
	15,			// SNIPERRIFLE
	600,			// M249
	600,			// M16A2
	30,			// SPORELAUNCHER
	36,			// Eagle
	100,			// SHOCKRIFLE	(no bp)
	100			// DISPLACER	(no bp)
}

new const SC_WP_Pistols[][] = { "weapon_glock", "weapon_357", "weapon_eagle" }

new const SC_WP_Shotguns[][] = { "weapon_shotgun" }

new const SC_WP_SMG[][] = { "weapon_9mmAR", "weapon_uzi", "weapon_uziakimbo" }

new const SC_WP_Rifles[][] = { "weapon_m16", "weapon_crossbow", "weapon_sniperrifle", "weapon_hornetgun",
			    "weapon_sporelauncher"} //, "weapon_shockrifle"}
			    
new const SC_WP_MG[][] = { "weapon_m249", "weapon_minigun" }

new const SC_WP_MELEE[][] = { "weapon_crowbar", "weapon_pipewrench", "weapon_grapple" } 

new const SC_WP_EQ[][] = { "weapon_medkit", "weapon_gauss", "weapon_egon", "weapon_displacer",
			    "weapon_rpg", "weapon_tripmine", "weapon_satchel",  "weapon_handgrenade" }// , "weapon_snark"}
			    
new const SC_It_HA[][] = { "item_healthkit", "item_battery" } // new addition

new CvarPointer_Ammo[30], CvarPointer_Weapon[30], CvarPointer_Interval;

new ItemOrder;

public plugin_precache()
{
	sprite_line = precache_model("sprites/dot.spr")
}

public plugin_init() 
{
	register_plugin("Scenario : Buyzone", PLUGIN_VERSION, "Anggara_nothing")
	
	register_clcmd("say /buy", "BuyMenuCMD")
	register_clcmd("npc_return", "BuyMenuCMD")
	register_clcmd("dropammo", "BuyAmmoCMD")
	
	
	register_think("func_buyzone", "Buyzone_Think")
	register_touch("func_buyzone", "player", "Buyzone_Touch")
	
	//DamageMessage = get_user_msgid("Damage")
	
	CvarPointer_Interval = register_cvar("cso_buyzone_interval","0.5")
	
	CvarPointer_Ammo[2] = register_cvar("cso_glock_ammo_price","1")
	CvarPointer_Ammo[3] = register_cvar("cso_python_ammo_price","1")
	CvarPointer_Ammo[4] = register_cvar("cso_mp5_ammo_price","1")
	CvarPointer_Ammo[6] = register_cvar("cso_crossbow_ammo_price","1")
	CvarPointer_Ammo[7] = register_cvar("cso_spas_ammo_price","1")
	CvarPointer_Ammo[8] = register_cvar("cso_rpg_ammo_price","1")
	CvarPointer_Ammo[9] = register_cvar("cso_gauss_ammo_price","1")
	CvarPointer_Ammo[10] = register_cvar("cso_egon_ammo_price","1")
	//CvarPointer_Ammo[12] = register_cvar("cso_hegrenade_ammo_price","5")
	//CvarPointer_Ammo[13] = register_cvar("cso_tripmine_ammo_price","3")
	//CvarPointer_Ammo[14] = register_cvar("cso_satchel_ammo_price","3")
	//CvarPointer_Ammo[15] = register_cvar("cso_snark_ammo_price","10")
	CvarPointer_Ammo[17] = register_cvar("cso_uzi_ammo_price","1")
	CvarPointer_Ammo[21] = register_cvar("cso_minigun_ammo_price","1")
	CvarPointer_Ammo[23] = register_cvar("cso_sniper_ammo_price","1")
	CvarPointer_Ammo[24] = register_cvar("cso_m249_ammo_price","1")
	CvarPointer_Ammo[25] = register_cvar("cso_m16_ammo_price","1")
	CvarPointer_Ammo[26] = register_cvar("cso_spore_ammo_price","1")
	CvarPointer_Ammo[27] = register_cvar("cso_eagle_ammo_price","1")
	CvarPointer_Ammo[29] = register_cvar("cso_displacer_ammo_price","1")
	CvarPointer_Ammo[0] = register_cvar("cso_m16grenade_ammo_price","4")
	
	//	pistols
	CvarPointer_Weapon[0] = register_cvar("cso_glock_price","3")
	CvarPointer_Weapon[1] = register_cvar("cso_python_price","12")
	CvarPointer_Weapon[2] = register_cvar("cso_eagle_price","6")
	
	//	shotguns
	CvarPointer_Weapon[3] = register_cvar("cso_spas_price","20")
	
	//	smg
	CvarPointer_Weapon[4] = register_cvar("cso_mp5_price","30")
	CvarPointer_Weapon[5] = register_cvar("cso_uzi_price","22")
	CvarPointer_Weapon[6] = register_cvar("cso_dualuzi_price","35")
	
	//	rifles
	CvarPointer_Weapon[7] = register_cvar("cso_m16_price","50")
	CvarPointer_Weapon[8] = register_cvar("cso_crossbow_price","30")
	CvarPointer_Weapon[9] = register_cvar("cso_sniper_price","40")
	CvarPointer_Weapon[10] = register_cvar("cso_hornet_price","60")
	CvarPointer_Weapon[11] = register_cvar("cso_spore_price","80")
	//CvarPointer_Weapon[12] = register_cvar("cso_shock_price","70")
	
	//	machine guns
	CvarPointer_Weapon[12] = register_cvar("cso_m249_price","150")
	CvarPointer_Weapon[13] = register_cvar("cso_minigun_price","300")
	
	//	melee
	CvarPointer_Weapon[14] = register_cvar("cso_crowbar_price","2")
	CvarPointer_Weapon[15] = register_cvar("cso_wrench_price","0")
	CvarPointer_Weapon[16] = register_cvar("cso_grapple_price","10")
	
	//	equipments
	CvarPointer_Weapon[17] = register_cvar("cso_medkit_price","15")
	CvarPointer_Weapon[18] = register_cvar("cso_gauss_price","70")
	CvarPointer_Weapon[19] = register_cvar("cso_egon_price","200")
	CvarPointer_Weapon[20] = register_cvar("cso_displacer_price","250")
	CvarPointer_Weapon[21] = register_cvar("cso_rpg_price","100")
	CvarPointer_Weapon[22] = register_cvar("cso_tripmine_price","10")
	CvarPointer_Weapon[23] = register_cvar("cso_satchel_price","7")
	CvarPointer_Weapon[24] = register_cvar("cso_hegrenade_price","5")
	//CvarPointer_Weapon[26] = register_cvar("cso_snark_price","20")
	CvarPointer_Weapon[25] = register_cvar("cso_hp_price","2")
	CvarPointer_Weapon[26] = register_cvar("cso_armor_price","2")
}

public client_putinserver(id)
{
	if(zs_is_survival_mode_enabled() == -1) pause("d");
	else
	{
		client_print(id, print_chat, "[BuyZone] Say /buy for open shop menu.");
		set_task(2.0, "BuyNotice", id);
	}
}

public BuyNotice(id)
{
	if (!is_user_connected(id))
	{
		remove_task(id);
		return;
	}
	
	client_print(id, print_chat, "[BuyZone] Say /buy for open shop menu.");
	set_task(180.0, "BuyNotice", id);
}

public BuyMenuCMD(id) {
	ShowBuyMenu(id)
	
	return PLUGIN_HANDLED 
} 

public BuyAmmoCMD(id) {
	ShowBuyMenu(id,6)
	return PLUGIN_HANDLED 
}

ShowBuyMenu(id, type = 0, showmenu = 0) {
	if(!is_user_alive(id) || InBuyzone[id] == 0.0)
		return PLUGIN_HANDLED;
	
	new menu;
	static format_teks[128];
	switch(type)
	{
		case 0 : {
			menu = menu_create("Buy Menu", "menu_handler")
			menu_additem(menu, "Pistols",		INFO_MAIN, 0) ;	//1
			menu_addblank(menu, 0);
			menu_additem(menu, "Shotguns",		INFO_MAIN, 0) ;	//2
			menu_addblank(menu, 0);
			menu_additem(menu, "SMG",		INFO_MAIN, 0) ;	//3
			menu_addblank(menu, 0);
			menu_additem(menu, "Rifles",		INFO_MAIN, 0) ;	//4
			menu_addblank(menu, 0);
			menu_additem(menu, "Machine Guns",	INFO_MAIN, 0) ;	//5
			menu_addblank(menu, 0);
			menu_additem(menu, "Weapon Ammo",	INFO_MAIN, 0) ;	//6
			menu_addblank(menu, 0);
			menu_additem(menu, "Melee/First aid",	INFO_MAIN, 0) ;	//7
			menu_addblank(menu, 0);
			menu_additem(menu, "Equipments",	INFO_MAIN, 0) ;	//8
			menu_addblank(menu, 0);
			
			format(format_teks, 127, "M16 Grenade (%d Points)", get_pcvar_num(CvarPointer_Ammo[0]));
			menu_additem(menu, format_teks,		INFO_MAIN, 0) ;	//9
			
			menu_addblank(menu, 0);
			menu_additem(menu, "Exit",		INFO_MAIN, 0) ;	//0
		}
		case 1 : {
			ItemOrder = 0;
			menu = menu_create("Buy Pistols", "menu_handler")
			
			FormatItemName("Glock 17", format_teks, charsmax(format_teks))
			menu_additem(menu, format_teks,		INFO_SEC, 0)
			menu_addblank(menu, 0);
			
			FormatItemName("Colt Python", format_teks, charsmax(format_teks))
			menu_additem(menu, format_teks,		INFO_SEC, 0)
			menu_addblank(menu, 0);
			
			FormatItemName("Desert Eagle", format_teks, charsmax(format_teks))
			menu_additem(menu, format_teks,		INFO_SEC, 0)
			menu_addblank(menu, 0);
			
			menu_addblank(menu, 1); //4
			menu_addblank(menu, 1); //5
			menu_addblank(menu, 1); //6
			menu_addblank(menu, 1); //7
			menu_addblank(menu, 1); //8
			menu_additem(menu, "Back",		INFO_BACK, 0)
		}
		case 2 : {
			ItemOrder = SG_POS;
			menu = menu_create("Buy Shotguns", "menu_handler")
			
			FormatItemName("SPAS-12 Shotgun", format_teks, charsmax(format_teks))
			menu_additem(menu, format_teks,		INFO_SHOT, 0)
			menu_addblank(menu, 0);
			
			menu_addblank(menu, 1); //2
			menu_addblank(menu, 1); //3
			menu_addblank(menu, 1); //4
			menu_addblank(menu, 1); //5
			menu_addblank(menu, 1); //6
			menu_addblank(menu, 1); //7
			menu_addblank(menu, 1); //8
			menu_additem(menu, "Back",		INFO_BACK, 0)
		}
		case 3 : {
			ItemOrder = SMG_POS;
			menu = menu_create("Buy SMG", "menu_handler")
			
			FormatItemName("H&K MP5A3", format_teks, charsmax(format_teks))
			menu_additem(menu, format_teks,		INFO_SMG, 0)
			menu_addblank(menu, 0);
			
			FormatItemName("Uzi", format_teks, charsmax(format_teks))
			menu_additem(menu, format_teks,		INFO_SMG, 0)
			menu_addblank(menu, 0);
			
			FormatItemName("Dual Uzi", format_teks, charsmax(format_teks))
			menu_additem(menu, format_teks,		INFO_SMG, 0)
			menu_addblank(menu, 1); //4
			menu_addblank(menu, 1); //5
			menu_addblank(menu, 1); //6
			menu_addblank(menu, 1); //7
			menu_addblank(menu, 1); //8
			menu_additem(menu, "Back",		INFO_BACK, 0)
		}
		case 4 : {
			ItemOrder = LR_POS;
			menu = menu_create("Buy Rifles", "menu_handler")
			
			FormatItemName("M16A2", format_teks, charsmax(format_teks))
			menu_additem(menu, format_teks,		INFO_RIF, 0)
			menu_addblank(menu, 0);
			
			FormatItemName("Crossbow", format_teks, charsmax(format_teks))
			menu_additem(menu, format_teks,		INFO_RIF, 0)
			menu_addblank(menu, 0);
			
			FormatItemName("M40a1 Sniper Rifle", format_teks, charsmax(format_teks))
			menu_additem(menu, format_teks,		INFO_RIF, 0)
			menu_addblank(menu, 0);
			
			FormatItemName("Hornet Gun", format_teks, charsmax(format_teks))
			menu_additem(menu, format_teks,		INFO_RIF, 0)
			menu_addblank(menu, 0);
			
			FormatItemName("Spore Launcher", format_teks, charsmax(format_teks))
			menu_additem(menu, format_teks,		INFO_RIF, 0)
			menu_addblank(menu, 0);
			
			/*FormatItemName("Shock Rifle", 12, format_teks, charsmax(format_teks))
			menu_additem(menu, format_teks,		INFO_RIF, 0)*/
			menu_addblank(menu, 0);
			
			menu_addblank(menu, 1); //7
			menu_addblank(menu, 1); //8
			menu_additem(menu, "Back",		INFO_BACK, 0)
		}
		case 5 : {
			ItemOrder = MG_POS;
			menu = menu_create("Buy Machine guns", "menu_handler")
			
			FormatItemName("M249 SAW", format_teks, charsmax(format_teks))
			menu_additem(menu, format_teks,		INFO_MG, 0)
			menu_addblank(menu, 0);
			
			FormatItemName("Minigun", format_teks, charsmax(format_teks))
			menu_additem(menu, format_teks,		INFO_MG, 0)
			menu_addblank(menu, 0);
			
			menu_addtext(menu,"(Note: Press USE to pickup microgun)"); //3
			menu_addtext(menu,"(Note: Microgun will spawned in your feet.)"); //4
			menu_addblank(menu, 1); //5
			menu_addblank(menu, 1); //6
			menu_addblank(menu, 1); //7
			menu_addblank(menu, 1); //8
			menu_additem(menu, "Back",		INFO_BACK, 0)
		}
		case 6 : {
			if(BuyAmmo(id, 0) && showmenu) ShowBuyMenu(id, 0);
		}
		case 7 : {
			ItemOrder = SR_POS;
			menu = menu_create("Buy Melee/First aid", "menu_handler")
			
			FormatItemName("Crowbar", format_teks, charsmax(format_teks))
			menu_additem(menu, format_teks,		INFO_SR, 0)
			menu_addblank(menu, 0);
			
			FormatItemName("Pipe Wrench", format_teks, charsmax(format_teks))
			menu_additem(menu, format_teks,		INFO_SR, 0)
			menu_addblank(menu, 0);
			
			FormatItemName("Barnacle", format_teks, charsmax(format_teks))
			menu_additem(menu, format_teks,		INFO_SR, 0)
			menu_addblank(menu, 0);
			
			ItemOrder = HA_POS;
			FormatItemName("First Aid Kit", format_teks, charsmax(format_teks))
			menu_additem(menu, format_teks,		INFO_SR, 0)
			menu_addblank(menu, 0);
			
			FormatItemName("H.E.V Armor Battery", format_teks, charsmax(format_teks))
			menu_additem(menu, format_teks,		INFO_SR, 0)
			menu_addblank(menu, 0);
			
			menu_addblank(menu, 1); //6
			menu_addblank(menu, 1); //7
			menu_addblank(menu, 1); //8
			menu_additem(menu, "Back",		INFO_BACK, 0)
		}
		case 8 : {
			ItemOrder = EQ_POS;
			menu = menu_create("Buy Equipments", "menu_handler")
			
			FormatItemName("Revival Medkit", format_teks, charsmax(format_teks))
			menu_additem(menu, format_teks,			INFO_EQ, 0)
			menu_addblank(menu, 0);
			
			FormatItemName("Tau Cannon", format_teks, charsmax(format_teks))
			menu_additem(menu, format_teks,			INFO_EQ, 0)
			menu_addblank(menu, 0);
			
			FormatItemName("Gluon/Egon Gun", format_teks, charsmax(format_teks))
			menu_additem(menu, format_teks,			INFO_EQ, 0)
			menu_addblank(menu, 0);
			
			FormatItemName("Displacer Cannon", format_teks, charsmax(format_teks))
			menu_additem(menu, format_teks,			INFO_EQ, 0)
			menu_addblank(menu, 0);
			
			FormatItemName("RPG launcher", format_teks, charsmax(format_teks))
			menu_additem(menu, format_teks,			INFO_EQ, 0)
			menu_addblank(menu, 0);
			
			FormatItemName("HECU Laser Tripmine", format_teks, charsmax(format_teks))
			menu_additem(menu, format_teks,			INFO_EQ, 0)
			menu_addblank(menu, 0);
			
			FormatItemName("Satchel Charge", format_teks, charsmax(format_teks))
			menu_additem(menu, format_teks,			INFO_EQ, 0)
			menu_addblank(menu, 0);
			
			FormatItemName("Mk 2 Grenade", format_teks, charsmax(format_teks))
			menu_additem(menu, format_teks,			INFO_EQ, 0)
			menu_addblank(menu, 0);
			
			/*FormatItemName("Squeak Grenade", 26, format_teks, charsmax(format_teks))
			menu_additem(menu, format_teks,			INFO_EQ, 0)*/
			menu_addblank(menu, 0);
			
			menu_additem(menu, "Back",			INFO_BACK, 0)
		}
		case 9 : {
			BuyAmmo(id, 1)
		}
	}
	
	if(menu)
	{
		menu_setprop( menu, MPROP_PERPAGE, 0);
		menu_display( id, menu, 0 );
	}
	
	return PLUGIN_HANDLED 
} 

public menu_handler( id, menu, item )
{
	if ( !is_user_alive(id) || InBuyzone[id] == 0.0)
	{
		menu_destroy( menu );
		return PLUGIN_HANDLED;
	}
	
	static szData[16], szName[64];
	new item_access, item_callback;
	menu_item_getinfo( menu, item, item_access, szData, charsmax( szData ), szName, charsmax( szName ), item_callback );
	
	//server_print("name %s item %d info %s", szName, item, szData);
	
	if( equal(szData, INFO_MAIN) )
	{		
		if( item == MENU_EXIT )		// dont ask me
			ShowBuyMenu(id);
		else
			ShowBuyMenu(id, item+1, 1);
		
		return PLUGIN_HANDLED;
	}
	
	if( equal(szData, INFO_SEC) ) {
		if(strlen(szName) > 0) {
			BuyItem(id, item, SC_WP_Pistols[item]);
		}
	}
	if( equal(szData, INFO_SHOT) ) {
		if(strlen(szName) > 0) {
			BuyItem(id, item+SG_POS, SC_WP_Shotguns[item]);
		}
	}
	if( equal(szData, INFO_SMG) ) {
		if(strlen(szName) > 0) {
			BuyItem(id, item+SMG_POS, SC_WP_SMG[item]);
		}
	}
	if( equal(szData, INFO_RIF) ) {
		if(strlen(szName) > 0)  {
			BuyItem(id, item+LR_POS, SC_WP_Rifles[item]);
		}
	}
	if( equal(szData, INFO_MG) ) {
		if(strlen(szName) > 0) {
			BuyItem(id, item+MG_POS, SC_WP_MG[item]);
		}
	}
	if( equal(szData, INFO_SR) ) {
		if(strlen(szName) > 0)
		{
			if(item >= sizeof(SC_WP_MELEE))
			{
				item -= sizeof(SC_WP_MELEE);
				BuyItem(id, item+HA_POS, SC_It_HA[item]);
			}
			else BuyItem(id, item+SR_POS, SC_WP_MELEE[item]);
		}
	}
	if( equal(szData, INFO_EQ) ) {
		BuyItem(id, item+EQ_POS, SC_WP_EQ[item]);
	}
	
	menu_destroy( menu );
	ShowBuyMenu(id);
	return PLUGIN_HANDLED;
}

public Buyzone_Think(ent)
{
	if(is_valid_ent(ent))
	{
		use_laser(ent)
	}
}

public Buyzone_Touch(ent, id)
{
	if(is_user_alive(id))
	{
		InBuyzone[id] = get_gametime();
		if(!task_exists(TASKID_BUYZONE + id)) set_task(get_pcvar_float(CvarPointer_Interval), "InsideBuyzone", TASKID_BUYZONE + id, _, _, "b");
	}
}

public InsideBuyzone(taskid) {
	new id = taskid - TASKID_BUYZONE;
	
	// check player if inside buyzone or not
	new Float:current_gametime = get_gametime();
	if (!is_user_alive(id) || (current_gametime - InBuyzone[id]) > get_pcvar_float(CvarPointer_Interval))
	{
		InBuyzone[id] = 0.0;
		remove_task(taskid);
		return;
	}
	
	/*message_begin(MSG_ONE_UNRELIABLE, DamageMessage, _, id)
	write_byte(0) 			// damage
	write_byte(0) 			// damage
	write_long(DMG_FREEZE) 	// type
	write_coord(0) 			// pos x
	write_coord(0) 			// pos y
	write_coord(0) 			// pos z
	message_end()*/
}

stock IsEnoughPoint(frag, price)	return (price <= frag);
stock FormatItemName(const name[], output[], len, override_num = -1) 
{
	new results = ItemOrder;
	if(override_num >= 0) results = override_num;
	format(output, len, "%s (%d Points)", name, ItemPrice(results))
	++ItemOrder;
}

stock BuyAmmo(id, argrenade = 0)
{
	new weapon,clip,ammo, frags, price = 0;
	weapon = get_user_weapon(id, clip, ammo);
	frags = get_user_frags(id);
	
	if(argrenade) {
		price = get_pcvar_num(CvarPointer_Ammo[0]);
		
		if( weapon == 25 ) // has m16?
		{
			if(IsEnoughPoint(frags,price)) 
			{
				sp_give_item(id, "ammo_ARgrenades");
				if(price > 0) set_user_frags(id, frags - price);
				client_print(id, print_chat, "[BuyZone] You bought a M203 grenade!");
				return 1;
			}
			else	client_print(id, print_chat, "[BuyZone] Not enough points");
		}
		else
		{
			client_print(id, print_chat, "[BuyZone] Switch to M16 before buying!");
		}
	}
	else {
		if(strlen(SC_AmmoEntities[weapon]) > 0)
		{
			if(ammo < SC_MaxBackPackAmmo[weapon])
			{
				price = get_pcvar_num(CvarPointer_Ammo[weapon]);
				if(IsEnoughPoint(frags,price)) 
				{
					give_item(id, SC_AmmoEntities[weapon])
					if(price > 0) set_user_frags(id, frags - price)
					//client_print(id, print_chat, "[BuyZone] You bought an ammo!");
					return 1;
				}
				else	client_print(id, print_chat, "[BuyZone] Not enough points");
			}
			else	client_print(id, print_chat, "[BuyZone] Ammo already full!");
		}
		else	client_print(id, print_chat, "[BuyZone] Switch weapon before buy ammo!");
	}
	
	return 0; 
}

stock BuyItem(id, it_pos, const it_name[])
{
	//server_print("Item pos %d", it_pos);
	new price = ItemPrice(it_pos);
	new frags = get_user_frags(id);
	
	if(is_user_alive(id) && IsEnoughPoint(frags,price)) 
	{
		if(equal(it_name, "item_healthkit") && is_player_health_maxed(id))
		{
			client_print(id, print_chat, "[BuyZone] Your HP is maxed!");
		}
		else if(equal(it_name, "item_battery") && is_player_armor_maxed(id))
		{
			client_print(id, print_chat, "[BuyZone] Your Armor is maxed!");
		}
		else
		{
			sp_give_item(id, it_name);
			if(price > 0) set_user_frags(id, frags - price);
			client_print(id, print_chat, "[BuyZone] You bought a %s! (-%d points)", it_name, price);
			engclient_cmd(id, it_name);
		}
	}
	else	client_print(id, print_chat, "[BuyZone] Not enough points");
}

stock sp_give_item(index, const item[]) // dont remove entity
{ 
	new ent = create_entity(item);
	if (!is_valid_ent(ent))
		return 0;
		
	new Float:origin[3], spawnflags;
	entity_get_vector(index, EV_VEC_origin, origin);
	entity_set_vector(ent, EV_VEC_origin, origin);
	
	entity_set_edict(ent, EV_ENT_owner, index);
	
	spawnflags = entity_get_int(ent, EV_INT_spawnflags);
	spawnflags |= SF_NORESPAWN;
	entity_set_int(ent, EV_INT_spawnflags, spawnflags);
	DispatchSpawn(ent);

	return ent;
}

stock is_player_health_maxed(id)
{
	// GodMode prevent to receive medkit or armor
	new Float:current_health = entity_get_float(id, EV_FL_health);
	return (get_user_godmode(id) || current_health >= entity_get_float(id, EV_FL_max_health));
}

stock is_player_armor_maxed(id)
{
	// GodMode prevent to receive medkit or armor
	new Float:current_armor = entity_get_float(id, EV_FL_armorvalue);
	return (get_user_godmode(id) || current_armor >= entity_get_float(id, EV_FL_armortype));
}

//////////////////////////////////////////////////////////
//		Laser Code by Miczu	   		//
//////////////////////////////////////////////////////////

public use_laser(ent)
{
	new Float: ent_min[3],Float: ent_max[3];
	
	new e_min[3],e_max[3],ents[3];	
	
	entity_get_vector(ent,EV_VEC_absmin,ent_min)
	entity_get_vector(ent,EV_VEC_absmax,ent_max)	
	
	for(new i=0;i<3;i++)
	{
		e_min[i]=floatround(ent_min[i])
		e_max[i]=floatround(ent_max[i])
		ents[i]=(e_min[i]+e_max[i])/2
	}
	
	Create_Box(e_min,e_max)
}

public Create_Box(mins[],maxs[])
{
	// Tiang
	/*DrawLine(maxs[0], maxs[1], maxs[2], maxs[0], maxs[1], mins[2])
	DrawLine(mins[0], mins[1], mins[2], mins[0], mins[1], maxs[2])
	DrawLine(mins[0], maxs[1], maxs[2], mins[0], maxs[1], mins[2])
	DrawLine(maxs[0], mins[1], mins[2], maxs[0], mins[1], maxs[2])*/
	
	// Atas
	/*DrawLine(maxs[0], maxs[1], maxs[2], mins[0], maxs[1], maxs[2])
	DrawLine(maxs[0], maxs[1], maxs[2], maxs[0], mins[1], maxs[2])
	DrawLine(maxs[0], mins[1], maxs[2], mins[0], mins[1], maxs[2])
	DrawLine(mins[0], mins[1], maxs[2], mins[0], maxs[1], maxs[2])*/
	
	// Bawah
	DrawLine(mins[0], mins[1], mins[2], maxs[0], mins[1], mins[2])
	DrawLine(mins[0], mins[1], mins[2], mins[0], maxs[1], mins[2])
	DrawLine(mins[0], maxs[1], mins[2], maxs[0], maxs[1], mins[2])
	DrawLine(maxs[0], maxs[1], mins[2], maxs[0], mins[1], mins[2])
	
}

public DrawLine(x1, y1, z1, x2, y2, z2) 
{
	new start[3]
	new stop[3]
	
	start[0]=(x1)
	start[1]=(y1)
	start[2]=(z1)
	
	stop[0]=(x2)
	stop[1]=(y2)
	stop[2]=(z2)

	Create_Line(start, stop)
}

public Create_Line(start[],stop[])
{  
	message_begin(MSG_ALL, SVC_TEMPENTITY)
	write_byte(0)
	write_coord(start[0])
	write_coord(start[1])
	write_coord(start[2])
	write_coord(stop[0])
	write_coord(stop[1])
	write_coord(stop[2])
	write_short(sprite_line)
	write_byte(1)
	write_byte(5)
	write_byte(floatround(NEXT_THINK*10))
	write_byte(15)	// line width
	write_byte(0)
	write_byte(0)	// RED
	write_byte(255)	// GREEN
	write_byte(0)	// BLUE					
	write_byte(250)	// brightness
	write_byte(5)
	message_end()
}

//////////////////////////////////////////////////////////
//		     	end code	   		//
//////////////////////////////////////////////////////////
