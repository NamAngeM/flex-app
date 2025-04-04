import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/profile_service.dart';
import 'services/app_config.dart';
import 'services/storage_service.dart';
import 'services/service_service.dart';
import 'services/category_service.dart';
import 'services/database_service.dart';
import 'services/hotel_service.dart';
import 'services/restaurant_service.dart';
import 'models/user_model.dart';
import 'models/service_model.dart';
import 'models/appointment_model.dart';
import 'models/hotel_model.dart';
import 'models/room_model.dart';
import 'models/hotel_booking_model.dart';
import 'models/restaurant_model.dart';
import 'models/restaurant_table_model.dart';
import 'theme/app_theme.dart';
import 'l10n/app_localizations.dart';
import 'utils/page_transitions.dart';
// Import des écrans
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/appointments_screen.dart';
import 'screens/new_appointment_screen.dart';
import 'screens/appointment_details_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/faq_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/contact_screen.dart';
import 'screens/search_screen.dart';
import 'screens/search_results_screen.dart';
import 'screens/service_details_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/help_screen.dart';
import 'screens/notification_screen.dart';
import 'screens/categories_screen.dart';
import 'screens/category_services_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/email_verification_screen.dart';
import 'screens/provider_selection_screen.dart';
import 'screens/appointment_confirmation_screen.dart';
import 'screens/map_screen.dart';
import 'screens/provider_details_screen.dart';
import 'screens/hotels_screen.dart';
import 'screens/hotel_details_screen.dart';
import 'screens/hotel_booking_screen.dart';
import 'screens/hotel_confirmerdv_screen.dart' as hotel_confirm;
import 'screens/booking_confirmation_screen.dart' hide BookingConfirmationScreen;
import 'screens/my_bookings_screen.dart';
// Import des écrans de restaurant
import 'screens/restaurants_screen.dart';
import 'screens/restaurant_details_screen.dart';
import 'screens/restaurant_booking_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialiser Firebase avec les options par défaut
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  print('🔥 Firebase initialisé avec succès');
  print('🔥 Mode développement: ${AppConfig().isDevMode() ? 'Activé' : 'Désactivé'}');
  print('🔥 Connexion directe à Firebase (pas d\'émulateurs)');
  
  // Vérifier la connexion à Firestore
  try {
    final testDoc = await FirebaseFirestore.instance.collection('test').doc('connectivity').set({
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'connected'
    });
    print('✅ Connexion à Firestore vérifiée avec succès');
  } catch (e) {
    print('❌ Erreur de connexion à Firestore: $e');
  }
  
  // Initialiser les locales pour intl
  await initializeDateFormatting('fr_FR', null);
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final AppConfig _appConfig = AppConfig();
  
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(
          create: (_) => AuthService(),
        ),
        Provider<ProfileService>(
          create: (_) => ProfileService(),
        ),
        Provider<StorageService>(
          create: (_) => StorageService(),
        ),
        Provider<ServiceService>(
          create: (_) => ServiceService(),
        ),
        Provider<CategoryService>(
          create: (_) => CategoryService(),
        ),
        Provider<HotelService>(
          create: (_) => HotelService(),
        ),
        Provider<RestaurantService>(
          create: (_) => RestaurantService(),
        ),
        StreamProvider<UserModel?>(
          create: (context) {
            final authService = context.read<AuthService>();
            if (AppConfig().isDevMode()) {
              print('Mode développement: utilisation d\'un utilisateur de test');
              // En mode développement, créer et retourner immédiatement un utilisateur de test
              return Stream<UserModel?>.value(UserModel(
                uid: 'test-user-id',
                email: 'test@example.com',
                fullName: 'Utilisateur Test',
                photoUrl: 'https://randomuser.me/api/portraits/men/1.jpg',
                role: UserRole.client,
                phoneNumber: '+33123456789',
                preferences: {'theme': 'light', 'notifications': true},
                createdAt: DateTime.now().subtract(Duration(days: 30)),
              ));
            } else {
              // En mode production, utiliser le flux d'authentification normal
              return authService.authStateChanges
                .asyncMap((user) async {
                  if (user == null) return null;
                  final userModel = await authService.getCurrentUser();
                  print('Utilisateur récupéré: ${userModel?.uid ?? 'null'}');
                  return userModel;
                });
            }
          },
          initialData: AppConfig().isDevMode() ? UserModel(
            uid: 'test-user-id',
            email: 'test@example.com',
            fullName: 'Utilisateur Test',
            photoUrl: 'https://randomuser.me/api/portraits/men/1.jpg',
            role: UserRole.client,
            phoneNumber: '+33123456789',
            preferences: {'theme': 'light', 'notifications': true},
            createdAt: DateTime.now().subtract(Duration(days: 30)),
          ) : null,
        ),
      ],
      child: MaterialApp(
        title: 'FlexBook RDV',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [
          const Locale('fr', 'FR'),
          const Locale('en', 'US'),
        ],
        locale: const Locale('fr', 'FR'),
        debugShowCheckedModeBanner: false,
        initialRoute: '/',
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/':
              return AppPageTransitions.fadeTransition(
                page: SplashScreen(),
                settings: settings,
              );
            case '/login':
              return AppPageTransitions.fadeTransition(
                page: LoginScreen(),
                settings: settings,
              );
            case '/home':
              return AppPageTransitions.fadeTransition(
                page: HomeScreen(),
                settings: settings,
              );
            case '/profile':
              return AppPageTransitions.slideTransition(
                page: ProfileScreen(),
                settings: settings,
              );
            case '/appointments':
              return AppPageTransitions.slideTransition(
                page: AppointmentsScreen(),
                settings: settings,
              );
            case '/new-appointment':
              ServiceModel? initialService;
              
              // Gérer les différents types d'arguments possibles
              final args = settings.arguments;
              if (args is ServiceModel) {
                initialService = args;
              } else if (args is Map<String, dynamic>) {
                initialService = args['initialService'] as ServiceModel?;
              }
              
              return AppPageTransitions.slideTransition(
                page: NewAppointmentScreen(
                  initialService: initialService,
                ),
                settings: settings,
              );
            case '/appointment-details':
              return AppPageTransitions.scaleTransition(
                page: AppointmentDetailsScreen(),
                settings: settings,
              );
            case '/edit-profile':
              return AppPageTransitions.slideTransition(
                page: EditProfileScreen(),
                settings: settings,
              );
            case '/faq':
              return AppPageTransitions.fadeTransition(
                page: FaqScreen(),
                settings: settings,
              );
            case '/chat':
              // Extraire les arguments de route
              final args = settings.arguments as Map<String, dynamic>?;
              return AppPageTransitions.slideTransition(
                page: ChatScreen(
                  conversationId: args?['conversationId'] ?? '',
                  otherUserName: args?['otherUserName'] ?? 'Utilisateur',
                  otherUserPhoto: args?['otherUserPhoto'],
                ),
                settings: settings,
              );
            case '/contact':
              return AppPageTransitions.fadeTransition(
                page: ContactScreen(),
                settings: settings,
              );
            case '/search':
              final args = settings.arguments;
              bool isForAppointment = false;
              
              if (args is Map<String, dynamic>) {
                isForAppointment = args['isForAppointment'] ?? false;
              }
              
              return AppPageTransitions.slideTransition(
                page: SearchScreen(isForAppointment: isForAppointment),
                settings: settings,
              );
            case '/search-results':
              // Extraire les arguments de la route
              final args = settings.arguments as Map<String, dynamic>?;
              final query = args?['query'] ?? '';
              final categoryId = args?['categoryId'];
              final isForAppointment = args?['isForAppointment'] ?? false;
              
              return AppPageTransitions.fadeTransition(
                page: SearchResultsScreen(
                  query: query,
                  categoryId: categoryId,
                  isForAppointment: isForAppointment,
                ),
                settings: settings,
              );
            case '/service-details':
              // Extraire les arguments de la route
              final args = settings.arguments;
              String serviceId;
              
              // Gérer les différents types d'arguments possibles
              if (args is Map<String, dynamic>) {
                serviceId = args['serviceId'] ?? '1';
              } else if (args is ServiceModel) {
                serviceId = args.id;
              } else if (args is String) {
                serviceId = args;
              } else {
                serviceId = '1'; // Valeur par défaut
              }
              
              return AppPageTransitions.scaleTransition(
                page: ServiceDetailsScreen(serviceId: serviceId),
                settings: settings,
              );
            case '/categories':
              return AppPageTransitions.slideTransition(
                page: CategoriesScreen(),
                settings: settings,
              );
            case '/category-services':
              return AppPageTransitions.slideTransition(
                page: CategoryServicesScreen(),
                settings: settings,
              );
            case '/settings':
              return AppPageTransitions.slideTransition(
                page: SettingsScreen(),
                settings: settings,
              );
            case '/help':
              return AppPageTransitions.fadeTransition(
                page: HelpScreen(),
                settings: settings,
              );
            case '/notifications':
              return AppPageTransitions.slideTransition(
                page: NotificationScreen(),
                settings: settings,
              );
            case '/signup':
              return AppPageTransitions.fadeTransition(
                page: SignUpScreen(),
                settings: settings,
              );
            case '/email-verification':
              return AppPageTransitions.fadeTransition(
                page: EmailVerificationScreen(),
                settings: settings,
              );
            case '/provider-selection':
              final args = settings.arguments as Map<String, dynamic>?;
              final initialService = args?['initialService'] as ServiceModel?;
              
              return AppPageTransitions.slideTransition(
                page: ProviderSelectionScreen(
                  initialService: initialService,
                ),
                settings: settings,
              );
            case '/appointment-confirmation':
              final args = settings.arguments as Map<String, dynamic>;
              final appointment = args['appointment'] as AppointmentModel;
              final serviceName = args['serviceName'] as String?;
              final providerName = args['providerName'] as String?;
              
              return AppPageTransitions.scaleTransition(
                page: AppointmentConfirmationScreen(
                  appointment: appointment,
                  serviceName: serviceName,
                  providerName: providerName,
                ),
                settings: settings,
              );
            case '/map':
              return AppPageTransitions.fadeTransition(
                page: MapScreen(),
                settings: settings,
              );
            case '/provider-map':
              final args = settings.arguments as Map<String, dynamic>?;
              final providerId = args?['providerId'] as String?;
              
              return AppPageTransitions.fadeTransition(
                page: MapScreen(providerId: providerId),
                settings: settings,
              );
            case '/provider-details':
              final args = settings.arguments as Map<String, dynamic>?;
              final providerId = args?['providerId'] as String? ?? '';
              
              return AppPageTransitions.fadeTransition(
                page: ProviderDetailsScreen(providerId: providerId),
                settings: settings,
              );
            case '/hotels':
              return AppPageTransitions.fadeTransition(
                page: HotelsScreen(),
                settings: settings,
              );
            case '/hotel-details':
              final args = settings.arguments as Map<String, dynamic>?;
              
              return AppPageTransitions.fadeTransition(
                page: HotelDetailsScreen(arguments: args),
                settings: settings,
              );
            case '/hotel-booking':
              final args = settings.arguments as Map<String, dynamic>;
              final hotel = args['hotel'] as HotelModel;
              final room = args['room'] as RoomModel;
              
              return AppPageTransitions.fadeTransition(
                page: HotelBookingScreen(
                  hotel: hotel,
                  room: room,
                ),
                settings: settings,
              );
            case '/hotel-booking-confirmation':
              final args = settings.arguments as Map<String, dynamic>;
              final booking = args['booking'] as HotelBookingModel;
              final hotel = args['hotel'] as HotelModel;
              final room = args['room'] as RoomModel;
              
              return AppPageTransitions.scaleTransition(
                page: hotel_confirm.BookingConfirmationScreen(
                  booking: booking,
                  hotel: hotel,
                  room: room,
                ),
                settings: settings,
              );
            case '/my-bookings':
              return AppPageTransitions.slideTransition(
                page: const MyBookingsScreen(),
                settings: settings,
              );
            case '/restaurants':
              return AppPageTransitions.fadeTransition(
                page: RestaurantsScreen(),
                settings: settings,
              );
            case '/restaurant-details':
              final args = settings.arguments as Map<String, dynamic>?;
              final restaurantId = args?['restaurantId'] as String? ?? '';
              
              return AppPageTransitions.fadeTransition(
                page: RestaurantDetailsScreen(restaurantId: restaurantId),
                settings: settings,
              );
            case '/restaurant-booking':
              final args = settings.arguments as Map<String, dynamic>;
              final restaurantId = args['restaurantId'] as String;
              final restaurantName = args['restaurantName'] as String;
              
              return AppPageTransitions.fadeTransition(
                page: RestaurantBookingScreen(
                  restaurantId: restaurantId,
                  restaurantName: restaurantName,
                ),
                settings: settings,
              );
            default:
              return null;
          }
        },
      ),
    );
  }
}