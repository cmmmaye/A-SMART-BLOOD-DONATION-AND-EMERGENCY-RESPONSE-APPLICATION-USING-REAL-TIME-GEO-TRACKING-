import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../database/database_helper.dart';
import '../database/user_session.dart';
import '../utils/validators.dart';
import '../widgets/action_button.dart';

class AddNewsItem extends StatefulWidget {
  static const route = 'add-news';
  const AddNewsItem({Key? key}) : super(key: key);

  @override
  _AddNewsItemState createState() => _AddNewsItemState();
}

class _AddNewsItemState extends State<AddNewsItem> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add News Item')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextFormField(
                    controller: _titleController,
                    textCapitalization: TextCapitalization.sentences,
                    validator: (v) => Validators.required(v!, 'Title'),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Title',
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _bodyController,
                    textCapitalization: TextCapitalization.sentences,
                    minLines: 3,
                    maxLines: 5,
                    validator: (v) => Validators.required(v!, 'Body'),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Body',
                    ),
                  ),
                  const SizedBox(height: 36),
                  ActionButton(
                    callback: _submit,
                    text: 'Submit',
                    isLoading: _isLoading,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final userId = UserSession.getCurrentUserId();
        if (userId == null) {
          Fluttertoast.showToast(msg: 'Please login to add news');
          setState(() => _isLoading = false);
          return;
        }

        await DatabaseHelper.instance.createNews(
          userId: userId,
          title: _titleController.text,
          content: _bodyController.text,
        );
        _titleController.clear();
        _bodyController.clear();
        Fluttertoast.showToast(msg: 'News item successfully added');
        Navigator.pop(context);
      } catch (e) {
        debugPrint('Error adding news: $e');
        Fluttertoast.showToast(
          msg: 'Something went wrong. Please try again',
        );
      }
      setState(() => _isLoading = false);
    }
  }
}
