import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/person.dart';
import '../models/food_item.dart';
import '../models/round.dart';
import 'package:uuid/uuid.dart';

enum TaxMode { percent, absolute }

class BillProvider with ChangeNotifier {
  List<Person> people = [];
  List<FoodItem> foods = [];
  List<Round> rounds = [];

  TaxMode taxMode = TaxMode.percent;
  String cgst = '0';
  String sgst = '0';
  String service = '0';

  Map<String, double> _payments = {};
  List<Map<String, dynamic>> _settlementHistory = [];

  static const _kPeople = 'people_v1';
  static const _kFoods = 'foods_v1';
  static const _kRounds = 'rounds_v1';
  static const _kTaxMode = 'taxmode_v1';
  static const _kCGST = 'cgst_v1';
  static const _kSGST = 'sgst_v1';
  static const _kService = 'service_v1';
  static const _kPayments = 'payments_v1';
  static const _kHistory = 'settlement_history_v1';

  String newId([String prefix = 'id']) => '$prefix${DateTime.now().microsecondsSinceEpoch}';

  Future<void> loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();

    final pjson = prefs.getString(_kPeople);
    if (pjson != null) {
      try {
        final list = json.decode(pjson) as List;
        people = list.map((e) => Person.fromJson(e)).toList();
      } catch (_) {}
    }

    final fjson = prefs.getString(_kFoods);
    if (fjson != null) {
      try {
        final list = json.decode(fjson) as List;
        foods = list.map((e) => FoodItem.fromJson(e)).toList();
      } catch (_) {}
    }

    final rjson = prefs.getString(_kRounds);
    if (rjson != null) {
      try {
        final list = json.decode(rjson) as List;
        rounds = list.map((e) => Round.fromJson(e)).toList();
      } catch (_) {}
    }

    final mode = prefs.getString(_kTaxMode);
    if (mode != null) taxMode = mode == 'percent' ? TaxMode.percent : TaxMode.absolute;
    cgst = prefs.getString(_kCGST) ?? '0';
    sgst = prefs.getString(_kSGST) ?? '0';
    service = prefs.getString(_kService) ?? '0';

