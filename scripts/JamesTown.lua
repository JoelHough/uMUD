--********************************************************************
--Written for cs3505 spring2012 by: Team Exception: cody curtis, joel hough, bailey malone, james murdock, john wells.
--*********************************************************************

Containers =
{
	Room = "A place for my stuff. Four walls and a ceiling.",
		
	Town = 
	   {
	   "A small village with a coast line containing a shipyard and some seaweed.  There are a port for new arrivals from the atlantic and an airport for those coming from the west.",
	   House = "A simple house, four walls, a roof, and a door.",
	   Inn = "A cozy place for passing adventurers to sleep for the night.",
	   Blacksmith = "An old shack housing various weapons and armor",
	   Gunsmith = "A place to replenish your ammunitions and purchase new gunnery.",
	   Shop = "A shop that sells anything you might need" ,
	   Pub = "A brewery where all the local folk kick back some brews and spirits.  This is also where soul mates are acquainted... for the night at least ;)",
	   Bordello = "A hore house when one can purchase... pleasure? ;) You know the kind I mean ;-)",
	   },	
	Zones = 
	   {
	   "Other parts of the world. Zones may contain evils never before seen",
	   Forest = "The forests in the west cover a large expanse, and there are many unknown evils lurking in here",
	   Desert = "The arid desert of the south has become the final resting place for many unwary travellers.",
	   Tundra = "Frozen wasteland of the north. Only the hardiest adventurers survive the extreme temperatures",
	   Ocean = "The oceans of the east stretch beyond the bounds of the known world. Here you may climb abord an old Brittish ship and sail to the end of the world.",
	   Dungeon = "Looks like something out of 'Silence of the Lambs', you should probably stay away.",
	   },
}

Things =
{
	Player = 
	   {
	   "Your average, run of the mill adventurer.",
	   Necromancer = "Master of the Dark Arts. Their time spent hanging out in mausoleums has killed their interpersonal skills",
	   Barbarian = "Strong like bull. Smart like tractor.",
	   Knight = "Chivalrous and Gallant. Handsome and Brave. Cocky to boot",
	   Bard = "Singing, dancing, jolly, and annoying as hell",
	   },
	Vegetation = 
	   {
	   "The Flora of the world.",
	   Bush = "A prickly bush",
	   Tree = "A large oak tree",
	   Well = "A deep well. Contains the water supply for the entire town.",
	   },

	Weapon = 
	   {
	   "Stuff to kill things with",
	   Sword = "A sharp sword, finely crafted steel.",
	   Dirk = "A simple dagger",
	   Staff = "A long wooden staff used by martial artists and aspiring wizards.",
	   Axe = "A woodsman's axe, used for cutting trees. The edge is dull.",
	   Bow= "A string bow used for hunting game",
	   Mace= "A bludgeoning tool. Used for cracking open skulls",
	   Rifle = "Used for reaching out and touching someone from a great distance.",
	   },

	Clothing = 
	   {
	   "Stuff to wear so you aren't naked. It's cold out and you don't want to embarass yourself.",
	   Tunic= "Simple cloth tunic, no defensive capabilities. At least you look good.",
	   Leather= "Leather armor made from dried animal hide. Decent protection, but it's uglier than sin.",
	   Plate= "A solid iron plate. Offers good protection, but it's extremely heavy.",
	   Ringmail= "Armor made from many thousands of iron rings. Protects from slicing blows, but is weak against piercing attacks",
	   Kilt = "If you don't know what it is, you probably should'nt be wearing it!",
	   },
	Wildlife= 
	 {
	   "The Fauna of the world, some are cute and fuzzy, some not so much.",
	   Rabbit= "A cute fuzzy bunny, with big nasty pointy teeth",
	   Squirrel= "Small woodland creature. Rodent class.",
	   Deer= "Four-legged woodland creature commonly hunted for meat",
	   Cow= "Milk machine and steak producer",
	   Dog= "Man's best friend!",
	   Cat= "A pretentious, arrogant creature.",
	   Boar= "Sharp tusks, thick hide, and a bad attitude. Stay clear of it unless you want some extra holes in your stomach.",
	
	}
}



function test_world()
   print'Testing world building'
   for k, v in ipairs(Things) do
      print'Test'
      DEBUG(Things.k[1] .. " " .. v)

   end
end

test_world()