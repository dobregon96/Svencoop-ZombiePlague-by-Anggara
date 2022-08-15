/*
* This script implements a survival mode
* DelayBeforeStart seconds after more than ( MinPlayersRequired - 1 ) players are in the game, respawning is disabled
* Once all players are dead, after DelayBeforeEnd seconds, a vote is started to ask all players if they want to restart or go to the next map
* This vote lasts for VoteTime seconds
* Once the vote has ended, after DelayBeforeChangeLevel seconds, the map is changed
* If the server is empty, or has less than MinPlayersRequired, the script waits for more players before enabling itself
*/

const int SURVIVAL_INFINITE_RETRIES = -1;


enum SurvivalState
{
	SURVIVAL_INACTIVE = 0,
	SURVIVAL_ACTIVATING,
	SURVIVAL_ACTIVE
}

// Mode
// 0 ==> set time before survival started
// 1 ==> set boolean survival activated/deactivated ( see DisableRespawn() )
// 2 ==> trigger SpawnAllPlayers
// 3 ==> retries left
// 4 ==> set boolean survival mode toggle (enable/disable) ( see CheckIfActivationNeeded() )
enum BuyZoneModeSwitch
{
	BZ_MODE_TIME 		= 0,
	BZ_MODE_ACTIVATED,
	BZ_MODE_SPAWN,
	BZ_MODE_RETRIES,
	BZ_MODE_ENABLED
}

final class Survival
{
	//Whether survival mode is enabled
	private bool m_fIsEnabled = true;
	
	//Current state
	private SurvivalState m_State = SURVIVAL_INACTIVE;
	
	//Minimum players required to enable survival mode
	private int m_iMinPlayersRequired;
	
	//When Survival mode will activate. Is 0 if it's not in the activating state
	private float m_flActivationTime = 0;
	
	//The interval between messages to all players indicating when Survival mode will start
	private float m_flDisplayTimeInterval = 1;
	
	//Retries
	private int m_iRetries;
	
	//Delay, in seconds, before survival mode starts after it is enabled
	private float m_flDelayBeforeStart;
	
	//Delay before the game starts the end vote
	private float m_flDelayBeforeEnd;
	
	//How much time is given for players to vote
	private float m_flVoteTime;
	
	//Time before changelevel if all players are dead and have voted
	private float m_flDelayBeforeChangeLevel;
	
	private CScheduledFunction@ m_pDisableRespawnFunc = null;
	private CScheduledFunction@ m_pCheckForLivingPlayersFunc = null;
	
	private bool m_fGameEnded = false;
	
	private CCVar@ m_pSurvivalRetries;
	
	private CCVar@ m_pNextSurvivalMap;
	
	bool IsEnabled
	{
		get const { return m_fIsEnabled; }
	}
	
	bool IsActive
	{
		get const { return m_State == SURVIVAL_ACTIVE; }
	}
	
	int MinPlayersRequired
	{
		get const { return m_iMinPlayersRequired; }
		set { m_iMinPlayersRequired = value; }
	}
	
	float DisplayTimeInterval
	{
		get const { return m_flDisplayTimeInterval; }
		set { m_flDisplayTimeInterval = Math.max( value, 1 ); }
	}
	
	float DelayBeforeStart
	{
		get const { return m_flDelayBeforeStart; }
		set { m_flDelayBeforeStart = Math.max( value, 0 )+1; }
	}
	
	float DelayBeforeEnd
	{
		get const { return m_flDelayBeforeEnd; }
		set { m_flDelayBeforeEnd = Math.max( value, 0 ); }
	}
	
	float VoteTime
	{
		get const { return m_flVoteTime; }
		set { m_flVoteTime = Math.max( value, 0 ); }
	}
	
	float DelayBeforeChangeLevel
	{
		get const { return m_flDelayBeforeChangeLevel; }
		set { m_flDelayBeforeChangeLevel = Math.max( value, 0 ); }
	}
	
	bool GameEnded
	{
		get const { return m_fGameEnded; }
	}
	
	Survival()
	{
		m_iRetries					= 3;	// Default retries
		m_iMinPlayersRequired 		= 2;	//Default to 2 players needed to start survival mode
		m_flDelayBeforeStart 		= 120;	//Default to 2 minutes before survival mode starts
		m_flDelayBeforeEnd 			= 60;	//Delay between the last player dying and the end vote start
		m_flVoteTime 				= 15;	//How long the vote lasts
		m_flDelayBeforeChangeLevel 	= 10;	//How long between the vote ends and the map is changed
		
		@m_pSurvivalRetries = CCVar( "survival_retries", 3, "Number of retries before a vote starts. -1 allows for infinite retries, without a vote.", ConCommandFlag::AdminOnly, CVarCallback( this.SurvivalRetriesCB ) );
		
		@m_pNextSurvivalMap = CCVar( "next_survival_map", "", "Sets the next survival map to switch to if next map is voted" , ConCommandFlag::AdminOnly, CVarCallback( this.SurvivalNextMapCB ) );
	}
	
