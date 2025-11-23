import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Modern icon system following Apple HIG principles
/// Provides consistent, beautiful icons throughout the app
class AppIcons {
  AppIcons._();

  // Dashboard & Navigation
  static IconData dashboard = PhosphorIcons.house(PhosphorIconsStyle.regular);
  static IconData dashboardFilled = PhosphorIcons.house(PhosphorIconsStyle.fill);
  
  // Fitness & Workouts
  static IconData workout = PhosphorIcons.barbell(PhosphorIconsStyle.regular);
  static IconData workoutFilled = PhosphorIcons.barbell(PhosphorIconsStyle.fill);
  static IconData exercise = PhosphorIcons.barbell(PhosphorIconsStyle.regular);
  static IconData running = PhosphorIcons.personSimpleRun(PhosphorIconsStyle.regular);
  
  // Nutrition & Meals
  static IconData meal = PhosphorIcons.forkKnife(PhosphorIconsStyle.regular);
  static IconData mealFilled = PhosphorIcons.forkKnife(PhosphorIconsStyle.fill);
  static IconData ingredients = PhosphorIcons.forkKnife(PhosphorIconsStyle.regular);
  static IconData recipe = PhosphorIcons.bookOpen(PhosphorIconsStyle.regular);
  static IconData cooking = PhosphorIcons.cookingPot(PhosphorIconsStyle.regular);
  
  // Water & Hydration
  static IconData water = PhosphorIcons.drop(PhosphorIconsStyle.regular);
  static IconData waterFilled = PhosphorIcons.drop(PhosphorIconsStyle.fill);
  static IconData waterDrop = PhosphorIcons.drop(PhosphorIconsStyle.regular);
  
  // Progress & Analytics
  static IconData progress = PhosphorIcons.chartLine(PhosphorIconsStyle.regular);
  static IconData progressFilled = PhosphorIcons.chartLine(PhosphorIconsStyle.fill);
  static IconData analytics = PhosphorIcons.chartBar(PhosphorIconsStyle.regular);
  static IconData trends = PhosphorIcons.trendUp(PhosphorIconsStyle.regular);
  static IconData stats = PhosphorIcons.chartPie(PhosphorIconsStyle.regular);
  
  // People & Clients
  static IconData client = PhosphorIcons.user(PhosphorIconsStyle.regular);
  static IconData clientFilled = PhosphorIcons.user(PhosphorIconsStyle.fill);
  static IconData clients = PhosphorIcons.users(PhosphorIconsStyle.regular);
  static IconData clientsFilled = PhosphorIcons.users(PhosphorIconsStyle.fill);
  static IconData addClient = PhosphorIcons.userPlus(PhosphorIconsStyle.regular);
  static IconData profile = PhosphorIcons.userCircle(PhosphorIconsStyle.regular);
  static IconData profileFilled = PhosphorIcons.userCircle(PhosphorIconsStyle.fill);
  
  // Communication
  static IconData message = PhosphorIcons.chatCircle(PhosphorIconsStyle.regular);
  static IconData messageFilled = PhosphorIcons.chatCircle(PhosphorIconsStyle.fill);
  static IconData notification = PhosphorIcons.bell(PhosphorIconsStyle.regular);
  static IconData notificationFilled = PhosphorIcons.bell(PhosphorIconsStyle.fill);
  
  // Actions
  static IconData add = PhosphorIcons.plus(PhosphorIconsStyle.regular);
  static IconData addCircle = PhosphorIcons.plusCircle(PhosphorIconsStyle.regular);
  static IconData edit = PhosphorIcons.pencil(PhosphorIconsStyle.regular);
  static IconData delete = PhosphorIcons.trash(PhosphorIconsStyle.regular);
  static IconData save = PhosphorIcons.floppyDisk(PhosphorIconsStyle.regular);
  static IconData cancel = PhosphorIcons.x(PhosphorIconsStyle.regular);
  static IconData check = PhosphorIcons.check(PhosphorIconsStyle.regular);
  static IconData checkCircle = PhosphorIcons.checkCircle(PhosphorIconsStyle.regular);
  static IconData search = PhosphorIcons.magnifyingGlass(PhosphorIconsStyle.regular);
  static IconData filter = PhosphorIcons.funnel(PhosphorIconsStyle.regular);
  static IconData settings = PhosphorIcons.gear(PhosphorIconsStyle.regular);
  static IconData settingsFilled = PhosphorIcons.gear(PhosphorIconsStyle.fill);
  
  // Navigation
  static IconData arrowRight = PhosphorIcons.arrowRight(PhosphorIconsStyle.regular);
  static IconData arrowLeft = PhosphorIcons.arrowLeft(PhosphorIconsStyle.regular);
  static IconData chevronRight = PhosphorIcons.caretRight(PhosphorIconsStyle.regular);
  static IconData chevronLeft = PhosphorIcons.caretLeft(PhosphorIconsStyle.regular);
  static IconData close = PhosphorIcons.x(PhosphorIconsStyle.regular);
  
  // Calendar & Time
  static IconData calendar = PhosphorIcons.calendar(PhosphorIconsStyle.regular);
  static IconData calendarFilled = PhosphorIcons.calendar(PhosphorIconsStyle.fill);
  static IconData clock = PhosphorIcons.clock(PhosphorIconsStyle.regular);
  static IconData history = PhosphorIcons.clockCounterClockwise(PhosphorIconsStyle.regular);
  
  // Goals & Targets
  static IconData goal = PhosphorIcons.target(PhosphorIconsStyle.regular);
  static IconData goalFilled = PhosphorIcons.target(PhosphorIconsStyle.fill);
  static IconData flag = PhosphorIcons.flag(PhosphorIconsStyle.regular);
  
  // Financial
  static IconData invoice = PhosphorIcons.receipt(PhosphorIconsStyle.regular);
  static IconData payment = PhosphorIcons.creditCard(PhosphorIconsStyle.regular);
  
  // Media
  static IconData video = PhosphorIcons.play(PhosphorIconsStyle.regular);
  static IconData image = PhosphorIcons.image(PhosphorIconsStyle.regular);
  static IconData camera = PhosphorIcons.camera(PhosphorIconsStyle.regular);
  
  // Status & Feedback
  static IconData success = PhosphorIcons.checkCircle(PhosphorIconsStyle.fill);
  static IconData error = PhosphorIcons.warning(PhosphorIconsStyle.fill);
  static IconData info = PhosphorIcons.info(PhosphorIconsStyle.fill);
  static IconData warning = PhosphorIcons.warningCircle(PhosphorIconsStyle.fill);
  
  // Other
  static IconData help = PhosphorIcons.question(PhosphorIconsStyle.regular);
  static IconData logout = PhosphorIcons.signOut(PhosphorIconsStyle.regular);
  static IconData darkMode = PhosphorIcons.moon(PhosphorIconsStyle.regular);
  static IconData lightMode = PhosphorIcons.sun(PhosphorIconsStyle.regular);
}

/// Icon widget with consistent styling
class AppIcon extends StatelessWidget {
  final IconData icon;
  final double? size;
  final Color? color;
  final PhosphorIconsStyle style;

  const AppIcon({
    super.key,
    required this.icon,
    this.size,
    this.color,
    this.style = PhosphorIconsStyle.regular,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PhosphorIcon(
      icon,
      size: size ?? 24,
      color: color ?? theme.iconTheme.color,
    );
  }
}

