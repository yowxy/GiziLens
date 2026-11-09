import 'food_component_model.dart';
import 'target_akg_model.dart';

class InspectionSession {
  InspectionSession._();

  static final InspectionSession instance = InspectionSession._();

  TargetAkgModel targetAkg = TargetAkgModel.standardPresets[1];
  List<FoodComponentModel> components =
      FoodComponentModel.getSampleComponents();
}
