import 'package:flutter/material.dart';

class DelayAlertScreen extends StatefulWidget {
  final String busNumber;
  const DelayAlertScreen({super.key, this.busNumber = 'BUS-101'});

  @override
  State<DelayAlertScreen> createState() => _DelayAlertScreenState();
}

class _DelayAlertScreenState extends State<DelayAlertScreen> {
  int _selectedDelay = 10;
  final List<int> _delayOptions = [5, 10, 15, 20];
  final TextEditingController _messageController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendAlert() async {
    setState(() => _isSending = true);

    // TODO: Connect to API
    // await http.post('$apiBaseUrl/api/notifications/delay', body: {...});

    await Future.delayed(const Duration(seconds: 2)); // simulate API call

    if (!mounted) return;
    setState(() => _isSending = false);

    // Show success
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 60),
          const SizedBox(height: 12),
          const Text('Alert Sent!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            'Delay alert of $_selectedDelay minutes has been sent to all students and parents.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ]),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // close dialog
                Navigator.pop(context); // close screen
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Done', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBusCard(),
                  const SizedBox(height: 16),
                  _buildDelaySelector(),
                  const SizedBox(height: 16),
                  _buildCustomMessage(),
                  const SizedBox(height: 16),
                  _buildAlertPreview(),
                  const SizedBox(height: 24),
                  _buildSendButton(),
                  const SizedBox(height: 12),
                  _buildCancelButton(context),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── HEADER ──
  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 16, right: 16, bottom: 20,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEF4444), Color(0xFFF97316)],
        ),
      ),
      child: Row(
        children: [
          // Close button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 12),

          // Icon + Title
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Delay Alert',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                Text('Notify students & parents',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),

          // Driver Dashboard badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white38),
            ),
            child: const Text('Driver Dashboard',
                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ── BUS CARD ──
  Widget _buildBusCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
        border: const Border(bottom: BorderSide(color: Color(0xFFFBBF24), width: 3)),
      ),
      child: Row(
        children: [
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.directions_bus_rounded, color: Color(0xFFF59E0B), size: 28),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('SENDING ALERT FOR',
                  style: TextStyle(fontSize: 10, color: Color(0xFFF59E0B), fontWeight: FontWeight.w700, letterSpacing: 1)),
              const SizedBox(height: 4),
              Text(widget.busNumber,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
            ],
          ),
        ],
      ),
    );
  }

  // ── DELAY SELECTOR ──
  Widget _buildDelaySelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.access_time, size: 18, color: Color(0xFF1A1A2E)),
            SizedBox(width: 8),
            Text('Select Delay Time',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
          ]),
          const SizedBox(height: 16),
          Row(
            children: _delayOptions.map((minutes) {
              final isSelected = _selectedDelay == minutes;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedDelay = minutes),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFEF4444) : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: isSelected
                          ? [BoxShadow(color: const Color(0xFFEF4444).withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))]
                          : [],
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Column(children: [
                          Text(
                            '$minutes',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : const Color(0xFF1A1A2E),
                            ),
                          ),
                          Text(
                            'minutes',
                            style: TextStyle(
                              fontSize: 11,
                              color: isSelected ? Colors.white70 : Colors.grey,
                            ),
                          ),
                        ]),
                        if (isSelected)
                          Positioned(
                            top: -8, right: -4,
                            child: Container(
                              width: 20, height: 20,
                              decoration: const BoxDecoration(
                                color: Color(0xFF16A34A),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check, color: Colors.white, size: 13),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── CUSTOM MESSAGE ──
  Widget _buildCustomMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Custom Message (Optional)',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
          const SizedBox(height: 12),
          TextField(
            controller: _messageController,
            maxLines: 3,
            maxLength: 100,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'e.g., Heavy traffic on Main Street.\nWe will update you shortly',
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFEF4444)),
              ),
              counterStyle: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  // ── ALERT PREVIEW ──
  Widget _buildAlertPreview() {
    final customMsg = _messageController.text.trim();
    final previewText = customMsg.isNotEmpty
        ? 'Bus ${widget.busNumber} will be delayed by $_selectedDelay minutes. $customMsg'
        : 'Bus ${widget.busNumber} will be delayed by $_selectedDelay minutes';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.warning_amber_outlined, color: Color(0xFFEF4444), size: 18),
            SizedBox(width: 8),
            Text('Alert Preview',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFFEF4444))),
          ]),
          const SizedBox(height: 10),
          Text(previewText,
              style: const TextStyle(fontSize: 13, color: Color(0xFF374151))),
          const Divider(height: 24, color: Color(0xFFFFE4E4)),
          const Text('This alert will be sent to',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))),
          const SizedBox(height: 10),
          _recipientRow('18 Students'),
          const SizedBox(height: 6),
          _recipientRow('All Registered Parents'),
          const SizedBox(height: 6),
          _recipientRow('School Administration'),
        ],
      ),
    );
  }

  Widget _recipientRow(String label) {
    return Row(children: [
      Container(
        width: 8, height: 8,
        decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle),
      ),
      const SizedBox(width: 8),
      Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF374151))),
    ]);
  }

  // ── SEND BUTTON ──
  Widget _buildSendButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: _isSending ? null : _sendAlert,
        icon: _isSending
            ? const SizedBox(
                width: 18, height: 18,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Icon(Icons.send, color: Colors.white, size: 20),
        label: Text(
          _isSending ? 'Sending...' : 'Send Alert',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF16A34A),
          disabledBackgroundColor: Colors.grey,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 2,
        ),
      ),
    );
  }

  // ── CANCEL BUTTON ──
  Widget _buildCancelButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel',
            style: TextStyle(fontSize: 15, color: Colors.grey, fontWeight: FontWeight.w500)),
      ),
    );
  }
}