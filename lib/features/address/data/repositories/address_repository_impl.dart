import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:eco_bites/core/error/failures.dart';
import 'package:eco_bites/core/network/network_info.dart';
import 'package:eco_bites/features/address/data/datasources/address_remote_data_source.dart';
import 'package:eco_bites/features/address/data/models/address_model.dart';
import 'package:eco_bites/features/address/domain/entities/address.dart';
import 'package:eco_bites/features/address/domain/repositories/address_repository.dart';

class AddressRepositoryImpl implements AddressRepository {
  const AddressRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  final AddressRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  @override
  Future<Either<Failure, void>> saveAddress(String userId, Address address) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.saveAddress(userId, AddressModel.fromEntity(address));
        return const Right<Failure, void>(null);
      } on FirebaseException catch (e) {
        return Left<Failure, void>(FirebaseFailure(e.message));
      }
    } else {
      return const Left<Failure, void>(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, Address?>> fetchUserAddress(String userId) async {
    if (await networkInfo.isConnected) {
      try {
        final AddressModel? addressModel = await remoteDataSource.fetchUserAddress(userId);
        if (addressModel == null) {
          return const Right<Failure, Address?>(null);
        }
        return Right<Failure, Address?>(addressModel);
      } on FirebaseException catch (e) {
        return Left<Failure, Address?>(FirebaseFailure(e.message));
      }
    } else {
      return const Left<Failure, Address?>(NetworkFailure('No internet connection'));
    }
  }
}
