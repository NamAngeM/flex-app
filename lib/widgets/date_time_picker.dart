import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/restaurant_model.dart';

class DateTimePicker extends StatefulWidget {
  final DateTime? initialDate;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final ValueChanged<DateTime>? onDateTimeChanged;
  final RestaurantModel restaurant;
  final List<DateTime>? unavailableSlots;

  const DateTimePicker({
    Key? key,
    this.initialDate,
    this.firstDate,
    this.lastDate,
    this.onDateTimeChanged,
    required this.restaurant,
    this.unavailableSlots,
  }) : super(key: key);

  @override
  State<DateTimePicker> createState() => _DateTimePickerState();
}

class _DateTimePickerState extends State<DateTimePicker> {
  late DateTime _selectedDate;
  TimeOfDay? _selectedTime;
  final DateFormat _dateFormat = DateFormat('EEEE d MMMM yyyy', 'fr_FR');
  final DateFormat _timeFormat = DateFormat('HH:mm', 'fr_FR');

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
    _selectedTime = TimeOfDay.fromDateTime(widget.initialDate ?? DateTime.now());
    _validateInitialDateTime();
  }

  void _validateInitialDateTime() {
    if (_selectedTime != null) {
      final currentSlots = _generateTimeSlots(_selectedDate);
      if (!currentSlots.contains(_selectedTime)) {
        _selectedTime = currentSlots.isNotEmpty ? currentSlots.first : null;
      }
    }
  }

  List<TimeOfDay> _generateTimeSlots(DateTime date) {
    final List<TimeOfDay> slots = [];
    
    // Vérifier si le restaurant est ouvert ce jour-là
    final dayOfWeek = date.weekday.toString();
    final hours = widget.restaurant.openingHours[dayOfWeek];
    
    if (hours == null) return slots;

    // Vérifier si c'est un jour férié
    if (widget.restaurant.holidayDates.any((holiday) =>
        holiday.year == date.year &&
        holiday.month == date.month &&
        holiday.day == date.day)) {
      return slots;
    }

    final interval = 30; // Intervalle en minutes entre les créneaux
    DateTime currentSlot = DateTime(
      date.year,
      date.month,
      date.day,
      hours.opening.hour,
      hours.opening.minute,
    );
    
    final DateTime closingTime = DateTime(
      date.year,
      date.month,
      date.day,
      hours.closing.hour,
      hours.closing.minute,
    );

    while (currentSlot.isBefore(closingTime)) {
      final timeOfDay = TimeOfDay.fromDateTime(currentSlot);
      
      // Vérifier si le créneau n'est pas pendant la pause
      bool isDuringBreak = false;
      if (hours.breakStart != null && hours.breakEnd != null) {
        final breakStart = DateTime(
          date.year,
          date.month,
          date.day,
          hours.breakStart!.hour,
          hours.breakStart!.minute,
        );
        final breakEnd = DateTime(
          date.year,
          date.month,
          date.day,
          hours.breakEnd!.hour,
          hours.breakEnd!.minute,
        );
        
        isDuringBreak = currentSlot.isAfter(breakStart) && 
                       currentSlot.isBefore(breakEnd);
      }

      // Vérifier si le créneau n'est pas déjà réservé
      bool isSlotAvailable = true;
      if (widget.unavailableSlots != null) {
        isSlotAvailable = !widget.unavailableSlots!.any((unavailable) =>
          unavailable.year == currentSlot.year &&
          unavailable.month == currentSlot.month &&
          unavailable.day == currentSlot.day &&
          unavailable.hour == currentSlot.hour &&
          unavailable.minute == currentSlot.minute
        );
      }

      if (!isDuringBreak && isSlotAvailable) {
        slots.add(timeOfDay);
      }

      currentSlot = currentSlot.add(Duration(minutes: interval));
    }

    return slots;
  }

  String _getUnavailabilityMessage(DateTime date) {
    final dayOfWeek = date.weekday.toString();
    final hours = widget.restaurant.openingHours[dayOfWeek];

    if (hours == null) {
      return 'Le restaurant est fermé ce jour';
    }

    if (widget.restaurant.holidayDates.any((holiday) =>
        holiday.year == date.year &&
        holiday.month == date.month &&
        holiday.day == date.day)) {
      return 'Le restaurant est fermé (jour férié)';
    }

    return 'Aucun créneau disponible pour cette date';
  }

  void _handleDateChanged(DateTime? date) {
    if (date != null) {
      setState(() {
        _selectedDate = date;
        _selectedTime = null;
      });
      _notifyDateTimeChanged();
    }
  }

  void _handleTimeChanged(TimeOfDay? time) {
    if (time != null) {
      setState(() {
        _selectedTime = time;
      });
      _notifyDateTimeChanged();
    }
  }

  void _notifyDateTimeChanged() {
    if (_selectedTime != null && widget.onDateTimeChanged != null) {
      final dateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );
      widget.onDateTimeChanged!(dateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeSlots = _generateTimeSlots(_selectedDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sélecteur de date
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: widget.firstDate ?? DateTime.now(),
              lastDate: widget.lastDate ?? DateTime.now().add(
                Duration(days: widget.restaurant.maxReservationDays),
              ),
              locale: const Locale('fr', 'FR'),
              selectableDayPredicate: (DateTime date) {
                final dayOfWeek = date.weekday.toString();
                return widget.restaurant.openingHours[dayOfWeek] != null &&
                       !widget.restaurant.holidayDates.any((holiday) =>
                          holiday.year == date.year &&
                          holiday.month == date.month &&
                          holiday.day == date.day);
              },
            );
            _handleDateChanged(date);
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: theme.primaryColor.withOpacity(0.5)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _dateFormat.format(_selectedDate),
                  style: theme.textTheme.bodyLarge,
                ),
                Icon(Icons.calendar_today, color: theme.primaryColor),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // Texte d'instruction pour l'heure
        Text(
          'Choisissez un horaire :',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        
        // Grille des créneaux horaires
        if (timeSlots.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              _getUnavailabilityMessage(_selectedDate),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: timeSlots.map((time) {
              final isSelected = _selectedTime?.hour == time.hour && 
                               _selectedTime?.minute == time.minute;
              
              return InkWell(
                onTap: () => _handleTimeChanged(time),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? theme.primaryColor : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? theme.primaryColor : theme.primaryColor.withOpacity(0.5),
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _timeFormat.format(DateTime(
                      2024,
                      1,
                      1,
                      time.hour,
                      time.minute,
                    )),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isSelected ? Colors.white : theme.primaryColor,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}