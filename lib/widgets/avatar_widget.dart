import 'package:flutter/material.dart';


class AvatarWidget extends StatelessWidget {
  final String? imageUrl; // URL for the user's image
  final String userName;

  const AvatarWidget({
    Key? key,
    required this.imageUrl,
    required this.userName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 24,
      backgroundColor: Colors.blueAccent,
      foregroundColor: Colors.white,
      backgroundImage: imageUrl != null && imageUrl!.isNotEmpty
          ? NetworkImage(imageUrl!)
          : null,
      child: imageUrl == null || imageUrl!.isEmpty
          ? Text(
        userName.isNotEmpty ? userName[0].toUpperCase() : '',
        style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white
        ),
      )
          : null,
    );
  }
}
