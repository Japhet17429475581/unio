import '../services/locale_service.dart';
import '../widgets/group_picker.dart';
import '../services/groups_service.dart';
import '../services/analytics_service.dart';
import '../utils/user_messages.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../widgets/unio_loader.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/brand.dart';
import '../config/university_config.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/direct_portal_client.dart';
import '../widgets/welcome_visuals.dart';

const onboardingCompletedPreferenceKey = 'onboarding_completed_v1';

enum _EntryStep {
  intro,
  role,
  authChoice,
  guestGroup,
  portalLogin,
  teacherLogin
}

class WelcomeScreen extends StatefulWidget {
  final Future<List<String>> Function() loadGroups;
  final Future<void> Function(String groupCode) onGuestLogin;
  final Future<void> Function(String login, String password, String fio)
      onTeacherLogin;
  final Future<void> Function(String login, String password, String groupCode)
      onPortalLogin;
  const WelcomeScreen(
      {super.key,
      this.loadGroups = fetchGroups,
      required this.onGuestLogin,
      required this.onTeacherLogin,
      required this.onPortalLogin});
  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _pages = PageController();
  _EntryStep? _step;
  int _page = 0;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadFirstLaunch();
  }

  Future<void> _loadFirstLaunch() async {
    var completed = false;
    try {
      completed = (await SharedPreferences.getInstance())
              .getBool(onboardingCompletedPreferenceKey) ??
          false;
    } catch (_) {/* Preferences must never prevent entry. */}
    if (!completed && mounted)
      analytics.track(AnalyticsEvent.onboardingStarted);
    if (mounted)
      setState(() => _step = completed ? _EntryStep.role : _EntryStep.intro);
  }

  Future<void> _finishIntro({bool skipped = false}) async {
    if (_step != _EntryStep.intro) return;
    analytics.track(AnalyticsEvent.onboardingFinished,
        action: skipped ? AnalyticsAction.skipped : AnalyticsAction.completed);
    _goTo(_EntryStep.role);
    try {
      await (await SharedPreferences.getInstance())
          .setBool(onboardingCompletedPreferenceKey, true);
    } catch (_) {
      /* Continue even if the introduction cannot be marked as seen. */
    }
  }

  void _goTo(_EntryStep step) {
    FocusScope.of(context).unfocus();
    setState(() => _step = step);
  }

  bool get _canGoBack =>
      _step != null &&
      _step != _EntryStep.role &&
      (_step != _EntryStep.intro || _page > 0);

  void _back() {
    if (_busy) return;
    switch (_step) {
      case _EntryStep.intro:
        if (_page > 0) _movePage(_page - 1);
      case _EntryStep.authChoice:
      case _EntryStep.teacherLogin:
        _goTo(_EntryStep.role);
      case _EntryStep.guestGroup:
      case _EntryStep.portalLogin:
        _goTo(_EntryStep.authChoice);
      default:
        break;
    }
  }

  void _movePage(int index) {
    if (MediaQuery.disableAnimationsOf(context)) {
      _pages.jumpToPage(index);
    } else {
      _pages.animateToPage(index,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOutCubic);
    }
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    // A dedicated brand palette; the application's selected theme is preserved.
    final theme = buildWelcomeTheme().copyWith(
      scaffoldBackgroundColor: welcomeBackground,
      colorScheme: buildWelcomeTheme().colorScheme.copyWith(
          primary: welcomeAccent,
          onPrimary: welcomeBackground,
          surface: welcomeSurface,
          onSurface: const Color(0xFFF4F2FF)),
      textSelectionTheme: const TextSelectionThemeData(
          cursorColor: welcomeAccent,
          selectionColor: Color(0x556B2FF5),
          selectionHandleColor: welcomeAccent),
      inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: welcomeSurface,
          labelStyle: const TextStyle(color: welcomeMuted),
          floatingLabelStyle: const TextStyle(color: welcomeAccent),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: Color(0xFF303349))),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: welcomeAccent, width: 1.5))),
    );
    return Theme(
        data: theme,
        child: AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.light.copyWith(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: welcomeBackground,
              systemNavigationBarDividerColor: Colors.transparent,
              systemNavigationBarIconBrightness: Brightness.light,
              systemNavigationBarContrastEnforced: false),
          child: PopScope(
            canPop: !_canGoBack && !_busy,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop) _back();
            },
            child: Scaffold(
                body: WelcomeBackdrop(
                    child: SafeArea(
                        child: Column(children: [
              Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 16, 8),
                  child: Row(children: [
                    if (_canGoBack) ...[
                      IconButton(
                          onPressed: _busy ? null : _back,
                          tooltip: l10n.uiBack,
                          icon: const Icon(Icons.arrow_back_rounded,
                              color: welcomeMuted)),
                      const SizedBox(width: 6)
                    ],
                    const WelcomeWordmark(),
                    const Spacer(),
                    if (_step == _EntryStep.intro)
                      TextButton(
                          onPressed: () => _finishIntro(skipped: true),
                          style: TextButton.styleFrom(
                              foregroundColor: welcomeMuted,
                              textStyle: const TextStyle(
                                  fontFamily: 'Onest',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500)),
                          child: Text(l10n.uiSkip)),
                  ])),
              Expanded(
                  child: AnimatedSwitcher(
                duration: Duration(milliseconds: reducedMotion ? 0 : 420),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) => AnimatedBuilder(
                  animation: animation,
                  child: FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                          position: Tween(
                                  begin: const Offset(.035, 0),
                                  end: Offset.zero)
                              .animate(animation),
                          child: child)),
                  builder: (context, content) {
                    final leaving = animation.status == AnimationStatus.reverse;
                    return IgnorePointer(
                        ignoring: leaving,
                        child: ExcludeSemantics(
                            excluding: leaving, child: content!));
                  },
                ),
                layoutBuilder: (current, previous) => Stack(
                    fit: StackFit.expand,
                    children: [...previous, if (current != null) current]),
                child: switch (_step) {
                  null => const Center(
                      key: ValueKey('loading'),
                      child: SizedBox(
                          width: 24,
                          height: 24,
                          child: UnioLoader(color: welcomeAccent))),
                  _EntryStep.intro => _intro(),
                  _EntryStep.role => _role(),
                  _EntryStep.authChoice => _authChoice(),
                  _ => _EntryForm(
                      key: ValueKey(_step),
                      loadGroups: widget.loadGroups,
                      step: _step!,
                      onBusyChanged: (value) {
                        if (mounted) setState(() => _busy = value);
                      },
                      onGuestLogin: widget.onGuestLogin,
                      onPortalLogin: widget.onPortalLogin,
                      onTeacherLogin: widget.onTeacherLogin),
                },
              )),
            ])))),
          ),
        ));
  }

  Widget _intro() => Column(key: const ValueKey('intro'), children: [
        Expanded(
            child: PageView.builder(
                controller: _pages,
                itemCount: _slides.length,
                onPageChanged: (value) => setState(() => _page = value),
                itemBuilder: (context, index) => AnimatedBuilder(
                    animation: _pages,
                    builder: (context, _) {
                      final distance = _pages.hasClients &&
                              _pages.position.hasContentDimensions
                          ? ((_pages.page ?? _page.toDouble()) - index)
                              .clamp(-1.0, 1.0)
                          : 0.0;
                      return _IntroPage(
                          index: index,
                          displacement: MediaQuery.disableAnimationsOf(context)
                              ? 0
                              : distance);
                    }))),
        Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Center(
                child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Semantics(
                          label: l10n.uiPageOf((_page + 1).toString(),
                              (_slides.length).toString()),
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                for (var i = 0; i < _slides.length; i++)
                                  Semantics(
                                      button: true,
                                      selected: i == _page,
                                      label: l10n.uiPage((i + 1).toString()),
                                      child: InkResponse(
                                          onTap: () => _movePage(i),
                                          radius: 22,
                                          child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 4,
                                                      vertical: 12),
                                              child: AnimatedContainer(
                                                  duration: Duration(
                                                      milliseconds:
                                                          MediaQuery.disableAnimationsOf(
                                                                  context)
                                                              ? 0
                                                              : 300),
                                                  width: i == _page ? 28 : 7,
                                                  height: 7,
                                                  decoration: BoxDecoration(
                                                      color: i == _page
                                                          ? welcomeAccent
                                                          : const Color(
                                                              0xFF36384D),
                                                      borderRadius:
                                                          BorderRadius.circular(9))))))
                              ])),
                      const SizedBox(height: 14),
                      _WelcomeButton(
                          label: _page == _slides.length - 1
                              ? l10n.uiGetStarted
                              : l10n.uiNext276,
                          onPressed: () {
                            if (_page == _slides.length - 1) {
                              _finishIntro();
                            } else {
                              _movePage(_page + 1);
                            }
                          }),
                    ])))),
      ]);

  Widget _role() => _EntryLayout(
      key: const ValueKey('role'),
      eyebrow: l10n.uiLetSGetAcquainted,
      title: l10n.uiChooseYourRole,
      description: l10n.uiStudentsAndTeachersHaveAccessToDifferentSections,
      art: 0,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(l10n.uiDoYouStudyOrTeach,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        const SizedBox(height: 24),
        _ChoiceCard(
            icon: Icons.school_outlined,
            title: l10n.uiIMAStudent,
            subtitle: l10n.uiClassesGradesAndApplications,
            color: welcomeAccent,
            onTap: () {
              analytics.track(AnalyticsEvent.roleSelected,
                  role: AnalyticsRole.student);
              _goTo(_EntryStep.authChoice);
            }),
        const SizedBox(height: 14),
        _ChoiceCard(
            icon: Icons.co_present_outlined,
            title: l10n.uiIMATeacher,
            subtitle: l10n.uiScheduleAndAvailableRooms,
            color: const Color(0xFF87C9FF),
            onTap: () {
              analytics.track(AnalyticsEvent.roleSelected,
                  role: AnalyticsRole.teacher);
              _goTo(_EntryStep.teacherLogin);
            }),
        const SizedBox(height: 22),
        Text(l10n.uiYouCanChangeYourRoleBySigningOut,
            textAlign: TextAlign.center,
            style: TextStyle(color: welcomeMuted, fontSize: 12)),
      ]));

  Widget _authChoice() => _EntryLayout(
      key: const ValueKey('authChoice'),
      eyebrow: l10n.uiForStudents,
      title: l10n.uiHowWouldYouLikeToSignIn,
      description: l10n.uiConnectYourPortalAccountOrStartWithYour,
      art: 1,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(l10n.uiWhatWorksForYou,
            style: TextStyle(fontSize: 25, fontWeight: FontWeight.w700)),
        const SizedBox(height: 24),
        _ChoiceCard(
            icon: Icons.account_balance_outlined,
            title: l10n.uiSignInViaThePortal198(
                (currentUniversity.shortName).toString()),
            subtitle: l10n.uiScheduleGradesAndApplications,
            color: welcomeAccent,
            onTap: () => _goTo(_EntryStep.portalLogin)),
        const SizedBox(height: 14),
        _ChoiceCard(
            icon: Icons.arrow_forward_rounded,
            title: l10n.uiContinueAsAGuest,
            subtitle: l10n.uiStartWithYourGroupCodeYouCanConnect,
            color: const Color(0xFF9DE7CA),
            onTap: () => _goTo(_EntryStep.guestGroup)),
      ]));
}

