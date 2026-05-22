// This code is very hacky, might be a bit messy -dastrukar
// Original code taken from Hideous Destructor

class HHelmet : HDArmour
{
	int Cooldown;

	Default
	{
		-HDPickup.DROPTRANSLATION
		HDMagammo.MaxPerUnit HHCONST_HUDHELMET;
		HDMagammo.MagBulk ENC_HUDHELMET;
		Tag "$TAG_HHELMET";
		Inventory.Icon "HELMA0";
		Inventory.PickupMessage "$PICKUP_HHELMET";
		HDPickup.refid "hdh";
	}

	action void A_WearHelmet()
	{
		bool helpText = HDWeapon.CheckDoHelpText(self);
		Invoker.SyncAmount();
		int dbl = Invoker.Mags[Invoker.Mags.Size() - 1];
		//if holding use, cycle to next armour
		if (Player && Player.Cmd.Buttons & BT_USE) {
			Invoker.Mags.Insert(0, dbl);
			Invoker.Mags.Pop();
			Invoker.SyncAmount();
			return;
		}

		// Strip worn helmet on double click
		if (
			Invoker.Cooldown > 0 &&
			Self.FindInventory("HHelmetWorn")
		)
		{
			Self.DropInventory(Self.FindInventory("HHelmetWorn"));
			return;
		}
		if (HDPlayerPawn(Self).StripTime > 0) return;

		if (Self.FindInventory("HHelmetWorn"))
		{
			Invoker.Cooldown = 10;
			return;
		}

		//and finally put on the actual armour
		HDArmour.ArmourChangeEffect(Self);
		let worn = HHelmetWorn(GiveInventoryType("HHelmetWorn"));
		worn.Durability = dbl;
		Invoker.Amount--;
		Invoker.Mags.Pop();

		invoker.WearHelmetHelpText(self, dbl);

		invoker.SyncAmount();
	}

	override void ActualPickup(actor other, bool silent)
	{
		Cooldown = 0;
		if (!other) return;

		int durability = Mags[Mags.Size() - 1];
		//put on the armour right away
		if (
			other.Player &&
			other.Player.Cmd.Buttons & BT_USE &&
			!other.FindInventory("HHelmetWorn") &&
			HDPlayerPawn(other).StripTime == 0
		)
		{
			HDArmour.ArmourChangeEffect(other);
			let worn = HDArmourWorn(other.GiveInventoryType("HHelmetWorn"));
			worn.Durability = durability;
			Destroy();
			return;
		}
		if (!TryPickup(other)) return;
		HHelmet aaa = HHelmet(other.FindInventory("HHelmet"));
		aaa.SyncAmount();
		aaa.Mags.Insert(0, durability);
		aaa.Mags.Pop();
		other.A_StartSound(PickupSound, CHAN_AUTO);
		other.A_Log(string.Format("\cg%s", PickupMessage()), true);
	}

	override double GetMagBulk(int loaded)
	{
		return ENC_HUDHELMET;
	}

	void WearHelmetHelpText(actor wearer, double durability)
	{
		if (!HDWeapon.CheckDoHelpText(wearer)) return;
		string opinion = "";
		double qual = durability / maxperunit;
		if (qual < 0.2)     opinion = "$HHELMET_DUR20";
		else if(qual < 0.3) opinion = "$HHELMET_DUR30";
		else if(qual < 0.6) opinion = "$HHELMET_DUR60";
		else if(qual < 0.7) opinion = "$HHELMET_DUR70";
		else if(qual < 0.9) opinion = "$HHELMET_DUR90";
		wearer.A_Log(
			Stringtable.Localize("$HHELMET_PUTON")
			..gettag()
			..Stringtable.Localize("$HD_SENTENCEBREAK")
			..Stringtable.Localize(opinion)
		,true);
	}

	States
	{
		Spawn:
			HELM A -1;
			stop;
		Use:
			TNT1 A 0 A_WearHelmet();
			fail;
	}
}

