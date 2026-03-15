import 'dart:async';

import 'package:flutter/material.dart';

import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/actions/init_global_error_logging.dart';
import '/custom_code/actions/init_inspection_draft.dart';
import '/common/components/loading_overlay.dart';
import '/features/asset_selection/components/form_picker_sheet.dart';
import '/features/inspection_form/pages/form_flow_tokens.dart';
import '/pages/components/app_drawer_content/app_drawer_content_widget.dart';
import '/pages/dashboard/home_page/home_page_widget.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────
const Color _kRed = Color(0xFFEF4444);
const Color _kRedBg = Color(0xFFFFF1F2);
const Color _kRedBdr = Color(0xFFFECDD3);
const Color _kAmber = Color(0xFFF59E0B);
const Color _kAmberBg = Color(0xFFFFFBEB);
const Color _kAmberBdr = Color(0xFFFDE68A);

// ─── Asset category helpers ──────────────────────────────────────────────────
const _kCategoryLabels = <String, String>{
  'vehicle': 'Vehicles',
  'trailer': 'Trailers',
  'heavy_equipment': 'Heavy Equip.',
  'access_equipment': 'Access Equip.',
  'power_equipment': 'Power Equip.',
  'fluid_handling': 'Fluid Handling',
  'safety_equipment': 'Safety',
  'building_systems': 'Building',
  'other': 'Other',
};

IconData _assetCategoryIcon(String? cat) {
  switch (cat) {
    case 'vehicle':
      return Icons.local_shipping_outlined;
    case 'trailer':
      return Icons.rv_hookup_outlined;
    case 'heavy_equipment':
      return Icons.construction_outlined;
    case 'access_equipment':
      return Icons.engineering_outlined;
    case 'power_equipment':
      return Icons.bolt_outlined;
    case 'fluid_handling':
      return Icons.water_drop_outlined;
    case 'safety_equipment':
      return Icons.health_and_safety_outlined;
    case 'building_systems':
      return Icons.apartment_outlined;
    default:
      return Icons.assignment_outlined;
  }
}

// ─── Inspection status from last_inspected_at ────────────────────────────────
enum _InspStatus { ok, due, overdue }

_InspStatus _inspStatus(DateTime? lastInspected) {
  if (lastInspected == null) return _InspStatus.overdue;
  final days = DateTime.now().difference(lastInspected).inDays;
  if (days > 7) return _InspStatus.overdue;
  if (days >= 3) return _InspStatus.due;
  return _InspStatus.ok;
}

String _inspStatusLabel(_InspStatus s) {
  switch (s) {
    case _InspStatus.ok:
      return 'Up to date';
    case _InspStatus.due:
      return 'Due';
    case _InspStatus.overdue:
      return 'Overdue';
  }
}

Color _inspStatusColor(_InspStatus s) {
  switch (s) {
    case _InspStatus.ok:
      return kFormGreen;
    case _InspStatus.due:
      return _kAmber;
    case _InspStatus.overdue:
      return _kRed;
  }
}

Color _inspStatusBg(_InspStatus s) {
  switch (s) {
    case _InspStatus.ok:
      return const Color(0xFFF0FDF4);
    case _InspStatus.due:
      return _kAmberBg;
    case _InspStatus.overdue:
      return _kRedBg;
  }
}

