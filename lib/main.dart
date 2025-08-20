import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';

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
    return AnimatedTheme(
      duration: const Duration(milliseconds: 400),
      data: themeMode == ThemeMode.light
          ? lightTheme
          : (_themeMode == AppTheme.oled ? oledTheme : darkTheme),
      child: MaterialApp(
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
      ),
    );
  }
}

class Debt {
  String person;
  int amount;
  DateTime? loanDate;
  DateTime? dueDate;
  bool isPaid;
  String? imagePath;

  Debt({
    required this.person,
    required this.amount,
    this.loanDate,
    this.dueDate,
    this.isPaid = false,
    this.imagePath,
  });

  Map<String, dynamic> toJson() => {
    "person": person,
    "amount": amount,
    "loanDate": loanDate?.toIso8601String(),
    "dueDate": dueDate?.toIso8601String(),
    "isPaid": isPaid,
    "imagePath": imagePath,
  };

  factory Debt.fromJson(Map<String, dynamic> json) => Debt(
    person: json["person"],
    amount: json["amount"],
    loanDate: json["loanDate"] != null
        ? DateTime.tryParse(json["loanDate"])
        : null,
    dueDate:
    json["dueDate"] != null ? DateTime.tryParse(json["dueDate"]) : null,
    isPaid: json["isPaid"],
    imagePath: json["imagePath"],
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
      setState(() {
        debts.add(debt);
      });
      _saveDebts();
    }
  }

  void _showAppSnackBar(String message) {
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).colorScheme.onBackground;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: textColor)),
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _markAsPaid(Debt debt) {
    setState(() => debt.isPaid = true);
    _saveDebts();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Đã chuyển sang nợ đã trả 💲")),
    );
  }


  void _deleteDebt(Debt debt) {
    setState(() => debts.remove(debt));
    _saveDebts();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Đã xóa khoản nợ ")),
    );
  }


  void _editDebt(Debt debt) async {
    final updated = await showDialog<Debt>(
      context: context,
      builder: (_) => EditDebtDialog(debt: debt),
    );
    if (updated != null) {
      setState(() {
        debt.person = updated.person;
        debt.amount = updated.amount;
        debt.loanDate = updated.loanDate;
        debt.dueDate = updated.dueDate;
        debt.isPaid = updated.isPaid;
        debt.imagePath = updated.imagePath;
      });
      _saveDebts();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đã sửa khoản nợ ")),
      );
    }
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
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
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
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 8),
                            itemCount:
                            debts.where((d) => !d.isPaid).length,
                            itemBuilder: (context, index) {
                              final d = debts
                                  .where((d) => !d.isPaid)
                                  .toList()[index];
                              return DebtItem(
                                debt: d,
                                onDelete: () => _deleteDebt(d),
                                onPaid: () => _markAsPaid(d),
                                onEdit: () => _editDebt(d),
                              );
                            },
                            separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                          )
                              : const Center(child: Text("Chưa có nợ")),
                        ),
                      ],
                    ),
                    debts.any((d) => d.isPaid)
                        ? ListView(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 8),
                      children: debts
                          .where((d) => d.isPaid)
                          .map((d) => DebtItem(
                        debt: d,
                        onDelete: () => _deleteDebt(d),
                        onEdit: () => _editDebt(d),
                        isPaidList: true,
                      ))
                          .toList(),
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
  final VoidCallback onEdit;
  final bool isPaidList;

  const DebtItem({
    super.key,
    required this.debt,
    required this.onDelete,
    required this.onEdit,
    this.onPaid,
    this.isPaidList = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: ListTile(
        leading:
        const Icon(Icons.attach_money, size: 40, color: Colors.green),
        title: Text(
          "${debt.person} - "
              "${NumberFormat("#,###", "vi_VN").format(debt.amount).replaceAll(',', '.')} đ",
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (debt.loanDate != null)
              Text("Ngày vay: ${DateFormat("dd/MM/yyyy").format(debt.loanDate!)}"),
            if (debt.dueDate != null)
              Text("Ngày trả: ${DateFormat("dd/MM/yyyy").format(debt.dueDate!)}"),
          ],
        ),
        onTap: debt.imagePath != null
            ? () {
          showDialog(
            context: context,
            builder: (_) => Dialog(
              child: InteractiveViewer(
                child: Image.file(File(debt.imagePath!)),
              ),
            ),
          );
        }
            : null,
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == "delete") {
              onDelete();
            } else if (value == "paid" && !isPaidList) {
              onPaid?.call();
            } else if (value == "edit") {
              onEdit();
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: "delete",
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text("Xóa"),
                ],
              ),
            ),
            if (!isPaidList)
              const PopupMenuItem(
                value: "paid",
                child: Row(
                  children: [
                    Icon(Icons.attach_money, color: Colors.green),
                    SizedBox(width: 8),
                    Text("Đánh dấu đã trả"),
                  ],
                ),
              ),
            const PopupMenuItem(
              value: "edit",
              child: Row(
                children: [
                  Icon(Icons.edit, color: Colors.blue),
                  SizedBox(width: 8),
                  Text("Sửa"),
                ],
              ),
            ),
          ],
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
  String? _imagePath;

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

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _imagePath = picked.path);
    }
  }

  void _submit() {
    final person = _personCtrl.text.trim();
    final amountText = _amountCtrl.text.trim();
    if (person.isEmpty || amountText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng nhập tên và số tiền")),
      );
      return;
    }

    final amount = int.tryParse(amountText.replaceAll('.', '')) ?? 0;

    final debt = Debt(
      person: person,
      amount: amount,
      loanDate: _loanDate,
      dueDate: _dueDate,
      imagePath: _imagePath,
    );

    Navigator.pop(context, debt);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Thêm khoản nợ"),
      content: SingleChildScrollView(
        child: Column(
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
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.image),
              label: const Text("Chọn ảnh hóa đơn"),
            ),
            if (_imagePath != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Image.file(File(_imagePath!), height: 100),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy")),
        ElevatedButton(onPressed: _submit, child: const Text("Thêm")),
      ],
    );
  }
}

