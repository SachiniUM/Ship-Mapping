import 'package:flutter/material.dart';

import '../common/pop_up_notification.dart';


class HttpErrorHandler {
   static showStatusDialog(BuildContext context, int statusCode, String reasonPhrase) {
    CustomNotificationPopup.showCustomNotificationPopup(
        context,
        title: statusCode.toString(),
        messageType: MessageType.Error,
        description: descriptionText(statusCode,reasonPhrase),
    );
  }

   static String descriptionText(int statusCode, String reasonPhrase) {
     final Map<int, String> statusCodeDescriptions = {
       403: 'Does not have access to the requested resource',
       404: 'Requested Resource not found',
       500: 'Internal server error',
       // Add more mappings as needed
     };

     return statusCodeDescriptions[statusCode] ?? reasonPhrase;
   }
}