class HHelmetWorn : HDArmourWorn
{
	int headshots;
	int bodyshots;
	int headDamage;
	int bodyDamage;

	Default {
		Tag "$TAG_HHELMET";

		HDPickup.RefId "hhw";
		HDPickup.WornLayer 0; // Don't use WornLayer to handle removing helmet
		HDPickup.bulk ENC_HUDHELMET * 0.1;

		HDArmourWorn.armoursprite "HELMA0";
		HDARmourWorn.armourback "HELMB0";

		HDArmourWorn.durability HHCONST_HUDHELMET;
	}

	override double RestrictSpeed(double speedcap){
		return speedcap;
	}

	override void DrawHudStuff(
		hdstatusbar sb,
		hdplayerpawn hpl,
		int hdFlags,
		int gzFlags
	)
	{
		// Drawing helmet on the HUD is handled in statusbar.zs for layering reasons.
		bool d = hh_durabilitytop;

		Vector2 helmpos =
			(hdFlags & HDSB_AUTOMAP)? (24, 86) :
			(hdFlags & HDSB_MUGSHOT)? (((sb.HudLevel == 1) ? -85 : -55), -18) :
			(0, -sb.mIndexFont.mFont.GetHeight() * 2 - 14);
		Vector2 coords = (helmPos.x, helmPos.y + hh_helmetoffsety);

		sb.DrawBar(
			armoursprite, armourback,
			durability, default.durability,
			coords, -1, sb.SHADER_VERT,
			gzFlags
		);
		sb.DrawString(
			sb.pNewSmallFont, sb.FormatNumber(durability),
			coords + (10, (d)? -14 : -7),
			gzFlags | sb.DI_ITEM_CENTER | sb.DI_TEXT_ALIGN_RIGHT,
			Font.CR_DARKGRAY,
			scale:(0.5,0.5)
		);
	}

	override Inventory CreateTossable(int amt)
	{
		if (HDPlayerPawn(Owner) && HDPlayerPawn(Owner).striptime > 0)
			return null;

		PrintHelmetDebug();

		//armour sometimes crumbles into dust
		if (Durability < Random(1, 5))
		{
			for (int i = 0; i < 10; i++)
			{
				Actor aaa = Spawn("WallChunk", Owner.Pos + (0, 0, Owner.Height - 24), ALLOW_REPLACE);
				Vector3 offsPos = (FRandom(-12, 12), FRandom(-12, 12), FRandom(-16, 4));
				aaa.SetOrigin(aaa.Pos + offsPos, false);
				aaa.Vel = Owner.Vel + offsPos * FRandom(0.3, 0.6);
				aaa.Scale *= FRandom(0.8 ,2.);
			}
			BreakSelf();
			return null;
		}

		//finally actually take off the armour
		string tosstype = GetClassName();
		tossType = tossType.left(tossType.length() - 4);
		let tossed = HDArmour(Owner.Spawn(
			tossType,
			(Owner.Pos.x, Owner.Pos.y, Owner.Pos.z + Owner.Height - 20),
			ALLOW_REPLACE
		));
		tossed.Mags.Clear();
		tossed.Mags.Push(Durability);
		tossed.Amount = 1;

		HDArmour.ArmourChangeEffect(Owner);
		Owner.A_Log(Stringtable.Localize("$HHELMET_REMOVE"), true);
		Destroy();
		return tossed;
	}

	// For convenience
	void BreakSelf()
	{
		PrintHelmetDebug();
		Owner.A_StartSound("helmet/break", CHAN_BODY);
		HDArmour.ArmourChangeEffect(Owner);
		Destroy();
	}

