import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../models/misc.dart';
import '../../models/product.dart';
import '../../providers/cart_provider.dart';
import '../../services/shop_service.dart';
import '../../widgets/common.dart';
import '../../widgets/virtual_pc.dart';

/// Các khe linh kiện theo thứ tự lắp ráp. `required` = bắt buộc để PC hoạt động.
const _slots = <({String slug, String label, bool required})>[
  (slug: 'cpu', label: 'CPU', required: true),
  (slug: 'mainboard', label: 'Mainboard', required: true),
  (slug: 'ram', label: 'RAM', required: true),
  (slug: 'vga', label: 'Card đồ hoạ', required: false),
  (slug: 'ssd', label: 'SSD', required: true),
  (slug: 'psu', label: 'Nguồn', required: true),
  (slug: 'case', label: 'Vỏ case', required: true),
  (slug: 'cooler', label: 'Tản nhiệt', required: false),
];

/// Công suất dự phòng cho mainboard, RAM, ổ cứng, quạt (khớp BASE_WATTAGE ở backend).
const _baseWattage = 150;

class BuilderScreen extends StatefulWidget {
  const BuilderScreen({super.key});

  @override
  State<BuilderScreen> createState() => _BuilderScreenState();
}

class _BuilderScreenState extends State<BuilderScreen> {
  final Map<String, Product> _selected = {};
  bool _busy = false;

  int get _total => _selected.values.fold(0, (sum, p) => sum + p.finalPrice);
  int get _wattage => _baseWattage + _selected.values.fold(0, (sum, p) => sum + p.tdp);
  int? get _psuWattage => (_selected['psu']?.specs['wattage'] as num?)?.toInt();
  bool get _complete => _slots.where((s) => s.required).every((s) => _selected.containsKey(s.slug));

