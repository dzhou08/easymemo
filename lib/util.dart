import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';


class ProfilePopupMenu extends StatelessWidget {
  final GoogleSignInAccount user;
  final VoidCallback onSignOut;
  final GlobalKey _key = GlobalKey();

  ProfilePopupMenu({required this.user, required this.onSignOut});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _showPopupMenu(context);
      },
      child: Container(
        key: _key,
        padding: EdgeInsets.all(8),
        child: CircleAvatar(
          backgroundImage: NetworkImage(user.photoUrl!),
        ),
      ),
    );
  }

  void _showPopupMenu(BuildContext context) {
    final RenderBox renderBox = _key.currentContext!.findRenderObject() as RenderBox;
    final Offset offset = renderBox.localToGlobal(Offset.zero);

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx, // Horizontal position
        offset.dy + renderBox.size.height, // Vertical position just below the avatar
        0,
        0,
      ),
      items: [
        PopupMenuItem<String>(
          value: 'Profile',
          child: Text('Profile'),
        ),
        PopupMenuItem<String>(
          value: 'Logout',
          child: Text('Logout'),
        ),
      ],
    ).then((value) {
      if (value == 'Logout') {
        onSignOut();
      }
    });
  }
}