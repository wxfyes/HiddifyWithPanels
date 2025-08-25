import 'package:dartx/dartx.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:hiddify/core/app_info/app_info_provider.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/failures.dart';
import 'package:hiddify/core/router/router.dart';
import 'package:hiddify/features/common/nested_app_bar.dart';
import 'package:hiddify/features/home/widget/connection_button.dart';
import 'package:hiddify/features/home/widget/empty_profiles_home_body.dart';
import 'package:hiddify/features/profile/notifier/active_profile_notifier.dart';
import 'package:hiddify/features/profile/widget/profile_tile.dart';
import 'package:hiddify/features/proxy/active/active_proxy_delay_indicator.dart';
import 'package:hiddify/features/proxy/active/active_proxy_footer.dart';
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hiddify/features/connection/model/connection_status.dart';
import 'package:hiddify/features/proxy/active/active_proxy_notifier.dart';
import 'package:hiddify/features/config_option/notifier/config_option_notifier.dart';
import 'package:hiddify/features/config_option/data/config_option_repository.dart';
import 'package:hiddify/features/connection/widget/experimental_feature_notice.dart';
import 'package:hiddify/core/theme/theme_extensions.dart';
import 'package:hiddify/utils/placeholders.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:sliver_tools/sliver_tools.dart';
import 'package:hiddify/features/common/glass_container.dart';
import 'package:url_launcher/url_launcher.dart';

// 发光彩色流动效果连接按钮
class GlowingConnectionButton extends StatefulWidget {
  const GlowingConnectionButton({super.key});

  @override
  State<GlowingConnectionButton> createState() => _GlowingConnectionButtonState();
}

