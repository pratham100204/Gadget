import 'package:flutter/material.dart';
import 'package:gadget/models/item.dart';
import 'package:gadget/models/transaction.dart';
import 'package:gadget/models/user.dart';
import 'package:gadget/services/crud.dart';
import 'package:gadget/utils/cache.dart';
import 'package:gadget/utils/form.dart';
import 'package:gadget/utils/loading.dart';
import 'package:gadget/utils/window.dart';
import 'package:provider/provider.dart';

class SalesEntryForm extends StatefulWidget {
  final String? title;
  final ItemTransaction? transaction;
  final bool? forEdit;
  final Item? swipeData;

  SalesEntryForm({this.title, this.transaction, this.forEdit, this.swipeData});

  @override
  State<StatefulWidget> createState() {
    return _SalesEntryFormState(this.title, this.transaction);
  }
}

class _SalesEntryFormState extends State<SalesEntryForm> {
  // Variables
  String? title;
  ItemTransaction? transaction;
  _SalesEntryFormState(this.title, this.transaction);

  var _formKey = GlobalKey<FormState>();
  final double _minimumPadding = 5.0;
  List<String> _forms = ['Sales Entry', 'Stock Entry', 'Item Entry'];
  String? formName;
  String? _currentFormSelected;

  static CrudHelper? crudHelper;
  static UserData? userData;
  List<Map<String, String>> itemNamesAndNicknames = [];
  String disclaimerText = '';
  String stringUnderName = '';
  String? tempItemId;
  bool enableAdvancedFields = false;

  List<String> units = [];
  String selectedUnit = '';
  TextEditingController itemNameController = TextEditingController();
  TextEditingController itemNumberController = TextEditingController();
  TextEditingController sellingPriceController = TextEditingController();
  TextEditingController duePriceController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController costPriceController = TextEditingController();

  String amountInfo = '';

  // Design Colors
  final Color _backgroundColor = const Color(0xFF000000);
  final Color _cardColor = const Color(0xFF1C1C1E);
  final Color _accentColor = const Color(0xFFFF3B30);
  final Color _textColor = Colors.white;
  final Color _subTextColor = Colors.grey;

  @override
  void initState() {
    super.initState();
    this.formName = _forms[0];
    this._currentFormSelected = this.formName;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    userData = Provider.of<UserData>(context);
    if (userData != null) {
      crudHelper = CrudHelper(userData: userData);
      _initiateTransactionData();
      _initializeItemNamesAndNicknamesMapCache();
    } else {
      Loading();
    }
  }

