/// Ответ GET /api/v1/auth/me.
///
/// ВНИМАНИЕ: точная форма ответа не описана во FRONTEND_CONTRACT.md —
/// там указан только заголовок X-Unio-Token, без примера JSON. Формат
/// ниже — разумное предположение по аналогии с телами /auth/guest и
/// /auth/portal (mode: "guest" | "portal", group_code, portal_login).
/// Если реальный ответ бэка называет поля иначе — просто скажите,
/// и это единственное место, которое нужно будет поправить.
class AccountInfo {
  final String mode; // "guest" | "portal"
  final String? groupCode;
  final String? portalLogin;
 
  const AccountInfo({
    required this.mode,
    this.groupCode,
    this.portalLogin,
  });
 
  bool get isPortal => mode == 'portal';
 
  factory AccountInfo.fromJson(Map<String, dynamic> json) {
    final account = (json['account'] as Map<String, dynamic>?) ?? json;
    return AccountInfo(
      mode: (account['mode'] ?? 'guest').toString(),
      groupCode: account['group_code'] as String?,
      portalLogin: account['portal_login'] as String?,
    );
  }
}