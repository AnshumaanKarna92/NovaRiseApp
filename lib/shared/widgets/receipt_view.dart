import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/material.dart";

class ReceiptView extends StatelessWidget {
  const ReceiptView({
    super.key,
    required this.url,
    this.height = 200,
    this.width = double.infinity,
    this.fit = BoxFit.cover,
  });

  final String url;
  final double? height;
  final double? width;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (url.startsWith("demo://")) {
      return Container(
        height: height,
        width: width,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.image_search_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 8),
              Text(
                "Demo Receipt Placeholder",
                style: Theme.of(context).textTheme.labelSmall,
              ),
              Text(
                url.replaceFirst("demo://", ""),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () => _showFullScreen(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: url,
          height: height,
          width: width,
          fit: fit,
          placeholder: (context, _) => Container(
            height: height,
            width: width,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: const Center(child: CircularProgressIndicator()),
          ),
          errorWidget: (context, _, __) => Container(
            height: height,
            width: width,
            color: Theme.of(context).colorScheme.errorContainer,
            child: const Center(child: Icon(Icons.broken_image_outlined)),
          ),
        ),
      ),
    );
  }

  void _showFullScreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: const CloseButton(color: Colors.white),
          ),
          body: Center(
            child: InteractiveViewer(
              child: CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
