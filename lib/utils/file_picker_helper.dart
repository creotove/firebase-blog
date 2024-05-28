import 'package:blog/utils/argument_helper.dart.dart';
import 'package:blog/utils/chat_service.dart';
import 'package:blog/utils/context_utility_service.dart';

class FilePickerHelper {
  final _chatService = ChatService();
  // Method to pick image from gallery implements the _pickImage method of ChatService and below function are same for audio, document and video
  void pickImage(String currentUserId, String receiverUserId) async {
    final pickedImage = await _chatService.pickImage();
    if (pickedImage != null) {
      final arguments = SendImageArguments(
        image: pickedImage,
        currentUserId: currentUserId,
        receiverUserId: receiverUserId,
      );
      await ContextUtilityService.navigatorKey.currentState?.pushNamed(
        '/send-image',
        arguments: arguments,
      );
    }
  }

  void pickAudio(String currentUserId, String receiverUserId) async {
    final pickedAudio = await _chatService.pickAudio();
    if (pickedAudio != null) {
      final arguments = SendAudioArguments(
        audio: pickedAudio,
        currentUserId: currentUserId,
        receiverUserId: receiverUserId,
      );
      await ContextUtilityService.navigatorKey.currentState?.pushNamed(
        '/send-audio',
        arguments: arguments,
      );
    }
  }

  void pickDocument(String currentUserId, String receiverUserId) async {
    final pickedDocument = await _chatService.pickDocument();
    if (pickedDocument != null) {
      final arguments = SendDocumentArguments(
        document: pickedDocument,
        currentUserId: currentUserId,
        receiverUserId: receiverUserId,
      );
      await ContextUtilityService.navigatorKey.currentState?.pushNamed(
        '/send-document',
        arguments: arguments,
      );
    }
  }

  void pickVideo(String currentUserId, String receiverUserId) async {
    final pickedVideo = await _chatService.pickVideo();
    if (pickedVideo != null) {
      final arguments = SendVideoArguments(
        video: pickedVideo,
        currentUserId: currentUserId,
        receiverUserId: receiverUserId,
      );
      await ContextUtilityService.navigatorKey.currentState?.pushNamed(
        '/send-video',
        arguments: arguments,
      );
    }
  }
}
