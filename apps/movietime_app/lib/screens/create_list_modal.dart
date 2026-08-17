import 'dart:ui';

import 'package:flutter/material.dart';

const kDefaultListName = 'Assistir depois';

Future<String?> showCreateListModal(
  BuildContext context, {
  String? initialName,
}) {
  return showDialog<String>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.52),
    builder: (_) => _CreateListDialog(initialName: initialName),
  );
}

class _CreateListDialog extends StatefulWidget {
  const _CreateListDialog({this.initialName});

  final String? initialName;

  @override
  State<_CreateListDialog> createState() => _CreateListDialogState();
}

class _CreateListDialogState extends State<_CreateListDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialName?.trim().isNotEmpty == true
          ? widget.initialName!.trim()
          : kDefaultListName,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _create() {
    final name = _controller.text.trim().isEmpty
        ? kDefaultListName
        : _controller.text.trim();
    Navigator.of(context).pop(name);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 47),
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            width: 295,
            height: 281,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Navigator.of(context).pop(),
                    child: const SizedBox(
                      width: 20,
                      height: 20,
                      child: Icon(
                        Icons.close_rounded,
                        color: Color(0xFF525252),
                        size: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  'Dê um nome para sua lista',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF9E9E9E),
                    fontSize: 14,
                    fontFamily: 'Netflix Sans',
                    fontWeight: FontWeight.w500,
                    height: 22 / 14,
                  ),
                ),
                const SizedBox(height: 25),
                SizedBox(
                  width: 250,
                  height: 82,
                  child: TextField(
                    controller: _controller,
                    textAlign: TextAlign.center,
                    textAlignVertical: TextAlignVertical.center,
                    cursorColor: const Color(0xFF9E9E9E),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontFamily: 'Netflix Sans',
                      fontWeight: FontWeight.w500,
                      height: 24 / 16,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.transparent,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 28,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF2C2C2C)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF2C2C2C)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF525252)),
                      ),
                    ),
                    onSubmitted: (_) => _create(),
                  ),
                ),
                const SizedBox(height: 25),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _create,
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFFA259FF), Color(0xFF562199)],
                      ),
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: const Center(
                      widthFactor: 1,
                      child: Text(
                        'Salvar',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontFamily: 'Netflix Sans',
                          fontWeight: FontWeight.w500,
                          height: 22 / 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
