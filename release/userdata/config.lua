config =
{
	maximumCopyToBuildRatio		= 10,
	neverUseDecryptors		= false,

	-- Structure material reduction role bonus, in percent
	structureMatRoleBonus	= 1,

	-- Use facility material reductions when generating reports
	reportFacilityBonuses = false,

	-- Set this to true to enable reactions in the invention report
	enableReactionsInReport = false,

	-- Set this to true to enable reactions in shopping lists
	enableReactionsInShoppingLists = true,
	
	-- Set this to true to enable "auto-build" in shopping lists, which determines if an item should be built
	-- or purchased based on its market price vs. build price.
	enableAutoBuild = false,

	-- Set this to show surplus-adjusted expenditures (good for appraisal)
	showExpenditures = false,

	-- Set this to show build times in shopping lists
	showRecipeBuildTimes = false,

	-- Scrapmetal reprocessing efficiency, in percent
	scrapmetalReprocessingEfficiency = 55.0,

	-- Facility reaction material reduction bonus, in percent
	structureReactionMatReduction = 2.64,

	-- Facility manufacturing cost reduction bonus, in percent
	structureManufacturingCostReduction = 5.0,

	-- Facility invention cost reduction from rig, in percent
	structureInventionCostReductionRig = 21.0,

	-- Facility invention cost reduction role bonus, in percent
	structureInventionCostReductionRoleBonus = 3.0,

	-- Facility invention tax, in percent
	structureInventionTax = 15.0,

	-- Facility reaction tax, in percent
	structureReactionTax = 10.0,

	-- Facility manufacturing tax, in percent
	structureManufacturingTax = 5.0,

	-- Set this to include outputs of in-progress manufacturing and reaction jobs when collating on-hand inventory
	collateIncludeIndustryProducts = true,

	-- The market outlier filter is a 2-step filter that tries to ignore outlier sell orders on the market
	-- It has two phases:
	-- In the first phase, all orders with a price within "aggregationThreshold" percent are merged
	-- In the second phase, it inspects the lowest scanDepth merged orders, and the first one that exceeds "tolerance" percent of the total volume of those orders is used as the price
	marketOrderOutlierFilter =
	{
		enabled = true,
		aggregationThreshold = 0.1,
		scanDepth = 5,
		tolerance = 4,
	},

	-- List of solar systems to collate on-hand inventory from
	collateSystems =
	{
		"Jita",
	},

	-- List of hangars to ignore
	collateIgnoreHangars =
	{
		--"CorpSAG2",
	},

	-- System to invent in
	inventionSystem = "Jita",

	inventionSkills =
	{
		-- Skills with sciences (or rather, their datacores)
		["Datacore - Amarrian Starship Engineering"]	= 4,
		["Datacore - Caldari Starship Engineering"]	= 4,
		["Datacore - Core Subsystems Engineering"]	= 4,
		["Datacore - Defensive Subsystems Engineering"]	= 4,
		["Datacore - Electromagnetic Physics"]		= 4,
		["Datacore - Electronic Engineering"]		= 4,
		["Datacore - Gallentean Starship Engineering"]	= 4,
		["Datacore - Graviton Physics"]			= 4,
		["Datacore - High Energy Physics"]		= 4,
		["Datacore - Hydromagnetic Physics"]		= 4,
		["Datacore - Laser Physics"]			= 4,
		["Datacore - Mechanical Engineering"]		= 4,
		["Datacore - Minmatar Starship Engineering"]	= 4,
		["Datacore - Molecular Engineering"]		= 4,
		["Datacore - Nanite Engineering"]		= 4,
		["Datacore - Nuclear Physics"]			= 4,
		["Datacore - Offensive Subsystems Engineering"]	= 4,
		["Datacore - Plasma Physics"]			= 4,
		["Datacore - Propulsion Subsystems Engineering"]	= 4,
		["Datacore - Quantum Physics"]			= 4,
		["Datacore - Rocket Science"]			= 4,

		-- Racial encryption method associations
		["Amarr Encryption Methods"]			= 4,
		["Caldari Encryption Methods"]			= 4,
		["Gallente Encryption Methods"]			= 4,
		["Minmatar Encryption Methods"]			= 4,
		["Sleeper Encryption Methods"]			= 4,
	},

	priceOverrides =
	{
		--["Mechanical Parts"]			= 11900,
		--["Power Diagnostic System II"]	= 1250248,
		--["Accelerant Decryptor"]	= 550000,
	},

	blueprintLevels =
	{
		["Coercer"] =
		{
			me = 7,
			pe = 20,
		},
	},

	publicMarkets =
	{
		{
			regionID = "10000002",	-- The Forge
			locations =
			{
				{
					locationID = "60003760",	-- Jita
					locationType = "highsec",
				},
			},
		},
	},

	citadelMarkets =
	{
		-- See the thread for instructions on how to use this section
		--{
		--	locationID = "???",
		--	authCharacterName = "???"
		--},
	},

	-- Set an item to "true" to use alchemy instead of the normal reaction
	alchemy =
	{
		["Caesarium Cadmide"] = false,
		["Crystallite Alloy"] = false,
		["Dysporite"] = false,
		["Fernite Alloy"] = false,
		["Ferrofluid"] = false,
		["Fluxed Condensates"] = false,
		["Hexite"] = false,
		["Hyperflurite"] = false,
		["Neo Mercurite"] = false,
		["Platinum Technite"] = false,
		["Promethium Mercurite"] = false,
		["Prometium"] = false,
		["Rolled Tungsten Alloy"] = false,
		["Solerium"] = false,
		["Thulium Hafnite"] = false,
		["Titanium Chromide"] = false,
		["Vanadium Hafnite"] = false,
	},
}
