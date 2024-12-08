using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.IO;
using YamlDotNet;
using System.Globalization;

namespace SDEParser
{
    class Program
    {
        struct BlueprintActivityProduct
        {
            public int quantity { get; set; }
            public double probability { get; set; }
            public int typeID { get; set; }
        }

        struct BlueprintActivityMaterial
        {
            public int quantity { get; set; }
            public int typeID { get; set; }
        }

        struct BlueprintActivitySkillRequirement
        {
            public int level { get; set; }
            public int typeID { get; set; }
        }

        struct BlueprintActivity
        {
            public int time { get; set; }
            public BlueprintActivityMaterial[] materials { get; set; }
            public BlueprintActivityProduct[] products { get; set; }
            public BlueprintActivitySkillRequirement[] skills { get; set; }
        }

        struct Blueprint
        {
            public Dictionary<string, BlueprintActivity> activities { get; set; }
            public int blueprintTypeID { get; set; }
            public int maxProductionLimit { get; set; }
        }

        struct Activity
        {
            public int activityID { get; set; }
            public string activityName { get; set; }
            public string description { get; set; }
            public string iconNo { get; set; }
            public bool published { get; set; }
        }

        struct TypeIDTraitBonus
        {
            public double bonus { get; set; }
            public int importance { get; set; }
            public int unitID { get; set; }
            public Dictionary<string, string> bonusText { get; set; }
            public bool isPositive { get; set; }
        }

        struct TypeIDTraits
        {
            public TypeIDTraitBonus[] miscBonuses { get; set; }
            public TypeIDTraitBonus[] roleBonuses { get; set; }
            public Dictionary<int, TypeIDTraitBonus[]> types { get; set; }
            public int iconID { get; set; }
        }

        struct TypeID
        {
            public int groupID { get; set; }
            public int soundID { get; set; }
            public int graphicID { get; set; }
            public int iconID { get; set; }
            public int factionID { get; set; }
            public int marketGroupID { get; set; }
            public double metaGroupID { get; set; }
            public int sofMaterialSetID { get; set; }
            public int? variationParentTypeID { get; set; }
            public Dictionary<string, string> name { get; set; }
            public Dictionary<string, string> description { get; set; }
            public Dictionary<int, int[]> masteries { get; set; }
            public TypeIDTraits traits { get; set; }
            public bool published { get; set; }
            public int portionSize { get; set; }
            public int raceID { get; set; }
            public double mass { get; set; }
            public double volume { get; set; }
            public double radius { get; set; }
            public double basePrice { get; set; }
            public double capacity { get; set; }
            public string sofFactionName { get; set; }
        }

        public struct MetaGroup
        {
            public int iconID { get; set; }
            public string iconSuffix { get; set; }
            public Dictionary<string, string> nameID { get; set; }
            public Dictionary<string, string> descriptionID { get; set; }
            public float[] color { get; set; }
        }

        public struct GroupID
        {
            public bool anchorable { get; set; }
            public bool anchored { get; set; }
            public bool fittableNonSingleton { get; set; }
            public bool published { get; set; }
            public bool useBasePrice { get; set; }
            public Dictionary<string, string> name { get; set; }
            public int categoryID { get; set; }
            public int iconID { get; set; }
        }

        public struct CategoryID
        {
            public Dictionary<string, string> name { get; set; }
            public bool published { get; set; }
            public int iconID { get; set; }
        }

        public struct TypeMaterial
        {
            public int materialTypeID { get; set; }
            public double quantity { get; set; }
        }

        public struct TypeMaterialList
        {
            public TypeMaterial[] materials { get; set; }
        }

        public class ItemName
        {
            public long itemID { get; set; }
            public string itemName { get; set; }
        }

        static string NameType(Dictionary<int, TypeID> typeIDs, int id)
        {
            TypeID typeID;
            if (typeIDs.TryGetValue(id, out typeID))
            {
                string str;
                if (typeID.name.TryGetValue("en", out str))
                    return str;

                return "UNKNOWN_ITEM_" + id.ToString();
            }
            return "UNKNOWN_ITEM_" + id.ToString();
        }

