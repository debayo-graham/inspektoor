import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'form_flow_tokens.dart';
import 'form_preview_page.dart';

// ─── Screen 2 — Search & Results ─────────────────────────────────────────────
class FormSearchPage extends StatefulWidget {
  final String initialQuery;
  const FormSearchPage({super.key, this.initialQuery = ''});

  @override
  State<FormSearchPage> createState() => _FormSearchPageState();
}

class _FormSearchPageState extends State<FormSearchPage> {
  late final TextEditingController _searchCtrl;
  final FocusNode _searchFocus = FocusNode();
  final ScrollController _scrollCtrl = ScrollController();
  Timer? _debounce;

  List<Map<String, dynamic>> _results = [];
  bool _loading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _offset = 0;
  String _selectedCategory = 'All';
  List<String> _categories = ['All'];
  bool _categoriesLoading = true;

  static const int _pageSize = 25;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController(text: widget.initialQuery);
    _scrollCtrl.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocus.requestFocus();
      _fetchCategories();
      _fetch();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
            _scrollCtrl.position.maxScrollExtent - 300 &&
        !_loading &&
        !_isLoadingMore &&
        _hasMore) {
      _fetchMore();
    }
  }

  Future<void> _fetchCategories() async {
    final orgId = FFAppState().currentOrgId;
    try {
      final rows = await Supabase.instance.client
          .from('template_categories')
          .select('name')
          .or('is_predefined.eq.true,org_id.eq.$orgId')
          .order('sort_order');
      final names = (rows as List)
          .map((r) => r['name'] as String)
          .toList();
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

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), _fetch);
  }

  Future<String> _freshToken() async {
    final supabase = Supabase.instance.client;
    try {
      await supabase.auth.refreshSession();
    } catch (_) {}
    return supabase.auth.currentSession?.accessToken ?? '';
  }

  Future<void> _fetch() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _offset = 0;
      _hasMore = true;
    });

    final token = await _freshToken();
    final orgId = FFAppState().currentOrgId;
    final scope = _selectedCategory == 'All' ? '' : _selectedCategory;

    final response = await SearchInspectionFormTemplatesCall.call(
      pOrg: orgId,
      pScope: scope,
      pQ: _searchCtrl.text.trim(),
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
      _loading = false;
      _hasMore = parsed.length >= _pageSize;
    });
  }

  Future<void> _fetchMore() async {
    if (!mounted) return;
    setState(() => _isLoadingMore = true);

    final token = await _freshToken();
    final orgId = FFAppState().currentOrgId;
    final scope = _selectedCategory == 'All' ? '' : _selectedCategory;
    final nextOffset = _offset + _pageSize;

    final response = await SearchInspectionFormTemplatesCall.call(
      pOrg: orgId,
      pScope: scope,
      pQ: _searchCtrl.text.trim(),
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

  void _selectCategory(String cat) {
    if (_selectedCategory == cat) return;
    setState(() => _selectedCategory = cat);
    _fetch();
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
                      child: Text('Select Form',
                          style: ffStyle(17, FontWeight.w800, kFormSlate8)),
                    ),
                  ),
                  const SizedBox(width: 36),
                ],
              ),
            ),

            // ── Search bar ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Container(
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
                        controller: _searchCtrl,
                        focusNode: _searchFocus,
                        onChanged: (_) => _onSearchChanged(),
                        style:
                            ffStyle(14, FontWeight.w500, kFormSlate7),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Search inspection forms…',
                          hintStyle:
                              ffStyle(14, FontWeight.w400, kFormSlate4),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 14),
                        ),
                      ),
                    ),
                    if (_searchCtrl.text.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _searchCtrl.clear();
                          _fetch();
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: const Icon(Icons.close_rounded,
                              color: kFormSlate4, size: 18),
                        ),
                      ),
                    if (_searchCtrl.text.isEmpty)
                      const SizedBox(width: 14),
                  ],
                ),
              ),
            ),

            // ── Category chips ───────────────────────────────────────────────
            SizedBox(
              height: 44,
              child: _categoriesLoading
                  ? const Padding(
                      padding: EdgeInsets.fromLTRB(20, 10, 0, 0),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: kFormBlue, strokeWidth: 2),
                      ),
                    )
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                      itemCount: _categories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final cat = _categories[i];
                        final active = cat == _selectedCategory;
                        return GestureDetector(
                          onTap: () => _selectCategory(cat),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: active ? kFormBlue : kFormBg,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              cat,
                              style: ffStyle(
                                11,
                                FontWeight.w700,
                                active ? Colors.white : kFormSlate5,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // ── Result count ─────────────────────────────────────────────────
            if (!_loading)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${_results.length} form${_results.length != 1 ? 's' : ''} found',
                    style: ffStyle(11, FontWeight.w700, kFormSlate4)
                        .copyWith(letterSpacing: 1.2),
                  ),
                ),
              ),

            // ── Results list ─────────────────────────────────────────────────
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: kFormBlue))
                  : _results.isEmpty
                      ? _buildEmpty()
                      : ListView.separated(
                          controller: _scrollCtrl,
                          cacheExtent: 400,
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                          itemCount:
                              _results.length + (_isLoadingMore ? 1 : 0),
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, i) {
                            if (i == _results.length) {
                              // Loading more spinner
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Center(
                                  child: CircularProgressIndicator(
                                      color: kFormBlue),
                                ),
                              );
                            }
                            return _FormResultRow(
                                form: _results[i], index: i);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off_rounded,
              size: 48, color: kFormSlate4),
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

// ─── Result row ───────────────────────────────────────────────────────────────
class _FormResultRow extends StatefulWidget {
  final Map<String, dynamic> form;
  final int index;
  const _FormResultRow({required this.form, required this.index});

  @override
  State<_FormResultRow> createState() => _FormResultRowState();
}

class _FormResultRowState extends State<_FormResultRow>
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

    // Cap stagger at 6 items (max 150ms delay) so deep-list items and
    // scroll-restored items animate in quickly.
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
    final createdAt = form['created_at'] as String?;

    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => FormPreviewPage(form: form),
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
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
                // Icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: kFormSurface,
                    border: Border.all(color: kFormBorder),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Icon(
                      categoryIcon(category),
                      color: kFormBlue,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Name + meta
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: ffStyle(13, FontWeight.w700, kFormSlate8),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
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
                                      9, FontWeight.w700, kFormBlue)),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            relativeTime(createdAt),
                            style:
                                ffStyle(11, FontWeight.w400, kFormSlate4),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Chevron
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
