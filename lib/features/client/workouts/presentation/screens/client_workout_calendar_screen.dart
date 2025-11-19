import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../../../../core/models/workout.dart';
import '../../../../../core/providers/repository_providers.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../../../shared/widgets/bottom_nav_bar.dart' show bottomNavIconColor;

/// Provider for client workout assignments
final clientWorkoutAssignmentsProvider = FutureProvider<List<WorkoutAssignment>>((ref) async {
  final workoutRepo = ref.watch(workoutRepositoryProvider);
  final user = ref.watch(currentUserProvider);

  if (user == null || user.role != 'client') {
    return [];
  }

  return workoutRepo.getAssignedWorkouts(user.id);
});

class ClientWorkoutCalendarScreen extends ConsumerStatefulWidget {
  const ClientWorkoutCalendarScreen({super.key});

  @override
  ConsumerState<ClientWorkoutCalendarScreen> createState() =>
      _ClientWorkoutCalendarScreenState();
}

class _ClientWorkoutCalendarScreenState
    extends ConsumerState<ClientWorkoutCalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  Widget build(BuildContext context) {
    final assignmentsAsync = ref.watch(clientWorkoutAssignmentsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Create a map of dates to assignments
    final assignmentsMap = <DateTime, List<WorkoutAssignment>>{};
    assignmentsAsync.whenData((assignments) {
      for (final assignment in assignments) {
        final date = DateTime(
          assignment.dueDate.year,
          assignment.dueDate.month,
          assignment.dueDate.day,
        );
        assignmentsMap.putIfAbsent(date, () => []).add(assignment);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Workout Calendar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.today_rounded),
            tooltip: 'Today',
            onPressed: () {
              setState(() {
                _focusedDay = DateTime.now();
                _selectedDay = DateTime.now();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Calendar
          Card(
            margin: const EdgeInsets.all(16),
            child: TableCalendar<WorkoutAssignment>(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              calendarFormat: _calendarFormat,
              startingDayOfWeek: StartingDayOfWeek.monday,
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                todayDecoration: BoxDecoration(
                  color: bottomNavIconColor.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: bottomNavIconColor,
                  shape: BoxShape.circle,
                ),
                markerDecoration: BoxDecoration(
                  color: bottomNavIconColor,
                  shape: BoxShape.circle,
                ),
                defaultTextStyle: TextStyle(
                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
                ),
                weekendTextStyle: TextStyle(
                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
                ),
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: true,
                titleCentered: true,
                formatButtonShowsNext: false,
                formatButtonDecoration: BoxDecoration(
                  color: bottomNavIconColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                formatButtonTextStyle: const TextStyle(color: Colors.white),
                leftChevronIcon: Icon(
                  Icons.chevron_left_rounded,
                  color: isDark
                      ? AppTheme.darkTextPrimary
                      : AppTheme.textPrimary,
                ),
                rightChevronIcon: Icon(
                  Icons.chevron_right_rounded,
                  color: isDark
                      ? AppTheme.darkTextPrimary
                      : AppTheme.textPrimary,
                ),
              ),
              eventLoader: (day) {
                final date = DateTime(day.year, day.month, day.day);
                return assignmentsMap[date] ?? [];
              },
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              onFormatChanged: (format) {
                setState(() {
                  _calendarFormat = format;
                });
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
            ),
          ),
          // Selected day assignments
          Expanded(
            child: assignmentsAsync.when(
              data: (assignments) {
                final selectedAssignments = assignments
                    .where((assignment) =>
                        isSameDay(assignment.dueDate, _selectedDay))
                    .toList();

                if (selectedAssignments.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.fitness_center_outlined,
                          size: 64,
                          color: isDark
                              ? AppTheme.darkTextSecondary
                              : AppTheme.textSecondary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No workouts scheduled',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: isDark
                                    ? AppTheme.darkTextSecondary
                                    : AppTheme.textSecondary,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          DateFormat('EEEE, MMMM d').format(_selectedDay),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: isDark
                                    ? AppTheme.darkTextHint
                                    : AppTheme.textHint,
                              ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: selectedAssignments.length,
                  itemBuilder: (context, index) {
                    final assignment = selectedAssignments[index];
                    return _WorkoutAssignmentCard(
                      assignment: assignment,
                      isDark: isDark,
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('Error: $error'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkoutAssignmentCard extends ConsumerWidget {
  final WorkoutAssignment assignment;
  final bool isDark;

  const _WorkoutAssignmentCard({
    required this.assignment,
    required this.isDark,
  });

  Color _getStatusColor() {
    switch (assignment.status) {
      case 'pending':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      default:
        return AppTheme.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutAsync = ref.watch(
      FutureProvider((ref) async {
        final workoutRepo = ref.watch(workoutRepositoryProvider);
        return workoutRepo.getWorkoutById(assignment.workoutId);
      }),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurfaceColor : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? AppTheme.darkSurfaceVariant
              : Colors.grey.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: workoutAsync.when(
          data: (workout) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      workout.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      assignment.status.toUpperCase(),
                      style: TextStyle(
                        color: _getStatusColor(),
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 16,
                    color: isDark
                        ? AppTheme.darkTextHint
                        : AppTheme.textHint,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${workout.duration} min',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppTheme.darkTextHint
                              : AppTheme.textHint,
                        ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.trending_up_rounded,
                    size: 16,
                    color: isDark
                        ? AppTheme.darkTextHint
                        : AppTheme.textHint,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    workout.difficulty,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppTheme.darkTextHint
                              : AppTheme.textHint,
                        ),
                  ),
                ],
              ),
            ],
          ),
          loading: () => const LinearProgressIndicator(),
          error: (_, __) => const Text('Error loading workout'),
        ),
      ),
    );
  }
}

