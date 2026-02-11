import 'dart:convert';
import 'package:flutter/material.dart';

@immutable
class Group {
  final int? id;
  final String name;
  final List<String> members;
  final String paidBy;
  final DateTime createdAt;
  final String? notes;
  final bool isArchived;
  final String type; // 'trip', 'home', 'other'

  const Group({
    this.id,
    required this.name,
    required this.members,
    required this.paidBy,
    required this.createdAt,
    this.notes,
    this.isArchived = false,
    this.type = 'trip',
  });

  Group copyWith({
    int? id,
    String? name,
    List<String>? members,
    String? paidBy,
    DateTime? createdAt,
    String? notes,
    bool? isArchived,
    String? type,
  }) {
    return Group(
      id: id ?? this.id,
      name: name ?? this.name,
      members: members ?? this.members,
      paidBy: paidBy ?? this.paidBy,
      createdAt: createdAt ?? this.createdAt,
      notes: notes ?? this.notes,
      isArchived: isArchived ?? this.isArchived,
      type: type ?? this.type,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'members': jsonEncode(members),
      'paidBy': paidBy,
      'createdAt': createdAt.toIso8601String(),
      'notes': notes,
      'isArchived': isArchived ? 1 : 0,
      'type': type,
    };
  }

  factory Group.fromMap(Map<String, dynamic> map) {
    return Group(
      id: map['id'],
      name: map['name'],
      members: List<String>.from(jsonDecode(map['members'])),
      paidBy: map['paidBy'],
      createdAt: DateTime.parse(map['createdAt']),
      notes: map['notes'],
      isArchived: (map['isArchived'] is int) ? (map['isArchived'] == 1) : (map['isArchived'] == true),
      type: map['type'] ?? 'trip',
    );
  }
}
