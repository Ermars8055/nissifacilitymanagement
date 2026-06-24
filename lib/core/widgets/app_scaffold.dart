import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/session/session_manager.dart';

class AppScaffold extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const AppScaffold({super.key, required this.navigationShell});

  // Branches: 0=Dashboard, 1=Buildings, 2=Assets, 3=Tasks, 4=Complaints
  static const _branchMap = [0, 3, 4, 1];

  void _onNavTap(int displayIndex, BuildContext context) {
    HapticFeedback.selectionClick();
    final branchIndex = _branchMap[displayIndex];
    navigationShell.goBranch(
      branchIndex,
      initialLocation: branchIndex == navigationShell.currentIndex,
    );
  }

  int get _currentDisplayIndex {
    final idx = _branchMap.indexOf(navigationShell.currentIndex);
    return idx;
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width > 1024;
    final role = SessionManager().currentUser?['role'] ?? '';
    final isAdmin = role == 'Admin' || role == 'Super Admin';

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            _DesktopSidebar(
              currentBranchIndex: navigationShell.currentIndex,
              isAdmin: isAdmin,
              onBranchTap: (i) => navigationShell.goBranch(
                i,
                initialLocation: i == navigationShell.currentIndex,
              ),
              onRoutePush: (r) => context.push(r),
            ),
            const VerticalDivider(thickness: 1, width: 1, color: Color(0xFFE0D9D0)),
            Expanded(child: navigationShell),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F3EC),
      body: navigationShell,
      bottomNavigationBar: _BottomNav(
        currentDisplayIndex: _currentDisplayIndex,
        onTap: (i) => _onNavTap(i, context),
        onQrTap: () {
          HapticFeedback.mediumImpact();
          context.push('/qr');
        },
      ),
    );
  }
}

// ── Nav item data ─────────────────────────────────────────────────────────────

class _NavItemData {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItemData({required this.icon, required this.activeIcon, required this.label});
}

const _navItems = [
  _NavItemData(icon: Icons.home_outlined,           activeIcon: Icons.home_rounded,           label: 'Home'),
  _NavItemData(icon: Icons.assignment_outlined,     activeIcon: Icons.assignment_rounded,     label: 'Tasks'),
  _NavItemData(icon: Icons.report_problem_outlined, activeIcon: Icons.report_problem_rounded, label: 'Issues'),
  _NavItemData(icon: Icons.business_outlined,       activeIcon: Icons.business_rounded,       label: 'Buildings'),
];

// ── Bottom Navigation Bar ─────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final int currentDisplayIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onQrTap;

  const _BottomNav({
    required this.currentDisplayIndex,
    required this.onTap,
    required this.onQrTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A1714).withValues(alpha: 0.07),
            blurRadius: 28,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 80,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Row(
                children: [
                  for (int i = 0; i < 2; i++)
                    Expanded(
                      child: _NavItem(
                        item: _navItems[i],
                        isSelected: currentDisplayIndex == i,
                        onTap: () => onTap(i),
                      ),
                    ),
                  const SizedBox(width: 80),
                  for (int i = 2; i < 4; i++)
                    Expanded(
                      child: _NavItem(
                        item: _navItems[i],
                        isSelected: currentDisplayIndex == i,
                        onTap: () => onTap(i),
                      ),
                    ),
                ],
              ),
              // Center QR button — forest green
              Positioned(
                top: -26,
                child: GestureDetector(
                  onTap: onQrTap,
                  child: Container(
                    width: 66,
                    height: 66,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E3D2F),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1E3D2F).withValues(alpha: 0.38),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                          spreadRadius: -2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.qr_code_scanner_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final _NavItemData item;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({required this.item, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFEBF2ED) : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              isSelected ? item.activeIcon : item.icon,
              color: isSelected ? const Color(0xFF1E3D2F) : const Color(0xFF8C8278),
              size: 26,
            ),
          ),
          const SizedBox(height: 3),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? const Color(0xFF1E3D2F) : const Color(0xFF8C8278),
            ),
            child: Text(item.label),
          ),
        ],
      ),
    );
  }
}

// ── Desktop Sidebar ───────────────────────────────────────────────────────────

class _DesktopSidebar extends StatelessWidget {
  final int currentBranchIndex;
  final bool isAdmin;
  final ValueChanged<int> onBranchTap;
  final ValueChanged<String> onRoutePush;

  const _DesktopSidebar({
    required this.currentBranchIndex,
    required this.isAdmin,
    required this.onBranchTap,
    required this.onRoutePush,
  });

