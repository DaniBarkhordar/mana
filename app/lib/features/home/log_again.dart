/// What "Log again" writes: the same foods, the same grams, logged now.
///
/// The one change is provenance. A component that was weighed the first time
/// is not weighed the second: nobody put today's plate on the scale, the user
/// tapped a button and asserted the number. So it is re-logged as
/// [PortionMethod.manualGrams] — a figure entered by hand, with that method's
/// published error — and the row's badge says "Estimated". Anything that was
/// already an estimate keeps its own method. The alternative, re-logging as
/// "Weighed", would print a provenance that is not true, and the whole
/// product rests on that badge meaning what it says.
library;

import '../../core/nutrition/models.dart';
import '../../core/nutrition/portion.dart';

/// The components of a previous meal as they should be logged a second time.
List<LoggedComponent> componentsForLogAgain(List<LoggedComponent> source) => [
      for (final c in source)
        LoggedComponent(
          food: c.food,
          grams: c.grams,
          method: c.method == PortionMethod.weighed
              ? PortionMethod.manualGrams
              : c.method,
          note: c.note,
          isCookingFat: c.isCookingFat,
        ),
    ];
