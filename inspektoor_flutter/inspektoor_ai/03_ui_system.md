UI System Map
Generated: 2026-02-28
Updated: 2026-03-14
Source: flutter_flow_theme.dart, flutter_flow_widgets.dart, custom_icons.dart,
        button_main_widget.dart, dashboard_tile_lg_blue_widget.dart,
        custom_navigation_component_widget.dart

--------------------------------------------------
Field Readability Guidelines
--------------------------------------------------

This app is used outdoors in the field — bright sunlight, gloved hands,
quick glances at arm's length. All custom feature UI must follow these
minimums. (Added 2026-03-14.)

  Minimum font size:   12px — nothing smaller, even for badges and hints
  Minimum icon size:   16px — for any visible icon
  Minimum tap target:  44x44 — iOS HIG guideline for gloved/outdoor use
  Preferred body text: 13-15px — primary content the user reads mid-task
  Headers:             17-20px — page titles and section headers

  Bump rules applied (2026-03-14):
    9  -> 12
    10 -> 12
    11 -> 12
    12 -> 13
    13+ -> no change

--------------------------------------------------
Theme Entry Point
--------------------------------------------------

File: lib/flutter_flow/flutter_flow_theme.dart

FlutterFlowTheme.of(context) is the single access point for all
colors and typography. It always returns LightModeTheme().
Dark mode is not implemented — the abstract class supports it
structurally but only one concrete class (LightModeTheme) exists.

Usage pattern throughout the codebase:
  FlutterFlowTheme.of(context).primary
  FlutterFlowTheme.of(context).bodyMedium

--------------------------------------------------
Color Palette — LightModeTheme
--------------------------------------------------

Core semantic colors:
  primary                   #27AAE2   (brand blue — main interactive color)
  secondary                 #BEE6F6   (light blue tint)
  tertiary                  #EE8B60   (orange accent — not widely used)
  alternate                 #E0E3E7   (light grey divider/border)
  primaryText               #1D354F   (dark navy — body text)
  secondaryText             #57636C   (medium grey — labels, captions)
  primaryBackground         #F1F4F8   (page background — cool off-white)
  secondaryBackground       #FFFFFF   (card/surface background)
  accent1–4                           (translucent tints, used sparingly)
  success                   #00AD07   (green)
  warning                   #FF9900   (amber)
  error                     #FF3333   (red)
  info                      #FFFFFF

App-specific custom colors (used in components):
  customBlueDark            #27AAE2   (same as primary — gradient end)
  customBlueLight           #82D9FF   (lighter blue — gradient start)
  customGreenDark           #76BD93
  customGreenLight          #B1E39B
  customRedDark             #F46572
  customRedLight            #FCA190
  customPurpleDark          #9D7BE7
  customPurpleLight         #C7AEFB
  customGreyDark            #808285
  customGreyLight           #C8C8C8
  customGreen               #0FB95B   (status green)
  customGreen02             #76BD93   (alias of customGreenDark)

UI structure colors:
  primaryBackground         #F1F4F8   (page bg)
  secondaryBackground       #FFFFFF   (card bg)
  backgroundCard            #262A34   (dark card bg — unused in light theme?)
  formFields                #EFF3FA   (input field fill)
  footerNav                 #E2E2E2
  navbarIconColor           #FFFFFF   (white icons on primary nav bar)
  lineColor                 #E0E3E7   (dividers)
  lightBorderDashedColor    #DEDEDE
  darkBorderColor           #1D354F

Splash screen specific:
  primarySplashBackgroundColor    #3B3834
  secondarySplashBackgroundColor  #7A736B

--------------------------------------------------
Typography — ThemeTypography
--------------------------------------------------

Font family: Inter (Google Fonts) — used exclusively across all styles.
No custom or fallback fonts.

