import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:plainscan/core/controllers/alltool_controller.dart';
import 'package:plainscan/features/alltools/widgets/buildFilters.dart';
import 'package:plainscan/features/alltools/widgets/buildHeader.dart';
import 'package:plainscan/features/alltools/widgets/buildSearchbar.dart';
import 'package:plainscan/features/alltools/widgets/buildToollist.dart';

class AllTools extends StatelessWidget {
  final bool showBackButton;

  AllTools({
    super.key,
    this.showBackButton = true,
  });

  final AllToolsController controller = Get.isRegistered<AllToolsController>()
      ? Get.find<AllToolsController>()
      : Get.put(AllToolsController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FD),
      body: SafeArea(
        child: Column(
          children: [
            buildHeader(showBack: showBackButton),
            buildSearchBar(),
            buildFilters(),
            buildToolList(),
          ],
        ),
      ),
    );
  }

 
 

  

}