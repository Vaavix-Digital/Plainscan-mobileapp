import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:plainscan/core/controllers/alltool_controller.dart';
import 'package:plainscan/features/alltools/widgets/buildFilters.dart';
import 'package:plainscan/features/alltools/widgets/buildHeader.dart';
import 'package:plainscan/features/alltools/widgets/buildSearchbar.dart';
import 'package:plainscan/features/alltools/widgets/buildToollist.dart';

class AllTools extends StatelessWidget {
  AllTools({super.key});

  final AllToolsController controller =
      Get.put(AllToolsController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FD),
      body: SafeArea(
        child: Column(
          children: [
            buildHeader(),
            buildSearchBar(),
            buildFilters(),
            buildToolList(),
          ],
        ),
      ),
    );
  }

 
 

  

}