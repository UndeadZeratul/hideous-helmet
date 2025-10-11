// The main helmet spawner handler
class HHHelmetSpawner : EventHandler
{
	transient Array<HHSpawnType> SpawnTypes;

	override void WorldLoaded(WorldEvent e)
	{
		New("HHSpawnType_Default");
		SpawnTypes.Clear();
	}

	override void WorldThingSpawned(WorldEvent e)
	{
		if (!e.Thing) return;
		Actor T = e.Thing;

		// Find anything inheriting from HHSpawnType and use it :]
		if (SpawnTypes.Size() <= 0)
		{
			let ti = ThinkerIterator.Create("HHSpawnType", Thinker.STAT_DEFAULT);
			HHSpawnType hhst;
			while (hhst = HHSpawnType(ti.next()))
			{
				SpawnTypes.Push(hhst);
			}
		}

		foreach (spawnType : SpawnTypes)
		{
			if (spawnType.CheckConditions(T, Level.Time))
			{
				spawnType.SpawnHelmet(T);
				return;
			}
		}
	}

	// Moved to a function for convenience
	static void SummonHelmet(int durability, Vector3 pos)
	{
		let helm = HHelmet(Actor.Spawn("HHelmet", pos, ALLOW_REPLACE));

		helm.Vel.x += FRandom(-2, 2);
		helm.Vel.y += FRandom(-2, 2);
		helm.Vel.z += FRandom(1, 3);

		helm.Mags.Clear();
		helm.Mags.Push(durability);
		helm.SyncAmount();
	}
}
