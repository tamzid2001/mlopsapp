import SwiftUI
import Charts
import Combine
import StoreKit
import AuthenticationServices
extension View {
    func cardWidth() -> some View {
        self.frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Main App Structure
@main
struct MAOptionsApp: App {
    @StateObject private var authManager = AuthenticationManager()
    @StateObject private var purchaseManager = PurchaseManager()
    @StateObject private var dataManager = DataManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .environmentObject(purchaseManager)
                .environmentObject(dataManager)
                .onAppear {
                    Task {
                        await purchaseManager.loadProducts()
                    }
                }
        }
    }
}

// MARK: - Tab View Structure
struct MainTabView: View {
    @State private var selectedTab = 0
    @EnvironmentObject var purchaseManager: PurchaseManager
    
    var body: some View {
        TabView(selection: $selectedTab) {
            CourseContentView()
                .tabItem {
                    Label("Courses", systemImage: "play.rectangle.fill")
                }
                .tag(0)
            
            AnalyticsToolsView()
                .tabItem {
                    Label("Analytics", systemImage: "chart.xyaxis.line")
                }
                .tag(1)
            
            TradingToolsView()
                .tabItem {
                    Label("Trading", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(2)
            
            BlogView()
                .tabItem {
                    Label("Blog", systemImage: "newspaper")
                }
                .tag(3)
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.circle")
                }
                .tag(4)
        }
        .accentColor(.blue)
    }
}

// MARK: - Authentication Manager
class AuthenticationManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isPremium = false
    
    struct User {
        let id: String
        let email: String
        let name: String
        var purchasedCourses: Set<String> = []
    }
    
    func signIn(email: String, password: String) async -> Bool {
        // Simulate API call
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        DispatchQueue.main.async {
            self.currentUser = User(id: UUID().uuidString, email: email, name: "User")
            self.isAuthenticated = true
            self.checkPremiumStatus()
        }
        return true
    }
    
    func signInWithApple() async {
        // Implement Sign in with Apple
        DispatchQueue.main.async {
            self.isAuthenticated = true
        }
    }
    
    func signOut() {
        isAuthenticated = false
        currentUser = nil
        isPremium = false
    }
    
    func checkPremiumStatus() {
        // Check KeyChain or UserDefaults for premium status
        isPremium = UserDefaults.standard.bool(forKey: "isPremium")
    }
}

// MARK: - Purchase Manager
class PurchaseManager: ObservableObject {
    @Published var products: [Product] = []
    @Published var purchasedProductIDs: Set<String> = []
    
    enum ProductID: String, CaseIterable {
        case premiumMonthly = "com.maOptions.premium.monthly"
        case premiumYearly = "com.maOptions.premium.yearly"
        case lifetimeAccess = "com.maOptions.lifetime"
    }
    
    func loadProducts() async {
        // Load StoreKit products
        do {
            products = try await Product.products(for: ProductID.allCases.map { $0.rawValue })
        } catch {
            print("Failed to load products: \(error)")
        }
    }
    
    func purchase(_ product: Product) async throws -> Bool {
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            switch verification {
            case .verified(let transaction):
                await transaction.finish()
                DispatchQueue.main.async {
                    self.purchasedProductIDs.insert(product.id)
                    UserDefaults.standard.set(true, forKey: "isPremium")
                }
                return true
            case .unverified:
                return false
            }
        case .userCancelled, .pending:
            return false
        @unknown default:
            return false
        }
    }
}

// MARK: - Data Manager
class DataManager: ObservableObject {
    @Published var stockData: [StockDataPoint] = []
    @Published var sagemakerPredictions: [Prediction] = []
    @Published var csvData: [[String]] = []
    
    struct StockDataPoint: Identifiable {
        let id = UUID()
        let date: Date
        let price: Double
        let volume: Int
    }
    
    struct Prediction {
        let date: Date
        let predictedPrice: Double
        let confidence: Double
        let optionStrategy: String
    }
    
    func fetchLatestStockPrice(symbol: String) async {
        // API call to fetch stock data
        guard let url = URL(string: "https://api.example.com/stock/\(symbol)") else { return }
        
        // Simulate API response
        DispatchQueue.main.async {
            self.stockData = self.generateMockStockData()
        }
    }
    
    func analyzeSageMakerCSV(fileURL: URL) async {
        // Process CSV and send to SageMaker endpoint
        // This would integrate with AWS SDK
        DispatchQueue.main.async {
            self.sagemakerPredictions = self.generateMockPredictions()
        }
    }
    
