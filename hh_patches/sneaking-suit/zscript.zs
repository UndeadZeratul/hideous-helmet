version "4.7"

class HHArmourTypeHandler_WAN_SneakingSuit : EventHandler
{
	override void WorldLoaded(WorldEvent e)
	{
		New("HHArmourType_WAN_SneakingSuitWorn");
		Destroy();
	}
}

class HHArmourType_WAN_SneakingSuitWorn : HHArmourType
{
	override string GetName()
	{
		return "WAN_SneakingSuit";
	}

	override string GetWornName()
	{
		return "WAN_SneakingSuitWorn";
	}

	override void DrawArmour(
		HDStatusBar sb,
		HDPickup hp,
		int hdFlags,
		int gzFlags
	)
	{
		let arm = WAN_SneakingSuitWorn(hp);
		let hdp = HDPlayerPawn(arm.Owner);
		Vector2 coords =
			(hdFlags & HDSB_AUTOMAP)? (4, 86) :
			(hdFlags & HDSB_MUGSHOT)? (((sb.HudLevel == 1)? -85 : -55), -4) :
			(0, -sb.mIndexFont.mFont.GetHeight() * 2);
		sb.DrawBar(
			"SNKSA0", "SNKSB0",
			arm.Durability, HDCONST_SNEAKINGSUIT,
			coords, -1, sb.SHADER_VERT,
			gzFlags
		);

		if (HHFunc.FindHelmet(hdp))
		{
			sb.DrawString(
				sb.pNewSmallFont,
				sb.FormatNumber(arm.Durability),
				coords + (10, -7),
				gzFlags | sb.DI_ITEM_CENTER | sb.DI_TEXT_ALIGN_RIGHT,
				Font.CR_DARKGRAY,
				scale: (0.5, 0.5)
			);
		}
	}
}