List<({String label, String title, String accent, String body})> get _slides =>
    [
      (
        label: l10n.uiWelcomeToUnio,
        title: l10n.uiHiThisIsUnio,
        accent: l10n.uiAnAppForYourStudies,
        body: l10n.uiViewYourScheduleSaveAssignmentsAndRequestCertificates
      ),
      (
        label: l10n.uiSchedule297,
        title: l10n.uiYourClassSchedule,
        accent: l10n.uiForTodayAndTheWeek,
        body: l10n.uiChooseADayToViewClassesTimesAnd
      ),
      (
        label: l10n.uiCertificatesAndApplications301,
        title: l10n.uiNeedACertificate,
        accent: l10n.uiRequestItInTheApp,
        body: l10n.uiRequestCertificatesViaThePortalTrackTheirStatus
      ),
      (
        label: l10n.uiMoreFeatures,
        title: l10n.uiNewsAndTeachers,
        accent: l10n.uiHomeworkAndNotes307,
        body: l10n.uiFindTeachersAndTheirClassesReadUniversityNews
      ),
    ];

class _IntroPage extends StatelessWidget {
  final int index;
  final double displacement;
  const _IntroPage({required this.index, required this.displacement});
  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    final slide = _slides[index];
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 760;
      final titleSize = wide
          ? 46.0
          : constraints.maxWidth < 360
              ? 30.0
              : 35.0;
      final text = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            WelcomeReveal(
                delay: .1,
                child: Text(slide.label,
                    style: const TextStyle(
                        color: welcomeAccent,
                        fontSize: 10,
                        letterSpacing: 1.7,
                        fontWeight: FontWeight.w700))),
            const SizedBox(height: 16),
            WelcomeReveal(
                delay: .2,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(slide.title,
                          style: TextStyle(
                              fontSize: titleSize,
                              fontWeight: FontWeight.w700,
                              height: 1.13,
                              letterSpacing: -1.4)),
                      Text(slide.accent,
                          style: TextStyle(
                              fontSize: titleSize,
                              color: welcomeAccent,
                              fontWeight: FontWeight.w700,
                              height: 1.13,
                              letterSpacing: -1.4)),
                    ])),
            const SizedBox(height: 18),
            WelcomeReveal(
                delay: .32,
                child: Text(slide.body,
                    style: const TextStyle(
                        color: welcomeMuted, fontSize: 15, height: 1.65))),
          ]);
      final art = WelcomeReveal(
          child: SizedBox(
              height: wide
                  ? 360
                  : (constraints.maxHeight * .49).clamp(170.0, 300.0),
              child: WelcomeArtwork(page: index, displacement: displacement)));
      return SingleChildScrollView(
          primary: false,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: ConstrainedBox(
              constraints: BoxConstraints(
                  minHeight: math.max(0, constraints.maxHeight - 24)),
              child: Center(
                  child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: wide ? 1040 : 440),
                      child: wide
                          ? Row(children: [
                              Expanded(child: text),
                              const SizedBox(width: 50),
                              Expanded(child: art)
                            ])
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                  art,
                                  const SizedBox(height: 24),
                                  text
                                ])))));
    });
  }
}

