import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/providers/repository_providers.dart';
import '../../../../../core/services/firebase_auth_service.dart';
import '../../../../../core/services/firebase_user_service.dart';
import '../../../../../core/models/user.dart';
import '../../../../../core/models/client_coach_relationship.dart';
import '../../../../../features/auth/presentation/providers/auth_provider.dart';
import 'client_list_screen.dart';

class AddClientScreen extends ConsumerStatefulWidget {
  const AddClientScreen({super.key});

  @override
  ConsumerState<AddClientScreen> createState() => _AddClientScreenState();
}

class _AddClientScreenState extends ConsumerState<AddClientScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _countryController = TextEditingController();
  bool _isSaving = false;

  // List of countries (simplified - you can use a package like country_picker for a better solution)
  final List<String> _countries = [
    'United States',
    'United Kingdom',
    'Canada',
    'Australia',
    'India',
    'Germany',
    'France',
    'Italy',
    'Spain',
    'Brazil',
    'Mexico',
    'Japan',
    'China',
    'South Korea',
    'Singapore',
    'United Arab Emirates',
    'South Africa',
    'New Zealand',
    'Other',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  String _generateTempPassword() {
    // Generate a random password with letters, numbers, and special characters
    // In production, use a more secure method and send via email
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*';
    final random = DateTime.now().millisecondsSinceEpoch;
    final password = StringBuffer();
    password.write('Temp'); // Start with Temp for easy identification
    for (int i = 0; i < 8; i++) {
      password.write(chars[(random + i) % chars.length]);
    }
    return password.toString();
  }

  Future<void> _saveClient() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Prevent double submission
    if (_isSaving) {
      debugPrint('⚠️ Save already in progress, ignoring duplicate call');
      return;
    }

    setState(() => _isSaving = true);

    try {
      debugPrint('🚀 Starting client creation process...');
      
      final coach = ref.read(currentUserProvider);
      if (coach == null) {
        throw Exception('Coach not found');
      }
      debugPrint('✅ Coach found: ${coach.id}');

      final authService = FirebaseAuthService();
      final userService = FirebaseUserService();
      final clientRepo = ref.read(clientRepositoryProvider);

      // Generate a temporary password
      final tempPassword = _generateTempPassword();
      debugPrint('🔑 Generated temporary password');

      // Create user account
      debugPrint('📝 Creating Firebase Auth user...');
      final newUser = await authService.signUpWithEmail(
        email: _emailController.text.trim(),
        password: tempPassword,
        name: _nameController.text.trim(),
        role: 'client',
      );
      debugPrint('✅ Firebase Auth user created: ${newUser.id}');

      // Update user with additional info (phone, country)
      final updatedUser = newUser.copyWith(
        preferences: {
          'phone': _phoneController.text.trim(),
          'country': _countryController.text.trim(),
        },
      );

      debugPrint('📝 Updating user with phone and country...');
      try {
        await userService.updateUser(updatedUser);
        debugPrint('✅ User updated in Firestore: ${updatedUser.id}');
      } catch (e, stackTrace) {
        debugPrint('❌ Error updating user in Firestore: $e');
        debugPrint('❌ Stack trace: $stackTrace');
        // Don't throw here - the user was created in Auth, we can continue
        // The phone/country can be updated later
      }

      // Create client-coach relationship
      debugPrint('📝 Creating client-coach relationship...');
      try {
        await clientRepo.addClient(
          coachId: coach.id,
          clientId: newUser.id,
        );
        debugPrint('✅ Client-coach relationship created');
      } catch (e, stackTrace) {
        debugPrint('❌ Error creating client-coach relationship: $e');
        debugPrint('❌ Stack trace: $stackTrace');
        throw Exception('Failed to create client relationship: $e');
      }

      if (mounted) {
        debugPrint('✅ Client creation completed successfully');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Client added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        ref.invalidate(clientListProvider);
        context.pop();
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error in _saveClient: $e');
      debugPrint('❌ Error type: ${e.runtimeType}');
      debugPrint('❌ Stack trace: $stackTrace');
      
      if (mounted) {
        String errorMessage = 'Error adding client';
        
        // Provide more specific error messages
        final errorString = e.toString().toLowerCase();
        if (errorString.contains('permission-denied') ||
            errorString.contains('permission denied')) {
          errorMessage = 'Permission denied. Please check your Firestore security rules.';
        } else if (errorString.contains('unavailable') ||
            errorString.contains('network')) {
          errorMessage = 'Network error. Please check your connection and try again.';
        } else if (errorString.contains('email-already-in-use') ||
            errorString.contains('email already exists')) {
          errorMessage = 'This email is already registered. Please use a different email.';
        } else if (errorString.contains('invalid-email')) {
          errorMessage = 'Invalid email address. Please check and try again.';
        } else if (errorString.contains('weak-password')) {
          errorMessage = 'Password is too weak. Please try again.';
        } else if (errorString.contains('timeout')) {
          errorMessage = 'Operation timed out. Please check your connection and try again.';
        } else {
          errorMessage = 'Error adding client: ${e.toString()}';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 8),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Client'),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveClient,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 8),
            Text(
              'Client Information',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name *',
                hintText: 'e.g., John Doe',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter client name';
                }
                if (value.trim().length < 2) {
                  return 'Name must be at least 2 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email Address *',
                hintText: 'e.g., john.doe@example.com',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter email address';
                }
                final emailRegex = RegExp(
                  r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                );
                if (!emailRegex.hasMatch(value.trim())) {
                  return 'Please enter a valid email address';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number *',
                hintText: 'e.g., +1 234 567 8900',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter phone number';
                }
                // Basic phone validation (at least 10 digits)
                final phoneRegex = RegExp(r'^[\d\s\+\-\(\)]{10,}$');
                if (!phoneRegex.hasMatch(value.trim())) {
                  return 'Please enter a valid phone number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _countryController.text.isEmpty ? null : _countryController.text,
              decoration: const InputDecoration(
                labelText: 'Country of Residence *',
                hintText: 'Select country',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.public),
              ),
              items: _countries.map((country) {
                return DropdownMenuItem(
                  value: country,
                  child: Text(country),
                );
              }).toList(),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a country';
                }
                return null;
              },
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _countryController.text = value;
                  });
                }
              },
              menuMaxHeight: 300,
            ),
            const SizedBox(height: 32),
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.blue),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Client Account Creation',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  color: Colors.blue[900],
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'A temporary password will be generated for the client. They will need to reset their password on first login. In production, an invitation email should be sent instead.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.blue[900],
                          ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 100), // Space for FAB
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isSaving ? null : _saveClient,
        icon: _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.person_add),
        label: Text(_isSaving ? 'Adding...' : 'Add Client'),
      ),
    );
  }
}