    private func generateMockStockData() -> [StockDataPoint] {
        (0..<30).map { i in
            StockDataPoint(
                date: Date().addingTimeInterval(-Double(i) * 86400),
                price: 150 + Double.random(in: -10...10),
                volume: Int.random(in: 1000000...5000000)
            )
        }
    }
    
    private func generateMockPredictions() -> [Prediction] {
        (1...7).map { i in
            Prediction(
                date: Date().addingTimeInterval(Double(i) * 86400),
                predictedPrice: 155 + Double.random(in: -5...5),
                confidence: Double.random(in: 0.7...0.95),
                optionStrategy: ["Bull Call Spread", "Iron Condor", "Protective Put"].randomElement()!
            )
        }
    }
}

// MARK: - Login View
struct LoginView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var showingSignUp = false
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(colors: [.blue.opacity(0.1), .purple.opacity(0.1)],
                             startPoint: .topLeading,
                             endPoint: .bottomTrailing)
                    .ignoresSafeArea()
                
                LazyVStack(alignment: .leading, spacing: 30) {
                    LazyVStack(alignment: .leading, spacing: 10) {
                        Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.blue)
                        
                        Text("M&A Options Pro")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Advanced Valuations & MLOps")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 50)
                    
                        TextField("Email", text: $email)
                            .textFieldStyle(ModernTextFieldStyle())
                        #if os(iOS) || targetEnvironment(macCatalyst)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                        #endif

                        
                        SecureField("Password", text: $password)
                            .textFieldStyle(ModernTextFieldStyle())
                        
                        Button(action: signIn) {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Sign In")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        
                        SignInWithAppleButton(
                            onRequest: { _ in },
                            onCompletion: { _ in
                                Task {
                                    await authManager.signInWithApple()
                                }
                            }
                        )
                        .signInWithAppleButtonStyle(.black)
                        .frame(height: 50)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 30)
                    
                    Button("Don't have an account? Sign Up") {
                        showingSignUp = true
                    }
                    .foregroundColor(.blue)
                    
                    Spacer()
                }
            }
            .sheet(isPresented: $showingSignUp) {
                SignUpView()
            }
        }
    func signIn() {
        isLoading = true
        Task {
            await authManager.signIn(email: email, password: password)
            isLoading = false
        }
    }
    }


// MARK: - Course Content View
struct CourseContentView: View {
    @EnvironmentObject var purchaseManager: PurchaseManager
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var selectedVideo: Video?
    @State private var searchText = ""
    
    let courses = [
        Course(id: "1", title: "Options Fundamentals", videos: generateVideos(count: 8, free: 2)),
        Course(id: "2", title: "Advanced M&A Valuations", videos: generateVideos(count: 10, free: 1)),
        Course(id: "3", title: "MLOps with SageMaker", videos: generateVideos(count: 12, free: 2)),
        Course(id: "4", title: "Time Series Forecasting", videos: generateVideos(count: 6, free: 1)),
        Course(id: "5", title: "Risk Management Strategies", videos: generateVideos(count: 8, free: 1))
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 20) {
                    SearchBar(text: $searchText)
                        .padding(.horizontal)
                    
                    if !authManager.isPremium {
                        PremiumBanner()
                            .padding(.horizontal)
                    }
                    
                    ForEach(courses) { course in
                        CourseSection(course: course, selectedVideo: $selectedVideo)
                    }
                }
                .padding(.vertical)
                .frame(maxWidth: .infinity)
            }
            .navigationTitle("Courses")
            .sheet(item: $selectedVideo) { video in
                VideoPlayerView(video: video)
            }
        }
    }
    
    static func generateVideos(count: Int, free: Int) -> [Video] {
        (0..<count).map { i in
            Video(
                id: UUID().uuidString,
                title: "Lesson \(i + 1)",
                duration: "\(Int.random(in: 5...25)) min",
                thumbnailURL: "thumbnail",
                videoURL: "video_url",
                isFree: i < free,
                description: "Comprehensive lesson covering key concepts"
            )
        }
    }
}

