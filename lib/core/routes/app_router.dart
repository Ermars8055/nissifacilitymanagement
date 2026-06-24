import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/app_scaffold.dart';
import '../session/session_manager.dart';
import '../widgets/placeholder_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/forgot_password_screen.dart';
import '../../features/auth/otp_screen.dart';
import '../../features/auth/building_selection_screen.dart';
import '../../features/admin/admin_dashboard_screen.dart';
import '../../features/dashboard/executive_dashboard.dart';
import '../../features/clients/client_list_screen.dart';
import '../../features/clients/client_details_screen.dart';
import '../../features/clients/client_form_screen.dart';
import '../../features/buildings/building_list_screen.dart';
import '../../features/buildings/building_details_screen.dart';
import '../../features/floors/floor_management_screen.dart';
import '../../features/rooms/room_management_screen.dart';
import '../../features/assets/asset_list_screen.dart';
import '../../features/assets/asset_details_screen.dart';
import '../../features/rooms/room_assets_screen.dart';
import '../../features/tasks/task_list_screen.dart';
import '../../features/tasks/task_details_screen.dart';
import '../../features/tasks/add_task_screen.dart';
import '../../features/tasks/checklist_execution_screen.dart';
import '../../features/complaints/complaint_list_screen.dart';
import '../../features/complaints/complaint_details_screen.dart';
import '../../features/checklists/checklist_library_screen.dart';
import '../../features/scheduler/scheduler_dashboard_screen.dart';
import '../../features/qr/qr_dashboard_screen.dart';
import '../../features/work_orders/work_order_list_screen.dart';
import '../../features/maintenance/pm_dashboard_screen.dart';
import '../../features/housekeeping/housekeeping_dashboard_screen.dart';
import '../../features/reports/reports_dashboard_screen.dart';
import '../../features/users/user_list_screen.dart';
import '../../features/notifications/notification_center_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/mapping/hierarchy_builder_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorDashboardKey = GlobalKey<NavigatorState>(debugLabel: 'shellDashboard');
final GlobalKey<NavigatorState> _shellNavigatorBuildingsKey = GlobalKey<NavigatorState>(debugLabel: 'shellBuildings');
final GlobalKey<NavigatorState> _shellNavigatorAssetsKey = GlobalKey<NavigatorState>(debugLabel: 'shellAssets');
final GlobalKey<NavigatorState> _shellNavigatorTasksKey = GlobalKey<NavigatorState>(debugLabel: 'shellTasks');
final GlobalKey<NavigatorState> _shellNavigatorComplaintsKey = GlobalKey<NavigatorState>(debugLabel: 'shellComplaints');

