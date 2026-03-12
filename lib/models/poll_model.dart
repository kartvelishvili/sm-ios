class PollItem {
  final int id;
  final String title;
  final String? description;
  final String? imageUrl;
  final String scope;
  final String? startsAt;
  final String? endsAt;
  final bool isActive;
  final bool isEnded;
  final int totalVotes;
  final int? userVotedOptionId;
  final bool hasVoted;
  final bool showResults;
  final bool showVoters;

  PollItem({
    required this.id,
    required this.title,
    this.description,
    this.imageUrl,
    this.scope = 'all',
    this.startsAt,
    this.endsAt,
    this.isActive = true,
    this.isEnded = false,
    this.totalVotes = 0,
    this.userVotedOptionId,
    this.hasVoted = false,
    this.showResults = false,
    this.showVoters = false,
  });

  factory PollItem.fromJson(Map<String, dynamic> json) {
    return PollItem(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      scope: json['scope'] as String? ?? 'all',
      startsAt: json['starts_at'] as String?,
      endsAt: json['ends_at'] as String?,
      isActive: json['is_active'] == true,
      isEnded: json['is_ended'] == true,
      totalVotes: json['total_votes'] as int? ?? 0,
      userVotedOptionId: json['user_voted_option_id'] as int?,
      hasVoted: json['has_voted'] == true,
      showResults: json['show_results'] == true,
      showVoters: json['show_voters'] == true,
    );
  }
}

class PollDetail {
  final PollItem poll;
  final List<PollOption> options;

  PollDetail({required this.poll, required this.options});

  factory PollDetail.fromJson(Map<String, dynamic> json) {
    return PollDetail(
      poll: PollItem.fromJson(json['poll'] as Map<String, dynamic>? ?? {}),
      options: (json['options'] as List?)
              ?.map((o) => PollOption.fromJson(o as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class PollOption {
  final int id;
  final String optionText;
  final int sortOrder;
  final int? voteCount;
  final double? percentage;
  final List<String>? voters;

  PollOption({
    required this.id,
    required this.optionText,
    this.sortOrder = 0,
    this.voteCount,
    this.percentage,
    this.voters,
  });

  factory PollOption.fromJson(Map<String, dynamic> json) {
    return PollOption(
      id: json['id'] as int? ?? 0,
      optionText: json['option_text'] as String? ?? '',
      sortOrder: json['sort_order'] as int? ?? 0,
      voteCount: json['vote_count'] as int?,
      percentage: (json['percentage'] as num?)?.toDouble(),
      voters: (json['voters'] as List?)?.cast<String>(),
    );
  }
}