	void MapInit()
	{
		const array<string> current = { g_Engine.mapname };
		
		g_Hooks.RegisterHook( Hooks::Player::ClientPutInServer, @ClientPutInServerHook( this.ClientPutInServer ) );
		g_Hooks.RegisterHook( Hooks::Player::ClientDisconnect, @ClientDisconnectHook( this.ClientDisconnect ) );
		g_Hooks.RegisterHook( Hooks::Player::PlayerKilled, @PlayerKilledHook( this.PlayerKilled ) );
	}
	
	void MapActivate()
	{		
		//Initialize setting
		SetBuyzoneValue(0.0, BZ_MODE_ACTIVATED);
		SetBuyzoneValue( float(GetRetriesLeft()), BZ_MODE_RETRIES );
		
		string szMapName;
		const string szNext = m_pNextSurvivalMap.GetString();
		szMapName = szNext.IsEmpty() ? g_MapCycle.GetNextMap() : szNext;
		
		SetBuyzoneValue(0.0, 5, szMapName);
	}
	
	private void SurvivalRetriesCB( CCVar@ cvar, const string& in szOldValue, float flOldValue )
	{
		//Clamp all negative values to -1.
		if( cvar.GetInt() < SURVIVAL_INFINITE_RETRIES )
			cvar.SetInt( SURVIVAL_INFINITE_RETRIES );
		
		m_iRetries = cvar.GetInt();
		
		string szAppend;
		snprintf( szAppend, "Retry set to %1 => %2 %3 left.", cvar.GetInt(), GetRetriesLeft(), GetRetriesLeft() <= 1 ? "retry" : "retries" );
		g_PlayerFuncs.ClientPrintAll( HUD_PRINTTALK, szAppend );
	}
	
	private void SurvivalNextMapCB( CCVar@ cvar, const string& in szOldValue, float flOldValue )
	{
		string szMapName;
		const string szNext = m_pNextSurvivalMap.GetString();
		szMapName = szNext.IsEmpty() ? g_MapCycle.GetNextMap() : szNext;
		
		SetBuyzoneValue(0.0, 5, szMapName);
	}
	
	bool HasInfiniteRetries() const
	{
		return m_pSurvivalRetries.GetInt() == SURVIVAL_INFINITE_RETRIES;
	}
	
	int GetRetriesAllowed() const
	{
		return HasInfiniteRetries() ? Math.INT32_MAX : m_pSurvivalRetries.GetInt();
	}
	
	int GetRetriesLeft() const
	{
		return m_iRetries;
	}
	
	void RetryUsed()
	{
		const int iLeft = GetRetriesLeft();
		
		if( iLeft > 0 )
		{
			m_iRetries =  iLeft - 1;
			SetBuyzoneValue( float(GetRetriesLeft()), BZ_MODE_RETRIES );
		}
	}
	
	//Resets survival mode to wait for players
	void Reset()
	{
		g_EngineFuncs.CVarSetFloat( "mp_observer_mode", 0 );
		g_EngineFuncs.CVarSetFloat( "mp_observer_cyclic", 0 );
		
		//Remove the respawn disabler
		if( m_pDisableRespawnFunc !is null )
		{
			g_Scheduler.RemoveTimer( m_pDisableRespawnFunc );
			@m_pDisableRespawnFunc = null;
		}
		
		if( m_pCheckForLivingPlayersFunc !is null )
		{
			g_Scheduler.RemoveTimer( m_pCheckForLivingPlayersFunc );
			@m_pCheckForLivingPlayersFunc = null;
		}
		
		m_State = SURVIVAL_INACTIVE;
		m_flActivationTime = 0;
		m_fGameEnded = false;
		
		/*
		* Respawn any dead players; disabling observer mode should do this, but we'll make sure of it here
		*/
		g_PlayerFuncs.RespawnAllPlayers( false, true );
	}
	
	void DisableRespawn()
	{
		g_EngineFuncs.CVarSetFloat( "mp_observer_mode", 1 );
		g_EngineFuncs.CVarSetFloat( "mp_observer_cyclic", 1 );
		
		@m_pDisableRespawnFunc = null;
		
		m_State = SURVIVAL_ACTIVE;
		m_flActivationTime = 0;
		
		//g_PlayerFuncs.ClientPrintAll( HUD_PRINTTALK, "Survival mode now enabled. No more respawning allowed." );
		
		SetBuyzoneValue(1.0, BZ_MODE_ACTIVATED);
		
		//All players may already be dead
		CheckEndConditions();
	}
	
