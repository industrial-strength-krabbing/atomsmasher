using System;
using System.Collections.Generic;
using System.IO;
using System.Text;
using System.Threading;
using Microsoft.Win32;
using System.Net;
using System.Security.Cryptography;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System.Reflection;
using System.Globalization;

namespace ESIHandler
{
    public class AuthToken
    {
        public string access_token { get; set; }
        public double expires_in { get; set; }
        public string token_type { get; set; }
        public string refresh_token { get; set; }
    }

    public class CharacterAuthInfo
    {
        public long CharacterID { get; set; }
        public string CharacterName { get; set; }
        public DateTime ExpirationTimeUTC { get; set; }
        public string AccessToken { get; set; }
        public string RefreshToken { get; set; }
    }

    public class CharacterInfo
    {
        public CharacterInfo(long characterID, string name)
        {
            CharacterID = characterID;
            Name = name;
        }

        public long CharacterID { get; private set; }
        public string Name { get; private set; }
    }

    public class Handler
    {
        const int TokenFileVersion = 1;
        const int QueryCacheVersion = 3;
        
        const string ESIPrefix = "https://esi.evetech.net/latest";

        private string protocol;
        private string clientID;
        private string callbackURI;
        private string pendingAuthPath;
        private string tokenFilePath;
        private string exePath;
        private IEnumerable<string> defaultScopes;
        private string applicationName;
        private List<CharacterAuthInfo> authInfos;

        public Handler(string protocol, string clientID, string callbackURI, string pendingAuthPath,
            string tokenFilePath, string exePath, IEnumerable<string> defaultScopes, string applicationName)
        {
            this.protocol = protocol;
            this.clientID = clientID;
            this.callbackURI = callbackURI;
            this.pendingAuthPath = pendingAuthPath;
            this.tokenFilePath = tokenFilePath;
            this.defaultScopes = defaultScopes;
            this.applicationName = applicationName;
            this.exePath = exePath;

            authInfos = ReadAuthTokens();
        }

        public string Authorize(long characterID)
        {
            int index = -1;

            for (int i = 0; i < authInfos.Count; i++)
            {
                if (authInfos[i].CharacterID == characterID)
                    index = i;
            }

            if (index == -1)
                throw new Exception("Bad character ID");

            CharacterAuthInfo authInfo = authInfos[index];

            double expiryTolerance = 60.0;

            double timeToExpiry = authInfo.ExpirationTimeUTC.Subtract(DateTime.UtcNow).TotalSeconds;
            if (timeToExpiry < expiryTolerance)
            {
                Console.WriteLine("Auth token expired for " + authInfo.CharacterName + ", getting a new one...");
                authInfo = RefreshToken(authInfo);
                if (authInfo == null)
                {
                    authInfos.RemoveAt(index);
                    return null;
                }
                else
                    authInfos[index] = authInfo;
            }

            return authInfo.AccessToken;
        }

        public CharacterAuthInfo RefreshToken(CharacterAuthInfo authInfo)
        {
            byte[] requestData;

            {
                StringBuilder tokenSB = new StringBuilder();
                tokenSB.Append("grant_type=refresh_token");
                tokenSB.Append("&refresh_token=");
                tokenSB.Append(WebUtility.UrlEncode(authInfo.RefreshToken));
                tokenSB.Append("&client_id=");
                tokenSB.Append(this.clientID);

                string tokenStr = tokenSB.ToString();

                requestData = Encoding.ASCII.GetBytes(tokenStr);
            }

            HttpWebRequest webRequest = WebRequest.CreateHttp("https://login.eveonline.com/v2/oauth/token");
            webRequest.Method = "POST";
            webRequest.ContentType = "application/x-www-form-urlencoded";
            webRequest.Host = "login.eveonline.com";
            webRequest.ContentLength = requestData.Length;

            Stream rq = webRequest.GetRequestStream();
            rq.Write(requestData, 0, requestData.Length);
            rq.Close();

            WebResponse response = webRequest.GetResponse();
            Stream responseStream = response.GetResponseStream();

            return InstallAuthToken(responseStream);
        }

