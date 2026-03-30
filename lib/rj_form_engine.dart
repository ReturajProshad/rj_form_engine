/// rj_form_engine — A schema-driven form engine for Flutter.
///
/// Build any number of forms from a simple [FieldMeta] schema.
/// Supports text, number, date, cascading dropdowns, image upload,
/// textarea, and fully custom fields — with zero external dependencies.
library rj_form_engine;

// Models
export 'src/models/field_meta.dart';
export 'src/models/dropdown_item.dart';
export 'src/models/dropdown_source.dart';
export 'src/models/form_result.dart';

// State
export 'src/state/form_controller.dart';

// Theme
export 'src/theme/form_theme.dart';

// Widgets
export 'src/widgets/rj_form.dart';
