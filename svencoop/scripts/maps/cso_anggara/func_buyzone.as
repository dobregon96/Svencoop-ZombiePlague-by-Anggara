/*
* func_buyzone
*/


class func_buyzone : ScriptBaseEntity
{	
	private CScheduledFunction@ m_pRespawnPlayersFunc = null;
	
	bool KeyValue( const string& in szKey, const string& in szValue )
	{
		if( szKey == "minhullsize" )
		{
			g_Utility.StringToVector( self.pev.vuser2, szValue );
			return true;
		}
		else if( szKey == "maxhullsize" )
		{
			g_Utility.StringToVector( self.pev.vuser3, szValue );
			return true;
		}
		else
			return BaseClass.KeyValue( szKey, szValue );
	}
	
	void Precache()
	{
		BaseClass.Precache();
	}
	
	void SetupModel()
	{
			g_Game.PrecacheModel( "sprites/BuyZone.spr" );
	}
	
	void Spawn()
	{
		self.pev.skin			= 0;
		self.pev.iuser1			= -1;
		self.pev.movetype 		= MOVETYPE_NONE;
		self.pev.solid 			= SOLID_TRIGGER;
		self.pev.rendermode		= kRenderGlow;
		self.pev.renderfx		= kRenderFxPulseFastWide;
		self.pev.renderamt		= 255;
		self.pev.viewmodel		= "";
		
		//self.pev.framerate 		= 1.0f;
		
		SetThink( ThinkFunction( this.BuyZoneThink ) );
		self.pev.nextthink = g_Engine.time + 0.1f;
		
		//Precache the model first
		SetupModel();
		
		self.SetObjectCollisionBox();
		
		//Allow for custom models
		g_EntityFuncs.SetModel( self, "sprites/BuyZone.spr" );
			
		//Custom hull size
		if( self.pev.vuser2 != g_vecZero && self.pev.vuser3 != g_vecZero )
			g_EntityFuncs.SetSize( self.pev, self.pev.vuser2, self.pev.vuser3 );
		else
			g_EntityFuncs.SetSize( self.pev, Vector( -64, -64, -36 ), Vector( 64, 64, 36 ) );
			
		self.Precache();
		DisplacerPortalSpawn();
	}
	
	void BuyZoneThink()
	{
		if(self.pev.iuser4 > 0)
		{
			self.pev.iuser4 = 0;
			RespawnAllPlayer();
		}
		self.pev.nextthink = g_Engine.time + 0.1f;
	}
	
	void RespawnAllPlayer()
	{
		CBasePlayer@ pPlayer;
		for( int id = 1; id <= g_Engine.maxClients; id++ )
		{
			@pPlayer = g_PlayerFuncs.FindPlayerByIndex( id );

			//Only respawn if the player died
			if( pPlayer !is null && !pPlayer.IsAlive() )
			{
				//Revive player
				pPlayer.GetObserver().RemoveDeadBody();
				pPlayer.SetOrigin( self.pev.origin );
				pPlayer.Revive();
			}
		}
		
		//Remove old respawner
		if( m_pRespawnPlayersFunc !is null )
		{
			g_Scheduler.RemoveTimer( m_pRespawnPlayersFunc );
			@m_pRespawnPlayersFunc = null;
		}
		
		@m_pRespawnPlayersFunc = g_Scheduler.SetTimeout( @this, "DelayedRespawn", 0.3 );
		
	}
	
	void DelayedRespawn()
	{
		g_PlayerFuncs.RespawnAllPlayers( true, true );
		@m_pRespawnPlayersFunc = null;
	}

	void DisplacerPortalSpawn()
	{
		// Create unit but dont spawn
		Vector vOrigin = self.pev.origin;
		vOrigin[2] += 120.0;
		CBaseEntity@ pEntity = g_EntityFuncs.Create( "info_teleport_destination", vOrigin, Vector( 0, 0, 0), true );
		
		g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "targetname", "displacer_global_target" );
		g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "teleport_cooldown", "1" );
		g_EntityFuncs.DispatchSpawn( pEntity.edict() );
		
		@pEntity = g_EntityFuncs.Create( "trigger_hurt", vOrigin, Vector( 0, 0, 0), true );
		g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "spawnflags", 32 );
		g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "dmg", -300 );
		g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "damagetype", 16 );
		g_EntityFuncs.DispatchSpawn( pEntity.edict() );
	}
}

void RegisterPointBuyzoneEntity()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "func_buyzone", "func_buyzone" );
}
