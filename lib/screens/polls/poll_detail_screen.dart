import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/poll_provider.dart';
import '../../models/poll_model.dart';
import '../../core/theme.dart';
import '../../core/localization.dart';

class PollDetailScreen extends StatefulWidget {
  final int pollId;

  const PollDetailScreen({super.key, required this.pollId});

  @override
  State<PollDetailScreen> createState() => _PollDetailScreenState();
}

class _PollDetailScreenState extends State<PollDetailScreen> {
  int? _selectedOptionId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PollProvider>().loadPollDetail(widget.pollId);
    });
  }

  @override
  void dispose() {
    context.read<PollProvider>().clearDetail();
    super.dispose();
  }

  Future<void> _castVote() async {
    if (_selectedOptionId == null) return;

    final provider = context.read<PollProvider>();
    final s = AppStrings.of(context);
    final success = await provider.vote(widget.pollId, _selectedOptionId!);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? s.pollVoteSuccess : s.pollVoteFailed),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PollProvider>();
    final detail = provider.currentPoll;
    final s = AppStrings.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(detail?.poll.title ?? s.pollsTitle,
            style: const TextStyle(fontSize: 16)),
      ),
      body: provider.detailLoading && detail == null
          ? const Center(child: CircularProgressIndicator())
          : provider.detailError != null && detail == null
              ? Center(child: Text(provider.detailError!))
              : detail == null
                  ? const SizedBox()
                  : _buildContent(context, detail, s, provider),
    );
  }

  Widget _buildContent(BuildContext context, PollDetail detail,
      AppStrings s, PollProvider provider) {
    final poll = detail.poll;
    final showResults = poll.hasVoted || poll.showResults || poll.isEnded;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Poll image
          if (poll.imageUrl != null && poll.imageUrl!.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.md),
                image: DecorationImage(
                  image: NetworkImage(poll.imageUrl!),
                  fit: BoxFit.cover,
                ),
              ),
            ),

          // Status & votes
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: poll.isActive
                      ? AppColors.success.withAlpha(25)
                      : AppColors.adaptiveTextMuted(context).withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  poll.isActive ? s.pollActive : s.pollEnded,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: poll.isActive
                        ? AppColors.success
                        : AppColors.adaptiveTextMuted(context),
                  ),
                ),
              ),
              const Spacer(),
              Text(
                s.pollTotalVotes(poll.totalVotes),
                style: TextStyle(
                  color: AppColors.adaptiveTextMuted(context),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Description
          if (poll.description != null && poll.description!.isNotEmpty) ...[
            Text(
              poll.description!,
              style: TextStyle(
                color: AppColors.adaptiveTextSecondary(context),
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Options
          ...detail.options.map((option) => showResults
              ? _ResultOption(option: option, poll: poll)
              : _VoteOption(
                  option: option,
                  selected: _selectedOptionId == option.id,
                  onTap: poll.isActive && !poll.hasVoted
                      ? () => setState(() => _selectedOptionId = option.id)
                      : null,
                )),

          const SizedBox(height: 20),

          // Vote button
          if (poll.isActive && !poll.hasVoted)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedOptionId != null && !provider.voting
                    ? _castVote
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                child: provider.voting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.black))
                    : Text(s.pollVote,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
            )
          else if (poll.hasVoted)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(15),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.primary.withAlpha(40)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_rounded,
                      size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    s.pollVoted,
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
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

class _VoteOption extends StatelessWidget {
  final PollOption option;
  final bool selected;
  final VoidCallback? onTap;

  const _VoteOption({
    required this.option,
    required this.selected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withAlpha(12)
              : AppColors.adaptiveSurface(context),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : AppColors.adaptiveBorder(context),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: selected
                  ? AppColors.primary
                  : AppColors.adaptiveTextMuted(context),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                option.optionText,
                style: TextStyle(
                  color: AppColors.adaptiveTextPrimary(context),
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultOption extends StatelessWidget {
  final PollOption option;
  final PollItem poll;

  const _ResultOption({required this.option, required this.poll});

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isVoted = poll.userVotedOptionId == option.id;
    final pct = option.percentage ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isVoted
              ? AppColors.primary.withAlpha(80)
              : AppColors.adaptiveBorder(context),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md - 1),
        child: Stack(
          children: [
            // Progress bar background
            Positioned.fill(
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: pct / 100,
                child: Container(
                  color: isVoted
                      ? AppColors.primary.withAlpha(20)
                      : AppColors.adaptiveTextMuted(context).withAlpha(12),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (isVoted)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Icon(Icons.check_circle,
                              size: 16, color: AppColors.primary),
                        ),
                      Expanded(
                        child: Text(
                          option.optionText,
                          style: TextStyle(
                            color: AppColors.adaptiveTextPrimary(context),
                            fontSize: 14,
                            fontWeight:
                                isVoted ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${pct.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: isVoted
                              ? AppColors.primary
                              : AppColors.adaptiveTextSecondary(context),
                        ),
                      ),
                    ],
                  ),
                  if (option.voteCount != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${option.voteCount} ${s.pollVote.toLowerCase()}',
                      style: TextStyle(
                        color: AppColors.adaptiveTextMuted(context),
                        fontSize: 11,
                      ),
                    ),
                  ],
                  // Show voters
                  if (poll.showVoters &&
                      option.voters != null &&
                      option.voters!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: option.voters!
                          .map((v) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.adaptiveSurface(context),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  v,
                                  style: TextStyle(
                                    color: AppColors.adaptiveTextMuted(context),
                                    fontSize: 10,
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