	// Handle damage
	override int, name, int, double, int, int, int HandleDamage(
		int damage,
		name mod,
		int flags,
		actor inflictor,
		actor source,
		double toWound,
		int toBurn,
		int toStun,
		int toBreak
	)
	{
		// "I don't really know how to get this working with the damage system here,
		//	so I'll just do it the really dumb and simple way."
		bool damageTaken;
		int dmgDiff = Durability;

		float hDefense = 1.3;
		float durabilityDmg = Max(0, damage >> Random(3,5));

		// I don't think I need this for now.
		/*if(
			mod=="teeth"||
			mod=="claws"||
			mod=="bite"||
			mod=="scratch"||
			mod=="nails"||
			mod=="natural"
		){
			damage/=h_defense;
			helmet.durability -= durability_dmg;
			damagetaken = true;
		}else*/ if (
			mod == "thermal" ||
			mod == "fire" ||
			mod == "ice" ||
			mod == "heat" ||
			mod == "cold" ||
			mod == "plasma" ||
			mod == "burning"
		)
		{
			// ngl, i don't actually know how this works.
			// but i'm including it anyways, just in case
			if(random(0,5))
			{
				damage-=10;
				Durability -= durabilityDmg;
				damageTaken = true;
			}
		}
		else if (
			mod == "cutting" ||
			mod == "slashing" ||
			mod == "piercing"
		)
		{
			// Stuff that armour shouldn't block, but also take damage from
			Durability -= durabilityDmg;
			damageTaken = true;
		}
		else if (
			mod != "bleedout" &&
			mod != "internal" &&
			mod != "invisiblebleedout" &&
			mod != "maxhpdrain" &&
			mod != "electro" &&
			mod != "electrical" &&
			mod != "lightning" &&
			mod != "bolt" &&
			mod != "balefire" &&
			mod != "hellfire" &&
			mod != "unholy" &&
			mod != "staples" &&
			mod != "falling" &&
			mod != "drowning" &&
			mod != "slime" &&
			mod != "bashing" &&
			mod != "Melee"
		)
		{
			// Basically any other damage type that armour should block
			Durability -= durabilityDmg;
			damageTaken = true;
		}
		//if (damagetaken && hh_debug) { DoHelmetDebug(dmgdiff-durability, mod); }
		if (durability < 1) BreakSelf();

		return damage, mod, flags, towound, toburn, tostun, tobreak;
	}

