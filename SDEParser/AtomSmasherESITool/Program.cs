using ESIHandler;
using Microsoft.Win32;
using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Net;
using System.Security.Cryptography;
using System.Text;
using System.Threading;

namespace AtomSmasherESITool
{
    public class MarketHistoryItem
    {
        public double average { get; set; }
        public string date { get; set; }
        public double highest { get; set; }
        public double lowest { get; set; }
        public long order_count { get; set; }
        public long volume { get; set; }
    }

    public class ItemName
    {
        public long itemID { get; set; }
        public string itemName { get; set; }
    }

    public class CharacterAsset
    {
        public bool is_blueprint_copy { get; set; }
        public bool is_singleton { get; set; }
        public long item_id { get; set; }
        public string location_flag { get; set; }
        public long location_id { get; set; }
        public string location_type { get; set; }
        public int quantity { get; set; }
        public int type_id { get; set; }
    }

    public class CharacterIndustryJob
    {
        public int activity_id { get; set; }
        public long blueprint_id { get; set; }
        public long blueprint_location_id { get; set; }
        public int blueprint_type_id { get; set; }
        public int completed_character_id { get; set; }
        public string completed_date { get; set; }
        public double cost { get; set; }
        public int duration { get; set; }
        public string end_date { get; set; }
        public long facility_id { get; set; }
        public int installer_id { get; set; }
        public int job_id { get; set; }
        public int licensed_runs { get; set; }
        public long output_location_id { get; set; }
        public string pause_date { get; set; }
        public double probability { get; set; }
        public int product_type_id { get; set; }
        public int runs { get; set; }
        public string start_date { get; set; }
        public long station_id { get; set; }
        public string status { get; set; }
        public int successful_runs { get; set; }
    }

    public class ContractInfo
    {
        public int acceptor_id { get; set; }
        public int assignee_id { get; set; }
        public string availability { get; set; }
        public double buyout { get; set; }
        public double collateral { get; set; }
        public int contract_id { get; set; }
        public string date_accepted { get; set; }
        public string date_completed { get; set; }
        public string date_expired { get; set; }
        public string date_issued { get; set; }
        public int days_to_complete { get; set; }
        public long end_location_id { get; set; }
        public bool for_corporation { get; set; }
        public int issuer_corporation_id { get; set; }
        public int issuer_id { get; set; }
        public double price { get; set; }
        public double reward { get; set; }
        public long start_location_id { get; set; }
        public string status { get; set; }
        public string title { get; set; }
        public string type { get; set; }
        public double volume { get; set; }

    }

    public class ContractItem
    {
        public bool is_included { get; set; }
        public bool is_singleton { get; set; }
        public int quantity { get; set; }
        public int raw_quantity { get; set; }
        public long record_id { get; set; }
        public int type_id { get; set; }
    }

    public class CharacterPublicInfo
    {
        public int ancestry_id { get; set; }
        public string birthday { get; set; }
        public int bloodline_id { get; set; }
        public long corporation_id { get; set; }
        public string description { get; set; }
        public string gender { get; set; }
        public string name { get; set; }
        public int race_id { get; set; }
        public double security_status { get; set; }
    }

    public class CharacterRoles
    {
        public string[] roles { get; set; }
        public string[] roles_at_base { get; set; }
        public string[] roles_at_hq { get; set; }
        public string[] roles_at_other { get; set; }
    }

    public class Coordinate
    {
        public double x { get; set; }
        public double y { get; set; }
        public double z { get; set; }
    }

    public class StructureInfo
    {
        public string name { get; set; }
        public int owner_id { get; set; }
        public Coordinate position { get; set; }
        public long solar_system_id { get; set; }
        public int type_id { get; set; }
    }

    public class LocationInfo
    {
        public long LocationID { get; set; }
        public string Name { get; set; }
        public long OwnerID { get; set; }
        public long SolarSystemID { get; set; }
        public string SolarSystemName { get; set; }
        public int TypeID { get; set; }
    }

    public class MarketPrice
    {
        public double adjusted_price { get; set; }
        public double average_price { get; set; }
        public long type_id { get; set; }
    }

    public class IndustrySystemCostIndex
    {
        public string activity { get; set; }
        public double cost_index { get; set; }
    }

    public class IndustrySystem
    {
        public IndustrySystemCostIndex[] cost_indices { get; set; }
        public int solar_system_id { get; set; }
    }

    public class PublicMarketOrder
    {
        public int duration { get; set; }
        public bool is_buy_order { get; set; }
        public string issued { get; set; }
        public long location_id { get; set; }
        public int min_volume { get; set; }
        public long order_id { get; set; }
        public double price { get; set; }
        public string range { get; set; }
        public int system_id { get; set; }
        public int type_id { get; set; }
        public int volume_remain { get; set; }
        public int volume_total { get; set; }
    }

    public struct CharacterizedLocation
    {
        public long location_id;
        public string location_type;
    }

    public class PublicMarketConfig
    {
        public long region_id { get; set; }
        public CharacterizedLocation[] characterized_locations { get; set; }
    }

    public class CitadelMarketConfig
    {
        public CharacterizedLocation characterized_location { get; set; }
        public string auth_character_name { get; set; }
    }

    public class MarketConfig
    {
        public PublicMarketConfig[] public_markets { get; set; }
        public CitadelMarketConfig[] citadel_markets { get; set; }
    }

    public struct XYZCoordinate
    {
        public double x { get; set; }
        public double y { get; set; }
        public double z { get; set; }
    }

    public class NPCStation
    {
        public int celestialIndex { get; set; }
        public int operationID { get; set; }
        public long orbitID { get; set; }
        public int orbitIndex { get; set; }
        public long ownerID { get; set; }
        public XYZCoordinate position { get; set; }
        public double reprocessingEfficiency { get; set; }
        public double reprocessingHangarFlag { get; set; }
        public double reprocessingStationsTake { get; set; }
        public long solarSystemID { get; set; }
        public int typeID { get; set; }
        public bool useOperationName { get; set; }
    }

    public struct NPCCorporationDivision
    {
        public int divisionNumber { get; set; }
        public long leaderID { get; set; }
        public int size { get; set; }
    }

    public class NPCCorporation
    {
        public int[] allowedMemberRaces { get; set; }
        public long ceoID { get; set; }
        public Dictionary<int, double> corporationTrades { get; set; }
        public bool deleted { get; set; }
        public Dictionary<string, string> description { get; set; }
        public Dictionary<int, NPCCorporationDivision> divisions { get; set; }
        public long enemyID { get; set; }
        public Dictionary<long, double> exchangeRates { get; set; }
        public char extent { get; set; }
        public long factionID { get; set; }
        public long friendID { get; set; }
        public bool hasPlayerPersonnelManager { get; set; }
        public int iconID { get; set; }
        public int initialPrice { get; set; }
        public Dictionary<long, int> investors { get; set; }
        public int[] lpOfferTables { get; set; }
        public int mainActivityID { get; set; }
        public int memberLimit { get; set; }
        public double minSecurity { get; set; }
        public int minimumJoinStanding { get; set; }
        public Dictionary<string, string> name { get; set; }
        public int raceID { get; set; }
        public int secondaryActivityID { get; set; }
        public bool sendCharTerminationMessage { get; set; }
        public long shares { get; set; }
        public char size { get; set; }
        public double sizeFactor { get; set; }
        public long solarSystemID { get; set; }
        public long stationID { get; set; }
        public double taxRate { get; set; }
        public string tickerName { get; set; }
        public bool uniqueName { get; set; }
    }

