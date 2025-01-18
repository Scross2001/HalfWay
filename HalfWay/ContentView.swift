import SwiftUI
import MapKit
import CoreLocation

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var currentLocation: CLLocation?
    @Published var locationError: String?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            currentLocation = location
            locationManager.stopUpdatingLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationError = error.localizedDescription
    }
}

class RestaurantSearchViewModel: ObservableObject {
    @Published var restaurants: [MKMapItem] = []
    @Published var errorMessage: String?

    func searchForRestaurants(near location: CLLocation) {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "Food"
        request.region = MKCoordinateRegion(
            center: location.coordinate,
            latitudinalMeters: 10000,
            longitudinalMeters: 10000
        )
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = "Search failed: \(error.localizedDescription)"
                }
                return
            }
            
            guard let mapItems = response?.mapItems, !mapItems.isEmpty else {
                DispatchQueue.main.async {
                    self.errorMessage = "No restaurants found in this area."
                }
                return
            }
            
            DispatchQueue.main.async {
                self.restaurants = mapItems
                self.errorMessage = nil
            }
        }
    }
}

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var viewModel = RestaurantSearchViewModel()

    var body: some View {
        NavigationView {
            VStack {
                if let location = locationManager.currentLocation {
                    Text("Your Location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
                        .padding()
                    
                    Button("Search for Restaurants") {
                        viewModel.searchForRestaurants(near: location)
                    }
                    .padding()

                    if let errorMessage = viewModel.errorMessage {
                        Text("Error: \(errorMessage)")
                            .foregroundColor(.red)
                            .padding()
                    } else if viewModel.restaurants.isEmpty {
                        Text("No restaurants found. Tap the button to search.")
                            .padding()
                    } else {
                        List(viewModel.restaurants, id: \.self) { restaurant in
                            VStack(alignment: .leading) {
                                Text(restaurant.name ?? "Unknown Name")
                                    .font(.headline)
                                Text(restaurant.placemark.title ?? "Unknown Address")
                                    .font(.subheadline)
                            }
                        }
                    }
                } else if let error = locationManager.locationError {
                    Text("Location Error: \(error)")
                        .foregroundColor(.red)
                        .padding()
                } else {
                    Text("Fetching your location...")
                        .padding()
                }
            }
            .navigationTitle("Restaurant Finder")
        }
    }
}

#Preview {
    ContentView()
}
