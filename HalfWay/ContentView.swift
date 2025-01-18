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
    var body: some View {
        VStack{
            Map(selection: $selectedPin) {
                ForEach(searchResults, id: \.self) { item in
                    let placemark = item.placemark
                    Marker(placemark.name ?? "", coordinate: placemark.coordinate)
                }
            }
            .overlay(alignment: .bottom, content: {
                TextField("Add a Second Location...", text: $searchLocation)
                    .font(.subheadline)
                    .padding(10)
                    .padding()
                    .shadow(radius: 10)
                    .textFieldStyle(.roundedBorder)
            }).onSubmit(of: .text, {
                Task{
                    await searchPlaces()
                }
                findCenterCoord()
            })
            .onChange(of: selectedPin, { oldValue, newValue in
                sheetVisible = true
                
            }).sheet(isPresented: $sheetVisible, content: {
                VStack{
                    HStack{
                        VStack(alignment: .leading) {
                            Text(selectedPin?.placemark.name ?? "")
                            
                            Text(selectedPin?.placemark.title ?? "")
                            
                        }
                    }
                }
            })
            .mapControls{
                MapUserLocationButton()
            }
            .onAppear() {
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
    
    func findCenterCoord(){
    }

}
#Preview {
    ContentView()
}
