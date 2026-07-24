import 'package:flutter/material.dart';
import 'package:ride_on_driver/core/utils/translate.dart';

import '../../../core/utils/common_widget.dart';
import '../../../core/utils/theme/project_color.dart';

class DriverFAQScreen extends StatefulWidget {
  const DriverFAQScreen({super.key});

  @override
  State<DriverFAQScreen> createState() => _DriverFAQScreenState();
}

class _DriverFAQScreenState extends State<DriverFAQScreen> {
  final List<Map<String, String>> faqList = [
    {
      "question": "How do I start receiving ride requests?",
      "answer":
          "Set your status to 'Online' to begin receiving nearby ride requests from passengers."
    },
    {
      "question": "How can I accept or reject a ride?",
      "answer":
          "Tap 'Accept' when a ride request appears. Ignore it if you don't wish to accept."
    },
    {
      "question": "What if the rider doesn’t show up?",
      "answer":
          "Wait 5-10 minutes, then cancel with the reason 'Rider No-show'."
    },
    {
      "question": "When do I get paid for completed rides?",
      "answer":
          "Payments reflect instantly in your wallet after each completed ride."
    },
    {
      "question": "How do I withdraw my wallet balance?",
      "answer":
          "Go to 'Wallet' > 'Withdraw', enter the amount, and confirm your bank account."
    },
    {
      "question": "Which documents are required to drive?",
      "answer":
          "Driving license, RC, insurance, and identity proof are mandatory."
    },
    {
      "question": "What if the app stops working?",
      "answer":
          "Restart your phone and check internet connection. Use 'Help' for support."
    },
    {
      "question": "Can I cancel a ride after accepting?",
      "answer":
          "Yes, with a valid reason. But frequent cancellations can affect your ratings."
    },
  ];
  List<bool> isExpandedList = [];
  @override
  void initState() {
    super.initState();
    isExpandedList = List<bool>.filled(faqList.length, false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBars(
          title: "FAQs",
          backgroundColor: notifires.getbgcolor,
          titleColor: notifires.getGrey1whiteColor),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: faqList.length,
        itemBuilder: (context, index) {
          final faq = faqList[index];
          final isExpanded = isExpandedList[index];
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: isExpanded ? Colors.indigo[50] : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .06),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ExpansionTile(
              onExpansionChanged: (value) {
                setState(() {
                  isExpandedList[index] = value;
                });
              },
              // collapsedIconColor: Colors.indigo,
              iconColor: themeColor,
              tilePadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              title: Row(
                children: [
                  Icon(Icons.question_answer_rounded, color: themeColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      faq["question"]!.translate(context),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  alignment: Alignment.centerLeft,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline, color: Colors.grey),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          faq["answer"]!.translate(context),
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.black87,
                            height: 1.4,
                          ),
                        ),
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
