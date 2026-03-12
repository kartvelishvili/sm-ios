import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/door_provider.dart';
import '../../models/door_model.dart';
import '../../core/theme.dart';
import '../../core/localization.dart';

class DoorsScreen extends StatefulWidget {
  const DoorsScreen({super.key});

  @override
  State<DoorsScreen> createState() => _DoorsScreenState();
}

class _DoorsScreenState extends State<DoorsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<DoorProvider>();
      provider.loadDoors().then((_) {
        if (provider.hasElevator) provider.loadPin();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DoorProvider>();
    final s = AppStrings.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(provider.complexName ?? s.doorsAndElevator),
      ),
      body: provider.isLoading && provider.doors.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : provider.error != null && provider.doors.isEmpty
              ? _buildError(provider, s)
              : provider.doors.isEmpty
                  ? _buildEmpty(s)
                  : _buildContent(provider, s),
    );
  }

  Widget _buildError(DoorProvider provider, AppStrings s) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.error.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.wifi_off, size: 48, color: AppColors.error),
            ),
            const SizedBox(height: 24),
            Text(
              provider.error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.adaptiveTextSecondary(context), fontSize: 15),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => provider.loadDoors(),
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(s.retryBtn),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(AppStrings s) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.adaptiveTextMuted(context).withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.door_sliding, size: 48, color: AppColors.adaptiveTextMuted(context)),
          ),
          const SizedBox(height: 16),
          Text(s.doorsNotFound,
              style: TextStyle(color: AppColors.adaptiveTextSecondary(context))),
        ],
      ),
    );
  }

  Widget _buildContent(DoorProvider provider, AppStrings s) {
    final doorItems = provider.doors.where((d) => d.isDoor).toList();
    final elevatorItems = provider.doors.where((d) => d.isElevator).toList();

    return RefreshIndicator(
      onRefresh: () async {
        await provider.loadDoors();
        if (provider.hasElevator) await provider.loadPin();
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // ── PIN Card (if elevators exist) ──
          if (elevatorItems.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: _PinCard(provider: provider, s: s),
              ),
            ),

          // ── Doors Section ──
          if (doorItems.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: _SectionHeader(
                  icon: Icons.door_sliding,
                  label: s.entrances,
                  count: doorItems.length,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _DoorTile(door: doorItems[index]),
                  ),
                  childCount: doorItems.length,
                ),
              ),
            ),
          ],

          // ── Elevators Section ──
          if (elevatorItems.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: _SectionHeader(
                  icon: Icons.elevator,
                  label: s.elevators,
                  count: elevatorItems.length,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _DoorTile(door: elevatorItems[index]),
                  ),
                  childCount: elevatorItems.length,
                ),
              ),
            ),
          ],

          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

// ─── Section Header ───
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;

  const _SectionHeader({
    required this.icon,
    required this.label,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.adaptiveTextMuted(context)),
        const SizedBox(width: 8),
        Text(
          '$label ($count)',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.adaptiveTextMuted(context),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Divider(height: 1, color: AppColors.adaptiveBorder(context))),
      ],
    );
  }
}

// ─── PIN Card ───
class _PinCard extends StatelessWidget {
  final DoorProvider provider;
  final AppStrings s;

  const _PinCard({required this.provider, required this.s});

