import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';

const double _bodyRatio = 0.35;
const double _bodyRatioMediumAndBelow = 0.4;

const _collapseButtonVisibleRoutes = [
  AppRoutes.personalChatDetails,
  AppRoutes.conversations,
  AppRoutes.actions,
  AppRoutes.groupChatDetails,
  AppRoutes.conversationsMeerkat,
  AppRoutes.groupInfo,
  AppRoutes.contactprofile,
  AppRoutes.newConversation,
  AppRoutes.newGroup,
  AppRoutes.addContact,
  AppRoutes.addNewAction,
  AppRoutes.actionDetails,
  AppRoutes.editAction,
];

class CustomSidebar extends ConsumerWidget {
  const CustomSidebar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int? selectedIndex;
  final void Function(int) onDestinationSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.only(top: 10),
      width: Constants.navigationRailWidth,
      color: const Color.fromRGBO(0, 53, 71, 1),
      child: Column(
        children: [
          ...AppDestination.values.map((e) {
            final index = AppDestination.values.indexOf(e);
            final isSelected = selectedIndex == index;
            return InkWell(
              onTap: () => onDestinationSelected(index),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _SidebarIcon(
                      iconAsset: e.icon,
                      name: e.name,
                      isSelected: isSelected,
                      onTap: () => onDestinationSelected(index),
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}

class _SidebarIcon extends StatefulWidget {
  const _SidebarIcon({
    required this.iconAsset,
    required this.name,
    required this.isSelected,
    required this.onTap,
  });

  final String iconAsset;
  final String name;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_SidebarIcon> createState() => _SidebarIconState();
}

class _SidebarIconState extends State<_SidebarIcon> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Tooltip(
        height: 45,
        enableTapToDismiss: false,
        richMessage: TextSpan(
          children: [
            WidgetSpan(
              child: InkWell(
                onTap: widget.onTap,
                child: Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: SvgPicture.asset(
                    widget.iconAsset,
                    width: 18,
                    height: 18,
                    colorFilter: ColorFilter.mode(
                      widget.isSelected
                          ? Colors.black
                          : const Color.fromRGBO(192, 232, 255, 1),
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
            ),
            TextSpan(
              text: widget.name.toUpperCase(),
              recognizer: TapGestureRecognizer()..onTap = widget.onTap,
              style: TextStyle(
                color: widget.isSelected
                    ? Colors.black
                    : const Color.fromRGBO(192, 232, 255, 1),
                fontSize: 14,
              ),
            ),
          ],
        ),
        decoration: BoxDecoration(
          color: widget.isSelected
              ? Theme.of(context).colorScheme.tertiary.getTonalPalette(80)
              : const Color.fromARGB(255, 7, 114, 149),
          borderRadius: BorderRadius.circular(8),
        ),
        preferBelow: false,
        verticalOffset: -22,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Container(
          width: 45,
          height: 45,
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: const Color.fromRGBO(0, 53, 71, 1),
            borderRadius: BorderRadius.circular(5),
            border: Border.all(
              color: widget.isSelected
                  ? Theme.of(context).colorScheme.tertiary.getTonalPalette(80)
                  : Theme.of(context).colorScheme.primary.getTonalPalette(30),
            ),
          ),
          child: SvgPicture.asset(
            widget.iconAsset,
            colorFilter: ColorFilter.mode(
              widget.isSelected
                  ? Theme.of(context).colorScheme.tertiary.getTonalPalette(80)
                  : const Color.fromRGBO(192, 232, 255, 1),
              BlendMode.srcIn,
            ),
          ),
        ),
      ),
    );
  }
}

class AppScaffoldShell extends ConsumerWidget {
  const AppScaffoldShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(authenticatedUserProvider, (previous, next) {
      if (next == null) {}
    });
    ref.watch(socketRepositoryProvider).checkIsConnected();

    final currentRoute = GoRouterState.of(context).fullPath;

    return Scaffold(
      body: Consumer(
        builder: (context, ref, _) {
          final isCollapsed = ref.watch(isPrimaryCollapsedProvider);
          final isMediumAndUp = Breakpoints.mediumAndUp.isActive(context);
          final useMediumRatio = !Breakpoints.mediumLarge.isActive(context);

          final effectiveBodyRatio = isCollapsed
              ? 0.0
              : (useMediumRatio ? _bodyRatioMediumAndBelow : _bodyRatio);
          final screenSize = MediaQuery.of(context).size;
          final themeColors = context.themeColors;

          final selectedIndex = isHomeChildRoute(currentRoute)
              ? navigationShell.currentIndex
              : null;

          final leftPosition = isCollapsed
              ? Constants.navigationRailWidth - 15
              : (screenSize.width * effectiveBodyRatio) + 31;

          final homeRoute = isHomeMainRoute(currentRoute);
          return Stack(
            children: [
              AdaptiveLayout(
                primaryNavigation: SlotLayout(
                  config: {
                    Breakpoints.mediumAndUp: SlotLayout.from(
                      key: const Key('primary-nav-medium'),
                      builder: (context) => GestureDetector(
                        onTap: () {
                          EventListener.postEvent(
                            event: MeerkatEvent.navRailOutsideClick,
                          );
                        },
                        child: CustomSidebar(
                          selectedIndex: selectedIndex,
                          onDestinationSelected: (index) =>
                              _updateNavigationShell(index, context, ref),
                        ),
                      ),
                    ),
                  },
                ),
                bottomNavigation: homeRoute
                    ? SlotLayout(
                        config: {
                          Breakpoints.small: SlotLayout.from(
                            key: const Key('bottom-nav-small'),
                            builder: (context) {
                              return BottomNavigationBar(
                                type: BottomNavigationBarType.fixed,
                                items: AppDestination.values.map((e) {
                                  final index =
                                      AppDestination.values.indexOf(e);
                                  return BottomNavigationBarItem(
                                    icon: Column(
                                      children: [
                                        const SizedBox(height: 15),
                                        SvgPicture.asset(e.icon),
                                      ],
                                    ),
                                    activeIcon: Column(
                                      children: [
                                        const SizedBox(height: 15),
                                        SvgPicture.asset(
                                          e.icon,
                                          color: selectedIndex == index
                                              ? themeColors.tertiary
                                                  .getTonalPalette(80)
                                              : null,
                                        ),
                                      ],
                                    ),
                                    label: e.name[0].toUpperCase() +
                                        e.name.substring(1),
                                  );
                                }).toList(),
                                currentIndex: selectedIndex ?? 0,
                                unselectedItemColor:
                                    themeColors.neutral.getTonalPalette(90),
                                selectedItemColor: selectedIndex == null
                                    ? themeColors.neutral.getTonalPalette(90)
                                    : themeColors.tertiary.getTonalPalette(80),
                                backgroundColor:
                                    themeColors.primary.getTonalPalette(20),
                                onTap: (index) =>
                                    _updateNavigationShell(index, context, ref),
                              );
                            },
                          ),
                        },
                      )
                    : null,
                body: SlotLayout(
                  config: <Breakpoint, SlotLayoutConfig>{
                    Breakpoints.smallAndUp: SlotLayout.from(
                      key: const Key('body-small-and-up'),
                      builder: (_) =>
                          SafeArea(bottom: !homeRoute, child: navigationShell),
                    ),
                  },
                ),
              ),
              if (Breakpoints.mediumAndUp.isActive(context) &&
                  _collapseButtonVisibleRoutes
                      .any((r) => currentRoute!.startsWith(r.fullPath)))
                Positioned(
                  top: screenSize.height * 0.01,
                  left: isCollapsed
                      ? Constants.navigationRailWidth - 15
                      : leftPosition,
                  child: GestureDetector(
                    onTap: () => ref
                        .read(isPrimaryCollapsedProvider.notifier)
                        .state = !isCollapsed,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCollapsed
                            ? const Color.fromRGBO(0, 53, 71, 1)
                            : const Color.fromRGBO(225, 243, 255, 1),
                        border: isCollapsed
                            ? null
                            : Border.all(
                                color: const Color.fromRGBO(223, 227, 231, 1),
                              ),
                        boxShadow: isCollapsed
                            ? null
                            : const [
                                BoxShadow(
                                  color: Color.fromRGBO(0, 0, 0, 0.25),
                                  offset: Offset(3, 0),
                                  blurRadius: 3,
                                ),
                              ],
                      ),
                      child: Center(
                        child: SvgPicture.asset(
                          isCollapsed ? Assets.menuOpenWhite : Assets.menuOpen,
                          width: 12.47,
                          height: 9.06,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  bool isHomeChildRoute(String? currentRoute) =>
      currentRoute != null &&
      AppDestination.values.any(
          (element) => element.route.pathSlug == getFirstSegment(currentRoute));

  bool isHomeMainRoute(String? currentRoute) =>
      currentRoute != null &&
      (AppDestination.values
              .any((element) => element.route.fullPath == currentRoute) ||
          AppRoutes.settings.fullPath == currentRoute);

  void _updateNavigationShell(
    int selectedIndex,
    BuildContext context,
    WidgetRef ref,
  ) {
    final hasChanged = selectedIndex != navigationShell.currentIndex;

    navigationShell.goBranch(selectedIndex, initialLocation: hasChanged);

    ref.read(isDetailsPageOpenProvider.notifier).state = false;
    ref.read(currentlyOpenConversationIdProvider.notifier).state = 1;
    ref.read(currentlyOpenActionIdProvider.notifier).state = null;
  }

  String getFirstSegment(String path) {
    final newpath = path.replaceAll(RegExp(r'^/|/\$'), '');
    final segments = newpath.split('/');
    return segments.isNotEmpty ? segments[0] : path;
  }
}
