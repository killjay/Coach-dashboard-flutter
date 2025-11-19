import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/models/user.dart';
import '../../../../../core/models/progress.dart';
import '../../../../../core/models/workout.dart';
import '../../../../../core/providers/repository_providers.dart';
import '../../../../../core/repositories/client_repository.dart';
import '../../../../../core/services/firebase_user_service.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../features/auth/presentation/providers/auth_provider.dart';
import 'tabs/body_composition_tab.dart';
import 'tabs/workout_progress_tab.dart';
import 'tabs/meals_consumed_tab.dart';
import 'tabs/steps_progress_tab.dart';
import 'tabs/water_intake_tab.dart';
import 'tabs/progress_photos_tab.dart';

/// Provider for client detail
final clientDetailProvider =
    FutureProvider.family<User?, String>((ref, clientId) async {
  final userService = FirebaseUserService();
  try {
    return await userService.getUser(clientId);
  } catch (e) {
    return null;
  }
});

class ClientDetailScreen extends ConsumerStatefulWidget {
  final String clientId;

  const ClientDetailScreen({
    super.key,
    required this.clientId,
  });

  @override
  ConsumerState<ClientDetailScreen> createState() =>
      _ClientDetailScreenState();
}

class _ClientDetailScreenState extends ConsumerState<ClientDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clientAsync = ref.watch(
      clientDetailProvider(widget.clientId),
    );

    return Scaffold(
      appBar: AppBar(
        title: clientAsync.when(
          data: (client) => Text(client?.name ?? 'Client'),
          loading: () => const Text('Client'),
          error: (_, __) => const Text('Client'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.flag_rounded),
            tooltip: 'Set Goal',
            onPressed: () {
              context.push('/coach/goals/create?clientId=${widget.clientId}');
            },
          ),
          IconButton(
            icon: const Icon(Icons.message_rounded),
            tooltip: 'Message Client',
            onPressed: () {
              context.push('/messages/${widget.clientId}');
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Body Composition', icon: Icon(Icons.monitor_weight)),
            Tab(text: 'Workouts', icon: Icon(Icons.fitness_center)),
            Tab(text: 'Meals', icon: Icon(Icons.restaurant)),
            Tab(text: 'Steps', icon: Icon(Icons.directions_walk)),
            Tab(text: 'Water', icon: Icon(Icons.water_drop)),
            Tab(text: 'Photos', icon: Icon(Icons.photo_library)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          BodyCompositionTab(clientId: widget.clientId),
          WorkoutProgressTab(clientId: widget.clientId),
          MealsConsumedTab(clientId: widget.clientId),
          StepsProgressTab(clientId: widget.clientId),
          WaterIntakeTab(clientId: widget.clientId),
          ProgressPhotosTab(clientId: widget.clientId),
        ],
      ),
    );
  }
}

