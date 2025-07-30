import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:medilab_prokit/components/MLCommonDiseaseListComponent.dart';
import 'package:medilab_prokit/model/MLDiseaseData.dart';
import 'package:medilab_prokit/utils/MLColors.dart';
import 'package:medilab_prokit/utils/MLCommon.dart';
import 'package:medilab_prokit/utils/MLDataProvider.dart';
import 'package:medilab_prokit/main.dart';

class MLCommonDiseaseScreen extends StatefulWidget {
  static String tag = '/MLCommonDiseaseScreen';

  @override
  MLCommonDiseaseScreenState createState() => MLCommonDiseaseScreenState();
}

class MLCommonDiseaseScreenState extends State<MLCommonDiseaseScreen> {
  int i = 0;
  List<MLDiseaseData> data = mlDiseaseDataList();

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    //
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: mlPrimaryColor,
        body: Container(
          padding: EdgeInsets.all(16.0),
          decoration: boxDecorationWithRoundedCorners(
            borderRadius: radiusOnly(topRight: 32),
            backgroundColor: appStore.isDarkModeOn ? black : white,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              8.height,
              Row(
                children: [
                  8.width,
                  mlBackToPreviousWidget(context, appStore.isDarkModeOn ? white : blackColor),
                  8.width,
                  Text('Common Disesase', style: boldTextStyle(size: 24)).expand(),
                ],
              ),
              16.height,
              MLCommonDiseaseListComponent().expand()
            ],
          ),
        ),
      ),
    );
  }
}
