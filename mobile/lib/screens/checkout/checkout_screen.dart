import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/format.dart';
import '../../core/validators.dart';
import '../../models/misc.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../services/shop_service.dart';
import '../../widgets/common.dart';
import 'vnpay_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _receiver = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _note = TextEditingController();
  List<Address> _addresses = [];
  String _payment = 'COD';
  bool _saveAddress = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _receiver.text = user?.fullName ?? '';
    _phone.text = user?.phone ?? '';
    context.read<ShopService>().getAddresses().then((list) {
      if (!mounted) return;
      setState(() => _addresses = list);
      if (list.isNotEmpty) _useAddress(list.first);
    }).catchError((_) {});
  }

  @override
  void dispose() {
    for (final c in [_receiver, _phone, _address, _note]) {
      c.dispose();
    }
    super.dispose();
  }

  void _useAddress(Address a) {
    _receiver.text = a.receiver;
    _phone.text = a.phone;
    _address.text = a.detail;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final shop = context.read<ShopService>();
    final cart = context.read<CartProvider>();
    setState(() => _submitting = true);
    try {
      if (_saveAddress) {
        await shop.createAddress(receiver: _receiver.text.trim(), phone: _phone.text.trim(), detail: _address.text.trim());
      }
      final order = await shop.createOrder(
        receiver: _receiver.text.trim(),
        phone: _phone.text.trim(),
        address: _address.text.trim(),
        note: _note.text,
        paymentMethod: _payment,
      );
      cart.reset(); // server đã xoá giỏ hàng
      if (!mounted) return;
      if (_payment == 'VNPAY') {
        await payWithVnpay(context, order.id);
        if (!mounted) return;
      } else {
        showMessage(context, 'Đặt hàng thành công!');
      }
      context.pushReplacement('/orders/${order.id}');
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      showMessage(context, ApiClient.messageOf(e), error: true);
      cart.load(); // tồn kho có thể đã thay đổi
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Thanh toán')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const _Title('Thông tin nhận hàng'),
            if (_addresses.isNotEmpty) ...[
              DropdownButtonFormField<Address>(
                decoration: const InputDecoration(labelText: 'Chọn từ sổ địa chỉ', prefixIcon: Icon(Icons.bookmark_border)),
                isExpanded: true,
                initialValue: _addresses.first,
                items: [
                  for (final a in _addresses)
                    DropdownMenuItem(value: a, child: Text('${a.receiver} – ${a.detail}', overflow: TextOverflow.ellipsis)),
                ],
                onChanged: (a) => setState(() => _useAddress(a!)),
              ),
              const SizedBox(height: 12),
            ],
            TextFormField(
              controller: _receiver,
              decoration: const InputDecoration(labelText: 'Người nhận', prefixIcon: Icon(Icons.person_outline)),
              validator: (v) => Validators.required(v, 'tên người nhận'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Số điện thoại', prefixIcon: Icon(Icons.phone_outlined)),
              validator: Validators.phone,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _address,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Địa chỉ giao hàng', prefixIcon: Icon(Icons.location_on_outlined)),
              validator: (v) => (v == null || v.trim().length < 5) ? 'Vui lòng nhập địa chỉ đầy đủ' : null,
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _saveAddress,
              onChanged: (v) => setState(() => _saveAddress = v!),
              title: const Text('Lưu vào sổ địa chỉ'),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            TextFormField(
              controller: _note,
              maxLength: 255,
              decoration: const InputDecoration(labelText: 'Ghi chú (không bắt buộc)', prefixIcon: Icon(Icons.notes)),
            ),
            const _Title('Phương thức thanh toán'),
            RadioGroup<String>(
              groupValue: _payment,
              onChanged: (v) => setState(() => _payment = v!),
              child: const Column(
                children: [
                  RadioListTile(
                    value: 'COD',
                    title: Text('Thanh toán khi nhận hàng (COD)'),
                    secondary: Icon(Icons.payments_outlined),
                  ),
                  RadioListTile(
                    value: 'VNPAY',
                    title: Text('Thanh toán online qua VNPay'),
                    subtitle: Text('ATM nội địa, Visa/Master, QR ngân hàng'),
                    secondary: Icon(Icons.account_balance_wallet_outlined),
                  ),
                ],
              ),
            ),
            const _Title('Đơn hàng'),
            for (final item in cart.items)
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(item.product.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text('${formatVnd(item.product.finalPrice)} × ${item.quantity}'),
                trailing: Text(formatVnd(item.subtotal)),
              ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tổng thanh toán'),
                    Text(formatVnd(cart.total),
                        style: const TextStyle(fontSize: 20, color: Colors.red, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              SizedBox(
                width: 170,
                child: LoadingButton(
                  loading: _submitting,
                  onPressed: cart.isEmpty ? null : _submit,
                  child: Text(_payment == 'VNPAY' ? 'Thanh toán' : 'Đặt hàng'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 8),
        child: Text(text, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
      );
}