// MARK: - Analytics Tools View
struct AnalyticsToolsView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var selectedSymbol = "AAPL"
    @State private var showingCSVImporter = false
    @State private var showingSageMakerAnalysis = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Stock Price Tool
                    StockPriceCard(selectedSymbol: $selectedSymbol)
                    
                    // Chart Visualization
                    if !dataManager.stockData.isEmpty {
                        StockChartView(data: dataManager.stockData)
                            .frame(height: 250)
                            .padding()
                            .background(.background)
                            .cornerRadius(15)
                            .shadow(radius: 2)
                    }
                    
                    // CSV Analysis Tool
                    AnalysisToolCard(
                        title: "CSV Pattern Analyzer",
                        icon: "doc.text.magnifyingglass",
                        description: "Upload and analyze CSV files for patterns",
                        action: { showingCSVImporter = true }
                    )
                    
                    // SageMaker Integration
                    AnalysisToolCard(
                        title: "SageMaker Predictions",
                        icon: "brain",
                        description: "ML-powered options strategy recommendations",
                        action: { showingSageMakerAnalysis = true }
                    )
                    
                    // Predictions Display
                    if !dataManager.sagemakerPredictions.isEmpty {
                        PredictionsView(predictions: dataManager.sagemakerPredictions)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
            }
            .navigationTitle("Analytics")
            .sheet(isPresented: $showingCSVImporter) {
                CSVImporterView()
            }
            .sheet(isPresented: $showingSageMakerAnalysis) {
                SageMakerAnalysisView()
            }
        }
    }
}

// MARK: - Trading Tools View
struct TradingToolsView: View {
    @State private var selectedStrategy = "Bull Call Spread"
    @State private var showingAlpacaSetup = false
    @State private var scheduledTrades: [ScheduledTrade] = []
    
    let strategies = ["Bull Call Spread", "Bear Put Spread", "Iron Condor", "Straddle", "Strangle"]
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 20) {
                    // Alpaca Integration Card
                    AlpacaIntegrationCard(showingSetup: $showingAlpacaSetup)
                    
                    // Strategy Selector
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Select Strategy")
                            .font(.headline)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(strategies, id: \.self) { strategy in
                                    StrategyChip(
                                        title: strategy,
                                        isSelected: selectedStrategy == strategy,
                                        action: { selectedStrategy = strategy }
                                    )
                                }
                            }
                        }
                    }
                    .padding()
                    .background(.background)
                    .cornerRadius(15)
                    .shadow(radius: 2)
                    
                    // Options Calculator
                    OptionsCalculatorCard(strategy: selectedStrategy)
                    
                    // Scheduled Trades
                    ScheduledTradesView(trades: $scheduledTrades)
                }
                .padding()
            }
            .navigationTitle("Trading Tools")
            .sheet(isPresented: $showingAlpacaSetup) {
                AlpacaSetupView()
            }
        }
    }
}

// MARK: - Blog View
struct BlogView: View {
    @State private var selectedCategory = "All"
    let categories = ["All", "Market Analysis", "Strategies", "MLOps", "Tutorials"]
    
    let blogPosts = [
        BlogPost(
            id: "1",
            title: "Understanding Implied Volatility in M&A Events",
            author: "Dr. Sarah Chen",
            date: Date(),
            category: "Market Analysis",
            excerpt: "How merger announcements affect options pricing...",
            readTime: "8 min",
            isPremium: false
        ),
        BlogPost(
            id: "2",
            title: "Building ML Pipelines for Options Trading",
            author: "Alex Thompson",
            date: Date().addingTimeInterval(-86400),
            category: "MLOps",
            excerpt: "Deploy production-ready models with SageMaker...",
            readTime: "12 min",
            isPremium: true
        ),
        BlogPost(
            id: "3",
            title: "Advanced Greeks: Beyond Delta and Gamma",
            author: "Michael Roberts",
            date: Date().addingTimeInterval(-172800),
            category: "Strategies",
            excerpt: "Deep dive into Vanna, Charm, and Color...",
            readTime: "15 min",
            isPremium: true
        )
    ]
    
    var filteredPosts: [BlogPost] {
        if selectedCategory == "All" {
            return blogPosts
        }
        return blogPosts.filter { $0.category == selectedCategory }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 20) {
                    // Category Filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(categories, id: \.self) { category in
                                CategoryChip(
                                    title: category,
                                    isSelected: selectedCategory == category,
                                    action: { selectedCategory = category }
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Blog Posts
                    LazyVStack(spacing: 15) {
                        ForEach(filteredPosts) { post in
                            BlogPostCard(post: post)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Blog")
        }
    }
}

// MARK: - Profile View
struct ProfileView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var purchaseManager: PurchaseManager
    @State private var showingSettings = false
    @State private var showingSubscription = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 20) {
                    // Profile Header
                    ProfileHeaderView()
                    
                    // Subscription Status
                    SubscriptionStatusCard(isPremium: authManager.isPremium)
                        .onTapGesture {
                            showingSubscription = true
                        }
                    
                    // Learning Progress
                    LearningProgressCard()
                    
                    // Quick Actions
                    VStack(spacing: 12) {
                        ProfileActionRow(
                            icon: "bell",
                            title: "Notifications",
                            action: {}
                        )
                        
                        ProfileActionRow(
                            icon: "bookmark",
                            title: "Saved Content",
                            action: {}
                        )
                        
                        ProfileActionRow(
                            icon: "chart.bar",
                            title: "Trading History",
                            action: {}
                        )
                        
                        ProfileActionRow(
                            icon: "gearshape",
                            title: "Settings",
                            action: { showingSettings = true }
                        )
                        
                        ProfileActionRow(
                            icon: "questionmark.circle",
                            title: "Help & Support",
                            action: {}
                        )
                    }
                    .padding()
                    .background(.background)
                    .cornerRadius(15)
                    .shadow(radius: 2)
                    
                    // Sign Out Button
                    Button(action: { authManager.signOut() }) {
                        Text("Sign Out")
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.background)
                            .cornerRadius(12)
                            .shadow(radius: 2)
                    }
                }
                .padding()
            }
            .navigationTitle("Profile")
            .sheet(isPresented: $showingSubscription) {
                SubscriptionView()
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
    }
}

