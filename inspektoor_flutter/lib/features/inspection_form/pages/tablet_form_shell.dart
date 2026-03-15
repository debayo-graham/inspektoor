import 'dart:async';

import 'package:flutter/material.dart';

import '/backend/api_requests/api_calls.dart';
import '/backend/supabase/supabase.dart';
import '/common/components/confirm_action_dialog.dart';
import '/features/asset_selection/pages/select_asset_page.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/dashboard/home_page/home_page_widget.dart';
import '/pages/inspection_forms/create_inspection_form_page/create_inspection_form_page_widget.dart';
import '/pages/inspection_forms/edit_inspection_form_page/edit_inspection_form_page_widget.dart';
import '/features/inspection_form/components/form_flow_step_bar.dart';
import '/features/inspection_form/components/form_header_card.dart';
import '/features/inspection_form/components/step_accordion_row.dart';
import 'form_flow_tokens.dart';
import 'form_preview_screen.dart';

// ─── Step enum ───────────────────────────────────────────────────────────────
enum _TabletStep { landing, search, details, confirmed }

// ─── Tablet Form Shell ───────────────────────────────────────────────────────
/// Single-page split-panel layout for the Create Inspection Form flow on
/// tablet (≥768px). Contains a gradient sidebar with step progress and a
/// right content area that swaps per step.
class TabletFormShell extends StatefulWidget {
  const TabletFormShell({super.key});

  @override
  State<TabletFormShell> createState() => _TabletFormShellState();
}

