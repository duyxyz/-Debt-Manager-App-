import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const DebtApp());
}

enum AppTheme { system, light, dark, oled }

class DebtApp extends StatefulWidget {
  const DebtApp({super.key});

  @override
  State<DebtApp> createState() => _DebtAppState();
}

class _DebtAppState extends State<DebtApp> {
  AppTheme _themeMode = AppTheme.system;
  Color _seedColor = Colors.teal;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt('themeMode') ?? 0;
    final colorValue = prefs.getInt('seedColor') ?? Colors.teal.value;
    setState(() {
      _themeMode = AppTheme.values[themeIndex];
      _seedColor = Color(colorValue);
    });
  }

  Future<void> _saveTheme(AppTheme theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeMode', theme.index);
  }

  Future<void> _saveColor(Color color) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('seedColor', color.value);
  }

  ThemeMode get themeMode {
    switch (_themeMode) {
      case AppTheme.light:
        return ThemeMode.light;
      case AppTheme.dark:
      case AppTheme.oled:
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  ThemeData get lightTheme => ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: _seedColor),
    useMaterial3: true,
  );

  ThemeData get darkTheme => ThemeData.dark().copyWith(
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.dark,
    ),
    useMaterial3: true,
  );

  ThemeData get oledTheme => ThemeData.dark().copyWith(
    scaffoldBackgroundColor: Colors.black,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.dark,
      background: Colors.black,
      surface: Colors.black,
    ),
    cardColor: Colors.black,
    useMaterial3: true,
  );

  void _changeTheme(AppTheme theme) {
    setState(() => _themeMode = theme);
    _saveTheme(theme);
  }

  void _changeColor(Color color) {
    setState(() => _seedColor = color);
    _saveColor(color);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sổ Nợ',
      theme: lightTheme,
      darkTheme: _themeMode == AppTheme.oled ? oledTheme : darkTheme,
      themeMode: themeMode,
      home: DebtHomePage(
        onThemeChange: _changeTheme,
        currentTheme: _themeMode,
        onColorChange: _changeColor,
        currentColor: _seedColor,
      ),
    );
  }
}

class Debt {
  String person;
  int amount;
  DateTime loanDate;
  DateTime dueDate;
  bool isPaid;

  Debt({
    required this.person,
    required this.amount,
    required this.loanDate,
    required this.dueDate,
    this.isPaid = false,
  });

  Map<String, dynamic> toJson() => {
    "person": person,
    "amount": amount,
    "loanDate": loanDate.toIso8601String(),
    "dueDate": dueDate.toIso8601String(),
    "isPaid": isPaid,
  };

  factory Debt.fromJson(Map<String, dynamic> json) => Debt(
    person: json["person"],
    amount: json["amount"],
    loanDate: DateTime.parse(json["loanDate"]),
    dueDate: DateTime.parse(json["dueDate"]),
    isPaid: json["isPaid"],
  );
}

class DebtHomePage extends StatefulWidget {
  final Function(AppTheme) onThemeChange;
  final Function(Color) onColorChange;
  final AppTheme currentTheme;
  final Color currentColor;

  const DebtHomePage({
    super.key,
    required this.onThemeChange,
    required this.currentTheme,
    required this.onColorChange,
    required this.currentColor,
  });

  @override
  State<DebtHomePage> createState() => _DebtHomePageState();
}

class _DebtHomePageState extends State<DebtHomePage> {
  final List<Debt> debts = [];

  @override
  void initState() {
    super.initState();
    _loadDebts();
  }

