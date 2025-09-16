import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:driver/controller/wallet_controller.dart';
import 'package:driver/model/wallet_transaction_model.dart';
import 'package:driver/ui/wallet/widgets/wallet_skeleton_loader.dart';
import 'package:driver/themes/app_colors.dart';
import 'package:driver/constant/constant.dart';

class InfiniteScrollTransactions extends StatefulWidget {
  final WalletController controller;
  final Function(WalletTransactionModel) onTransactionTap;

  const InfiniteScrollTransactions({
    super.key,
    required this.controller,
    required this.onTransactionTap,
  });

  @override
  State<InfiniteScrollTransactions> createState() =>
      _InfiniteScrollTransactionsState();
}

class _InfiniteScrollTransactionsState
    extends State<InfiniteScrollTransactions> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Check if user scrolled to bottom
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // Load more when user is 200px from bottom
      widget.controller.loadMoreTransactions();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // 🔥 EXPERT: Show skeleton loader for initial loading
      if (widget.controller.isLoadingTransactions.value) {
        return const WalletSkeletonLoader();
      }

      // Show empty state if no transactions
      if (widget.controller.transactionList.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                "No transaction found".tr,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        );
      }

      // Show transactions with infinite scroll
      return ListView.builder(
        controller: _scrollController,
        itemCount: widget.controller.transactionList.length +
            (widget.controller.hasMoreTransactions.value ? 1 : 0),
        itemBuilder: (context, index) {
          // Show loading indicator at bottom
          if (index == widget.controller.transactionList.length) {
            return _buildLoadMoreIndicator();
          }

          // Show transaction item
          WalletTransactionModel transaction =
              widget.controller.transactionList[index];

          return _buildTransactionCard(transaction);
        },
      );
    });
  }

  Widget _buildLoadMoreIndicator() {
    return Obx(() {
      if (widget.controller.isLoadingMore.value) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "جاري تحميل المزيد...".tr,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[400]
                      : Colors.grey[600],
                ),
              ),
            ],
          ),
        );
      } else if (!widget.controller.hasMoreTransactions.value) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Text(
            "لا توجد معاملات أخرى".tr,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[400]
                  : Colors.grey[500],
            ),
          ),
        );
      }
      return const SizedBox.shrink();
    });
  }

  Widget _buildTransactionCard(WalletTransactionModel transaction) {
    return InkWell(
      onTap: () => widget.onTransactionTap(transaction),
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
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Icon(
                      Icons.account_balance_wallet,
                      size: 24,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              Constant.dateFormatTimestamp(
                                  transaction.createdDate),
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            "${Constant.IsNegative(double.parse(transaction.amount.toString())) ? "(-" : "+"}"
                            "${Constant.amountShow(amount: transaction.amount.toString().replaceAll("-", ""))}"
                            "${Constant.IsNegative(double.parse(transaction.amount.toString())) ? ")" : ""}",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: Constant.IsNegative(double.parse(
                                      transaction.amount.toString()))
                                  ? Colors.red
                                  : Colors.green,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _getTransactionNote(transaction.note.toString()),
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          if (transaction.note == "Charge Wallet")
                            Text(
                              _getChargeWalletStatus(transaction.state),
                              style: TextStyle(
                                color: _getChargeWalletStatusColor(
                                    transaction.state),
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

  // 🎯 EXPERT: Helper methods for original design

  String _getTransactionNote(String note) {
    switch (note) {
      case "Ride amount credited":
        return "amountAdded".tr;
      case "Admin commission debited":
        return "amountAdmin".tr;
      case "Charge Wallet":
        return "Charge Wallet".tr;
      default:
        return note;
    }
  }

  String _getChargeWalletStatus(String? state) {
    if (state == null) return "";

    switch (state) {
      case "pending":
        return "Pending".tr;
      case "accepted":
        return "Approved".tr;
      default:
        return "Rejected".tr;
    }
  }

  Color _getChargeWalletStatusColor(String? state) {
    if (state == null) return Colors.grey;

    switch (state) {
      case "pending":
        return Colors.amber;
      case "accepted":
        return Colors.green;
      default:
        return Colors.red;
    }
  }
}