// MARK: - Supporting Views and Components

struct Course: Identifiable {
    let id: String
    let title: String
    let videos: [Video]
}

struct Video: Identifiable {
    let id: String
    let title: String
    let duration: String
    let thumbnailURL: String
    let videoURL: String
    let isFree: Bool
    let description: String
}

struct BlogPost: Identifiable {
    let id: String
    let title: String
    let author: String
    let date: Date
    let category: String
    let excerpt: String
    let readTime: String
    let isPremium: Bool
}

struct ScheduledTrade: Identifiable {
    let id = UUID()
    let symbol: String
    let strategy: String
    let executionTime: Date
    let status: String
}

struct ModernTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(.regularMaterial)
            .cornerRadius(12)
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search courses...", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
        }
        .padding(12)
        .background(.regularMaterial)
        .cornerRadius(10)
    }
}

struct PremiumBanner: View {
    @EnvironmentObject var purchaseManager: PurchaseManager
    @State private var showingPurchase = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Unlock Premium")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text("Get access to all courses and tools")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Upgrade") {
                    showingPurchase = true
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing))
                .foregroundColor(.white)
                .cornerRadius(20)
            }
        }
        .padding()
        .background(LinearGradient(colors: [.blue.opacity(0.1), .purple.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing))
        .cornerRadius(12)
        .sheet(isPresented: $showingPurchase) {
            SubscriptionView()
        }
    }
}

struct CourseSection: View {
    let course: Course
    @Binding var selectedVideo: Video?
    @EnvironmentObject var authManager: AuthenticationManager
    