Type scale (name / weight / size):
  displayLarge      SemiBold  64px
  displayMedium     SemiBold  44px
  displaySmall      SemiBold  36px
  headlineLarge     SemiBold  32px
  headlineMedium    SemiBold  28px
  headlineSmall     SemiBold  24px
  titleLarge        SemiBold  20px
  titleMedium       SemiBold  18px    — color: primaryText
  titleSmall        SemiBold  16px    — color: primaryText
  labelLarge        Regular   16px    — color: secondaryText
  labelMedium       Regular   14px    — color: secondaryText
  labelSmall        Regular   12px    — color: secondaryText
  bodyLarge         Regular   16px    — color: primaryText
  bodyMedium        Regular   14px    — color: primaryText
  bodySmall         Regular   12px    — color: primaryText

Pattern: titles use SemiBold + primaryText. Labels use Regular + secondaryText.
Body uses Regular + primaryText.

Override pattern used in components:
  FlutterFlowTheme.of(context).bodyMedium.override(
    font: GoogleFonts.inter(fontWeight: ..., fontStyle: ...),
    color: ...,
    fontSize: ...,
    letterSpacing: 0.0,
  )

TextStyleHelper extension (.override()) is the standard way to
customize a base style without replacing it entirely.

Deprecated aliases still present (title1, title2, subtitle1, etc.)
but all new code should use the Material 3 names (displaySmall, headlineMedium, etc.)

--------------------------------------------------
Custom Icon Sets — FFIcons
--------------------------------------------------

File: lib/flutter_flow/custom_icons.dart

Eight custom icon font families are registered:

  Inspektoor     — checkBox, multipleCheckBox, radioButtonChecked
  MyFlutterApp   — delete, edit, deleteOther
  Inspecktoor02  — chevronLeft
  Inspecktoor03  — menu
  Inspecktoor04  — moreVert
  Inspecktoor05  — binOutline, editOutline
  Inspecktoor06  — number
  Inspecktoor07  — calendar

These are domain-specific icons for inspection form field types and
common actions. Used alongside Material Icons and FontAwesome.

Icon packages in use: flutter (Material Icons), font_awesome_flutter,
custom FFIcons font families.

--------------------------------------------------
Reusable Widgets — FlutterFlow Layer
--------------------------------------------------

File: lib/flutter_flow/flutter_flow_widgets.dart

FFButtonWidget
  Standard button used everywhere.
  Wraps ElevatedButton / ElevatedButton.icon.
  Configured via FFButtonOptions (height, width, color, textStyle,
  borderRadius, borderSide, elevation, hover states).
  Shows CircularProgressIndicator during async onPressed.
  Default border radius: 8.0 (can be overridden per call site).

FFFocusIndicator
  Accessibility wrapper. Adds animated border on focus.
  Used as a builder or child wrapper.

Other flutter_flow/ widgets (not deeply read, classified by name):
  flutter_flow_checkbox_group.dart   — Multi-select checkbox lists
  flutter_flow_radio_button.dart     — Radio button group
  flutter_flow_drop_down.dart        — Dropdown selector
  flutter_flow_button_tabbar.dart    — Tab bar with button style
  flutter_flow_credit_card_form.dart — Credit card input (billing only)
  flutter_flow_icon_button.dart      — Icon-only button (FlutterFlowIconButton)
  flutter_flow_web_view.dart         — Embedded web view
  flutter_flow_animations.dart       — Animation helpers (flutter_animate)

--------------------------------------------------
Reusable Components — pages/components/
--------------------------------------------------

ButtonMainWidget (button_main/)
  App's primary CTA button wrapper over FFButtonWidget.
  Props: buttonText, buttonColor, buttonTextColor, borderColor,
         disableButton, buttonElevation, action (async callback).
  Defaults: color=#27AAE2, white text, elevation=3, radius=24.
  Width: double.infinity (full-width).
  Bottom padding: 16px.
  Disabled state: opacity 0.5, onPressed set to null.

DashboardTileLgBlueWidget (dashboard_tile_lg_blue/)
  170x170 square tile with rounded corners (radius 30).
  Layout: Stack with background decorative image + content column.
  Content: icon+title row, large numeric value (48px w500), description.
  Gradient: customBlueLight → customBlueDark (right to left).
  Text color: secondaryBackground (white) throughout.
  Four color variants exist: blue, green, purple, red.
  Each variant likely uses its corresponding custom color pair.