class AppRouter {
  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    redirect: (BuildContext context, GoRouterState state) {
      final loggedIn = SessionManager().isLoggedIn;
      final loc = state.matchedLocation;
      final onAuth = loc.startsWith('/login') ||
                     loc.startsWith('/forgot') ||
                     loc.startsWith('/otp');
      if (!loggedIn && !onAuth) return '/login';
      if (loggedIn && onAuth) {
        final role = SessionManager().currentRole;
        if (role == 'Admin' || role == 'Super Admin') return '/dashboard';
        return '/select-building';
      }
      return null;
    },
    routes: <RouteBase>[
      // Auth Routes
      GoRoute(
        path: '/login',
        builder: (BuildContext context, GoRouterState state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (BuildContext context, GoRouterState state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/otp',
        builder: (BuildContext context, GoRouterState state) => const OtpScreen(),
      ),
      GoRoute(
        path: '/select-building',
        builder: (BuildContext context, GoRouterState state) => const BuildingSelectionScreen(),
      ),
      GoRoute(
        path: '/admin-dashboard',
        builder: (BuildContext context, GoRouterState state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/clients',
        builder: (BuildContext context, GoRouterState state) => const ClientListScreen(),
        routes: [
          GoRoute(
            path: 'create',
            builder: (BuildContext context, GoRouterState state) => const ClientFormScreen(),
          ),
          GoRoute(
            path: 'details/:id',
            builder: (BuildContext context, GoRouterState state) => ClientDetailsScreen(clientId: state.pathParameters['id']!),
          ),
        ],
      ),

      // App Shell containing bottom navigation / side navigation
      StatefulShellRoute.indexedStack(
        builder: (BuildContext context, GoRouterState state, StatefulNavigationShell navigationShell) {
          return AppScaffold(navigationShell: navigationShell);
        },
        branches: <StatefulShellBranch>[
          // Branch Dashboard
          StatefulShellBranch(
            navigatorKey: _shellNavigatorDashboardKey,
            routes: <RouteBase>[
              GoRoute(
                path: '/dashboard',
                builder: (BuildContext context, GoRouterState state) => const ExecutiveDashboard(),
              ),
            ],
          ),

          // Branch Buildings/Facilities
          StatefulShellBranch(
            navigatorKey: _shellNavigatorBuildingsKey,
            routes: <RouteBase>[
              GoRoute(
                path: '/buildings',
                builder: (BuildContext context, GoRouterState state) {
                  final role = SessionManager().currentUser?['role'] ?? '';
                  final bId = SessionManager().selectedBuildingId;
                  if (role != 'Admin' && role != 'Super Admin' && bId != null) {
                    return BuildingDetailsScreen(buildingId: bId);
                  }
                  return const BuildingListScreen();
                },
                routes: [
                  GoRoute(
                    path: 'details/:id',
                    builder: (BuildContext context, GoRouterState state) => BuildingDetailsScreen(buildingId: state.pathParameters['id']!),
                    routes: [
                      GoRoute(
                        path: 'floors',
                        builder: (BuildContext context, GoRouterState state) => FloorManagementScreen(buildingId: state.pathParameters['id']!),
                      ),
                      GoRoute(
                        path: 'floors/:floorId/rooms',
                        builder: (BuildContext context, GoRouterState state) => RoomManagementScreen(
                          buildingId: state.pathParameters['id']!,
                          floorId: state.pathParameters['floorId']!,
                        ),
                      ),
                      GoRoute(
                        path: 'floors/:floorId/rooms/:roomId/assets',
                        builder: (BuildContext context, GoRouterState state) => RoomAssetsScreen(
                          buildingId: state.pathParameters['id']!,
                          floorId: state.pathParameters['floorId']!,
                          roomId: state.pathParameters['roomId']!,
                        ),
                      ),
                    ]
                  ),
                ]
              ),
            ],
          ),

          // Branch Assets
          StatefulShellBranch(
            navigatorKey: _shellNavigatorAssetsKey,
            routes: <RouteBase>[
              GoRoute(
                path: '/assets',
                builder: (BuildContext context, GoRouterState state) => const AssetListScreen(),
                routes: [
                  GoRoute(
                    path: 'details/:id',
                    builder: (BuildContext context, GoRouterState state) => AssetDetailsScreen(assetId: state.pathParameters['id']!),
                  ),
                ]
              ),
            ],
          ),

          // Branch Tasks
          StatefulShellBranch(
            navigatorKey: _shellNavigatorTasksKey,
            routes: <RouteBase>[
              GoRoute(
                path: '/tasks',
                builder: (BuildContext context, GoRouterState state) => const TaskListScreen(),
                routes: [
                  GoRoute(
                    path: 'add',
                    builder: (BuildContext context, GoRouterState state) => const AddTaskScreen(),
                  ),
                  GoRoute(
                    path: 'details/:id',
                    builder: (BuildContext context, GoRouterState state) => TaskDetailsScreen(taskId: state.pathParameters['id']!),
                    routes: [
                      GoRoute(
                        path: 'execute',
                        builder: (BuildContext context, GoRouterState state) => ChecklistExecutionScreen(taskId: state.pathParameters['id']!),
                      ),
                    ]
                  ),
                ]
              ),
            ],
          ),

          // Branch Complaints
          StatefulShellBranch(
            navigatorKey: _shellNavigatorComplaintsKey,
            routes: <RouteBase>[
              GoRoute(
                path: '/complaints',
                builder: (BuildContext context, GoRouterState state) => const ComplaintListScreen(),
                routes: [
                  GoRoute(
                    path: 'details/:id',
                    builder: (BuildContext context, GoRouterState state) => ComplaintDetailsScreen(complaintId: state.pathParameters['id']!),
                  ),
                ]
              ),
            ],
          ),
        ],
      ),
      
      // Top level routes for remaining modules
      GoRoute(path: '/checklists', builder: (context, state) => const ChecklistLibraryScreen()),
      GoRoute(path: '/scheduler', builder: (context, state) => const SchedulerDashboardScreen()),
      GoRoute(path: '/qr', builder: (context, state) => const QrDashboardScreen()),
      GoRoute(path: '/work-orders', builder: (context, state) => const WorkOrderListScreen()),
      GoRoute(path: '/pm', builder: (context, state) => const PmDashboardScreen()),
      GoRoute(path: '/housekeeping', builder: (context, state) => const HousekeepingDashboardScreen()),
      GoRoute(path: '/reports', builder: (context, state) => const ReportsDashboardScreen()),
      GoRoute(path: '/users', builder: (context, state) => const UserListScreen()),
      GoRoute(path: '/notifications', builder: (context, state) => const NotificationCenterScreen()),
      GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
      GoRoute(path: '/hierarchy-builder', builder: (context, state) => const HierarchyBuilderScreen()),
    ],
  );
}
