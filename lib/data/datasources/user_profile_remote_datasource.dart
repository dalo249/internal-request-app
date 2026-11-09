import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:internal_request_app/core/utils/result.dart';
import 'package:internal_request_app/domain/models/user_profile.dart';

class UserProfileRemoteDataSource {
  UserProfileRemoteDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  Future<Result<void>> createProfile(UserProfile profile) async {
    final data = profile.toJson()..['createdAt'] = FieldValue.serverTimestamp();

    try {
      await _users.doc(profile.uid).set(data);
      return Result<void>.ok(null);
    } on FirebaseException catch (exception) {
      return Result<void>.error(exception);
    } on Exception catch (exception) {
      return Result<void>.error(exception);
    }
  }

  Stream<Result<UserProfile?>> watchProfile(String uid) async* {
    try {
      await for (final snapshot in _users.doc(uid).snapshots()) {
        if (!snapshot.exists) {
          yield Result.ok(null);
          continue;
        }

        try {
          final data = snapshot.data();
          if (data == null) {
            yield Result.error(
              const FormatException('El perfil no contiene datos.'),
            );
            continue;
          }

          final createdAt = data['createdAt'];
          if (createdAt is Timestamp) {
            data['createdAt'] = createdAt.toDate().toIso8601String();
          }
          data['uid'] = snapshot.id;
          yield Result.ok(UserProfile.fromJson(data));
        } on Exception catch (exception) {
          yield Result.error(exception);
        }
      }
    } on Exception catch (exception) {
      yield Result.error(exception);
    }
  }
}
