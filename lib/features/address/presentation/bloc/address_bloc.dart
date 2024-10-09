import 'package:eco_bites/features/address/domain/models/address.dart';
import 'package:eco_bites/features/address/presentation/bloc/address_event.dart';
import 'package:eco_bites/features/address/presentation/bloc/address_state.dart';
import 'package:eco_bites/features/address/repository/address_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddressBloc extends Bloc<AddressEvent, AddressState> {
  AddressBloc({required this.addressRepository}) : super(AddressInitial()) {
    on<SaveAddress>(_onSaveAddress);
    on<LoadAddress>(_onLoadAddress);
    on<UpdateCurrentLocation>(_onUpdateCurrentLocation);
    on<ClearAddress>(_onClearAddress);
  }
  final AddressRepository addressRepository;

  Future<String?> _getUserId() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId');
  }

  Future<void> _onSaveAddress(
    SaveAddress event,
    Emitter<AddressState> emit,
  ) async {
    emit(AddressLoading());
    try {
      final String? userId = await _getUserId();
      if (userId == null) {
        throw Exception('User not authenticated');
      }
      await addressRepository.saveAddress(userId, event.address);

      final AddressState currentState = state;
      if (currentState is AddressLoaded) {
        emit(
          AddressLoaded(
            event.address,
            currentLocation: currentState.currentLocation,
          ),
        );
      } else {
        emit(AddressLoaded(event.address));
      }
    } catch (e) {
      emit(AddressError(e.toString()));
    }
  }

  Future<void> _onLoadAddress(
    LoadAddress event,
    Emitter<AddressState> emit,
  ) async {
    emit(AddressLoading());
    try {
      final String? userId = await _getUserId();
      if (userId == null) {
        throw Exception('User not authenticated');
      }
      final List<Address> addresses =
          await addressRepository.fetchUserAddresses(userId);

      if (addresses.isNotEmpty) {
        emit(AddressLoaded(addresses.first));
      } else {
        emit(AddressInitial());
      }
    } catch (e) {
      emit(AddressError(e.toString()));
    }
  }

  Future<void> _onUpdateCurrentLocation(
    UpdateCurrentLocation event,
    Emitter<AddressState> emit,
  ) async {
    final AddressState currentState = state;
    if (currentState is AddressLoaded) {
      emit(
        AddressLoaded(
          currentState.savedAddress,
          currentLocation: event.currentLocation,
        ),
      );
    }
  }

  void _onClearAddress(ClearAddress event, Emitter<AddressState> emit) {
    emit(AddressInitial());
  }
}
