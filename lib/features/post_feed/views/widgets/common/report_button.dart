import 'package:flutter/material.dart';
import 'package:auragains/features/post_feed/repositories/report_repository.dart';

class ReportButton extends StatelessWidget {
  final String reportBy;
  final String targetType;
  final int targetId;
  final double iconSize;

  const ReportButton({
    super.key,
    required this.reportBy,
    required this.targetType,
    required this.targetId,
    this.iconSize = 20,
  });

  @override
  Widget build(BuildContext context) {

    final reportRepo = ReportRepository();

    return IconButton(
      onPressed: () {

        showModalBottomSheet(
          context: context,

          builder: (_) {
            return _ReportBottomSheet(

              onSubmit: (reason) async {

                await reportRepo.submitReport(
                  reportBy: reportBy,
                  targetType: targetType,
                  targetId: targetId,
                  reason: reason,
                );
              },
            );
          },
        );
      },

      icon: Icon(
        Icons.flag_outlined,
        color: Colors.white,
        size: iconSize
      ),
    );
  }
}

class _ReportBottomSheet extends StatefulWidget {

  final Future<void> Function(String reason) onSubmit; // use ReportRepository.submitReport function

  const _ReportBottomSheet({
    required this.onSubmit,
  });

  @override
  State<_ReportBottomSheet> createState() =>
      _ReportBottomSheetState();
}

class _ReportBottomSheetState extends State<_ReportBottomSheet> {

  String selectedReason = '';

  final TextEditingController customReasonController = TextEditingController();

  final reasons = [
    'RACIST',
    'Spam',
    'Harassment',
    'False Information',
    'NSFW',
    'Violence',
    'Other',
  ];

  bool get canSubmit {
    if (selectedReason.isEmpty) {
      return false;
    }
    if (selectedReason == 'Other' && customReasonController.text.trim().isEmpty) {
      return false;
    }

    return true;
  }

  @override
  void dispose() {
    customReasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Container(

      decoration: const BoxDecoration(
        color: Color.fromARGB(255, 51, 51, 51),

        borderRadius: BorderRadius.vertical(
          top: Radius.circular(26),
        ),
      ),

      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 26),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [

                  // ===================================
                  // TITLE
                  // ===================================
                  const Text(
                    '⚠ REPORT ⚠',

                    style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.5,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    'Select the related issue.',

                    style: TextStyle(
                      color:Colors.grey.shade500,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ===================================
                  // REPORT OPTIONS
                  // ===================================
                  ...reasons.map((reason) {

                    final isSelected = selectedReason == reason; // Check if this reason is currently selected

                    return GestureDetector(
                      onTap: () {

                        setState(() {
                          selectedReason = reason;
                        });
                      },

                      child: AnimatedContainer(
                        duration: const Duration(
                          milliseconds: 180
                        ),

                        margin: const EdgeInsets.only(
                          bottom: 14
                        ),

                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 18
                        ),

                        decoration: BoxDecoration(
                          color: isSelected ? Colors.redAccent.withValues(alpha: 0.10) : const Color(0xFF1A1A1A),

                          borderRadius: BorderRadius.circular(18),

                          border: Border.all(
                            width: 1.2,

                            color: isSelected ? Colors.redAccent : Colors.white12,
                          ),
                        ),

                        child: Row(
                          children: [

                            AnimatedContainer(
                              duration: const Duration(
                                milliseconds: 180
                              ),

                              width: 22,
                              height: 22,

                              decoration: BoxDecoration(
                                shape: BoxShape.circle,

                                border: Border.all(
                                  width: 2,

                                  color: isSelected ? Colors.redAccent : Colors.white38
                                ),
                              ),

                              child: Center(
                                child: AnimatedContainer(
                                  duration: const Duration(
                                    milliseconds: 180
                                  ),

                                  width: isSelected ? 10 : 0,

                                  height: isSelected ? 10 : 0,

                                  decoration:  const BoxDecoration(
                                    shape: BoxShape.circle,

                                    color: Colors.redAccent,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(
                              width: 18,
                            ),

                            Expanded(
                              child: Text(
                                reason,

                                style: TextStyle(
                                  color: isSelected
                                          ? Colors.redAccent
                                          : Colors.white,

                                  fontSize: 16,

                                  fontWeight: FontWeight.w700
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 10),

                  // ===================================
                  // CUSTOM DETAIL SECTION
                  // ===================================
                  if (selectedReason == 'Other') ...[

                    Container(
                      padding: const EdgeInsets.all(18),

                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),

                        borderRadius: BorderRadius.circular(18),

                        border: Border.all(
                          color: Colors.redAccent.withValues(alpha: 0.18),
                        ),
                      ),

                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [

                          Row(
                            children: [

                              Container(
                                width: 10,
                                height: 10,

                                decoration: const BoxDecoration(
                                  color:Colors.redAccent,

                                  shape: BoxShape.circle,
                                ),
                              ),

                              const SizedBox(width: 10),

                              const Text(
                                'Other Reason',

                                style: TextStyle(
                                  color:Colors.redAccent,

                                  fontWeight: FontWeight.bold,

                                  letterSpacing: 1.2
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          TextField(
                            controller: customReasonController,

                            onChanged: (_) {
                              setState(() {});
                            },

                            maxLines: 5,

                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                            ),

                            decoration: InputDecoration(
                              hintText: 'Describe the issue...',

                              hintStyle: TextStyle(
                                color:Colors.grey.shade600,
                              ),

                              filled: true,

                              fillColor:const Color(0xFF101010),

                              contentPadding:const EdgeInsets.all(18),

                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),

                                borderSide: BorderSide(
                                  color: Colors.redAccent.withValues(alpha: 0.15),
                                ),
                              ),

                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),

                                borderSide: BorderSide(
                                  color: Colors.redAccent.withValues(alpha: 0.15),
                                ),
                              ),

                              focusedBorder: const OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(16),
                                ),

                                borderSide: BorderSide(
                                  color:Colors.redAccent,

                                  width: 1.4,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],

                  const SizedBox(height: 30),

                  // ===================================
                  // SUBMIT BUTTON
                  // ===================================
                  SizedBox(
                    width: double.infinity,
                    height: 56,

                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:Colors.redAccent,

                        foregroundColor:Colors.black,

                        elevation: 0,

                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),

                      ),

                      onPressed: canSubmit ? () async {
                        String finalReason = selectedReason;

                        if (selectedReason == 'Other') {
                          finalReason = customReasonController.text.trim();
                        }

                        try {
                          await widget.onSubmit(finalReason);

                          // CLOSE BOTTOM SHEET
                          if (context.mounted) {
                            Navigator.pop(context);
                          }

                          // SUCCESS MESSAGE
                          if (context.mounted) {

                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(

                                SnackBar(
                                  behavior: SnackBarBehavior.floating,

                                  margin: const EdgeInsets.all(20),

                                  backgroundColor:Colors.greenAccent,

                                  content: const Text('Report submitted successfully.')
                                ),
                              );
                          }

                        } catch (e) {

                          if (context.mounted) {

                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(

                                SnackBar(
                                  behavior: SnackBarBehavior.floating,

                                  margin: const EdgeInsets.all(20),

                                  backgroundColor:Colors.redAccent,

                                  content: const Text('Failed to submit report.'),
                                ),
                              );
                          }
                        }
                      } : null,

                      child: const Text(
                        'SUBMIT REPORT',

                        style: TextStyle(
                          fontSize: 15,
                          fontWeight:
                              FontWeight.w900,

                          letterSpacing: 1.3,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}