    var body: some View {
        LazyVStack(alignment: .leading, spacing: 10) {
            Text(course.title)
                .font(.title3)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(course.videos) { video in
                        VideoThumbnailCard(video: video) {
                            if video.isFree || authManager.isPremium {
                                selectedVideo = video
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct VideoThumbnailCard: View {
    let video: Video
    let action: () -> Void
    @EnvironmentObject var authManager: AuthenticationManager
    
    var isLocked: Bool {
        !video.isFree && !authManager.isPremium
    }
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(LinearGradient(colors: [.blue.opacity(0.3), .purple.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 160, height: 90)
                    
                    if isLocked {
                        Image(systemName: "lock.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                    } else {
                        Image(systemName: "play.circle.fill")
                            .font(.title)
                            .foregroundColor(.white)
                    }
                    
                    if video.isFree {
                        Text("FREE")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(4)
                            .position(x: 140, y: 15)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(video.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    
                    Text(video.duration)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(width: 160, alignment: .leading)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct VideoPlayerView: View {
    let video: Video
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Video Player Placeholder
                ZStack {
                    Rectangle()
                        .fill(Color.black)
                        .aspectRatio(16/9, contentMode: .fit)
                    
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.white)
                }
                
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 15) {
                        Text(video.title)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        HStack {
                            Label(video.duration, systemImage: "clock")
                            Spacer()
                            Button(action: {}) {
                                Image(systemName: "bookmark")
                            }
                            Button(action: {}) {
                                Image(systemName: "square.and.arrow.up")
                            }
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        
                        Text(video.description)
                            .font(.body)
                        
                        // Related Materials
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Course Materials")
                                .font(.headline)
                            
                            ForEach(["Slides.pdf", "Exercise.xlsx", "Notes.docx"], id: \.self) { file in
                                HStack {
                                    Image(systemName: "doc.text")
                                    Text(file)
                                    Spacer()
                                    Button("Download") {}
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }
                                .padding()
                                .background(.regularMaterial)
                                .cornerRadius(8)
                            }
                        }
                        .padding(.top)
                    }
                    .padding()
                }
            }
            .navigationTitle("…")
            #if os(iOS) || targetEnvironment(macCatalyst)
            .navigationBarTitleDisplayMode(.inline)
            #endif

            .toolbar {
            #if os(iOS) || targetEnvironment(macCatalyst)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            #else
                ToolbarItem { // .automatic on macOS titlebar
                    Button("Done") { dismiss() }
                }
            #endif
            }
        }
    }
}

struct StockPriceCard: View {
    @Binding var selectedSymbol: String
    @EnvironmentObject var dataManager: DataManager
    @State private var isLoading = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Stock Price Tracker")
                .font(.headline)
            
            HStack {
                TextField("Symbol", text: $selectedSymbol)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button(action: fetchData) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    } else {
                        Text("Fetch")
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
        .padding()
        .background(.background)
        .cornerRadius(15)
        .shadow(radius: 2)
    }
    
    func fetchData() {
        isLoading = true
        Task {
            await dataManager.fetchLatestStockPrice(symbol: selectedSymbol)
            isLoading = false
        }
    }
}

struct StockChartView: View {
    let data: [DataManager.StockDataPoint]
    
    var body: some View {
        Chart(data) { point in
            LineMark(
                x: .value("Date", point.date),
                y: .value("Price", point.price)
            )
            .foregroundStyle(Color.blue)
            
            AreaMark(
                x: .value("Date", point.date),
                y: .value("Price", point.price)
            )
            .foregroundStyle(LinearGradient(colors: [.blue.opacity(0.3), .clear], startPoint: .top, endPoint: .bottom))
        }
        .chartYAxis {
            AxisMarks(position: .leading)
        }
    }
}

struct AnalysisToolCard: View {
    let title: String
    let icon: String
    let description: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 50)
                
                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(.background)
            .cornerRadius(15)
            .shadow(radius: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct PredictionsView: View {
    let predictions: [DataManager.Prediction]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("ML Predictions")
                .font(.headline)
            
            ForEach(predictions.indices, id: \.self) { index in
                let prediction = predictions[index]
                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(prediction.optionStrategy)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text("Target: $\(String(format: "%.2f", prediction.predictedPrice))")
                            .font(.caption)
                        
                        Text("Confidence: \(Int(prediction.confidence * 100))%")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text(prediction.date, style: .date)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Image(systemName: prediction.confidence > 0.8 ? "arrow.up.circle.fill" : "arrow.right.circle.fill")
                            .foregroundColor(prediction.confidence > 0.8 ? .green : .orange)
                    }
                }
                .padding()
                .background(.regularMaterial)
                .cornerRadius(10)
            }
        }
        .padding()
        .background(.background)
        .cornerRadius(15)
        .shadow(radius: 2)
    }
}

struct CSVImporterView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataManager: DataManager
    @State private var selectedFileURL: URL?
    @State private var isAnalyzing = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Import CSV File")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Upload your trading data for pattern analysis")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Button(action: selectFile) {
                    Label("Select CSV File", systemImage: "folder")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                
                if let url = selectedFileURL {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text(url.lastPathComponent)
                            .lineLimit(1)
                    }
                    .padding()
                    .background(.regularMaterial)
                    .cornerRadius(8)
                    
                    Button(action: analyzeFile) {
                        if isAnalyzing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Analyze Patterns")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("…")
            #if os(iOS) || targetEnvironment(macCatalyst)
            .navigationBarTitleDisplayMode(.inline)
            #endif

            .toolbar {
            #if os(iOS) || targetEnvironment(macCatalyst)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            #else
                ToolbarItem { // .automatic on macOS titlebar
                    Button("Done") { dismiss() }
                }
            #endif
            }
        }
    }
    
    func selectFile() {
        // Implement file picker
        selectedFileURL = URL(string: "file://example.csv")
    }
    
    func analyzeFile() {
        guard let url = selectedFileURL else { return }
        isAnalyzing = true
        Task {
            await dataManager.analyzeSageMakerCSV(fileURL: url)
            isAnalyzing = false
            dismiss()
        }
    }
}

struct SageMakerAnalysisView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedModel = "Time Series Forecast"
    @State private var confidenceThreshold = 0.7
    @State private var lookbackDays = 30
    
