import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/shopping_detail_entry.dart';

void navigateToShoppingDetail(
  BuildContext context,
  ShoppingDetailEntry entry, {
  String source = 'star_data',
}) {
  context.push(
    '/shopping/detail',
    extra: ShoppingDetailArgs(
      entry: entry,
      source: source,
    ),
  );
}

class ShoppingDetailArgs {
  const ShoppingDetailArgs({
    required this.entry,
    required this.source,
  });

  final ShoppingDetailEntry entry;
  final String source;
}



