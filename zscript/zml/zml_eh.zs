/*

    What: Z-xtensible Markup Language Parser Event Handler
    Who: Sarah Blackburn
    When: 05/02/22

*/


class ZMLHandler : EventHandler
{
    string ZMLVersion;

    private actor SeedPawn;
    private bool Spawn;

    override void OnRegister()
    {
        // This mess creates the nice greeting ZML sends to the console.
        ZMLVersion = "0.1.2";
        string greeting = "Greetings! I am the Z-xtensible Markup Language Parser Event System, ";
        string vers = "version: ";
        int greetlen = string.Format("%s%s%s", greeting, vers, ZMLVersion).Length();
        string fullGreeting = string.Format("\n\n\cx%s\cc%s\cy%s\n\cx", greeting, vers, ZMLVersion);
        for (int i = 0; i < greetLen; i++)
            fullGreeting.AppendFormat("%s", "-");
        console.printf(fullGreeting);

        // Next we need to see if the level has a weed - if it does then ZML does nothing
        ThinkerIterator weedFinder = ThinkerIterator.Create("ZMLWeed");
        actor weedPawn = ZMLWeed(weedFinder.Next());
        if (weedPawn)
        {
            SeedPawn = null;
            Spawn = false;
            console.Printf("\cq\t\t - - ZML is disabled due to a weed in this level!");
        }
        else
        {
            // Ok, no weed, guess we better do our job then
            // Find out if there's a seed
            ThinkerIterator seedFinder = ThinkerIterator.Create("ZMLSeed");
            SeedPawn = ZMLSeed(seedFinder.Next());
            if (SeedPawn) // Yes, do nothing, WorldTick will initialize
                console.Printf("\cx\t\t - - ZML seed found!");
            else // Nope, WorldTick needs to spawn it too
                Spawn = true;
        }
    }

    override void WorldTick()
    {
        if (Spawn)
        {
            [Spawn, SeedPawn] = players[consoleplayer].mo.A_SpawnItemEx("ZMLSeed");
            if (Spawn && SeedPawn)
                console.Printf("\cx\t\t - - ZML seed created!"); 

            Spawn = false;
        }
    }

    /* - END OF METHODS - */
}