class EditDebtDialog extends StatefulWidget {
  final Debt debt;

  const EditDebtDialog({super.key, required this.debt});

  @override
  State<EditDebtDialog> createState() => _EditDebtDialogState();
}

class _EditDebtDialogState extends State<EditDebtDialog> {
  late TextEditingController _personCtrl;
  late TextEditingController _amountCtrl;
  DateTime? _loanDate;
  DateTime? _dueDate;
  String? _imagePath;

  @override
  void initState() {
    super.initState();
    _personCtrl = TextEditingController(text: widget.debt.person);
    _amountCtrl =
        TextEditingController(text: widget.debt.amount.toString());
    _loanDate = widget.debt.loanDate;
    _dueDate = widget.debt.dueDate;
    _imagePath = widget.debt.imagePath;
  }

  Future<void> _pickDate(bool isLoanDate) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
      initialDate: isLoanDate ? _loanDate ?? now : _dueDate ?? now,
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

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _imagePath = picked.path);
    }
  }

  void _submit() {
    final person = _personCtrl.text.trim();
    final amountText = _amountCtrl.text.trim();
    if (person.isEmpty || amountText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng nhập tên và số tiền")),
      );
      return;
    }

    final amount = int.tryParse(amountText.replaceAll('.', '')) ?? 0;

    final debt = Debt(
      person: person,
      amount: amount,
      loanDate: _loanDate,
      dueDate: _dueDate,
      isPaid: widget.debt.isPaid,
      imagePath: _imagePath,
    );

    Navigator.pop(context, debt);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Sửa khoản nợ"),
      content: SingleChildScrollView(
        child: Column(
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
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.image),
              label: const Text("Chọn ảnh hóa đơn"),
            ),
            if (_imagePath != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Image.file(File(_imagePath!), height: 100),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy")),
        ElevatedButton(onPressed: _submit, child: const Text("Lưu")),
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
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Chọn giao diện", style: TextStyle(fontSize: 18)),
          Wrap(
            children: AppTheme.values
                .map((t) => ChoiceChip(
              label: Text(t.name),
              selected: currentTheme == t,
              onSelected: (_) => onThemeChange(t),
            ))
                .toList(),
          ),
          const SizedBox(height: 16),
          const Text("Chọn màu chủ đạo", style: TextStyle(fontSize: 18)),
          Wrap(
            spacing: 8,
            children: Colors.primaries
                .map((c) => ChoiceChip(
              label: Container(
                width: 24,
                height: 24,
                color: c,
              ),
              selected: currentColor == c,
              onSelected: (_) => onColorChange(c),
            ))
                .toList(),
          ),
        ],
      ),
    );
  }
}
