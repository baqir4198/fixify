import 'dart:convert';

import 'package:handyman_app/models/booking_model.dart';
import 'package:handyman_app/models/provider_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _bookingKey = 'user_bookings';
  static const String _providerKey = 'custom_providers';


  static Future<void> saveProvider(ProviderModel provider)async{
    final prefs = await SharedPreferences.getInstance();
    List<String> existingProviders = prefs.getStringList(_providerKey)??[];
    existingProviders.add(jsonEncode(provider.toMap()));
    await prefs.setStringList(_providerKey, existingProviders);
  }
  static Future<List<ProviderModel>> getSavedProviders() async{
    final prefs = await SharedPreferences.getInstance();
    List<String> providerRaw = prefs.getStringList(_providerKey)??[];
    return providerRaw.map((p)=> ProviderModel.fromMap(jsonDecode(p))).toList();
  }

  static Future<void> saveBooking(Map<String,dynamic> bookingData) async{
    final prefs = await SharedPreferences.getInstance();
    List<String> bookings = prefs.getStringList(_bookingKey)??[];
    bookings.add(jsonEncode(bookingData));
    await prefs.setStringList(_bookingKey,bookings);
  }
  static Future<List<BookingModel>> getBookings() async{
    final  prefs = await SharedPreferences.getInstance();
    List<String> bookingsRaw = prefs.getStringList(_bookingKey)??[];

    return  bookingsRaw.map((item){
      Map<String, dynamic> data = jsonDecode(item);
      return BookingModel(
        id: data['id'],
        date: DateTime.parse(data['date']),
        time: data['time'],
        status: data['status'],
        provider: ProviderModel(
            id:'',
            name: data['providerName'],
            profession: data['profession'],
            rating: 4.5,
            pricePerHour: 0.0,
            imageUrl: "https://i.pravatar.cc/150",
        ),
      );
    }).toList();
  }
  static Future<void> deleteBooking(String id)async{
    final prefs = await SharedPreferences.getInstance();
    List<String> bookingsRaw = prefs.getStringList(_bookingKey)??[];

    bookingsRaw.removeWhere((item){
      Map<String, dynamic> data = jsonDecode(item);
      return data['id'] == id;
    });
    await prefs.setStringList(_bookingKey,bookingsRaw);
  }
}
