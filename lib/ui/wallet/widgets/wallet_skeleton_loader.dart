import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import 'package:driver/themes/app_colors.dart';

class WalletSkeletonLoader extends StatelessWidget {
  const WalletSkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Loading message
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.primary.withOpacity(0.7),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "جاري تحميل المعاملات...".tr,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[400]
                      : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),

        // Skeleton transaction cards - matching real pagination count
        Expanded(
          child: ListView.builder(
            itemCount: 8, // Show 8 skeleton cards (realistic for mobile screen)
            padding: const EdgeInsets.symmetric(horizontal: 10),
            itemBuilder: (context, index) {
              return _buildSkeletonTransactionCard(context);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSkeletonTransactionCard(BuildContext context) {
    // 🎯 EXPERT: Dynamic colors for dark/light mode
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[700]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[600]! : Colors.grey[100]!;
    final placeholderColor = isDark ? Colors.grey[600] : Colors.grey[300];

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1E1E1E)
                : Colors.white,
            borderRadius: const BorderRadius.all(Radius.circular(10)),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF2E2E2E)
                  : const Color(0xFFE5E7EB),
              width: 0.5,
            ),
            boxShadow: Theme.of(context).brightness == Brightness.dark
                ? null
                : [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 🎯 EXPERT: Exact wallet icon like original (theme-aware)
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[700] : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Icon(
                      Icons.account_balance_wallet,
                      size: 24,
                      color: isDark ? Colors.grey[400] : Colors.black,
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // 🎯 EXPERT: Content matching original layout exactly
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // First row: Date and Amount placeholders (like original)
                      Row(
                        children: [
                          // Date placeholder
                          Expanded(
                            child: Container(
                              height: 16,
                              decoration: BoxDecoration(
                                color: placeholderColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Amount placeholder
                          Container(
                            width: 80,
                            height: 16,
                            decoration: BoxDecoration(
                              color: placeholderColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Second row: Transaction note and status (like original)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Transaction note placeholder
                          Container(
                            width: MediaQuery.of(context).size.width * 0.4,
                            height: 14,
                            decoration: BoxDecoration(
                              color: placeholderColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          // Status placeholder (smaller)
                          Container(
                            width: 60,
                            height: 14,
                            decoration: BoxDecoration(
                              color: placeholderColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