class _EntryLayout extends StatelessWidget {
  final String eyebrow, title, description;
  final int art;
  final Widget child;
  const _EntryLayout(
      {super.key,
      required this.eyebrow,
      required this.title,
      required this.description,
      required this.art,
      required this.child});
  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 850;
      final heading =
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (wide) ...[
          SizedBox(height: 280, child: WelcomeArtwork(page: art)),
          const SizedBox(height: 24)
        ],
        Text(eyebrow,
            style: const TextStyle(
                color: welcomeAccent,
                fontSize: 10,
                letterSpacing: 1.8,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        Text(title,
            style: TextStyle(
                fontSize: wide ? 44 : 33,
                fontWeight: FontWeight.w700,
                letterSpacing: -1,
                height: 1.15)),
        const SizedBox(height: 14),
        Text(description,
            style:
                const TextStyle(color: welcomeMuted, fontSize: 15, height: 1.6))
      ]);
      return SingleChildScrollView(
          primary: false,
          key: const ValueKey('entryScroll'),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: ConstrainedBox(
              constraints: BoxConstraints(
                  minHeight: math.max(0, constraints.maxHeight - 56)),
              child: Center(
                  child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: wide ? 1080 : 440),
                      child: wide
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                  Expanded(
                                      child: WelcomeReveal(child: heading)),
                                  const SizedBox(width: 72),
                                  Expanded(
                                      child: WelcomeReveal(
                                          delay: .15,
                                          child: Container(
                                              padding: const EdgeInsets.all(32),
                                              decoration: BoxDecoration(
                                                  color:
                                                      const Color(0xFF111421),
                                                  borderRadius:
                                                      BorderRadius.circular(32),
                                                  border: Border.all(
                                                      color: const Color(
                                                          0xFF272B40))),
                                              child: child)))
                                ])
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                  WelcomeReveal(child: heading),
                                  const SizedBox(height: 36),
                                  WelcomeReveal(delay: .15, child: child)
                                ])))));
    });
  }
}

