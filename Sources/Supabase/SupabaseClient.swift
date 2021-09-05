import GoTrue
import PostgREST
import Realtime
import SupabaseStorage

/**
 The main class for accessing Supabase functionality
 
 Initialize this class using `.init(supabaseURL: String, supabaseKey: String)`
 
 There are four main classes contained by the `Supabase` class.
 1.  `auth`
 2.  `database`
 3.  `realtime`
 4.  `storage`
 Each class listed is available under `Supabase.{name}`, eg: `Supabase.auth`
 
 For more usage information read the README.md
 */
public class SupabaseClient {
    
    // MARK: - Properties
    
    private var supabaseUrl: String
    private var supabaseKey: String
    private var schema: String
    private var restUrl: String
    private var realtimeUrl: String
    private var authUrl: String
    private var storageUrl: String
    
    // MARK: - Clients
    
    /// Auth client for Supabase
    public var auth: GoTrueClient
    
    /// Storage client for Supabase.
    public var storage: SupabaseStorageClient {
        var headers: [String: String] = [:]
        headers["apikey"] = supabaseKey
        headers["Authorization"] = "Bearer \(auth.session?.accessToken ?? supabaseKey)"
        return SupabaseStorageClient(url: storageUrl, headers: headers)
    }
    
    /// Database client for Supabase.
    public var database: PostgrestClient {
        var headers: [String: String] = [:]
        headers["apikey"] = supabaseKey
        headers["Authorization"] = "Bearer \(auth.session?.accessToken ?? supabaseKey)"
        return PostgrestClient(url: restUrl, headers: headers, schema: schema)
    }
    
    private var realtimeClient: RealtimeClient {
        return RealtimeClient(endPoint: realtimeUrl, params: ["apikey": supabaseKey])
    }
    
    // MARK: - Init
    /// Init `Supabase` with the provided parameters.
    /// - Parameters:
    ///   - supabaseUrl: Unique Supabase project url
    ///   - supabaseKey: Supabase anonymous API Key
    ///   - schema: Database schema name, defaults to `public`
    ///   - autoRefreshToken: Toggles whether `Supabase.auth` automatically refreshes auth tokens. Defaults to `true`
    public init(
        supabaseUrl: String,
        supabaseKey: String,
        schema: String = "public",
        autoRefreshToken: Bool = true,
        listenForAuthChanges: Bool = false
    ) {
        self.supabaseUrl = supabaseUrl
        self.supabaseKey = supabaseKey
        self.schema = schema
        restUrl = "\(supabaseUrl)/rest/v1"
        realtimeUrl = "\(supabaseUrl)/realtime/v1"
        authUrl = "\(supabaseUrl)/auth/v1"
        storageUrl = "\(supabaseUrl)/storage/v1"
        
        auth = GoTrueClient(
            url: authUrl,
            headers: ["apikey": supabaseKey],
            autoRefreshToken: autoRefreshToken
        )
        
        if listenForAuthChanges {
            setUpAuthListener()
        }
    }
    
    // MARK: - Auth state listener
    
    private var authStateListener: ((AuthChangeEvent) -> Void)? = nil
    
    /// Set up a state change listener to update the database and storage auth headers
    private func setUpAuthListener() {
        authStateListener = { [weak self] event in
            self?.updateClientHeaders()
        }
        auth.onAuthStateChange = authStateListener
    }
    
    /// Updates the database and storage client's auth header
    private func updateClientHeaders() {
        database.config.headers["Authorization"] = "Bearer \(auth.session?.accessToken ?? supabaseKey)"
        storage.config.headers["Authorization"] = "Bearer \(auth.session?.accessToken ?? supabaseKey)"
    }
    
    // MARK: - Deinit
    
    deinit {
        authStateListener = nil
        auth.onAuthStateChange = nil
    }
}
