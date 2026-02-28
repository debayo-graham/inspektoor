// Automatic FlutterFlow imports
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import '/custom_code/actions/index.dart'; // Imports custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

class SelectableFormsList extends StatefulWidget {
  const SelectableFormsList({
    super.key,
    this.width,
    this.height,
    required this.forms,
    required this.selectedIds,
    required this.selectAll,
    required this.clearAll,
    required this.onChanged,
    this.onLoadMore,
  });

  final double? width;
  final double? height;
  final List<dynamic> forms;
  final List<String> selectedIds;
  final bool selectAll;
  final bool clearAll;
  final Future Function(List<String> seletedIds) onChanged;
  final Future Function()? onLoadMore;

  @override
  State<SelectableFormsList> createState() => _SelectableFormsListState();
}

class _SelectableFormsListState extends State<SelectableFormsList> {
  late List<String> selected;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    selected = List<String>.from(widget.selectedIds);

    _scrollController.addListener(_handleScroll);
  }

  @override
  void didUpdateWidget(covariant SelectableFormsList oldWidget) {
    super.didUpdateWidget(oldWidget);

    /// Trigger Select All
    if (widget.selectAll && !oldWidget.selectAll) {
      setState(() {
        selected = widget.forms.map((f) => f['id'] as String).toList();
      });
      widget.onChanged(selected);
    }

    /// Trigger Clear All
    if (widget.clearAll && !oldWidget.clearAll) {
      setState(() {
        selected = [];
      });
      widget.onChanged(selected);
    }
  }

  void toggle(String id) {
    setState(() {
      if (selected.contains(id)) {
        selected.remove(id);
      } else {
        selected.add(id);
      }
    });

    widget.onChanged(selected);
  }

  void _handleScroll() {
    if (widget.onLoadMore == null) return;

    final pos = _scrollController.position;

    // Trigger load more when within 200px of the bottom
    if (pos.pixels > pos.maxScrollExtent - 200) {
      widget.onLoadMore!();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width ?? double.infinity,
      height: widget.height, // nullable is fine
      child: ListView.builder(
        controller: _scrollController,
        itemCount: widget.forms.length,
        //shrinkWrap: false,
        //physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          final item = widget.forms[index];
          final id = item['id'] as String;
          final name = item['name'] ?? "";

          return CheckboxListTile(
            value: selected.contains(id),
            onChanged: (_) => toggle(id),
            title: Text(name),
          );
        },
      ),
    );
  }
}
