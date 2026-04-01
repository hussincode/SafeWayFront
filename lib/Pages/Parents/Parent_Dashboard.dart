import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:safeway/Pages/Parents/Live_Bus_Tracker.dart';
import 'package:safeway/services/api_config.dart';
import 'package:safeway/Pages/login_page.dart';

// ── Parent Info Model ──
class ParentInfoModel {
  final String fullName;
  final String uniqueID;
  final int totalChildren;
  final int onBoard;
  final List<ChildModel> children;

  ParentInfoModel({
    required this.fullName,
    required this.uniqueID,
    required this.totalChildren,
    required this.onBoard,
    required this.children,
  });

  factory ParentInfoModel.fromJson(Map<String, dynamic> j) => ParentInfoModel(
    fullName:      j['fullName']      ?? '',
    uniqueID:      j['uniqueID']      ?? '',
    totalChildren: j['totalChildren'] ?? 0,
    onBoard:       j['onBoard']       ?? 0,
    children: (j['children'] as List)
        .map((c) => ChildModel.fromJson(c))
        .toList(),
  );
}

// ── Child Model ──
class ChildModel {
  final String name;
  final String route;
  final String busNumber;
  final String eta;
  final String pickupStation;
  final String subscription;
  final bool isOnBoard;
  final String? boardingNote;

  ChildModel({
    required this.name,
    required this.route,
    required this.busNumber,
    required this.eta,
    required this.pickupStation,
    required this.subscription,
    required this.isOnBoard,
    this.boardingNote,
  });

  factory ChildModel.fromJson(Map<String, dynamic> j) => ChildModel(
    name:          j['name']          ?? '',
    route:         j['route']         ?? '',
    busNumber:     j['busNumber']      ?? '',
    eta:           j['eta']           ?? '',
    pickupStation: j['pickupStation'] ?? '',
    subscription:  j['subscription']  ?? 'UNPAID',
    isOnBoard:     j['isOnBoard']     ?? false,
    boardingNote:  j['boardingNote'],
  );
}

class ParentDashboardScreen extends StatefulWidget {
  const ParentDashboardScreen({super.key});

  @override
  State<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends State<ParentDashboardScreen> {
  final _storage = const FlutterSecureStorage();

  ParentInfoModel? _parentInfo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadParentInfo();
  }

