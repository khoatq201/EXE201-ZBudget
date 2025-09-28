import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();

  DateTime? _selectedDate;
  String? _selectedGender;
  bool _isLoading = false;

  final List<String> _genderOptions = ['male', 'female', 'other'];

  final Map<String, String> _genderLabels = {
    'male': 'Nam',
    'female': 'Nữ',
    'other': 'Khác',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hoàn thiện thông tin'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Chào mừng!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Hãy bổ sung thêm một vài thông tin để chúng tôi phục vụ bạn tốt hơn.',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 32),

              // Phone Field
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Số điện thoại',
                  hintText: 'Nhập số điện thoại của bạn',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (!RegExp(
                      r'^(\+84|84|0)(3|5|7|8|9)[0-9]{8}$',
                    ).hasMatch(value)) {
                      return 'Số điện thoại không hợp lệ';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Date of Birth Field
              GestureDetector(
                onTap: _selectDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, color: Colors.grey[600]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedDate != null
                              ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                              : 'Chọn ngày sinh',
                          style: TextStyle(
                            fontSize: 16,
                            color: _selectedDate != null
                                ? Colors.black
                                : Colors.grey[600],
                          ),
                        ),
                      ),
                      Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Gender Field
              Text('Giới tính', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedGender,
                    hint: const Text('Chọn giới tính'),
                    isExpanded: true,
                    items: _genderOptions.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(_genderLabels[value] ?? value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedGender = newValue;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // City Field
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(
                  labelText: 'Thành phố',
                  hintText: 'Nhập thành phố của bạn',
                  prefixIcon: Icon(Icons.location_city),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value != null && value.length > 50) {
                    return 'Tên thành phố không được vượt quá 50 ký tự';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : _skipForNow,
                      child: const Text('Bỏ qua'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _completeProfile,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Hoàn thành'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Note
              Text(
                'Bạn có thể cập nhật thông tin này bất cứ lúc nào trong Cài đặt.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _selectedDate ??
          DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('vi', 'VN'),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _completeProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = AuthService();
      await authService.completeProfile(
        phone: _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim()
            : null,
        dateOfBirth: _selectedDate,
        gender: _selectedGender,
        city: _cityController.text.trim().isNotEmpty
            ? _cityController.text.trim()
            : null,
      );

      if (mounted) {
        // Navigate to home
        Navigator.of(context).pushReplacementNamed('/home');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cập nhật thông tin thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _skipForNow() {
    // Navigate to home without completing profile
    Navigator.of(context).pushReplacementNamed('/home');
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _cityController.dispose();
    super.dispose();
  }
}