class _TabletFormShellState extends State<TabletFormShell>
    with TickerProviderStateMixin {
  _TabletStep _step = _TabletStep.landing;

  // ── Categories (shared landing + search) ─────────────────────────────────
  List<String> _categories = [];
  bool _categoriesLoading = true;

  // ── Search state ─────────────────────────────────────────────────────────
  final TextEditingController _searchCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  Timer? _debounce;
  String _selectedCategory = 'All';
  List<Map<String, dynamic>> _results = [];
  bool _searchLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _offset = 0;
  static const int _pageSize = 25;

  // ── Selected form + schema ───────────────────────────────────────────────
  Map<String, dynamic>? _selectedForm;
  List<Map<String, dynamic>> _schemaSteps = [];
  bool _schemaLoading = false;
  int? _openStepIndex; // accordion in details panel

  // ── Duplicated form ──────────────────────────────────────────────────────
  Map<String, dynamic>? _duplicatedForm;
  bool _duplicating = false;

  // ── Recently used forms (landing) ────────────────────────────────────────
  List<Map<String, dynamic>> _recentForms = [];

  // ── Confirmed animations ─────────────────────────────────────────────────
  AnimationController? _ringCtrl;
  AnimationController? _checkCtrl;
  AnimationController? _contentCtrl;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    _fetchCategories();
    _fetchRecentForms();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    _ringCtrl?.dispose();
    _checkCtrl?.dispose();
    _contentCtrl?.dispose();
    super.dispose();
  }

  // ── Data fetching ────────────────────────────────────────────────────────

  Future<void> _fetchCategories() async {
    try {
      final rows = await Supabase.instance.client
          .from('template_categories')
          .select('name')
          .eq('is_predefined', true)
          .order('sort_order', ascending: true);
      final names = (rows as List).map((r) => r['name'] as String).toList();
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

  Future<void> _fetchRecentForms() async {
    try {
      final orgId = FFAppState().currentOrgId;
      final rows = await Supabase.instance.client
          .from('inspection_templates')
          .select('id, name, category, schema, created_at, category_id, version')
          .eq('org_id', orgId)
          .eq('is_predefined', false)
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .limit(3);
      if (mounted) {
        setState(() {
          _recentForms =
              (rows as List).whereType<Map<String, dynamic>>().toList();
        });
      }
    } catch (_) {
      // silent — landing still works without recent forms
    }
  }

  Future<String> _freshToken() async {
    final supabase = Supabase.instance.client;
    try {
      await supabase.auth.refreshSession();
    } catch (_) {}
    return supabase.auth.currentSession?.accessToken ?? '';
  }

  Future<void> _fetchSearch() async {
    if (!mounted) return;
    setState(() {
      _searchLoading = true;
      _offset = 0;
      _hasMore = true;
    });

    final token = await _freshToken();
    final orgId = FFAppState().currentOrgId;
    final category = _selectedCategory == 'All' ? '' : _selectedCategory;

    final response = await SearchInspectionFormTemplatesCall.call(
      pOrg: orgId,
      pScope: 'predefined',
      pQ: _searchCtrl.text.trim(),
      pCategory: category,
      pLimit: _pageSize,
      pOffset: 0,
      pSortBy: 'created_at',
      pSortDir: 'desc',
      userAccessToken: token,
    );

    if (!mounted) return;

    List<Map<String, dynamic>> parsed = [];
    if (response.succeeded) {
      try {
        final decoded = jsonDecode(response.bodyText);
        if (decoded is List) {
          parsed = decoded.whereType<Map<String, dynamic>>().toList();
        }
      } catch (_) {}
    }

    setState(() {
      _results = parsed;
      _searchLoading = false;
      _hasMore = parsed.length >= _pageSize;
    });
  }

  Future<void> _fetchMore() async {
    if (!mounted) return;
    setState(() => _isLoadingMore = true);

    final token = await _freshToken();
    final orgId = FFAppState().currentOrgId;
    final category = _selectedCategory == 'All' ? '' : _selectedCategory;
    final nextOffset = _offset + _pageSize;

    final response = await SearchInspectionFormTemplatesCall.call(
      pOrg: orgId,
      pScope: 'predefined',
      pQ: _searchCtrl.text.trim(),
      pCategory: category,
      pLimit: _pageSize,
      pOffset: nextOffset,
      pSortBy: 'created_at',
      pSortDir: 'desc',
      userAccessToken: token,
    );

    if (!mounted) return;

    List<Map<String, dynamic>> parsed = [];
    if (response.succeeded) {
      try {
        final decoded = jsonDecode(response.bodyText);
        if (decoded is List) {
          parsed = decoded.whereType<Map<String, dynamic>>().toList();
        }
      } catch (_) {}
    }

    setState(() {
      _results.addAll(parsed);
      _offset = nextOffset;
      _hasMore = parsed.length >= _pageSize;
      _isLoadingMore = false;
    });
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
            _scrollCtrl.position.maxScrollExtent - 300 &&
        !_searchLoading &&
        !_isLoadingMore &&
        _hasMore) {
      _fetchMore();
    }
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), _fetchSearch);
  }

  void _selectCategory(String cat) {
    if (_selectedCategory == cat) return;
    setState(() => _selectedCategory = cat);
    _fetchSearch();
  }

  Future<void> _fetchSchema(Map<String, dynamic> form) async {
    setState(() {
      _selectedForm = form;
      _schemaLoading = true;
      _schemaSteps = [];
      _openStepIndex = null;
    });

    try {
      final id = form['id'] as String?;
      if (id == null) throw Exception('Missing template id');

      final response = await Supabase.instance.client
          .from('inspection_templates')
          .select('schema')
          .eq('id', id)
          .single();

      final schema = response['schema'];
      List<dynamic> rawItems = [];

      if (schema is Map && schema.containsKey('items')) {
        rawItems = (schema['items'] as List?) ?? [];
      } else if (schema is List) {
        rawItems = schema;
      }

      final items = rawItems.whereType<Map<String, dynamic>>().toList()
        ..sort((a, b) => ((a['order'] as num?) ?? 0)
            .compareTo((b['order'] as num?) ?? 0));

      if (mounted) {
        setState(() {
          _schemaSteps = items;
          _schemaLoading = false;
          _step = _TabletStep.details;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _schemaLoading = false);
      }
    }
  }

  // ── Duplication ──────────────────────────────────────────────────────────

  Future<void> _confirmAndDuplicate() async {
    final form = _selectedForm;
    if (form == null) return;

    final confirmed = await ConfirmActionDialog.show(
      context,
      icon: Icons.file_copy_outlined,
      title: 'Use this form?',
      message:
          'This will add a copy of this form template to your organization.',
      confirmLabel: 'Use Form',
      themeColor: kFormBlue,
    );
    if (!confirmed || !mounted) return;

    setState(() => _duplicating = true);

    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      final orgId = FFAppState().currentOrgId;

      final newRow = await supabase
          .from('inspection_templates')
          .insert({
            'org_id': orgId,
            'name': form['name'] as String? ?? 'Untitled',
            'category_id': form['category_id'] as String?,
            'schema': form['schema'],
            'version': 1,
            'is_active': true,
            'is_predefined': false,
            'created_by': userId,
          })
          .select()
          .single();

      if (!mounted) return;
      setState(() {
        _duplicating = false;
        _duplicatedForm = newRow;
        _step = _TabletStep.confirmed;
      });
      _startConfirmAnimations();
    } catch (e) {
      if (!mounted) return;
      setState(() => _duplicating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add form: $e',
              style: ffStyle(13, FontWeight.w500, Colors.white)),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _startConfirmAnimations() {
    _ringCtrl?.dispose();
    _checkCtrl?.dispose();
    _contentCtrl?.dispose();

    _ringCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _checkCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _contentCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));

    _ringCtrl!.forward().then((_) {
      _checkCtrl!.forward();
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) _contentCtrl!.forward();
      });
    });
  }

  Future<void> _deleteDuplicate() async {
    final formId = _duplicatedForm?['id'] as String?;
    if (formId == null) return;
    try {
      await InspectionTemplatesTable().delete(
        matchingRows: (rows) => rows.eq('id', formId),
      );
    } catch (_) {}
  }

  void _changeForm() async {
    await _deleteDuplicate();
    if (!mounted) return;
    setState(() {
      _duplicatedForm = null;
      _selectedForm = null;
      _schemaSteps = [];
      _openStepIndex = null;
      _step = _TabletStep.search;
    });
  }

  void _startInspection() {
    final form = _duplicatedForm ?? _selectedForm;
    if (form == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SelectAssetPage(
          form: form,
          schemaItems: _schemaSteps,
        ),
      ),
    );
  }

  void _editForm() {
    final form = _duplicatedForm ?? _selectedForm;
    if (form == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditInspectionFormPageWidget(
          inspectionFormTemplateRow: form,
        ),
      ),
    );
  }

  void _done() {
    Navigator.of(context).popUntil((route) =>
        route.settings.name == HomePageWidget.routeName || route.isFirst);
  }

  // ── Navigation helpers ───────────────────────────────────────────────────

  void _goToSearch() {
    setState(() => _step = _TabletStep.search);
    if (_results.isEmpty) _fetchSearch();
  }

  void _selectForm(Map<String, dynamic> form) {
    _fetchSchema(form);
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _deleteDuplicate();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final isLandscape = constraints.maxWidth >= 1024;

            if (isLandscape) {
              // ── Landscape tablet: vertical sidebar + content ──────────
              return SafeArea(
                child: Row(
                  children: [
                    _buildSidebar(300),
                    Expanded(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            transitionBuilder: (child, animation) =>
                                FadeTransition(opacity: animation, child: child),
                            child: _buildContent(isLandscape: true),
                          ),
                          // ── X close — top-right of content area ──────
                          Positioned(
                            top: 24,
                            right: 32,
                            child: GestureDetector(
                              onTap: () async {
                                if (_duplicatedForm != null) {
                                  final confirmed = await ConfirmActionDialog.show(
                                    context,
                                    icon: Icons.close_rounded,
                                    title: 'Exit form setup?',
                                    message: 'Are you sure you want to exit? Any unsaved progress will be lost.',
                                    confirmLabel: 'Exit',
                                    themeColor: const Color(0xFFEF4444),
                                  );
                                  if (!confirmed || !mounted) return;
                                  await _deleteDuplicate();
                                }
                                if (!mounted) return;
                                Navigator.of(context).popUntil((route) => route.settings.name == HomePageWidget.routeName || route.isFirst);
                              },
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.close_rounded,
                                    color: kFormSlate5, size: 20),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }

            // ── Mobile + portrait tablet: horizontal step bar + content ─
            return Column(
              children: [
                FormFlowStepBar(
                  currentStepIndex: _step.index,
                  onBack: () async {
                    if (_step == _TabletStep.landing) {
                      if (_duplicatedForm != null) {
                        final confirmed = await ConfirmActionDialog.show(
                          context,
                          icon: Icons.close_rounded,
                          title: 'Exit form setup?',
                          message: 'Are you sure you want to exit? Any unsaved progress will be lost.',
                          confirmLabel: 'Exit',
                          themeColor: const Color(0xFFEF4444),
                        );
                        if (!confirmed || !mounted) return;
                        await _deleteDuplicate();
                      }
                      if (!mounted) return;
                      Navigator.of(context).popUntil((route) => route.settings.name == HomePageWidget.routeName || route.isFirst);
                    } else {
                      if (_duplicatedForm != null) {
                        await _deleteDuplicate();
                      }
                      if (!mounted) return;
                      setState(() {
                        _step = _TabletStep.values[_step.index - 1];
                      });
                    }
                  },
                  selectedForm: _selectedForm,
                  schemaStepCount: _schemaSteps.length,
                  onClose: () async {
                    if (_duplicatedForm != null) {
                      final confirmed = await ConfirmActionDialog.show(
                        context,
                        icon: Icons.close_rounded,
                        title: 'Exit form setup?',
                        message: 'Are you sure you want to exit? Any unsaved progress will be lost.',
                        confirmLabel: 'Exit',
                        themeColor: const Color(0xFFEF4444),
                      );
                      if (!confirmed || !mounted) return;
                      await _deleteDuplicate();
                    }
                    if (!mounted) return;
                    Navigator.of(context).popUntil((route) => route.settings.name == HomePageWidget.routeName || route.isFirst);
                  },
                ),
                Expanded(
                  child: SafeArea(
                    top: false,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, animation) =>
                          FadeTransition(opacity: animation, child: child),
                      child: _buildContent(isLandscape: false),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent({required bool isLandscape}) {
    return switch (_step) {
      _TabletStep.landing => _LandingContent(
          key: const ValueKey('landing'),
          categories: _categories,
          categoriesLoading: _categoriesLoading,
          recentForms: _recentForms,
          onBrowse: _goToSearch,
          onCategoryTap: (cat) {
            _selectedCategory = cat;
            _goToSearch();
          },
          onFormTap: _selectForm,
        ),
      _TabletStep.search => _SearchContent(
          key: const ValueKey('search'),
          searchCtrl: _searchCtrl,
          scrollCtrl: _scrollCtrl,
          categories: _categories,
          categoriesLoading: _categoriesLoading,
          selectedCategory: _selectedCategory,
          results: _results,
          loading: _searchLoading,
          isLoadingMore: _isLoadingMore,
          onSearchChanged: _onSearchChanged,
          onCategoryTap: _selectCategory,
          onFormTap: _selectForm,
        ),
      _TabletStep.details => _DetailsContent(
          key: const ValueKey('details'),
          form: _selectedForm!,
          steps: _schemaSteps,
          schemaLoading: _schemaLoading,
          duplicating: _duplicating,
          isLandscape: isLandscape,
          openStepIndex: _openStepIndex,
          onToggleStep: (i) =>
              setState(() => _openStepIndex = _openStepIndex == i ? null : i),
          onUseThisForm: _confirmAndDuplicate,
        ),
      _TabletStep.confirmed => _ConfirmedContent(
          key: const ValueKey('confirmed'),
          form: _duplicatedForm ?? _selectedForm!,
          schemaItems: _schemaSteps,
          ringCtrl: _ringCtrl,
          checkCtrl: _checkCtrl,
          contentCtrl: _contentCtrl,
          onStartInspection: _startInspection,
          onEditForm: _editForm,
          onChangeForm: _changeForm,
          onDone: _done,
        ),
    };
  }

  // ── Sidebar ──────────────────────────────────────────────────────────────

  Widget _buildSidebar(double width) {
    final steps = [
      (id: _TabletStep.landing, label: 'Get Started'),
      (id: _TabletStep.search, label: 'Select Form'),
      (id: _TabletStep.details, label: 'Review Steps'),
      (id: _TabletStep.confirmed, label: 'Confirm'),
    ];

    return Container(
      width: width,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kFormSidebarDk, kFormBlue],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Back button ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: GestureDetector(
              onTap: () async {
                if (_step == _TabletStep.landing) {
                  // Step 0 → go to dashboard (with cleanup if needed)
                  if (_duplicatedForm != null) {
                    final confirmed = await ConfirmActionDialog.show(
                      context,
                      icon: Icons.close_rounded,
                      title: 'Exit form setup?',
                      message: 'Are you sure you want to exit? Any unsaved progress will be lost.',
                      confirmLabel: 'Exit',
                      themeColor: const Color(0xFFEF4444),
                    );
                    if (!confirmed || !mounted) return;
                    await _deleteDuplicate();
                  }
                  if (!mounted) return;
                  Navigator.of(context).popUntil((route) => route.settings.name == HomePageWidget.routeName || route.isFirst);
                } else {
                  // Steps 1-3 → go to previous step (with cleanup if duplicate exists)
                  if (_duplicatedForm != null) {
                    await _deleteDuplicate();
                  }
                  if (!mounted) return;
                  setState(() {
                    _step = _TabletStep.values[_step.index - 1];
                  });
                }
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.chevron_left_rounded,
                        color: Colors.white, size: 22),
                  ),
                  if (_step == _TabletStep.landing) ...[
                    const SizedBox(width: 10),
                    Text('Dashboard',
                        style: ffStyle(15, FontWeight.w700, Colors.white70)),
                  ],
                ],
              ),
            ),
          ),

          // ── Title ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Text('Create Inspection Form',
                style: ffStyle(20, FontWeight.w800, Colors.white)),
          ),
          const SizedBox(height: 24),

          // ── Step indicators ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: steps.asMap().entries.map((e) {
                final i = e.key;
                final s = e.value;
                final isActive = _step == s.id;
                final isDone = _step.index > s.id.index;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.white.withValues(alpha: 0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: isDone
                                ? kFormGreen
                                : isActive
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: isDone
                                ? const Icon(Icons.check_rounded,
                                    color: Colors.white, size: 14)
                                : Text(
                                    '${i + 1}',
                                    style: ffStyle(
                                      12,
                                      FontWeight.w800,
                                      isActive
                                          ? kFormBlue
                                          : Colors.white.withValues(alpha: 0.5),
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          s.label,
                          style: ffStyle(
                            13,
                            FontWeight.w600,
                            isActive
                                ? Colors.white
                                : isDone
                                    ? Colors.white.withValues(alpha: 0.8)
                                    : Colors.white.withValues(alpha: 0.45),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // ── Selected form card ───────────────────────────────────────
          if (_selectedForm != null) ...[
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SELECTED FORM',
                      style:
                          ffStyle(12, FontWeight.w700, Colors.white54)
                              .copyWith(letterSpacing: 1.0),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            categoryIcon(
                                _selectedForm!['category'] as String?),
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedForm!['name'] as String? ??
                                    'Untitled',
                                style: ffStyle(
                                    13, FontWeight.w700, Colors.white),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${_schemaSteps.length} steps'
                                '${(_selectedForm!['category'] as String?) != null ? ' · ${_selectedForm!['category']}' : ''}',
                                style: ffStyle(
                                    12, FontWeight.w400, Colors.white60),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],

          const Spacer(),

          // ── Helper text ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Text(
              'Select a form to review its steps before starting your inspection.',
              style: ffStyle(12, FontWeight.w400, Colors.white38),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// LANDING CONTENT
// ═══════════════════════════════════════════════════════════════════════════════

class _LandingContent extends StatelessWidget {
  final List<String> categories;
  final bool categoriesLoading;
  final List<Map<String, dynamic>> recentForms;
  final VoidCallback onBrowse;
  final ValueChanged<String> onCategoryTap;
  final ValueChanged<Map<String, dynamic>> onFormTap;

  const _LandingContent({
    super.key,
    required this.categories,
    required this.categoriesLoading,
    required this.recentForms,
    required this.onBrowse,
    required this.onCategoryTap,
    required this.onFormTap,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(40, 32, 40, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CHOOSE HOW TO GET STARTED',
            style: ffStyle(13, FontWeight.w700, kFormSlate4)
                .copyWith(letterSpacing: 1.2),
          ),
          const SizedBox(height: 24),

          // ── Two-column grid ──────────────────────────────────────────
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Use Existing card
                Expanded(child: _buildExistingCard()),
                const SizedBox(width: 20),
                // Build New card
                Expanded(child: _buildNewCard(context)),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // ── Recently Used ────────────────────────────────────────────
          if (recentForms.isNotEmpty) ...[
            Text(
              'RECENTLY USED',
              style: ffStyle(12, FontWeight.w700, kFormSlate4)
                  .copyWith(letterSpacing: 1.2),
            ),
            const SizedBox(height: 12),
            ...recentForms.asMap().entries.map((e) {
              final form = e.value;
              final name = form['name'] as String? ?? 'Untitled';
              final category = form['category'] as String?;
              final schema = form['schema'];
              int stepCount = 0;
              if (schema is Map && schema.containsKey('items')) {
                stepCount = ((schema['items'] as List?) ?? []).length;
              } else if (schema is List) {
                stepCount = schema.length;
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: () => onFormTap(form),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: kFormBorder, width: 1.5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F9FF),
                            border:
                                Border.all(color: const Color(0xFFBAE6FD)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(categoryIcon(category),
                              color: kFormBlue, size: 18),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name,
                                  style: ffStyle(
                                      13, FontWeight.w700, kFormSlate8),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 2),
                              Text(
                                '$stepCount steps'
                                '${category != null ? ' · $category' : ''}'
                                ' · ${relativeTime(form['created_at'] as String?)}',
                                style:
                                    ffStyle(12, FontWeight.w400, kFormSlate4),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded,
                            color: kFormBorder, size: 18),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildExistingCard() {
    return GestureDetector(
      onTap: onBrowse,
      child: Container(
        clipBehavior: Clip.antiAlias,
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F9FF),
                      border: Border.all(color: const Color(0xFFBAE6FD)),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.description_outlined,
                        color: kFormBlue, size: 22),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Flexible(
                        child: Text('Use Existing Form',
                            style: ffStyle(17, FontWeight.w800, kFormSlate8)),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          border:
                              Border.all(color: const Color(0xFFBBF7D0)),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('Recommended',
                            style: ffStyle(12, FontWeight.w800, kFormGreen)
                                .copyWith(letterSpacing: 0.5)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Pick from a library of pre-configured inspection forms',
                    style: ffStyle(13, FontWeight.w400, kFormSlate4),
                  ),
                  const SizedBox(height: 14),
                  // Category preview chips
                  if (!categoriesLoading && categories.length > 1)
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: categories
                          .where((c) => c != 'All')
                          .take(3)
                          .map((cat) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0F9FF),
                                  border: Border.all(
                                      color: const Color(0xFFBAE6FD)),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(cat,
                                    style: ffStyle(
                                        12, FontWeight.w600, kFormBlue)),
                              ))
                          .toList(),
                    ),
                ],
              ),
            ),
            // Browse & Select button
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
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
          ],
        ),
      ),
    );
  }

  Widget _buildNewCard(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const CreateInspectionFormPageWidget(),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFF0FDF4), Color(0xFFDCFCE7)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.add_rounded,
                  color: kFormGreen, size: 22),
            ),
            const SizedBox(height: 16),
            Text('Build New Form',
                style: ffStyle(17, FontWeight.w800, kFormSlate8)),
            const SizedBox(height: 6),
            Text(
              'Create a custom checklist from scratch, step by step',
              style: ffStyle(13, FontWeight.w400, kFormSlate4),
            ),
            const Spacer(),
            Row(
              children: [
                Text('Get started',
                    style: ffStyle(15, FontWeight.w700, kFormGreen)),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right_rounded,
                    color: kFormGreen, size: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SEARCH CONTENT
// ═══════════════════════════════════════════════════════════════════════════════

class _SearchContent extends StatelessWidget {
  final TextEditingController searchCtrl;
  final ScrollController scrollCtrl;
  final List<String> categories;
  final bool categoriesLoading;
  final String selectedCategory;
  final List<Map<String, dynamic>> results;
  final bool loading;
  final bool isLoadingMore;
  final VoidCallback onSearchChanged;
  final ValueChanged<String> onCategoryTap;
  final ValueChanged<Map<String, dynamic>> onFormTap;

  const _SearchContent({
    super.key,
    required this.searchCtrl,
    required this.scrollCtrl,
    required this.categories,
    required this.categoriesLoading,
    required this.selectedCategory,
    required this.results,
    required this.loading,
    required this.isLoadingMore,
    required this.onSearchChanged,
    required this.onCategoryTap,
    required this.onFormTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Header ──────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 32, 32, 0),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Select Form',
                    style: ffStyle(20, FontWeight.w800, kFormSlate8)),
              ),
              const SizedBox(height: 16),

              // ── Search bar ─────────────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: kFormBlue, width: 2),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: kFormBlue.withValues(alpha: 0.08),
                      blurRadius: 0,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 14),
                    const Icon(Icons.search_rounded,
                        color: kFormBlue, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: searchCtrl,
                        onChanged: (_) => onSearchChanged(),
                        style: ffStyle(14, FontWeight.w500, kFormSlate7),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Search inspection forms…',
                          hintStyle:
                              ffStyle(14, FontWeight.w400, kFormSlate4),
                          isDense: true,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                  ],
                ),
              ),

              // ── Category tabs (horizontal scroll) ──────────────────────
              if (!categoriesLoading)
                SizedBox(
                  height: 48,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(top: 10),
                    itemCount: categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 6),
                    itemBuilder: (_, i) {
                      final cat = categories[i];
                      final active = cat == selectedCategory;
                      return GestureDetector(
                        onTap: () => onCategoryTap(cat),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: active ? kFormBlue : kFormSurface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            cat,
                            style: ffStyle(
                              12,
                              FontWeight.w700,
                              active ? Colors.white : kFormSlate5,
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

        // ── Result count ────────────────────────────────────────────────
        if (!loading)
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 16, 32, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${results.length} form${results.length != 1 ? 's' : ''}',
                style: ffStyle(12, FontWeight.w700, kFormSlate4)
                    .copyWith(letterSpacing: 1.2),
              ),
            ),
          ),

        // ── Results grid ────────────────────────────────────────────────
        Expanded(
          child: loading
              ? const Center(
                  child: CircularProgressIndicator(color: kFormBlue))
              : results.isEmpty
                  ? _buildEmpty()
                  : GridView.builder(
                      controller: scrollCtrl,
                      padding:
                          const EdgeInsets.fromLTRB(32, 8, 32, 32),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 3.2,
                      ),
                      itemCount:
                          results.length + (isLoadingMore ? 1 : 0),
                      itemBuilder: (_, i) {
                        if (i == results.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(
                                  color: kFormBlue),
                            ),
                          );
                        }
                        return _SearchFormCard(
                          form: results[i],
                          index: i,
                          onTap: () => onFormTap(results[i]),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off_rounded, size: 48, color: kFormSlate4),
          const SizedBox(height: 12),
          Text('No forms found',
              style: ffStyle(15, FontWeight.w700, kFormSlate7)),
          const SizedBox(height: 4),
          Text('Try a different search or category',
              style: ffStyle(13, FontWeight.w400, kFormSlate4)),
        ],
      ),
    );
  }
}