	override double, double OnBulletImpact(
		HDBulletActor bullet,
		double pen,
		double penShell,
		double hitAngle,
		double deemedWidth,
		vector3 hitPos,
		vector3 vu,
		bool hitActorIsTall
	)
	{
		let hitActor = Owner;
		if (!hitActor) return 0, 0;

		let hdmb = HDMobBase(hitActor);
		let hdp = HDPlayerPawn(hitActor);
		
		// If standing right over an incap'd victim, bypass armour
		if (
			bullet.Pitch > 80 &&
			(
				(hdp && hdp.Incapacitated) ||
				(
					hdmb &&
					hdmb.Frame >= hdmb.DownedFrame &&
					hdmb.InStateSequence(hdmb.CurState, hdmb.ResolveState("falldown"))
				)
			)
		) return pen, penShell;

		double hitHeight = hitActorIsTall? ((hitPos.z - hitActor.Pos.z) / hitActor.Height) : 0.5;

		// i mean, do you really expect a damaged helmet to block damage as well as it should?
		float sucks = Durability * FRandom(0.4, 1.8);
		float helmetShell = (sucks > 25)? FRandom(15, 20) : FRandom(5, 10);

		if (hh_debug) Console.PrintF(hitActor.GetClassName().."  helmet sucks:  "..sucks);

		//poorer armour on limbs and torso
		//sometimes slip through a gap
		int crackseed=int(level.time+angle)&(1|2|4|8|16|32);
		int gotHitLocation=GetHitLocation(bullet,hitactor,hitheight,hitangle,crackseed);

		//mutator cvar limits coverage to torso
		// if(
		// 	hd_armourvest
		// 	&&gotHitLocation!=ARMOUR_TORSO
		// )return pen,penshell;

		string debugText;

		switch (gotHitLocation) {
			case ARMOUR_FACE:
				//face: assume resistant but not perfect visor
				helmetShell *= frandom(0.1,0.9);
				if (hh_debug) debugText = "HEADSHOT.";
				headshots++;
				break;
			case ARMOUR_HEAD:
				//head: thinner material required
				if(hdmb && !hdmb.bHASHELMET)
				{
					helmetShell = -1;
				}
				else
				{
					helmetShell = min(helmetShell, frandom(10, 20));
				}

				if (hh_debug) debugText = "HEADSHOT.";
				headshots++;
				break;
			case ARMOUR_ARMS:
				//arms: don't protect the limbs
				helmetShell = 0;
				bodyshots++;
				break;
			case ARMOUR_LEGS:
				//legs: don't protect the limbs
				helmetShell = 0;
				if (hh_debug) debugText = "leg shot.";
				bodyshots++;
				break;
			case ARMOUR_TORSO:
			default:
				// imagine that the helmet has a magical net
				// also, enemies don't always aim for your "head" anyways, so it's kind of pointless for it to just protect the "head"
				helmetShell *= 0.5;
				bodyshots++;
				if (hh_debug) debugText = "body shot.";
				break;
		}


		if (debugText) Console.PrintF(debugText);

		// durability stuff
		if (helmetShell > 0)
		{
			// helmet takes some damage
			int ddd = Random(-1, (int(Min(pen, helmetShell) * bullet.Stamina) * 0.0005));

			if (hh_debug) Console.PrintF("Random(Min("..pen..", "..helmetShell..") * "..bullet.Stamina.." * 0.0005) = "..ddd);

			if (ddd < 1)
			{
				bool penetrated = (pen > helmetShell);
				if (gotHitLocation == ARMOUR_FACE || gotHitLocation == ARMOUR_HEAD)
				{
					if (
						penetrated ||
						FRandom(0, 1) <= 0.25
					)
					{
						// 25% chance to damage the helmet if shot in the face
						ddd = 1;
					}
				}
				else if (
					penetrated &&
					FRandom(0, 1) <= 0.50
				)
				{
					// 50% chance to not damage the helmet if you got penetrated in the chest
					ddd = 1;
				}
			}
			if (ddd > 0)
			{
				Durability -= ddd;
				if (hh_debug) Console.PrintF("helmet took "..ddd.." damage");

				if (gotHitLocation == ARMOUR_FACE || gotHitLocation == ARMOUR_HEAD)
				{
					headDamage += ddd;
				}
				else
				{
					bodyDamage += ddd;
				}
			}
		}
		else if (hh_debug) Console.PrintF("missed the helmet!");

		if (hh_debug) Console.PrintF(hitActor.getclassname().."  helmet resistance:  "..helmetShell);
		penShell += helmetShell;


		//add some knockback even when target unhurt
		if (
			penShell > pen &&
			hitActor.Health > 0 &&
			hitActorIsTall
		) {
			hitActor.Vel += vu * 0.001 * hitHeight * mass;
			if (
				hdp &&
				!hdp.Incapacitated
			)
			{
				hdp.WepBobRecoil2 += (FRandom(-5, 5), FRandom(2.5, 4)) * 0.01 * hitHeight * mass;
				hdp.PlayRunning();
			}
			else if (Random(0, 255) < hitActor.PainChance)
			{
				HDMobBase.ForcePain(hitActor);
			}
		}


		// Helmet can't take it anymore :[
		if (Durability < 1) BreakSelf();

		return pen, penshell;
	}

	// Sometimes, reading through the debug log is not worth it
	void PrintHelmetDebug()
	{
		if (hh_debug) Console.PrintF("Helmet stats:\n Headshots: "..headshots.."("..headdamage..")\n Bodyshots: "..bodyshots.."("..bodydamage..")");
	}

	void DoHelmetDebug(
		int actualDamage,
		name mod
	)
	{
		A_Log("damage before: "..damage);
		A_Log("helmet took "..actualDamage.." "..mod.." damage");
		A_Log(string.format("damage %d", damage));
	}
}
