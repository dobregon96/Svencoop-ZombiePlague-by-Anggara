/*
* zombiespawn
*/

class zombiespawn : ScriptBaseEntity
{
	bool KeyValue( const string& in szKey, const string& in szValue )
	{
		if( szKey == "id" )
		{
			self.pev.iuser1 = atoi( szValue );
			return true;
		}
		else
			return BaseClass.KeyValue( szKey, szValue );
	}
	
	void Precache()
	{
		BaseClass.Precache();
		
		g_SoundSystem.PrecacheSound( self.pev.message );
	}
	
	void SetupModel()
	{
			//g_Game.PrecacheModel( "models/common/lambda.mdl" );
	}
	
	void Spawn()
	{
		self.pev.movetype 		= MOVETYPE_FLY;
		self.pev.solid 			= SOLID_TRIGGER;
		
		self.pev.framerate 		= 1.0f;
		
		//Precache the model first
		SetupModel();
		
		//Allow for custom models
		//g_EntityFuncs.SetModel( self, "models/common/lambda.mdl" );
			
		if( string( self.pev.message ).IsEmpty() )
			self.pev.message = "debris/beamstart4.wav";
		
		//g_EntityFuncs.SetOrigin( self, self.pev.origin );
			
		self.Precache();
		
		//ZombieSpawn();
	}
	
	void ZombieSpawn()
	{
		CBaseEntity@ pEntity = g_EntityFuncs.Create( "monster_gonome", self.pev.origin, Vector( 0, self.pev.angles.y, 0), true );
		
		g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "freeroam", 2);
		g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "bloodcolor", 1);
		//g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "guard_ent", "func_buyzone");
		g_EntityFuncs.DispatchSpawn( pEntity.edict() );
	}
}

void RegisterZombieSpawnEntity()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "zombiespawn", "zombiespawn" );
}

