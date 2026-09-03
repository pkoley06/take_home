import '../../domain/entities/dashboard_card_config.dart';
import '../../domain/entities/dashboard_card_type.dart';

class DashboardCardModel extends DashboardCardConfig {
  const DashboardCardModel({
    required super.type,
    required super.sortOrder,
    super.isVisible,
  });

  factory DashboardCardModel.fromMap(Map<String, Object?> map) {
    return DashboardCardModel(
      type: DashboardCardType.values.byName(map['id']! as String),
      sortOrder: map['sort_order']! as int,
      isVisible: (map['is_visible']! as int) == 1,
    );
  }

  factory DashboardCardModel.fromEntity(DashboardCardConfig entity) {
    return DashboardCardModel(
      type: entity.type,
      sortOrder: entity.sortOrder,
      isVisible: entity.isVisible,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': type.name,
      'sort_order': sortOrder,
      'is_visible': isVisible ? 1 : 0,
    };
  }
}
