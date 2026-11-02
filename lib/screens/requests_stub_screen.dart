import '../services/locale_service.dart';
import 'package:flutter/material.dart';

import '../widgets/message.dart';

/// Заглушка «Подать заявление»: backend-эндпоинт (portal_requests.py)
/// требует session_id, а откуда его брать (какой логин-флоу его выдаёт)
/// пока не определено — экран включаем, когда появится эта часть бэка.
class RequestsStubScreen extends StatelessWidget {
  const RequestsStubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.uiSubmitAnApplication)),
      body: Center(
        child: Message(
          icon: Icons.edit_document,
          title: l10n.uiComingSoon,
          text: l10n.uiThisSectionIsStillBeingDeveloped,
        ),
      ),
    );
  }
}
