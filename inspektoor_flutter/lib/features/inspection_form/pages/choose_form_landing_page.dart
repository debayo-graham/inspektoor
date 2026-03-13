import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'form_flow_tokens.dart';
import 'form_search_page.dart';
import '/pages/inspection_forms/create_inspection_form_page/create_inspection_form_page_widget.dart';

// ─── Screen 1 — Landing ───────────────────────────────────────────────────────
class ChooseFormLandingPage extends StatefulWidget {
  const ChooseFormLandingPage({super.key});

  static const String routeName = 'ChooseInspectionFormPage';
  static const String routePath = '/chooseInspectionFormPage';

  @override
  State<ChooseFormLandingPage> createState() => _ChooseFormLandingPageState();
}

class _ChooseFormLandingPageState extends State<ChooseFormLandingPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<String> _categories = [];
  bool _categoriesLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchCategories() async {
    try {
      final rows = await Supabase.instance.client
          .from('template_categories')
          .select('name')
          .eq('is_predefined', true)
          .order('sort_order', ascending: true);
      final names =
          (rows as List).map((r) => r['name'] as String).toList();
      if (mounted) {
        setState(() {
          _categories = ['All', ...names];
          _categoriesLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _categoriesLoading = false);
    }
  }

  void _openSearch({String category = 'All'}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FormSearchPage(
          initialQuery: _searchCtrl.text.trim(),
          initialCategory: category,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── App bar ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  const FormFlowBackButton(),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Create Inspection Form',
                        style: ffStyle(17, FontWeight.w800, kFormSlate8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 36),
                ],
              ),
            ),

            // ── Body ─────────────────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
                child: Column(
                  children: [
                    Text(
                      'Choose how to get started',
                      style: ffStyle(13, FontWeight.w600, kFormSlate4)
                          .copyWith(letterSpacing: 1.2),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    // ── Use Existing card ─────────────────────────────────
                    _UseExistingCard(
                      searchCtrl: _searchCtrl,
                      categories: _categories,
                      categoriesLoading: _categoriesLoading,
                      onBrowse: () => _openSearch(),
                      onCategoryTap: (cat) => _openSearch(category: cat),
                    ),

                    // ── or divider ────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Row(
                        children: [
                          const Expanded(child: Divider(color: kFormBorder)),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12),
                            child: Text('or',
                                style: ffStyle(
                                    12, FontWeight.w600, kFormSlate4)),
                          ),
                          const Expanded(child: Divider(color: kFormBorder)),
                        ],
                      ),
                    ),

                    // ── Build New row ─────────────────────────────────────
                    GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              const CreateInspectionFormPageWidget(),
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: kFormBorder, width: 2),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFFF0FDF4),
                                    Color(0xFFDCFCE7)
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.add_rounded,
                                  color: kFormGreen, size: 22),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Build New Form',
                                      style: ffStyle(
                                          15, FontWeight.w800, kFormSlate8)),
                                  const SizedBox(height: 2),
                                  Text(
                                      'Create a custom checklist from scratch',
                                      style: ffStyle(
                                          12, FontWeight.w400, kFormSlate4)),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded,
                                color: kFormBorder, size: 22),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Use Existing card ────────────────────────────────────────────────────────
class _UseExistingCard extends StatelessWidget {
  final TextEditingController searchCtrl;
  final List<String> categories;
  final bool categoriesLoading;
  final VoidCallback onBrowse;
  final ValueChanged<String> onCategoryTap;

  const _UseExistingCard({
    required this.searchCtrl,
    required this.categories,
    required this.categoriesLoading,
    required this.onBrowse,
    required this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: kFormBlue, width: 2),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: kFormBlue.withValues(alpha: 0.12),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFE0F2FE), Color(0xFFBAE6FD)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.description_outlined,
                          color: kFormBlue, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text('Use Existing Form',
                                    style: ffStyle(
                                        16, FontWeight.w800, kFormSlate8)),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0FDF4),
                                  border: Border.all(
                                      color: const Color(0xFFBBF7D0)),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Recommended',
                                  style: ffStyle(9, FontWeight.w800,
                                          kFormGreen)
                                      .copyWith(letterSpacing: 0.5),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            "Pick from a form that's already been configured",
                            style: ffStyle(12, FontWeight.w400, kFormSlate4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Search bar (interactive)
                Container(
                  decoration: BoxDecoration(
                    color: kFormBg,
                    border: Border.all(color: kFormBorder, width: 1.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 14),
                      const Icon(Icons.search_rounded,
                          color: kFormSlate4, size: 16),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: searchCtrl,
                          style: ffStyle(13, FontWeight.w500, kFormSlate7),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Search inspection forms…',
                            hintStyle:
                                ffStyle(13, FontWeight.w400, kFormSlate4),
                            isDense: true,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onSubmitted: (_) => onBrowse(),
                          textInputAction: TextInputAction.search,
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Category chips — horizontal scroll, loaded from DB
                if (categoriesLoading)
                  const SizedBox(
                    height: 30,
                    child: Center(
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            color: kFormBlue, strokeWidth: 2),
                      ),
                    ),
                  )
                else if (categories.isNotEmpty)
                  SizedBox(
                    height: 32,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final cat = categories[i];
                        return GestureDetector(
                          onTap: () => onCategoryTap(cat),
                          child: Container(
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F9FF),
                              border: Border.all(
                                  color: const Color(0xFFBAE6FD)),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(cat,
                                style:
                                    ffStyle(11, FontWeight.w600, kFormBlue)),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // Browse & Select button
          GestureDetector(
            onTap: onBrowse,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [kFormBlue, kFormBlueDk],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(22),
                  bottomRight: Radius.circular(22),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Browse & Select',
                      style: ffStyle(14, FontWeight.w700, Colors.white)),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded,
                      color: Colors.white, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
