//
//  ContentView.swift
//  HalfWay
//
//  Created by Sam Cross on 1/15/25.
//

import SwiftUI
import MapKit

struct ContentView: View {
    @State private var userPosition: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var searchLocation = ""
    @State private var searchResults = [MKMapItem]()
    @State private var selectedPin: MKMapItem?
    @State private var sheetVisible = false
    @State private var lookAroundScene: MKLookAroundScene?
    @State public var arrays: [CLLocationCoordinate2D] = []
    var body: some View {
        VStack {
            Map(selection: $selectedPin) {
                ForEach(searchResults, id: \.self) { item in
                    let placemark = item.placemark
                    Marker(placemark.name ?? "", coordinate: placemark.coordinate)
                }
            }
            .overlay(alignment: .bottom) {
                VStack(spacing: 10) {
                    TextField("Add a Second Location...", text: $searchLocation)
                        .font(.subheadline)
                        .padding(10)
                        .background(Color.white)
                        .cornerRadius(8)
                        .shadow(radius: 5)
                        .textFieldStyle(.roundedBorder)

                    Button(action: {
                        Task{
                            await printCords()
                        }
                    }) {
                        Text("Print Coordinates")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            .shadow(radius: 5)
                    }
                }
                .padding()
            }
            .onSubmit(of: .text) {
                Task {
                    await addLocation()
                }
                findCenterCoord()
            }
            .onChange(of: selectedPin) { oldValue, newValue in
                sheetVisible = true
            }
            .sheet(isPresented: $sheetVisible) {
                VStack {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(selectedPin?.placemark.name ?? "")
                                .font(.headline)
                            Text(selectedPin?.placemark.title ?? "")
                                .font(.subheadline)
                        }
                    }
                    .padding()
                }
            }
            .mapControls {
                MapUserLocationButton()
            }
            .onAppear {
                CLLocationManager().requestWhenInUseAuthorization()
            }
        }
    }

}

extension ContentView {
    func searchPlaces() async{
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchLocation
        
        let results = try? await MKLocalSearch(request: request).start()
        self.searchResults = results?.mapItems ?? []
    }
    
    func printCords() async{
        var totalLong = 0.0
        var totalLat = 0.0
        var count = 0
        arrays.forEach{ cordante in
            totalLong += cordante.longitude
            totalLat += cordante.latitude
            count += 1
        }
        print("Longitude\(totalLong) Latitude\(totalLat)")
        print("Final")
        print("Longitude\(totalLong/Double(count)) Latitude\(totalLat/Double(count))")
        print(arrays)
        print(count)
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "Resturants"
        
        let userCoordinate = CLLocationCoordinate2D(latitude: totalLat/Double(count), longitude: totalLong/Double(count))
        
        request.region = MKCoordinateRegion(
                center: userCoordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
        
        let results = try? await MKLocalSearch(request: request).start()
        self.searchResults = results?.mapItems ?? []
        
    }
    
    func addLocation() async {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchLocation
        
        do {
            let results = try await MKLocalSearch(request: request).start()
            self.searchResults = results.mapItems
            
            if let firstCoordinate = self.searchResults.first?.placemark.coordinate {
                arrays.append(firstCoordinate)
                self.searchLocation = ""
            } else {
                print("No coordinates found for the search query.")
            }
        } catch {
            print("Error performing location search: \(error.localizedDescription)")
        }
    }
    
    func findCenterCoord(){
    }

}
#Preview {
    ContentView()
}
