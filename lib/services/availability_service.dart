import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../models/provider_model.dart';
import '../models/appointment_model.dart';
import 'app_config.dart';

class AvailabilityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final bool _devMode = AppConfig().isDevMode();
  
  // Get available time slots for a specific provider on a specific date
  Future<List<DateTime>> getAvailableTimeSlots({
    required String providerId,
    required DateTime date,
    required int serviceDuration,
  }) async {
    // Create a list of all possible time slots for the day
    final List<DateTime> allTimeSlots = _generateTimeSlots(date, serviceDuration);
    
    if (_devMode) {
      // For development, simulate some booked slots
      final bookedSlots = _getMockBookedSlots(providerId, date);
      return allTimeSlots.where((slot) => 
        !bookedSlots.any((bookedSlot) => 
          slot.isAfter(bookedSlot.subtract(Duration(minutes: serviceDuration - 1))) && 
          slot.isBefore(bookedSlot.add(Duration(minutes: serviceDuration)))
        )
      ).toList();
    }
    
    // Get the provider's working hours
    final workingHours = await _getProviderWorkingHours(providerId, date);
    if (workingHours.isEmpty) {
      return [];
    }
    
    // Get all appointments for this provider on this date
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(Duration(days: 1));
    
    final appointmentsSnapshot = await _firestore
        .collection('appointments')
        .where('providerId', isEqualTo: providerId)
        .where('dateTime', isGreaterThanOrEqualTo: startOfDay)
        .where('dateTime', isLessThan: endOfDay)
        .where('status', whereIn: ['pending', 'confirmed'])
        .get();
    
    final appointments = appointmentsSnapshot.docs
        .map((doc) => AppointmentModel.fromFirestore(doc))
        .toList();
    
    // Filter out time slots that overlap with existing appointments
    return allTimeSlots.where((slot) {
      // Check if the slot is within working hours
      if (!_isWithinWorkingHours(slot, workingHours)) {
        return false;
      }
      
      // Check if the slot overlaps with any existing appointment
      for (var appointment in appointments) {
        final appointmentStart = appointment.dateTime;
        final appointmentEnd = appointment.endTime;
        
        final slotEnd = slot.add(Duration(minutes: serviceDuration));
        
        // Check for overlap
        if (!(slotEnd.isBefore(appointmentStart) || 
              slot.isAfter(appointmentEnd))) {
          return false;
        }
      }
      
      return true;
    }).toList();
  }
  
  // Generate all possible time slots for a day based on 15-minute intervals
  List<DateTime> _generateTimeSlots(DateTime date, int serviceDuration) {
    final List<DateTime> slots = [];
    final startTime = DateTime(date.year, date.month, date.day, 8, 0); // 8:00 AM
    final endTime = DateTime(date.year, date.month, date.day, 20, 0);  // 8:00 PM
    
    DateTime currentSlot = startTime;
    while (currentSlot.isBefore(endTime)) {
      slots.add(currentSlot);
      currentSlot = currentSlot.add(Duration(minutes: 15)); // 15-minute intervals
    }
    
    return slots;
  }
  
  // Check if a time slot is within provider's working hours
  bool _isWithinWorkingHours(DateTime slot, List<Map<String, DateTime>> workingHours) {
    for (var period in workingHours) {
      if (slot.isAfter(period['start']!) && 
          slot.isBefore(period['end']!)) {
        return true;
      }
    }
    return false;
  }
  
  // Get provider's working hours for a specific date
  Future<List<Map<String, DateTime>>> _getProviderWorkingHours(String providerId, DateTime date) async {
    if (_devMode) {
      // Mock working hours for development
      final dayOfWeek = date.weekday;
      
      // Default working hours: 9 AM - 12 PM, 2 PM - 6 PM
      // Closed on Sundays (day 7)
      if (dayOfWeek == 7) {
        return [];
      }
      
      return [
        {
          'start': DateTime(date.year, date.month, date.day, 9, 0),  // 9:00 AM
          'end': DateTime(date.year, date.month, date.day, 12, 0),   // 12:00 PM
        },
        {
          'start': DateTime(date.year, date.month, date.day, 14, 0), // 2:00 PM
          'end': DateTime(date.year, date.month, date.day, 18, 0),   // 6:00 PM
        },
      ];
    }
    
    try {
      final scheduleDoc = await _firestore
          .collection('providers')
          .doc(providerId)
          .collection('schedule')
          .doc(date.weekday.toString())
          .get();
      
      if (!scheduleDoc.exists) {
        return [];
      }
      
      final data = scheduleDoc.data() as Map<String, dynamic>;
      final List<Map<String, DateTime>> workingHours = [];
      
      for (var period in (data['periods'] as List<dynamic>)) {
        final startHour = period['startHour'];
        final startMinute = period['startMinute'];
        final endHour = period['endHour'];
        final endMinute = period['endMinute'];
        
        workingHours.add({
          'start': DateTime(date.year, date.month, date.day, startHour, startMinute),
          'end': DateTime(date.year, date.month, date.day, endHour, endMinute),
        });
      }
      
      return workingHours;
    } catch (e) {
      print('Error getting provider working hours: $e');
      return [];
    }
  }
  
  // Mock booked slots for development
  List<DateTime> _getMockBookedSlots(String providerId, DateTime date) {
    // Simulate some booked slots
    return [
      DateTime(date.year, date.month, date.day, 10, 0),  // 10:00 AM
      DateTime(date.year, date.month, date.day, 14, 30), // 2:30 PM
      DateTime(date.year, date.month, date.day, 16, 0),  // 4:00 PM
    ];
  }
  
  // Check if a specific time slot is available
  Future<bool> isTimeSlotAvailable({
    required String providerId,
    required DateTime dateTime,
    required int serviceDuration,
  }) async {
    final availableSlots = await getAvailableTimeSlots(
      providerId: providerId,
      date: DateTime(dateTime.year, dateTime.month, dateTime.day),
      serviceDuration: serviceDuration,
    );
    
    return availableSlots.any((slot) => 
      slot.hour == dateTime.hour && slot.minute == dateTime.minute);
  }
}