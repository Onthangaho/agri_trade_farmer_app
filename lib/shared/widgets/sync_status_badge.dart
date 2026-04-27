// lib/shared/widgets/sync_status_badge.dart
/// App bar sync badge reflecting pending background sync state.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../providers/sync_provider.dart';

class SyncStatusBadge extends StatelessWidget {
  const SyncStatusBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SyncProvider>(
      builder: (BuildContext context, SyncProvider syncProvider, Widget? child) {
        final bool hasPending = syncProvider.pendingCount > 0;
        final bool isSuccessful = syncProvider.lastSyncResult != null &&
            syncProvider.lastSyncResult!.synced > 0 &&
            !hasPending;

        final Widget icon = syncProvider.isSyncing
            ? const Icon(Icons.sync, color: Colors.white)
            .animate(onPlay: (AnimationController controller) => controller.repeat(reverse: true))
            .scale(begin: 1, end: 1.12, duration: 900.ms)
            : isSuccessful
                ? const Icon(Icons.cloud_done, color: Colors.white)
                : hasPending
                    ? const Icon(Icons.cloud_queue, color: Colors.white)
                    : const Icon(Icons.cloud_outlined, color: Colors.white70);

        return Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              CircleAvatar(
                radius: 18,
                backgroundColor: syncProvider.isSyncing
                    ? const Color(0xFF16A34A)
                    : hasPending
                        ? const Color(0xFFD97706)
                        : isSuccessful
                            ? const Color(0xFF15803D)
                            : const Color(0xFF6B7280),
                child: icon,
              ),
              if (hasPending)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                    child: Text(
                      '${syncProvider.pendingCount}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}