// ─── Search form card ────────────────────────────────────────────────────────
class _SearchFormCard extends StatefulWidget {
  final Map<String, dynamic> form;
  final int index;
  final VoidCallback onTap;
  const _SearchFormCard({
    required this.form,
    required this.index,
    required this.onTap,
  });

  @override
  State<_SearchFormCard> createState() => _SearchFormCardState();
}

class _SearchFormCardState extends State<_SearchFormCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    final delay = min(widget.index, 6) * 25;
    Future.delayed(Duration(milliseconds: delay), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final form = widget.form;
    final name = form['name'] as String? ?? 'Untitled';
    final category = form['category'] as String?;
    final schema = form['schema'];
    int stepCount = 0;
    if (schema is Map && schema.containsKey('items')) {
      stepCount = ((schema['items'] as List?) ?? []).length;
    } else if (schema is List) {
      stepCount = schema.length;
    }

    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: kFormBorder, width: 1.5),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F9FF),
                    border: Border.all(color: const Color(0xFFBAE6FD)),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(categoryIcon(category),
                      color: kFormBlue, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(name,
                          style: ffStyle(13, FontWeight.w700, kFormSlate8),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (category != null && category.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0F9FF),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(category,
                                  style: ffStyle(
                                      12, FontWeight.w700, kFormBlue)),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Text('$stepCount steps',
                              style: ffStyle(
                                  12, FontWeight.w400, kFormSlate4)),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: kFormBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.chevron_right_rounded,
                      color: kFormSlate4, size: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// DETAILS CONTENT
// ═══════════════════════════════════════════════════════════════════════════════

class _DetailsContent extends StatelessWidget {
  final Map<String, dynamic> form;
  final List<Map<String, dynamic>> steps;
  final bool schemaLoading;
  final bool duplicating;
  final bool isLandscape;
  final int? openStepIndex;
  final ValueChanged<int> onToggleStep;
  final VoidCallback onUseThisForm;

  const _DetailsContent({
    super.key,
    required this.form,
    required this.steps,
    required this.schemaLoading,
    required this.duplicating,
    required this.isLandscape,
    required this.openStepIndex,
    required this.onToggleStep,
    required this.onUseThisForm,
  });

  @override
  Widget build(BuildContext context) {
    if (isLandscape) return _buildLandscape(context);
    return _buildPortrait(context);
  }

  // ── Mobile + portrait tablet: accordion layout ────────────────────────────
  Widget _buildPortrait(BuildContext context) {
    final name = form['name'] as String? ?? 'Untitled';
    final category = form['category'] as String?;
    final createdAt = form['created_at'] as String?;

    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Preview button
                    if (!schemaLoading && steps.isNotEmpty)
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => FormPreviewScreen(
                                templateItems: steps,
                                formName: name,
                              ),
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 9),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F3FF),
                              border: Border.all(
                                  color: const Color(0xFFDDD6FE),
                                  width: 1.5),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                    Icons.play_circle_outline_rounded,
                                    color: Color(0xFF8B5CF6),
                                    size: 18),
                                const SizedBox(width: 6),
                                Text('Preview',
                                    style: ffStyle(14, FontWeight.w700,
                                        const Color(0xFF8B5CF6))),
                              ],
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    FormHeaderCard(
                      name: name,
                      category: category,
                      createdAt: createdAt,
                      stepCount: steps.length,
                      loading: schemaLoading,
                      version: (form['version'] as num?)?.toInt() ?? 1,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'INSPECTION STEPS',
                      style: ffStyle(13, FontWeight.w700, kFormSlate4)
                          .copyWith(letterSpacing: 1.2),
                    ),
                    const SizedBox(height: 12),
                    if (schemaLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child:
                              CircularProgressIndicator(color: kFormBlue),
                        ),
                      )
                    else if (steps.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text('No steps defined for this form.',
                              style:
                                  ffStyle(13, FontWeight.w400, kFormSlate4)),
                        ),
                      )
                    else
                      ...steps.asMap().entries.map(
                            (e) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: StepRow(
                                step: e.value,
                                index: e.key,
                                isOpen: openStepIndex == e.key,
                                onToggle: () => onToggleStep(e.key),
                              ),
                            ),
                          ),
                  ],
                ),
              ),
            ),
          ],
        ),
        // ── Sticky CTA ──────────────────────────────────────────────────
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: 0),
                  Colors.white,
                  Colors.white,
                ],
              ),
            ),
            child: GestureDetector(
              onTap: duplicating ? null : onUseThisForm,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [kFormBlue, kFormBlueDk],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: kFormBlue.withValues(alpha: 0.35),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (duplicating)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    else ...[
                      Text('Use This Form',
                          style:
                              ffStyle(15, FontWeight.w800, Colors.white)),
                      const SizedBox(width: 8),
                      const Icon(Icons.check_rounded,
                          color: Colors.white, size: 18),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Landscape tablet: split-panel layout (existing) ───────────────────────
  Widget _buildLandscape(BuildContext context) {
    final name = form['name'] as String? ?? 'Untitled';
    final stepCount = steps.length;
    final estTime = '~${(stepCount * 1.5).ceil()} min';

    return Row(
      children: [
        // ── Left sub-panel: step list ────────────────────────────────────
        SizedBox(
          width: 360,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FORM DETAILS',
                      style: ffStyle(12, FontWeight.w700, kFormSlate4)
                          .copyWith(letterSpacing: 1.0),
                    ),
                    Text(name,
                        style: ffStyle(14, FontWeight.w800, kFormSlate8),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _MiniStat(
                          label: 'Steps',
                          value: schemaLoading ? '—' : '$stepCount',
                          color: kFormBlue,
                          bg: const Color(0xFFF0F9FF),
                        ),
                        const SizedBox(width: 8),
                        _MiniStat(
                          label: 'Time',
                          value: schemaLoading ? '—' : estTime,
                          color: kFormGreen,
                          bg: const Color(0xFFF0FDF4),
                        ),
                        const SizedBox(width: 8),
                        _MiniStat(
                          label: 'Ver.',
                          value: 'v${form['version'] ?? 1}',
                          color: kFormAmber,
                          bg: const Color(0xFFFFFBEB),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              // Preview button
              if (!schemaLoading && steps.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => FormPreviewScreen(
                            templateItems: steps,
                            formName: form['name'] as String? ?? 'Untitled',
                          ),
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 9),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F3FF),
                          border: Border.all(
                              color: const Color(0xFFDDD6FE), width: 1.5),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.play_circle_outline_rounded,
                                color: Color(0xFF8B5CF6), size: 18),
                            const SizedBox(width: 6),
                            Text('Preview',
                                style: ffStyle(14, FontWeight.w700,
                                    const Color(0xFF8B5CF6))),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'STEPS — TAP TO INSPECT',
                    style: ffStyle(12, FontWeight.w700, kFormSlate4)
                        .copyWith(letterSpacing: 1.0),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: schemaLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: kFormBlue))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                        itemCount: steps.length,
                        itemBuilder: (_, i) {
                          final step = steps[i];
                          final type = step['type'] as String?;
                          final label =
                              step['label'] as String? ?? 'Step ${i + 1}';
                          final isOpen = openStepIndex == i;
                          final isRequired = step['required'] != false;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: GestureDetector(
                              onTap: () => onToggleStep(i),
                              child: AnimatedContainer(
                                duration:
                                    const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isOpen
                                      ? const Color(0xFFF0F9FF)
                                      : Colors.white,
                                  border: Border.all(
                                    color: isOpen
                                        ? kFormBlue
                                        : kFormBorder,
                                    width: isOpen ? 2 : 1.5,
                                  ),
                                  borderRadius:
                                      BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 3,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: isOpen
                                            ? kFormBlue
                                            : kFormBorder,
                                        borderRadius:
                                            BorderRadius.circular(2),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: isOpen
                                            ? kFormBlue
                                            : kFormSurface,
                                        border: Border.all(
                                            color: isOpen
                                                ? kFormBlue
                                                : kFormBorder),
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        itemTypeIcon(type),
                                        color: isOpen
                                            ? Colors.white
                                            : kFormSlate5,
                                        size: 13,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(label,
                                              style: ffStyle(
                                                  12,
                                                  FontWeight.w700,
                                                  kFormSlate8),
                                              maxLines: 1,
                                              overflow: TextOverflow
                                                  .ellipsis),
                                          Text(
                                              itemTypeLabel(type),
                                              style: ffStyle(
                                                  12,
                                                  FontWeight.w400,
                                                  isOpen
                                                      ? kFormBlue
                                                      : kFormSlate4)),
                                        ],
                                      ),
                                    ),
                                    if (isRequired)
                                      Container(
                                        padding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 2),
                                        decoration: BoxDecoration(
                                          color:
                                              const Color(0xFFFFFBEB),
                                          border: Border.all(
                                              color: const Color(
                                                  0xFFFDE68A)),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text('Req',
                                            style: ffStyle(
                                                12,
                                                FontWeight.w800,
                                                kFormAmber)),
                                      ),
                                    const SizedBox(width: 4),
                                    AnimatedRotation(
                                      turns: isOpen ? 0.5 : 0,
                                      duration: const Duration(
                                          milliseconds: 200),
                                      child: Icon(
                                        Icons.expand_more_rounded,
                                        color: isOpen
                                            ? kFormBlue
                                            : kFormSlate4,
                                        size: 18,
                                      ),
                                    ),
                                  ],
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

        // ── Divider ──────────────────────────────────────────────────────
        Container(width: 1, color: kFormBorder),

        // ── Right sub-panel: step detail ─────────────────────────────────
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: openStepIndex != null && openStepIndex! < steps.length
                    ? _StepDetailPanel(step: steps[openStepIndex!])
                    : _buildNoStepSelected(),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(28, 20, 28, 20),
                decoration: BoxDecoration(
                  border:
                      Border(top: BorderSide(color: kFormBorder, width: 1)),
                ),
                child: GestureDetector(
                  onTap: duplicating ? null : onUseThisForm,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [kFormBlue, kFormBlueDk],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: kFormBlue.withValues(alpha: 0.30),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (duplicating)
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        else ...[
                          const Icon(Icons.check_rounded,
                              color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Text('Use This Form',
                              style:
                                  ffStyle(15, FontWeight.w800, Colors.white)),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNoStepSelected() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: kFormSurface,
              border: Border.all(color: kFormBorder, width: 1.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.info_outline_rounded,
                color: kFormSlate4, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            'Select a step on the left\nto view its configuration',
            textAlign: TextAlign.center,
            style: ffStyle(14, FontWeight.w600, kFormSlate4),
          ),
        ],
      ),
    );
  }
}

