import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:flutter_highlight/themes/vs2015.dart';

class CodeBlockBuilder extends StatelessWidget {
  final String code;
  final String language;
  final bool isDarkMode;

  const CodeBlockBuilder({
    super.key,
    required this.code,
    required this.language,
    this.isDarkMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasMultipleLines = code.contains('\n');

    // Choose theme based on dark mode
    final highlightTheme = isDarkMode ? vs2015Theme : githubTheme;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFF3F3F3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (language.isNotEmpty || hasMultipleLines)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (language.isNotEmpty)
                    Text(
                      language,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                  if (hasMultipleLines)
                    InkWell(
                      onTap: () => _copyToClipboard(context),
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.copy,
                              size: 16,
                              color:
                                  isDarkMode
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Copy',
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                    isDarkMode
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          HighlightView(
            code,
            language: language.isNotEmpty ? language : 'plaintext',
            theme: highlightTheme,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            textStyle: TextStyle(
              fontFamily: 'monospace',
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: code));

    // Show snackbar if context is still mounted
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Code copied to clipboard'),
        behavior: SnackBarBehavior.floating,
        width: 220,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