Color _inspStatusBdr(_InspStatus s) {
  switch (s) {
    case _InspStatus.ok:
      return const Color(0xFFBBF7D0);
    case _InspStatus.due:
      return _kAmberBdr;
    case _InspStatus.overdue:
      return _kRedBdr;
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// SelectAssetPage
// ═════════════════════════════════════════════════════════════════════════════
/// Asset selection screen. Two entry points:
///   1. From FormConfirmedPage → [form] + [schemaItems] are provided.
///   2. From main nav "Inspect Asset" → [form] is null.
class SelectAssetPage extends StatefulWidget {
  static String routeName = 'SelectAssetPage';
  static String routePath = '/selectAssetPage';

  /// The duplicated inspection template (null when accessed from nav).
  final Map<String, dynamic>? form;

  /// Parsed schema items for the selected form.
  final List<Map<String, dynamic>>? schemaItems;

  const SelectAssetPage({super.key, this.form, this.schemaItems});

  @override
  State<SelectAssetPage> createState() => _SelectAssetPageState();
}

class _SelectAssetPageState extends State<SelectAssetPage> {
  final _searchCtrl = TextEditingController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  Timer? _debounce;

  List<Map<String, dynamic>> _assets = [];
  List<String> _categories = [];
  bool _loading = true;
  String _filterCategory = 'All';
  String _query = '';
  Map<String, dynamic>? _selected;
  bool _starting = false;

  /// True when accessed from drawer (no form pre-selected).
  bool get _isStandalone => widget.form == null;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchChanged);
    _fetchAssets();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Data fetching ──────────────────────────────────────────────────────────

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() => _query = _searchCtrl.text.trim().toLowerCase());
      }
    });
  }

  Future<void> _fetchAssets() async {
    try {
      final rows = await SupaFlow.client
          .from('assets')
          .select()
          .isFilter('deleted_at', null)
          .order('name', ascending: true);

      if (!mounted) return;

      final cats = <String>{};
      for (final r in rows) {
        final c = r['category'] as String?;
        if (c != null && c.isNotEmpty) cats.add(c);
      }

      setState(() {
        _assets = List<Map<String, dynamic>>.from(rows);
        _categories = cats.toList()..sort();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    return _assets.where((a) {
      if (_filterCategory != 'All' && a['category'] != _filterCategory) {
        return false;
      }
      if (_query.isNotEmpty) {
        final name = (a['name'] as String? ?? '').toLowerCase();
        final code = (a['serial_or_vin'] as String? ?? '').toLowerCase();
        if (!name.contains(_query) && !code.contains(_query)) return false;
      }
      return true;
    }).toList();
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _beginInspection() async {
    final asset = _selected;
    if (asset == null || _starting) return;

    setState(() => _starting = true);

    final assetId = asset['id'] as String;
    final assetName = asset['name'] as String? ?? '';

    try {
      String templateId;
      String schemaJson;

      if (widget.form != null) {
        // Form was pre-selected (from FormConfirmedPage).
        LoadingOverlay.show(context,
            message: 'Preparing inspection\u2026',
            icon: Icons.assignment_outlined);
        templateId = widget.form!['id'] as String;
        schemaJson = jsonEncode(widget.form!['schema']);

        // Auto-assign template to asset if not already linked.
        // Non-critical — must not block the inspection if it fails.
        try {
          final existing = await SupaFlow.client
              .from('asset_inspection_templates')
              .select('asset_id')
              .eq('asset_id', assetId)
              .eq('inspection_template_id', templateId)
              .maybeSingle();
          if (existing == null) {
            await SupaFlow.client
                .from('asset_inspection_templates')
                .insert({
              'asset_id': assetId,
              'inspection_template_id': templateId,
            });
          }
        } catch (e, st) {
          debugPrint('Auto-assign template failed: $e');
          logCaughtError(e, stack: st, screen: 'SelectAssetPage');
        }
      } else {
        // No form pre-selected — let the user pick one.
        setState(() => _starting = false);

        if (!mounted) return;
        final pickedForm = await showFormPickerSheet(
          context,
          assetName: assetName,
          assetId: assetId,
        );

        if (pickedForm == null || !mounted) {
          // User dismissed the sheet — deselect the asset.
          if (mounted) setState(() => _selected = null);
          return;
        }

        // Let the sheet close animation finish before showing overlay.
        await Future.delayed(const Duration(milliseconds: 300));
        if (!mounted) return;

        setState(() => _starting = true);
        LoadingOverlay.show(context,
            message: 'Preparing inspection\u2026',
            icon: Icons.assignment_outlined);

        templateId = pickedForm['id'] as String;
        schemaJson = jsonEncode(pickedForm['schema']);

        // Auto-assign template to asset (non-critical).
        try {
          final existing = await SupaFlow.client
              .from('asset_inspection_templates')
              .select('asset_id')
              .eq('asset_id', assetId)
              .eq('inspection_template_id', templateId)
              .maybeSingle();
          if (existing == null) {
            await SupaFlow.client
                .from('asset_inspection_templates')
                .insert({
              'asset_id': assetId,
              'inspection_template_id': templateId,
            });
          }
        } catch (e, st) {
          debugPrint('Auto-assign template failed: $e');
          logCaughtError(e, stack: st, screen: 'SelectAssetPage');
        }
      }

      FFAppState().update(() {
        FFAppState().templateJson = schemaJson;
      });

      await initInspectionDraft(assetId, templateId, assetName);

      if (mounted) {
        LoadingOverlay.hide(context);
        setState(() => _starting = false);
        context.pushNamed('InspectAsset');
      }
    } catch (e) {
      if (mounted) {
        LoadingOverlay.hide(context);
        setState(() => _starting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start inspection',
                style: ffStyle(13, FontWeight.w500, Colors.white)),
            backgroundColor: _kRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  void _showOverflowMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _OverflowSheet(
        onDashboard: () async {
          Navigator.pop(ctx); // close sheet
          // Delete the duplicated template
          final formId = widget.form?['id'] as String?;
          if (formId != null) {
            try {
              await InspectionTemplatesTable().delete(
                matchingRows: (rows) => rows.eq('id', formId),
              );
            } catch (_) {}
          }
          if (!mounted) return;
          Navigator.of(context).popUntil((route) =>
              route.settings.name == HomePageWidget.routeName || route.isFirst);
        },
        onCancel: () {
          Navigator.pop(ctx);
          _showCancelSheet();
        },
      ),
    );
  }

  void _showCancelSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0xFF0F172A).withValues(alpha: 0.4),
      builder: (ctx) => _CancelSheet(
        onKeep: () => Navigator.pop(ctx),
        onConfirm: () {
          Navigator.pop(ctx); // close sheet
          // Pop all the way back — user cancelled the whole flow.
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      drawer: _isStandalone
          ? Drawer(
              child: AppDrawerContentWidget(),
            )
          : null,
      body: SafeArea(
        child: Stack(
          children: [
            // ── Main content column ───────────────────────────────────
            Column(
              children: [
                // ── Header ───────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Row(
                    children: [
                      // Hamburger menu when standalone, back button in flow
                      if (_isStandalone)
                        GestureDetector(
                          onTap: () =>
                              _scaffoldKey.currentState?.openDrawer(),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: kFormBg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.menu_rounded,
                                color: kFormSlate5, size: 20),
                          ),
                        )
                      else
                        const FormFlowBackButton(),
                      Expanded(
                        child: Center(
                          child: Text('Select Asset',
                              style:
                                  ffStyle(17, FontWeight.w800, kFormSlate8)),
                        ),
                      ),
                      // Overflow dots
                      GestureDetector(
                        onTap: _showOverflowMenu,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: kFormBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.more_vert_rounded,
                              color: kFormSlate5, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // ── Search bar ───────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: kFormSurface,
                      border: Border.all(color: kFormBorder, width: 1.5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search_rounded,
                            size: 18, color: kFormSlate4),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _searchCtrl,
                            style:
                                ffStyle(13, FontWeight.w500, kFormSlate8),
                            decoration: InputDecoration.collapsed(
                              hintText:
                                  'Search by name or asset code\u2026',
                              hintStyle:
                                  ffStyle(13, FontWeight.w400, kFormSlate4),
                            ),
                          ),
                        ),
                        const Icon(Icons.qr_code_scanner_rounded,
                            size: 18, color: kFormBlue),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // ── Filter chips ─────────────────────────────────────
                SizedBox(
                  height: 34,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      _FilterChip(
                        label: 'All',
                        selected: _filterCategory == 'All',
                        onTap: () =>
                            setState(() => _filterCategory = 'All'),
                      ),
                      for (final cat in _categories) ...[
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: _kCategoryLabels[cat] ?? cat,
                          selected: _filterCategory == cat,
                          onTap: () =>
                              setState(() => _filterCategory = cat),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // ── Results header ───────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Text(
                        '${filtered.length} asset${filtered.length != 1 ? 's' : ''}',
                        style: ffStyle(13, FontWeight.w700, kFormSlate4),
                      ),
                      const Spacer(),
                      if (_selected != null) ...[
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: kFormGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text('1 selected',
                            style:
                                ffStyle(13, FontWeight.w700, kFormGreen)),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 6),

                // ── Asset list ───────────────────────────────────────
                Expanded(
                  child: _loading
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: kFormBlue))
                      : filtered.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 40),
                                child: Text(
                                  _query.isNotEmpty
                                      ? 'No assets match your search.'
                                      : 'No assets found.',
                                  textAlign: TextAlign.center,
                                  style: ffStyle(
                                      14, FontWeight.w500, kFormSlate4),
                                ),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(
                                  20, 4, 20, 160),
                              itemCount:
                                  filtered.length + 1, // +1 for "Add New"
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (_, i) {
                                if (i == filtered.length) {
                                  return _AddNewAssetButton(onTap: () {
                                    // TODO: navigate to add asset page
                                    context.pushNamed('AddAssetPage');
                                  });
                                }
                                final asset = filtered[i];
                                final isSelected =
                                    _selected?['id'] == asset['id'];
                                return _AssetCard(
                                  asset: asset,
                                  isSelected: isSelected,
                                  onTap: () {
                                    FocusScope.of(context).unfocus();
                                    if (_isStandalone) {
                                      // Open form picker immediately.
                                      setState(() => _selected = asset);
                                      _beginInspection();
                                    } else {
                                      setState(() => _selected =
                                          isSelected ? null : asset);
                                    }
                                  },
                                );
                              },
                            ),
                ),
              ],
            ),

            // ── Sticky footer (positioned at bottom) ─────────────────
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _StickyFooter(
                // Standalone: tap goes straight to form picker, so never
                // show the recap + Begin button in the footer.
                selected: _isStandalone ? null : _selected,
                starting: _starting,
                onDeselect: () => setState(() => _selected = null),
                onBegin: _beginInspection,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Sub-widgets
// ═════════════════════════════════════════════════════════════════════════════

// ── Filter chip ──────────────────────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? kFormBlue : kFormSurface,
          border: Border.all(
            color: selected ? Colors.transparent : kFormBorder,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: ffStyle(
              12, FontWeight.w700, selected ? Colors.white : kFormSlate5),
        ),
      ),
    );
  }
}

// ── Asset card ───────────────────────────────────────────────────────────────
class _AssetCard extends StatelessWidget {
  final Map<String, dynamic> asset;
  final bool isSelected;
  final VoidCallback onTap;
  const _AssetCard(
      {required this.asset, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final name = asset['name'] as String? ?? 'Unnamed';
    final code = asset['serial_or_vin'] as String? ?? '';
    final location = asset['location'] as String? ?? '';
    final category = asset['category'] as String?;
    final lastStr = asset['last_inspected_at'] as String?;
    final lastDt = lastStr != null ? DateTime.tryParse(lastStr) : null;
    final status = _inspStatus(lastDt);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF0F9FF) : Colors.white,
          border: Border.all(
            color: isSelected ? kFormBlue : kFormBorder,
            width: isSelected ? 2 : 1.5,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: kFormBlue.withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  )
                ],
        ),
        child: Row(
          children: [
            // Left bar
            Container(
              width: 4,
              height: 52,
              decoration: BoxDecoration(
                color: isSelected ? kFormBlue : kFormBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            // Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : kFormSurface,
                border: Border.all(
                    color: isSelected
                        ? const Color(0xFFBAE6FD)
                        : kFormBorder),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _assetCategoryIcon(category),
                size: 18,
                color: isSelected ? kFormBlue : kFormSlate5,
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: ffStyle(13, FontWeight.w700, kFormSlate8),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      if (code.isNotEmpty) ...[
                        Icon(Icons.sell_outlined,
                            size: 10, color: kFormSlate4),
                        const SizedBox(width: 3),
                        Text(code,
                            style: ffStyle(
                                12, FontWeight.w600, kFormSlate4)),
                      ],
                      if (code.isNotEmpty && location.isNotEmpty)
                        Text(' · ',
                            style: ffStyle(
                                12, FontWeight.w400, kFormBorder)),
                      if (location.isNotEmpty)
                        Flexible(
                          child: Text(location,
                              style: ffStyle(
                                  12, FontWeight.w400, kFormSlate4),
                              overflow: TextOverflow.ellipsis),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _inspStatusBg(status),
                          border: Border.all(
                              color: _inspStatusBdr(status)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _inspStatusLabel(status),
                          style: ffStyle(13, FontWeight.w800,
                              _inspStatusColor(status)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        lastDt != null
                            ? 'Last: ${relativeTime(lastStr)}'
                            : 'Never inspected',
                        style:
                            ffStyle(13, FontWeight.w400, kFormSlate4),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Selection circle
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected ? kFormBlue : kFormSurface,
                border: Border.all(
                  color: isSelected ? kFormBlue : kFormBorder,
                  width: 1.5,
                ),
                shape: BoxShape.circle,
              ),
              child: isSelected
                  ? const Icon(Icons.check_rounded,
                      size: 14, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Add New Asset button ─────────────────────────────────────────────────────
class _AddNewAssetButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddNewAssetButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: kFormBorder,
            width: 1.5,
            strokeAlign: BorderSide.strokeAlignCenter,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_rounded, size: 16, color: kFormSlate4),
            const SizedBox(width: 6),
            Text('Add New Asset',
                style: ffStyle(13, FontWeight.w600, kFormSlate4)),
          ],
        ),
      ),
    );
  }
}

// ── Sticky footer ────────────────────────────────────────────────────────────
class _StickyFooter extends StatelessWidget {
  final Map<String, dynamic>? selected;
  final bool starting;
  final VoidCallback onDeselect;
  final VoidCallback onBegin;

  const _StickyFooter({
    required this.selected,
    required this.starting,
    required this.onDeselect,
    required this.onBegin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x00FFFFFF), Colors.white, Colors.white],
          stops: [0.0, 0.25, 1.0],
        ),
      ),
      child: selected != null ? _selectedFooter() : _emptyFooter(),
    );
  }

  Widget _emptyFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.touch_app_outlined, size: 16, color: kFormSlate4),
        const SizedBox(width: 8),
        Text('Tap an asset to get started',
            style: ffStyle(13, FontWeight.w600, kFormSlate4)),
      ],
    );
  }

  Widget _selectedFooter() {
    final asset = selected!;
    final name = asset['name'] as String? ?? '';
    final code = asset['serial_or_vin'] as String? ?? '';
    final location = asset['location'] as String? ?? '';
    final category = asset['category'] as String?;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Recap strip
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F9FF),
            border: Border.all(
                color: const Color(0xFFBAE6FD), width: 1.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(_assetCategoryIcon(category),
                  size: 16, color: kFormBlue),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: ffStyle(13, FontWeight.w700, kFormSlate8),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    if (code.isNotEmpty || location.isNotEmpty)
                      Text(
                        [code, location]
                            .where((s) => s.isNotEmpty)
                            .join(' · '),
                        style:
                            ffStyle(13, FontWeight.w400, kFormSlate4),
                      ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onDeselect,
                child: const Icon(Icons.close_rounded,
                    size: 16, color: kFormSlate4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Begin Inspection button
        GestureDetector(
          onTap: starting ? null : onBegin,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [kFormGreen, kFormGreenDk],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: kFormGreen.withValues(alpha: 0.30),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (starting)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                else
                  const Icon(Icons.check_rounded,
                      size: 18, color: Colors.white),
                const SizedBox(width: 8),
                Text(starting ? 'Starting\u2026' : 'Begin Inspection',
                    style: ffStyle(15, FontWeight.w800, Colors.white)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Overflow bottom sheet ────────────────────────────────────────────────────
class _OverflowSheet extends StatelessWidget {
  final VoidCallback onDashboard;
  final VoidCallback onCancel;

  const _OverflowSheet({
    required this.onDashboard,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: kFormBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('OPTIONS',
                  style: ffStyle(13, FontWeight.w700, kFormSlate4)),
            ),
          ),
          const Divider(height: 1, color: kFormBorder),
          _OverflowItem(
            icon: Icons.home_rounded,
            label: 'Go to Dashboard',
            color: kFormSlate5,
            bg: kFormSurface,
            onTap: onDashboard,
          ),
          _OverflowItem(
            icon: Icons.warning_amber_rounded,
            label: 'Cancel Inspection',
            color: _kRed,
            bg: _kRedBg,
            onTap: onCancel,
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }
}

class _OverflowItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bg;
  final VoidCallback onTap;

  const _OverflowItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.bg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 12),
            Text(label,
                style: ffStyle(
                    14,
                    FontWeight.w600,
                    color == _kRed ? _kRed : kFormSlate8)),
          ],
        ),
      ),
    );
  }
}