  @override
  Widget build(BuildContext context) {
    final pin = provider.elevatorPin;
    final isLoading = provider.pinLoading;
    final statusCode = provider.pinStatusCode;

    if (statusCode == 402) return _buildDenied(context);
    if (statusCode == 503) return _buildNotGenerated(context);

    return Container(
      decoration: AppColors.isDark(context)
          ? BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withAlpha(30),
                  AppColors.darkCard,
                  AppColors.primary.withAlpha(15),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary.withAlpha(60), width: 1),
            )
          : BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: AppColors.surface,
              border: Border.all(color: AppColors.primary.withAlpha(60), width: 1),
            ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Title row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(30),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.pin, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.elevatorPin,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        s.pinChangesDaily,
                        style: TextStyle(fontSize: 11, color: AppColors.adaptiveTextMuted(context)),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: isLoading ? null : () => provider.loadPin(),
                  icon: Icon(Icons.refresh, color: AppColors.adaptiveTextMuted(context), size: 20),
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // PIN Display
            if (isLoading && pin == null)
              const SizedBox(
                height: 60,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else if (provider.pinError != null && pin == null)
              Text(
                provider.pinError!,
                style: TextStyle(color: AppColors.error, fontSize: 13),
                textAlign: TextAlign.center,
              )
            else if (pin != null)
              _buildPinDisplay(context, pin),
          ],
        ),
      ),
    );
  }

  Widget _buildPinDisplay(BuildContext context, ElevatorPin pin) {
    return Column(
      children: [
        // PIN digits — tap to copy
        GestureDetector(
          onTap: () {
            Clipboard.setData(ClipboardData(text: pin.pin));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.copy, color: Colors.white, size: 16),
                    SizedBox(width: 8),
                    Text('PIN დაკოპირდა'),
                  ],
                ),
                backgroundColor: AppColors.primary,
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            );
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ...pin.pin.split('').map(
                    (digit) => Container(
                      width: 52,
                      height: 64,
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      decoration: BoxDecoration(
                        color: AppColors.adaptiveBackground(context),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.primary.withAlpha(80),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withAlpha(20),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          digit,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
              const SizedBox(width: 8),
              Icon(Icons.copy, size: 16, color: AppColors.adaptiveTextMuted(context)),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Info row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.adaptiveSurface(context),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.schedule, size: 13, color: AppColors.adaptiveTextMuted(context)),
              const SizedBox(width: 6),
              Text(
                _formatPinTime(pin),
                style: TextStyle(fontSize: 11, color: AppColors.adaptiveTextMuted(context)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatPinTime(ElevatorPin pin) {
    if (pin.nextRotation != null && pin.nextRotation!.isNotEmpty) {
      try {
        final next = DateTime.parse(pin.nextRotation!);
        final diff = next.difference(DateTime.now());
        if (diff.inHours > 0) return '${s.pinNextRotation}: ${diff.inHours} სთ';
        if (diff.inMinutes > 0) return '${s.pinNextRotation}: ${diff.inMinutes} წთ';
      } catch (_) {}
    }
    if (pin.updatedAt.isNotEmpty) {
      try {
        final updated = DateTime.parse(pin.updatedAt);
        final h = updated.hour.toString().padLeft(2, '0');
        final m = updated.minute.toString().padLeft(2, '0');
        return '${s.pinUpdated}: $h:$m';
      } catch (_) {}
    }
    return s.pinChangesDaily;
  }

  Widget _buildDenied(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.error.withAlpha(12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.error.withAlpha(40), width: 1),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.error.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock, color: AppColors.error, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.elevatorPin,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(s.pinAccessDenied,
                    style: TextStyle(fontSize: 12, color: AppColors.error.withAlpha(200))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotGenerated(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.warning.withAlpha(12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.warning.withAlpha(40), width: 1),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.warning.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.hourglass_empty, color: AppColors.warning, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.elevatorPin,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(s.pinNotGenerated,
                    style: TextStyle(fontSize: 12, color: AppColors.warning)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Door/Elevator Tile (redesigned) ───
class _DoorTile extends StatefulWidget {
  final DoorItem door;
  const _DoorTile({required this.door});

  @override
  State<_DoorTile> createState() => _DoorTileState();
}

class _DoorTileState extends State<_DoorTile>
    with SingleTickerProviderStateMixin {
  bool _isOpening = false;
  Timer? _cooldownTimer;
  int _cooldown = 0;
  late AnimationController _successAnim;

  @override
  void initState() {
    super.initState();
    _successAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _successAnim.dispose();
    super.dispose();
  }

  void _startCooldown() {
    _cooldown = 3;
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _cooldown--;
          if (_cooldown <= 0) timer.cancel();
        });
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _openDoor() async {
    if (_isOpening || _cooldown > 0) return;

    setState(() => _isOpening = true);
    final provider = context.read<DoorProvider>();
    final success = await provider.openDoor(widget.door.id);

    if (mounted) {
      setState(() => _isOpening = false);

      if (success) {
        _startCooldown();
        _successAnim.forward(from: 0);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    provider.successMessage ?? AppStrings.of(context).doorOpened,
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error ?? AppStrings.of(context).doorOpenFailed),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
      provider.clearMessages();
    }
  }

  @override
  Widget build(BuildContext context) {
    final door = widget.door;
    final s = AppStrings.of(context);
    final isElevator = door.isElevator;
    final Color accent = door.hasAccess ? AppColors.success : AppColors.error;

    return AnimatedBuilder(
      animation: _successAnim,
      builder: (context, child) {
        final glow = _successAnim.value;
        return Container(
          decoration: BoxDecoration(
            color: AppColors.adaptiveCard(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: glow > 0
                  ? AppColors.success.withAlpha((glow * 150).toInt())
                  : AppColors.adaptiveCard(context).withAlpha(80),
              width: 1,
            ),
            boxShadow: glow > 0
                ? [
                    BoxShadow(
                      color: AppColors.success.withAlpha((glow * 40).toInt()),
                      blurRadius: 12,
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: door.hasAccess && !_isOpening && _cooldown <= 0
                  ? _openDoor
                  : null,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Icon
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: accent.withAlpha(18),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: accent.withAlpha(50), width: 1.5),
                      ),
                      child: Icon(
                        isElevator ? Icons.elevator : Icons.door_sliding,
                        color: accent,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            door.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              _StatusChip(
                                label: door.hasAccess
                                    ? door.accessReason == 'grace_period'
                                        ? s.gracePeriodLabel
                                        : s.accessGranted
                                    : s.accessDenied,
                                color: door.hasAccess
                                    ? door.accessReason == 'grace_period'
                                        ? AppColors.warning
                                        : AppColors.success
                                    : AppColors.error,
                              ),
                              if (door.graceDaysLeft != null &&
                                  door.graceDaysLeft! > 0) ...[
                                const SizedBox(width: 6),
                                _StatusChip(
                                  label: s.graceDaysLeft(door.graceDaysLeft!),
                                  color: AppColors.warning,
                                ),
                              ],
                              if (door.building != null) ...[
                                const SizedBox(width: 6),
                                Text(
                                  door.building!,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.adaptiveTextMuted(context),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Open/Lock button
                    _buildOpenButton(door, accent),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOpenButton(DoorItem door, Color accent) {
    if (!door.hasAccess) {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.error.withAlpha(15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.lock, color: AppColors.error, size: 20),
      );
    }

    if (_isOpening) {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.success.withAlpha(15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.success,
            ),
          ),
        ),
      );
    }

    if (_cooldown > 0) {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.adaptiveSurface(context),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            '${_cooldown}s',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.adaptiveTextMuted(context),
            ),
          ),
        ),
      );
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.success, Color(0xFF059669)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.success.withAlpha(40),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Icon(Icons.lock_open, color: Colors.white, size: 20),
    );
  }
}

// ─── Status Chip ───
class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
