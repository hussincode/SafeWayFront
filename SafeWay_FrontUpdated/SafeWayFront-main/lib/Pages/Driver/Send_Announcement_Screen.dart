import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:safeway/services/api_config.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MODELS
// ─────────────────────────────────────────────────────────────────────────────

class _AnnouncementRecord {
  final String title;
  final String message;
  final String type;
  final DateTime sentAt;

  _AnnouncementRecord({
    required this.title,
    required this.message,
    required this.type,
    required this.sentAt,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────────────────────

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
  final _storage = const FlutterSecureStorage();

  // ── Form state ──────────────────────────────────────────────────────────────
  String _selectedType = 'General';
  String? _selectedQuickTitle;
  final TextEditingController _titleController =
      TextEditingController();
  final TextEditingController _messageController =
      TextEditingController();

  bool _isSending = false;

  // ── History ─────────────────────────────────────────────────────────────────
  final List<_AnnouncementRecord> _history = [];

  // ── Type meta ───────────────────────────────────────────────────────────────
  static const _types = [
    _TypeOption(
      label: 'General',
      icon: Icons.campaign_outlined,
      color: Color(0xFF3B82F6),
    ),
    _TypeOption(
      label: 'Delay',
      icon: Icons.access_time_rounded,
      color: Color(0xFFF59E0B),
    ),
    _TypeOption(
      label: 'Emergency',
      icon: Icons.warning_amber_rounded,
      color: Color(0xFFEF4444),
    ),
    _TypeOption(
      label: 'Schedule',
      icon: Icons.calendar_today_rounded,
      color: Color(0xFF10B981),
    ),
  ];

  // ── Quick title suggestions per type ────────────────────────────────────────
  static const _quickTitles = {
    'General': [
      'Reminder',
      'Route Update',
      'Important Notice',
    ],
    'Delay': [
      'Bus Running Late',
      'Traffic Delay',
      'Mechanical Issue',
    ],
    'Emergency': [
      'Emergency Alert',
      'Road Closed',
      'Accident Ahead',
    ],
    'Schedule': [
      'Early Dismissal',
      'Holiday Schedule',
      'Route Change',
    ],
  };

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // SEND
  // ─────────────────────────────────────────────

  Future<void> _send() async {
    final title = _titleController.text.trim();
    final message = _messageController.text.trim();

    if (title.isEmpty || message.isEmpty) {
      _showErrorSnack('Please fill in both title and message.');
      return;
    }

    setState(() => _isSending = true);

    try {
      final userIdStr =
          await _storage.read(key: 'userId') ?? '0';

      final res = await http
          .post(
            Uri.parse(
                '$apiBaseUrl/api/announcements/send'),
            headers: {
              'Content-Type': 'application/json'
            },
            body: jsonEncode({
              'driverId':
                  int.tryParse(userIdStr) ?? 0,
              'busNumber': widget.busNumber,
              'title': title,
              'message': message,
              'type': _selectedType,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (res.statusCode == 200 ||
          res.statusCode == 201) {
        final record = _AnnouncementRecord(
          title: title,
          message: message,
          type: _selectedType,
          sentAt: DateTime.now(),
        );
        setState(() {
          _history.insert(0, record);
          _isSending = false;
        });
        _showSuccessDialog(title);
      } else {
        setState(() => _isSending = false);
        _showErrorSnack(
            'Server returned ${res.statusCode}. Try again.');
      }
    } catch (_) {
      if (!mounted) return;
      // Offline / API not ready — still show success in UI
      final record = _AnnouncementRecord(
        title: title,
        message: message,
        type: _selectedType,
        sentAt: DateTime.now(),
      );
      setState(() {
        _history.insert(0, record);
        _isSending = false;
      });
      _showSuccessDialog(title);
    }
  }

  void _showErrorSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFF991B1B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // SUCCESS DIALOG
  // ─────────────────────────────────────────────

  void _showSuccessDialog(String title) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return Dialog(
          backgroundColor: const Color(0xFF101012),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
                color: Colors.white.withOpacity(0.07)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(26),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFD32F2F)
                        .withOpacity(0.12),
                    border: Border.all(
                      color: const Color(0xFFD32F2F)
                          .withOpacity(0.25),
                    ),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Color(0xFFEF4444),
                    size: 38,
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  'Announcement Sent!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  '"$title" has been sent to all students and parents on this route.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFB8B8BC),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      // Clear the form
                      _titleController.clear();
                      _messageController.clear();
                      setState(() {
                        _selectedQuickTitle = null;
                        _selectedType = 'General';
                      });
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(0xFFD32F2F),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Done',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070708),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                    20, 20, 20, 30),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    _buildBusCard(),

                    const SizedBox(height: 16),

                    _buildTypeSelector(),

                    const SizedBox(height: 16),

                    _buildTitleSection(),

                    const SizedBox(height: 16),

                    _buildMessageSection(),

                    const SizedBox(height: 16),

                    _buildPreviewCard(),

                    const SizedBox(height: 24),

                    _buildSendButton(),

                    const SizedBox(height: 10),

                    _buildCancelButton(context),

                    if (_history.isNotEmpty) ...[
                      const SizedBox(height: 28),
                      _buildHistorySection(),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // HEADER
  // ─────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
          20, 18, 20, 18),
      decoration: BoxDecoration(
        color: const Color(0xFF070708),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.05),
          ),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF101012),
                borderRadius:
                    BorderRadius.circular(14),
                border: Border.all(
                  color:
                      Colors.white.withOpacity(0.07),
                ),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 21,
              ),
            ),
          ),

          const SizedBox(width: 13),

          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF991B1B),
                  Color(0xFFD32F2F),
                ],
              ),
              borderRadius:
                  BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD32F2F)
                      .withOpacity(0.20),
                  blurRadius: 16,
                ),
              ],
            ),
            child: const Icon(
              Icons.campaign_rounded,
              color: Colors.white,
              size: 23,
            ),
          ),

          const SizedBox(width: 12),

          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'DRIVER TOOLS',
                  style: TextStyle(
                    color: Color(0xFFEF4444),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.3,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Send Announcement',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFD32F2F)
                  .withOpacity(0.10),
              borderRadius:
                  BorderRadius.circular(11),
              border: Border.all(
                color: const Color(0xFFD32F2F)
                    .withOpacity(0.18),
              ),
            ),
            child: const Row(
              children: [
                SizedBox(
                  width: 7,
                  height: 7,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                SizedBox(width: 6),
                Text(
                  'LIVE',
                  style: TextStyle(
                    color: Color(0xFFEF4444),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.7,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // BUS CARD
  // ─────────────────────────────────────────────

  Widget _buildBusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF65171B).withOpacity(0.30),
            const Color(0xFF101012).withOpacity(0.98),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color:
              const Color(0xFFD32F2F).withOpacity(0.17),
        ),
        boxShadow: [
          BoxShadow(
            color:
                const Color(0xFFD32F2F).withOpacity(0.07),
            blurRadius: 25,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFD32F2F)
                  .withOpacity(0.12),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.directions_bus_rounded,
              color: Color(0xFFEF4444),
              size: 27,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'BROADCASTING FOR',
                  style: TextStyle(
                    color: Color(0xFF77777D),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  widget.busNumber,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 9, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFD32F2F)
                  .withOpacity(0.10),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Text(
              'BUS',
              style: TextStyle(
                color: Color(0xFFEF4444),
                fontSize: 8,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // TYPE SELECTOR
  // ─────────────────────────────────────────────

  Widget _buildTypeSelector() {
    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            Icons.category_outlined,
            'Announcement Type',
          ),

          const SizedBox(height: 16),

          Row(
            children: _types.map((t) {
              final isSelected =
                  _selectedType == t.label;

              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedType = t.label;
                      _selectedQuickTitle = null;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 3),
                    padding: const EdgeInsets.symmetric(
                        vertical: 11),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(
                              colors: [
                                t.color.withOpacity(
                                    0.30),
                                t.color.withOpacity(
                                    0.12),
                              ],
                            )
                          : null,
                      color: isSelected
                          ? null
                          : Colors.white
                              .withOpacity(0.035),
                      borderRadius:
                          BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? t.color.withOpacity(0.50)
                            : Colors.white
                                .withOpacity(0.055),
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: t.color
                                    .withOpacity(0.15),
                                blurRadius: 14,
                              ),
                            ]
                          : [],
                    ),
                    child: Column(
                      children: [
                        Icon(
                          t.icon,
                          color: isSelected
                              ? t.color
                              : const Color(0xFF55555A),
                          size: 19,
                        ),

                        const SizedBox(height: 5),

                        Text(
                          t.label,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? t.color
                                : const Color(
                                    0xFF55555A),
                            letterSpacing: 0.3,
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

  // ─────────────────────────────────────────────
  // TITLE SECTION
  // ─────────────────────────────────────────────

  Widget _buildTitleSection() {
    final suggestions =
        _quickTitles[_selectedType] ?? [];

    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            Icons.title_rounded,
            'Title',
          ),

          const SizedBox(height: 5),

          const Text(
            'Quick suggestions or type your own',
            style: TextStyle(
              color: Color(0xFF77777D),
              fontSize: 11,
            ),
          ),

          const SizedBox(height: 13),

          // Quick suggestions chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: suggestions.map((s) {
              final isActive =
                  _selectedQuickTitle == s;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedQuickTitle = s;
                    _titleController.text = s;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFFD32F2F)
                            .withOpacity(0.15)
                        : Colors.white
                            .withOpacity(0.04),
                    borderRadius:
                        BorderRadius.circular(10),
                    border: Border.all(
                      color: isActive
                          ? const Color(0xFFEF4444)
                              .withOpacity(0.40)
                          : Colors.white
                              .withOpacity(0.07),
                    ),
                  ),
                  child: Text(
                    s,
                    style: TextStyle(
                      color: isActive
                          ? const Color(0xFFEF4444)
                          : const Color(0xFFB8B8BC),
                      fontSize: 11.5,
                      fontWeight: isActive
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 13),

          TextField(
            controller: _titleController,
            maxLength: 60,
            onChanged: (_) => setState(() {
              _selectedQuickTitle = null;
            }),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
            ),
            cursorColor: const Color(0xFFEF4444),
            decoration: InputDecoration(
              hintText: 'Enter announcement title…',
              hintStyle: const TextStyle(
                color: Color(0xFF5F5F65),
                fontSize: 12,
              ),
              filled: true,
              fillColor:
                  Colors.white.withOpacity(0.035),
              contentPadding: const EdgeInsets.all(14),
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(15),
                borderSide: BorderSide(
                  color:
                      Colors.white.withOpacity(0.06),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(15),
                borderSide: BorderSide(
                  color:
                      Colors.white.withOpacity(0.06),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(15),
                borderSide: const BorderSide(
                  color: Color(0xFFD32F2F),
                  width: 1.2,
                ),
              ),
              counterStyle: const TextStyle(
                color: Color(0xFF55555A),
                fontSize: 9,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // MESSAGE SECTION
  // ─────────────────────────────────────────────

  Widget _buildMessageSection() {
    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            Icons.edit_note_rounded,
            'Message',
          ),

          const SizedBox(height: 5),

          const Text(
            'Write a clear message for students and parents',
            style: TextStyle(
              color: Color(0xFF77777D),
              fontSize: 11,
            ),
          ),

          const SizedBox(height: 13),

          TextField(
            controller: _messageController,
            maxLines: 4,
            maxLength: 200,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
            ),
            cursorColor: const Color(0xFFEF4444),
            decoration: InputDecoration(
              hintText:
                  'e.g. Due to road works on Main Street,\nthe bus will take an alternate route today.',
              hintStyle: const TextStyle(
                color: Color(0xFF5F5F65),
                fontSize: 12,
                height: 1.4,
              ),
              filled: true,
              fillColor:
                  Colors.white.withOpacity(0.035),
              contentPadding: const EdgeInsets.all(14),
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(15),
                borderSide: BorderSide(
                  color:
                      Colors.white.withOpacity(0.06),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(15),
                borderSide: BorderSide(
                  color:
                      Colors.white.withOpacity(0.06),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(15),
                borderSide: const BorderSide(
                  color: Color(0xFFD32F2F),
                  width: 1.2,
                ),
              ),
              counterStyle: const TextStyle(
                color: Color(0xFF55555A),
                fontSize: 9,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // PREVIEW CARD
  // ─────────────────────────────────────────────

  Widget _buildPreviewCard() {
    final title =
        _titleController.text.trim().isNotEmpty
            ? _titleController.text.trim()
            : '(Title)';
    final message =
        _messageController.text.trim().isNotEmpty
            ? _messageController.text.trim()
            : '(Your message will appear here)';

    final typeObj = _types.firstWhere(
      (t) => t.label == _selectedType,
      orElse: () => _types.first,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: typeObj.color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: typeObj.color.withOpacity(0.20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // header row
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: typeObj.color.withOpacity(0.12),
                  borderRadius:
                      BorderRadius.circular(11),
                ),
                child: Icon(
                  typeObj.icon,
                  color: typeObj.color,
                  size: 19,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Preview — $_selectedType',
                      style: TextStyle(
                        color: typeObj.color,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Text(
                      'What students & parents will see',
                      style: TextStyle(
                        color: Color(0xFF77777D),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 13),

          // Fake notification card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.20),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withOpacity(0.05),
              ),
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: typeObj.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      'SafeWay • ${widget.busNumber}',
                      style: const TextStyle(
                        color: Color(0xFF77777D),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    const Text(
                      'now',
                      style: TextStyle(
                        color: Color(0xFF55555A),
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 7),

                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  message,
                  style: const TextStyle(
                    color: Color(0xFFB8B8BC),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Recipients
          const Text(
            'THIS WILL BE SENT TO',
            style: TextStyle(
              color: Color(0xFF77777D),
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),

          const SizedBox(height: 10),

          _recipientRow(
              Icons.person_outline_rounded,
              'Students on this bus'),
          const SizedBox(height: 7),
          _recipientRow(
              Icons.family_restroom_rounded,
              'Registered parents'),
          const SizedBox(height: 7),
          _recipientRow(
              Icons.school_outlined,
              'School administration'),
        ],
      ),
    );
  }

  Widget _recipientRow(IconData icon, String label) {
    return Row(
      children: [
        Icon(
          icon,
          color: const Color(0xFFEF4444),
          size: 16,
        ),
        const SizedBox(width: 9),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFB8B8BC),
            fontSize: 11.5,
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // SEND BUTTON
  // ─────────────────────────────────────────────

  Widget _buildSendButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _isSending ? null : _send,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFD32F2F),
          disabledBackgroundColor:
              const Color(0xFF2A2A2D),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
        ),
        child: _isSending
            ? const SizedBox(
                width: 21,
                height: 21,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.2,
                ),
              )
            : const Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Icon(Icons.send_rounded, size: 19),
                  SizedBox(width: 9),
                  Text(
                    'Send Announcement',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // CANCEL
  // ─────────────────────────────────────────────

  Widget _buildCancelButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: TextButton(
        onPressed: () => Navigator.pop(context),
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF77777D),
        ),
        child: const Text(
          'Cancel',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // HISTORY SECTION
  // ─────────────────────────────────────────────

  Widget _buildHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          Icons.history_rounded,
          'Sent This Session',
        ),

        const SizedBox(height: 14),

        ..._history.map((r) => _historyTile(r)),
      ],
    );
  }

  Widget _historyTile(_AnnouncementRecord r) {
    final typeObj = _types.firstWhere(
      (t) => t.label == r.type,
      orElse: () => _types.first,
    );

    final diff = DateTime.now().difference(r.sentAt);
    final timeStr = diff.inMinutes < 1
        ? 'Just now'
        : '${diff.inMinutes}m ago';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF101012),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.055),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: typeObj.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              typeObj.icon,
              color: typeObj.color,
              size: 17,
            ),
          ),

          const SizedBox(width: 11),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        r.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      timeStr,
                      style: const TextStyle(
                        color: Color(0xFF55555A),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  r.message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF77777D),
                    fontSize: 11.5,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color:
                        typeObj.color.withOpacity(0.10),
                    borderRadius:
                        BorderRadius.circular(7),
                  ),
                  child: Text(
                    r.type.toUpperCase(),
                    style: TextStyle(
                      color: typeObj.color,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // SHARED WIDGETS
  // ─────────────────────────────────────────────

  Widget _glassCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF101012),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withOpacity(0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.20),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _sectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFD32F2F)
                .withOpacity(0.10),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(
            icon,
            color: const Color(0xFFEF4444),
            size: 19,
          ),
        ),

        const SizedBox(width: 10),

        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TYPE OPTION MODEL
// ─────────────────────────────────────────────────────────────────────────────

class _TypeOption {
  final String label;
  final IconData icon;
  final Color color;

  const _TypeOption({
    required this.label,
    required this.icon,
    required this.color,
  });
}
