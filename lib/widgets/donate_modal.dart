import 'package:flutter/material.dart';
import '../features/sadqa/presentation/widgets/online_donation_modal.dart';

class DonateModal extends StatelessWidget {
  const DonateModal({super.key});

  static Future<void> show(BuildContext context) {
    OnlineDonationModal.show(context);
    return Future.value();
  }

  @override
  Widget build(BuildContext context) {
    return const OnlineDonationModal();
  }
}
