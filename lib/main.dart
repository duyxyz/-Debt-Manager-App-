Expanded(
  child: debts.any((d) => !d.isPaid)
      ? ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          itemCount: debts.where((d) => !d.isPaid).length,
          itemBuilder: (context, index) {
            final d = debts.where((d) => !d.isPaid).toList()[index];
            return DebtItem(
              debt: d,
              onDelete: () => _deleteDebt(d),
              onPaid: () => _markAsPaid(d),
              onEdit: () => _editDebt(d),
            );
          },
          separatorBuilder: (context, index) => const SizedBox(height: 12),
        )
      : const Center(child: Text("Chưa có nợ")),
),
