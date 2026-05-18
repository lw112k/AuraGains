import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/onboarding_model.dart';

class OnboardingRepository {
  final SupabaseClient _supabase;

  OnboardingRepository({SupabaseClient? supabase}) 
      : _supabase = supabase ?? Supabase.instance.client;

  Future<void> completeOnboarding(OnboardingModel data) async {
    try {
      // 1. Calculate approximate DOB (This format 'YYYY-MM-DD' is perfect for your 'date' column type)
      String? dateOfBirth;
      if (data.age != null) {
        final now = DateTime.now();
        final dob = DateTime(now.year - data.age!, now.month, now.day);
        dateOfBirth = dob.toIso8601String().split('T')[0]; 
      }

      // 2. Format the Gender to match the Enum
      String? formattedGender;
      if (data.gender != null) {
        formattedGender = data.gender!.toLowerCase();
      }

      // 3. Fetch the level_id from the 'level' table
      int? levelId;
      if (data.objective != null) {
        print('--- DEBUG: Searching for objective: "${data.objective}" ---');  // error check debug
        
        final levelResponse = await _supabase
            .from('level')
            .select('level_id')
            .eq('name', data.objective!.trim())
            .maybeSingle();

        if (levelResponse != null) {
          levelId = levelResponse['level_id'] as int;
          print('--- DEBUG: Found Level ID: $levelId ---'); // error check debug
        } else {
          print('--- DEBUG: Level ID was NULL! String did not match DB. ---'); // error check debug
        }
      }

      // 4. Update the user table
      print('--- DEBUG: Updating User ID ${data.userId} with Level ID $levelId ---');  // error check debug
      await _supabase.from('user').update({  
        'gender': ?formattedGender,
        'date_of_birth': ?dateOfBirth,
        'level_id': ?levelId,
      }).eq('user_id', data.userId);

      // 5. Insert the physical metrics into the 'body_Status' table
      String dbUnitSystem = data.unitSystem == 'imperial' ? 'ft/lbs' : 'cm/kg';
      await _supabase.from('body_status').insert({
        'user_id': data.userId,
        'weight': data.weight,
        'height': data.height,
        'unit_system': dbUnitSystem,
      });



    } catch (e) {
      print('Supabase Onboarding Error: $e');
      rethrow;
    }
  }
}