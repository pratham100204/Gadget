import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:gadget/models/item.dart';
import 'package:gadget/models/user.dart';
import 'package:gadget/services/crud.dart';
import 'package:gadget/utils/cache.dart';
import 'package:gadget/utils/form.dart';
import 'package:gadget/utils/image_store.dart';
import 'package:gadget/utils/window.dart';
import 'package:image/image.dart' as img;
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class ItemEntryForm extends StatefulWidget {
  final String? title;
  final Item? item;
  final bool? forEdit;

  ItemEntryForm({this.item, this.title, this.forEdit});

  @override
  State<StatefulWidget> createState() {
    return _ItemEntryFormState(this.item, this.title);
  }
}

class _ItemEntryFormState extends State<ItemEntryForm> {
  // Variables
  var _formKey = GlobalKey<FormState>();
  final double _minimumPadding = 5.0;
  static CrudHelper? crudHelper;
  static UserData? userData;

  String? title;
  Item? item;

  // Design Colors
  final Color _backgroundColor = const Color(0xFF000000);
  final Color _cardColor = const Color(0xFF1C1C1E);
  final Color _accentColor = const Color(0xFFFF3B30);
  final Color _textColor = Colors.white;
  final Color _subTextColor = Colors.grey;

  _ItemEntryFormState(this.item, this.title);

  List<String> _forms = ['Sales Entry', 'Stock Entry', 'Item Entry'];
  String? formName;
  String stringUnderName = '';
  String stringUnderNickName = '';
  String? _currentFormSelected;

  Map<String, double> units = {};
  TextEditingController itemNameController = TextEditingController();
  TextEditingController itemNickNameController = TextEditingController();
  TextEditingController markedPriceController = TextEditingController();
  TextEditingController totalStockController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController costPriceController = TextEditingController();
  Uint8List? _imageBytes;

  @override
  void initState() {
    this.formName = _forms[2];
    this._currentFormSelected = formName;
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    userData = Provider.of<UserData>(context);
    if (userData != null) {
      crudHelper = CrudHelper(userData: userData);
      _initiateItemData();
    }
  }

  void _initiateItemData() {
    if (this.item == null) {
      this.item = Item('');
    }

    if (this.item!.id != null) {
      this.itemNameController.text = '${item!.name}';
      this.itemNickNameController.text = '${item!.nickName ?? ''}';
      this.markedPriceController.text = this.item!.markedPrice ?? '';
      if (this.item!.totalStock != 0 && (userData!.checkStock ?? true)) {
        this.totalStockController.text = FormUtils.fmtToIntIfPossible(
          this.item!.totalStock,
        );
      }
      this.descriptionController.text = this.item!.description ?? '';
      // load saved image if any (use nickName or name as key)
      String key =
          this.item!.nickName?.isNotEmpty == true
              ? this.item!.nickName!
              : (this.item!.name ?? '');
      if (key.isNotEmpty) {
        ImageStore.loadImage(key).then((bytes) {
          if (bytes != null) setState(() => _imageBytes = bytes);
        });
      }
    }
  }