    let models = ["Time Series Forecast", "Options Pricing", "Volatility Prediction", "Risk Assessment"]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Model Selection") {
                    Picker("Model", selection: $selectedModel) {
                        ForEach(models, id: \.self) { model in
                            Text(model).tag(model)
                        }
                    }
                }
                
                Section("Parameters") {
                    VStack(alignment: .leading) {
                        Text("Confidence Threshold: \(Int(confidenceThreshold * 100))%")
                        Slider(value: $confidenceThreshold, in: 0.5...0.95)
                    }
                    
                    Stepper("Lookback: \(lookbackDays) days", value: $lookbackDays, in: 7...90)
                }
                
                Section {
                    Button(action: runAnalysis) {
                        Label("Run Analysis", systemImage: "brain")
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle("SageMaker Analysis")
            #if os(iOS) || targetEnvironment(macCatalyst)
            .navigationBarTitleDisplayMode(.inline)
            #endif

            .toolbar {
            #if os(iOS) || targetEnvironment(macCatalyst)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            #else
                ToolbarItem { // .automatic on macOS titlebar
                    Button("Done") { dismiss() }
                }
            #endif
            }
        }
    }
    
    func runAnalysis() {
        // Trigger SageMaker analysis
        dismiss()
    }
}

struct AlpacaIntegrationCard: View {
    @Binding var showingSetup: Bool
    @State private var isConnected = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "link.circle.fill")
                    .font(.title2)
                    .foregroundColor(isConnected ? .green : .orange)
                
                VStack(alignment: .leading) {
                    Text("Alpaca Trading")
                        .font(.headline)
                    
                    Text(isConnected ? "Connected" : "Not Connected")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(isConnected ? "Settings" : "Connect") {
                    showingSetup = true
                }
                .padding(.horizontal, 15)
                .padding(.vertical, 6)
                .background(isConnected ? Color.gray : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            
            if isConnected {
                HStack(spacing: 20) {
                    StatItem(title: "Balance", value: "$25,432")
                    StatItem(title: "P&L Today", value: "+$342", color: .green)
                    StatItem(title: "Open Positions", value: "7")
                }
            }
        }
        .padding()
        .background(.background)
        .cornerRadius(15)
        .shadow(radius: 2)
    }
}

struct StatItem: View {
    let title: String
    let value: String
    var color: Color = .primary
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }
}

struct StrategyChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color.gray.opacity(0.2))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

struct OptionsCalculatorCard: View {
    let strategy: String
    @State private var strikePrice = "150"
    @State private var premium = "2.50"
    @State private var contracts = "10"
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("\(strategy) Calculator")
                .font(.headline)
            
            HStack(spacing: 10) {
                VStack(alignment: .leading) {
                    Text("Strike")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("150", text: $strikePrice)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                VStack(alignment: .leading) {
                    Text("Premium")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("2.50", text: $premium)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                VStack(alignment: .leading) {
                    Text("Contracts")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("10", text: $contracts)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
            }
            
            HStack {
                ResultBox(title: "Max Profit", value: "$2,500", color: .green)
                ResultBox(title: "Max Loss", value: "$500", color: .red)
                ResultBox(title: "Break Even", value: "$152.50", color: .blue)
            }
            
            Button(action: {}) {
                Text("Schedule Trade")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
        .background(.background)
        .cornerRadius(15)
        .shadow(radius: 2)
    }
}

struct ResultBox: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 5) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

struct ScheduledTradesView: View {
    @Binding var trades: [ScheduledTrade]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Scheduled Trades")
                    .font(.headline)
                Spacer()
                Button(action: {}) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            
            if trades.isEmpty {
                Text("No scheduled trades")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else {
                ForEach(trades) { trade in
                    ScheduledTradeRow(trade: trade)
                }
            }
        }
        .padding()
        .background(.background)
        .cornerRadius(15)
        .shadow(radius: 2)
    }
}

struct ScheduledTradeRow: View {
    let trade: ScheduledTrade
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(trade.symbol)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(trade.strategy)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(trade.executionTime, style: .time)
                    .font(.caption)
                Text(trade.status)
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(statusColor.opacity(0.2))
                    .foregroundColor(statusColor)
                    .cornerRadius(4)
            }
        }
        .padding(.vertical, 8)
    }
    
    var statusColor: Color {
        switch trade.status {
        case "Pending": return .orange
        case "Executed": return .green
        case "Failed": return .red
        default: return .gray
        }
    }
}

struct AlpacaSetupView: View {
    @Environment(\.dismiss) var dismiss
    @State private var apiKey = ""
    @State private var apiSecret = ""
    @State private var isPaper = true
    
