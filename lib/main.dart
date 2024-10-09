import 'package:eco_bites/app.dart';
import 'package:eco_bites/features/address/presentation/bloc/address_bloc.dart';
import 'package:eco_bites/features/address/repository/address_repository.dart';
import 'package:eco_bites/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:eco_bites/features/auth/repository/auth_repository.dart';
import 'package:eco_bites/features/cart/domain/models/cart_item_data.dart';
import 'package:eco_bites/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:eco_bites/features/food/presentation/bloc/food_business_bloc.dart';
import 'package:eco_bites/features/food/repository/food_business_repository.dart';
import 'package:eco_bites/features/orders/presentation/bloc/order_bloc.dart';
import 'package:eco_bites/features/orders/presentation/bloc/order_event.dart';
import 'package:eco_bites/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:nested/nested.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final DateTime appLaunchTime = DateTime.now();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await FirebasePerformance.instance.setPerformanceCollectionEnabled(true);

  final AuthRepository authRepository = AuthRepository();

  await dotenv.load();

  runApp(
    MultiBlocProvider(
      providers: <SingleChildWidget>[
        BlocProvider<CartBloc>(
          create: (BuildContext context) => CartBloc(<CartItemData>[
            CartItemData(
              id: '1',
              title: 'Pineapple Pizza',
              normalPrice: 32000,
              offerPrice: 28000,
            ),
            CartItemData(
              id: '2',
              title: 'Donut',
              normalPrice: 21000,
              offerPrice: 11000,
              quantity: 2,
            ),
            CartItemData(
              id: '3',
              title: 'Cheeseburger',
              normalPrice: 15000,
              offerPrice: 12000,
            ),
          ]),
        ),
        BlocProvider<AuthBloc>(
          create: (BuildContext context) =>
              AuthBloc(authRepository: authRepository),
        ),
        BlocProvider<OrderBloc>(
          create: (BuildContext context) => OrderBloc()..add(LoadOrders()),
        ),
        BlocProvider<AddressBloc>(
          create: (BuildContext context) => AddressBloc(
            addressRepository: AddressRepository(),
          ),
        ),
        BlocProvider<FoodBusinessBloc>(
          create: (BuildContext context) => FoodBusinessBloc(
            foodBusinessRepository: FoodBusinessRepository(),
            addressBloc: context.read<AddressBloc>(),
          ),
        ),
      ],
      child: MyApp(
        appLaunchTime: appLaunchTime,
      ),
    ),
  );
}
