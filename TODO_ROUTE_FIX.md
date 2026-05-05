# TODO: Fix Dense Road-Accurate Route Rendering

## Plan Steps:
- [x] Step 1: Update lib/services/route_service.dart - debugPrint prints, add raw response log (added foundation.dart import)
- [x] Step 2: Update lib/screens/home_screen.dart - preview multiple routes (yellow shortest, orange recommended, purple least congested)
- [ ] Step 3: Test with Adyar → Thiruvanmiyur (longer route)
- [ ] Step 4: Verify console "Total points: 200+" per route
- [ ] Step 5: Run `flutter analyze`
- [ ] Step 6: `flutter run` - check smooth curved roads

**Expected**: Dense polylines matching Google Maps navigation curves.