  Future<void> _pick(String slug, String label) async {
    // Gửi các linh kiện đã chọn ở khe khác để server lọc linh kiện tương thích.
    final others = [for (final e in _selected.entries) if (e.key != slug) e.value.id];
    final picked = await showModalBottomSheet<Product>(
      context: context,
      // Mở trên navigator gốc để sheet không bị thanh điều hướng dưới che mất.
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.8,
        builder: (_, scroll) => _PickerSheet(slug: slug, label: label, selectedIds: others, scroll: scroll),
      ),
    );
    if (picked == null) return;
    setState(() {
      _selected[slug] = picked;
      // Đổi CPU/mainboard/RAM có thể làm linh kiện khác không còn tương thích -> bỏ chọn để người dùng chọn lại.
      _dropIncompatible(slug);
    });
  }

  void _dropIncompatible(String changed) {
    String? socket(String s) => _selected[s]?.specs['socket'] as String?;
    String? ramType(String s) => _selected[s]?.specs['ram_type'] as String?;
    final removed = <String>[];
    if (changed != 'mainboard' && _selected.containsKey('mainboard')) {
      if ((socket('cpu') != null && socket('cpu') != socket('mainboard')) ||
          (ramType('ram') != null && ramType('ram') != ramType('mainboard'))) {
        _selected.remove('mainboard');
        removed.add('Mainboard');
      }
    }
    if (changed == 'mainboard') {
      if (socket('cpu') != null && socket('cpu') != socket('mainboard')) {
        _selected.remove('cpu');
        removed.add('CPU');
      }
      if (ramType('ram') != null && ramType('ram') != ramType('mainboard')) {
        _selected.remove('ram');
        removed.add('RAM');
      }
    }
    final cooler = _selected['cooler'];
    if (cooler != null && socket('cpu') != null && !(cooler.specs['sockets'] as List? ?? []).contains(socket('cpu'))) {
      _selected.remove('cooler');
      removed.add('Tản nhiệt');
    }
    if (removed.isNotEmpty) {
      showMessage(context, 'Đã bỏ chọn ${removed.join(', ')} do không còn tương thích');
    }
  }

  Future<void> _aiBuild() async {
    final result = await showModalBottomSheet<AiBuild>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _AiBuildSheet(),
    );
    if (result == null || !mounted) return;
    setState(() {
      _selected
        ..clear()
        ..addEntries(result.products.map((p) => MapEntry(p.categorySlug, p)));
    });
    showMessage(context, 'Đã áp dụng cấu hình AI gợi ý (${result.products.length} linh kiện)');
  }

  Future<void> _addAllToCart() async {
    setState(() => _busy = true);
    final cart = context.read<CartProvider>();
    String? error;
    for (final p in _selected.values) {
      error = await cart.add(p.id) ?? error;
    }
    if (!mounted) return;
    setState(() => _busy = false);
    if (error != null) {
      showMessage(context, error, error: true);
    } else {
      showMessage(context, 'Đã thêm ${_selected.length} linh kiện vào giỏ');
      context.go('/cart');
    }
  }

  Future<void> _save() async {
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController(text: 'PC ${_selected['cpu']?.name ?? 'của tôi'}');
        return AlertDialog(
          title: const Text('Lưu cấu hình'),
          content: TextField(controller: controller, autofocus: true, maxLength: 100, decoration: const InputDecoration(labelText: 'Tên cấu hình')),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Huỷ')),
            FilledButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('Lưu')),
          ],
        );
      },
    );
    if (name == null || name.isEmpty || !mounted) return;
    try {
      await context.read<ShopService>().saveBuild(name, [for (final p in _selected.values) p.id]);
      if (mounted) showMessage(context, 'Đã lưu cấu hình "$name"');
    } catch (e) {
      if (mounted) showMessage(context, ApiClient.messageOf(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final psu = _psuWattage;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Build PC'),
        actions: [
          IconButton(tooltip: 'Cấu hình đã lưu', icon: const Icon(Icons.bookmarks_outlined), onPressed: () => context.push('/builds')),
          if (_selected.isNotEmpty)
            IconButton(tooltip: 'Làm lại', icon: const Icon(Icons.refresh), onPressed: () => setState(_selected.clear)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          VirtualPc(
            selected: _selected.keys.toSet(),
            onTapSlot: (slug) => _pick(slug, _slots.firstWhere((s) => s.slug == slug).label),
          ),
          const SizedBox(height: 12),
          _AiBuildCard(onTap: _aiBuild),
          Card(
            color: theme.colorScheme.primaryContainer,
            child: ListTile(
              leading: const Icon(Icons.electric_bolt),
              title: Text('Công suất ước tính: $_wattage W'),
              subtitle: Text(
                psu == null
                    ? 'Gợi ý nguồn tối thiểu ${(_wattage * 1.2 / 50).ceil() * 50} W'
                    : psu >= _wattage
                        ? 'Nguồn $psu W đáp ứng đủ'
                        : '⚠ Nguồn $psu W không đủ, hãy chọn nguồn lớn hơn',
              ),
            ),
          ),
          for (final slot in _slots) _slotTile(slot.slug, slot.label, slot.required),
          const SizedBox(height: 80),
        ],
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
                    Text('${_selected.length}/${_slots.length} linh kiện'),
                    Text(formatVnd(_total), style: const TextStyle(fontSize: 18, color: Colors.red, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              IconButton.outlined(onPressed: _selected.isEmpty ? null : _save, icon: const Icon(Icons.bookmark_add_outlined)),
              const SizedBox(width: 8),
              SizedBox(
                width: 150,
                child: LoadingButton(
                  loading: _busy,
                  onPressed: _complete ? _addAllToCart : null,
                  child: const Text('Thêm vào giỏ'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _slotTile(String slug, String label, bool required) {
    final p = _selected[slug];
    return Card(
      child: ListTile(
        onTap: () => _pick(slug, label),
        leading: p == null
            ? CircleAvatar(child: Icon(categoryIcon(slug)))
            : ClipRRect(borderRadius: BorderRadius.circular(6), child: SizedBox(width: 48, height: 48, child: ProductImage(p.imageUrl))),
        title: Text(p?.name ?? '$label${required ? ' *' : ' (tuỳ chọn)'}', maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: p == null
            ? const Text('Chạm để chọn')
            : Text('${formatVnd(p.finalPrice)}${_specHint(p)}', style: const TextStyle(color: Colors.red)),
        trailing: p == null
            ? const Icon(Icons.add_circle_outline)
            : IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => _selected.remove(slug))),
      ),
    );
  }

  String _specHint(Product p) {
    final s = p.specs;
    final parts = [s['socket'], s['ram_type'], if (s['wattage'] != null) '${s['wattage']}W'].whereType<Object>();
    return parts.isEmpty ? '' : '  ·  ${parts.join(' · ')}';
  }
}

class _PickerSheet extends StatefulWidget {
  const _PickerSheet({required this.slug, required this.label, required this.selectedIds, required this.scroll});

  final String slug;
  final String label;
  final List<int> selectedIds;
  final ScrollController scroll;

  @override
  State<_PickerSheet> createState() => _PickerSheetState();
}

class _PickerSheetState extends State<_PickerSheet> {
  late Future<List<Product>> _future = _load();

  Future<List<Product>> _load() => context.read<ShopService>().compatibleProducts(widget.slug, widget.selectedIds);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Chọn ${widget.label}', style: Theme.of(context).textTheme.titleLarge),
        if (widget.selectedIds.isNotEmpty)
          const Text('Chỉ hiển thị linh kiện tương thích', style: TextStyle(color: Colors.green)),
        Expanded(
          child: FutureView(
            future: _future,
            onRetry: () => setState(() => _future = _load()),
            builder: (context, products) => products.isEmpty
                ? const EmptyView(icon: Icons.block, message: 'Không có linh kiện tương thích còn hàng')
                : ListView.builder(
                    controller: widget.scroll,
                    itemCount: products.length,
                    itemBuilder: (_, i) {
                      final p = products[i];
                      return ListTile(
                        onTap: () => Navigator.pop(context, p),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: SizedBox(width: 48, height: 48, child: ProductImage(p.imageUrl)),
                        ),
                        title: Text(p.name),
                        subtitle: Text(formatVnd(p.finalPrice), style: const TextStyle(color: Colors.red)),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}

class _AiBuildCard extends StatelessWidget {
  const _AiBuildCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF0B3D91), AppTheme.primary]),
          ),
          child: const ListTile(
            leading: Icon(Icons.auto_awesome, color: Colors.white),
            title: Text('AI build giúp bạn', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text('Nhập ngân sách & nhu cầu, AI chọn cấu hình tương thích tốt nhất',
                style: TextStyle(color: Colors.white70)),
            trailing: Icon(Icons.chevron_right, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

const _purposes = {
  'gaming': ('Chơi game', Icons.sports_esports),
  'office': ('Văn phòng', Icons.work_outline),
  'design': ('Đồ hoạ', Icons.brush_outlined),
  'streaming': ('Livestream', Icons.videocam_outlined),
};

/// Form AI build + hiển thị kết quả. Trả về [AiBuild] khi người dùng bấm "Áp dụng".
class _AiBuildSheet extends StatefulWidget {
  const _AiBuildSheet();

  @override
  State<_AiBuildSheet> createState() => _AiBuildSheetState();
}

class _AiBuildSheetState extends State<_AiBuildSheet> {
  final _budget = TextEditingController(text: '25');
  final _notes = TextEditingController();
  String _purpose = 'gaming';
  bool _loading = false;
  AiBuild? _result;

  @override
  void dispose() {
    _budget.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    final millions = double.tryParse(_budget.text.replaceAll(',', '.'));
    if (millions == null || millions < 5 || millions > 300) {
      showMessage(context, 'Ngân sách từ 5 đến 300 triệu', error: true);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    try {
      final result = await context.read<ShopService>().aiSuggest(
            budget: (millions * 1000000).round(),
            purpose: _purpose,
            notes: _notes.text,
          );
      if (mounted) setState(() => _result = result);
    } catch (e) {
      if (mounted) showMessage(context, ApiClient.messageOf(e), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      builder: (_, scroll) => ListView(
        controller: scroll,
        padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.viewInsetsOf(context).bottom + 24),
        children: [
          Row(children: [
            const Icon(Icons.auto_awesome, color: AppTheme.primary),
            const SizedBox(width: 8),
            Text('AI build PC', style: Theme.of(context).textTheme.titleLarge),
          ]),
          const SizedBox(height: 16),
          if (_result == null) ..._form() else ..._resultView(_result!),
        ],
      ),
    );
  }

  List<Widget> _form() => [
        TextField(
          controller: _budget,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Ngân sách',
            suffixText: 'triệu ₫',
            prefixIcon: Icon(Icons.account_balance_wallet_outlined),
          ),
        ),
        const SizedBox(height: 16),
        const Text('Nhu cầu chính', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final e in _purposes.entries)
              ChoiceChip(
                avatar: Icon(e.value.$2, size: 18),
                label: Text(e.value.$1),
                selected: _purpose == e.key,
                onSelected: (_) => setState(() => _purpose = e.key),
              ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _notes,
          maxLines: 2,
          maxLength: 500,
          decoration: const InputDecoration(
            labelText: 'Yêu cầu thêm (không bắt buộc)',
            hintText: 'VD: chơi Valorant, GTA V ở 2K, thích AMD...',
          ),
        ),
        const SizedBox(height: 8),
        LoadingButton(loading: _loading, onPressed: _run, child: const Text('AI build ngay')),
        if (_loading)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text('AI đang phân tích hàng nghìn tổ hợp linh kiện...',
                textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
          ),
      ];

  List<Widget> _resultView(AiBuild r) => [
        Row(children: [
          Expanded(child: Text(r.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          Chip(
            visualDensity: VisualDensity.compact,
            avatar: Icon(r.aiPowered ? Icons.auto_awesome : Icons.calculate_outlined, size: 16),
            label: Text(r.aiPowered ? 'Claude AI' : 'Thuật toán Voltix', style: const TextStyle(fontSize: 12)),
          ),
        ]),
        const SizedBox(height: 8),
        Text(r.explanation),
        const SizedBox(height: 8),
        for (final tip in r.tips)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.lightbulb_outline, size: 18, color: Colors.amber),
              const SizedBox(width: 6),
              Expanded(child: Text(tip)),
            ]),
          ),
        const Divider(height: 24),
        for (final p in r.products)
          ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(width: 44, height: 44, child: ProductImage(p.imageUrl)),
            ),
            title: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(p.categoryName),
            trailing: Text(formatVnd(p.finalPrice)),
          ),
        const Divider(height: 24),
        Row(children: [
          Expanded(child: Text('Công suất ~${r.estimatedWattage}W')),
          Text(formatVnd(r.total), style: const TextStyle(fontSize: 18, color: Colors.red, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              onPressed: () => setState(() => _result = null),
              child: const Text('Build lại'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: FilledButton(onPressed: () => Navigator.pop(context, r), child: const Text('Áp dụng'))),
        ]),
      ];
}
