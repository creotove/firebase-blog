import 'package:blog/theme/app_pallete.dart';
import 'package:blog/widgets/audio_player.dart';
import 'package:blog/widgets/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class BuildMessageContent extends StatelessWidget {
  final bool isMe;
  final String messageType;
  final String decryptedMessage;
  final Map<String, dynamic> message;
  final bool isDeletedBySender;
  final bool isDeletedByReceiver;

  const BuildMessageContent({
    super.key,
    required this.isMe,
    required this.messageType,
    required this.decryptedMessage,
    required this.message,
    required this.isDeletedBySender,
    required this.isDeletedByReceiver,
  });

  @override
  Widget build(BuildContext context) {
    switch (messageType) {
      case "text":
        return Builder(
          builder: (context) {
            if (isDeletedBySender && isMe) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  gradient: isMe
                      ? const LinearGradient(
                          colors: [
                            AppPallete.gradient1,
                            AppPallete.gradient2
                          ],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Wrap(
                  children: [
                    Icon(Icons.error, color: Colors.white),
                    Text(
                      'You deleted this message',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              );
            } else if (isDeletedBySender && !isMe) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  gradient: isMe
                      ? const LinearGradient(
                          colors: [
                            AppPallete.gradient1,
                            AppPallete.gradient2
                          ],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'This message was deleted',
                  style: TextStyle(color: Colors.white),
                ),
              );
            } else if (isDeletedByReceiver && isMe) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  gradient: isMe
                      ? const LinearGradient(
                          colors: [
                            AppPallete.gradient1,
                            AppPallete.gradient2
                          ],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  decryptedMessage,
                  style: const TextStyle(color: Colors.white),
                ),
              );
            } else if (isDeletedByReceiver && !isMe) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  gradient: isMe
                      ? const LinearGradient(
                          colors: [
                            AppPallete.gradient1,
                            AppPallete.gradient2
                          ],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Wrap(
                  children: [
                    Icon(Icons.error, color: Colors.white),
                    SizedBox(width: 5),
                    Text(
                      'You deleted this message',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              );
            } else {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  gradient: isMe
                      ? const LinearGradient(
                          colors: [
                            AppPallete.gradient1,
                            AppPallete.gradient2
                          ],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  decryptedMessage,
                  style: const TextStyle(color: Colors.white),
                ),
              );
            }
          },
        );
      case "image":
        return Builder(
          builder: (context) {
            if (isDeletedBySender && isMe) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  gradient: isMe
                      ? const LinearGradient(
                          colors: [
                            AppPallete.gradient1,
                            AppPallete.gradient2
                          ],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Wrap(
                  children: [
                    Icon(Icons.error, color: Colors.white),
                    SizedBox(width: 5),
                    Text(
                      'You deleted this message',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              );
            } else if (isDeletedBySender && !isMe) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  gradient: isMe
                      ? const LinearGradient(
                          colors: [
                            AppPallete.gradient1,
                            AppPallete.gradient2
                          ],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'This message was deleted',
                  style: TextStyle(color: Colors.white),
                ),
              );
            } else if (isDeletedByReceiver && isMe) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: CachedNetworkImage(
                      imageUrl: message['imageUrl'],
                      height: 200.0,
                      width: 200.0,
                      progressIndicatorBuilder: (context, url, downloadProgress) => SizedBox(
                        height: 50.0,
                        width: 50.0,
                        child: LinearProgressIndicator(value: downloadProgress.progress),
                      ),
                      errorWidget: (context, url, error) => const Icon(Icons.error),
                    ),
                  ),
                ],
              );
            } else if (isDeletedByReceiver && !isMe) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  gradient: isMe
                      ? const LinearGradient(
                          colors: [
                            AppPallete.gradient1,
                            AppPallete.gradient2
                          ],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Wrap(
                  children: [
                    Icon(Icons.error, color: Colors.white),
                    SizedBox(width: 5),
                    Text(
                      'You deleted this message',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              );
            } else {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: CachedNetworkImage(
                      imageUrl: message['imageUrl'],
                      height: 200.0,
                      width: 200.0,
                      progressIndicatorBuilder: (context, url, downloadProgress) => SizedBox(
                        height: 50.0,
                        width: 50.0,
                        child: LinearProgressIndicator(value: downloadProgress.progress),
                      ),
                      errorWidget: (context, url, error) => const Icon(Icons.error),
                    ),
                  ),
                ],
              );
            }
          },
        );
      case "audio":
        return Builder(
          builder: (context) {
            if (isDeletedBySender && isMe) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  gradient: isMe
                      ? const LinearGradient(
                          colors: [
                            AppPallete.gradient1,
                            AppPallete.gradient2
                          ],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Wrap(
                  children: [
                    Icon(Icons.error, color: Colors.white),
                    SizedBox(width: 5),
                    Text(
                      'You deleted this message',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              );
            } else if (isDeletedBySender && !isMe) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  gradient: isMe
                      ? const LinearGradient(
                          colors: [
                            AppPallete.gradient1,
                            AppPallete.gradient2
                          ],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'This message was deleted',
                  style: TextStyle(color: Colors.white),
                ),
              );
            } else if (isDeletedByReceiver && isMe) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.blue,
                  gradient: isMe
                      ? const LinearGradient(
                          colors: [
                            AppPallete.gradient1,
                            AppPallete.gradient2
                          ],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                width: 200,
                child: CompactAudioPlayerWidget(audioUrl: message['audioUrl']),
              );
            } else if (isDeletedByReceiver && !isMe) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  gradient: isMe
                      ? const LinearGradient(
                          colors: [
                            AppPallete.gradient1,
                            AppPallete.gradient2
                          ],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Wrap(
                  children: [
                    Icon(Icons.error, color: Colors.white),
                    SizedBox(width: 5),
                    Text(
                      'You deleted this message',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              );
            } else {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.blue,
                  gradient: isMe
                      ? const LinearGradient(
                          colors: [
                            AppPallete.gradient1,
                            AppPallete.gradient2
                          ],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                width: 200,
                child: CompactAudioPlayerWidget(audioUrl: message['audioUrl']),
              );
            }
          },
        );
      case "document":
        return Builder(
          builder: (context) {
            if (isDeletedBySender && isMe) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  gradient: isMe
                      ? const LinearGradient(
                          colors: [
                            AppPallete.gradient1,
                            AppPallete.gradient2
                          ],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Wrap(
                  children: [
                    Icon(Icons.error, color: Colors.white),
                    SizedBox(width: 5),
                    Text(
                      'You deleted this message',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              );
            } else if (isDeletedBySender && !isMe) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  gradient: isMe
                      ? const LinearGradient(
                          colors: [
                            AppPallete.gradient1,
                            AppPallete.gradient2
                          ],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'This message was deleted',
                  style: TextStyle(color: Colors.white),
                ),
              );
            } else if (isDeletedByReceiver && isMe) {
              return Container(
                width: 100,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  gradient: isMe
                      ? const LinearGradient(
                          colors: [
                            AppPallete.gradient1,
                            AppPallete.gradient2
                          ],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                child: const Row(
                  children: [
                    Icon(Icons.insert_drive_file, color: Colors.white),
                    Text(
                      'Document',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              );
            } else if (isDeletedByReceiver && !isMe) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  gradient: isMe
                      ? const LinearGradient(
                          colors: [
                            AppPallete.gradient1,
                            AppPallete.gradient2
                          ],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Wrap(
                  children: [
                    Icon(Icons.error, color: Colors.white),
                    SizedBox(width: 5),
                    Text(
                      'You deleted this message',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              );
            } else {
              return Container(
                // width: MediaQuery.of(context).size.width * 0.3,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  gradient: isMe
                      ? const LinearGradient(
                          colors: [
                            AppPallete.gradient1,
                            AppPallete.gradient2
                          ],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                child: const Wrap(
                  children: [
                    Icon(Icons.insert_drive_file, color: Colors.white),
                    Text(
                      'Document',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              );
            }
          },
        );
      case "video":
        return Builder(
          builder: (context) {
            if (isDeletedBySender && isMe) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  gradient: isMe
                      ? const LinearGradient(
                          colors: [
                            AppPallete.gradient1,
                            AppPallete.gradient2
                          ],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Wrap(
                  children: [
                    Icon(Icons.error, color: Colors.white),
                    SizedBox(width: 5),
                    Text(
                      'You deleted this message',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              );
            } else if (isDeletedBySender && !isMe) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  gradient: isMe
                      ? const LinearGradient(
                          colors: [
                            AppPallete.gradient1,
                            AppPallete.gradient2
                          ],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'This message was deleted',
                  style: TextStyle(color: Colors.white),
                ),
              );
            } else if (isDeletedByReceiver && isMe) {
              return SizedBox(
                width: 200,
                child: CompactVideoPlayer(videoUrl: message['videoUrl']),
              );
            } else if (isDeletedByReceiver && !isMe) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  gradient: isMe
                      ? const LinearGradient(
                          colors: [
                            AppPallete.gradient1,
                            AppPallete.gradient2
                          ],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Wrap(
                  children: [
                    Icon(Icons.error, color: Colors.white),
                    SizedBox(width: 5),
                    Text(
                      'You deleted this message',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              );
            } else {
              return SizedBox(
                width: 200,
                child: CompactVideoPlayer(videoUrl: message['videoUrl']),
              );
            }
          },
        );
      default:
        return const Text(
          'File corrupted or not supported',
          style: TextStyle(color: Colors.white),
        );
    }
  }
}