class _ChoiceCard extends StatefulWidget {
  final IconData icon;
  final String title, subtitle;
  final Color color;
  final VoidCallback onTap;
  const _ChoiceCard(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.color,
      required this.onTap});
  @override
  State<_ChoiceCard> createState() => _ChoiceCardState();
}

class _ChoiceCardState extends State<_ChoiceCard> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    return AnimatedScale(
        scale: _pressed && !MediaQuery.disableAnimationsOf(context) ? .975 : 1,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        child: Material(
            color: welcomeSurface,
            borderRadius: BorderRadius.circular(24),
            child: InkWell(
                onTap: widget.onTap,
                onHighlightChanged: (v) => setState(() => _pressed = v),
                borderRadius: BorderRadius.circular(24),
                splashColor: widget.color.withValues(alpha: .12),
                child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                            color: widget.color.withValues(alpha: .22))),
                    child: Row(children: [
                      Container(
                          width: 48,
                          height: 54,
                          decoration: BoxDecoration(
                              color: widget.color.withValues(alpha: .10),
                              borderRadius: BorderRadius.circular(16)),
                          child:
                              Icon(widget.icon, color: widget.color, size: 27)),
                      const SizedBox(width: 16),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(widget.title,
                                style: const TextStyle(
                                    fontSize: 17, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 6),
                            Text(widget.subtitle,
                                style: const TextStyle(
                                    color: welcomeMuted,
                                    fontSize: 12,
                                    height: 1.5))
                          ])),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded,
                          size: 18, color: welcomeMuted)
                    ])))));
  }
}

