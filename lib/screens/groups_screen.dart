import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/group_provider.dart';
import '../models/group.dart';
import '../models/transaction.dart';
import 'add_group_screen.dart';
import 'group_details_screen.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  Map<int, GroupStats> _groupStats = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadGroupsWithStats();
    });
  }

  Future<void> _loadGroupsWithStats() async {
    await context.read<GroupProvider>().loadGroups();
    await _calculateGroupStats();
  }

  Future<void> _calculateGroupStats() async {
    final groups = context.read<GroupProvider>().groups;
    final Map<int, GroupStats> stats = {};

    for (var group in groups) {
      if (group.id != null) {
        final transactions =
            await context.read<GroupProvider>().getGroupTransactions(group.id!);

        double myBalance = 0.0;

        for (var transaction in transactions) {
           if (transaction.paidBy == 'You') {
             if (transaction.split != null) {
                transaction.split!.forEach((member, amount) {
                    if (member != 'You') {
                        myBalance += amount;
                    }
                });
             }
           } else {
             if (transaction.split != null) {
                if (transaction.split!.containsKey('You')) {
                    var myShare = transaction.split!['You'];
                    if (myShare is num) {
                       myBalance -= myShare.toDouble();
                    }
                }
             }
           }
        }

        stats[group.id!] = GroupStats(
          userBalance: myBalance,
          transactionCount: transactions.length,
          lastActivity: transactions.isNotEmpty ? transactions.first.date : group.createdAt,
        );
      }
    }

    if (mounted) {
      setState(() {
        _groupStats = stats;
      });
    }
  }

  void _navigateToAddGroup() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddGroupScreen()),
    ).then((_) => _loadGroupsWithStats());
  }

  void _navigateToGroupDetails(Group group) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupDetailsScreen(group: group),
      ),
    ).then((_) => _loadGroupsWithStats());
  }

  IconData _getGroupIcon(String type) {
    switch (type) {
      case 'trip': return Icons.flight_takeoff_rounded;
      case 'home': return Icons.home_rounded;
      case 'couple': return Icons.favorite_rounded;
      default: return Icons.groups_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Consumer<GroupProvider>(
        builder: (context, groupProvider, child) {
          final groups = groupProvider.groups;
          final isLoading = groupProvider.isLoading;

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                floating: false,
                backgroundColor: colorScheme.surface,
                elevation: 0,
                scrolledUnderElevation: 1,
                shadowColor: Colors.black.withOpacity(0.05),
                title: Text(
                  AppLocalizations.of(context)!.groups,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.primary,
                    letterSpacing: -0.5,
                  ),
                ),
                actions: [
                  IconButton(
                    icon: Icon(Icons.add_rounded, color: colorScheme.primary),
                    onPressed: _navigateToAddGroup,
                    tooltip: 'Create Group',
                  ),
                ],
              ),
              if (isLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (groups.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                colorScheme.primary.withOpacity(0.1),
                                colorScheme.primary.withOpacity(0.05),
                              ],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.groups_rounded,
                            size: 80,
                            color: colorScheme.primary.withOpacity(0.5),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          AppLocalizations.of(context)!.noGroups,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 48),
                          child: Text(
                            AppLocalizations.of(context)!.createGroupPrompt,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 32),
                        FilledButton.icon(
                          onPressed: _navigateToAddGroup,
                          icon: const Icon(Icons.add_rounded),
                          label: Text(AppLocalizations.of(context)!.createGroup),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 32, vertical: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final group = groups[index];
                        final stats = _groupStats[group.id];
                        return _buildGroupCard(group, index, stats);
                      },
                      childCount: groups.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: Consumer<GroupProvider>(
        builder: (context, provider, _) {
          return provider.groups.isNotEmpty
              ? FloatingActionButton.extended(
                  heroTag: 'groups_screen_fab',
                  onPressed: _navigateToAddGroup,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('New Group'),
                  elevation: 2,
                )
                  .animate()
                  .fadeIn(duration: 300.ms, delay: 200.ms)
                  .slideY(begin: 0.3, duration: 400.ms, curve: Curves.easeOutCubic)
              : const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildGroupCard(Group group, int index, GroupStats? stats) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final gradientColors = _getGradientColors(index, colorScheme);
    
    final balance = stats?.userBalance ?? 0.0;
    final isOwed = balance > 0.01;
    final isDebt = balance < -0.01;
    final isSettled = !isOwed && !isDebt;

    return InkWell(
      onTap: () => _navigateToGroupDetails(group),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark 
                ? [
                    const Color(0xFF1E1E1E),
                    const Color(0xFF252525),
                  ]
                : [
                    Colors.white,
                    colorScheme.surfaceContainer.withOpacity(0.3),
                  ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : colorScheme.outlineVariant.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: gradientColors[0].withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: -4,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.03),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // Enhanced Avatar with Icon
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: gradientColors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: gradientColors[0].withOpacity(0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Text(
                            group.name.isNotEmpty ? group.name[0].toUpperCase() : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 2,
                          right: 2,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: Icon(
                              _getGroupIcon(group.type),
                              size: 14,
                              color: gradientColors[1],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                group.name,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 18,
                                      letterSpacing: -0.3,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (stats?.transactionCount != null && stats!.transactionCount > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: colorScheme.primaryContainer.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${stats.transactionCount}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.people_outline_rounded,
                              size: 14,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${group.members.length} members',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              Icons.access_time_rounded,
                              size: 14,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                stats != null 
                                    ? DateFormat('MMM d').format(stats.lastActivity)
                                    : DateFormat('MMM d').format(group.createdAt),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Divider(
              height: 1, 
              thickness: 1,
              color: colorScheme.outlineVariant.withOpacity(0.2),
              indent: 20,
              endIndent: 20,
            ),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: BoxDecoration(
                color: isSettled 
                    ? colorScheme.surfaceContainer.withOpacity(0.4)
                    : isOwed 
                        ? const Color(0xFF10B981).withOpacity(0.08)
                        : const Color(0xFFEF4444).withOpacity(0.08),
                borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   if (isSettled)
                      Row(
                          children: [
                              Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                      color: colorScheme.surfaceContainer,
                                      shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.check_circle_rounded, 
                                    size: 18, 
                                    color: colorScheme.primary,
                                  ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                  "All settled up",
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: colorScheme.onSurface,
                                  ),
                              ),
                          ],
                      )
                   else if (isOwed)
                      Expanded(
                        child: Row(
                            children: [
                                Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            const Color(0xFF10B981).withOpacity(0.2),
                                            const Color(0xFF10B981).withOpacity(0.1),
                                          ],
                                        ),
                                        shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.trending_down_rounded, 
                                      size: 18, 
                                      color: Color(0xFF10B981),
                                    ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                          const Text(
                                              "You get back",
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 11,
                                                  color: Color(0xFF10B981),
                                                  letterSpacing: 0.3,
                                              ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                              "₹${balance.abs().toStringAsFixed(2)}",
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 17,
                                                  color: Color(0xFF10B981),
                                                  letterSpacing: -0.5,
                                              ),
                                          ),
                                      ],
                                  ),
                                ),
                            ],
                        ),
                      )
                   else
                      Expanded(
                        child: Row(
                            children: [
                                 Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            const Color(0xFFEF4444).withOpacity(0.2),
                                            const Color(0xFFEF4444).withOpacity(0.1),
                                          ],
                                        ),
                                        shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.trending_up_rounded, 
                                      size: 18, 
                                      color: Color(0xFFEF4444),
                                    ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                          const Text(
                                              "You owe",
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 11,
                                                  color: Color(0xFFEF4444),
                                                  letterSpacing: 0.3,
                                              ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                              "₹${balance.abs().toStringAsFixed(2)}",
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 17,
                                                  color: Color(0xFFEF4444),
                                                  letterSpacing: -0.5,
                                              ),
                                          ),
                                      ],
                                  ),
                                ),
                            ],
                        ),
                      ),
                    
                    Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainer.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: colorScheme.onSurfaceVariant,
                            size: 14,
                        ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    )
        .animate(delay: (80 * index).ms)
        .fadeIn(duration: 500.ms, curve: Curves.easeOut)
        .slideY(begin: 0.15, duration: 500.ms, curve: Curves.easeOutCubic)
        .scale(begin: const Offset(0.95, 0.95), duration: 500.ms, curve: Curves.easeOutCubic);
  }

  List<Color> _getGradientColors(int index, ColorScheme colorScheme) {
    final gradients = [
      [const Color(0xFF667eea), const Color(0xFF764ba2)], // Purple
      [const Color(0xFFf093fb), const Color(0xFFF5576c)], // Pink
      [const Color(0xFF4facfe), const Color(0xFF00f2fe)], // Blue
      [const Color(0xFF43e97b), const Color(0xFF38f9d7)], // Green
      [const Color(0xFFfa709a), const Color(0xFFfee140)], // Orange
      [const Color(0xFFa8edea), const Color(0xFFfed6e3)], // Mint
    ];
    
    return gradients[index % gradients.length];
  }
}

class GroupStats {
  final double userBalance;
  final int transactionCount;
  final DateTime lastActivity;

  GroupStats({
    required this.userBalance,
    required this.transactionCount,
    required this.lastActivity,
  });
}
