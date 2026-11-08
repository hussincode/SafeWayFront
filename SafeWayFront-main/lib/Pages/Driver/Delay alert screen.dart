import 'package:flutter/material.dart';

class DelayAlertScreen extends StatefulWidget {
  final String busNumber;

  const DelayAlertScreen({
    super.key,
    this.busNumber = 'BUS-101',
  });

  @override
  State<DelayAlertScreen> createState() =>
      _DelayAlertScreenState();
}

class _DelayAlertScreenState
    extends State<DelayAlertScreen> {
  int _selectedDelay = 10;

  final List<int> _delayOptions = [
    5,
    10,
    15,
    20,
  ];

  final TextEditingController _messageController =
      TextEditingController();

  bool _isSending = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // SEND ALERT
  // ─────────────────────────────────────────────

  Future<void> _sendAlert() async {
    setState(() {
      _isSending = true;
    });

    // TODO: Connect to API
    // await http.post(
    //   Uri.parse('$apiBaseUrl/api/notifications/delay'),
    //   body: {...},
    // );

    await Future.delayed(
      const Duration(seconds: 2),
    );

    if (!mounted) return;

    setState(() {
      _isSending = false;
    });

    _showSuccessDialog();
  }

  // ─────────────────────────────────────────────
  // SUCCESS DIALOG
  // ─────────────────────────────────────────────

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return Dialog(
          backgroundColor:
              const Color(0xFF101012),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: Colors.white.withOpacity(0.07),
            ),
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
                  'Alert Sent!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  'Delay alert of $_selectedDelay minutes has been sent to all students and parents.',
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
                      Navigator.pop(context);
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
                  20,
                  20,
                  20,
                  30,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
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

                    const SizedBox(height: 10),

                    _buildCancelButton(context),
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
        20,
        18,
        20,
        18,
      ),
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
                  color: Colors.white
                      .withOpacity(0.07),
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
              Icons.warning_amber_rounded,
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
                  'DRIVER ALERT',
                  style: TextStyle(
                    color: Color(0xFFEF4444),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.3,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Delay Alert',
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
            const Color(0xFF65171B)
                .withOpacity(0.30),
            const Color(0xFF101012)
                .withOpacity(0.98),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFD32F2F)
              .withOpacity(0.17),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD32F2F)
                .withOpacity(0.07),
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
              borderRadius:
                  BorderRadius.circular(15),
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
                  'SENDING ALERT FOR',
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
              horizontal: 9,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFD32F2F)
                  .withOpacity(0.10),
              borderRadius:
                  BorderRadius.circular(9),
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
  // DELAY SELECTOR
  // ─────────────────────────────────────────────

  Widget _buildDelaySelector() {
    return _glassCard(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            Icons.access_time_rounded,
            'Select Delay Time',
          ),

          const SizedBox(height: 17),

          Row(
            children: _delayOptions.map((minutes) {
              final isSelected =
                  _selectedDelay == minutes;

              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDelay = minutes;
                    });
                  },
                  child: Container(
                    margin:
                        const EdgeInsets.symmetric(
                      horizontal: 4,
                    ),
                    padding:
                        const EdgeInsets.symmetric(
                      vertical: 13,
                    ),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? const LinearGradient(
                              colors: [
                                Color(0xFF991B1B),
                                Color(0xFFD32F2F),
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
                            ? const Color(0xFFEF4444)
                                .withOpacity(0.35)
                            : Colors.white
                                .withOpacity(0.055),
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(
                                  0xFFD32F2F,
                                ).withOpacity(0.20),
                                blurRadius: 14,
                              ),
                            ]
                          : [],
                    ),
                    child: Column(
                      children: [
                        Text(
                          '$minutes',
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight:
                                FontWeight.w700,
                            color: isSelected
                                ? Colors.white
                                : const Color(
                                    0xFFE5E5E7,
                                  ),
                          ),
                        ),

                        const SizedBox(height: 2),

                        Text(
                          'minutes',
                          style: TextStyle(
                            fontSize: 9.5,
                            color: isSelected
                                ? Colors.white70
                                : const Color(
                                    0xFF77777D,
                                  ),
                          ),
                        ),

                        if (isSelected) ...[
                          const SizedBox(height: 5),
                          const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                        ] else
                          const SizedBox(height: 19),
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
  // CUSTOM MESSAGE
  // ─────────────────────────────────────────────

  Widget _buildCustomMessage() {
    return _glassCard(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            Icons.edit_note_rounded,
            'Custom Message',
          ),

          const SizedBox(height: 5),

          const Text(
            'Optional message for students and parents',
            style: TextStyle(
              color: Color(0xFF77777D),
              fontSize: 11,
            ),
          ),

          const SizedBox(height: 13),

          TextField(
            controller: _messageController,
            maxLines: 3,
            maxLength: 100,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
            ),
            cursorColor:
                const Color(0xFFEF4444),
            decoration: InputDecoration(
              hintText:
                  'e.g. Heavy traffic on Main Street.\nWe will update you shortly.',
              hintStyle: const TextStyle(
                color: Color(0xFF5F5F65),
                fontSize: 12,
                height: 1.4,
              ),
              filled: true,
              fillColor:
                  Colors.white.withOpacity(0.035),
              contentPadding:
                  const EdgeInsets.all(14),
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(15),
                borderSide: BorderSide(
                  color: Colors.white
                      .withOpacity(0.06),
                ),
              ),
              enabledBorder:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(15),
                borderSide: BorderSide(
                  color: Colors.white
                      .withOpacity(0.06),
                ),
              ),
              focusedBorder:
                  OutlineInputBorder(
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
  // ALERT PREVIEW
  // ─────────────────────────────────────────────

  Widget _buildAlertPreview() {
    final customMsg =
        _messageController.text.trim();

    final previewText = customMsg.isNotEmpty
        ? 'Bus ${widget.busNumber} will be delayed by $_selectedDelay minutes. $customMsg'
        : 'Bus ${widget.busNumber} will be delayed by $_selectedDelay minutes.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF991B1B)
            .withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFEF4444)
              .withOpacity(0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFD32F2F)
                      .withOpacity(0.12),
                  borderRadius:
                      BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.warning_amber_outlined,
                  color: Color(0xFFEF4444),
                  size: 19,
                ),
              ),

              const SizedBox(width: 10),

              const Text(
                'Alert Preview',
                style: TextStyle(
                  color: Color(0xFFEF4444),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),

          const SizedBox(height: 13),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: Colors.black
                  .withOpacity(0.15),
              borderRadius:
                  BorderRadius.circular(13),
              border: Border.all(
                color: Colors.white
                    .withOpacity(0.04),
              ),
            ),
            child: Text(
              previewText,
              style: const TextStyle(
                color: Color(0xFFE5E5E7),
                fontSize: 12.5,
                height: 1.5,
              ),
            ),
          ),

          const SizedBox(height: 18),

          const Text(
            'THIS ALERT WILL BE SENT TO',
            style: TextStyle(
              color: Color(0xFF77777D),
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),

          const SizedBox(height: 11),

          _recipientRow(
            Icons.person_outline_rounded,
            'Students on this bus',
          ),

          const SizedBox(height: 8),

          _recipientRow(
            Icons.family_restroom_rounded,
            'Registered parents',
          ),

          const SizedBox(height: 8),

          _recipientRow(
            Icons.school_outlined,
            'School administration',
          ),
        ],
      ),
    );
  }

  Widget _recipientRow(
    IconData icon,
    String label,
  ) {
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
        onPressed:
            _isSending ? null : _sendAlert,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              const Color(0xFFD32F2F),
          disabledBackgroundColor:
              const Color(0xFF2A2A2D),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(17),
          ),
        ),
        child: _isSending
            ? const SizedBox(
                width: 21,
                height: 21,
                child:
                    CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.2,
                ),
              )
            : const Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.send_rounded,
                    size: 19,
                  ),
                  SizedBox(width: 9),
                  Text(
                    'Send Delay Alert',
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

  Widget _buildCancelButton(
    BuildContext context,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: TextButton(
        onPressed: () =>
            Navigator.pop(context),
        style: TextButton.styleFrom(
          foregroundColor:
              const Color(0xFF77777D),
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
  // SHARED
  // ─────────────────────────────────────────────

  Widget _glassCard({
    required Widget child,
  }) {
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

  Widget _sectionTitle(
    IconData icon,
    String title,
  ) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFD32F2F)
                .withOpacity(0.10),
            borderRadius:
                BorderRadius.circular(11),
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