CustomNavigationComponentWidget (custom_navigation_component/)
  Responsive navigation bar — adapts between phone and tablet/desktop.

  Phone layout:
    Horizontal bar, 360x70, radius 8, color=primary (#27AAE2).
    Bottom-aligned, 16px insets from screen edges.
    4 tab items: Dashboard (window icon), Assets (clipboard-list),
                 Forms (layer-group), Notifications (bell).
    Active indicator: short horizontal Divider below icon (animated).
    Inactive items: opacity 0.5.
    Optional central FAB button (circular, 70x70, gradient blue,
    + icon, floats above bar, bottom-aligned).

  Desktop/tablet layout:
    Vertical sidebar pill, 70 wide, radius 8, right-aligned with 16px margin.
    Same 4 items as vertical stack.
    Active indicator: short VerticalDivider beside icon (animated).
    Same optional central FAB (circular, gradient).

  Animation: active item container slides in (MoveEffect 400ms easeInOut).
  Dividers animate with ScaleEffect + FadeEffect (150ms easeInOut).

  Navigation targets: index 1 = HomePage, index 2 = AssetListPage,
  index 3 = AssetListPage (placeholder), index 4 = HomePage (placeholder).
  NOTE: Indexes 3 and 4 route to placeholder destinations, suggesting
  the forms and notifications sections are not yet fully wired.

Other components (not deeply read, classified by name):
  app_drawer_content          Side drawer navigation (alternate to bottom nav)
  empty_list                  Empty state placeholder
  snackbar                    Toast notification display
  custom_confirm_dialog       Yes/No confirmation modal
  custom_message_dialog       Informational message modal
  option_row                  Single tappable row with label
  pin_code                    PIN entry widget
  card_editor_sheet           Bottom sheet for building inspection form cards
  inspection_gallery_more_options   Context menu for gallery items

--------------------------------------------------
Layout Conventions (inferred from components)
--------------------------------------------------

Spacing:
  Standard horizontal page padding: 16px (inferred from nav bar insets)
  Standard bottom padding on primary buttons: 16px
  Standard gap between nav items: 16px horizontal, 16px vertical
  Card internal padding: spaceEvenly with column/row layout

Borders:
  Cards and containers: BorderRadius.circular(8) default
  Primary button: BorderRadius.circular(24) — pill shape
  Dashboard tiles: BorderRadius.circular(30) — heavy rounding
  Nav bar: BorderRadius.circular(8)
  FAB: circular (BoxShape.circle)

Elevation:
  Default button elevation: 2.0 (FFButtonWidget), 3 (ButtonMain default)
  FAB shadow: blurRadius 4, offset (0, 2), color #33000000

Responsiveness:
  Uses FlutterFlow's responsiveVisibility() helper.
  Phone: bottom nav bar.
  Tablet/desktop: right-side vertical nav.

--------------------------------------------------
Observations
--------------------------------------------------

1. LIGHT MODE ONLY: No dark mode implementation exists. The theme class
   supports it structurally, but only LightModeTheme is used.

2. SINGLE FONT: Inter (Google Fonts) is used for all text. No secondary
   typeface.

3. BRAND COLOR: #27AAE2 (primary blue) is the dominant interactive color.
   It is used for the nav bar, primary buttons, and gradient anchors.

4. COLOR NAMING INCONSISTENCY: The custom color set mixes semantic names
   (customGreen, customRedDark) with arbitrary names (customColor17–20,
   variasion2, v3). The v3 / variasion2 / primaryBlue / darkThemeBlue
   tokens are likely unused or experimental.

5. DASHBOARD TILES: Four color variants (blue, green, purple, red) share
   the same layout. Each is a separate widget file rather than a single
   parameterized widget.

6. NAV ROUTING INCOMPLETE: The navigation component currently routes
   tabs 3 and 4 back to HomePage/AssetListPage. These are placeholders
   for forms and notifications sections not yet built.

7. CUSTOM ICONS: Eight separate icon font families suggest incremental
   addition of icons over time. They cover inspection-specific glyphs
   (checkbox, radio, multi-check, calendar, number) plus action icons.
