import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/router/router.dart';

import 'package:hiddify/features/panel/xboard/utils/logout_dialog.dart';
import 'package:hiddify/features/stats/widget/side_bar_stats_overview.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';


abstract interface class RootScaffold {
  static final stateKey = GlobalKey<ScaffoldState>();

  static bool canShowDrawer(BuildContext context) =>
      Breakpoints.small.isActive(context);
}

class AdaptiveRootScaffold extends HookConsumerWidget {
  const AdaptiveRootScaffold(this.navigator, {super.key});

  final Widget navigator;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);

    final selectedIndex = getCurrentIndex(context);

    final destinations = [
      NavigationDestination(
        icon: const Icon(FluentIcons.power_20_filled),
        label: t.home.pageTitle,
      ),
      NavigationDestination(
        icon: const Icon(FluentIcons.filter_20_filled),
        label: t.proxies.pageTitle,
      ),
      NavigationDestination(
        icon: const Icon(FluentIcons.globe_20_filled),
        label: "官网",
      ),
      // 隐藏套餐按钮
      // NavigationDestination(
      //   icon: const Icon(FluentIcons.money_24_filled),
      //   label: t.purchase.pageTitle,
      // ),
      NavigationDestination(
        icon: const Icon(FluentIcons.person_20_filled), 
        label: t.userInfo.pageTitle, 
      ),
      NavigationDestination(
        icon: const Icon(FluentIcons.box_edit_20_filled),
        label: t.config.pageTitle,
      ),
      NavigationDestination(
        icon: const Icon(FluentIcons.settings_20_filled),
        label: t.settings.pageTitle,
      ),
      NavigationDestination(
        icon: const Icon(FluentIcons.document_text_20_filled),
        label: t.logs.pageTitle,
      ),
      NavigationDestination(
        icon: const Icon(FluentIcons.info_20_filled),
        label: t.about.pageTitle,
      ),
      NavigationDestination(
        icon: const Icon(FluentIcons.sign_out_20_filled),
        label: t.logout.buttonText,
      ),
    ];

    return _CustomAdaptiveScaffold(
      selectedIndex: selectedIndex,
      onSelectedIndexChange: (index) {
        if (index == destinations.length - 1) {
          // 显示登出对话框
          showDialog(
            context: context,
            builder: (context) => const LogoutDialog(), // 使用 LogoutDialog 组件
          );
        } else if (index == 2) {
          // 官网按钮 - 跳转到浏览器
          final url = Uri.parse('https://www.tianque.cc');
          launchUrl(url, mode: LaunchMode.externalApplication);
        } else {
          RootScaffold.stateKey.currentState?.closeDrawer();
          switchTab(index, context);
        }
      },
      destinations: destinations,
      drawerDestinationRange: useMobileRouter ? (4, null) : (0, null),
      bottomDestinationRange: (0, 4),
      useBottomSheet: useMobileRouter,
      sidebarTrailing: const Expanded(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: SideBarStatsOverview(),
        ),
      ),
      body: navigator,
    );
  }
}

class _CustomAdaptiveScaffold extends HookConsumerWidget {
  const _CustomAdaptiveScaffold({
    required this.selectedIndex,
    required this.onSelectedIndexChange,
    required this.destinations,
    required this.drawerDestinationRange,
    required this.bottomDestinationRange,
    this.useBottomSheet = false,
    this.sidebarTrailing,
    required this.body,
  });

  final int selectedIndex;
  final Function(int) onSelectedIndexChange;
  final List<NavigationDestination> destinations;
  final (int, int?) drawerDestinationRange;
  final (int, int?) bottomDestinationRange;
  final bool useBottomSheet;
  final Widget? sidebarTrailing;
  final Widget body;

  List<NavigationDestination> destinationsSlice((int, int?) range) =>
      destinations.sublist(range.$1, range.$2);

  int? selectedWithOffset((int, int?) range) {
    final index = selectedIndex - range.$1;
    return index < 0 || (range.$2 != null && index > (range.$2! - 1))
        ? null
        : index;
  }