        static string NameGroup(Dictionary<int, GroupID> groupIDs, Dictionary<int, TypeID> typeIDs, int id)
        {
            TypeID typeID;
            if (!typeIDs.TryGetValue(id, out typeID))
                return "UNKNOWN_TYPE_GROUP_" + id.ToString();

            GroupID groupID;
            if (!groupIDs.TryGetValue(typeID.groupID, out groupID))
                return "UNKNOWN_GROUP_" + typeID.groupID.ToString();

            string str;
            if (!groupID.name.TryGetValue("en", out str))
                return "UNNAMED_GROUP_" + typeID.groupID.ToString();

            return str;
        }

        static bool IsPublishedTypeID(Dictionary<int, TypeID> typeIDs, int typeID)
        {
            TypeID typeIDData;
            if (typeIDs.TryGetValue(typeID, out typeIDData))
                return typeIDData.published;
            else
                return false;
        }

        static void Main(string[] args)
        {
            Dictionary<int, Blueprint> blueprints;
            Dictionary<int, TypeID> typeIDs;
            Dictionary<int, GroupID> groupIDs;
            Dictionary<int, CategoryID> categoryIDs;
            Dictionary<int, MetaGroup> metaGroups;
            Dictionary<int, List<TypeMaterial>> indexedTypeMaterials = new Dictionary<int, List<TypeMaterial>>();

            CultureInfo us = new CultureInfo("en-US");     // So we get US-format decimals

            // Useless due to fucked up data :ccp:
            Console.WriteLine("Loading meta groups...");

            using (StreamReader sr = new StreamReader("data2/metaGroups.yaml"))
            {
                YamlDotNet.Serialization.Deserializer ds = new YamlDotNet.Serialization.Deserializer();
                metaGroups = ds.Deserialize<Dictionary<int, MetaGroup>>(sr);
            }

            Console.WriteLine("Loading category IDs...");

            using (StreamReader sr = new StreamReader("data2/categories.yaml"))
            {
                YamlDotNet.Serialization.Deserializer ds = new YamlDotNet.Serialization.Deserializer();
                categoryIDs = ds.Deserialize<Dictionary<int, CategoryID>>(sr);
            }

            Console.WriteLine("Loading group IDs...");

            using (StreamReader sr = new StreamReader("data2/groups.yaml"))
            {
                YamlDotNet.Serialization.Deserializer ds = new YamlDotNet.Serialization.Deserializer();
                groupIDs = ds.Deserialize<Dictionary<int, GroupID>>(sr);
            }

            Console.WriteLine("Loading reprocessing materials...");

            using (StreamReader sr = new StreamReader("data2/typeMaterials.yaml"))
            {
                YamlDotNet.Serialization.Deserializer ds = new YamlDotNet.Serialization.Deserializer();
                Dictionary<int, TypeMaterialList> typeMaterials = ds.Deserialize<Dictionary<int, TypeMaterialList>>(sr);

                Console.WriteLine("    Indexing reprocessing materials...");

                foreach (KeyValuePair<int, TypeMaterialList> kvp in typeMaterials)
                    indexedTypeMaterials[kvp.Key] = new List<TypeMaterial>(kvp.Value.materials);
            }

            Console.WriteLine("Loading blueprints...");

            using (StreamReader sr = new StreamReader("data2/blueprints.yaml"))
            {
                YamlDotNet.Serialization.Deserializer ds = new YamlDotNet.Serialization.Deserializer();
                blueprints = ds.Deserialize<Dictionary<int, Blueprint>>(sr);
            }

            blueprints.Remove(45732);   // Stupid test blueprint

            Console.WriteLine("Loading type IDs...");

            using (StreamReader sr = new StreamReader("data2/types.yaml"))
            {
                YamlDotNet.Serialization.Deserializer ds = new YamlDotNet.Serialization.Deserializer();
                typeIDs = ds.Deserialize<Dictionary<int, TypeID>>(sr);
            }

            Console.WriteLine("Loading names...");

            Dictionary<long, string> names = new Dictionary<long, string>();

            using (StreamReader sr = new StreamReader("data2/invNames.yaml"))
            {
                YamlDotNet.Serialization.Deserializer ds = new YamlDotNet.Serialization.Deserializer();
                ItemName[] namesList = ds.Deserialize<ItemName[]>(sr);
                foreach (ItemName item in namesList)
                    names[item.itemID] = item.itemName;
            }

            Console.WriteLine("Cleaning up garbage blueprints...");

            {
                List<int> badBlueprints = new List<int>();
                foreach (int typeID in blueprints.Keys)
                    if (!IsPublishedTypeID(typeIDs, typeID))
                        badBlueprints.Add(typeID);

                foreach (int typeID in badBlueprints)
                    blueprints.Remove(typeID);
            }

            Console.WriteLine("Writing data...");

            using (StreamWriter sw = new StreamWriter("data/blueprints_complex.csv"))
            {
                foreach (KeyValuePair<int, Blueprint> bpidBlueprint in blueprints)
                {
                    foreach (KeyValuePair<string, BlueprintActivity> activityNameActivity in bpidBlueprint.Value.activities)
                    {
                        if (activityNameActivity.Key != "manufacturing")
                            continue;

                        if (activityNameActivity.Value.materials == null || activityNameActivity.Value.products == null)
                            continue;

                        foreach (BlueprintActivityProduct product in activityNameActivity.Value.products)
                        {
                            foreach (BlueprintActivityMaterial material in activityNameActivity.Value.materials)
                            {
                                sw.Write(material.quantity.ToString());
                                sw.Write("\t");
                                sw.Write(NameType(typeIDs, material.typeID));
                                sw.Write("\t");
                                sw.Write(NameType(typeIDs, product.typeID));
                                sw.WriteLine();
                            }
                        }
                    }
                }
            }

            using (StreamWriter sw = new StreamWriter("data/reactions_properties.csv"))
            {
                foreach (KeyValuePair<int, Blueprint> bpidBlueprint in blueprints)
                {
                    foreach (KeyValuePair<string, BlueprintActivity> activityNameActivity in bpidBlueprint.Value.activities)
                    {
                        if (activityNameActivity.Key != "reaction")
                            continue;

                        if (activityNameActivity.Value.materials == null || activityNameActivity.Value.products == null)
                            continue;

                        foreach (BlueprintActivityProduct product in activityNameActivity.Value.products)
                        {
                            sw.Write(NameType(typeIDs, product.typeID));
                            sw.Write("\t");
                            sw.Write(product.quantity.ToString());
                            sw.Write("\t");
                            sw.Write(activityNameActivity.Value.time.ToString());
                            sw.Write("\t");
                            sw.Write(bpidBlueprint.Key.ToString());
                            sw.Write("\t");
                            sw.Write(groupIDs[typeIDs[product.typeID].groupID].name["en"]);
                            sw.WriteLine();
                        }
                    }
                }
            }

            using (StreamWriter sw = new StreamWriter("data/reactions_normal.csv"))
            {
                foreach (KeyValuePair<int, Blueprint> bpidBlueprint in blueprints)
                {
                    foreach (KeyValuePair<string, BlueprintActivity> activityNameActivity in bpidBlueprint.Value.activities)
                    {
                        if (activityNameActivity.Key != "reaction")
                            continue;

                        if (activityNameActivity.Value.materials == null || activityNameActivity.Value.products == null)
                            continue;

                        foreach (BlueprintActivityProduct product in activityNameActivity.Value.products)
                        {
                            foreach (BlueprintActivityMaterial material in activityNameActivity.Value.materials)
                            {
                                sw.Write(material.quantity.ToString());
                                sw.Write("\t");
                                sw.Write(NameType(typeIDs, material.typeID));
                                sw.Write("\t");
                                sw.Write(NameType(typeIDs, product.typeID));
                                sw.WriteLine();
                            }
                        }
                    }
                }
            }

            using (StreamWriter sw = new StreamWriter("data/reactions_alchemy.csv"))
            {
                foreach (KeyValuePair<int, Blueprint> bpidBlueprint in blueprints)
                {
                    foreach (KeyValuePair<string, BlueprintActivity> activityNameActivity in bpidBlueprint.Value.activities)
                    {
                        if (activityNameActivity.Key != "reaction")
                            continue;

                        if (activityNameActivity.Value.materials == null || activityNameActivity.Value.products == null)
                            continue;

                        foreach (BlueprintActivityProduct product in activityNameActivity.Value.products)
                        {
                            string productName = NameType(typeIDs, product.typeID);

                            if (productName.StartsWith("Unrefined"))
                            {
                                List<TypeMaterial> typeMaterials = null;
                                if (indexedTypeMaterials.TryGetValue(product.typeID, out typeMaterials))
                                {
                                    foreach (TypeMaterial tm in typeMaterials)
                                    {
                                        sw.Write(productName);
                                        sw.Write("\t");
                                        sw.Write(tm.quantity.ToString(us));
                                        sw.Write("\t");
                                        sw.Write(NameType(typeIDs, tm.materialTypeID));
                                        sw.WriteLine();
                                    }
                                }
                            }
                        }
                    }
                }
            }

            using (StreamWriter sw = new StreamWriter("data/blueprints_properties.csv"))
            {
                foreach (KeyValuePair<int, Blueprint> bpidBlueprint in blueprints)
                {
                    foreach (KeyValuePair<string, BlueprintActivity> activityNameActivity in bpidBlueprint.Value.activities)
                    {
                        if (activityNameActivity.Key != "manufacturing")
                            continue;

                        if (activityNameActivity.Value.products == null)
                            continue;

                        double productionTime = activityNameActivity.Value.time;

                        TypeID blueprintTypeID;
                        double blueprintBasePrice = 0.0;
                        if (typeIDs.TryGetValue(bpidBlueprint.Key, out blueprintTypeID))
                            blueprintBasePrice = blueprintTypeID.basePrice;

                        foreach (BlueprintActivityProduct product in activityNameActivity.Value.products)
                        {
                            double researchCopyTime = 0.0;
                            double researchTechTime = 0.0;
                            double inventionProbability = 0.0;
                            double inventionRuns = 0.0;

                            foreach (KeyValuePair<string, BlueprintActivity> otherActivityNameActivity in bpidBlueprint.Value.activities)
                            {
                                if (otherActivityNameActivity.Key == "copying")
                                    researchCopyTime = otherActivityNameActivity.Value.time;
                                else if (otherActivityNameActivity.Key == "invention")
                                {
                                    researchTechTime = otherActivityNameActivity.Value.time;
                                    if (otherActivityNameActivity.Value.products != null)
                                    {
                                        foreach (BlueprintActivityProduct inventionProduct in otherActivityNameActivity.Value.products)
                                        {
                                            inventionProbability = inventionProduct.probability;
                                            inventionRuns = inventionProduct.quantity;
                                        }
                                    }
                                }
                            }

                            sw.Write(NameType(typeIDs, product.typeID));
                            sw.Write("\t");
                            sw.Write(researchCopyTime.ToString("G", us));
                            sw.Write("\t");
                            sw.Write(researchTechTime.ToString("G", us));
                            sw.Write("\t");
                            sw.Write(inventionProbability.ToString("G", us));
                            sw.Write("\t");
                            sw.Write(inventionRuns.ToString("G", us));
                            sw.Write("\t");
                            sw.Write(productionTime.ToString("G", us));
                            sw.Write("\t");
                            sw.Write(bpidBlueprint.Value.maxProductionLimit.ToString());
                            sw.Write("\t");
                            sw.Write(NameGroup(groupIDs, typeIDs, product.typeID));
                            sw.Write("\t");
                            sw.Write(bpidBlueprint.Key.ToString());
                            sw.Write("\t");
                            sw.Write(blueprintBasePrice.ToString());
                            sw.WriteLine();
                        }
                    }
                }
            }

            using (StreamWriter sw = new StreamWriter("data/blueprints_datacores.csv"))
            {
                using (StreamWriter swInvLoose = new StreamWriter("data/blueprints_invention_loose.csv"))
                {
                    foreach (KeyValuePair<int, Blueprint> bpidBlueprint in blueprints)
                    {
                        List<string> productNames = new List<string>();

                        foreach (KeyValuePair<string, BlueprintActivity> activityNameActivity in bpidBlueprint.Value.activities)
                        {
                            if (activityNameActivity.Key != "manufacturing")
                                continue;

                            if (activityNameActivity.Value.products == null)
                                continue;

                            double productionTime = activityNameActivity.Value.time;

                            foreach (BlueprintActivityProduct product in activityNameActivity.Value.products)
                                productNames.Add(NameType(typeIDs, product.typeID));
                        }

                        bool isLoose = (productNames.Count == 0);

                        if (isLoose)
                            productNames.Add("None");

                        string encryptionSkill = "None";

                        foreach (KeyValuePair<string, BlueprintActivity> otherActivityNameActivity in bpidBlueprint.Value.activities)
                        {
                            if (otherActivityNameActivity.Key == "invention")
                            {
                                if (otherActivityNameActivity.Value.materials == null)
                                    continue;

                                foreach (BlueprintActivitySkillRequirement skillReq in otherActivityNameActivity.Value.skills)
                                {
                                    string name = NameType(typeIDs, skillReq.typeID);
                                    if (name.Contains("Encryption Methods"))
                                        encryptionSkill = name;
                                }

                                foreach (BlueprintActivityMaterial inventionMat in otherActivityNameActivity.Value.materials)
                                {
                                    foreach (string productName in productNames)
                                    {
                                        if (isLoose)
                                            sw.Write(NameType(typeIDs, bpidBlueprint.Key));
                                        else
                                            sw.Write(productName);

                                        sw.Write("\t");
                                        sw.Write(NameType(typeIDs, inventionMat.typeID));
                                        sw.Write("\t");
                                        sw.Write(inventionMat.quantity.ToString());
                                        sw.Write("\t");
                                        sw.Write(encryptionSkill);
                                        sw.WriteLine();
                                    }
                                }

                                if (isLoose)
                                {
                                    foreach (BlueprintActivityProduct inventionProduct in otherActivityNameActivity.Value.products)
                                    {
                                        Blueprint inventedBP;
                                        if (!blueprints.TryGetValue(inventionProduct.typeID, out inventedBP))
                                            continue;

                                        BlueprintActivity inventedManufacturingActivity;
                                        if (!inventedBP.activities.TryGetValue("manufacturing", out inventedManufacturingActivity))
                                            continue;

                                        if (inventedManufacturingActivity.products == null)
                                            continue;

                                        foreach (BlueprintActivityProduct inventedBPProduct in inventedManufacturingActivity.products)
                                        {
                                            swInvLoose.Write(NameType(typeIDs, bpidBlueprint.Key));
                                            swInvLoose.Write("\t");
                                            swInvLoose.Write(NameType(typeIDs, inventedBPProduct.typeID));
                                            swInvLoose.Write("\t");
                                            swInvLoose.Write(inventionProduct.probability.ToString());
                                            swInvLoose.Write("\t");
                                            swInvLoose.Write(inventionProduct.quantity.ToString());
                                            swInvLoose.Write("\t");
                                            swInvLoose.Write(otherActivityNameActivity.Value.time.ToString());
                                            swInvLoose.WriteLine();
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            using (StreamWriter sw = new StreamWriter("data/blueprints_t2.csv"))
            {
                int techIImetaGroup = 0;
                int structureTechIImetaGroup = 0;

                foreach (KeyValuePair<int, MetaGroup> metaGroupPair in metaGroups)
                {
                    string metaGroupName;
                    if (metaGroupPair.Value.nameID.TryGetValue("en", out metaGroupName))
                    {
                        if (metaGroupName == "Tech II")
                            techIImetaGroup = metaGroupPair.Key;
                        if (metaGroupName == "Structure Tech II")
                            structureTechIImetaGroup = metaGroupPair.Key;
                    }
                }

                foreach (KeyValuePair<int, TypeID> typeIDPair in typeIDs)
                {
                    TypeID parentTypeID;
                    if ((typeIDPair.Value.metaGroupID == techIImetaGroup || typeIDPair.Value.metaGroupID == structureTechIImetaGroup) && typeIDPair.Value.variationParentTypeID != null && typeIDs.TryGetValue((int)typeIDPair.Value.variationParentTypeID, out parentTypeID))
                    {
                        sw.Write(parentTypeID.name["en"]);
                        sw.Write("\t");
                        sw.Write(typeIDs[typeIDPair.Key].name["en"]);
                        sw.Write("\t");
                        sw.Write(groupIDs[typeIDPair.Value.groupID].name["en"]);
                        sw.Write("\t");
                        sw.Write(categoryIDs[groupIDs[typeIDPair.Value.groupID].categoryID].name["en"]);
                        sw.WriteLine();
                    }
                }
            }

            using (StreamWriter sw = new StreamWriter("data/blueprints_multiplequantity.csv"))
            {
                foreach (KeyValuePair<int, Blueprint> bpidBlueprint in blueprints)
                {
                    foreach (KeyValuePair<string, BlueprintActivity> activityNameActivity in bpidBlueprint.Value.activities)
                    {
                        if (activityNameActivity.Key != "manufacturing")
                            continue;

                        if (activityNameActivity.Value.products == null)
                            continue;

                        foreach (BlueprintActivityProduct product in activityNameActivity.Value.products)
                        {
                            if (product.quantity != 1)
                            {
                                sw.Write(NameType(typeIDs, product.typeID));
                                sw.Write("\t");
                                sw.Write(product.quantity.ToString());
                                sw.WriteLine();
                            }
                        }
                    }
                }
            }

            using (StreamWriter sw = new StreamWriter("data/cache/names.dat"))
            {
                foreach (KeyValuePair<int, TypeID> typeID in typeIDs)
                {
                    sw.Write(typeID.Key.ToString());
                    sw.Write("\t");
                    sw.Write(NameType(typeIDs, typeID.Key));
                    sw.WriteLine();
                }
            }

            using (StreamWriter sw = new StreamWriter("data/cache/names_marketonly.dat"))
            {
                foreach (KeyValuePair<int, TypeID> typeID in typeIDs)
                {
                    if (typeID.Value.marketGroupID == 0 || !typeID.Value.published)
                        continue;

                    sw.Write(typeID.Key.ToString());
                    sw.Write("\t");
                    sw.Write(NameType(typeIDs, typeID.Key));
                    sw.WriteLine();
                }
            }

            using (StreamWriter sw = new StreamWriter("data/cache/legacy_names.dat"))
            {
                foreach (KeyValuePair<long, string> name in names)
                {
                    sw.Write(name.Key.ToString());
                    sw.Write("\t");
                    sw.Write(name.Value);
                    sw.WriteLine();
                }
            }

            using (StreamWriter sw = new StreamWriter("data/cache/items_properties.dat"))
            {
                List<int> typeIDKeys = new List<int>();
                foreach (KeyValuePair<int, TypeID> typeID in typeIDs)
                    typeIDKeys.Add(typeID.Key);

                sw.WriteLine("item\tvolume\tbasePrice");
                foreach (int key in typeIDKeys)
                {
                    TypeID typeID = typeIDs[key];

                    sw.Write(NameType(typeIDs, key));
                    sw.Write("\t");
                    sw.Write(typeID.volume.ToString(us));
                    sw.Write("\t");
                    sw.Write(typeID.basePrice);
                    sw.WriteLine();
                }
            }

            using (StreamWriter sw = new StreamWriter("data/cache/reprocessing_t1.dat"))
            {
                string[] mineralsSorted = new string[] { "Tritanium", "Pyerite", "Mexallon", "Isogen", "Nocxium", "Zydrine", "Megacyte" };

                Dictionary<string, int> mineralsMap = new Dictionary<string, int>();
                for (int i = 0; i < mineralsSorted.Length; i++)
                    mineralsMap[mineralsSorted[i]] = i;

                sw.Write("item");
                foreach (string mineral in mineralsSorted)
                {
                    sw.Write('\t');
                    sw.Write(mineral.ToLowerInvariant());
                }

                sw.WriteLine();

                foreach (KeyValuePair<int, List<TypeMaterial>> typeIDMaterials in indexedTypeMaterials)
                {
                    if (typeIDMaterials.Value.Count == 0)
                        continue;

                    bool anyNonMinerals = false;
                    double[] numMinerals = new double[mineralsSorted.Length];
                    foreach (TypeMaterial tm in typeIDMaterials.Value)
                    {
                        string materialName = NameType(typeIDs, tm.materialTypeID);
                        int matIndex;
                        if (mineralsMap.TryGetValue(materialName, out matIndex))
                            numMinerals[matIndex] += tm.quantity;
                        else
                            anyNonMinerals = true;
                    }

                    if (!anyNonMinerals)
                    {
                        sw.Write(NameType(typeIDs, typeIDMaterials.Key));

                        for (int i = 0; i < mineralsSorted.Length; i++)
                        {
                            sw.Write('\t');
                            sw.Write(numMinerals[i]);
                        }

                        sw.WriteLine();
                    }
                }
            }
        }
    }
}
