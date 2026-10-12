import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/photo_credits.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/brand_mark.dart';
import '../../logic/settings/settings_cubit.dart';
import '../../routing/app_routes.dart';
import '../common/l10n_extensions.dart';
import '../common/language_toggle.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _pageCount = 3;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish(String route) async {
    await context.read<SettingsCubit>().completeOnboarding();
    if (mounted) context.go(route);
  }

  void _next() => _controller.nextPage(
        duration: AppDurations.slow,
        curve: Curves.easeOutCubic,
      );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final pages = [
      (l10n.onboarding1Title, l10n.onboarding1Body),
      (l10n.onboarding2Title, l10n.onboarding2Body),
      (l10n.onboarding3Title, l10n.onboarding3Body),
    ];
    final isLast = _page == _pageCount - 1;
    final colors = context.colors;
    final palette = context.palette;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Photos cross-fade with the page.
          for (var i = 0; i < _pageCount; i++)
            AnimatedOpacity(
              opacity: i == _page ? 1 : 0,
              duration: AppDurations.slow,
              child: Image.asset(
                BundledPhotos.onboarding[i].asset,
                fit: BoxFit.cover,
                excludeFromSemantics: true,
              ),
            ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0, 0.35, 0.62, 1],
                colors: [
                  palette.imageScrim.withValues(alpha: 0.35),
                  Colors.transparent,
                  palette.imageScrim.withValues(alpha: 0.75),
                  palette.imageScrim,
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.xs,
                    AppSpacing.xs,
                    0,
                  ),
                  child: Row(
                    children: [
                      BrandLockup(name: l10n.appName, inverted: true),
                      const Spacer(),
                      const LanguageToggle(onDark: true),
                      if (!isLast)
                        TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => _controller.animateToPage(
                            _pageCount - 1,
                            duration: AppDurations.slow,
                            curve: Curves.easeOutCubic,
                          ),
                          child: Text(l10n.onboardingSkip),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: _pageCount,
                    onPageChanged: (i) => setState(() => _page = i),
                    itemBuilder: (context, i) => Semantics(
                      label: l10n.onboardingPageLabel(i + 1, _pageCount),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xl,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pages[i].$1,
                              style: context.textStyles.headlineLarge?.copyWith(
                                color: Colors.white,
                                height: 1.15,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              pages[i].$2,
                              style: context.textStyles.bodyLarge?.copyWith(
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xl),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    0,
                    AppSpacing.xl,
                    AppSpacing.xl,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _PageDots(count: _pageCount, index: _page),
                      const SizedBox(height: AppSpacing.xl),
                      AnimatedSwitcher(
                        duration: AppDurations.medium,
                        child: isLast
                            ? Column(
                                key: const ValueKey('final'),
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  FilledButton(
                                    onPressed: () => _finish(AppRoutes.register),
                                    child: Text(l10n.onboardingCreateAccount),
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      side: const BorderSide(
                                        color: Colors.white70,
                                      ),
                                    ),
                                    onPressed: () => _finish(AppRoutes.login),
                                    child: Text(l10n.onboardingHaveAccount),
                                  ),
                                ],
                              )
                            : FilledButton.icon(
                                key: const ValueKey('next'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: colors.primary,
                                ),
                                onPressed: _next,
                                icon: const Icon(Icons.arrow_forward),
                                iconAlignment: IconAlignment.end,
                                label: Text(l10n.onboardingNext),
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Row(
        children: [
          for (var i = 0; i < count; i++)
            AnimatedContainer(
              duration: AppDurations.medium,
              curve: Curves.easeOutCubic,
              margin: const EdgeInsetsDirectional.only(end: AppSpacing.xs),
              width: i == index ? 28 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: i == index ? Colors.white : Colors.white.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
        ],
      ),
    );
  }
}
