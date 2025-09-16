import 'package:driver/themes/app_colors.dart';
import 'package:driver/themes/responsive.dart';
import 'package:driver/utils/DarkThemeProvider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class ButtonThem {
  const ButtonThem({Key? key});

  static buildButton(
      BuildContext context, {
        required String title,
        double btnHeight = 48,
        double txtSize = 14,
        double btnWidthRatio = 0.9,
        double btnRadius = 10,
        required Function() onPress,
        bool isVisible = true,
        Color? customColor, // Added optional custom color parameter
        Color? textColor, // Optional text color override
      }) {
    // themeChange not needed here since color is unified across themes

    return Visibility(
      visible: isVisible,
      child: SizedBox(
        width: Responsive.width(100, context) * btnWidthRatio,
        child: MaterialButton(
          onPressed: onPress,
          height: btnHeight,
          elevation: 0.5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(btnRadius),
          ),
          // Use customColor if provided; otherwise always use green across themes
          color: customColor ?? AppColors.darkModePrimary,
          child: Text(
            title.toUpperCase(),
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
                color: textColor ?? Colors.black,
                fontSize: txtSize, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  static buildBorderButton(
      BuildContext context, {
        required String title,
        double btnHeight = 50,
        double txtSize = 14,
        double btnWidthRatio = 0.9,
        double borderRadius = 10,
        required Function() onPress,
        bool isVisible = true,
        bool iconVisibility = false,
        String iconAssetImage = '',
        Color? color,
        Color? textColor,
      }) {
    final themeChange = Provider.of<DarkThemeProvider>(context);

    return Visibility(
      visible: isVisible,
      child: SizedBox(
        width: Responsive.width(100, context) * btnWidthRatio,
        height: btnHeight,
        child: ElevatedButton(
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all<Color>(
                themeChange.getThem() ? Colors.transparent : Colors.white),
            foregroundColor: MaterialStateProperty.all<Color>(
                themeChange.getThem()
                    ? AppColors.darkModePrimary
                    : Colors.white),
            shape: MaterialStateProperty.all<RoundedRectangleBorder>(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(borderRadius),
                side: BorderSide(
                  color: color ??
                      (themeChange.getThem()
                          ? AppColors.darkModePrimary
                          : AppColors.primary),
                ),
              ),
            ),
          ),
          onPressed: onPress,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Visibility(
                visible: iconVisibility,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child:
                  Image.asset(iconAssetImage, fit: BoxFit.cover, width: 32),
                ),
              ),
              Text(
                title.toUpperCase(),
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    color: textColor ??
                        (color ??
                            (themeChange.getThem()
                                ? AppColors.darkModePrimary
                                : AppColors.primary)),
                    fontSize: txtSize,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static roundButton(
      BuildContext context, {
        required String title,
        double btnHeight = 48,
        double txtSize = 14,
        double btnWidthRatio = 0.9,
        required Function() onPress,
        bool isVisible = true,
      }) {
    // themeChange not needed here since color is unified across themes

    return Visibility(
      visible: isVisible,
      child: SizedBox(
        width: Responsive.width(100, context) * btnWidthRatio,
        child: MaterialButton(
          onPressed: onPress,
          height: btnHeight,
          elevation: 0.5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          // Always use green across themes
          color: AppColors.darkModePrimary,
          child: Text(
            title.toUpperCase(),
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
                color: Colors.black,
                fontSize: txtSize, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