    var body: some View {
        NavigationView {
            Form {
                Section("API Configuration") {
                    TextField("API Key", text: $apiKey)
                    SecureField("API Secret", text: $apiSecret)
                    Toggle("Paper Trading", isOn: $isPaper)
                }
                
                Section("Account Info") {
                    HStack {
                        Text("Status")
                        Spacer()
                        Text("Not Connected")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section {
                    Button(action: connect) {
                        Text("Connect Account")
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle("Alpaca Setup")
            #if os(iOS) || targetEnvironment(macCatalyst)
            .navigationBarTitleDisplayMode(.inline)
            #endif

            .toolbar {
            #if os(iOS) || targetEnvironment(macCatalyst)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            #else
                ToolbarItem { // .automatic on macOS titlebar
                    Button("Done") { dismiss() }
                }
            #endif
            }
        }
    }
    
    func connect() {
        // Implement Alpaca connection
        dismiss()
    }
}

struct BlogPostCard: View {
    let post: BlogPost
    @EnvironmentObject var authManager: AuthenticationManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(post.category)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(4)
                
                if post.isPremium && !authManager.isPremium {
                    Label("Premium", systemImage: "crown.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                
                Spacer()
                
                Text(post.readTime)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(post.title)
                .font(.headline)
                .lineLimit(2)
            
            Text(post.excerpt)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            HStack {
                Text(post.author)
                    .font(.caption)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text(post.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(.background)
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color.gray.opacity(0.2))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

struct ProfileHeaderView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    
    var body: some View {
        VStack(spacing: 15) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            VStack(spacing: 5) {
                Text(authManager.currentUser?.name ?? "User")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(authManager.currentUser?.email ?? "user@example.com")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 30) {
                ProfileStat(title: "Courses", value: "12")
                ProfileStat(title: "Hours", value: "48")
                ProfileStat(title: "Certificates", value: "3")
            }
        }
        .padding()
        .background(.background)
        .cornerRadius(15)
        .shadow(radius: 2)
    }
}

struct ProfileStat: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 5) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct SubscriptionStatusCard: View {
    let isPremium: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text(isPremium ? "Premium Member" : "Free Plan")
                    .font(.headline)
                
                Text(isPremium ? "Full access to all content" : "Upgrade for unlimited access")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: isPremium ? "crown.fill" : "arrow.up.circle.fill")
                .font(.title2)
                .foregroundColor(isPremium ? .orange : .blue)
        }
        .padding()
        .background(isPremium ?
            LinearGradient(colors: [.orange.opacity(0.1), .yellow.opacity(0.1)],
                          startPoint: .topLeading, endPoint: .bottomTrailing) :
            LinearGradient(colors: [.blue.opacity(0.1), .purple.opacity(0.1)],
                          startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .cornerRadius(12)
    }
}

struct LearningProgressCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Learning Progress")
                .font(.headline)
            
            VStack(spacing: 10) {
                ProgressItem(
                    title: "Options Fundamentals",
                    progress: 0.75,
                    color: .blue
                )
                
                ProgressItem(
                    title: "M&A Valuations",
                    progress: 0.45,
                    color: .purple
                )
                
                ProgressItem(
                    title: "MLOps with SageMaker",
                    progress: 0.30,
                    color: .green
                )
            }
        }
        .padding()
        .background(.background)
        .cornerRadius(15)
        .shadow(radius: 2)
    }
}

struct ProgressItem: View {
    let title: String
    let progress: Double
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(title)
                    .font(.subheadline)
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geometry.size.width * progress, height: 8)
                }
            }
            .frame(height: 8)
        }
    }
}

struct ProfileActionRow: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.blue)
                    .frame(width: 30)
                
                Text(title)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SubscriptionView: View {
    @Environment(\.dismiss) var dismiss

    // Use your real product IDs from App Store Connect or your .storekit config
    private let productIDs = [
        PurchaseManager.ProductID.premiumMonthly.rawValue,
        PurchaseManager.ProductID.premiumYearly.rawValue
    ]

    var body: some View {
        NavigationStack {
            SubscriptionStoreView(productIDs: productIDs) {
                // Optional header above the paywall content
                VStack(spacing: 8) {
                    Image(systemName: "crown.fill").font(.largeTitle)
                    Text("Unlock Premium").font(.title2).bold()
                    Text("Get unlimited access to all courses and tools")
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 12)
            }
            // Style the primary CTA
            .subscriptionStoreButtonLabel(.action)        // or .multiline
            // Show useful secondary buttons
            .storeButton(.visible, for: .restorePurchases)
            .storeButton(.visible, for: .redeemCode)
            .storeButton(.visible, for: .signIn)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") { dismiss() }
                }
            }
            .navigationTitle("Premium")
        }
    }
}


struct LegacyPaywall: View {
    @EnvironmentObject var purchaseManager: PurchaseManager
    @Environment(\.dismiss) var dismiss
    @State private var isBuying = false
    @State private var error: String?