	int GetLivingPlayersCount()
	{
		int iLivingPlayers = 0;
		
		for( int iIndex = 1; iIndex <= g_Engine.maxClients; ++iIndex )
		{
			CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( iIndex );
			
			if( pPlayer !is null && pPlayer.IsAlive() )
				++iLivingPlayers;
		}
		
		return iLivingPlayers;
	}
	
	void CheckForLivingPlayers()
	{
		@m_pCheckForLivingPlayersFunc = null;
		
		//Check again, players might have been revived by a monster
		int iLivingPlayers = GetLivingPlayersCount();
		
		if( iLivingPlayers == 0 )
		{
			EndRound();
		}
	}

	/*
	*	 Can be used to end a round and force a retry to be used.
	*/
	void EndRound()
	{
		m_fGameEnded = true;
			
		if( !HasInfiniteRetries() && GetRetriesLeft() == 0 )
		{
			NextMapPlease();
		}
		else
		{
			StartEndVote();
		}
	}
	
	void StartEndVote()
	{
		Vote vote( "End Round vote", "Choose to retry the round or go to the next one.", m_flVoteTime, 50 );
		
		vote.SetYesText( "Retry" );
		vote.SetNoText( "Go to next map" );
		
		vote.SetVoteBlockedCallback( VoteBlocked( this.VoteBlocked ) );
		vote.SetVoteEndCallback( VoteEnd( this.VoteEnd ) );
		
		vote.Start();
	}
	
	void VoteBlocked( Vote@ pVote, float flTime )
	{
		//Schedule to vote again after the current vote has finished
		g_Scheduler.SetTimeout( @this, "StartEndVote", flTime - g_Engine.time );
	}
	
	void VoteEnd( Vote@ pVote, bool bResult, int iVoters )
	{
		if( !bResult )
		{
			NextMapPlease();
		}
		else
		{
			RetryUsed();
			//If 0 retries are allowed, don't print the number.
			if( !HasInfiniteRetries() &&  GetRetriesAllowed() > 0 )
			{
				TryAgain();
				string szAppend;
				
				snprintf( szAppend, " %1 %2 left.", GetRetriesLeft(), GetRetriesLeft() <= 1 ? "retry" : "retries" );
				g_PlayerFuncs.ClientPrintAll( HUD_PRINTTALK, szAppend );
			}
		}
	}
	
	void TryAgain()
	{
		g_EngineFuncs.CVarSetFloat( "mp_observer_mode", 0 );
		g_EngineFuncs.CVarSetFloat( "mp_observer_cyclic", 0 );
		SetBuyzoneValue(0.0, BZ_MODE_ACTIVATED);
		
		//Remove the respawn disabler
		if( m_pDisableRespawnFunc !is null )
		{
			g_Scheduler.RemoveTimer( m_pDisableRespawnFunc );
			@m_pDisableRespawnFunc = null;
		}
		
		if( m_pCheckForLivingPlayersFunc !is null )
		{
			g_Scheduler.RemoveTimer( m_pCheckForLivingPlayersFunc );
			@m_pCheckForLivingPlayersFunc = null;
		}
		
		m_State = SURVIVAL_INACTIVE;
		m_flActivationTime = 0;
		m_fGameEnded = false;
		
		@m_pDisableRespawnFunc = g_Scheduler.SetTimeout( @this, "DisableRespawn", 21.0 );
		
		// Bring them alive!
		// SetBuyzoneValue(1.0, BZ_MODE_SPAWN);
		// g_PlayerFuncs.RespawnAllPlayers( true, true );
	}
	
	void NextMapPlease()
	{
			string szMapName;
			const string szNext = m_pNextSurvivalMap.GetString();
			
			szMapName = szNext.IsEmpty() ? g_MapCycle.GetNextMap() : szNext;
			
			TriggerLevelChange( szMapName );
	}
	
	private void TriggerLevelChange( const string& in szMapName )
	{
		const int iDelay = int( m_flDelayBeforeChangeLevel );
		
		string szText;
		
		szText = "Changing map to \"" + szMapName + "\" in " + iDelay + " seconds.";
		
		g_PlayerFuncs.ClientPrintAll( HUD_PRINTTALK, szText );
		g_Scheduler.SetTimeout( @this, "PerformChangeLevel", m_flDelayBeforeChangeLevel, szMapName );
	}
	
	void PerformChangeLevel( string& in szMapName )
	{
		g_EngineFuncs.ChangeLevel( szMapName );
	}
	
