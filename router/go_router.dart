GoRouter goRouter() {
  FutureOr<String?> redirect(BuildContext context, GoRouterState state) {
   
    // if (state.fullPath == AppRoutes.home.pathSlug) {
    //   return AppRoutes.conversations.fullPath;
    // }
    // if (state.fullPath == AppRoutes.personalChatDetails.pathSlug &&
    //     state.extra == null) {
    //   return AppRoutes.conversations.fullPath;
    // }

    return null;
  }

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.splash.fullPath,
    observers: [AppRouteObserver()],
    extraCodec: const GoRouterExtraCodec(),
    routerNeglect: true,
    redirect: redirect,
     routes: [
      GoRoute(
        path: AppRoutes.splash.path,
        name: AppRoutes.splash.name,
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => _defaultTrnasition(
          context: context,
          child: const SplashScreen(),
          name: AppRoutes.splash.name,
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppScaffoldShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.conversations.path,
                name: AppRoutes.conversations.name,
                pageBuilder: (context, state) {
                  bool isLargeScreen =
                      Breakpoints.mediumLargeAndUp.isActive(context);
                  final isDetail = state.fullPath != null &&
                      state.fullPath != AppRoutes.conversations.fullPath;
                  return _defaultTrnasition(
                    context: context,
                    child: AdaptiveScreeen(
                      body: Consumer(builder: (context, ref, _) {
                        return const ConversationList();
                      }),
                      secondaryBody: isLargeScreen && !isDetail
                          ? const ConversationMeerkat()
                          : null,
                      secondaryAppbar: const CustomAppBar(),
                      enableCollapse: true,
                    ),
                    name: AppRoutes.conversations.name,
                  );
                },
                routes: [
                  GoRoute(
                    path: AppRoutes.personalChatDetails.path,
                    name: AppRoutes.personalChatDetails.name,
                    pageBuilder: (context, state) {
                      final cotact = state.extra as PhoneContact?;
                      return _defaultTrnasition(
                        context: context,
                        child: AdaptiveScreeen(
                          body: const ConversationList(),
                          secondaryBody: ConversationPerson(cotact),
                          secondaryAppbar: const CustomAppBar(),
                          enableCollapse: true,
                        ),
                        name: AppRoutes.personalChatDetails.name,
                      );
                    },
                  ),
                ],
            ),
            ......
            ],),]),
        ]
    )




Page<T> _defaultTrnasition<T>({
  required BuildContext context,
  required Widget child,
  String? name,
  Object? arguments,
  String? restorationId,
  LocalKey? key,
}) {
  final fixedChild = child;

  if (kIsWeb) {
    return NoTransitionPage<T>(
      key: key,
      name: name,
      arguments: arguments,
      child: fixedChild,
      restorationId: restorationId,
    );
  } else if (Platform.isIOS) {
    return CupertinoPage<T>(
      key: key,
      name: name,
      arguments: arguments,
      child: CupertinoPageScaffold(child: fixedChild),
      restorationId: restorationId,
    );
  } else if (Platform.isAndroid) {
    return MaterialPage<T>(
      key: key,
      name: name,
      arguments: arguments,
      child: fixedChild,
      restorationId: restorationId,
    );
  } else {
    return NoTransitionPage<T>(
      key: key,
      name: name,
      arguments: arguments,
      child: fixedChild,
      restorationId: restorationId,
    );
  }
}





class AppRouteObserver extends NavigatorObserver {
  AppRouteObserver();

  static const _verboseDebug = false;

  @override
  Future<void> didPush(
    Route<dynamic> route,
    Route<dynamic>? previousRoute,
  ) async {
    if (_verboseDebug) {
      debugPrint(
        // 'Telemetry Route Observer: Route pushed on branch ${branch.name} '
        '(route: ${route.settings.name} '
        'previousRoute: ${previousRoute?.settings.name})',
      );
    }
  }

  @override
  Future<void> didPop(
    Route<dynamic> route,
    Route<dynamic>? previousRoute,
  ) async {
    if (_verboseDebug) {
      debugPrint(
        // 'Telemetry Route Observer: Route popped on branch ${branch.name} '
        '(route: ${route.settings.name} '
        'previousRoute: ${previousRoute?.settings.name})',
      );
    }
  }
}