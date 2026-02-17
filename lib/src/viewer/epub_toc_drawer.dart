import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'epub_reader_controller.dart';

/// Table of Contents drawer for EPUB reader
class EpubTocDrawer extends GetView<EpubReaderController> {
  const EpubTocDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isDark = controller.isDarkMode.value;
      final bgColor = isDark ? const Color(0xFF1a1a1a) : Colors.white;
      final textColor = isDark ? Colors.white : Colors.black87;
      final subtitleColor = isDark ? Colors.white60 : Colors.black54;
      final primaryColor = Theme.of(context).primaryColor;

      return Drawer(
        backgroundColor: bgColor,
        width: MediaQuery.of(context).size.width * 0.85,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: bgColor,
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? Colors.white12 : Colors.black12,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.list,
                        color: primaryColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Table of Contents',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          Text(
                            '${controller.totalChapters.value} chapters',
                            style: TextStyle(
                              fontSize: 13,
                              color: subtitleColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: subtitleColor),
                      onPressed: () => Get.back(),
                    ),
                  ],
                ),
              ),

              // Progress indicator
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Reading Progress',
                          style: TextStyle(
                            fontSize: 13,
                            color: subtitleColor,
                          ),
                        ),
                        Text(
                          '${(controller.progress.value * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: controller.progress.value,
                      backgroundColor: isDark ? Colors.white12 : Colors.black12,
                      valueColor: AlwaysStoppedAnimation(primaryColor),
                      minHeight: 4,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ],
                ),
              ),

              // Chapters list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: controller.chapters.length,
                  itemBuilder: (context, index) {
                    final chapter = controller.chapters[index];
                    final isCurrentChapter =
                        controller.currentChapterIndex.value == index;

                    return _ChapterItem(
                      chapter: chapter,
                      isCurrentChapter: isCurrentChapter,
                      isDarkMode: isDark,
                      primaryColor: primaryColor,
                      onTap: () {
                        controller.goToChapter(index);
                        Get.back();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _ChapterItem extends StatelessWidget {
  final ChapterInfo chapter;
  final bool isCurrentChapter;
  final bool isDarkMode;
  final Color primaryColor;
  final VoidCallback onTap;

  const _ChapterItem({
    required this.chapter,
    required this.isCurrentChapter,
    required this.isDarkMode,
    required this.primaryColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final subtitleColor = isDarkMode ? Colors.white60 : Colors.black54;
    final highlightColor = isCurrentChapter
        ? primaryColor.withValues(alpha: 0.1)
        : Colors.transparent;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          16.0 + (chapter.depth * 16.0),
          12,
          16,
          12,
        ),
        color: highlightColor,
        child: Row(
          children: [
            // Chapter indicator
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isCurrentChapter
                    ? primaryColor
                    : (isDarkMode
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.05)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: isCurrentChapter
                    ? const Icon(Icons.play_arrow,
                        size: 16, color: Colors.white)
                    : Text(
                        '${chapter.index + 1}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: subtitleColor,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),

            // Chapter title
            Expanded(
              child: Text(
                chapter.title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight:
                      isCurrentChapter ? FontWeight.w600 : FontWeight.normal,
                  color: isCurrentChapter ? primaryColor : textColor,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Current indicator
            if (isCurrentChapter)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Reading',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