  Future<void> _loadDebts() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList("debts") ?? [];
    setState(() {
      debts.clear();
      debts.addAll(list.map((e) => Debt.fromJson(jsonDecode(e))).toList());
    });
  }

  Future<void> _saveDebts() async {
    final prefs = await SharedPreferences.getInstance();
    final list = debts.map((d) => jsonEncode(d.toJson())).toList();
    await prefs.setStringList("debts", list);
  }

  void _addDebt() async {
    final debt = await showDialog<Debt>(
      context: context,
      builder: (_) => const AddDebtDialog(),
    );
    if (debt != null) {
      setState(() => debts.add(debt));
      _saveDebts();
    }
  }

  void _markAsPaid(Debt debt) {
    setState(() => debt.isPaid = true);
    _saveDebts();
  }

  void _deleteDebt(Debt debt) {
    setState(() => debts.remove(debt));
    _saveDebts();
  }

  int get totalUnpaid =>
      debts.where((d) => !d.isPaid).fold(0, (s, d) => s + d.amount);

  void _openSettings() {
    showModalBottomSheet(
      context: context,
      builder: (_) => ThemeSettingsSheet(
        currentTheme: widget.currentTheme,
        onThemeChange: widget.onThemeChange,
        onColorChange: widget.onColorChange,
        currentColor: widget.currentColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: SafeArea(
        child: Scaffold(
          body: Column(
            children: [
              const TabBar(
                tabs: [
                  Tab(text: "ĐANG NỢ"),
                  Tab(text: "NỢ ĐÃ TRẢ"),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.1),
                          width: double.infinity,
                          child: Text(
                            "Tổng nợ: ${NumberFormat("#,###", "vi_VN").format(totalUnpaid).replaceAll(',', '.')} đ",
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          child: debts.any((d) => !d.isPaid)
                              ? ListView.separated(
                            itemCount:
                            debts.where((d) => !d.isPaid).length,
                            separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                            itemBuilder: (_, index) {
                              final debt = debts
                                  .where((d) => !d.isPaid)
                                  .toList()[index];
                              return DebtItem(
                                debt: debt,
                                onDelete: () => _deleteDebt(debt),
                                onPaid: () => _markAsPaid(debt),
                              );
                            },
                            padding: const EdgeInsets.all(12),
                          )
                              : const Center(child: Text("Chưa có nợ")),
                        ),
                      ],
                    ),
                    debts.any((d) => d.isPaid)
                        ? ListView.separated(
                      itemCount: debts.where((d) => d.isPaid).length,
                      separatorBuilder: (_, __) =>
                      const SizedBox(height: 12),
                      itemBuilder: (_, index) {
                        final debt = debts
                            .where((d) => d.isPaid)
                            .toList()[index];
                        return DebtItem(
                          debt: debt,
                          onDelete: () => _deleteDebt(debt),
                          isPaidList: true,
                        );
                      },
                      padding: const EdgeInsets.all(12),
                    )
                        : const Center(child: Text("Chưa có nợ đã trả")),
                  ],
                ),
              ),
            ],
          ),
          floatingActionButton: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FloatingActionButton(
                onPressed: _openSettings,
                child: const Icon(Icons.settings),
              ),
              const SizedBox(width: 12),
              FloatingActionButton(
                onPressed: _addDebt,
                child: const Icon(Icons.add),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DebtItem extends StatelessWidget {
  final Debt debt;
  final VoidCallback onDelete;
  final VoidCallback? onPaid;
  final bool isPaidList;

  const DebtItem({
    super.key,
    required this.debt,
    required this.onDelete,
    this.onPaid,
    this.isPaidList = false,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(debt),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      secondaryBackground: Container(
        color: Colors.green,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.check, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onDelete();
          return true;
        } else if (direction == DismissDirection.endToStart && !isPaidList) {
          onPaid?.call();
          return false;
        }
        return false;
      },
      child: Card(
        margin: EdgeInsets.zero,
        child: ListTile(
          title: Text("${debt.person} - "
              "${NumberFormat("#,###", "vi_VN").format(debt.amount).replaceAll(',', '.')} đ"),
          subtitle: Text(
              "Ngày vay: ${DateFormat("dd/MM/yyyy").format(debt.loanDate)}\nNgày trả: ${DateFormat("dd/MM/yyyy").format(debt.dueDate)}"),
          trailing: isPaidList
              ? const Icon(Icons.check_circle, color: Colors.green)
              : null,
        ),
      ),
    );
  }
}

class AddDebtDialog extends StatefulWidget {
  const AddDebtDialog({super.key});

  @override
  State<AddDebtDialog> createState() => _AddDebtDialogState();
}

class _AddDebtDialogState extends State<AddDebtDialog> {
  final _personCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  DateTime? _loanDate;
  DateTime? _dueDate;

  Future<void> _pickDate(bool isLoanDate) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
      initialDate: now,
    );
    if (picked != null) {
      setState(() {
        if (isLoanDate) {
          _loanDate = picked;
        } else {
          _dueDate = picked;
        }
      });
    }
  }

  void _submit() {
    final person = _personCtrl.text.trim();
    final amountText = _amountCtrl.text.trim();
    if (person.isEmpty ||
        amountText.isEmpty ||
        _loanDate == null ||
        _dueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng nhập đầy đủ thông tin")),
      );
      return;
    }

    final amount = int.tryParse(amountText.replaceAll('.', '')) ?? 0;

    final debt = Debt(
      person: person,
      amount: amount,
      loanDate: _loanDate!,
      dueDate: _dueDate!,
    );

    Navigator.pop(context, debt);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Thêm khoản nợ"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _personCtrl,
            decoration: const InputDecoration(
              labelText: "Người nợ",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: "Số tiền",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _pickDate(true),
                  child: Text(_loanDate == null
                      ? "Ngày vay"
                      : DateFormat("dd/MM/yyyy").format(_loanDate!)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _pickDate(false),
                  child: Text(_dueDate == null
                      ? "Ngày trả"
                      : DateFormat("dd/MM/yyyy").format(_dueDate!)),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
        ElevatedButton(onPressed: _submit, child: const Text("Thêm")),
      ],
    );
  }
}

class ThemeSettingsSheet extends StatelessWidget {
  final AppTheme currentTheme;
  final Function(AppTheme) onThemeChange;
  final Function(Color) onColorChange;
  final Color currentColor;

  const ThemeSettingsSheet({
    super.key,
    required this.currentTheme,
    required this.onThemeChange,
    required this.onColorChange,
    required this.currentColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = [
      Colors.teal,
      Colors.blue,
      Colors.green,
      Colors.red,
      Colors.purple,
      Colors.orange,
    ];

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RadioListTile<AppTheme>(
            value: AppTheme.system,
            groupValue: currentTheme,
            title: const Text("Theo hệ thống"),
            onChanged: (v) => onThemeChange(v!),
          ),
          RadioListTile<AppTheme>(
            value: AppTheme.light,
            groupValue: currentTheme,
            title: const Text("Sáng"),
            onChanged: (v) => onThemeChange(v!),
          ),
          RadioListTile<AppTheme>(
            value: AppTheme.dark,
            groupValue: currentTheme,
            title: const Text("Tối"),
            onChanged: (v) => onThemeChange(v!),
          ),
          RadioListTile<AppTheme>(
            value: AppTheme.oled,
            groupValue: currentTheme,
            title: const Text("OLED"),
            onChanged: (v) => onThemeChange(v!),
          ),
          const Divider(),
          Wrap(
            spacing: 8,
            children: colors
                .map((c) => GestureDetector(
              onTap: () => onColorChange(c),
              child: CircleAvatar(
                backgroundColor: c,
                child: currentColor == c
                    ? const Icon(Icons.check, color: Colors.white)
                    : null,
              ),
            ))
                .toList(),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