    await _loadPayments();
    await _loadHistory();
    notifyListeners();
  }

  Future<void> _saveAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPeople, json.encode(people.map((e) => e.toJson()).toList()));
    await prefs.setString(_kFoods, json.encode(foods.map((e) => e.toJson()).toList()));
    await prefs.setString(_kRounds, json.encode(rounds.map((e) => e.toJson()).toList()));
    await prefs.setString(_kTaxMode, taxMode == TaxMode.percent ? 'percent' : 'absolute');
    await prefs.setString(_kCGST, cgst);
    await prefs.setString(_kSGST, sgst);
    await prefs.setString(_kService, service);
  }

  // People
  void addPerson(String name) {
    people.add(Person(id: const Uuid().v4(), name: name));
    _saveAll();
    notifyListeners();
  }

  void removePerson(String id) {
    people.removeWhere((p) => p.id == id);
    for (var round in rounds) round.participantIds.remove(id);
    for (var food in foods) food.assigned.remove(id);
    _saveAll();
    notifyListeners();
  }

  void editPerson(String id, String newName) {
    final index = people.indexWhere((p) => p.id == id);
    if (index != -1) {
      people[index].name = newName;
      _saveAll();
      notifyListeners();
    }
  }

  // Food items
  void addFood(String name, double price, int qty, {String? roundId}) {
    final assigned = people.isNotEmpty ? people.map((p) => p.id).toSet() : <String>{};
    foods.add(FoodItem(
      id: newId('f'),
      name: name,
      price: price,
      qty: qty,
      assigned: assigned,
      roundNumber: roundId,
      isRoundBased: roundId != null,
    ));
    _saveAll();
    notifyListeners();
  }

  void editFood(String id, {String? name, double? price, int? qty, String? roundId}) {
    final f = foods.firstWhere((x) => x.id == id);
    if (name != null) f.name = name;
    if (price != null) f.price = price;
    if (qty != null) f.qty = qty;
    if (roundId != null) {
      f.roundNumber = roundId;
      f.isRoundBased = true;
    }
    _saveAll();
    notifyListeners();
  }

  void removeFood(String id) {
    foods.removeWhere((f) => f.id == id);
    _saveAll();
    notifyListeners();
  }

  // FIXED: preserve round association when manually assigning participants
  void assignFood(String foodId, Set<String> assigned) {
    final f = foods.firstWhere((x) => x.id == foodId);
    f.assigned = assigned;
    // Do NOT clear roundNumber or isRoundBased – keep the round association.
    // Only if the user explicitly wants to remove from round, they can edit the food.
    _saveAll();
    notifyListeners();
  }

  // Rounds
  void addRound(String name, Set<String> participantIds) {
    rounds.add(Round(id: const Uuid().v4(), name: name, participantIds: participantIds));
    _saveAll();
    notifyListeners();
  }

  void updateRound(String roundId, {String? name, Set<String>? participantIds}) {
    final round = rounds.firstWhere((r) => r.id == roundId);
    if (name != null) round.name = name;
    if (participantIds != null) round.participantIds = participantIds;
    _saveAll();
    notifyListeners();
  }

  void deleteRound(String roundId) {
    rounds.removeWhere((r) => r.id == roundId);
    for (var food in foods) {
      if (food.roundNumber == roundId) {
        // Option: either remove round association or keep it but mark isRoundBased false
        food.isRoundBased = false;
        food.roundNumber = null;
      }
    }
    _saveAll();
    notifyListeners();
  }

  // Calculations
  double get subtotal => foods.fold(0.0, (s, f) => s + f.price * f.qty);
  double _toDouble(String s) => double.tryParse(s) ?? 0.0;

  Map<String, double> perPersonTotals() {
    final Map<String, double> totals = {};
    for (var p in people) totals[p.id] = 0.0;

    for (var f in foods) {
      final cost = f.price * f.qty;
      Set<String> participants;
      if (f.isRoundBased && f.roundNumber != null) {
        final round = rounds.firstWhere(
              (r) => r.id == f.roundNumber,
          orElse: () => Round(id: '', name: '', participantIds: {}),
        );
        participants = round.participantIds.isNotEmpty
            ? round.participantIds
            : people.map((p) => p.id).toSet();
      } else {
        participants = f.assigned.isNotEmpty
            ? f.assigned
            : people.map((p) => p.id).toSet();
      }
      if (participants.isEmpty) continue;
      final share = cost / participants.length;
      for (var pid in participants) totals[pid] = (totals[pid] ?? 0) + share;
    }

    if (taxMode == TaxMode.percent) {
      final multiplier = 1.0 + (_toDouble(cgst) + _toDouble(sgst) + _toDouble(service)) / 100.0;
      totals.updateAll((k, v) => v * multiplier);
    } else {
      final totalTax = _toDouble(cgst) + _toDouble(sgst) + _toDouble(service);
      final baseSum = totals.values.fold(0.0, (a, b) => a + b);
      if (baseSum <= 0.0001) {
        if (people.isNotEmpty) {
          final equalShare = (subtotal + totalTax) / people.length;
          for (var p in people) totals[p.id] = equalShare;
        }
      } else {
        totals.updateAll((k, v) {
          final taxShare = (v / baseSum) * totalTax;
          return v + taxShare;
        });
      }
    }
    return totals;
  }

  double getPersonShare(String personId) => perPersonTotals()[personId] ?? 0.0;

  void updateTaxes({TaxMode? mode, String? cgstV, String? sgstV, String? serviceV}) {
    if (mode != null) taxMode = mode;
    if (cgstV != null) cgst = cgstV;
    if (sgstV != null) sgst = sgstV;
    if (serviceV != null) service = serviceV;
    _saveAll();
    notifyListeners();
  }

  // Payments & History
  Map<String, double> get payments => Map.unmodifiable(_payments);

  void setPayment(String personId, double amount) {
    _payments[personId] = amount;
    _savePayments();
    notifyListeners();
  }

  double getPayment(String personId) => _payments[personId] ?? 0.0;

  void clearAllPayments() {
    _payments.clear();
    _savePayments();
    notifyListeners();
  }

  Future<void> _savePayments() async {
    final prefs = await SharedPreferences.getInstance();
    final paymentsJson = _payments.map((k, v) => MapEntry(k, v.toString()));
    await prefs.setString(_kPayments, jsonEncode(paymentsJson));
  }

  Future<void> _loadPayments() async {
    final prefs = await SharedPreferences.getInstance();
    final String? paymentsString = prefs.getString(_kPayments);
    if (paymentsString != null) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(paymentsString);
        _payments = decoded.map((k, v) => MapEntry(k, double.parse(v.toString())));
      } catch (_) {}
    }
  }

  List<Map<String, dynamic>> get settlementHistory => List.unmodifiable(_settlementHistory);

  void addSettlementToHistory(Map<String, dynamic> settlement) {
    _settlementHistory.insert(0, settlement);
    _saveHistory();
    notifyListeners();
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kHistory, jsonEncode(_settlementHistory));
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? historyString = prefs.getString(_kHistory);
    if (historyString != null) {
      try {
        _settlementHistory = List<Map<String, dynamic>>.from(jsonDecode(historyString));
      } catch (_) {}
    }
  }

  Future<void> clearAll() async {
    people.clear();
    foods.clear();
    rounds.clear();
    cgst = '0';
    sgst = '0';
    service = '0';
    _payments.clear();
    _settlementHistory.clear();
    await _saveAll();
    await _savePayments();
    await _saveHistory();
    notifyListeners();
  }
}