    public class Faction
    {
        public long corporationID { get; set; }
        public Dictionary<string, string> description { get; set; }
        public string flatLogo { get; set; }
        public string flatLogoWithName { get; set; }
        public int iconID { get; set; }
        public int[] memberRaces { get; set; }
        public long militiaCorporationID { get; set; }
        public Dictionary<string, string> name { get; set; }
        public Dictionary<string, string> shortDescription { get; set; }
        public double sizeFactor { get; set; }
        public long solarSystemID { get; set; }
        public bool uniqueName { get; set; }
    }

    public class StationOperation
    {
        public int activityID { get; set; }
        public double border { get; set; }
        public double corridor { get; set; }
        public Dictionary<string, string> description { get; set; }
        public double fringe { get; set; }
        public double hub { get; set; }
        public double manufacturingFactor { get; set; }
        public Dictionary<string, string> operationName { get; set; }
        public double ratio { get; set; }
        public double researchFactor { get; set; }
        public int[] services { get; set; }
        public Dictionary<int, int> stationTypes { get; set; }
    }

    class Program
    {
        const string AtomSmasherProtocol = "eveauth-atomsmasher";
        const string AtomSmasherClientID = "56d8d11f77f84bd88a3047a1882dff35";
        const string AtomSmasherCallbackURI = AtomSmasherProtocol + "://go/";
        const string AtomSmasherPendingAuthPath = "data/auth_pending.txt";
        const string AtomSmasherTokenPath = "data/auth_token.txt";
        const string AtomSmasherLocationCachePath = "data/cache/locations.dat";
        const string AtomSmasherApplicationName = "Atom Smasher";
        const int AtomSmasherLocationCacheVersion = 3;

        const string ESIPrefix = "https://esi.evetech.net/latest";

        static string GetExpectedPath()
        {
            return System.Reflection.Assembly.GetExecutingAssembly().Location;
        }

        static IEnumerable<string> GetDefaultScopes()
        {
            List<string> scopes = new List<string>();

            scopes.Add("esi-universe.read_structures.v1");
            scopes.Add("esi-characters.read_corporation_roles.v1");
            scopes.Add("esi-assets.read_assets.v1");
            scopes.Add("esi-assets.read_corporation_assets.v1");
            scopes.Add("esi-industry.read_character_jobs.v1");
            scopes.Add("esi-industry.read_corporation_jobs.v1");
            scopes.Add("esi-markets.structure_markets.v1");
            scopes.Add("esi-contracts.read_character_contracts.v1");
            scopes.Add("esi-contracts.read_corporation_contracts.v1");

            return scopes;
        }

        static string GetRootDirectory()
        {
            string myPath = GetExpectedPath();
            for (int i = 0; i < 5; i++)
                myPath = Path.GetDirectoryName(myPath);

            return myPath;
        }