// ─── Mini stat chip (details panel) ──────────────────────────────────────────
class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color bg;
  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(value, style: ffStyle(14, FontWeight.w800, color)),
            const SizedBox(height: 1),
            Text(label, style: ffStyle(12, FontWeight.w600, kFormSlate4)),
          ],
        ),
      ),
    );
  }
}

// ─── Step detail panel (right sub-panel in details) ──────────────────────────
class _StepDetailPanel extends StatelessWidget {
  final Map<String, dynamic> step;
  const _StepDetailPanel({required this.step});

  @override
  Widget build(BuildContext context) {
    final type = step['type'] as String? ?? '';
    final label = step['label'] as String? ?? 'Step';
    final cfg = (step['config'] as Map<String, dynamic>?) ?? {};
    final isRequired = step['required'] != false;

    // Build config rows from the config map
    final configRows = <Widget>[];
    _addConfigRowsForType(type, cfg, configRows);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 24, 72, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F9FF),
                  border: Border.all(color: const Color(0xFFBAE6FD)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(itemTypeIcon(type), color: kFormBlue, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: ffStyle(18, FontWeight.w800, kFormSlate8)),
                    const SizedBox(height: 2),
                    Text(itemTypeLabel(type),
                        style: ffStyle(13, FontWeight.w600, kFormBlue)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Hint box
          if (cfg['placeholder'] != null &&
              (cfg['placeholder'] as String).isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F9FF),
                border: Border.all(color: const Color(0xFFBAE6FD)),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'HINT',
                    style: ffStyle(12, FontWeight.w700, kFormSlate4)
                        .copyWith(letterSpacing: 1.0),
                  ),
                  const SizedBox(height: 4),
                  Text(cfg['placeholder'] as String,
                      style: ffStyle(13, FontWeight.w600, kFormSlate7)),
                ],
              ),
            ),

          // Configuration
          Text(
            'CONFIGURATION',
            style: ffStyle(12, FontWeight.w700, kFormSlate4)
                .copyWith(letterSpacing: 1.0),
          ),
          const SizedBox(height: 8),
          ...configRows,
          const SizedBox(height: 12),

          // Required status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isRequired
                  ? const Color(0xFFFFFBEB)
                  : kFormSurface,
              border: Border.all(
                color: isRequired
                    ? const Color(0xFFFDE68A)
                    : kFormBorder,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: isRequired ? kFormBlue : kFormBorder,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: isRequired
                      ? const Icon(Icons.check_rounded,
                          color: Colors.white, size: 10)
                      : null,
                ),
                const SizedBox(width: 10),
                Text(
                  isRequired
                      ? 'Required — must be completed'
                      : 'Optional step',
                  style: ffStyle(
                      13,
                      FontWeight.w600,
                      isRequired ? kFormAmber : kFormSlate4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _addConfigRowsForType(
      String type, Map<String, dynamic> cfg, List<Widget> rows) {
    switch (type) {
      case 'numeric':
        final min = cfg['min']?.toString();
        final max = cfg['max']?.toString();
        final unit = cfg['unit']?.toString();
        if (min != null) rows.add(_cfgRow(Icons.arrow_downward_rounded, 'Min value', unit != null ? '$min $unit' : min));
        if (max != null) rows.add(_cfgRow(Icons.arrow_upward_rounded, 'Max value', unit != null ? '$max $unit' : max));
        if (unit != null) rows.add(_cfgRow(Icons.straighten_rounded, 'Unit', unit));
        rows.add(_cfgRow(Icons.tag_rounded, 'Input type', 'Number only'));
        if (cfg['ocrEnabled'] == true) {
          rows.add(_cfgRow(Icons.document_scanner_outlined, 'OCR scan', 'Enabled'));
        }
      case 'alphanumeric':
        rows.add(_cfgRow(Icons.text_fields_rounded, 'Input type', 'Text & numbers'));
        if (cfg['maxLength'] != null) {
          rows.add(_cfgRow(Icons.straighten_rounded, 'Max length', '${cfg['maxLength']} characters'));
        }
        if (cfg['ocrEnabled'] == true) {
          rows.add(_cfgRow(Icons.document_scanner_outlined, 'OCR scan', 'Enabled'));
        }
      case 'comment-box':
        rows.add(_cfgRow(Icons.chat_bubble_outline_rounded, 'Input type', 'Free text'));
        if (cfg['maxLength'] != null) {
          rows.add(_cfgRow(Icons.straighten_rounded, 'Max length', '${cfg['maxLength']} characters'));
        }
        rows.add(_cfgRow(Icons.document_scanner_outlined, 'OCR scan', cfg['ocrEnabled'] == true ? 'Enabled' : 'Disabled'));
      case 'multi-check':
        final checks = cfg['checks'] is List ? (cfg['checks'] as List) : [];
        rows.add(_cfgRow(Icons.checklist_rounded, 'Items', '${checks.length} checklist item${checks.length != 1 ? 's' : ''}'));
        for (final check in checks) {
          if (check is Map) {
            rows.add(_cfgRow(Icons.check_box_outline_blank_rounded, check['label']?.toString() ?? '', ''));
          }
        }
      case 'single-check':
        rows.add(_cfgRow(Icons.check_circle_outline_rounded, 'Input type', 'Pass / Fail'));
        rows.add(_cfgRow(Icons.photo_camera_outlined, 'Photo on fail', cfg['photoRequired'] == true ? 'Required' : 'Optional'));
      case 'photo':
        rows.add(_cfgRow(Icons.photo_camera_outlined, 'Source', 'Camera or gallery'));
        if (cfg['minPhotos'] != null) rows.add(_cfgRow(Icons.photo_outlined, 'Min photos', '${cfg['minPhotos']}'));
        if (cfg['maxPhotos'] != null) rows.add(_cfgRow(Icons.photo_library_outlined, 'Max photos', '${cfg['maxPhotos']}'));
      case 'signature':
        rows.add(_cfgRow(Icons.draw_outlined, 'Type', 'Digital draw'));
        rows.add(_cfgRow(Icons.person_outline_rounded, 'Signee', 'Assigned inspector'));
      default:
        for (final entry in cfg.entries) {
          if (entry.value != null) {
            rows.add(_cfgRow(Icons.settings_outlined, entry.key, entry.value.toString()));
          }
        }
    }
  }

  Widget _cfgRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: kFormSurface,
          border: Border.all(color: kFormBorder),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, color: kFormSlate4, size: 15),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label,
                  style: ffStyle(13, FontWeight.w500, kFormSlate5)),
            ),
            if (value.isNotEmpty)
              Text(value, style: ffStyle(13, FontWeight.w700, kFormSlate7)),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// CONFIRMED CONTENT
