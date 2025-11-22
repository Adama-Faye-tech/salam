import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class EditEquipmentScreen extends StatefulWidget {
  final String equipmentId;

  const EditEquipmentScreen({super.key, required this.equipmentId});

  @override
  State<EditEquipmentScreen> createState() => _EditEquipmentScreenState();
}

class _EditEquipmentScreenState extends State<EditEquipmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _api = ApiService();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();

  String _category = 'Tracteur';
  bool _available = true;
  bool _loading = true;
  bool _saving = false;

  final List<String> _categories = [
    'Tracteur',
    'Semoir',
    'Irrigation',
    'Moissonneuse',
    'Pulvérisateur',
    'Remorque',
    'Autre',
  ];

  @override
  void initState() {
    super.initState();
    _loadEquipment();
  }

  Future<void> _loadEquipment() async {
    try {
      final equipmentId = int.tryParse(widget.equipmentId) ?? 0;
      final equipment = await _api.getEquipmentById(equipmentId);
      if (!mounted) return;
      setState(() {
        _nameController.text = equipment?['name']?.toString() ?? '';
        _descriptionController.text =
            equipment?['description']?.toString() ?? '';
        _priceController.text = equipment?['price_per_day']?.toString() ?? '';
        _locationController.text = equipment?['location']?.toString() ?? '';
        _imageUrlController.text = equipment?['image_url']?.toString() ?? '';
        _category = equipment?['category']?.toString() ?? 'Tracteur';
        _available = equipment?['available'] ?? true;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final equipmentId = int.tryParse(widget.equipmentId) ?? 0;
      final res = await _api.updateEquipment(
        id: equipmentId,
        title: _nameController.text.trim(),
        category: _category,
        dailyRate: double.tryParse(_priceController.text.trim()),
        description: _descriptionController.text.trim(),
        available: _available,
      );

      if (!mounted) return;
      if (res['success'] == true) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Matériel mis à jour')));
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Erreur')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Modifier le matériel')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Modifier le matériel')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nom du matériel'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Nom requis' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _category,
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _category = v ?? _category),
                decoration: const InputDecoration(labelText: 'Catégorie'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Prix par jour (FCFA)',
                ),
                keyboardType: TextInputType.number,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Prix requis' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 4,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Localisation'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _imageUrlController,
                decoration: const InputDecoration(
                  labelText: 'URL image (optionnelle)',
                ),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Disponible'),
                value: _available,
                onChanged: (v) => setState(() => _available = v),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Enregistrer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
