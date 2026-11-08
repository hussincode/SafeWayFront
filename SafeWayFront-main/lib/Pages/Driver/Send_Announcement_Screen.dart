import 'package:flutter/material.dart';

class SendAnnouncementScreen extends StatefulWidget {
  final String busNumber;

  const SendAnnouncementScreen({
    super.key,
    this.busNumber = 'BUS-101',
  });

  @override
  State<SendAnnouncementScreen> createState() =>
      _SendAnnouncementScreenState();
}

class _SendAnnouncementScreenState
    extends State<SendAnnouncementScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070708),
      appBar: AppBar(
        backgroundColor: const Color(0xFF070708),
        foregroundColor: Colors.white,
        title: const Text('Send Announcement'),
      ),
      body: Center(
        child: Text(
          'Bus: ${widget.busNumber}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
          ),
        ),
      ),
    );
  }
}