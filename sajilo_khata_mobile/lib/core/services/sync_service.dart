import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../database/khata_repository.dart';

/// Pushes locally stored (unsynced) records to Cloud Firestore under
/// `shops/{uid}/...`. Customers and inventory are small, so they are upserted whole.
class SyncService {
  SyncService(this._repo, {required this.firebaseReady});

  final KhataRepository _repo;
  final bool firebaseReady;

  static const int _batchLimit = 450;

  /// Returns the number of records pushed. Throws [StateError] if sync is unavailable.
  Future<int> syncNow(String? uid) async {
    if (!firebaseReady || uid == null) {
      throw StateError('Cloud sync unavailable: Firebase is not configured.');
    }

    final shop = FirebaseFirestore.instance.collection('shops').doc(uid);
    final writes =
        <(DocumentReference<Map<String, dynamic>>, Map<String, dynamic>)>[];

    final bills = await _repo.getUnsyncedBills();
    for (final b in bills) {
      writes.add((
        shop.collection('bills').doc('${b.id}'),
        b.toMap()..['syncStatus'] = 1
      ));
    }
    final txs = await _repo.getUnsyncedTransactions();
    for (final t in txs) {
      writes.add((
        shop.collection('transactions').doc('${t.id}'),
        t.toMap()..['syncStatus'] = 1
      ));
    }
    for (final c in await _repo.getCustomers()) {
      writes.add((shop.collection('customers').doc('${c.id}'), c.toMap()));
    }
    for (final p in await _repo.getProducts()) {
      writes.add((shop.collection('inventory').doc('${p.id}'), p.toMap()));
    }

    // Firestore batches are capped at 500 operations
    for (var i = 0; i < writes.length; i += _batchLimit) {
      final batch = FirebaseFirestore.instance.batch();
      for (final (ref, data) in writes.skip(i).take(_batchLimit)) {
        batch.set(ref, data);
      }
      await batch.commit();
    }
    await _repo.markSynced('bills', bills.map((b) => b.id!).toList());
    await _repo.markSynced(
        'khata_transactions', txs.map((t) => t.id!).toList());
    debugPrint(
        'Synced ${bills.length} bills and ${txs.length} ledger entries to Firestore');
    return bills.length + txs.length;
  }
}