  Future<void> _loadParentInfo() async {
    try {
      final userIdStr = await _storage.read(key: 'userId') ?? '0';
      final userId    = int.tryParse(userIdStr) ?? 0;

      if (userId == 0) {
        setState(() => _isLoading = false);
        return;
      }

      final res = await http.get(
        Uri.parse('$apiBaseUrl/api/auth/parent-info/$userId'),
      );

      if (!mounted) return;

      if (res.statusCode == 200) {
        setState(() {
          _parentInfo = ParentInfoModel.fromJson(jsonDecode(res.body));
          _isLoading  = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('ParentInfo error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _isLoading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: 80),
                        child: CircularProgressIndicator(color: Color(0xFF16A34A)),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionLabel('Your Children'),
                        const SizedBox(height: 12),

                        // ✅ Real children from DB
                        if (_parentInfo != null && _parentInfo!.children.isNotEmpty)
                          ..._parentInfo!.children.map((child) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildChildCard(
                              name:          child.name,
                              route:         child.route,
                              busNumber:     child.busNumber,
                              eta:           child.eta,
                              pickupStation: child.pickupStation,
                              subscription:  child.subscription,
                              isOnBoard:     child.isOnBoard,
                              boardingNote:  child.boardingNote,
                            ),
                          ))
                        else
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Center(
                              child: Text('No children linked to your account.',
                                  style: TextStyle(color: Colors.grey)),
                            ),
                          ),

                        const SizedBox(height: 16),
                        _buildLiveMapButton(context),
                        const SizedBox(height: 16),
                        _buildSummaryCard(),
                        const SizedBox(height: 16),
                        _buildSubscriptionsCard(),
                        const SizedBox(height: 16),
                        _buildNotificationsCard(),
                        const SizedBox(height: 24),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ── HEADER — Real name ──
  Widget _buildHeader(BuildContext context) {
    final name = _parentInfo?.fullName ?? 'Loading...';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        bottom: 24, left: 20, right: 20,
      ),
      color: const Color(0xFF16A34A),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (Route<dynamic> route) => false,
    );
  },
            child: const Row(
              children: [
                Icon(Icons.arrow_back, color: Colors.white, size: 18),
                SizedBox(width: 6),
                Text('Back to Home', style: TextStyle(color: Colors.white, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ✅ Real name from DB
                  Text(name,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text("Monitor your children's bus activity",
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Icon(Icons.person_outline, color: Colors.white, size: 26),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E)));
  }

  Widget _buildChildCard({
    required String name, required String route, required String busNumber,
    required String eta, required String pickupStation, required String subscription,
    required bool isOnBoard, required String? boardingNote,
  }) {
    final subColor = subscription == 'PAID' ? const Color(0xFF16A34A)
        : subscription == 'EXPIRED' ? const Color(0xFFEA580C)
        : const Color(0xFFDC2626);
    final subBg = subscription == 'PAID' ? const Color(0xFFDCFCE7)
        : subscription == 'EXPIRED' ? const Color(0xFFFFF7ED)
        : const Color(0xFFFFF0F0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(route, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ]),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isOnBoard ? const Color(0xFFDCFCE7) : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isOnBoard ? 'On Board' : 'Not Boarded',
                  style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600,
                    color: isOnBoard ? const Color(0xFF16A34A) : const Color(0xFF6B7280),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: _infoBox('Bus Number', busNumber, const Color(0xFFEFF6FF), const Color(0xFF1D4ED8))),
            const SizedBox(width: 10),
            Expanded(child: _infoBox('ETA', eta, const Color(0xFFEFF6FF), const Color(0xFF1D4ED8))),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _infoBox('Pickup Station', pickupStation, const Color(0xFFFFF7ED), const Color(0xFF92400E))),
            const SizedBox(width: 10),
            // ✅ Real subscription color from DB
            Expanded(child: _infoBox('Subscription', subscription, subBg, subColor)),
          ]),
          if (boardingNote != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(10),
                border: const Border(left: BorderSide(color: Color(0xFF16A34A), width: 3)),
              ),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.access_time_rounded, size: 16, color: Color(0xFF16A34A)),
                const SizedBox(width: 8),
                Expanded(child: Text(boardingNote,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF16A34A)))),
              ]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoBox(String label, String value, Color bg, Color valueColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: valueColor)),
      ]),
    );
  }

  Widget _buildLiveMapButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const LiveBusTrackingScreen())),
        icon: const Icon(Icons.location_on_outlined, color: Colors.white),
        label: const Text('Show Live Map',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF16A34A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  // ✅ Real summary from DB
  Widget _buildSummaryCard() {
    final total   = _parentInfo?.totalChildren ?? 0;
    final onBoard = _parentInfo?.onBoard       ?? 0;
    final active  = _parentInfo?.children
        .where((c) => c.subscription == 'PAID').length ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Summary', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          _summaryRow('Total Children',        '$total',   Colors.black),
          const Divider(height: 20),
          _summaryRow('Currently On Board',    '$onBoard', const Color(0xFF16A34A)),
          const Divider(height: 20),
          _summaryRow('Active Subscriptions',  '$active',  const Color(0xFF2979FF)),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: Color(0xFF444444))),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: valueColor)),
      ],
    );
  }

  // ✅ Real subscriptions from children data
  Widget _buildSubscriptionsCard() {
    final children = _parentInfo?.children ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.credit_card_outlined, size: 18, color: Color(0xFF1A1A2E)),
            SizedBox(width: 8),
            Text('Subscriptions', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 14),
          if (children.isEmpty)
            const Text('No children found.', style: TextStyle(color: Colors.grey))
          else
            ...children.map((child) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _subscriptionRow(child.name, child.subscription),
            )),
        ],
      ),
    );
  }

  Widget _subscriptionRow(String name, String status) {
    final color = status == 'PAID' ? const Color(0xFF16A34A)
        : status == 'EXPIRED' ? const Color(0xFFEA580C)
        : const Color(0xFFDC2626);
    final bg = status == 'PAID' ? const Color(0xFFDCFCE7)
        : status == 'EXPIRED' ? const Color(0xFFFFF7ED)
        : const Color(0xFFFFF0F0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name, style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A2E))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
            child: Text(status,
                style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.notifications_outlined, size: 18, color: Color(0xFF1A1A2E)),
            const SizedBox(width: 8),
            const Text('Notifications', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(20)),
              child: const Text('1', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ]),
          const SizedBox(height: 14),
          _notificationItem(icon: Icons.access_time_rounded, iconColor: const Color(0xFF2979FF),
              message: 'Bus BUS-101 arriving at Main Street Station in 5 minutes', time: '', isUnread: true),
          const SizedBox(height: 10),
          _notificationItem(icon: Icons.check_circle_outline_rounded, iconColor: const Color(0xFF16A34A),
              message: 'Liam Smith boarded the bus at Park Avenue Station', time: '16m ago', isUnread: false),
          const SizedBox(height: 10),
          _notificationItem(icon: Icons.error_outline_rounded, iconColor: const Color(0xFFF59E0B),
              message: 'BUS-101 delayed by 10 minutes due to traffic', time: '31m ago', isUnread: false),
        ],
      ),
    );
  }

  Widget _notificationItem({
    required IconData icon, required Color iconColor,
    required String message, required String time, required bool isUnread,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isUnread ? const Color(0xFFEFF6FF) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(message, style: const TextStyle(fontSize: 13, color: Color(0xFF1A1A2E))),
          if (time.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(time, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ])),
        if (isUnread)
          Container(width: 8, height: 8,
              decoration: const BoxDecoration(color: Color(0xFF2979FF), shape: BoxShape.circle)),
      ]),
    );
  }
}