        public CharacterInfo[] GetCharacters()
        {
            List<CharacterInfo> chars = new List<CharacterInfo>();

            foreach (CharacterAuthInfo authInfo in authInfos)
                chars.Add(new CharacterInfo(authInfo.CharacterID, authInfo.CharacterName));

            return chars.ToArray();
        }

        List<CharacterAuthInfo> ReadAuthTokens()
        {
            string authTokensPath = GetRootDirectory() + "/" + tokenFilePath;

            try
            {
                using (StreamReader sr = new StreamReader(authTokensPath))
                {
                    List<CharacterAuthInfo> authInfos = new List<CharacterAuthInfo>();

                    int version = int.Parse(sr.ReadLine());
                    if (version != TokenFileVersion)
                        return authInfos;

                    int numTokens = int.Parse(sr.ReadLine());

                    for (int i = 0; i < numTokens; i++)
                    {
                        CharacterAuthInfo authInfo = new CharacterAuthInfo();

                        authInfo.CharacterName = sr.ReadLine();
                        authInfo.CharacterID = long.Parse(sr.ReadLine());
                        authInfo.ExpirationTimeUTC = DateTime.FromBinary(long.Parse(sr.ReadLine()));
                        authInfo.AccessToken = sr.ReadLine();
                        authInfo.RefreshToken = sr.ReadLine();

                        authInfos.Add(authInfo);
                    }

                    return authInfos;
                }
            }
            catch (Exception)
            {
                Console.WriteLine("Auth tokens file was unreadable or doesn't exist, creating a new one.");
                return new List<CharacterAuthInfo>();
            }
        }

        void WriteAuthTokens(IReadOnlyList<CharacterAuthInfo> authInfos)
        {
            string authTokensPath = GetRootDirectory() + "/" + tokenFilePath;

            using (StreamWriter sw = new StreamWriter(authTokensPath))
            {
                sw.WriteLine(TokenFileVersion);
                sw.WriteLine(authInfos.Count);

                foreach (CharacterAuthInfo authInfo in authInfos)
                {
                    sw.WriteLine(authInfo.CharacterName);
                    sw.WriteLine(authInfo.CharacterID);
                    sw.WriteLine(authInfo.ExpirationTimeUTC.ToBinary());
                    sw.WriteLine(authInfo.AccessToken);
                    sw.WriteLine(authInfo.RefreshToken);
                }
            }
        }

        string GetExpectedPath()
        {
            return exePath;
        }

        private IEnumerable<string> GetDefaultScopes()
        {
            return defaultScopes;
        }

        string GetRootDirectory()
        {
            string myPath = GetExpectedPath();
            for (int i = 0; i < 5; i++)
                myPath = Path.GetDirectoryName(myPath);

            return myPath;
        }

