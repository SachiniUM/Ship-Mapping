import 'package:flutter/material.dart';

class CustomNotificationPopup extends StatefulWidget {
  final String title;
  final String? description;
  final MessageType messageType;
  final IconData? customIcon;
  final List<CustomNotificationButton>? buttons;

  CustomNotificationPopup({
    required this.title,
    this.description,
    required this.messageType,
    this.customIcon,
    this.buttons,
  });

  @override
  _CustomNotificationPopupState createState() => _CustomNotificationPopupState();

  static void showCustomNotificationPopup(BuildContext context, {
    required String title,
    required String description,
    required MessageType messageType,
    IconData? customIcon,
    List<CustomNotificationButton>? buttons,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CustomNotificationPopup(
          title: title,
          description: description,
          messageType: messageType,
          customIcon: customIcon,
          buttons: buttons,
        );
      },
    );
  }
}


class _CustomNotificationPopupState extends State<CustomNotificationPopup> {

  Color? _getColor() {
    switch (widget.messageType) {
      case MessageType.Information:
        return Colors.lightBlue[200];
      case MessageType.Warning:
        return Colors.amber[400];
      case MessageType.Error:
        return Colors.red[400];
      default:
        return Colors.grey; // Default color for unknown message types
    }
  }

  IconData _getIcon() {
    switch (widget.messageType) {
      case MessageType.Information:
        return Icons.info_outline_rounded;
      case MessageType.Warning:
        return Icons.warning_amber_rounded;
      case MessageType.Error:
        return Icons.report_gmailerrorred;
      default:
        return Icons.info; // Default icon for unknown message types
    }
  }

  IconData get effectiveIcon => widget.customIcon ?? _getIcon();

  @override
  Widget build(BuildContext context) {
    List<CustomNotificationButton>? allButtons = widget.buttons;
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;
    return AlertDialog(
      content: Container(
        width: screenWidth * 0.4,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                Container(
                  height: screenHeight * 0.10,
                  alignment: Alignment.topCenter,
                  child: Container(
                    decoration: BoxDecoration(
                      color: _getColor(),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16.0),
                        topRight: Radius.circular(16.0),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Center(
                            child: Icon(effectiveIcon, size: screenHeight * 0.06),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: IconButton(
                    icon: Icon(Icons.close, color: Colors.white),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ],
            ),
            Container(
              margin: EdgeInsets.all(30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(widget.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25)),
                ],
              ),
            ),
            Container(
              margin: EdgeInsets.fromLTRB(20, 10, 20, 30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.description!),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: allButtons != null && allButtons.isNotEmpty
          ? [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (var button in allButtons)
              CustomNotificationButton(
                name: button.name,
                color: button.color ?? _getColor(),
                textColor: button.textColor ?? Colors.black,
                onPressed: button.onPressed,
              ),
          ],
        ),
      ]
          : [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomNotificationButton(
              name: 'OK',
              color: _getColor() ?? Colors.grey,
              onPressed: () {
                Navigator.of(context).pop();
              },
              textColor: Colors.black,
            ),
          ],
        ),
      ],
      insetPadding: EdgeInsets.zero,
      backgroundColor: Colors.white,
      contentPadding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
    );
  }


}



enum MessageType {
  Information,
  Warning,
  Error,
}

class CustomNotificationButton extends StatelessWidget {
  final String name;
  final Color? color;
  final Color? textColor;
  final VoidCallback onPressed;

  CustomNotificationButton({
    required this.name,
    this.color,
    this.textColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(backgroundColor: color),
      child: Text(
        name,
        style: TextStyle(color: textColor),
      ),
    );
  }
}
