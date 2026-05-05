# Smart Traffic Prediction UI - Implementation Guide

## Overview
This document provides a complete guide to the Flutter UI integration with the Flask API for traffic prediction and Google Maps visualization.

## Changes Made

### 1. Dependencies (pubspec.yaml)
Added the following packages:
- **http** (^1.1.0) - For making API calls
- **google_maps_flutter** (^2.5.0) - For displaying maps and markers
- **google_maps_flutter_web** (^0.5.0) - Web support for Google Maps

### 2. New Files Created

#### a) lib/models/traffic_models.dart
Contains data models for the API integration:
- `TrafficPredictionRequest` - Encapsulates API request data
- `TrafficPredictionResponse` - Parses API response
- `LocationCoordinates` - Represents a location with lat/long
- `LocationDatabase` - Static database of locations (Adyar, Besant Nagar, IIT Madras, Thiruvanmiyur)
- `TrafficMetrics` - Generates vehicle count and speed based on time of day

#### b) lib/services/traffic_service.dart
Handles API communication:
- `predictTraffic(Map<String, dynamic> data)` - Makes POST request to Flask API
- Error handling with custom exceptions
- Response parsing and level conversion
- Timeout handling (15 seconds)

### 3. Updated Files

#### a) lib/screens/home_screen.dart
**New Features:**
- Google Maps integration with markers and polylines
- Real location selection (Adyar, Besant Nagar, IIT Madras, Thiruvanmiyur)
- Source (green) and destination (red) markers
- Route polyline between selected locations
- Dynamic camera positioning to show both source and destination
- Loading indicator while API call is in progress
- Error message display
- Validation of all input fields
- Automatic generation of vehicle_count and avg_speed based on travel time

**API Integration:**
- Sends POST request to: https://smart-traffic-congestion-msez.onrender.com/predict
- Request body includes:
  - latitude/longitude (center point between source and destination)
  - hour (from time picker)
  - day_type (default 0)
  - vehicle_count (based on peak/normal/night hours)
  - avg_speed (based on peak/normal/night hours)

**Time-based Traffic Metrics:**
- Peak (8-10am, 5-8pm): vehicle_count=100, avg_speed=20
- Normal (7-8am, 10am-12pm, 4-5pm): vehicle_count=60, avg_speed=35
- Night (all other hours): vehicle_count=30, avg_speed=50

#### b) lib/screens/result_screen.dart
**Enhanced Features:**
- Displays source and destination information
- Shows traffic level with color-coded result (Green/Yellow/Red)
- Displays appropriate message based on congestion level
- Shows estimated travel time
- Route recommendation based on congestion level
- Smooth animations and card-based UI

## Setup Instructions

### Prerequisites
1. Flutter SDK (3.9.2 or higher)
2. Android SDK / iOS SDK (for building on respective platforms)
3. Google Maps API Key (required for both Android and iOS)

### Getting Google Maps API Key

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Enable the Maps SDK for Android and iOS
4. Create an API key
5. Restrict the key to Android and iOS applications

### Android Configuration

1. Open `android/app/src/main/AndroidManifest.xml`
2. Add the following inside the `<application>` tag:
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_API_KEY_HERE"/>
```

3. Update `android/app/build.gradle.kts`:
```kotlin
android {
    compileSdk = 34
    // ... other configurations
}
```

### iOS Configuration

1. Open `ios/Runner/GeneratedPluginRegistrant.m`
2. Add Google Maps pod to `ios/Podfile`:
```ruby
pod 'GoogleMaps'
```

3. Add API key to `ios/Runner/AppDelegate.swift`:
```swift
import GoogleMaps

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("YOUR_API_KEY_HERE")
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

### Installation Steps

1. Install dependencies:
```bash
flutter pub get
```

2. Clean build cache:
```bash
flutter clean
```

3. Run the app:
```bash
flutter run
```

## API Endpoint Details

**Base URL:** `https://smart-traffic-congestion-msez.onrender.com`

**Endpoint:** `/predict`

**Method:** POST

**Request Headers:**
```json
{
    "Content-Type": "application/json",
    "Accept": "application/json"
}
```

**Request Body:**
```json
{
    "latitude": 13.0065,
    "longitude": 80.2366,
    "hour": 10,
    "day_type": 0,
    "vehicle_count": 60,
    "avg_speed": 35
}
```

**Response:**
```json
{
    "congestion_level": "Low|Medium|High"
}
```

## UI Flow

1. **Home Screen:**
   - User selects source location (dropdown)
   - User selects destination location (dropdown)
   - Google Map shows markers and route
   - User selects travel time
   - User clicks "Predict Traffic" button

2. **During Prediction:**
   - Loading spinner displayed
   - Button disabled
   - API call made in background

3. **Result Screen:**
   - Traffic level displayed with color coding
   - Message shown based on congestion level
   - Estimated time shown
   - Recommendation provided
   - Option to view route suggestions

## Locations Database

| Location | Latitude | Longitude |
|----------|----------|-----------|
| Adyar | 13.0067 | 80.2570 |
| Besant Nagar | 13.0003 | 80.2667 |
| IIT Madras | 12.9916 | 80.2337 |
| Thiruvanmiyur | 12.9830 | 80.2594 |

## Error Handling

- **Network timeout:** Shows error message and allows retry
- **Invalid inputs:** Displays validation error message
- **API errors:** Shows HTTP error status with message
- **Missing coordinates:** Validates location selection

## Performance Optimizations

1. **API Timeout:** 15 seconds
2. **Map Animations:** Smooth camera transitions
3. **Marker Clustering:** Properly handles map updates
4. **State Management:** Efficient setState calls
5. **Asset Loading:** Proper resource management

## Testing

### Test Scenarios:

1. **Peak Hour Test:**
   - Time: 9:00 AM
   - Expected: High vehicle count, low speed
   
2. **Normal Hour Test:**
   - Time: 11:00 AM
   - Expected: Medium vehicle count, medium speed

3. **Night Hour Test:**
   - Time: 2:00 AM
   - Expected: Low vehicle count, high speed

4. **Error Handling Test:**
   - Test with no internet connection
   - Verify error messages display correctly

## Troubleshooting

### Issue: "GoogleMap widget not found"
**Solution:** Run `flutter pub get` and rebuild the project

### Issue: API returns 503 Service Unavailable
**Solution:** The Render.com free tier may have cold starts; try again after waiting

### Issue: Map shows blank screen
**Solution:** Verify Google Maps API key is correctly configured for the platform

### Issue: Markers not showing
**Solution:** Ensure locations are properly selected from dropdowns

## Future Enhancements

1. Add real-time traffic layer from Google Maps
2. Integrate navigation with turn-by-turn directions
3. Add traffic history and trends
4. Implement user preferences and saved routes
5. Add weather data integration
6. Push notifications for traffic updates
7. Integration with other map providers
8. Offline mode support

## Contact & Support

For issues or questions regarding the implementation, refer to the Flutter and Google Maps documentation:
- [Flutter Documentation](https://flutter.dev/docs)
- [Google Maps Flutter Plugin](https://pub.dev/packages/google_maps_flutter)
- [Flask Backend Documentation](https://smart-traffic-congestion-msez.onrender.com)