	/*
	*	Checks if activation is needed.
	*	If Survival mode is set to activate here, returns true
	*	If Survival mode should not be activated, or is already active, returns false
	*/
	bool CheckIfActivationNeeded()
	{
		if( m_fIsEnabled && m_State == SURVIVAL_INACTIVE && g_PlayerFuncs.GetNumPlayers() >= m_iMinPlayersRequired && m_pDisableRespawnFunc is null )
		{
			m_State = SURVIVAL_ACTIVATING;
			
			SetBuyzoneValue(1.0, BZ_MODE_ENABLED);
			SetBuyzoneValue(m_flDelayBeforeStart, BZ_MODE_TIME);
			
			@m_pDisableRespawnFunc = g_Scheduler.SetTimeout( @this, "DisableRespawn", m_flDelayBeforeStart );
			
			const string szText = "Survival mode starting in " + int( m_flDelayBeforeStart ) + " seconds";
			
			//PRINTTALK won't work here, probably because it's too soon after joining
			g_PlayerFuncs.ClientPrintAll( HUD_PRINTCONSOLE, szText );
			
			return true;
		}
		
		return false;
	}
	
	private void DisplayTimeUntilActivation()
	{
		if( m_State != SURVIVAL_ACTIVATING )
			return;
			
		const float flTimeLeft = m_flActivationTime - g_Engine.time;	
		
		const string szText = "Survival mode starting in " + int( Math.Ceil( flTimeLeft ) ) + " seconds";
		
		//PRINTTALK won't work here, probably because it's too soon after joining
		g_PlayerFuncs.ClientPrintAll( HUD_PRINTCENTER, szText );
			
		g_Scheduler.SetTimeout( @this, "DisplayTimeUntilActivation", flTimeLeft < m_flDisplayTimeInterval ? flTimeLeft : m_flDisplayTimeInterval );
	}
	
	private HookReturnCode ClientPutInServer( CBasePlayer@ pPlayer )
	{
		CheckIfActivationNeeded();
		
		return HOOK_CONTINUE;
	}

	private HookReturnCode ClientDisconnect( CBasePlayer@ pPlayer )
	{
		/*if( g_PlayerFuncs.GetNumPlayers() < m_iMinPlayersRequired )
		{
			Reset();
		}
		else*/
		//{
			//Make sure game ends if nobody is alive anymore
			CheckEndConditions();
		//}
		
		return HOOK_CONTINUE;
	}
	
	private HookReturnCode PlayerKilled( CBasePlayer@ pPlayer, CBaseEntity@ pAttacker, int iGib )
	{
		CheckEndConditions();
		
		return HOOK_CONTINUE;
	}
	
	void CheckEndConditions()
	{
		if( IsActive && !m_fGameEnded && m_pCheckForLivingPlayersFunc is null && GetLivingPlayersCount() == 0 )
		{
			string szText = "No living players left";
			
			/*if( !HasInfiniteRetries() && GetRetriesLeft() == 0 )
				szText += "; starting end vote in " + int( m_flDelayBeforeEnd ) + " seconds";*/
			
			g_PlayerFuncs.ClientPrintAll( HUD_PRINTCENTER, szText );
			
			@m_pCheckForLivingPlayersFunc = g_Scheduler.SetTimeout( @this, "CheckForLivingPlayers", m_flDelayBeforeEnd );
		}
	}
	
	// Mode
	// 0 ==> set time before survival started
	// 1 ==> set boolean survival activated/deactivated ( see DisableRespawn() )
	// 2 ==> trigger SpawnAllPlayers
	// 3 ==> retries left
	// 4 ==> set boolean survival mode toggle (enable/disable) ( see CheckIfActivationNeeded() )
	// 5 ==> set next survival map
	// pev_iuser2 reserved for round number
	void SetBuyzoneValue(const float value, int mode = BZ_MODE_TIME, string svNextmap = "")
	{
		CBaseEntity@ pEnt = null;
		
		if(mode == 2)
		{
			@pEnt = g_EntityFuncs.FindEntityByClassname( pEnt, "func_buyzone" );
			if(@pEnt !is null) pEnt.pev.iuser4 = 1;					// trigger SpawnAllPlayers
		}
		else {
			while( ( @pEnt = g_EntityFuncs.FindEntityByClassname( pEnt, "func_buyzone" ) ) !is null )
			{
				if(mode == 0) { pEnt.pev.fuser1 = value; }				// time before survival started
				if(mode == 1) { pEnt.pev.iuser1 = int( value ); }		// is survival activated?
				if(mode == 3) { pEnt.pev.iuser3 = int( value ); }		// number retries left
				if(mode == 4) { pEnt.pev.skin = int( value ); }			// is survival mode enabled?
				if(mode == 5) { pEnt.pev.viewmodel = svNextmap; }		// next survival map?
			}
		}
	}
}