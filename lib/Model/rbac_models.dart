import 'package:flutter/material.dart';
import 'package:stock_management/Config/theme/app_theme.dart';

/// A single grantable capability in the system, e.g. "product:view".
class PermissionData {
  const PermissionData({
    required this.code,
    required this.category,
    required this.description,
  });

  final String code;
  final String category;
  final String description;

  PermissionData copyWith({String? code, String? category, String? description}) {
    return PermissionData(
      code: code ?? this.code,
      category: category ?? this.category,
      description: description ?? this.description,
    );
  }
}

/// A named security role (SUPER_ADMIN, Warehouse Staff, STAFF, ...) — admin-defined data, not a fixed set.
class RoleData {
  const RoleData({
    required this.name,
    required this.description,
    this.permissionCodes = const [],
  });

  final String name;
  final String description;
  final List<String> permissionCodes;

  RoleData copyWith({String? name, String? description, List<String>? permissionCodes}) {
    return RoleData(
      name: name ?? this.name,
      description: description ?? this.description,
      permissionCodes: permissionCodes ?? this.permissionCodes,
    );
  }
}

// A small rotating accent palette for role/permission-category pills.
// Roles are open-ended admin-defined data (unlike the old fixed 3-value
// TeamRole enum), so there's no fixed name -> color mapping anymore —
// instead every name gets a stable color from this list via its hash, so
// the same name always renders the same color without a lookup table.
List<Color> get _accentColors => [AppColors.brand700, AppColors.success, AppColors.warning, AppColors.danger];
List<Color> get _accentBgColors => [AppColors.brand50, AppColors.successBg, AppColors.warningBg, AppColors.dangerBg];

Color accentColorFor(String name) => _accentColors[name.hashCode.abs() % _accentColors.length];

Color accentBgFor(String name) => _accentBgColors[name.hashCode.abs() % _accentBgColors.length];
