import 'package:flutter/material.dart';
import '../core/constants/colors.dart';
import '../core/constants/typography.dart';

class TablePagination extends StatelessWidget {
  final int currentPage;
  final int totalItems;
  final int itemsPerPage;
  final ValueChanged<int> onPageChanged;

  const TablePagination({
    super.key,
    required this.currentPage,
    required this.totalItems,
    required this.itemsPerPage,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final int totalPages = (totalItems / itemsPerPage).ceil();
    final int startItem = totalItems == 0 ? 0 : (currentPage - 1) * itemsPerPage + 1;
    final int endItem = (currentPage * itemsPerPage) > totalItems ? totalItems : (currentPage * itemsPerPage);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: CarbonColors.surface1,
        border: Border(
          top: BorderSide(color: CarbonColors.hairline, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Menampilkan $startItem-$endItem dari $totalItems data',
            style: CarbonTypography.caption.copyWith(color: CarbonColors.inkMuted),
          ),
          Row(
            children: [
              Text(
                'Halaman $currentPage dari ${totalPages == 0 ? 1 : totalPages}',
                style: CarbonTypography.caption.copyWith(color: CarbonColors.inkMuted),
              ),
              const SizedBox(width: 16),
              
              // Prev Button
              _buildPaginationButton(
                icon: Icons.chevron_left,
                onPressed: currentPage > 1 ? () => onPageChanged(currentPage - 1) : null,
              ),
              const SizedBox(width: 4),
              
              // Next Button
              _buildPaginationButton(
                icon: Icons.chevron_right,
                onPressed: currentPage < totalPages ? () => onPageChanged(currentPage + 1) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationButton({
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    final disabled = onPressed == null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: disabled ? Colors.transparent : CarbonColors.surface2,
            border: Border.all(
              color: disabled ? CarbonColors.hairline : CarbonColors.inkSubtle,
              width: 1,
            ),
          ),
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 20,
            color: disabled ? CarbonColors.inkSubtle.withOpacity(0.5) : CarbonColors.ink,
          ),
        ),
      ),
    );
  }
}
