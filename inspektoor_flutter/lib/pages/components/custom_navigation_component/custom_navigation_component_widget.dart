import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:math';
import 'dart:ui';
import '/index.dart';
import '/features/asset_selection/pages/select_asset_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'custom_navigation_component_model.dart';
export 'custom_navigation_component_model.dart';

class CustomNavigationComponentWidget extends StatefulWidget {
  const CustomNavigationComponentWidget({
    super.key,
    int? selectedPageIndex,
    bool? hidden,
    bool? showCentralButton,
    this.onTapCentralButton,
  })  : this.selectedPageIndex = selectedPageIndex ?? 1,
        this.hidden = hidden ?? false,
        this.showCentralButton = showCentralButton ?? false;

  final int selectedPageIndex;
  final bool hidden;
  final bool showCentralButton;
  final Future Function()? onTapCentralButton;

  @override
  State<CustomNavigationComponentWidget> createState() =>
      _CustomNavigationComponentWidgetState();
}

class _CustomNavigationComponentWidgetState
    extends State<CustomNavigationComponentWidget>
    with TickerProviderStateMixin {
  late CustomNavigationComponentModel _model;

  final animationsMap = <String, AnimationInfo>{};

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => CustomNavigationComponentModel());

    animationsMap.addAll({
      'verticalDividerOnPageLoadAnimation1': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          ScaleEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 150.0.ms,
            begin: Offset(1.0, 0.6),
            end: Offset(1.0, 1.0),
          ),
          FadeEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 150.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
        ],
      ),
      'verticalDividerOnPageLoadAnimation2': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          ScaleEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 150.0.ms,
            begin: Offset(1.0, 0.6),
            end: Offset(1.0, 1.0),
          ),
          FadeEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 150.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
        ],
      ),
      'verticalDividerOnPageLoadAnimation3': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          ScaleEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 150.0.ms,
            begin: Offset(1.0, 0.6),
            end: Offset(1.0, 1.0),
          ),
          FadeEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 150.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
        ],
      ),
      'verticalDividerOnPageLoadAnimation4': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          ScaleEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 150.0.ms,
            begin: Offset(1.0, 0.6),
            end: Offset(1.0, 1.0),
          ),
          FadeEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 150.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
        ],
      ),
      'containerOnPageLoadAnimation1': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          MoveEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 400.0.ms,
            begin: Offset(4.0, 0.0),
            end: Offset(0.0, 0.0),
          ),
          FadeEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 400.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
        ],
      ),
      'dividerOnPageLoadAnimation1': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          ScaleEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 150.0.ms,
            begin: Offset(0.6, 1.0),
            end: Offset(1.0, 1.0),
          ),
          FadeEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 150.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
        ],
      ),
      'dividerOnPageLoadAnimation2': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          ScaleEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 150.0.ms,
            begin: Offset(0.6, 1.0),
            end: Offset(1.0, 1.0),
          ),
          FadeEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 150.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
        ],
      ),
      'dividerOnPageLoadAnimation3': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          ScaleEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 150.0.ms,
            begin: Offset(0.6, 1.0),
            end: Offset(1.0, 1.0),
          ),
          FadeEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 150.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
        ],
      ),
      'dividerOnPageLoadAnimation4': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          ScaleEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 150.0.ms,
            begin: Offset(0.6, 1.0),
            end: Offset(1.0, 1.0),
          ),
          FadeEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 150.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
        ],
      ),
      'containerOnPageLoadAnimation2': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          MoveEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 400.0.ms,
            begin: Offset(0.0, 4.0),
            end: Offset(0.0, 0.0),
          ),
          FadeEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 400.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
        ],
      ),
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: widget!.hidden != true,
      child: Stack(
        children: [
          if (responsiveVisibility(
            context: context,
            phone: false,
          ))
            Align(
              alignment: AlignmentDirectional(1.0, 0.0),
              child: Padding(
                padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 16.0, 0.0),
                child: Container(
                  width: 70.0,
                  height: valueOrDefault<double>(
                    widget!.showCentralButton ? 360.0 : 284.0,
                    360.0,
                  ),
                  decoration: BoxDecoration(
                    color: FlutterFlowTheme.of(context).primary,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (widget!.selectedPageIndex == 1)
                            SizedBox(
                              height: 30.0,
                              child: VerticalDivider(
                                width: 2.0,
                                thickness: 2.0,
                                color: FlutterFlowTheme.of(context).lineColor,
                              ),
                            ).animateOnPageLoad(animationsMap[
                                'verticalDividerOnPageLoadAnimation1']!),
                          MouseRegion(
                            opaque: false,
                            cursor: MouseCursor.defer ?? MouseCursor.defer,
                            child: Opacity(
                              opacity:
                                  widget!.selectedPageIndex == 1 ? 1.0 : 0.5,
                              child: FlutterFlowIconButton(
                                key: ValueKey('HomeIconButton'),
                                borderRadius: 30.0,
                                borderWidth: 0.0,
                                buttonSize: 50.0,
                                hoverColor:
                                    FlutterFlowTheme.of(context).secondary,
                                icon: Icon(
                                  Icons.cottage_outlined,
                                  color: FlutterFlowTheme.of(context)
                                      .navbarIconColor,
                                  size: 24.0,
                                ),
                                onPressed: () async {
                                  context.goNamed(
                                    HomePageWidget.routeName,
                                    extra: <String, dynamic>{
                                      '__transition_info__': TransitionInfo(
                                        hasTransition: true,
                                        transitionType: PageTransitionType.fade,
                                        duration: Duration(milliseconds: 0),
                                      ),
                                    },
                                  );
                                },
                              ),
                            ),
                            onEnter: ((event) async {
                              safeSetState(
                                  () => _model.homeMouseRegionHovered1 = true);
                            }),
                            onExit: ((event) async {
                              safeSetState(
                                  () => _model.homeMouseRegionHovered1 = false);
                            }),
                          ),
                        ].divide(SizedBox(width: 4.0)),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (widget!.selectedPageIndex == 2)
                            SizedBox(
                              height: 30.0,
                              child: VerticalDivider(
                                width: 2.0,
                                thickness: 2.0,
                                color: FlutterFlowTheme.of(context).lineColor,
                              ),
                            ).animateOnPageLoad(animationsMap[
                                'verticalDividerOnPageLoadAnimation2']!),
                          MouseRegion(
                            opaque: false,
                            cursor: MouseCursor.defer ?? MouseCursor.defer,
                            child: Opacity(
                              opacity:
                                  widget!.selectedPageIndex == 2 ? 1.0 : 0.5,
                              child: FlutterFlowIconButton(
                                key: ValueKey('NoteIconButton'),
                                borderRadius: 30.0,
                                borderWidth: 0.0,
                                buttonSize: 50.0,
                                hoverColor:
                                    FlutterFlowTheme.of(context).secondary,
                                icon: Icon(
                                  Icons.note_alt_outlined,
                                  color: FlutterFlowTheme.of(context)
                                      .navbarIconColor,
                                  size: 24.0,
                                ),
                                onPressed: () async {
                                  context.goNamed(
                                    HomePageWidget.routeName,
                                    extra: <String, dynamic>{
                                      '__transition_info__': TransitionInfo(
                                        hasTransition: true,
                                        transitionType: PageTransitionType.fade,
                                        duration: Duration(milliseconds: 0),
                                      ),
                                    },
                                  );
                                },
                              ),
                            ),
                            onEnter: ((event) async {
                              safeSetState(
                                  () => _model.noteMouseRegionHovered1 = true);
                            }),
                            onExit: ((event) async {
                              safeSetState(
                                  () => _model.noteMouseRegionHovered1 = false);
                            }),
                          ),
                        ].divide(SizedBox(width: 4.0)),
                      ),
                      if (widget!.showCentralButton == true) Spacer(),
                      Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (widget!.selectedPageIndex == 3)
                            SizedBox(
                              height: 30.0,
                              child: VerticalDivider(
                                width: 2.0,
                                thickness: 2.0,
                                color: FlutterFlowTheme.of(context).lineColor,
                              ),
                            ).animateOnPageLoad(animationsMap[
                                'verticalDividerOnPageLoadAnimation3']!),
                          Opacity(
                            opacity: widget!.selectedPageIndex == 3 ? 1.0 : 0.5,
                            child: FlutterFlowIconButton(
                              key: ValueKey('ProfileIconButton'),
                              borderRadius: 30.0,
                              borderWidth: 0.0,
                              buttonSize: 50.0,
                              hoverColor:
                                  FlutterFlowTheme.of(context).secondary,
                              icon: Icon(
                                Icons.person_outline,
                                color: FlutterFlowTheme.of(context)
                                    .navbarIconColor,
                                size: 24.0,
                              ),
                              onPressed: () async {
                                context.goNamed(
                                  HomePageWidget.routeName,
                                  extra: <String, dynamic>{
                                    '__transition_info__': TransitionInfo(
                                      hasTransition: true,
                                      transitionType: PageTransitionType.fade,
                                      duration: Duration(milliseconds: 0),
                                    ),
                                  },
                                );
                              },
                            ),
                          ),
                        ].divide(SizedBox(width: 4.0)),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (widget!.selectedPageIndex == 4)
                            SizedBox(
                              height: 30.0,
                              child: VerticalDivider(
                                width: 2.0,
                                thickness: 2.0,
                                color: FlutterFlowTheme.of(context).lineColor,
                              ),
                            ).animateOnPageLoad(animationsMap[
                                'verticalDividerOnPageLoadAnimation4']!),
                          Opacity(
                            opacity: widget!.selectedPageIndex == 4 ? 1.0 : 0.5,
                            child: FlutterFlowIconButton(
                              key: ValueKey('SettingsIconButton'),
                              borderRadius: 30.0,
                              borderWidth: 0.0,
                              buttonSize: 50.0,
                              hoverColor:
                                  FlutterFlowTheme.of(context).secondary,
                              icon: Icon(
                                Icons.settings_outlined,
                                color: FlutterFlowTheme.of(context)
                                    .navbarIconColor,
                                size: 24.0,
                              ),
                              onPressed: () async {
                                context.goNamed(
                                  HomePageWidget.routeName,
                                  extra: <String, dynamic>{
                                    '__transition_info__': TransitionInfo(
                                      hasTransition: true,
                                      transitionType: PageTransitionType.fade,
                                      duration: Duration(milliseconds: 0),
                                    ),
                                  },
                                );
                              },
                            ),
                          ),
                        ].divide(SizedBox(width: 4.0)),
                      ),
                    ]
                        .divide(SizedBox(height: 16.0))
                        .addToStart(SizedBox(height: 16.0))
                        .addToEnd(SizedBox(height: 16.0)),
                  ),
                ),
              ),
            ),
          if ((widget!.showCentralButton == true) &&
              responsiveVisibility(
                context: context,
                phone: false,
              ))
            Align(
              alignment: AlignmentDirectional(1.0, 0.0),
              child: Padding(
                padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 16.0, 0.0),
                child: ClipOval(
                  child: Container(
                    width: 70.0,
                    height: 70.0,
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 4.0,
                          color: Color(0x33000000),
                          offset: Offset(
                            0.0,
                            2.0,
                          ),
                        )
                      ],
                      gradient: LinearGradient(
                        colors: [
                          FlutterFlowTheme.of(context).primary,
                          FlutterFlowTheme.of(context).secondary
                        ],
                        stops: [0.0, 1.0],
                        begin: AlignmentDirectional(0.0, -1.0),
                        end: AlignmentDirectional(0, 1.0),
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: FlutterFlowIconButton(
                      borderRadius: 20.0,
                      borderWidth: 0.0,
                      buttonSize: 10.0,
                      hoverColor: FlutterFlowTheme.of(context).secondary,
                      icon: Icon(
                        Icons.add,
                        color: FlutterFlowTheme.of(context).navbarIconColor,
                        size: 32.0,
                      ),
                      onPressed: () async {
                        await widget.onTapCentralButton?.call();
                      },
                    ),
                  ),
                ).animateOnPageLoad(
                    animationsMap['containerOnPageLoadAnimation1']!),
              ),
            ),
          if (responsiveVisibility(
            context: context,
            tablet: false,
            tabletLandscape: false,
            desktop: false,
          ))
            Align(
              alignment: AlignmentDirectional(0.0, 1.0),
              child: Padding(
                padding: EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 16.0),
                child: Container(
                  width: 360.0,
                  height: 70.0,
                  decoration: BoxDecoration(
                    color: FlutterFlowTheme.of(context).primary,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          MouseRegion(
                            opaque: false,
                            cursor: MouseCursor.defer ?? MouseCursor.defer,
                            child: Opacity(
                              opacity:
                                  widget!.selectedPageIndex == 1 ? 1.0 : 0.5,
                              child: FlutterFlowIconButton(
                                key: ValueKey('HomeIconButton'),
                                borderColor: Colors.transparent,
                                borderRadius: 30.0,
                                borderWidth: 0.0,
                                buttonSize: 50.0,
                                hoverColor:
                                    FlutterFlowTheme.of(context).secondary,
                                icon: Icon(
                                  Icons.window,
                                  color: FlutterFlowTheme.of(context)
                                      .navbarIconColor,
                                  size: 24.0,
                                ),
                                onPressed: () async {
                                  context.goNamed(
                                    HomePageWidget.routeName,
                                    extra: <String, dynamic>{
                                      '__transition_info__': TransitionInfo(
                                        hasTransition: true,
                                        transitionType: PageTransitionType.fade,
                                      ),
                                    },
                                  );
                                },
                              ),
                            ),
                            onEnter: ((event) async {
                              safeSetState(
                                  () => _model.homeMouseRegionHovered2 = true);
                            }),
                            onExit: ((event) async {
                              safeSetState(
                                  () => _model.homeMouseRegionHovered2 = false);
                            }),
                          ),
                          if (widget!.selectedPageIndex == 1)
                            SizedBox(
                              width: 30.0,
                              child: Divider(
                                height: 2.0,
                                thickness: 2.0,
                                color: FlutterFlowTheme.of(context).lineColor,
                              ),
                            ).animateOnPageLoad(
                                animationsMap['dividerOnPageLoadAnimation1']!),
                        ],
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          MouseRegion(
                            opaque: false,
                            cursor: MouseCursor.defer ?? MouseCursor.defer,
                            child: Opacity(
                              opacity:
                                  widget!.selectedPageIndex == 2 ? 1.0 : 0.5,
                              child: FlutterFlowIconButton(
                                key: ValueKey('NoteIconButton'),
                                borderColor: Colors.transparent,
                                borderRadius: 30.0,
                                borderWidth: 0.0,
                                buttonSize: 50.0,
                                hoverColor:
                                    FlutterFlowTheme.of(context).secondary,
                                icon: FaIcon(
                                  FontAwesomeIcons.clipboardList,
                                  color: FlutterFlowTheme.of(context)
                                      .navbarIconColor,
                                  size: 24.0,
                                ),
                                onPressed: () async {
                                  context.goNamed(
                                    SelectAssetPage.routeName,
                                    extra: <String, dynamic>{
                                      '__transition_info__': TransitionInfo(
                                        hasTransition: true,
                                        transitionType: PageTransitionType.fade,
                                      ),
                                    },
                                  );
                                },
                              ),
                            ),
                            onEnter: ((event) async {
                              safeSetState(
                                  () => _model.noteMouseRegionHovered2 = true);
                            }),
                            onExit: ((event) async {
                              safeSetState(
                                  () => _model.noteMouseRegionHovered2 = false);
                            }),
                          ),
                          if (widget!.selectedPageIndex == 2)
                            SizedBox(
                              width: 30.0,
                              child: Divider(
                                height: 2.0,
                                thickness: 2.0,
                                color: FlutterFlowTheme.of(context).lineColor,
                              ),
                            ).animateOnPageLoad(
                                animationsMap['dividerOnPageLoadAnimation2']!),
                        ],
                      ),
                      if (widget!.showCentralButton == true) Spacer(),
                      Column(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Opacity(
                            opacity: widget!.selectedPageIndex == 3 ? 1.0 : 0.5,
                            child: FlutterFlowIconButton(
                              key: ValueKey('ProfileIconButton'),
                              borderColor: Colors.transparent,
                              borderRadius: 30.0,
                              borderWidth: 0.0,
                              buttonSize: 50.0,
                              hoverColor:
                                  FlutterFlowTheme.of(context).secondary,
                              icon: FaIcon(
                                FontAwesomeIcons.layerGroup,
                                color: FlutterFlowTheme.of(context)
                                    .navbarIconColor,
                                size: 24.0,
                              ),
                              onPressed: () async {
                                context.goNamed(
                                  AssetListPageWidget.routeName,
                                  extra: <String, dynamic>{
                                    '__transition_info__': TransitionInfo(
                                      hasTransition: true,
                                      transitionType: PageTransitionType.fade,
                                    ),
                                  },
                                );
                              },
                            ),
                          ),
                          if (widget!.selectedPageIndex == 3)
                            SizedBox(
                              width: 30.0,
                              child: Divider(
                                height: 2.0,
                                thickness: 2.0,
                                color: FlutterFlowTheme.of(context).lineColor,
                              ),
                            ).animateOnPageLoad(
                                animationsMap['dividerOnPageLoadAnimation3']!),
                        ],
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Opacity(
                            opacity: widget!.selectedPageIndex == 4 ? 1.0 : 0.5,
                            child: FlutterFlowIconButton(
                              key: ValueKey('SettingsIconButton'),
                              borderColor: Colors.transparent,
                              borderRadius: 30.0,
                              borderWidth: 0.0,
                              buttonSize: 50.0,
                              hoverColor:
                                  FlutterFlowTheme.of(context).secondary,
                              icon: FaIcon(
                                FontAwesomeIcons.bell,
                                color: FlutterFlowTheme.of(context)
                                    .navbarIconColor,
                                size: 24.0,
                              ),
                              onPressed: () async {
                                context.goNamed(
                                  HomePageWidget.routeName,
                                  extra: <String, dynamic>{
                                    '__transition_info__': TransitionInfo(
                                      hasTransition: true,
                                      transitionType: PageTransitionType.fade,
                                    ),
                                  },
                                );
                              },
                            ),
                          ),
                          if (widget!.selectedPageIndex == 4)
                            SizedBox(
                              width: 30.0,
                              child: Divider(
                                height: 2.0,
                                thickness: 2.0,
                                color: FlutterFlowTheme.of(context).lineColor,
                              ),
                            ).animateOnPageLoad(
                                animationsMap['dividerOnPageLoadAnimation4']!),
                        ],
                      ),
                    ]
                        .divide(SizedBox(width: 16.0))
                        .addToStart(SizedBox(width: 16.0))
                        .addToEnd(SizedBox(width: 16.0)),
                  ),
                ),
              ),
            ),
          if ((widget!.showCentralButton == true) &&
              responsiveVisibility(
                context: context,
                tablet: false,
                tabletLandscape: false,
                desktop: false,
              ))
            Align(
              alignment: AlignmentDirectional(0.0, 1.0),
              child: Padding(
                padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 32.0),
                child: ClipOval(
                  child: Container(
                    width: 70.0,
                    height: 70.0,
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 4.0,
                          color: Color(0x33000000),
                          offset: Offset(
                            0.0,
                            2.0,
                          ),
                        )
                      ],
                      gradient: LinearGradient(
                        colors: [
                          FlutterFlowTheme.of(context).customBlueDark,
                          FlutterFlowTheme.of(context).customBlueLight
                        ],
                        stops: [0.0, 1.0],
                        begin: AlignmentDirectional(0.0, -1.0),
                        end: AlignmentDirectional(0, 1.0),
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: FlutterFlowIconButton(
                      borderColor: Colors.transparent,
                      borderRadius: 20.0,
                      borderWidth: 0.0,
                      buttonSize: 10.0,
                      hoverColor: FlutterFlowTheme.of(context).secondary,
                      icon: Icon(
                        Icons.add,
                        color: FlutterFlowTheme.of(context).navbarIconColor,
                        size: 32.0,
                      ),
                      onPressed: () async {
                        await widget.onTapCentralButton?.call();
                      },
                    ),
                  ),
                ).animateOnPageLoad(
                    animationsMap['containerOnPageLoadAnimation2']!),
              ),
            ),
        ],
      ),
    );
  }
}
