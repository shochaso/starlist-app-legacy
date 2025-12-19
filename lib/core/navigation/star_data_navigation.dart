import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

const String starDataRouteName = 'star-data-page';
const String myDataRouteName = 'my-data-page';
const String starDataDailyRouteName = 'star-data-page-daily';
const String myDataDailyRouteName = 'my-data-page-daily';

void navigateToStarData(BuildContext context, String username) {
  GoRouter.of(context).goNamed(
    starDataRouteName,
    pathParameters: {'username': username},
  );
}

void navigateToMyData(BuildContext context) {
  GoRouter.of(context).goNamed(myDataRouteName);
}



