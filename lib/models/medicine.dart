import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

class MedicineModel {
  String? id;
  String? name;
  dynamic measure;
  int? firstStock;
  int? lastStock;
  int? arrivedStock;
  int? returnedStock;
  int? price;
  String? expDt;
  Color? color;
  int? total;
  int? subTotal;

  MedicineModel({
    this.id,
    this.name,
    this.measure,
    this.firstStock,
    this.lastStock,
    this.arrivedStock,
    this.returnedStock,
    this.price,
    this.expDt,
    this.color,
    this.total,
    this.subTotal,
  });

  factory MedicineModel.fromJson(Map<String, dynamic> json, {String? id}) {
    return MedicineModel(
      id: id ?? json['id'],
      name: json['name'],
      measure: json['measure'],
      firstStock: json['first_stock'],
      lastStock: json['last_stock'],
      arrivedStock: json['arrived_stock'],
      returnedStock: json['return_stock'],
      price: json['price'],
      expDt: json['expdt'],
      color: _randomColor(json['name']),
      total: json['total'],
      subTotal: json['sub_total'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'measure': measure,
      'first_stock': firstStock,
      'last_stock': lastStock,
      'arrived_stock': arrivedStock,
      'return_stock': returnedStock,
      'price': price,
      'expdt': expDt,
      'total': total,
      'sub_total': subTotal,
    };
  }

  MedicineModel copyWith({
    String? id,
    String? name,
    dynamic measure,
    int? firstStock,
    int? lastStock,
    int? arrivedStock,
    int? returnedStock,
    int? price,
    String? expDt,
    Color? color,
    int? total,
    int? subTotal,
  }) {
    return MedicineModel(
      id: id ?? this.id,
      name: name ?? this.name,
      measure: measure ?? this.measure,
      firstStock: firstStock ?? this.firstStock,
      lastStock: lastStock ?? this.lastStock,
      arrivedStock: arrivedStock ?? this.arrivedStock,
      returnedStock: returnedStock ?? this.returnedStock,
      price: price ?? this.price,
      expDt: expDt ?? this.expDt,
      color: color ?? this.color,
      total: total ?? this.total,
      subTotal: subTotal ?? this.subTotal,
    );
  }

  static Color _randomColor(String? key) {
    final random = Random(key.hashCode); // generate konsisten
    return Color.fromARGB(
      0xFF,
      random.nextInt(256),
      random.nextInt(256),
      random.nextInt(256),
    );
  }
}