class _WelcomeButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  const _WelcomeButton(
      {required this.label, required this.onPressed, this.loading = false});
  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    return SizedBox(
        width: double.infinity,
        child: FilledButton(
            onPressed: loading ? null : onPressed,
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFEAE3FF),
                foregroundColor: welcomeBackground,
                disabledBackgroundColor: const Color(0xFF353147),
                disabledForegroundColor: welcomeMuted,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20))),
            child: loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: UnioLoader(color: welcomeAccent))
                : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Flexible(
                        child: Text(label,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700))),
                    const SizedBox(width: 12),
                    const Icon(Icons.arrow_forward_rounded, size: 20)
                  ])));
  }
}

class _EntryForm extends StatefulWidget {
  final Future<List<String>> Function() loadGroups;
  final _EntryStep step;
  final ValueChanged<bool> onBusyChanged;
  final Future<void> Function(String) onGuestLogin;
  final Future<void> Function(String, String, String) onPortalLogin,
      onTeacherLogin;
  const _EntryForm(
      {super.key,
      required this.loadGroups,
      required this.step,
      required this.onBusyChanged,
      required this.onGuestLogin,
      required this.onTeacherLogin,
      required this.onPortalLogin});
  @override
  State<_EntryForm> createState() => _EntryFormState();
}

class _EntryFormState extends State<_EntryForm> {
  final _groupPicker = GlobalKey<GroupPickerState>();
  final _group = TextEditingController(),
      _fio = TextEditingController(),
      _login = TextEditingController(),
      _password = TextEditingController();
  bool _busy = false, _obscure = true;
  String? _error;
  bool get _teacher => widget.step == _EntryStep.teacherLogin;
  bool get _portal => widget.step == _EntryStep.portalLogin;

  Future<void> _submit() async {
    if (_busy) return;
    var group = _group.text.trim();
    final login = _login.text.trim();
    final fio = _fio.text.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (_teacher
        ? fio.length < 3 ||
            fio.length > 255 ||
            login.isEmpty ||
            _password.text.isEmpty
        : group.isEmpty ||
            (_portal && (login.isEmpty || _password.text.isEmpty))) {
      setState(() => _error = _teacher
          ? fio.length < 3 || fio.length > 255
              ? l10n.uiEnterYourFullNameCharacters
              : l10n.uiEnterYourVgspuPortalUsernameAndPassword
          : _portal
              ? l10n.uiEnterYourGroupUsernameAndPassword
              : l10n.uiEnterYourGroupCode);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    widget.onBusyChanged(true);
    final role = _teacher ? AnalyticsRole.teacher : AnalyticsRole.student;
    final method =
        _teacher || _portal ? AnalyticsMethod.portal : AnalyticsMethod.guest;
    analytics.track(AnalyticsEvent.loginAttempt, role: role, method: method);
    try {
      if (!_teacher) group = await _groupPicker.currentState!.validate();
      if (_teacher) {
        await widget.onTeacherLogin(login, _password.text, fio);
      } else if (_portal) {
        await widget.onPortalLogin(login, _password.text, group);
      } else {
        await widget.onGuestLogin(group);
      }
      analytics.track(AnalyticsEvent.loginResult,
          role: role, method: method, outcome: AnalyticsOutcome.success);
    } catch (error) {
      analytics.track(AnalyticsEvent.loginResult,
          role: role, method: method, outcome: AnalyticsOutcome.failed);
      if (mounted)
        setState(() => _error = switch (error) {
              AuthApiException e => userMessage(e),
              ApiException e => userMessage(e),
              DirectPortalException e => userMessage(e),
              GroupDirectoryException e => e.message,
              _ => l10n.uiCouldNotSignInCheckYourConnectionAnd,
            });
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        widget.onBusyChanged(false);
      }
    }
  }

