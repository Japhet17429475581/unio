import '../services/locale_service.dart';
import 'package:flutter/material.dart';
import '../services/pwa_bridge.dart';

Future<void> showPwaHelp(BuildContext context) async {
  if (promptPwaInstall()) return;
  await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
            title: Text(l10n.uiUnioOnYourHomeScreen),
            content: SingleChildScrollView(
                child: Text(l10n.uiOnIphoneOpenUnioInSafariTapShare)),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.uiGotIt))
            ],
          ));
}
