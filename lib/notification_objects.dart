import 'package:flutter/material.dart';

class NotificationReceiver extends StatelessWidget {
  final Widget child;

  const NotificationReceiver({Key key, this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned(
          child: NotificationBar(),
          bottom: 10.0,
          left: 10.0,
          height: 50.0,
          width: 50.0,
        )
      ],
    );
  }
}

class NotificationBar extends StatefulWidget {

  const NotificationBar({Key key}) : super(key: key);

  @override
  _NotificationBarState createState() => _NotificationBarState();
}

class _NotificationBarState extends State<NotificationBar> {

  NotificationState currentState = NotificationState.getState();

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

class Notification extends StatelessWidget {

  final NotificationContent content;

  const Notification({Key key, this.content}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40.0,
      child: Text(
        content.message
      ),
      foregroundDecoration: BoxDecoration(
        border: Border.all(
          color: Colors.orange
        )
      )
    );
  }
}



class NotificationState {

  static NotificationState _singleton;

  static NotificationState getState() {
    return _singleton == null ? new NotificationState() : _singleton;
  }

  List<NotificationContent> _allNotifications;

  void notify(NotificationContent notification){
    this._allNotifications.add(notification);
  }
}

class NotificationContent {

  String message;
  DateTime expiry;

}
