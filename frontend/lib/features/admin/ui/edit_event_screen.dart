import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/features/admin/providers/admin_provider.dart';
import 'package:frontend/features/events/models/event.dart';
import 'package:frontend/core/validators.dart';
import 'package:flutter/services.dart';

class EditEventScreen extends StatefulWidget {
  final Event event;

  const EditEventScreen({super.key, required this.event});

  @override
  State<EditEventScreen> createState() => _EditEventScreenState();
}

class _EditEventScreenState extends State<EditEventScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _categoryController;
  late TextEditingController _locationController;
  late TextEditingController _capacityController;
  
  late DateTime? _eventDate;
  late DateTime? _registrationDeadline;
  late bool _isPrivate;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.event.name);
    _descController = TextEditingController(text: widget.event.description);
    _categoryController = TextEditingController(text: widget.event.category);
    _locationController = TextEditingController(text: widget.event.location);
    _capacityController = TextEditingController(text: widget.event.capacity.toString());
    _eventDate = widget.event.eventDate;
    _registrationDeadline = widget.event.registrationDeadline;
    _isPrivate = widget.event.isPrivate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _categoryController.dispose();
    _locationController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _eventDate == null || _registrationDeadline == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields and select dates.')));
      return;
    }

    if (_registrationDeadline!.isAfter(_eventDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registration deadline cannot be after the event date.')));
      return;
    }

    final data = {
      "name": _nameController.text.trim(),
      "description": _descController.text.trim(),
      "category": _categoryController.text.trim(),
      "location": _locationController.text.trim(),
      "eventDate": _eventDate!.toUtc().toIso8601String(),
      "registrationDeadline": _registrationDeadline!.toUtc().toIso8601String(),
      "capacity": int.tryParse(_capacityController.text.trim()) ?? 0,
      "isPrivate": _isPrivate,
    };

    final success = await context.read<AdminProvider>().updateEvent(widget.event.id, data);
    
    if (!mounted) return;
    
    if (success) {
      context.pop();
    } else {
      final err = context.read<AdminProvider>().error ?? 'Failed to update event.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }

  Future<void> _pickDate(bool isEventDate) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isEventDate ? _eventDate ?? DateTime.now() : _registrationDeadline ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        if (isEventDate) {
          _eventDate = date;
        } else {
          _registrationDeadline = date;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Event')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Event Name'),
                validator: Validators.requiredField,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
                validator: Validators.requiredField,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(labelText: 'Category'),
                validator: Validators.requiredField,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Location'),
                validator: Validators.requiredField,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _capacityController,
                decoration: const InputDecoration(labelText: 'Capacity'),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: Validators.positiveInteger,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _pickDate(true),
                      child: Text(_eventDate == null ? 'Select Event Date' : 'Event: ${_eventDate!.toString().split(' ')[0]}'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _pickDate(false),
                      child: Text(_registrationDeadline == null ? 'Select Deadline' : 'Deadline: ${_registrationDeadline!.toString().split(' ')[0]}'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Private Event (Invite Only)'),
                subtitle: const Text('Private events do not appear on the public discover page.'),
                value: _isPrivate,
                onChanged: (val) => setState(() => _isPrivate = val),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: adminProvider.isLoading ? null : _submit,
                child: adminProvider.isLoading
                    ? const CircularProgressIndicator()
                    : const Text('SAVE CHANGES'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