// ═══════════════════════════════════════════════════════════════════════════════

class _ConfirmedContent extends StatelessWidget {
  final Map<String, dynamic> form;
  final List<Map<String, dynamic>> schemaItems;
  final AnimationController? ringCtrl;
  final AnimationController? checkCtrl;
  final AnimationController? contentCtrl;
  final VoidCallback onStartInspection;
  final VoidCallback onEditForm;
  final VoidCallback onChangeForm;
  final VoidCallback onDone;

  const _ConfirmedContent({
    super.key,
    required this.form,
    required this.schemaItems,
    required this.ringCtrl,
    required this.checkCtrl,
    required this.contentCtrl,
    required this.onStartInspection,
    required this.onEditForm,
    required this.onChangeForm,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    final name = form['name'] as String? ?? 'Untitled';
    final category = form['category'] as String?;
    final stepCount = schemaItems.length;

    final ringScale = ringCtrl != null
        ? CurvedAnimation(parent: ringCtrl!, curve: Curves.easeOut)
        : const AlwaysStoppedAnimation(1.0);
    final checkScale = checkCtrl != null
        ? CurvedAnimation(parent: checkCtrl!, curve: Curves.elasticOut)
        : const AlwaysStoppedAnimation(1.0);
    final contentOpacity = contentCtrl != null
        ? CurvedAnimation(parent: contentCtrl!, curve: Curves.easeOut)
        : const AlwaysStoppedAnimation(1.0);
    final contentSlide = contentCtrl != null
        ? Tween<Offset>(
            begin: const Offset(0, 0.08),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(parent: contentCtrl!, curve: Curves.easeOut))
        : const AlwaysStoppedAnimation(Offset.zero);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Animated checkmark ──────────────────────────────────────
            ScaleTransition(
              scale: ringScale,
              child: SizedBox(
                width: 100,
                height: 100,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: kFormGreen.withValues(alpha: 0.10),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: kFormGreen.withValues(alpha: 0.07),
                        shape: BoxShape.circle,
                      ),
                    ),
                    ScaleTransition(
                      scale: checkScale,
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [kFormGreen, kFormGreenDk],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: kFormGreen.withValues(alpha: 0.35),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.check_rounded,
                            color: Colors.white, size: 30),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Text ────────────────────────────────────────────────────
            SlideTransition(
              position: contentSlide,
              child: FadeTransition(
                opacity: contentOpacity,
                child: Column(
                  children: [
                    Text('Form Assigned!',
                        style: ffStyle(26, FontWeight.w800, kFormSlate8)),
                    const SizedBox(height: 8),
                    Text('Your inspection is ready to go',
                        style: ffStyle(14, FontWeight.w400, kFormSlate4)),
                    const SizedBox(height: 32),

                    // ── Form summary card ───────────────────────────────
                    Container(
                      constraints: const BoxConstraints(maxWidth: 420),
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                            color: const Color(0xFFD1FAE5), width: 2),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: kFormGreen.withValues(alpha: 0.10),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [kFormGreen, kFormGreenDk],
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(categoryIcon(category),
                                      color: Colors.white, size: 22),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(name,
                                          style: ffStyle(15,
                                              FontWeight.w800, kFormSlate8),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis),
                                      const SizedBox(height: 2),
                                      Text(
                                        '$stepCount steps'
                                        '${category != null ? ' · $category' : ''}',
                                        style: ffStyle(
                                            12, FontWeight.w400, kFormSlate4),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: const BoxDecoration(
                                    color: kFormGreen,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.check_rounded,
                                      color: Colors.white, size: 14),
                                ),
                              ],
                            ),
                          ),
                          // Stats row
                          Container(
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(
                                    color: const Color(0xFFD1FAE5)),
                              ),
                            ),
                            child: Row(
                              children: [
                                _confirmStat(
                                    'Steps', '$stepCount', true),
                                _confirmStat(
                                    'Est. Time',
                                    '~${(stepCount * 1.5).ceil()} min',
                                    true),
                                _confirmStat('Version',
                                    'v${form['version'] ?? 1}', false),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // ── Edit Form (primary) ────────────────────────────
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: GestureDetector(
                        onTap: onEditForm,
                        child: Container(
                          width: double.infinity,
                          padding:
                              const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [kFormBlue, kFormBlueDk],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    kFormBlue.withValues(alpha: 0.30),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.edit_rounded,
                                  color: Colors.white, size: 16),
                              const SizedBox(width: 8),
                              Text('Edit Form',
                                  style: ffStyle(
                                      15, FontWeight.w800, Colors.white)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ── Start Inspection + Change Form (side by side) ──
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: onStartInspection,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 14),
                                decoration: BoxDecoration(
                                  color: kFormBg,
                                  borderRadius:
                                      BorderRadius.circular(16),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                        Icons.play_arrow_rounded,
                                        color: kFormSlate5, size: 16),
                                    const SizedBox(width: 6),
                                    Text('Start Inspection',
                                        style: ffStyle(13,
                                            FontWeight.w700, kFormSlate5)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: GestureDetector(
                              onTap: onChangeForm,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 14),
                                decoration: BoxDecoration(
                                  color: kFormBg,
                                  borderRadius:
                                      BorderRadius.circular(16),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                        Icons.swap_horiz_rounded,
                                        color: kFormSlate5, size: 16),
                                    const SizedBox(width: 6),
                                    Text('Change Form',
                                        style: ffStyle(13,
                                            FontWeight.w700, kFormSlate5)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // ── Done button ───────────────────────────────────
                    GestureDetector(
                      onTap: onDone,
                      child: Padding(
                        padding:
                            const EdgeInsets.symmetric(vertical: 10),
                        child: Text('Done — return to dashboard',
                            style: ffStyle(
                                13, FontWeight.w600, kFormSlate4)),
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

  Widget _confirmStat(String label, String value, bool showBorder) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: showBorder
              ? Border(
                  right:
                      BorderSide(color: const Color(0xFFD1FAE5), width: 1))
              : null,
        ),
        child: Column(
          children: [
            Text(value, style: ffStyle(16, FontWeight.w800, kFormGreen)),
            const SizedBox(height: 1),
            Text(label.toUpperCase(),
                style: ffStyle(12, FontWeight.w700, kFormSlate4)
                    .copyWith(letterSpacing: 0.8)),
          ],
        ),
      ),
    );
  }
}
