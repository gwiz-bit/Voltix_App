import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../models/order.dart';
import '../../services/admin_service.dart';
import '../../widgets/common.dart';
import '../order/orders_screen.dart';

typedef _Dashboard = ({
  Map<String, dynamic> summary,
  List<Map<String, dynamic>> revenue,
  List<Map<String, dynamic>> byStatus,
  List<Map<String, dynamic>> top,
});

/// Báo cáo thống kê cho quản lý.
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late Future<_Dashboard> _future = _load();

  Future<_Dashboard> _load() async {
    final s = context.read<AdminService>();
    final (summary, revenue, byStatus, top) =
        await (s.summary(), s.revenueByDay(days: 30), s.ordersByStatus(), s.topProducts()).wait;
    return (summary: summary, revenue: revenue, byStatus: byStatus, top: top);
  }

  void _reload() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Báo cáo thống kê')),
      body: FutureView(
        future: _future,
        onRetry: _reload,
        builder: (context, d) {
          final s = d.summary;
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1.9,
                  children: [
                    _StatCard('Doanh thu tháng', formatVnd(s['month_revenue'] as int), Icons.payments, Colors.blue),
                    _StatCard('Doanh thu hôm nay', formatVnd(s['today_revenue'] as int), Icons.today, Colors.green),
                    _StatCard('Đơn cần xử lý', '${s['pending_orders']} / ${s['total_orders']}', Icons.hourglass_top,
                        Colors.orange, onTap: () => context.push('/admin/orders')),
                    _StatCard('Sắp hết hàng', '${s['low_stock']} sản phẩm', Icons.warning_amber, Colors.red),
                  ],
                ),
                _ChartCard(title: 'Doanh thu 30 ngày gần nhất', child: _RevenueChart(data: d.revenue)),
                _ChartCard(title: 'Đơn hàng theo trạng thái', child: _StatusChart(data: d.byStatus)),
                Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
                        child: Text('Top sản phẩm bán chạy', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      for (final (i, p) in d.top.indexed)
                        ListTile(
                          dense: true,
                          leading: CircleAvatar(radius: 14, child: Text('${i + 1}')),
                          title: Text(p['name'] as String, maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text('Đã bán ${p['sold']}'),
                          trailing: Text(formatVnd(p['revenue'] as int)),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard(this.label, this.value, this.icon, this.color, {this.onTap});

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 4),
                Flexible(child: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey))),
              ]),
              const SizedBox(height: 4),
              FittedBox(child: Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(height: 200, child: child),
          ],
        ),
      ),
    );
  }
}

class _RevenueChart extends StatelessWidget {
  const _RevenueChart({required this.data});

  final List<Map<String, dynamic>> data;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    final spots = [for (final (i, d) in data.indexed) FlSpot(i.toDouble(), (d['revenue'] as int).toDouble())];
    return LineChart(
      LineChartData(
        gridData: const FlGridData(drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) => [
              for (final s in spots)
                LineTooltipItem(
                  '${(data[s.x.toInt()]['date'] as String).substring(5)}\n${formatVnd(s.y)}',
                  const TextStyle(color: Colors.white, fontSize: 12),
                ),
            ],
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              getTitlesWidget: (v, meta) => Text(formatCompact(v), style: const TextStyle(fontSize: 10)),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 7,
              getTitlesWidget: (v, meta) {
                final i = v.toInt();
                if (i < 0 || i >= data.length) return const SizedBox();
                return Text((data[i]['date'] as String).substring(8), style: const TextStyle(fontSize: 10));
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            preventCurveOverShooting: true,
            color: color,
            barWidth: 2.5,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: true, color: color.withValues(alpha: 0.12)),
          ),
        ],
      ),
    );
  }
}

class _StatusChart extends StatelessWidget {
  const _StatusChart({required this.data});

  final List<Map<String, dynamic>> data;

  @override
  Widget build(BuildContext context) {
    final statuses = [for (final d in data) OrderStatus.parse(d['status'] as String)];
    return BarChart(
      BarChartData(
        gridData: const FlGridData(drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (v, meta) => Text(v.toInt().toString(), style: const TextStyle(fontSize: 10)),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (v, meta) => Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Icon(statuses[v.toInt()].icon, size: 18, color: statuses[v.toInt()].color),
              ),
            ),
          ),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, _, rod, _) => BarTooltipItem(
              '${statuses[group.x].label}: ${rod.toY.toInt()}',
              const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ),
        barGroups: [
          for (final (i, d) in data.indexed)
            BarChartGroupData(x: i, barRods: [
              BarChartRodData(
                toY: (d['count'] as int).toDouble(),
                color: statuses[i].color,
                width: 22,
                borderRadius: BorderRadius.circular(4),
              ),
            ]),
        ],
      ),
    );
  }
}

/// Danh sách đơn hàng cho nhân viên xử lý, lọc theo trạng thái.
class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  OrderStatus? _status = OrderStatus.pending;
  late Future<List<Order>> _future = _load();

  Future<List<Order>> _load() => context.read<AdminService>().orders(status: _status);

  void _reload() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Xử lý đơn hàng')),
      body: Column(
        children: [
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                for (final s in [null, ...OrderStatus.values])
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(s?.label ?? 'Tất cả'),
                      selected: _status == s,
                      onSelected: (_) {
                        _status = s;
                        _reload();
                      },
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: FutureView(
              future: _future,
              onRetry: _reload,
              builder: (context, orders) => OrderList(
                orders: orders,
                showCustomer: true,
                onRefresh: () async => _reload(),
                onTap: (o) async {
                  await context.push('/orders/${o.id}');
                  _reload();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
