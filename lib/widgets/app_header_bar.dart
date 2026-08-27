import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/extensions/context_extensions.dart';
import 'global_search_modal.dart';

class AppHeaderBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Widget? titleWidget;
  final bool showDrawerButton;
  final bool showBackButton;
  final bool? centerTitle;
  final double? titleSpacing;
  final double? leadingWidth;
  final Color? backgroundColor;
  final double? elevation;
  final Color? iconColor;
  final SystemUiOverlayStyle? systemOverlayStyle;
  final List<Widget>? actions;

  const AppHeaderBar({
    super.key,
    required this.title,
    this.titleWidget,
    this.showDrawerButton = true,
    this.showBackButton = false,
    this.centerTitle,
    this.titleSpacing,
    this.leadingWidth,
    this.backgroundColor,
    this.elevation,
    this.iconColor,
    this.systemOverlayStyle,
    this.actions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override 
  Widget build(BuildContext context) {
    return AppBar(
      centerTitle: centerTitle ?? true,
      titleSpacing: titleSpacing,
      leadingWidth: leadingWidth ?? (showBackButton && centerTitle == false ? 44 : null),
      backgroundColor: backgroundColor ?? Colors.transparent,
      elevation: elevation ?? 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: systemOverlayStyle,
      iconTheme: iconColor != null ? IconThemeData(color: iconColor) : null,
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back_rounded, size: 26),
              tooltip: 'Back',
              onPressed: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              },
            )
          : showDrawerButton
              ? IconButton(
                  icon: const Icon(Icons.menu_rounded, size: 26), 
                  tooltip: 'Open Menu',
                  onPressed: () {
                    _openDrawer(context);
                  },
                )
              : null,
      title: titleWidget ??
          Text(
            title,
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
              color: context.colorScheme.onSurface,
            ),
          ),
      actions: actions ?? [
        IconButton(
          icon: const Icon(Icons.search_rounded, size: 24),
          tooltip: 'Search Features & Quran',
          onPressed: () {
            GlobalSearchModal.show(context);
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  void _openDrawer(BuildContext context) {
    ScaffoldState? scaffoldState = context.findAncestorStateOfType<ScaffoldState>();
    while (scaffoldState != null) {
      if (scaffoldState.hasDrawer) {
        scaffoldState.openDrawer();
        return;
      }
      scaffoldState = scaffoldState.context.findAncestorStateOfType<ScaffoldState>();
    }
  }
}