// ── Cancel bottom sheet ──────────────────────────────────────────────────────
class _CancelSheet extends StatelessWidget {
  final VoidCallback onKeep;
  final VoidCallback onConfirm;

  const _CancelSheet({required this.onKeep, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: kFormBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Warning icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _kRedBg,
                    border: Border.all(color: _kRedBdr),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.warning_amber_rounded,
                      size: 24, color: _kRed),
                ),
                const SizedBox(height: 16),
                Text('Cancel Inspection?',
                    style: ffStyle(18, FontWeight.w800, kFormSlate8)),
                const SizedBox(height: 6),
                Text(
                  'You\u2019ll lose your form selection and asset. '
                  'You can always start a new inspection from the dashboard.',
                  style: ffStyle(13, FontWeight.w400, kFormSlate5),
                ),
                const SizedBox(height: 24),
                // Red confirm button
                GestureDetector(
                  onTap: onConfirm,
                  child: Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [_kRed, Color(0xFFDC2626)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color:
                              _kRed.withValues(alpha: 0.25),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text('Yes, Cancel Inspection',
                          style: ffStyle(
                              14, FontWeight.w800, Colors.white)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Keep going button
                GestureDetector(
                  onTap: onKeep,
                  child: Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: kFormSurface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text('Keep Going',
                          style: ffStyle(
                              14, FontWeight.w700, kFormSlate5)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 24),
        ],
      ),
    );
  }
}
