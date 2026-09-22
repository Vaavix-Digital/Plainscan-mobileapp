import 'package:flutter/material.dart';
import 'package:upgrader/upgrader.dart';

void main() {
  final alert = UpgradeAlert(
    navigatorKey: GlobalKey<NavigatorState>(),
    child: Container(),
  );
}
