import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/equipment_model.dart';
import '../../providers/user_provider.dart';
import '../../services/api_service.dart';
import '../auth/login_screen.dart';

class BookingScreen extends StatefulWidget {
  final Equipment equipment;

  const BookingScreen({super.key, required this.equipment});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  bool _useHourly = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  double _calculatePrice() {
    if (_startDate == null) return 0;

    if (_useHourly && _startTime != null && _endTime != null) {
      // Calculer les heures
      final start = DateTime(
        _startDate!.year,
        _startDate!.month,
        _startDate!.day,
        _startTime!.hour,
        _startTime!.minute,
      );
      final end = _endDate != null
          ? DateTime(
              _endDate!.year,
              _endDate!.month,
              _endDate!.day,
              _endTime!.hour,
              _endTime!.minute,
            )
          : DateTime(
              _startDate!.year,
              _startDate!.month,
              _startDate!.day,
              _endTime!.hour,
              _endTime!.minute,
            );

      final hours = end.difference(start).inHours;
      if (hours <= 0) return 0;

      return widget.equipment.pricePerHour * hours;
    } else if (_endDate != null) {
      // Calculer les jours
      final days = _endDate!.difference(_startDate!).inDays + 1;
      if (days <= 0) return 0;

      return widget.equipment.pricePerDay * days;
    }

    return 0;
  }

  int _calculateDuration() {
    if (_startDate == null) return 0;

    if (_useHourly && _startTime != null && _endTime != null) {
      final start = DateTime(
        _startDate!.year,
        _startDate!.month,
        _startDate!.day,
        _startTime!.hour,
        _startTime!.minute,
      );
      final end = _endDate != null
          ? DateTime(
              _endDate!.year,
              _endDate!.month,
              _endDate!.day,
              _endTime!.hour,
              _endTime!.minute,
            )
          : DateTime(
              _startDate!.year,
              _startDate!.month,
              _startDate!.day,
              _endTime!.hour,
              _endTime!.minute,
            );

      return end.difference(start).inHours;
    } else if (_endDate != null) {
      return (_endDate!.difference(_startDate!).inDays + 1) * 24;
    }

    return 0;
  }

  Future<void> _selectStartDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked;
        // Réinitialiser la date de fin si elle est avant la nouvelle date de début
        if (_endDate != null && _endDate!.isBefore(picked)) {
          _endDate = null;
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sélectionnez d''abord la date de début')),
      );
      return;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate!.add(const Duration(days: 1)),
      firstDate: _startDate!,
      lastDate: _startDate!.add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  Future<void> _selectStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? const TimeOfDay(hour: 8, minute: 0),
    );

    if (picked != null) {
      setState(() => _startTime = picked);
    }
  }

  Future<void> _selectEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime ?? const TimeOfDay(hour: 17, minute: 0),
    );

    if (picked != null) {
      setState(() => _endTime = picked);
    }
  }

  Future<void> _submitBooking() async {
    if (!_formKey.currentState!.validate()) return;

    final userProvider = context.read<UserProvider>();
    if (!userProvider.isAuthenticated) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vous devez être connecté')));
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
      return;
    }

    // Validations
    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sélectionnez la date de début')),
      );
      return;
    }

    if (_useHourly) {
      if (_startTime == null || _endTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sélectionnez les heures de début et fin'),
          ),
        );
        return;
      }
    } else {
      if (_endDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sélectionnez la date de fin')),
        );
        return;
      }
    }

    final price = _calculatePrice();
    if (price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Prix invalide. Vérifiez les dates/heures'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final apiService = ApiService();

      await apiService.createOrder(
        equipmentId: int.tryParse(widget.equipment.id) ?? 0,
        startDate: _startDate!,
        endDate: _endDate ?? _startDate!,
        deliveryAddress: _notesController.text.isNotEmpty
            ? _notesController.text
            : null,
      );

      if (mounted) {
        setState(() => _isLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Demande de réservation envoyée !'),
            backgroundColor: Colors.green,
          ),
        );

        // Retour avec succès
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final price = _calculatePrice();
    final duration = _calculateDuration();

    return Scaffold(
      appBar: AppBar(title: const Text('Réserver')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Carte équipement
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    if (widget.equipment.photos.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          widget.equipment.photos.first,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            width: 80,
                            height: 80,
                            color: Colors.grey[300],
                            child: const Icon(Icons.agriculture),
                          ),
                        ),
                      ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.equipment.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.equipment.category,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 8),
                          if (widget.equipment.pricePerHour > 0)
                            Text(
                              '${widget.equipment.pricePerHour.toStringAsFixed(0)} FCFA/h',
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          Text(
                            '${widget.equipment.pricePerDay.toStringAsFixed(0)} FCFA/jour',
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Option tarif horaire
            if (widget.equipment.pricePerHour > 0)
              SwitchListTile(
                title: const Text('Location à l''heure'),
                subtitle: const Text('Sinon location à la journée'),
                value: _useHourly,
                onChanged: (value) {
                  setState(() {
                    _useHourly = value;
                    if (!value) {
                      _startTime = null;
                      _endTime = null;
                    }
                  });
                },
              ),
            const SizedBox(height: 16),

            // Date de début
            ListTile(
              title: const Text('Date de début *'),
              subtitle: Text(
                _startDate != null
                    ? dateFormat.format(_startDate!)
                    : 'Sélectionner une date',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: _selectStartDate,
              tileColor: Colors.grey[100],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 12),

            // Heure de début (si horaire)
            if (_useHourly)
              ListTile(
                title: const Text('Heure de début *'),
                subtitle: Text(
                  _startTime != null
                      ? _startTime!.format(context)
                      : 'Sélectionner une heure',
                ),
                trailing: const Icon(Icons.access_time),
                onTap: _selectStartTime,
                tileColor: Colors.grey[100],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            if (_useHourly) const SizedBox(height: 12),

            // Date de fin (si journée)
            if (!_useHourly)
              ListTile(
                title: const Text('Date de fin *'),
                subtitle: Text(
                  _endDate != null
                      ? dateFormat.format(_endDate!)
                      : 'Sélectionner une date',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: _selectEndDate,
                tileColor: Colors.grey[100],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            if (!_useHourly) const SizedBox(height: 12),

            // Heure de fin (si horaire)
            if (_useHourly)
              ListTile(
                title: const Text('Heure de fin *'),
                subtitle: Text(
                  _endTime != null
                      ? _endTime!.format(context)
                      : 'Sélectionner une heure',
                ),
                trailing: const Icon(Icons.access_time),
                onTap: _selectEndTime,
                tileColor: Colors.grey[100],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            if (_useHourly) const SizedBox(height: 12),

            // Date de fin optionnelle pour horaire multi-jours
            if (_useHourly)
              ListTile(
                title: const Text('Date de fin (optionnel)'),
                subtitle: Text(
                  _endDate != null
                      ? dateFormat.format(_endDate!)
                      : 'Si sur plusieurs jours',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: _selectEndDate,
                tileColor: Colors.grey[50],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            if (_useHourly) const SizedBox(height: 12),

            // Notes
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optionnel)',
                hintText: 'Informations supplémentaires...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Récapitulatif
            if (price > 0)
              Card(
                color: Colors.green[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Récapitulatif',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Durée:'),
                          Text(
                            _useHourly
                                ? '$duration heure(s)'
                                : '${duration ~/ 24} jour(s)',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total:'),
                          Text(
                            '${price.toStringAsFixed(0)} FCFA',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),

            // Boutons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: const Text('Annuler'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitBooking,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            'Envoyer la demande',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}