    var body: some View {
        VStack(spacing: 16) {
            Text("Choose a plan").font(.title2).bold()

            HStack {
                Button("Buy Monthly") { buy(.premiumMonthly) }
                Button("Buy Annual")  { buy(.premiumYearly) }
            }
            .buttonStyle(.borderedProminent)

            Button("Restore Purchases") {
                Task { try? await AppStore.sync() } // system restore
            }
            .buttonStyle(.bordered)

            if let error { Text(error).foregroundColor(.red) }
            Button("Close") { dismiss() }
        }
        .padding()
        .task {
            if purchaseManager.products.isEmpty {
                await purchaseManager.loadProducts()
            }
        }
    }

    private func buy(_ id: PurchaseManager.ProductID) {
        guard let product = purchaseManager.products.first(where: { $0.id == id.rawValue }) else { return }
        Task {
            do {
                _ = try await purchaseManager.purchase(product)
            } catch {
                await MainActor.run { self.error = error.localizedDescription }
            }
        }
    }
}


struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            Text(text)
                .font(.subheadline)
            
            Spacer()
        }
    }
}

struct PlanCard: View {
    let title: String
    let price: String
    let period: String
    var savings: String? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text(title)
                            .font(.headline)

                        if let savings {
                            Text(savings)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }

                    // FIX 1: use alignment:, not baseline:
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text(price)
                            .font(.title2)
                            .fontWeight(.bold)

                        Text(period)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? .blue : .gray)
            }
            .padding()

            // FIX 2: split the backgrounds so the types are clear
            .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
            .background(.regularMaterial)

            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @State private var notificationsEnabled = true
    @State private var biometricsEnabled = false
    @State private var downloadOnWiFiOnly = true
    @State private var videoQuality = "Auto"
    
    let videoQualities = ["Auto", "720p", "1080p", "4K"]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Notifications") {
                    Toggle("Push Notifications", isOn: $notificationsEnabled)
                    Toggle("Course Updates", isOn: .constant(true))
                    Toggle("Trading Alerts", isOn: .constant(true))
                }
                
                Section("Security") {
                    Toggle("Face ID / Touch ID", isOn: $biometricsEnabled)
                    Button("Change Password") {}
                    Button("Two-Factor Authentication") {}
                }
                
                Section("Video Settings") {
                    Picker("Video Quality", selection: $videoQuality) {
                        ForEach(videoQualities, id: \.self) { quality in
                            Text(quality).tag(quality)
                        }
                    }
                    Toggle("Download on Wi-Fi Only", isOn: $downloadOnWiFiOnly)
                }
                
                Section("Data & Storage") {
                    Button("Clear Cache") {}
                        .foregroundColor(.blue)
                    Button("Download All Content") {}
                        .foregroundColor(.blue)
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    Button("Terms of Service") {}
                    Button("Privacy Policy") {}
                }
            }
            .navigationTitle("Settings")
            #if os(iOS) || targetEnvironment(macCatalyst)
            .navigationBarTitleDisplayMode(.inline)
            #endif

            .toolbar {
            #if os(iOS) || targetEnvironment(macCatalyst)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            #else
                ToolbarItem { // .automatic on macOS titlebar
                    Button("Done") { dismiss() }
                }
            #endif
            }
        }
    }
}

struct SignUpView: View {
    @Environment(\.dismiss) var dismiss
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var fullName = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 20) {
                    Text("Create Account")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.top, 30)
                    
                    VStack(spacing: 15) {
                        TextField("Full Name", text: $fullName)
                            .textFieldStyle(ModernTextFieldStyle())
                        
                        TextField("Email", text: $email)
                            .textFieldStyle(ModernTextFieldStyle())
                        #if os(iOS) || targetEnvironment(macCatalyst)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                        #endif

                        
                        SecureField("Password", text: $password)
                            .textFieldStyle(ModernTextFieldStyle())
                        
                        SecureField("Confirm Password", text: $confirmPassword)
                            .textFieldStyle(ModernTextFieldStyle())
                    }
                    .padding(.horizontal)
                    
                    Button(action: signUp) {
                        Text("Sign Up")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    
                    Text("By signing up, you agree to our Terms of Service and Privacy Policy")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            .navigationTitle("…")
            #if os(iOS) || targetEnvironment(macCatalyst)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
            #if os(iOS) || targetEnvironment(macCatalyst)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            #else
                ToolbarItem { // .automatic on macOS titlebar
                    Button("Done") { dismiss() }
                }
            #endif
            }
        }
    }
    
    func signUp() {
        // Implement sign up logic
        dismiss()
    }
}
