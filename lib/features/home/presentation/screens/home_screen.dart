import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eco_bites/core/utils/distance.dart';
import 'package:eco_bites/features/address/domain/models/address.dart';
import 'package:eco_bites/features/address/presentation/bloc/address_bloc.dart';
import 'package:eco_bites/features/address/presentation/bloc/address_event.dart';
import 'package:eco_bites/features/address/presentation/bloc/address_state.dart';
import 'package:eco_bites/features/address/presentation/screens/address_screen.dart';
import 'package:eco_bites/features/food/domain/models/cuisine_type.dart';
import 'package:eco_bites/features/food/presentation/bloc/food_business_bloc.dart';
import 'package:eco_bites/features/food/presentation/bloc/food_business_event.dart';
import 'package:eco_bites/features/home/presentation/bloc/home_bloc.dart';
import 'package:eco_bites/features/home/presentation/widgets/for_you_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:material_symbols_icons/symbols.dart';

class HomeScreen extends StatefulWidget { // Pass appLaunchTime from splash screen

  const HomeScreen({super.key, required this.appLaunchTime});
  final DateTime appLaunchTime;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider<HomeBloc>(
      create: (BuildContext context) => HomeBloc(),
      child: HomeScreenContent(appLaunchTime: widget.appLaunchTime),
    );
  }
}
class HomeScreenContent extends StatefulWidget { // Get the app launch time

  const HomeScreenContent({super.key, required this.appLaunchTime});

  final DateTime appLaunchTime;

  @override
  State<HomeScreenContent> createState() => _HomeScreenContentState();
}
class _HomeScreenContentState extends State<HomeScreenContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  StreamSubscription<Position>? _positionStreamSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 6,
      vsync: this,
    );
    _tabController.addListener(_handleTabSelection);

    // Measure and log loading time after UI is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final DateTime homePageRenderedTime = DateTime.now();
      final Duration loadTime = homePageRenderedTime.difference(widget.appLaunchTime);
      logEvent('Home page loaded in ${loadTime.inMilliseconds}ms');
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final AddressState addressState = context.read<AddressBloc>().state;
      if (addressState is! AddressLoaded) {
        context.read<AddressBloc>().add(LoadAddress());
      }
      _startListeningToLocationChanges();

      // Fetch offers for the user's favorite cuisine when the screen loads
      // Assuming you have a way to get the user's favorite cuisine
      // TODO(abel): Implement a method to get the user's favorite cuisine
      // For now, we'll use a default value
      context.read<FoodBusinessBloc>().add(
            const FetchSurplusFoodBusinesses(
              favoriteCuisine: CuisineType.local,
            ),
          );
    });
  }

  Future<void> logEvent(String message) async {
    await FirebaseFirestore.instance.collection('logs').add(<String, dynamic>{
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  void _startListeningToLocationChanges() {
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 100, // Update every 100 meters
      ),
    ).listen((Position position) {
      _updateCurrentLocation(position);
    });
  }

  void _updateCurrentLocation(Position position) {
    context.read<AddressBloc>().add(
          UpdateCurrentLocation(
            Address(
              fullAddress: '',
              latitude: position.latitude,
              longitude: position.longitude,
            ),
          ),
        );
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      context.read<HomeBloc>().add(TabChanged(_tabController.index));
    }
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _navigateToAddressScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext context) => const AddressScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(top: 32.0, left: 16.0, right: 16.0),
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: BlocBuilder<AddressBloc, AddressState>(
                  builder: (BuildContext context, AddressState state) {
                    if (state is AddressLoaded) {
                      final bool isFar = state.currentLocation != null &&
                          isFarFromSavedAddress(
                            state.currentLocation!.latitude,
                            state.currentLocation!.longitude,
                            state.savedAddress.latitude,
                            state.savedAddress.longitude,
                          );
                      return Column(
                        children: <Widget>[
                          GestureDetector(
                            onTap: _navigateToAddressScreen,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Icon(
                                  Symbols.location_on_rounded,
                                  fill: 1,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  state.savedAddress.fullAddress,
                                  style: theme.textTheme.titleMedium,
                                ),
                              ],
                            ),
                          ),
                          if (isFar) ...<Widget>[
                            const SizedBox(height: 8),
                            Text(
                              'You are far from your saved address',
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: Colors.red),
                            ),
                          ],
                        ],
                      );
                    }
                    return GestureDetector(
                      onTap: _navigateToAddressScreen,
                      child: Text(
                        'Add an address',
                        style: theme.textTheme.titleMedium,
                      ),
                    );
                  },
                ),
              ),
              // Search Bar
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search deals...',
                  suffixIcon: const Icon(Symbols.search_rounded, fill: 1),
                  border: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  fillColor: theme.colorScheme.surfaceContainerHigh,
                  filled: true,
                ),
                onChanged: (String query) {
                  context.read<HomeBloc>().add(SearchQueryChanged(query));
                },
              ),
              const SizedBox(height: 16),
              // Carousel
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: CarouselView(
                    itemExtent: 330,
                    shrinkExtent: 200,
                    children: <Widget>[
                      Image.asset(
                        'assets/carousel/50off.jpeg',
                        fit: BoxFit.cover,
                      ),
                      Image.asset(
                        'assets/carousel/free-delivery.jpeg',
                        fit: BoxFit.cover,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Tab Bar
              BlocBuilder<HomeBloc, HomeState>(
                buildWhen: (HomeState previous, HomeState current) =>
                    previous.selectedTabIndex != current.selectedTabIndex,
                builder: (BuildContext context, HomeState state) {
                  return Column(
                    children: <Widget>[
                      TabBar(
                        controller: _tabController,
                        isScrollable: true,
                        tabs: <Widget>[
                          _buildTab(
                            Symbols.recommend_rounded,
                            'For You',
                            0,
                            state.selectedTabIndex,
                          ),
                          _buildTab(
                            Symbols.fastfood_rounded,
                            'Restaurant',
                            1,
                            state.selectedTabIndex,
                          ),
                          _buildTab(
                            Symbols.nutrition_rounded,
                            'Ingredients',
                            2,
                            state.selectedTabIndex,
                          ),
                          _buildTab(
                            Symbols.store_rounded,
                            'Store',
                            3,
                            state.selectedTabIndex,
                          ),
                          _buildTab(
                            Symbols.bakery_dining,
                            'Diary',
                            4,
                            state.selectedTabIndex,
                          ),
                          _buildTab(
                            Symbols.local_cafe_rounded,
                            'Drink',
                            5,
                            state.selectedTabIndex,
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 200,
                        child: TabBarView(
                          controller: _tabController,
                          children: const <Widget>[
                            ForYouTab(),
                            Center(child: Text('Restaurant Content')),
                            Center(child: Text('Ingredients Content')),
                            Center(child: Text('Store Content')),
                            Center(child: Text('Diary Content')),
                            Center(child: Text('Drink Content')),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTab(IconData icon, String label, int index, int selectedIndex) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            icon,
            fill: selectedIndex == index ? 1 : 0,
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}