        bool CheckRegistryKey()
        {
            string commandLine = "\"" + GetExpectedPath() + "\" \"Install\" \"%1\"";

            object handlerPath = Registry.GetValue(@"HKEY_CLASSES_ROOT\" + protocol + @"\shell\open\command\", "", null);

            if (handlerPath == null || handlerPath.GetType() != typeof(string) || (string)handlerPath != commandLine)
            {
                using (StreamWriter sw = new StreamWriter("uri_handler_install.reg"))
                {
                    sw.WriteLine("Windows Registry Editor Version 5.00");
                    sw.WriteLine();
                    sw.WriteLine("[HKEY_CLASSES_ROOT\\" + protocol + "]");
                    sw.WriteLine("@=\"URL:" + applicationName + " Auth Handler\"");
                    sw.WriteLine("\"URL Protocol\"=\"\"");
                    sw.WriteLine();
                    sw.WriteLine("[HKEY_CLASSES_ROOT\\" + protocol + "\\shell]");
                    sw.WriteLine();
                    sw.WriteLine("[HKEY_CLASSES_ROOT\\" + protocol + "\\shell\\open]");
                    sw.WriteLine();
                    sw.WriteLine("[HKEY_CLASSES_ROOT\\" + protocol + "\\shell\\open\\command]");
                    sw.WriteLine("@=\"" + commandLine.Replace("\\", "\\\\").Replace("\"", "\\\"") + "\"");
                }

                Console.WriteLine(applicationName + "'s URI handler isn't registered, or is set to the wrong path.");
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

        void GetSSOParameters(IEnumerable<string> requestedScopes, out byte[] secureKeyOut, out string stateOut, out string uriOut)
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
            uriParameters.Add(new KeyValuePair<string, string>("redirect_uri", callbackURI));
            uriParameters.Add(new KeyValuePair<string, string>("client_id", clientID));
            uriParameters.Add(new KeyValuePair<string, string>("scope", scopesList));
            uriParameters.Add(new KeyValuePair<string, string>("code_challenge", UrlSafeBase64Encode(challenge)));
            uriParameters.Add(new KeyValuePair<string, string>("code_challenge_method", "S256"));
            uriParameters.Add(new KeyValuePair<string, string>("state", UrlSafeBase64Encode(stateKey)));

            secureKeyOut = randomKey;
            stateOut = UrlSafeBase64Encode(stateKey);
            uriOut = EncodeUri("http://login.eveonline.com/v2/oauth/authorize/", uriParameters);
        }

        public void Authenticate()
        {
            byte[] key;
            string authState;
            string uri;
            GetSSOParameters(GetDefaultScopes(), out key, out authState, out uri);

            Console.WriteLine("Writing pending auth config...");
            using (StreamWriter sw = new StreamWriter(GetRootDirectory() + "/" + pendingAuthPath))
            {
                sw.WriteLine(UrlSafeBase64Encode(key));
                sw.WriteLine(authState);
            }

            Console.WriteLine("Pending auth registered, launching browser...");

            try
            {
                System.Diagnostics.Process.Start(uri);
            }
            catch (System.ComponentModel.Win32Exception)
            {
                Console.WriteLine("Failed to launch browser.  Open it manually and visit the following URL:\n");
                Console.WriteLine(uri);
                Console.WriteLine("\nAfterwards, copy the response URL and run the following command:");
                Console.WriteLine("mono SDEParser/AtomSmasherESITool/bin/Release/AtomSmasherESITool.exe Install [RESPONSE URL]");
            }
        }

        static CharacterAuthInfo UnpackToken(AuthToken authToken)
        {
            string[] tokenParts = authToken.access_token.Split('.');

            byte[] payload = UrlSafeBase64Decode(tokenParts[1]);

            JsonTextReader reader = new JsonTextReader(new StringReader(Encoding.ASCII.GetString(payload)));
            JObject rootObject = (JObject)JToken.ReadFrom(reader);

            JToken subToken;
            if (!rootObject.TryGetValue("sub", out subToken))
                throw new Exception("Missing 'sub' in JWT token");

            JValue subValue = (JValue)subToken;
            string packedSubID = (string)subValue.Value;

            string charPrefix = "CHARACTER:EVE:";

            if (!packedSubID.StartsWith(charPrefix))
                throw new Exception("Malformed(?) character ID");

            JToken nameToken;
            if (!rootObject.TryGetValue("name", out nameToken))
                throw new Exception("Missing character name");

            CharacterAuthInfo authInfo = new CharacterAuthInfo();
            authInfo.AccessToken = authToken.access_token;
            authInfo.RefreshToken = authToken.refresh_token;
            authInfo.ExpirationTimeUTC = DateTime.UtcNow.AddSeconds(authToken.expires_in);
            authInfo.CharacterID = long.Parse(packedSubID.Substring(charPrefix.Length));
            authInfo.CharacterName = (string)((JValue)nameToken).Value;

            return authInfo;
        }

        CharacterAuthInfo InstallAuthToken(Stream stream)
        {
            StreamReader sr = new StreamReader(stream);
            string json = sr.ReadToEnd();

            AuthToken token = JsonConvert.DeserializeObject<AuthToken>(json);

            CharacterAuthInfo authInfo = UnpackToken(token);

            List<CharacterAuthInfo> authInfos = ReadAuthTokens();
            for (int i = 0; i < authInfos.Count; i++)
            {
                if (authInfos[i].CharacterID == authInfo.CharacterID)
                {
                    authInfos.RemoveAt(i);
                    i--;
                }
            }

            authInfos.Add(authInfo);

            WriteAuthTokens(authInfos);

            return authInfo;
        }

        public void InstallTokenFromUri(string uri)
        {
            if (!uri.StartsWith(callbackURI + "?"))
            {
                Console.WriteLine("Invalid callback URI");
                Environment.ExitCode = -1;
                return;
            }

            Dictionary<string, string> queryParams = new Dictionary<string, string>();

            foreach (string kvp in uri.Substring(callbackURI.Length + 1).Split('&'))
            {
                int split = kvp.IndexOf('=');
                string key, value;
                if (split < 0)
                {
                    key = kvp;
                    value = "";
                }
                else
                {
                    key = kvp.Substring(0, split);
                    value = kvp.Substring(split + 1);
                }

                queryParams[WebUtility.UrlDecode(key)] = WebUtility.UrlDecode(value);
            }

            string pendingAuthPath = GetRootDirectory() + "/" + this.pendingAuthPath;

            if (!File.Exists(pendingAuthPath))
            {
                Console.WriteLine("No pending authorization was found");
                Environment.ExitCode = -1;
                CloseoutCountdown(10);
                return;
            }

            string keyBase64;
            string expectedState;

            using (StreamReader sr = new StreamReader(pendingAuthPath))
            {
                keyBase64 = sr.ReadLine();
                expectedState = sr.ReadLine();
            }

            if (expectedState != queryParams["state"])
            {
                Console.WriteLine("State from ESI didn't match pending auth, something's weird.");
                Environment.ExitCode = -1;
                CloseoutCountdown(10);
                return;
            }

            string code = queryParams["code"];
            byte[] requestData;

            {
                StringBuilder tokenSB = new StringBuilder();
                tokenSB.Append("grant_type=authorization_code");
                tokenSB.Append("&code=");
                tokenSB.Append(WebUtility.UrlEncode(code));
                tokenSB.Append("&client_id=");
                tokenSB.Append(clientID);
                tokenSB.Append("&code_verifier=");
                tokenSB.Append(keyBase64);

                string tokenStr = tokenSB.ToString();

                requestData = Encoding.ASCII.GetBytes(tokenStr);
            }

            HttpWebRequest webRequest = WebRequest.CreateHttp("https://login.eveonline.com/v2/oauth/token");
            webRequest.Method = "POST";
            webRequest.ContentType = "application/x-www-form-urlencoded";
            webRequest.Host = "login.eveonline.com";
            webRequest.ContentLength = requestData.Length;

            Stream rq = webRequest.GetRequestStream();
            rq.Write(requestData, 0, requestData.Length);
            rq.Close();

            Console.WriteLine("Requesting authorization...");

            WebResponse response = webRequest.GetResponse();
            Stream responseStream = response.GetResponseStream();

            CharacterAuthInfo authInfo = InstallAuthToken(responseStream);

            Console.WriteLine("Authorization was successful!  Installed token for character " + authInfo.CharacterName);
            CloseoutCountdown(10);
        }

        public byte[] ExecutePublicESIQuery(string endpoint, IEnumerable<KeyValuePair<string, string>> kvps, bool cacheable, out int pages)
        {
            List<KeyValuePair<string, string>> modifiedKVPs = new List<KeyValuePair<string, string>>(kvps);
            modifiedKVPs.Add(new KeyValuePair<string, string>("datasource", "tranquility"));

            return ExecuteQuery(ESIPrefix + endpoint, modifiedKVPs, cacheable, null, out pages);
        }

        public byte[] ExecuteSecureESIQuery(string endpoint, long characterID, IEnumerable<KeyValuePair<string, string>> kvps, bool cacheable, out int pages)
        {
            string auth = this.Authorize(characterID);

            List<KeyValuePair<string, string>> modifiedKVPs = new List<KeyValuePair<string, string>>(kvps);
            modifiedKVPs.Add(new KeyValuePair<string, string>("datasource", "tranquility"));

            return ExecuteQuery(ESIPrefix + endpoint, modifiedKVPs, cacheable, auth, out pages);
        }

        byte[] ExecuteQuery(string baseUri, IEnumerable<KeyValuePair<string, string>> kvps, bool cacheable, string auth, out int pages)
        {
            string uri = EncodeUri(baseUri, kvps);
            string basicURI = uri;

            if (auth != null)
                uri += "&token=" + auth;

            pages = -1;

            if (cacheable)
            {
                SHA256 hash = SHA256.Create();

                string queryName = UrlSafeBase64Encode(hash.ComputeHash(Encoding.ASCII.GetBytes(basicURI)));

                HttpWebResponse response;

                string queryCachePath = GetRootDirectory() + "/data/cache/queries/" + queryName + ".cache";
                if (File.Exists(queryCachePath))
                {
                    using (FileStream fs = new FileStream(queryCachePath, FileMode.Open, FileAccess.Read))
                    {
                        using (BinaryReader br = new BinaryReader(fs, Encoding.UTF8))
                        {
                            if (br.ReadUInt32() == QueryCacheVersion)
                            {
                                string etag = br.ReadString();

                                HttpWebRequest webRequest = WebRequest.CreateHttp(uri);
                                webRequest.Method = "GET";
                                webRequest.Headers.Add("If-None-Match", etag);

                                try
                                {
                                    response = (HttpWebResponse)webRequest.GetResponse();
                                }
                                catch (WebException we)
                                {
                                    response = (HttpWebResponse)we.Response;

                                    if (response.StatusCode != HttpStatusCode.NotModified)
                                        throw;
                                }

                                if (response.StatusCode == HttpStatusCode.NotModified)
                                {
                                    pages = br.ReadInt32();
                                    ulong cacheSize = br.ReadUInt64();
                                    byte[] cachedBytes = new byte[cacheSize];
                                    br.Read(cachedBytes, 0, (int)cacheSize);
                                    return cachedBytes;
                                }
                            }
                            else
                            {
                                HttpWebRequest webRequest = WebRequest.CreateHttp(uri);
                                webRequest.Method = "GET";

                                response = (HttpWebResponse)webRequest.GetResponse();
                            }
                        }
                    }
                }
                else
                {
                    HttpWebRequest webRequest = WebRequest.CreateHttp(uri);
                    webRequest.Method = "GET";

                    response = (HttpWebResponse)webRequest.GetResponse();
                }

                byte[] bytes;
                using (MemoryStream ms = new MemoryStream())
                {
                    response.GetResponseStream().CopyTo(ms);
                    bytes = ms.ToArray();
                }

                string newEtag = response.Headers.Get("etag");
                string pagesStr = response.Headers.Get("X-Pages");

                if (pagesStr != null)
                {
                    if (!int.TryParse(pagesStr, out pages))
                        pages = -1;
                }

                if (newEtag != null)
                {
                    using (FileStream fs = new FileStream(queryCachePath, FileMode.Create, FileAccess.Write))
                    {
                        using (BinaryWriter bw = new BinaryWriter(fs, Encoding.UTF8))
                        {
                            bw.Write(QueryCacheVersion);
                            bw.Write(newEtag);
                            bw.Write(pages);
                            bw.Write(bytes.LongLength);
                            bw.Write(bytes);
                        }
                    }
                }

                return bytes;
            }
            else
            {

                HttpWebRequest webRequest = WebRequest.CreateHttp(uri);
                webRequest.Method = "GET";
                if (auth != null)
                    webRequest.Headers.Add("Authorizaton", "Bearer " + auth);

                HttpWebResponse response = (HttpWebResponse)webRequest.GetResponse();
                byte[] bytes;
                using (MemoryStream ms = new MemoryStream())
                {
                    response.GetResponseStream().CopyTo(ms);
                    bytes = ms.ToArray();
                }

                return bytes;
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
    }
}