class _GlowingConnectionButtonState extends State<GlowingConnectionButton>
    with TickerProviderStateMixin {
  late AnimationController _colorController;
  late AnimationController _glowController;
  late Animation<Color?> _colorAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    
    // 颜色动画控制器
    _colorController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
    
    // 发光动画控制器
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    // 颜色动画 - 在多种颜色之间循环
    _colorAnimation = ColorTween(
      begin: Colors.cyan,
      end: Colors.purple,
    ).animate(CurvedAnimation(
      parent: _colorController,
      curve: Curves.easeInOut,
    ));

    // 发光动画
    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _colorController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final t = ref.watch(translationsProvider);
        final connectionStatus = ref.watch(connectionNotifierProvider);
        final activeProxy = ref.watch(activeProxyNotifierProvider);
        final delay = activeProxy.valueOrNull?.urlTestDelay ?? 0;

        final requiresReconnect = ref.watch(configOptionNotifierProvider).valueOrNull;

        final buttonTheme = Theme.of(context).extension<ConnectionButtonTheme>()!;

        Future<bool> showExperimentalNotice() async {
          final hasExperimental = ref.read(ConfigOptions.hasExperimentalFeatures);
          final canShowNotice = !ref.read(disableExperimentalFeatureNoticeProvider);
          if (hasExperimental && canShowNotice && context.mounted) {
            return await const ExperimentalFeatureNoticeDialog().show(context) ?? false;
          }
          return true;
        }

        final onTap = switch (connectionStatus) {
          AsyncData(value: Disconnected()) || AsyncError() => () async {
              if (await showExperimentalNotice()) {
                return await ref.read(connectionNotifierProvider.notifier).toggleConnection();
              }
            },
          AsyncData(value: Connected()) => () async {
              if (requiresReconnect == true && await showExperimentalNotice()) {
                return await ref.read(connectionNotifierProvider.notifier).reconnect(await ref.read(activeProfileProvider.future));
              }
              return await ref.read(connectionNotifierProvider.notifier).toggleConnection();
            },
          _ => () {},
        };

        final enabled = switch (connectionStatus) {
          AsyncData(value: Connected()) || AsyncData(value: Disconnected()) || AsyncError() => true,
          _ => false,
        };

        final label = switch (connectionStatus) {
          AsyncData(value: Connected()) when requiresReconnect == true => t.connection.reconnect,
          AsyncData(value: Connected()) when delay <= 0 || delay >= 65000 => t.connection.connecting,
          AsyncData(value: final status) => status.present(t),
          _ => t.connection.tapToConnect,
        };

        final buttonColor = switch (connectionStatus) {
          AsyncData(value: Connected()) when requiresReconnect == true => Colors.teal,
          AsyncData(value: Connected()) when delay <= 0 || delay >= 65000 => Color.fromARGB(255, 185, 176, 103),
          AsyncData(value: Connected()) => buttonTheme.connectedColor!,
          AsyncData(value: _) => buttonTheme.idleColor!,
          _ => Colors.red,
        };

        return AnimatedBuilder(
          animation: Listenable.merge([_colorController, _glowController]),
          builder: (context, child) {
            final currentColor = _colorAnimation.value ?? Colors.cyan;
            final glowIntensity = _glowAnimation.value;
            
            // 根据连接状态调整颜色
            final displayColor = enabled ? currentColor : buttonColor;
            
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50),
                boxShadow: enabled ? [
                  BoxShadow(
                    color: displayColor.withOpacity(0.3 * glowIntensity),
                    blurRadius: 20 + (10 * glowIntensity),
                    spreadRadius: 2 + (3 * glowIntensity),
                  ),
                  BoxShadow(
                    color: displayColor.withOpacity(0.1 * glowIntensity),
                    blurRadius: 40 + (20 * glowIntensity),
                    spreadRadius: 5 + (5 * glowIntensity),
                  ),
                ] : [
                  BoxShadow(
                    color: displayColor.withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: enabled ? onTap : null,
                  borderRadius: BorderRadius.circular(50),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50),
                      gradient: LinearGradient(
                        colors: [
                          displayColor.withOpacity(0.8),
                          displayColor.withOpacity(0.6),
                          displayColor.withOpacity(0.4),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: displayColor.withOpacity(0.5),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          FluentIcons.power_24_filled,
                          color: Colors.white,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                color: Colors.black26,
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class HomePage extends HookConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final hasAnyProfile = ref.watch(hasAnyProfileProvider);
    final activeProfile = ref.watch(activeProfileProvider);

    return Scaffold(
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          const GlassBackground(),
          CustomScrollView(
            slivers: [
              NestedAppBar(
                title: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: t.general.appTitle),
                      const TextSpan(text: " "),
                      const WidgetSpan(
                        child: AppVersionLabel(),
                        alignment: PlaceholderAlignment.middle,
                      ),
                    ],
                  ),
                ),
                actions: [
                  IconButton(
                    onPressed: () => const QuickSettingsRoute().push(context),
                    icon: const Icon(FluentIcons.options_24_filled),
                    tooltip: t.config.quickSettings,
                  ),
                ],
              ),
              switch (activeProfile) {
                AsyncData(value: final profile?) => MultiSliver(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: GlassContainer(
                          child: ProfileTile(profile: profile, isMain: true),
                        ),
                      ),
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Center(
                                child: SizedBox(
                                  width: 420,
                                  child: GlassContainer(
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                                    child: const Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        GlowingConnectionButton(),
                                        SizedBox(height: 8),
                                        ActiveProxyDelayIndicator(),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            if (MediaQuery.sizeOf(context).width < 840)
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: GlassContainer(child: const ActiveProxyFooter()),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                AsyncData() => switch (hasAnyProfile) {
                    AsyncData(value: true) => const EmptyActiveProfileHomeBody(),
                    _ => SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: GlassContainer(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  t.home.noSubscriptionMsg,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () {
                                    // 移除套餐页面跳转，改为跳转到官网
                                    final url = Uri.parse('https://www.tianque.cc');
                                    launchUrl(url, mode: LaunchMode.externalApplication);
                                  },
                                  child: Text(t.home.goToPurchasePage),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  },
                AsyncError(:final error) => SliverErrorBodyPlaceholder(t.presentShortError(error)),
                _ => const SliverToBoxAdapter(),
              },
            ],
          ),
        ],
      ),
    );
  }
}

class AppVersionLabel extends HookConsumerWidget {
  const AppVersionLabel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final theme = Theme.of(context);

    final version = ref.watch(appInfoProvider).requireValue.presentVersion;
    if (version.isBlank) return const SizedBox();

    return Semantics(
      label: t.about.version,
      button: false,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(4),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 4,
          vertical: 1,
        ),
        child: Text(
          version,
          textDirection: TextDirection.ltr,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSecondaryContainer,
          ),
        ),
      ),
    );
  }
}
