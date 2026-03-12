import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/poll_provider.dart';
import '../../models/poll_model.dart';
import '../../core/theme.dart';
import '../../core/localization.dart';
import 'poll_detail_screen.dart';

class PollsScreen extends StatefulWidget {
  const PollsScreen({super.key});

  @override
  State<PollsScreen> createState() => _PollsScreenState();
}

class _PollsScreenState extends State<PollsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PollProvider>().loadPolls();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PollProvider>();
    final s = AppStrings.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.pollsTitle),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: s.pollActive),
            Tab(text: s.pollEnded),
          ],
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.adaptiveTextMuted(context),
          indicatorColor: AppColors.primary,
        ),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(provider.error!),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => provider.loadPolls(),
                        child: Text(s.retryBtn),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => provider.loadPolls(),
                  color: AppColors.primary,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _PollList(
                        polls: provider.activePolls,
                        emptyText: s.pollsEmpty,
                      ),
                      _PollList(
                        polls: provider.endedPolls,
                        emptyText: s.pollsEmpty,
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _PollList extends StatelessWidget {
  final List<PollItem> polls;
  final String emptyText;

  const _PollList({required this.polls, required this.emptyText});

  @override
  Widget build(BuildContext context) {
    if (polls.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.poll_outlined,
                size: 48, color: AppColors.adaptiveTextMuted(context)),
            const SizedBox(height: 12),
            Text(
              emptyText,
              style: TextStyle(
                color: AppColors.adaptiveTextMuted(context),
                fontSize: 15,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: polls.length,
      itemBuilder: (context, index) => _PollCard(poll: polls[index]),
    );
  }
}

class _PollCard extends StatelessWidget {
  final PollItem poll;

  const _PollCard({required this.poll});

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PollDetailScreen(pollId: poll.id),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: AppColors.adaptiveCardDecoration(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status badge & scope
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: poll.isActive
                          ? AppColors.success.withAlpha(25)
                          : AppColors.adaptiveTextMuted(context).withAlpha(25),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      poll.isActive ? s.pollActive : s.pollEnded,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: poll.isActive
                            ? AppColors.success
                            : AppColors.adaptiveTextMuted(context),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (poll.hasVoted)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(20),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_outline,
                              size: 12, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            s.pollVoted,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const Spacer(),
                  Text(
                    s.pollTotalVotes(poll.totalVotes),
                    style: TextStyle(
                      color: AppColors.adaptiveTextMuted(context),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Title
              Text(
                poll.title,
                style: TextStyle(
                  color: AppColors.adaptiveTextPrimary(context),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),

              if (poll.description != null &&
                  poll.description!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  poll.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.adaptiveTextSecondary(context),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],

              // End date
              if (poll.endsAt != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.schedule,
                        size: 14,
                        color: AppColors.adaptiveTextMuted(context)),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(poll.endsAt!),
                      style: TextStyle(
                        color: AppColors.adaptiveTextMuted(context),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final d = DateTime.parse(dateStr);
      return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
    } catch (_) {
      return dateStr;
    }
  }
}
