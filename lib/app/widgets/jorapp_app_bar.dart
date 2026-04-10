import 'package:flutter/material.dart';

class JorappAppBar extends StatelessWidget implements PreferredSizeWidget {
  final void Function() onMenuPressed;

  const JorappAppBar({super.key, required this.onMenuPressed});

  @override
  Size get preferredSize => const Size.fromHeight(76);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: 76,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              'assets/branding/jorapp_logo.png',
              width: 36,
              height: 36,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 14),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'JorAppLab',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              Text(
                'Parc du Jorat',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          iconSize: 30,
          padding: const EdgeInsets.all(10),
          icon: const Icon(Icons.menu_rounded),
          onPressed: onMenuPressed,
        ),
        const SizedBox(width: 12),
      ],
    );
  }
}