  void _initiateTransactionData() {
    if (this.transaction == null) {
      this.transaction = ItemTransaction(0, null, 0.0, 0.0, '');
    }
    if (this.widget.swipeData != null) {
      Item item = this.widget.swipeData!;
      this.units = item.units?.keys.toList() ?? [];
      if (this.units.isNotEmpty) {
        this.units.add('');
      }
    }

    if (this.transaction!.id != null) {
      this.itemNumberController.text = FormUtils.fmtToIntIfPossible(
        this.transaction!.items,
      );
      this.sellingPriceController.text = FormUtils.fmtToIntIfPossible(
        this.transaction!.amount,
      );
      this.costPriceController.text = FormUtils.fmtToIntIfPossible(
        this.transaction!.costPrice,
      );
      this.descriptionController.text = this.transaction!.description ?? '';
      this.duePriceController.text = FormUtils.fmtToIntIfPossible(
        this.transaction!.dueAmount,
      );
      if (this.descriptionController.text.isNotEmpty ||
          (this.transaction!.dueAmount ?? 0.0) != 0.0) {
        setState(() {
          this.enableAdvancedFields = true;
        });
      }

      Future<Item?> itemFuture = crudHelper!.getItemById(
        this.transaction!.itemId!,
      );
      itemFuture.then((item) {
        if (item == null) {
          setState(() {
            this.disclaimerText =
                'Orphan Transaction: The item associated with this transaction has been deleted';
          });
        } else {
          this.itemNameController.text = '${item.name}';
          this.tempItemId = item.id;
          this._addUnitsIfPresent(item);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: _textColor),
        title: Text(
          this.title ?? 'Sales Entry',
          style: TextStyle(color: _textColor, fontWeight: FontWeight.bold),
        ),
      ),
      body: buildForm(context),
    );
  }

  Widget buildForm(BuildContext context) {
    return Column(
      children: <Widget>[
        // Styled Page Switcher Dropdown
        Container(
          margin: EdgeInsets.all(16),
          padding: EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              dropdownColor: _cardColor,
              isExpanded: true,
              icon: Icon(Icons.arrow_drop_down, color: _accentColor),
              style: TextStyle(color: _textColor, fontSize: 16),
              items:
                  _forms.map((String dropDownStringItem) {
                    return DropdownMenuItem<String>(
                      value: dropDownStringItem,
                      child: Text(dropDownStringItem),
                    );
                  }).toList(),
              onChanged: (String? newValueSelected) {
                WindowUtils.navigateToPage(
                  context,
                  caller: this.formName!,
                  target: newValueSelected!,
                );
              },
              value: _currentFormSelected,
            ),
          ),
        ),

        Expanded(
          child: Form(
            key: this._formKey,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: ListView(
                children: <Widget>[
                  // Disclaimer
                  Visibility(
                    visible: this.disclaimerText.isNotEmpty,
                    child: Container(
                      padding: EdgeInsets.all(12),
                      margin: EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        this.disclaimerText,
                        style: TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  ),

                  // Item Name (Autocomplete or Text Field)
                  Visibility(
                    visible: this.widget.swipeData == null ? true : false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Item Name",
                          style: TextStyle(color: _subTextColor, fontSize: 14),
                        ),
                        SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: _cardColor,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Autocomplete<Map<String, String>>(
                            optionsBuilder: (
                              TextEditingValue textEditingValue,
                            ) {
                              if (textEditingValue.text == '') {
                                return const Iterable<
                                  Map<String, String>
                                >.empty();
                              }
                              return itemNamesAndNicknames.where((
                                Map<String, String> option,
                              ) {
                                return option['name']!.toLowerCase().contains(
                                  textEditingValue.text.toLowerCase(),
                                );
                              });
                            },
                            displayStringForOption:
                                (Map<String, String> option) => option['name']!,
                            fieldViewBuilder: (
                              BuildContext context,
                              TextEditingController fieldTextEditingController,
                              FocusNode fieldFocusNode,
                              VoidCallback onFieldSubmitted,
                            ) {
                              // Sync logic controller with autocomplete controller
                              if (this.itemNameController.text !=
                                      fieldTextEditingController.text &&
                                  fieldTextEditingController.text.isEmpty) {
                                fieldTextEditingController.text =
                                    this.itemNameController.text;
                              }

                              return TextFormField(
                                controller: fieldTextEditingController,
                                focusNode: fieldFocusNode,
                                style: TextStyle(color: _textColor),
                                decoration: InputDecoration(
                                  hintText: "Search item...",
                                  hintStyle: TextStyle(
                                    color: Colors.grey.shade700,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                ),
                                onChanged: (val) {
                                  this.itemNameController.text = val;
                                  setState(() {
                                    this.updateItemName();
                                  });
                                },
                                validator: (val) {
                                  if (val!.isEmpty) return "Required";
                                  return null;
                                },
                              );
                            },
                            onSelected: (Map<String, String> selection) {
                              this.itemNameController.text = selection['name']!;
                              setState(() {
                                this.updateItemName();
                              });
                            },
                            optionsViewBuilder: (context, onSelected, options) {
                              return Align(
                                alignment: Alignment.topLeft,
                                child: Material(
                                  color: _cardColor,
                                  elevation: 4.0,
                                  child: Container(
                                    width:
                                        MediaQuery.of(context).size.width - 32,
                                    child: ListView.builder(
                                      padding: EdgeInsets.zero,
                                      shrinkWrap: true,
                                      itemCount: options.length,
                                      itemBuilder: (
                                        BuildContext context,
                                        int index,
                                      ) {
                                        final option = options.elementAt(index);
                                        return ListTile(
                                          title: Text(
                                            option['name']!,
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                          subtitle: Text(
                                            option['nickName'] ?? '',
                                            style: TextStyle(
                                              color: Colors.grey,
                                            ),
                                          ),
                                          onTap: () => onSelected(option),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Error text under name
                  if (stringUnderName.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: 5, left: 10, bottom: 10),
                      child: Text(
                        this.stringUnderName,
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),

                  // Units Dropdown
                  Visibility(
                    visible: this.units.isNotEmpty,
                    child: Container(
                      margin: EdgeInsets.only(top: 12),
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: _cardColor,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          dropdownColor: _cardColor,
                          isExpanded: true,
                          icon: Icon(
                            Icons.arrow_drop_down,
                            color: _accentColor,
                          ),
                          style: TextStyle(color: _textColor, fontSize: 16),
                          hint: Text(
                            "Select Unit",
                            style: TextStyle(color: _subTextColor),
                          ),
                          items:
                              this.units.map((dropDownStringItem) {
                                return DropdownMenuItem<String>(
                                  value: dropDownStringItem.toString(),
                                  child: Text(dropDownStringItem.toString()),
                                );
                              }).toList(),
                          onChanged: (value) {
                            setState(() => this.selectedUnit = value!);
                            _recomputeAmountInfo(); // Recompute price info on unit change
                          },
                          value: this.selectedUnit,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 12),

                  // No of items
                  _buildStyledTextField(
                    label: "No of Items",
                    hint: "Quantity sold",
                    controller: this.itemNumberController,
                    keyboardType: TextInputType.number,
                    onChanged: this.updateTransactionItems,
                    validator:
                        (val) => val!.isEmpty ? 'Please fill this field' : null,
                  ),

                  SizedBox(height: 12),

                  // Total Selling Price
                  _buildStyledTextField(
                    label: "Total Selling Price (₹)",
                    hint: "Total amount",
                    controller: this.sellingPriceController,
                    keyboardType: TextInputType.number,
                    onChanged: this.updateTransactionAmount,
                    validator:
                        (val) => val!.isEmpty ? 'Please fill this field' : null,
                  ),

                  // Amount Info Calculation
                  Visibility(
                    visible: amountInfo.isNotEmpty,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: 8.0,
                        horizontal: 8.0,
                      ),
                      child: Text(
                        amountInfo,
                        style: TextStyle(
                          color: _accentColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 12),

                  // Advanced Fields (Toggle)
                  Center(
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          this.enableAdvancedFields =
                              !this.enableAdvancedFields;
                        });
                      },
                      child: Text(
                        this.enableAdvancedFields
                            ? 'Hide Advanced Fields'
                            : 'Show Advanced Fields',
                        style: TextStyle(color: _accentColor),
                      ),
                    ),
                  ),

                  Visibility(
                    visible: this.enableAdvancedFields,
                    child: Column(
                      children: [
                        _buildStyledTextField(
                          label: "Cost Price",
                          controller: this.costPriceController,
                          keyboardType: TextInputType.number,
                          onChanged: this.updateTransactionCostPrice,
                        ),
                        SizedBox(height: 12),
                        _buildStyledTextField(
                          label: "Due Amount",
                          controller: this.duePriceController,
                          keyboardType: TextInputType.number,
                          onChanged: this.updateTransactionDueAmount,
                        ),
                        SizedBox(height: 12),
                        _buildStyledTextField(
                          label: "Description",
                          controller: this.descriptionController,
                          maxLines: 2,
                          onChanged: this.updateTransactionDescription,
                        ),
                      ],
                    ),
                  ),

                  // Buttons
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 30),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: SizedBox(
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _accentColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: Text(
                                "Save",
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onPressed: this.checkAndSave,
                            ),
                          ),
                        ),
                        if (this.transaction!.id != null) ...[
                          SizedBox(width: 16),
                          Expanded(
                            child: SizedBox(
                              height: 50,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF2C2C2E),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child: Text(
                                  "Delete",
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.red,
                                  ),
                                ),
                                onPressed: this._delete,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- Styled Helper Widget ---
  Widget _buildStyledTextField({
    required String label,
    String? hint,
    required TextEditingController controller,
    Function(String)? onChanged,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: _subTextColor, fontSize: 14)),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(15),
          ),
          child: TextFormField(
            controller: controller,
            onChanged: onChanged,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: TextStyle(color: _textColor),
            validator: validator,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey.shade700),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- Logic Methods (Unchanged) ---

  void updateItemName() {
    String name = this.itemNameController.text;
    Future<Item?> itemFuture = crudHelper!.getItem("name", name);
    itemFuture.then(
      (item) {
        if (item == null) {
          this.stringUnderName = 'Unregistered name';
          this.tempItemId = null;
          setState(() => this.units = []);
        } else {
          this.stringUnderName = '';
          this.tempItemId = item.id;
          setState(() => this._addUnitsIfPresent(item));
        }
      },
      onError: (e) {
        debugPrint('UpdateitemName Error::  $e');
      },
    );
  }

  void updateTransactionItems(String val) {
    _recomputeAmountInfo();
  }

  void updateTransactionAmount(String val) {
    _recomputeAmountInfo();
  }

  void updateTransactionCostPrice(String val) {}

  void updateTransactionDueAmount(String val) {}

  void updateTransactionDescription(String val) {}

  void _recomputeAmountInfo() {
    try {
      // Quantity considering selected unit multiplier
      double unitMultiple = 1.0;
      if (this.selectedUnit.isNotEmpty) {
        // Multiplier logic is in save, just visual here
      }

      double qty =
          (double.tryParse(this.itemNumberController.text) ?? 0).abs() *
          unitMultiple;
      double total =
          (double.tryParse(this.sellingPriceController.text) ?? 0).abs();
      if (qty > 0) {
        double unitPrice = total / qty;
        setState(
          () =>
              amountInfo =
                  "₹ ${FormUtils.fmtToIntIfPossible(total)} = ${FormUtils.fmtToIntIfPossible(qty)} × ₹ ${FormUtils.fmtToIntIfPossible(unitPrice)}",
        );
      } else {
        setState(() => amountInfo = '');
      }
    } catch (_) {
      setState(() => amountInfo = '');
    }
  }

  void clearFieldsAndTransaction() {
    this.itemNameController.text = '';
    this.itemNumberController.text = '';
    this.sellingPriceController.text = '';
    this.costPriceController.text = '';
    this.descriptionController.text = '';
    this.duePriceController.text = '';
    this.enableAdvancedFields = false;
    this.units = [];
    this.selectedUnit = '';
    this.transaction = ItemTransaction(0, null, 0.0, 0.0, '');
    setState(() => amountInfo = '');
  }

  void _addUnitsIfPresent(Item item) {
    if (item.units != null) {
      this.units = item.units!.keys.toList();
      this.units.add('');
    } else {
      this.units = [];
    }
  }

  void checkAndSave() {
    debugPrint("Save button clicked");
    if (this._formKey.currentState!.validate()) {
      debugPrint("validated");
      this._save();
    }
  }

  // Save data to database
  void _save() async {
    void _alertFail(message) {
      WindowUtils.showAlertDialog(context, "Failed!", message);
    }

    Item? item;
    if (this.widget.swipeData != null) {
      debugPrint("Using swipeData to save");
      item = this.widget.swipeData;
    } else {
      if (this.tempItemId == null) {
        _alertFail("Item not registered");
        return;
      }
      item = await crudHelper!.getItemById(this.tempItemId!).catchError((e) {
        return null;
      });
    }

    debugPrint("Saving sales item is $item");
    if (item == null) {
      _alertFail("Item not registered");
      return;
    }

    String itemId = item.id!;
    double unitMultiple = 1.0;
    if (this.selectedUnit != '') {
      if (item.units?.containsKey(this.selectedUnit) ?? false) {
        unitMultiple = item.units![this.selectedUnit]!;
      }
    }
    double items =
        double.parse(this.itemNumberController.text).abs() * unitMultiple;

    // Additional checks.
    if ((this.transaction!.id == null && this.transaction!.itemId != itemId) ||
        _beingApproved()) {
      // Case insert
      if ((userData!.checkStock ?? true) && item.totalStock < items) {
        _alertFail("Empty stock. Cannot sell.");
        return;
      }

      // Cp of transaction is set only once during insert.
      this.transaction!.costPrice = item.costPrice;
      item.decreaseStock(items);
    } else {
      // Case update
      debugPrint(
        "updating transaction and this is current stock ${item.totalStock} of ${item.name}",
      );
      double netAddition = items - this.transaction!.items!;

      if ((userData!.checkStock ?? true) && item.totalStock < netAddition) {
        _alertFail("Empty or insufficient stock.\nCannot sell.");
        return;
      } else {
        item.decreaseStock(netAddition);
      }
    }

    this.transaction!.itemId = itemId;
    this.transaction!.items = items;

    String message = await FormUtils.saveTransactionAndUpdateItem(
      this.transaction!,
      item,
      userData: userData!,
    );

    this.saveCallback(message);
  }

  bool _beingApproved() {
    return FormUtils.isDatabaseOwner(userData!) &&
        !FormUtils.isTransactionOwner(userData!, this.transaction!);
  }

  void _delete() async {
    if (this.transaction!.id == null) {
      this.clearFieldsAndTransaction();
      WindowUtils.showAlertDialog(context, "Status", 'Item not created');
      return;
    } else {
      Item? item = await crudHelper!.getItemById(this.transaction!.itemId!);
      WindowUtils.showAlertDialog(
        context,
        "Delete?",
        "This action is very dangerous and you may lose vital information. Delete?",
        onPressed: (buildContext) {
          FormUtils.deleteTransactionAndUpdateItem(
            this.saveCallback,
            this.transaction!,
            item!,
            userData!,
          );
        },
      );
    }
  }

  void saveCallback(String message) {
    if (message.isEmpty) {
      this.clearFieldsAndTransaction();
      if (this.widget.forEdit ?? false) {
        WindowUtils.moveToLastScreen(this.context, modified: true);
      }
      WindowUtils.showAlertDialog(
        this.context,
        "Status",
        'Sales updated successfully',
      );
    } else {
      WindowUtils.showAlertDialog(this.context, 'Failed!', message);
    }
  }

  void _initializeItemNamesAndNicknamesMapCache() async {
    Map<String, List<String>> itemMap = await StartupCache().itemMap;
    List<Map<String, String>> cacheItemAndNickNames = [];
    if (itemMap.isNotEmpty) {
      itemMap.forEach((key, value) {
        Map<String, String> nameNickNameMap = {
          'name': value.first,
          'nickName': value.last,
        };
        cacheItemAndNickNames.add(nameNickNameMap);
      });
    }
    setState(() {
      this.itemNamesAndNicknames = cacheItemAndNickNames;
    });
  }
}