  @override
  Widget build(BuildContext context) {
    final user = SessionManager().currentUser;
    final name = user?['name'] as String? ?? 'Field Worker';
    final role = user?['role'] as String? ?? '';
    final initials = name.trim().split(' ').map((p) => p.isNotEmpty ? p[0] : '').take(2).join().toUpperCase();

    return Container(
      width: 252,
      color: const Color(0xFFF7F3EC),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo area
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3D2F),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(Icons.business_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('FacilityPro', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1A1714))),
                    Text('Enterprise', style: TextStyle(fontSize: 12, color: Color(0xFF8C8278))),
                  ],
                ),
              ],
            ),
          ),

          Container(height: 1, color: const Color(0xFFDDD5C8)),

          // Scrollable nav area
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  _SidebarSection(label: 'MAIN'),
                  _SidebarNavItem(icon: Icons.home_outlined,           activeIcon: Icons.home_rounded,           label: 'Dashboard',  isSelected: currentBranchIndex == 0, onTap: () => onBranchTap(0)),
                  _SidebarNavItem(icon: Icons.assignment_outlined,     activeIcon: Icons.assignment_rounded,     label: 'Tasks',      isSelected: currentBranchIndex == 3, onTap: () => onBranchTap(3)),
                  _SidebarNavItem(icon: Icons.report_problem_outlined, activeIcon: Icons.report_problem_rounded, label: 'Complaints', isSelected: currentBranchIndex == 4, onTap: () => onBranchTap(4)),
                  _SidebarNavItem(icon: Icons.business_outlined,       activeIcon: Icons.business_rounded,       label: 'Buildings',  isSelected: currentBranchIndex == 1, onTap: () => onBranchTap(1)),
                  _SidebarNavItem(icon: Icons.devices_outlined,        activeIcon: Icons.devices_rounded,        label: 'Assets',     isSelected: currentBranchIndex == 2, onTap: () => onBranchTap(2)),
                  const SizedBox(height: 8),
                  Container(height: 1, color: const Color(0xFFDDD5C8)),
                  _SidebarSection(label: 'OPERATIONS'),
                  _SidebarLinkItem(icon: Icons.qr_code_outlined,        label: 'QR Scanner',  onTap: () => onRoutePush('/qr')),
                  _SidebarLinkItem(icon: Icons.calendar_month_outlined,  label: 'Scheduler',   onTap: () => onRoutePush('/scheduler')),
                  _SidebarLinkItem(icon: Icons.build_outlined,           label: 'Work Orders', onTap: () => onRoutePush('/work-orders')),
                  _SidebarLinkItem(icon: Icons.analytics_outlined,       label: 'Reports',     onTap: () => onRoutePush('/reports')),
                  if (isAdmin) ...[
                    const SizedBox(height: 8),
                    Container(height: 1, color: const Color(0xFFDDD5C8)),
                    _SidebarSection(label: 'ADMIN'),
                    _SidebarLinkItem(icon: Icons.people_outline,           label: 'Clients',    onTap: () => onRoutePush('/clients')),
                    _SidebarLinkItem(icon: Icons.manage_accounts_outlined,  label: 'Users',      onTap: () => onRoutePush('/users')),
                    _SidebarLinkItem(icon: Icons.checklist_outlined,        label: 'Checklists', onTap: () => onRoutePush('/checklists')),
                    _SidebarLinkItem(icon: Icons.settings_outlined,         label: 'Settings',   onTap: () => onRoutePush('/settings')),
                  ],
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),

          Container(height: 1, color: const Color(0xFFDDD5C8)),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 21,
                  backgroundColor: const Color(0xFFEBF2ED),
                  child: Text(initials, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E3D2F))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1714)), overflow: TextOverflow.ellipsis),
                      Text(role, style: const TextStyle(fontSize: 12, color: Color(0xFF8C8278))),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout_rounded, size: 20, color: Color(0xFF8C8278)),
                  onPressed: () {
                    SessionManager().clear();
                    context.go('/login');
                  },
                  tooltip: 'Logout',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _SidebarSection extends StatelessWidget {
  final String label;
  const _SidebarSection({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
      child: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFFAA9F94), letterSpacing: 1.3)),
    );
  }
}

class _SidebarNavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarNavItem({required this.icon, required this.activeIcon, required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: Material(
        color: isSelected ? const Color(0xFFEBF2ED) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(
              children: [
                Icon(
                  isSelected ? activeIcon : icon,
                  color: isSelected ? const Color(0xFF1E3D2F) : const Color(0xFF6B6560),
                  size: 21,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? const Color(0xFF1E3D2F) : const Color(0xFF4A4540),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarLinkItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SidebarLinkItem({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFF6B6560), size: 21),
                const SizedBox(width: 12),
                Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF4A4540))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