  @override
  void dispose() {
    _group.dispose();
    _fio.dispose();
    _login.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    return _EntryLayout(
        eyebrow: _teacher
            ? l10n.uiForTeachers314
            : _portal
                ? l10n.uiYourAccount
                : l10n.uiQuickStart,
        title: _teacher
            ? l10n.uiTeacherSchedule
            : _portal
                ? l10n.uiSignInViaThePortal318
                : l10n.uiChooseYourGroup,
        description: _teacher
            ? l10n.uiSignInWithYourVgspuPortalAccountYour
            : _portal
                ? l10n.uiUseYourPortalUsernameAndPassword(
                    (currentUniversity.shortName).toString())
                : kIsWeb
                    ? l10n.uiChooseAGroupAndPlanYourDayNo
                    : l10n.uiEnterYourGroupCodeAndPlanYourDay,
        art: _teacher
            ? 3
            : _portal
                ? 2
                : 1,
        child: AutofillGroup(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
              Text(
                  _teacher
                      ? l10n.uiTeacherSignIn
                      : _portal
                          ? l10n.uiSignInViaThePortal(
                              (currentUniversity.shortName).toString())
                          : l10n.uiGuestAccess,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(height: 24),
              if (_teacher) ...[
                TextField(
                    controller: _fio,
                    enabled: !_busy,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => _clearError(),
                    decoration: InputDecoration(
                        labelText: l10n.uiFullName,
                        prefixIcon:
                            Icon(Icons.school_outlined, color: welcomeMuted))),
                const SizedBox(height: 14)
              ],
              if (!_teacher) ...[
                GroupPicker(
                    key: _groupPicker,
                    load: widget.loadGroups,
                    controller: _group,
                    enabled: !_busy,
                    portal: _portal,
                    onSubmit: _submit,
                    onChanged: _clearError),
                const SizedBox(height: 14)
              ],
              if (_teacher || _portal) ...[
                TextField(
                    controller: _login,
                    enabled: !_busy,
                    autocorrect: false,
                    enableSuggestions: false,
                    autofillHints: const [AutofillHints.username],
                    textCapitalization: TextCapitalization.none,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => _clearError(),
                    decoration: InputDecoration(
                        labelText: l10n.uiPortalUsername,
                        prefixIcon: const Icon(Icons.person_outline_rounded,
                            color: welcomeMuted))),
                const SizedBox(height: 14)
              ],
              if (_portal || _teacher) ...[
                TextField(
                    controller: _password,
                    enabled: !_busy,
                    obscureText: _obscure,
                    autocorrect: false,
                    enableSuggestions: false,
                    autofillHints: const [AutofillHints.password],
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                    onChanged: (_) => _clearError(),
                    decoration: InputDecoration(
                        labelText: l10n.uiPortalPassword,
                        prefixIcon: const Icon(Icons.lock_outline_rounded,
                            color: welcomeMuted),
                        suffixIcon: IconButton(
                            tooltip: _obscure
                                ? l10n.uiShowPassword
                                : l10n.uiHidePassword,
                            onPressed: _busy
                                ? null
                                : () => setState(() => _obscure = !_obscure),
                            icon: Icon(
                                _obscure
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: welcomeMuted)))),
                const SizedBox(height: 14)
              ],
              if (_error != null)
                Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Semantics(
                        liveRegion: true,
                        child: Text(_error!,
                            style: const TextStyle(
                                color: Color(0xFFFFA4AA),
                                fontSize: 13,
                                height: 1.5)))),
              const SizedBox(height: 8),
              _WelcomeButton(
                  label: _portal || _teacher ? l10n.uiSignIn : l10n.uiContinue,
                  onPressed: _submit,
                  loading: _busy),
              const SizedBox(height: 20),
              Text(
                  _teacher || _portal
                      ? kIsWeb
                          ? l10n.uiYourPasswordIsNotSavedInTheBrowser
                          : l10n.uiYourUsernameAndPasswordAreStoredSecurelyOn
                      : l10n.uiNoPortalUsernameOrPasswordNeeded,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: welcomeMuted, fontSize: 12, height: 1.5))
            ])));
  }

  void _clearError() {
    if (_error != null) setState(() => _error = null);
  }
}