  // --- UI Builder ---
  @override
  Widget build(BuildContext context) {
    // We replace CustomScaffold with a direct Scaffold to control the dark theme exactly
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Text(
          this.title ?? 'Item Entry',
          style: TextStyle(color: _textColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: _backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: _textColor),
      ),
      body: buildForm(context),
    );
  }

  Widget buildForm(BuildContext context) {
    return Column(
      children: <Widget>[
        // Styled Dropdown
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
              style: TextStyle(color: _textColor, fontSize: 16),
              icon: Icon(Icons.arrow_drop_down, color: _accentColor),
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
                  // Item Name
                  _buildStyledTextField(
                    label: "Item Name",
                    hint: "Name of the new item",
                    controller: this.itemNameController,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Item name is required';
                      }
                      return null;
                    },
                    onChanged: (String value) {
                      setState(() {
                        this.updateItemName();
                      });
                    },
                  ),
                  _buildErrorText(this.stringUnderName),

                  // Nick Name
                  SizedBox(height: 12),
                  _buildStyledTextField(
                    label: "Nick Name (ID)",
                    hint: "Short & unique [optional]",
                    controller: this.itemNickNameController,
                    onChanged: (String value) {
                      setState(() {
                        this.updateItemNickName();
                      });
                    },
                  ),
                  _buildErrorText(this.stringUnderNickName),

                  // Marked Price
                  SizedBox(height: 12),
                  Visibility(
                    visible:
                        (this.item!.id != null) ||
                        !(userData!.checkStock ?? true),
                    child: _buildStyledTextField(
                      label: "Marked Price",
                      hint: "Expected selling price",
                      controller: this.markedPriceController,
                      keyboardType: TextInputType.number,
                      onChanged: this.updateMarkedPrice,
                    ),
                  ),

                  // Total Stock
                  SizedBox(height: 12),
                  Visibility(
                    visible: this.totalStockController.text.isNotEmpty,
                    child: _buildStyledTextField(
                      label: "Total Stock",
                      controller: this.totalStockController,
                      keyboardType: TextInputType.number,
                      onChanged: this.updateTotalStock,
                    ),
                  ),

                  SizedBox(height: 16),

                  // Image Picker Section
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _cardColor,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      children: [
                        _imageBytes != null
                            ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.memory(
                                _imageBytes!,
                                width: 70,
                                height: 70,
                                fit: BoxFit.cover,
                              ),
                            )
                            : Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.black26,
                              ),
                              child: Icon(
                                Icons.add_a_photo,
                                color: _subTextColor,
                              ),
                            ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Item Image",
                                style: TextStyle(
                                  color: _textColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 5),
                              Row(
                                children: [
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _accentColor,
                                      shape: StadiumBorder(),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                    ),
                                    child: Text(
                                      'Pick',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    onPressed: _pickImage,
                                  ),
                                  if (_imageBytes != null)
                                    TextButton(
                                      onPressed: () async {
                                      // Delete image from storage
                                      String key =
                                          this.item!.nickName?.isNotEmpty == true
                                              ? this.item!.nickName!
                                              : (this.item!.name ?? '');
                                      if (key.isNotEmpty) {
                                        await ImageStore.removeImage(key);
                                      }
                                      setState(() => _imageBytes = null);
                                    },
                                    child: Text(
                                      'Remove',
                                      style: TextStyle(color: Colors.red),
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

                  SizedBox(height: 16),

                  // Description
                  _buildStyledTextField(
                    label: "Description",
                    hint: "Any additional info",
                    controller: this.descriptionController,
                    maxLines: 3,
                    onChanged: this.updateDescription,
                  ),

                  // Units Header
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        'Units',
                        style: TextStyle(
                          color: _textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton.icon(
                        icon: Icon(Icons.add, color: _accentColor),
                        label: Text(
                          'Add Unit',
                          style: TextStyle(color: _accentColor),
                        ),
                        onPressed: () {
                          setState(() {
                            showDialogForUnits();
                          });
                        },
                      ),
                    ],
                  ),

                  this.showUnitsMapping(),

                  // Save and Delete Buttons
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
                        if (this.item!.id != null) ...[
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

  // --- Helper Widgets for Styles ---

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

  Widget _buildErrorText(String text) {
    if (text.isEmpty) return SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(top: 5, left: 10),
      child: Text(text, style: TextStyle(color: Colors.red, fontSize: 12)),
    );
  }

  Future<void> _pickImage() async {
    final XFile? file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 2400,
    );
    if (file != null) {
      String imagePath = file.path;
      // Note: ImageCropper UI settings updated for dark theme
      try {
        CroppedFile? croppedFile = await ImageCropper().cropImage(
          sourcePath: file.path,
          compressFormat: ImageCompressFormat.jpg,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Crop Image',
              toolbarColor: _backgroundColor,
              toolbarWidgetColor: Colors.white,
              statusBarColor: _backgroundColor,
              backgroundColor: _backgroundColor,
              activeControlsWidgetColor: _accentColor,
              initAspectRatio: CropAspectRatioPreset.square,
              lockAspectRatio: false,
            ),
            IOSUiSettings(title: 'Crop'),
          ],
        );
        if (croppedFile != null) {
          imagePath = croppedFile.path;
        }
      } catch (e) {
        // Fallback if cropper fails - use original image
        debugPrint('Image cropper failed, using original image: $e');
      }

      try {
        Uint8List bytes = await File(imagePath).readAsBytes();
        img.Image? decoded = img.decodeImage(bytes);
        if (decoded != null) {
          img.Image resized = img.copyResize(decoded, width: 800);
          Uint8List jpg = Uint8List.fromList(
            img.encodeJpg(resized, quality: 80),
          );
          setState(() => _imageBytes = jpg);
        } else {
          setState(() => _imageBytes = bytes);
        }
      } catch (e) {
        debugPrint('Image processing failed: $e');
        try {
          Uint8List bytes = await file.readAsBytes();
          setState(() => _imageBytes = bytes);
        } catch (e) {
          debugPrint('Failed to read image bytes: $e');
          // Show error to user
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to load image. Please try again.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    }
  }

  // --- Logic Methods (Kept largely unchanged) ---

  void updateItemName() {
    String name = this.itemNameController.text;
    Future<Item?> itemFuture = crudHelper!.getItem("name", name);
    itemFuture.then(
      (item) {
        if (item != null) {
          this.stringUnderName = 'Name already exists';
        } else {
          this.stringUnderName = '';
        }
      },
      onError: (e) {
        debugPrint('UpdateitemName Error::  $e');
      },
    );
  }

  void updateItemNickName() {
    String nickName = this.itemNickNameController.text;
    Future<Item?> itemFuture = crudHelper!.getItem("nick_name", nickName);
    itemFuture.then(
      (item) {
        if (item != null) {
          this.stringUnderNickName = 'Nick name already exists';
        } else {
          this.stringUnderNickName = '';
        }
      },
      onError: (e) {
        debugPrint('UpdateitemNickName Error::  $e');
      },
    );
  }

  void updateMarkedPrice(String val) {
    this.item!.markedPrice = val;
  }

  void updateTotalStock(String val) {
    this.item!.totalStock = double.tryParse(val) ?? 0.0;
  }

  void updateDescription(String val) {
    this.item!.description = val;
  }

  void checkAndSave() {
    debugPrint("Save button clicked");
    if (this._formKey.currentState!.validate()) {
      debugPrint("validated");
      this._save();
    }
  }

  void _save() async {
    this.item!.name = this.itemNameController.text;
    this.item!.nickName = this.itemNickNameController.text;
    this.item!.markedPrice = this.markedPriceController.text;
    this.item!.description = this.descriptionController.text;

    String message = '';
    if (this.item!.id == null) {
      int result = await crudHelper!.addItem(this.item!);
      if (result == 0) {
        message = 'Failed to create item';
      }
    } else {
      int result = await crudHelper!.updateItem(this.item!);
      if (result == 0) {
        message = 'Failed to update item';
      }
    }
    // persist image in shared preferences (if chosen)
    if (_imageBytes != null) {
      String key =
          this.item!.nickName?.isNotEmpty == true
              ? this.item!.nickName!
              : (this.item!.name ?? '');
      if (key.isNotEmpty) {
        await ImageStore.saveImage(key, _imageBytes!);
      }
    }
    this.saveCallback(message);
  }

  void saveCallback(String message) {
    if (message.isEmpty) {
      this.clearFieldsAndItem();
      refreshItemMapCache();
      // Navigate back with success flag
      Navigator.pop(context, true);
      WindowUtils.showAlertDialog(
        this.context,
        'Status',
        'Item saved successfully',
      );
    } else {
      WindowUtils.showAlertDialog(this.context, 'Failed!', message);
    }
  }

  void clearFieldsAndItem() {
    this.itemNameController.text = '';
    this.itemNickNameController.text = '';
    this.markedPriceController.text = '';
    this.totalStockController.text = '';
    this.descriptionController.text = '';
    this.item!.units = {};
    this.item = Item('');
    setState(() => _imageBytes = null);
  }

  void _delete() async {
    if (this.item!.id == null) {
      WindowUtils.showAlertDialog(context, "Status", 'Item not created');
      return;
    }
    WindowUtils.showAlertDialog(
      context,
      "Delete?",
      "This action is very dangerous and you may lose vital information. Delete?",
      onPressed: (buildContext) async {
        // Close confirmation dialog
        Navigator.pop(context);
        
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(_accentColor),
            ),
          ),
        );
        
        try {
          // Delete item
          await crudHelper!.deleteItem(this.item!.id!);
          
          // Delete associated image if exists
          String key = this.item!.nickName?.isNotEmpty == true
              ? this.item!.nickName!
              : (this.item!.name ?? '');
          if (key.isNotEmpty) {
            await ImageStore.removeImage(key);
          }
          
          // Close loading dialog
          Navigator.pop(context);
          
          // Navigate back with success flag
          Navigator.pop(context, true);
          
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Item deleted successfully'),
              backgroundColor: Colors.green,
              duration: Duration(milliseconds: 1500),
            ),
          );
        } catch (e) {
          // Close loading dialog
          Navigator.pop(context);
          
          // Show error message
          WindowUtils.showAlertDialog(
            context,
            'Error',
            'Failed to delete item: ${e.toString()}',
          );
        }
      },
    );
  }

  void refreshItemMapCache() async {
    await StartupCache(userData: userData!, reload: true).itemMap;
  }

  Widget showUnitsMapping() {
    double _minimumPadding = 5.0;
    return this.item!.units?.isNotEmpty ?? false
        ? Padding(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: ListView.builder(
            physics: NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: this.item!.units!.keys.length,
            itemBuilder: (BuildContext context, int index) {
              String name = this.item!.units!.keys.toList()[index];
              double quantity = double.parse("${this.item!.units![name]}");
              return Container(
                margin: EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: _cardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  title: Text(name, style: TextStyle(color: Colors.white)),
                  subtitle: Text(
                    FormUtils.fmtToIntIfPossible(quantity),
                    style: TextStyle(color: _accentColor),
                  ),
                  trailing: Icon(Icons.edit, color: _subTextColor),
                  onTap: () {
                    setState(() {
                      showDialogForUnits(name: name, quantity: quantity);
                    });
                  },
                ),
              );
            },
          ),
        )
        : Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: Text(
            "No units added yet.",
            style: TextStyle(color: _subTextColor, fontStyle: FontStyle.italic),
          ),
        );
  }

  void showDialogForUnits({String? name, double? quantity}) {
    final _unitFormKey = GlobalKey<FormState>();

    // Custom Dialog Style
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: _cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: SingleChildScrollView(
              child: Form(
                key: _unitFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      "Add Units",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 20),

                    TextFormField(
                      initialValue: name ?? '',
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "Unit name",
                        labelStyle: TextStyle(color: _subTextColor),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: _subTextColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: _accentColor),
                        ),
                      ),
                      onChanged: (val) => setState(() => name = val),
                      validator:
                          (val) => (val?.isEmpty ?? false) ? "Required" : null,
                    ),
                    SizedBox(height: 15),
                    TextFormField(
                      initialValue: FormUtils.fmtToIntIfPossible(quantity),
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "Quantity",
                        labelStyle: TextStyle(color: _subTextColor),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: _subTextColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: _accentColor),
                        ),
                      ),
                      validator: (val) {
                        if (val?.isEmpty ?? false) return "Required";
                        try {
                          quantity = double.parse(val!).abs();
                          return null;
                        } catch (e) {
                          return "Invalid";
                        }
                      },
                    ),
                    SizedBox(height: 25),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _accentColor,
                            ),
                            child: Text(
                              'Add',
                              style: TextStyle(color: Colors.white),
                            ),
                            onPressed: () async {
                              if (_unitFormKey.currentState!.validate()) {
                                if (this.item!.units == null) {
                                  this.item!.units = {};
                                }
                                this.item!.units![name!] = quantity!;
                                setState(() => Navigator.pop(context));
                              }
                            },
                          ),
                        ),
                        if (name != null &&
                            name!.isNotEmpty &&
                            this.item!.units!.containsKey(name)) ...[
                          SizedBox(width: 10),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              this.item!.units!.remove(name);
                              setState(() => Navigator.pop(context));
                            },
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