        static bool CheckRegistryKey()
        {
            string commandLine = "\"" + GetExpectedPath() + "\" \"Install\" \"%1\"";

            object handlerPath = Registry.GetValue(@"HKEY_CLASSES_ROOT\eveauth-atomsmasher\shell\open\command\", "", null);

            if (handlerPath == null || handlerPath.GetType() != typeof(string) || (string)handlerPath != commandLine)
            {
                using (StreamWriter sw = new StreamWriter("uri_handler_install.reg"))
                {
                    sw.WriteLine("Windows Registry Editor Version 5.00");
                    sw.WriteLine();
                    sw.WriteLine("[HKEY_CLASSES_ROOT\\" + AtomSmasherProtocol + "]");
                    sw.WriteLine("@=\"URL:Atom Smasher Auth Handler\"");
                    sw.WriteLine("\"URL Protocol\"=\"\"");
                    sw.WriteLine();
                    sw.WriteLine("[HKEY_CLASSES_ROOT\\" + AtomSmasherProtocol + "\\shell]");
                    sw.WriteLine();
                    sw.WriteLine("[HKEY_CLASSES_ROOT\\" + AtomSmasherProtocol + "\\shell\\open]");
                    sw.WriteLine();
                    sw.WriteLine("[HKEY_CLASSES_ROOT\\" + AtomSmasherProtocol + "\\shell\\open\\command]");
                    sw.WriteLine("@=\"" + commandLine.Replace("\\", "\\\\").Replace("\"", "\\\"") + "\"");
                }

                Console.WriteLine("Atom Smasher's URI handler isn't registered, or is set to the wrong path.");
                Console.WriteLine("I've outputted a 'uri_handler_install.reg' file.  Run it, then try authenticating again.");
                Console.WriteLine();
                Console.WriteLine("To uninstall the URI handler later, run 'uri_handler_uninstall.reg'.");
                Console.WriteLine();
                CloseoutCountdown(10);

                return false;
            }

            return true;
        }

        static string EncodeUri(string baseUri, IEnumerable<KeyValuePair<string, string>> parameters)
        {
            StringBuilder sb = new StringBuilder();

            sb.Append(baseUri);
            sb.Append("?");

            bool first = true;
            foreach (KeyValuePair<string, string> param in parameters)
            {
                if (first)
                    first = false;
                else
                    sb.Append("&");

                sb.Append(WebUtility.UrlEncode(param.Key));
                sb.Append("=");
                sb.Append(WebUtility.UrlEncode(param.Value));
            }

            return sb.ToString();
        }

        static string UrlSafeBase64Encode(byte[] bytes)
        {
            string result = Convert.ToBase64String(bytes, Base64FormattingOptions.None);
            int paddingOffset = result.IndexOf('=');
            if (paddingOffset >= 0)
                result = result.Substring(0, paddingOffset);

            result = result.Replace('+', '-').Replace('/', '_');

            return result;
        }

        static byte[] UrlSafeBase64Decode(string str)
        {
            str = str.Replace('_', '/').Replace('-', '+');
            while (str.Length % 4 > 0)
                str += "=";

            return Convert.FromBase64String(str);
        }

        static void GetSSOParameters(IEnumerable<string> requestedScopes, out byte[] secureKeyOut, out string stateOut, out string uriOut)
        {
            // https://docs.esi.evetech.net/docs/sso/native_sso_flow.html

            string scopesList;

            {
                StringBuilder scopesListSB = new StringBuilder();
                bool first = true;
                foreach (string scope in requestedScopes)
                {
                    if (first)
                        first = false;
                    else
                        scopesListSB.Append(" ");

                    scopesListSB.Append(scope);
                }

                scopesList = scopesListSB.ToString();
            }

            RNGCryptoServiceProvider rng = new RNGCryptoServiceProvider();

            byte[] randomKey = new byte[32];
            rng.GetBytes(randomKey);

            byte[] stateKey = new byte[32];
            rng.GetBytes(stateKey);

            string base64Key = UrlSafeBase64Encode(randomKey);
            SHA256 sha256 = SHA256.Create();

            byte[] challenge = sha256.ComputeHash(Encoding.ASCII.GetBytes(base64Key));

            List<KeyValuePair<string, string>> uriParameters = new List<KeyValuePair<string, string>>();

            uriParameters.Add(new KeyValuePair<string, string>("response_type", "code"));
            uriParameters.Add(new KeyValuePair<string, string>("redirect_uri", AtomSmasherCallbackURI));
            uriParameters.Add(new KeyValuePair<string, string>("client_id", AtomSmasherClientID));
            uriParameters.Add(new KeyValuePair<string, string>("scope", scopesList));
            uriParameters.Add(new KeyValuePair<string, string>("code_challenge", UrlSafeBase64Encode(challenge)));
            uriParameters.Add(new KeyValuePair<string, string>("code_challenge_method", "S256"));
            uriParameters.Add(new KeyValuePair<string, string>("state", UrlSafeBase64Encode(stateKey)));

            secureKeyOut = randomKey;
            stateOut = UrlSafeBase64Encode(stateKey);
            uriOut = EncodeUri("http://login.eveonline.com/v2/oauth/authorize/", uriParameters);
        }

        static MarketConfig ReadMarketConfig(string path)
        {
            MarketConfig market = new MarketConfig();

            using (StreamReader sr = new StreamReader(path))
            {
                int numPublicMarkets = int.Parse(sr.ReadLine());

                List<PublicMarketConfig> pubMarkets = new List<PublicMarketConfig>();
                for (int i = 0; i < numPublicMarkets; i++)
                {
                    PublicMarketConfig pubMarket = new PublicMarketConfig();

                    List<CharacterizedLocation> locations = new List<CharacterizedLocation>();
                    pubMarket.region_id = long.Parse(sr.ReadLine());
                    int numLocations = int.Parse(sr.ReadLine());
                    for (int j = 0; j < numLocations; j++)
                    {
                        CharacterizedLocation cl;
                        cl.location_id = long.Parse(sr.ReadLine());
                        cl.location_type = sr.ReadLine();
                        locations.Add(cl);
                    }

                    pubMarket.characterized_locations = locations.ToArray();

                    pubMarkets.Add(pubMarket);
                }

                market.public_markets = pubMarkets.ToArray();

                int numCitMarkets = int.Parse(sr.ReadLine());

                List<CitadelMarketConfig> citMarkets = new List<CitadelMarketConfig>();
                for (int i = 0; i < numCitMarkets; i++)
                {
                    CitadelMarketConfig citMarket = new CitadelMarketConfig();

                    citMarket.auth_character_name = sr.ReadLine();

                    CharacterizedLocation cl;
                    cl.location_id = long.Parse(sr.ReadLine());
                    cl.location_type = sr.ReadLine();

                    citMarket.characterized_location = cl;

                    citMarkets.Add(citMarket);
                }

                market.citadel_markets = citMarkets.ToArray();
            }

            return market;
        }

        static Dictionary<long, LocationInfo> LoadLocationCache()
        {
            Dictionary<long, LocationInfo> cache = new Dictionary<long, LocationInfo>();

            string cachePath = GetRootDirectory() + "/" + AtomSmasherLocationCachePath;

            if (!File.Exists(cachePath))
                return cache;

            using (StreamReader sr = new StreamReader(cachePath))
            {
                int version = int.Parse(sr.ReadLine());
                if (version != AtomSmasherLocationCacheVersion)
                    return cache;

                int numLocations = int.Parse(sr.ReadLine());

                for (int i = 0; i < numLocations; i++)
                {
                    long locationID = long.Parse(sr.ReadLine());

                    LocationInfo li = new LocationInfo();
                    li.LocationID = locationID;
                    li.Name = sr.ReadLine();
                    li.OwnerID = long.Parse(sr.ReadLine());
                    li.SolarSystemID = long.Parse(sr.ReadLine());
                    li.SolarSystemName = sr.ReadLine();
                    li.TypeID = int.Parse(sr.ReadLine());
                    cache[locationID] = li;
                }
            }

            return cache;
        }

        static void SaveLocationCache(IReadOnlyDictionary<long, LocationInfo> cache)
        {
            using (StreamWriter sw = new StreamWriter(GetRootDirectory() + "/" + AtomSmasherLocationCachePath))
            {
                sw.WriteLine(AtomSmasherLocationCacheVersion);
                sw.WriteLine(cache.Count);

                foreach (LocationInfo li in cache.Values)
                {
                    sw.WriteLine(li.LocationID);
                    sw.WriteLine(li.Name);
                    sw.WriteLine(li.OwnerID);
                    sw.WriteLine(li.SolarSystemID);
                    sw.WriteLine(li.SolarSystemName);
                    sw.WriteLine(li.TypeID);
                }
            }
        }

        static Dictionary<long, LocationInfo> ResolveLocations(Handler esiHandler, IReadOnlyDictionary<long, long> assetParent, IReadOnlyDictionary<long, long> locationSeenOnCharacter)
        {
            Dictionary<long, LocationInfo> locationCache = LoadLocationCache();

            HashSet<long> unknownLocations = new HashSet<long>();
            Dictionary<long, long> unknownLocationCharacterID = new Dictionary<long, long>();


            foreach (long locationID in locationSeenOnCharacter.Keys)
            {
                long topLevelLocationID = ResolveTopLevelLocation(locationID, assetParent);

                if (locationCache.ContainsKey(topLevelLocationID))
                    continue;

                unknownLocations.Add(topLevelLocationID);
                if (!unknownLocationCharacterID.ContainsKey(topLevelLocationID))
                {
                    long characterID = 0;
                    if (!locationSeenOnCharacter.TryGetValue(topLevelLocationID, out characterID))
                        characterID = locationSeenOnCharacter[locationID];

                    unknownLocationCharacterID[topLevelLocationID] = characterID;
                }
            }

            if (unknownLocations.Count > 0)
            {
                string rootDir = GetRootDirectory();

                Console.WriteLine("Attempting to identify " + unknownLocations.Count.ToString() + " unknown locations...");

                Console.WriteLine("    Loading solar systems...");

                Dictionary<long, string> solarSystemNames = new Dictionary<long, string>();
                using (StreamReader sr = new StreamReader(GetRootDirectory() + "/data/cache/solar_systems.dat"))
                {
                    while (!sr.EndOfStream)
                    {
                        string line = sr.ReadLine();
                        string[] tokens = line.Split('\t');

                        if (tokens.Length == 2)
                            solarSystemNames[long.Parse(tokens[0])] = tokens[1];
                    }
                }

                Console.WriteLine("    Loading NPC corporations...");

                Dictionary<long, NPCCorporation> npcCorps = null;

                using (StreamReader sr = new StreamReader(rootDir + "/data2/npcCorporations.yaml"))
                {
                    YamlDotNet.Serialization.Deserializer ds = new YamlDotNet.Serialization.Deserializer();
                    npcCorps = ds.Deserialize<Dictionary<long, NPCCorporation>>(sr);
                }

                Console.WriteLine("    Loading operations...");

                Dictionary<long, StationOperation> stationOperations = null;

                using (StreamReader sr = new StreamReader(rootDir + "/data2/stationOperations.yaml"))
                {
                    YamlDotNet.Serialization.Deserializer ds = new YamlDotNet.Serialization.Deserializer();

                    stationOperations = ds.Deserialize<Dictionary<long, StationOperation>>(sr);
                }

                Console.WriteLine("    Loading stations...");

                int numResolvedStations = 0;
                using (StreamReader sr = new StreamReader(rootDir + "/data2/npcStations.yaml"))
                {
                    YamlDotNet.Serialization.Deserializer ds = new YamlDotNet.Serialization.Deserializer();

                    Dictionary<long, NPCStation> npcStations = ds.Deserialize<Dictionary<long, NPCStation>>(sr);

                    List<long> resolvedStationLocations = new List<long>();

                    foreach (long locationID in unknownLocations)
                    {
                        NPCStation npcStation = null;
                        if (npcStations.TryGetValue(locationID, out npcStation))
                        {
                            resolvedStationLocations.Add(locationID);

                            LocationInfo li = new LocationInfo();
                            li.LocationID = locationID;
                            li.Name = FormatNPCStationName(npcStation, solarSystemNames, stationOperations, npcCorps);
                            li.OwnerID = npcStation.ownerID;
                            li.SolarSystemID = npcStation.solarSystemID;
                            li.TypeID = npcStation.typeID;

                            locationCache[locationID] = li;

                            numResolvedStations++;
                        }
                    }

                    foreach (long removeLocationID in resolvedStationLocations)
                    {
                        unknownLocations.Remove(removeLocationID);
                    }
                }

                Console.WriteLine(numResolvedStations.ToString() + " locations resolved as stations");

                {
                    HashSet<long> possibleCitadels = new HashSet<long>(unknownLocations);

                    int numResolvedCitadels = 0;

                    foreach (long locationID in possibleCitadels)
                    {
                        if (locationID < 1000000000000)
                            continue;

                        KeyValuePair<string, string>[] queryParams = new KeyValuePair<string, string>[1];
                        queryParams[0] = new KeyValuePair<string, string>("structure_id", locationID.ToString());

                        try
                        {
                            int numPages;
                            byte[] structureBlob = esiHandler.ExecuteSecureESIQuery("/universe/structures/" + locationID.ToString() + "/", unknownLocationCharacterID[locationID], queryParams, true, out numPages);
                            StructureInfo structure = JsonConvert.DeserializeObject<StructureInfo>(Encoding.ASCII.GetString(structureBlob));

                            unknownLocations.Remove(locationID);

                            LocationInfo li = new LocationInfo();
                            li.LocationID = locationID;
                            li.Name = structure.name;
                            li.OwnerID = structure.owner_id;
                            li.SolarSystemID = structure.solar_system_id;
                            li.TypeID = structure.type_id;

                            locationCache[locationID] = li;

                            numResolvedCitadels++;

                        }
                        catch (Exception e)
                        {
                            Console.WriteLine("Error when trying to resolve structure " + locationID.ToString());
                            Console.WriteLine("    (Usually this means you don't have docking rights, or it's a customs office)");
                            Thread.Sleep(2000);
                        }
                    }

                    Console.WriteLine(numResolvedCitadels.ToString() + " resolved as structures");
                }

                Console.WriteLine(unknownLocations.Count + " unknown locations");

                foreach (long locationID in unknownLocations)
                {
                    LocationInfo li = new LocationInfo();
                    li.LocationID = locationID;
                    li.Name = "Unknown location " + locationID.ToString();
                    li.OwnerID = -1;
                    li.SolarSystemID = -1;
                    li.TypeID = -1;

                    locationCache[locationID] = li;
                }

                foreach (LocationInfo li in locationCache.Values)
                {
                    string name;
                    if (!solarSystemNames.TryGetValue(li.SolarSystemID, out name))
                        name = "Unknown";

                    li.SolarSystemName = name;
                }

                SaveLocationCache(locationCache);
            }

            return locationCache;
        }

        public static string RomanNumeral(int index)
        {
            switch (index)
            {
                case 1:
                    return "I";
                case 2:
                    return "II";
                case 3:
                    return "III";
                case 4:
                    return "IV";
                case 5:
                    return "V";
                case 6:
                    return "VI";
                case 7:
                    return "VII";
                case 8:
                    return "VIII";
                case 9:
                    return "IX";
                case 10:
                    return "X";
                case 11:
                    return "XI";
                case 12:
                    return "XII";
                case 13:
                    return "XIII";
                case 14:
                    return "XIV";
                case 15:
                    return "XV";
                case 16:
                    return "XVI";
                case 17:
                    return "XVII";
                case 18:
                    return "XVIII";
                default:
                    return index.ToString();
            }
        }

        private static string FormatNPCStationName(NPCStation npcStation, Dictionary<long, string> solarSystemNames, Dictionary<long, StationOperation> stationOperations, Dictionary<long, NPCCorporation> npcCorps)
        {
            StringBuilder sb = new StringBuilder(32);

            {
                string solarSystemName;
                if (solarSystemNames.TryGetValue(npcStation.solarSystemID, out solarSystemName))
                {
                    sb.Append(solarSystemName);
                }
                else
                {
                    sb.Append("UNKNOWN_SOLAR_SYSTEM_");
                    sb.Append(npcStation.solarSystemID);
                }
            }

            sb.Append(" ");
            sb.Append(RomanNumeral(npcStation.celestialIndex));

            if (npcStation.orbitIndex != 0)
            {
                sb.Append(" - Moon ");
                sb.Append(npcStation.orbitIndex);
            }

            sb.Append(" - ");

            {
                NPCCorporation npcCorp;
                string npcCorpName;
                if (npcCorps.TryGetValue(npcStation.ownerID, out npcCorp) && npcCorp.name.TryGetValue("en", out npcCorpName))
                {
                    sb.Append(npcCorpName);
                }
                else
                {
                    sb.Append("UNKNOWN_NPC_CORP_");
                    sb.Append(npcStation.ownerID);
                }
            }

            if (npcStation.useOperationName)
            {
                sb.Append(" ");

                string operationName = "";
                StationOperation stationOperation;
                if (stationOperations.TryGetValue(npcStation.operationID, out stationOperation) && stationOperation.operationName.TryGetValue("en", out operationName))
                {
                    sb.Append(operationName);
                }
                else
                {
                    sb.Append("UNKNOWN_OPERATION_");
                    sb.Append(npcStation.operationID.ToString());
                }
            }

            return sb.ToString();
        }

        static void AddIfNotExists<K, V>(IDictionary<K, V> dict, K key, V value)
        {
            if (!dict.ContainsKey(key))
                dict[key] = value;
        }

        static void DumpLocations(Dictionary<long, LocationInfo> locationCache, string path)
        {
            YamlDotNet.Serialization.Deserializer ds = new YamlDotNet.Serialization.Deserializer();

            using (StreamWriter sw = new StreamWriter(path))
            {
                sw.WriteLine("location\tname\tsolarSystem");
                foreach (LocationInfo location in locationCache.Values)
                {
                    sw.Write(location.LocationID);
                    sw.Write("\t");
                    sw.Write(location.Name);
                    sw.Write("\t");
                    sw.Write(location.SolarSystemName);
                    sw.WriteLine();
                }
            }
        }

        static string ResolveLocationSolarSystem(long locationID, IReadOnlyDictionary<long, long> assetParent, Dictionary<long, LocationInfo> locationCache)
        {
            LocationInfo locationInfo;
            if (locationCache.TryGetValue(ResolveTopLevelLocation(locationID, assetParent), out locationInfo))
                return locationInfo.SolarSystemName;

            return "Unknown";
        }

        static long ResolveTopLevelLocation(long locationID, IReadOnlyDictionary<long, long> assetParent)
        {
            long parentID;
            while (assetParent.TryGetValue(locationID, out parentID))
                locationID = parentID;

            return locationID;
        }


        static void WritePropertyNames(Type t, StreamWriter writer)
        {
            bool isFirst = true;

            foreach (System.Reflection.PropertyInfo p in t.GetProperties())
            {
                if (isFirst)
                    isFirst = false;
                else
                    writer.Write("\t");

                writer.Write(p.Name);
            }
        }

        static void WriteProperties(object obj, StreamWriter writer)
        {
            CultureInfo us = new CultureInfo("en-US");     // So we get US-format decimals

            bool isFirst = true;

            Type t = obj.GetType();
            foreach (System.Reflection.PropertyInfo p in t.GetProperties())
            {
                if (isFirst)
                    isFirst = false;
                else
                    writer.Write("\t");

                object propertyValue = p.GetValue(obj);
                if (propertyValue != null)
                {
                    Type propertyType = propertyValue.GetType();
                    if (propertyType == typeof(float))
                    {
                        float f = (float)propertyValue;
                        writer.Write(f.ToString(us));
                    }
                    else if (propertyType == typeof(double))
                    {
                        double d = (double)propertyValue;
                        writer.Write(d.ToString(us));
                    }
                    else if (propertyType == typeof(bool))
                    {
                        bool b = (bool)propertyValue;
                        writer.Write(b ? "true" : "false");
                    }
                    else
                        writer.Write(propertyValue);
                }
            }
        }

        static void CloseoutCountdown(int seconds)
        {
            while (seconds > 0)
            {
                Console.Write("Closing in " + seconds.ToString() + "...");

                Thread.Sleep(1000);
                seconds--;

                if (seconds == 0)
                    Console.WriteLine();
                else
                    Console.Write("\r");
            }
        }

        static void FetchOnHandInventory(Handler esiHandler)
        {
            CharacterInfo[] chars = esiHandler.GetCharacters();

            string assetsDumpLocation = GetRootDirectory() + "/data/cache/assets.dat";
            string corpAssetsDumpLocation = GetRootDirectory() + "/data/cache/assets_corp.dat";
            string locationsDumpLocation = GetRootDirectory() + "/data/cache/asset_locations.dat";
            string industryJobsDumpLocation = GetRootDirectory() + "/data/cache/industry_jobs.dat";
            string corpIndustryJobsDumpLocation = GetRootDirectory() + "/data/cache/industry_jobs_corp.dat";
            string contractsDumpLocation = GetRootDirectory() + "/data/cache/contracts.dat";
            string contractsItemsDumpLocation = GetRootDirectory() + "/data/cache/contracts_items.dat";
            string contractsCacheLocation = GetRootDirectory() + "/data/cache/contracts_cache.dat";

            Dictionary<long, long> charCorps = new Dictionary<long, long>();
            Dictionary<long, long> directorRoles = new Dictionary<long, long>();        // Corp --> character
            Dictionary<long, long> factoryManagerRoles = new Dictionary<long, long>();  // Corp --> character
            Dictionary<long, long> contractManagerRoles = new Dictionary<long, long>(); // Corp --> character

            Dictionary<long, List<CharacterAsset>> allCharAssets = new Dictionary<long, List<CharacterAsset>>();
            Dictionary<long, List<CharacterIndustryJob>> allCharJobs = new Dictionary<long, List<CharacterIndustryJob>>();
            Dictionary<long, List<CharacterAsset>> allCorpAssets = new Dictionary<long, List<CharacterAsset>>();
            Dictionary<long, List<CharacterIndustryJob>> allCorpJobs = new Dictionary<long, List<CharacterIndustryJob>>();
            Dictionary<long, long> locationSeenOnCharacter = new Dictionary<long, long>();

            Dictionary<long, string> charNames = new Dictionary<long, string>();

            HashSet<string> corpHangars = new HashSet<string>(new string[]{ "CorpDeliveries", "CorpSAG1", "CorpSAG2", "CorpSAG3", "CorpSAG4", "CorpSAG5", "CorpSAG6", "CorpSAG7" });

            foreach (CharacterInfo c in chars)
            {
                charNames[c.CharacterID] = c.Name;

                Console.WriteLine("Fetching corporation roles for " + c.Name + "...");

                {
                    KeyValuePair<string, string>[] queryParams = new KeyValuePair<string, string>[0];

                    int numPages;
                    byte[] charPublicInfoBlob = esiHandler.ExecutePublicESIQuery("/characters/" + c.CharacterID.ToString() + "/", queryParams, true, out numPages);

                    CharacterPublicInfo pubInfo = JsonConvert.DeserializeObject<CharacterPublicInfo>(Encoding.UTF8.GetString(charPublicInfoBlob));

                    long corporationID = pubInfo.corporation_id;
                    charCorps[c.CharacterID] = corporationID;

                    bool needDirector = !directorRoles.ContainsKey(corporationID);
                    bool needFactoryManager = !factoryManagerRoles.ContainsKey(corporationID);

                    if (needDirector || needFactoryManager)
                    {
                        byte[] rolesBlob = esiHandler.ExecuteSecureESIQuery("/characters/" + c.CharacterID.ToString() + "/roles/", c.CharacterID, queryParams, true, out numPages);
                        string str = Encoding.UTF8.GetString(rolesBlob);
                        CharacterRoles roles = JsonConvert.DeserializeObject<CharacterRoles>(Encoding.UTF8.GetString(rolesBlob));

                        foreach (string role in roles.roles)
                        {
                            if (needDirector && role == "Director")
                                directorRoles[corporationID] = c.CharacterID;
                            if (role == "Factory_Manager")
                                factoryManagerRoles[corporationID] = c.CharacterID;
                            if (role == "Contract_Manager")
                                contractManagerRoles[corporationID] = c.CharacterID;
                        }
                    }
                }

                Console.WriteLine("Fetching assets for character " + c.Name + "...");

                {
                    List<CharacterAsset> charAssets = new List<CharacterAsset>();

                    KeyValuePair<string, string>[] queryParams = new KeyValuePair<string, string>[1];

                    int numPages = 1;
                    for (int page = 1; page <= numPages; page++)
                    {
                        queryParams[0] = new KeyValuePair<string, string>("page", page.ToString());
                        byte[] assetsBlob = esiHandler.ExecuteSecureESIQuery("/characters/" + c.CharacterID.ToString() + "/assets/", c.CharacterID, queryParams, true, out numPages);

                        CharacterAsset[] assets = JsonConvert.DeserializeObject<CharacterAsset[]>(Encoding.ASCII.GetString(assetsBlob));
                        charAssets.AddRange(assets);

                        foreach (CharacterAsset asset in assets)
                        {
                            if (asset.location_flag == "Hangar")
                                AddIfNotExists(locationSeenOnCharacter, asset.location_id, c.CharacterID);
                        }

                        Console.WriteLine("Page " + page.ToString() + " / " + numPages.ToString() + " retrieved");
                    }

                    allCharAssets[c.CharacterID] = charAssets;
                }

                Console.WriteLine("Fetching industry jobs for " + c.Name + "...");

                {
                    List<CharacterIndustryJob> charJobs = new List<CharacterIndustryJob>();

                    KeyValuePair<string, string>[] queryParams = new KeyValuePair<string, string>[1];
                    queryParams[0] = new KeyValuePair<string, string>("include_completed", "false");

                    int numPages;
                    byte[] jobsBlob = esiHandler.ExecuteSecureESIQuery("/characters/" + c.CharacterID.ToString() + "/industry/jobs/", c.CharacterID, queryParams, true, out numPages);

                    CharacterIndustryJob[] industryJobs = JsonConvert.DeserializeObject<CharacterIndustryJob[]>(Encoding.ASCII.GetString(jobsBlob));
                    charJobs.AddRange(industryJobs);

                    foreach (CharacterIndustryJob job in industryJobs)
                    {
                        AddIfNotExists(locationSeenOnCharacter, job.blueprint_location_id, c.CharacterID);
                        AddIfNotExists(locationSeenOnCharacter, job.output_location_id, c.CharacterID);
                    }

                    allCharJobs[c.CharacterID] = charJobs;
                }
            }

            // Corporation assets + jobs
            foreach (KeyValuePair<long, long> corpChar in directorRoles)
            {
                long corporationID = corpChar.Key;
                long characterID = corpChar.Value;

                Console.WriteLine("Fetching corporation assets via " + charNames[characterID] + "...");

                List<CharacterAsset> corpAssets = new List<CharacterAsset>();

                KeyValuePair<string, string>[] queryParams = new KeyValuePair<string, string>[1];

                int numPages = 1;
                for (int page = 1; page <= numPages; page++)
                {
                    queryParams[0] = new KeyValuePair<string, string>("page", page.ToString());
                    byte[] assetsBlob = esiHandler.ExecuteSecureESIQuery("/corporations/" + corporationID.ToString() + "/assets/", characterID, queryParams, true, out numPages);

                    CharacterAsset[] assets = JsonConvert.DeserializeObject<CharacterAsset[]>(Encoding.ASCII.GetString(assetsBlob));
                    corpAssets.AddRange(assets);

                    foreach (CharacterAsset asset in assets)
                    {
                        if (corpHangars.Contains(asset.location_flag))
                            AddIfNotExists(locationSeenOnCharacter, asset.location_id, characterID);
                    }

                    Console.WriteLine("Page " + page.ToString() + " / " + numPages.ToString() + " retrieved");
                }

                allCorpAssets[corporationID] = corpAssets;
            }

            foreach (KeyValuePair<long, long> corpChar in factoryManagerRoles)
            {
                long corporationID = corpChar.Key;
                long characterID = corpChar.Value;

                Console.WriteLine("Fetching corporation industry jobs via " + charNames[characterID] + "...");

                List<CharacterIndustryJob> corpJobs = new List<CharacterIndustryJob>();

                KeyValuePair<string, string>[] queryParams = new KeyValuePair<string, string>[1];
                queryParams[0] = new KeyValuePair<string, string>("include_completed", "false");

                int numPages;

                try
                {
                    byte[] jobsBlob = esiHandler.ExecuteSecureESIQuery("/corporations/" + corporationID.ToString() + "/industry/jobs/", characterID, queryParams, true, out numPages);

                    CharacterIndustryJob[] industryJobs = JsonConvert.DeserializeObject<CharacterIndustryJob[]>(Encoding.ASCII.GetString(jobsBlob));
                    corpJobs.AddRange(industryJobs);

                    foreach (CharacterIndustryJob job in industryJobs)
                    {
                        AddIfNotExists(locationSeenOnCharacter, job.blueprint_location_id, characterID);
                        AddIfNotExists(locationSeenOnCharacter, job.output_location_id, characterID);
                    }

                    allCorpJobs[corporationID] = corpJobs;
                }
                catch (WebException ex)
                {
                    Console.WriteLine("Industry jobs endpoint is still dead.  Great job, CCP!  Corp industry outputs will be excluded.");
                    break;
                }
            }

            HashSet<int> alreadySeenContractIDs = new HashSet<int>();
            List<ContractInfo> allContracts = new List<ContractInfo>();
            Dictionary<int, ContractItem[]> allContractItems = new Dictionary<int, ContractItem[]>();
            Dictionary<int, ContractItem[]> cachedContracts = new Dictionary<int, ContractItem[]>();

            if (File.Exists(contractsCacheLocation))
            {
                try
                {
                    string contractsCacheStr = File.ReadAllText(contractsCacheLocation);
                    cachedContracts = JsonConvert.DeserializeObject<Dictionary<int, ContractItem[]>>(contractsCacheStr);
                }
                catch (Exception ex)
                {
                    Console.WriteLine("Failed to load contract cache");
                }
            }

            foreach (CharacterInfo c in chars)
            {
                Console.WriteLine("Fetching contracts for " + c.Name + "...");

                KeyValuePair<string, string>[] queryParams = new KeyValuePair<string, string>[1];

                List<ContractInfo> interestingContracts = new List<ContractInfo>();

                int numPages = 1;
                for (int page = 1; page <= numPages; page++)
                {
                    queryParams[0] = new KeyValuePair<string, string>("page", page.ToString());
                    byte[] contractsBlob = esiHandler.ExecuteSecureESIQuery("/characters/" + c.CharacterID.ToString() + "/contracts/", c.CharacterID, queryParams, true, out numPages);

                    ContractInfo[] contracts = JsonConvert.DeserializeObject<ContractInfo[]>(Encoding.ASCII.GetString(contractsBlob));

                    foreach (ContractInfo contract in contracts)
                    {
                        if (contract.status == "outstanding" && contract.availability != "personal" && !alreadySeenContractIDs.Contains(contract.contract_id) && contract.assignee_id != c.CharacterID)
                        {
                            interestingContracts.Add(contract);
                            alreadySeenContractIDs.Add(contract.contract_id);
                        }
                    }

                    Console.WriteLine("Page " + page.ToString() + " / " + numPages.ToString() + " retrieved");
                }

                for (int ci = 0; ci < interestingContracts.Count; ci++)
                {
                    ContractInfo contract = interestingContracts[ci];

                    ContractItem[] contractItems;
                    if (!cachedContracts.TryGetValue(contract.contract_id, out contractItems))
                    {
                        int contractNumPages = 1;
                        byte[] contractsBlob = esiHandler.ExecuteSecureESIQuery("/characters/" + c.CharacterID.ToString() + "/contracts/" + contract.contract_id + "/items/", c.CharacterID, queryParams, true, out contractNumPages);

                        contractItems = JsonConvert.DeserializeObject<ContractItem[]>(Encoding.ASCII.GetString(contractsBlob));

                        Console.WriteLine("Contract contents " + (ci + 1).ToString() + " / " + interestingContracts.Count.ToString() + " retrieved");
                    }
                    allContractItems[contract.contract_id] = contractItems;
                }
            }

            foreach (KeyValuePair<long, long> corpChar in contractManagerRoles)
            {
                long corporationID = corpChar.Key;
                long characterID = corpChar.Value;

                Console.WriteLine("Fetching corporation contracts via " + charNames[characterID] + "...");

                KeyValuePair<string, string>[] queryParams = new KeyValuePair<string, string>[1];

                List<ContractInfo> interestingContracts = new List<ContractInfo>();

                int numPages = 1;
                for (int page = 1; page <= numPages; page++)
                {
                    queryParams[0] = new KeyValuePair<string, string>("page", page.ToString());
                    byte[] contractsBlob = esiHandler.ExecuteSecureESIQuery("/corporations/" + corporationID.ToString() + "/contracts/", characterID, queryParams, true, out numPages);

                    ContractInfo[] contracts = JsonConvert.DeserializeObject<ContractInfo[]>(Encoding.ASCII.GetString(contractsBlob));

                    foreach (ContractInfo contract in contracts)
                    {
                        if (contract.status == "outstanding" && contract.availability != "personal" && !alreadySeenContractIDs.Contains(contract.contract_id) && contract.assignee_id != corporationID)
                        {
                            interestingContracts.Add(contract);
                            alreadySeenContractIDs.Add(contract.contract_id);
                        }
                    }

                    Console.WriteLine("Page " + page.ToString() + " / " + numPages.ToString() + " retrieved");
                }

                for (int ci = 0; ci < interestingContracts.Count; ci++)
                {
                    ContractInfo contract = interestingContracts[ci];

                    ContractItem[] contractItems;
                    if (!cachedContracts.TryGetValue(contract.contract_id, out contractItems))
                    {
                        int contractNumPages = 1;
                        byte[] contractsBlob = esiHandler.ExecuteSecureESIQuery("/corporations/" + corporationID.ToString() + "/contracts/" + contract.contract_id + "/items/", characterID, queryParams, true, out contractNumPages);

                        contractItems = JsonConvert.DeserializeObject<ContractItem[]>(Encoding.ASCII.GetString(contractsBlob));

                        Console.WriteLine("Contract contents " + (ci + 1).ToString() + " / " + interestingContracts.Count.ToString() + " retrieved");
                    }
                    allContractItems[contract.contract_id] = contractItems;
                }
            }

            Console.WriteLine("Saving contract cache...");

            {
                string contractCacheStr = JsonConvert.SerializeObject(allContractItems);
                File.WriteAllText(contractsCacheLocation, contractCacheStr);
            }

            Console.WriteLine("Resolving asset hierarchy...");

            Dictionary<long, long> assetParent = new Dictionary<long, long>();

            foreach (List<CharacterAsset> charAssets in allCharAssets.Values)
            {
                foreach (CharacterAsset asset in charAssets)
                {
                    if (asset.location_type != "solar_system")
                        assetParent[asset.item_id] = asset.location_id;
                }
            }

            foreach (List<CharacterAsset> corpAssets in allCorpAssets.Values)
            {
                foreach (CharacterAsset asset in corpAssets)
                {
                    if (asset.location_type != "solar_system")
                        assetParent[asset.item_id] = asset.location_id;
                }
            }

            Dictionary<long, LocationInfo> locationCache = ResolveLocations(esiHandler, assetParent, locationSeenOnCharacter);

            using (StreamWriter sw = new StreamWriter(assetsDumpLocation))
            {
                sw.Write("character_id\tsolar_system_name\t");
                WritePropertyNames(typeof(CharacterAsset), sw);
                sw.WriteLine();

                List<long> charIDs = new List<long>(allCharAssets.Keys);
                charIDs.Sort();

                foreach (long charID in charIDs)
                {
                    List<CharacterAsset> assets = allCharAssets[charID];
                    foreach (CharacterAsset asset in assets)
                    {
                        sw.Write(charID);
                        sw.Write("\t");
                        sw.Write(ResolveLocationSolarSystem(asset.location_id, assetParent, locationCache));
                        sw.Write("\t");
                        WriteProperties(asset, sw);
                        sw.WriteLine();
                    }
                }
            }

            using (StreamWriter sw = new StreamWriter(corpAssetsDumpLocation))
            {
                sw.Write("corporation_id\tsolar_system_name\t");
                WritePropertyNames(typeof(CharacterAsset), sw);
                sw.WriteLine();

                List<long> corpIDs = new List<long>(allCorpAssets.Keys);
                corpIDs.Sort();

                foreach (long corpID in corpIDs)
                {
                    List<CharacterAsset> assets = allCorpAssets[corpID];
                    foreach (CharacterAsset asset in assets)
                    {
                        sw.Write(corpID);
                        sw.Write("\t");
                        sw.Write(ResolveLocationSolarSystem(asset.location_id, assetParent, locationCache));
                        sw.Write("\t");
                        WriteProperties(asset, sw);
                        sw.WriteLine();
                    }
                }
            }

            using (StreamWriter sw = new StreamWriter(industryJobsDumpLocation))
            {
                sw.Write("character_id\toutput_solar_system\t");
                WritePropertyNames(typeof(CharacterIndustryJob), sw);
                sw.WriteLine();

                List<long> charIDs = new List<long>(allCharJobs.Keys);
                charIDs.Sort();

                foreach (long charID in charIDs)
                {
                    List<CharacterIndustryJob> jobs = allCharJobs[charID];
                    foreach (CharacterIndustryJob job in jobs)
                    {
                        sw.Write(charID);
                        sw.Write("\t");
                        sw.Write(ResolveLocationSolarSystem(job.output_location_id, assetParent, locationCache));
                        sw.Write("\t");
                        WriteProperties(job, sw);
                        sw.WriteLine();
                    }
                }
            }

            using (StreamWriter sw = new StreamWriter(corpIndustryJobsDumpLocation))
            {
                sw.Write("corporation_id\toutput_solar_system\t");
                WritePropertyNames(typeof(CharacterIndustryJob), sw);
                sw.WriteLine();

                List<long> corpIDs = new List<long>(allCorpJobs.Keys);
                corpIDs.Sort();

                foreach (long corpID in corpIDs)
                {
                    List<CharacterIndustryJob> jobs = allCorpJobs[corpID];
                    foreach (CharacterIndustryJob job in jobs)
                    {
                        sw.Write(corpID);
                        sw.Write("\t");
                        sw.Write(ResolveLocationSolarSystem(job.output_location_id, assetParent, locationCache));
                        sw.Write("\t");
                        WriteProperties(job, sw);
                        sw.WriteLine();
                    }
                }
            }

            using (StreamWriter sw = new StreamWriter(contractsDumpLocation))
            {
                CultureInfo us = new CultureInfo("en-US");     // So we get US-format decimals

                sw.WriteLine("contractID\tprice");
                foreach (ContractInfo contract in allContracts)
                    sw.WriteLine(contract.contract_id + "\t" + contract.price.ToString());
            }

            using (StreamWriter sw = new StreamWriter(contractsItemsDumpLocation))
            {
                sw.WriteLine("contractID\titemID\trawQuantity\tquantity");
                foreach (KeyValuePair<int, ContractItem[]> contract in allContractItems)
                {
                    int contractID = contract.Key;

                    foreach (ContractItem item in contract.Value)
                    {
                        if (!item.is_included)
                            continue;

                        sw.Write(contractID);
                        sw.Write("\t");
                        sw.Write(item.type_id);
                        sw.Write("\t");
                        sw.Write(item.raw_quantity);
                        sw.Write("\t");
                        sw.Write(item.quantity);
                        sw.WriteLine();
                    }
                }
            }

            DumpLocations(locationCache, locationsDumpLocation);
        }

        static void FetchMarketOrders(Handler esiHandler, string configPath)
        {
            MarketConfig config = ReadMarketConfig(configPath);

            foreach (PublicMarketConfig pubMarket in config.public_markets)
            {
                RetrieveAndWriteMarketOrders(esiHandler, (int)pubMarket.region_id, pubMarket.characterized_locations, null, false, "data/cache/public_market_" + pubMarket.region_id.ToString() + ".dat");
            }

            foreach (CitadelMarketConfig citMarket in config.citadel_markets)
            {
                CharacterizedLocation[] cl = new CharacterizedLocation[] { citMarket.characterized_location };
                RetrieveAndWriteMarketOrders(esiHandler, 0, cl, citMarket.auth_character_name, true, "data/cache/citadel_market_" + citMarket.characterized_location.location_id.ToString() + ".dat");
            }
        }

        static void RetrieveAndWriteMarketOrders(Handler esiHandler, int regionID, IEnumerable<CharacterizedLocation> cls, string characterName, bool isSecure, string outputPath)
        {
            CultureInfo us = new CultureInfo("en-US");     // So we get US-format decimals

            Dictionary<long, CharacterizedLocation> clsDict = new Dictionary<long, CharacterizedLocation>();
            foreach (CharacterizedLocation cl in cls)
                clsDict.Add(cl.location_id, cl);

            KeyValuePair<string, string>[] queryParams;

            long? charID = null;
            if (isSecure)
            {
                queryParams = new KeyValuePair<string, string>[1];

                foreach (CharacterInfo charInfo in esiHandler.GetCharacters())
                {
                    if (charInfo.Name == characterName)
                    {
                        charID = charInfo.CharacterID;
                        break;
                    }
                }

                if (charID == null)
                {
                    Console.WriteLine("Couldn't find character named " + characterName + ", make sure it's authenticated");
                    return;
                }
            }
            else
            {
                queryParams = new KeyValuePair<string, string>[3];
                queryParams[1] = new KeyValuePair<string, string>("order_type", "sell");
                queryParams[2] = new KeyValuePair<string, string>("region_id", regionID.ToString());
            }

            IEnumerable<CharacterizedLocation> locationIterator = cls;

            if (!isSecure)
            {
                Console.WriteLine("Fetching market orders for region " + regionID.ToString() + "...");

                CharacterizedLocation cl;
                cl.location_id = 0;
                cl.location_type = "default";
                locationIterator = new CharacterizedLocation[] { cl };
            }

            Dictionary<long, PublicMarketOrder> marketOrdersDict = new Dictionary<long, PublicMarketOrder>();

            foreach (CharacterizedLocation iteratedLocation in locationIterator)
            {
                if (isSecure)
                    Console.WriteLine("Fetching market orders for location " + iteratedLocation.location_id.ToString() + "...");

                int numPages = 1;
                for (int page = 1; page <= numPages; page++)
                {
                    queryParams[0] = new KeyValuePair<string, string>("page", page.ToString());
                    byte[] ordersBlob;
                    if (isSecure)
                        ordersBlob = esiHandler.ExecuteSecureESIQuery("/markets/structures/" + iteratedLocation.location_id.ToString() + "/", (long)charID, queryParams, true, out numPages);
                    else
                        ordersBlob = esiHandler.ExecutePublicESIQuery("/markets/" + regionID.ToString() + "/orders/", queryParams, true, out numPages);

                    PublicMarketOrder[] marketOrders = JsonConvert.DeserializeObject<PublicMarketOrder[]>(Encoding.ASCII.GetString(ordersBlob));

                    // This ensures that duplicate orders get trashed if the order updating in the middle of the query causes an order to move to a different page
                    foreach (PublicMarketOrder marketOrder in marketOrders)
                    {
                        if (marketOrder.is_buy_order)
                            continue;   // Citadel market queries can't use order_type :ccp:

                        if (clsDict.Count == 0 || clsDict.ContainsKey(marketOrder.location_id))
                            marketOrdersDict[marketOrder.order_id] = marketOrder;
                    }

                    Console.WriteLine("Page " + page.ToString() + " / " + numPages.ToString() + " retrieved");
                }
            }

            Console.WriteLine("Collating...");

            Dictionary<int, List<PublicMarketOrder>> typeOrders = new Dictionary<int, List<PublicMarketOrder>>();
            List<int> allTypeIDs = new List<int>();
            foreach (PublicMarketOrder marketOrder in marketOrdersDict.Values)
            {
                List<PublicMarketOrder> itemOrders = null;
                if (!typeOrders.TryGetValue(marketOrder.type_id, out itemOrders))
                {
                    itemOrders = new List<PublicMarketOrder>();
                    typeOrders[marketOrder.type_id] = itemOrders;
                    allTypeIDs.Add(marketOrder.type_id);
                }

                itemOrders.Add(marketOrder);
            }

            allTypeIDs.Sort();

            Console.WriteLine("Exporting...");

            using (StreamWriter sw = new StreamWriter(outputPath))
            {
                sw.WriteLine("typeID\tprice\tquantity\tlocationType");
                foreach (int typeID in allTypeIDs)
                {
                    foreach (PublicMarketOrder marketOrder in typeOrders[typeID])
                    {
                        sw.Write(typeID);
                        sw.Write("\t");
                        sw.Write(marketOrder.price.ToString(us));
                        sw.Write("\t");
                        sw.Write(marketOrder.volume_remain);
                        sw.Write("\t");
                        sw.Write(clsDict[marketOrder.location_id].location_type);
                        sw.WriteLine();
                    }
                }
            }
        }

        static void FetchItemValues(Handler esiHandler)
        {
            CultureInfo us = new CultureInfo("en-US");     // So we get US-format decimals

            Dictionary<string, string> queryParams = new Dictionary<string, string>();

            int numPages;
            byte[] pricesBlob = esiHandler.ExecutePublicESIQuery("/markets/prices/", queryParams, true, out numPages);

            MarketPrice[] marketPrices = JsonConvert.DeserializeObject<MarketPrice[]>(Encoding.UTF8.GetString(pricesBlob));
            
            Dictionary<long, string> names = new Dictionary<long, string>();
            using (StreamReader sr = new StreamReader(GetRootDirectory() + "/data/cache/names.dat"))
            {
                while (!sr.EndOfStream)
                {
                    string line = sr.ReadLine();
                    string[] tokens = line.Split('\t');

                    if (tokens.Length == 2)
                        names[long.Parse(tokens[0])] = tokens[1];
                }
            }

            using (StreamWriter sw = new StreamWriter("data/items_esi_prices.dat"))
            {
                sw.WriteLine("item\taveragePrice\tadjustedPrice");
                foreach (MarketPrice marketPrice in marketPrices)
                {
                    string itemName;
                    if (!names.TryGetValue(marketPrice.type_id, out itemName))
                        itemName = "UNKNOWN_ITEM_" + marketPrice.type_id.ToString();

                    sw.Write(itemName);
                    sw.Write("\t");
                    sw.Write(marketPrice.average_price.ToString(us));
                    sw.Write("\t");
                    sw.Write(marketPrice.adjusted_price.ToString(us));
                    sw.WriteLine();
                }
            }
        }

        static void FetchSCI(Handler esiHandler)
        {
            CultureInfo us = new CultureInfo("en-US");     // So we get US-format decimals

            Dictionary<string, string> queryParams = new Dictionary<string, string>();

            int numPages;
            byte[] pricesBlob = esiHandler.ExecutePublicESIQuery("/industry/systems/", queryParams, true, out numPages);

            IndustrySystem[] industrySystems = JsonConvert.DeserializeObject<IndustrySystem[]>(Encoding.UTF8.GetString(pricesBlob));

            Dictionary<long, string> solarSystemNames = new Dictionary<long, string>();
            using (StreamReader sr = new StreamReader(GetRootDirectory() + "/data/cache/solar_systems.dat"))
            {
                while (!sr.EndOfStream)
                {
                    string line = sr.ReadLine();
                    string[] tokens = line.Split('\t');

                    if (tokens.Length == 2)
                        solarSystemNames[long.Parse(tokens[0])] = tokens[1];
                }
            }

            using (StreamWriter sw = new StreamWriter(GetRootDirectory() + "/data/sci.dat"))
            {
                sw.WriteLine("solarSystemName\tactivity\tcostIndex");
                foreach (IndustrySystem system in industrySystems)
                {
                    string solarSystemName;
                    if (!solarSystemNames.TryGetValue(system.solar_system_id, out solarSystemName))
                        solarSystemName = "UNKNOWN_SOLAR_SYSTEM_" + system.solar_system_id.ToString();

                    foreach (IndustrySystemCostIndex sci in system.cost_indices)
                    {
                        sw.Write(solarSystemName);
                        sw.Write("\t");
                        sw.Write(sci.activity);
                        sw.Write("\t");
                        sw.Write(sci.cost_index.ToString(us));
                        sw.WriteLine();
                    }
                }
            }
        }

        static void Main(string[] args)
        {
            if (args.Length < 1)
            {
                Console.WriteLine("Auth handler unknown operation");
                Environment.ExitCode = -1;
                return;
            }

            string operation = args[0];

            Handler esiHandler = new Handler(AtomSmasherProtocol, AtomSmasherClientID, AtomSmasherCallbackURI, AtomSmasherPendingAuthPath, AtomSmasherTokenPath, GetExpectedPath(), GetDefaultScopes(), AtomSmasherApplicationName);

#if !DEBUG
            try
#endif
            {
                switch (operation)
                {
                    case "Authenticate":
                        if (CheckRegistryKey())
                            esiHandler.Authenticate();
                        break;
                    case "Install":
                        esiHandler.InstallTokenFromUri(args[1]);
                        break;
                    case "FetchOnHandInventory":
                        FetchOnHandInventory(esiHandler);
                        break;
                    case "FetchSCI":
                        FetchSCI(esiHandler);
                        break;
                    case "FetchItemValues":
                        FetchItemValues(esiHandler);
                        break;
                    case "FetchMarketOrders":
                        FetchMarketOrders(esiHandler, args[1]);
                        break;
                }

            }
#if !DEBUG
            catch (Exception ex)
            {
                Console.WriteLine("Something went wrong:");
                Console.WriteLine(ex.ToString());
            }
#endif
        }
    }
}
