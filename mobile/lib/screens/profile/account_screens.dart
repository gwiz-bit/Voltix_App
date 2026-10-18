import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/validators.dart';
import '../../models/misc.dart';
import '../../providers/auth_provider.dart';
import '../../services/shop_service.dart';
import '../../widgets/common.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: context.read<AuthProvider>().user?.fullName);
  late final _phone = TextEditingController(text: context.read<AuthProvider>().user?.phone);
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final error = await context.read<AuthProvider>().updateProfile(_name.text, _phone.text);
    if (!mounted) return;
    setState(() => _saving = false);
    if (error != null) {
      showMessage(context, error, error: true);
    } else {
      showMessage(context, 'Đã cập nhật thông tin');
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = context.read<AuthProvider>().user?.email ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('Thông tin cá nhân')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              initialValue: email,
              enabled: false,
              decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Họ và tên', prefixIcon: Icon(Icons.person_outline)),
              validator: (v) => Validators.required(v, 'họ tên'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Số điện thoại', prefixIcon: Icon(Icons.phone_outlined)),
              validator: Validators.phone,
            ),
            const SizedBox(height: 24),
            LoadingButton(loading: _saving, onPressed: _save, child: const Text('Lưu')),
          ],
        ),
      ),
    );
  }
}

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _old = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_old, _new, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final error = await context.read<AuthProvider>().changePassword(_old.text, _new.text);
    if (!mounted) return;
    setState(() => _saving = false);
    if (error != null) {
      showMessage(context, error, error: true);
    } else {
      showMessage(context, 'Đổi mật khẩu thành công');
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đổi mật khẩu')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _old,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Mật khẩu hiện tại', prefixIcon: Icon(Icons.lock_outline)),
              validator: (v) => Validators.required(v, 'mật khẩu hiện tại'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _new,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Mật khẩu mới', prefixIcon: Icon(Icons.lock_reset)),
              validator: (v) => Validators.password(v) ?? (v == _old.text ? 'Mật khẩu mới phải khác mật khẩu cũ' : null),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirm,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Nhập lại mật khẩu mới', prefixIcon: Icon(Icons.lock_reset)),
              validator: (v) => v != _new.text ? 'Mật khẩu nhập lại không khớp' : null,
            ),
            const SizedBox(height: 24),
            LoadingButton(loading: _saving, onPressed: _save, child: const Text('Đổi mật khẩu')),
          ],
        ),
      ),
    );
  }
}

class AddressesScreen extends StatefulWidget {
  const AddressesScreen({super.key});

  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  late Future<List<Address>> _future = context.read<ShopService>().getAddresses();

  void _reload() => setState(() => _future = context.read<ShopService>().getAddresses());

  Future<void> _delete(Address a) async {
    try {
      await context.read<ShopService>().deleteAddress(a.id);
      _reload();
    } catch (e) {
      if (mounted) showMessage(context, ApiClient.messageOf(e), error: true);
    }
  }

  Future<void> _add() async {
    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _AddressForm(),
    );
    if (added == true) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sổ địa chỉ')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text('Thêm địa chỉ'),
      ),
      body: FutureView(
        future: _future,
        onRetry: _reload,
        builder: (context, list) => list.isEmpty
            ? const EmptyView(icon: Icons.location_off_outlined, message: 'Chưa có địa chỉ nào')
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
                itemCount: list.length,
                itemBuilder: (_, i) {
                  final a = list[i];
                  return Card(
                    child: ListTile(
                      leading: Icon(a.isDefault ? Icons.home : Icons.location_on_outlined,
                          color: a.isDefault ? Theme.of(context).colorScheme.primary : null),
                      title: Text('${a.receiver} · ${a.phone}'),
                      subtitle: Text('${a.detail}${a.isDefault ? '\nMặc định' : ''}'),
                      isThreeLine: a.isDefault,
                      trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _delete(a)),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _AddressForm extends StatefulWidget {
  const _AddressForm();

  @override
  State<_AddressForm> createState() => _AddressFormState();
}

class _AddressFormState extends State<_AddressForm> {
  final _formKey = GlobalKey<FormState>();
  late final _receiver = TextEditingController(text: context.read<AuthProvider>().user?.fullName);
  late final _phone = TextEditingController(text: context.read<AuthProvider>().user?.phone);
  final _detail = TextEditingController();
  bool _default = false;
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_receiver, _phone, _detail]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await context.read<ShopService>().createAddress(
            receiver: _receiver.text.trim(),
            phone: _phone.text.trim(),
            detail: _detail.text.trim(),
            isDefault: _default,
          );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        showMessage(context, ApiClient.messageOf(e), error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.viewInsetsOf(context).bottom + 16),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Thêm địa chỉ', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextFormField(
              controller: _receiver,
              decoration: const InputDecoration(labelText: 'Người nhận'),
              validator: (v) => Validators.required(v, 'tên người nhận'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Số điện thoại'),
              validator: Validators.phone,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _detail,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Địa chỉ (số nhà, đường, phường, quận, tỉnh)'),
              validator: (v) => (v == null || v.trim().length < 5) ? 'Vui lòng nhập địa chỉ đầy đủ' : null,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _default,
              onChanged: (v) => setState(() => _default = v),
              title: const Text('Đặt làm mặc định'),
            ),
            LoadingButton(loading: _saving, onPressed: _save, child: const Text('Lưu địa chỉ')),
          ],
        ),
      ),
    );
  }
}