  void selectWithOffset(int index, (int, int?) range) =>
      onSelectedIndexChange(index + range.$1);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      key: RootScaffold.stateKey,
      drawer: Breakpoints.small.isActive(context)
          ? Drawer(
              width: (MediaQuery.sizeOf(context).width * 0.88).clamp(1, 304),
              child: NavigationRail(
                extended: true,
                selectedIndex: selectedWithOffset(drawerDestinationRange),
                destinations: destinationsSlice(drawerDestinationRange)
                    .map((dest) => AdaptiveScaffold.toRailDestination(dest))
                    .toList(),
                onDestinationSelected: (index) =>
                    selectWithOffset(index, drawerDestinationRange),
                // 添加彩色字体效果
                backgroundColor: Colors.grey[900],
                selectedIconTheme: const IconThemeData(
                  color: Colors.cyan,
                  size: 24,
                ),
                unselectedIconTheme: const IconThemeData(
                  color: Colors.white70,
                  size: 20,
                ),
                selectedLabelTextStyle: const TextStyle(
                  color: Colors.cyan,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.cyan,
                      blurRadius: 8,
                    ),
                  ],
                ),
                unselectedLabelTextStyle: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            )
          : null,
      body: AdaptiveLayout(
        primaryNavigation: SlotLayout(
          config: <Breakpoint, SlotLayoutConfig>{
            Breakpoints.medium: SlotLayout.from(
              key: const Key('primaryNavigation'),
              builder: (_) => AdaptiveScaffold.standardNavigationRail(
                selectedIndex: selectedIndex,
                destinations: destinations
                    .map((dest) => AdaptiveScaffold.toRailDestination(dest))
                    .toList(),
                onDestinationSelected: onSelectedIndexChange,
                // 添加彩色字体效果
                backgroundColor: Colors.grey[900],
                selectedIconTheme: const IconThemeData(
                  color: Colors.cyan,
                  size: 24,
                ),
                unselectedIconTheme: const IconThemeData(
                  color: Colors.white70,
                  size: 20,
                ),
                selectedLabelTextStyle: const TextStyle(
                  color: Colors.cyan,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.cyan,
                      blurRadius: 8,
                    ),
                  ],
                ),
                unselectedLabelTextStyle: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ),
            Breakpoints.large: SlotLayout.from(
              key: const Key('primaryNavigation1'),
              builder: (_) => AdaptiveScaffold.standardNavigationRail(
                extended: true,
                selectedIndex: selectedIndex,
                destinations: destinations
                    .map((dest) => AdaptiveScaffold.toRailDestination(dest))
                    .toList(),
                onDestinationSelected: onSelectedIndexChange,
                trailing: sidebarTrailing,
                // 添加彩色字体效果
                backgroundColor: Colors.grey[900],
                selectedIconTheme: const IconThemeData(
                  color: Colors.cyan,
                  size: 24,
                ),
                unselectedIconTheme: const IconThemeData(
                  color: Colors.white70,
                  size: 20,
                ),
                selectedLabelTextStyle: const TextStyle(
                  color: Colors.cyan,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.cyan,
                      blurRadius: 8,
                    ),
                  ],
                ),
                unselectedLabelTextStyle: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ),
          },
        ),
        body: SlotLayout(
          config: <Breakpoint, SlotLayoutConfig?>{
            Breakpoints.standard: SlotLayout.from(
              key: const Key('body'),
              inAnimation: AdaptiveScaffold.fadeIn,
              outAnimation: AdaptiveScaffold.fadeOut,
              builder: (context) => body,
            ),
          },
        ),
      ),
      // AdaptiveLayout bottom sheet has accessibility issues
      bottomNavigationBar: useBottomSheet && Breakpoints.small.isActive(context)
          ? NavigationBar(
              selectedIndex: selectedWithOffset(bottomDestinationRange) ?? 0,
              destinations: destinationsSlice(bottomDestinationRange),
              onDestinationSelected: (index) =>
                  selectWithOffset(index, bottomDestinationRange),
            )
          : null,
    );
  }
}
