import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:handyman_app/models/booking_model.dart';
import 'package:handyman_app/models/message_model.dart';
import 'package:handyman_app/services/storage_service.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';

class ChatScreen extends StatefulWidget {
  final BookingModel booking;
  final bool isProvider;

  const ChatScreen({
    super.key,
    required this.booking,
    this.isProvider = false
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final ImagePicker _picker = ImagePicker();

  bool _isRecording = false;
  String? _currentlyPlayingPath;
  int _recordDuration = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _startTimer() {
    setState(() => _recordDuration = 0);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) => setState(() => _recordDuration++));
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _handleSend() async {
    String senderId = widget.isProvider ? widget.booking.provider.id : widget.booking.customerId;
    String receiverId = widget.isProvider ? widget.booking.customerId : widget.booking.provider.id;

    if (_isRecording) {
      String durationStr = _formatDuration(_recordDuration);
      _timer?.cancel();
      final path = await _audioRecorder.stop();
      setState(() => _isRecording = false);
      if (path != null) _sendMedia(path, MessageType.audio, duration: durationStr, sId: senderId, rId: receiverId);
    } else if (_messageController.text.trim().isNotEmpty) {
      _sendMedia(_messageController.text.trim(), MessageType.text, sId: senderId, rId: receiverId);
      _messageController.clear();
    }
  }

  void _sendMedia(String path, MessageType type, {String? duration, required String sId, required String rId}) async {
    String finalContent = type == MessageType.audio ? "$path|${duration ?? '00:00'}" : path;

    final newMessage = MessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      bookingId: widget.booking.id,
      senderId: sId,
      receiverId: rId,
      content: finalContent,
      type: type,
      timestamp: DateTime.now(),
    );
    await StorageService.sendMessage(newMessage);
  }

  // --- UPDATED PICKERS ---
  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      _processAndSend(image.path);
    }
  }

  Future<void> _pickVideo() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      _processAndSend(video.path);
    }
  }

  void _processAndSend(String path) {
    String sId = widget.isProvider ? widget.booking.provider.id : widget.booking.customerId;
    String rId = widget.isProvider ? widget.booking.customerId : widget.booking.provider.id;
    _sendMedia(path, MessageType.text, sId: sId, rId: rId);
  }

  // Gallery aur Video ke liye chota menu
  void _showAttachmentMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.image, color: Colors.blue),
            title: const Text("Gallery Image"),
            onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); },
          ),
          ListTile(
            leading: const Icon(Icons.videocam, color: Colors.red),
            title: const Text("Video"),
            onTap: () { Navigator.pop(context); _pickVideo(); },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String currentUserId = widget.isProvider ? widget.booking.provider.id : widget.booking.customerId;
    StorageService.markAsSeen(widget.booking.id, currentUserId);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leadingWidth: 70,
        leading: InkWell(
          onTap: () => Navigator.pop(context),
          child: Row(
            children: [
              const SizedBox(width: 8),
              const Icon(Icons.arrow_back, color: Colors.black),
              const SizedBox(width: 4),
              _buildAvatar(), // Initial logic placeholder
            ],
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.isProvider ? widget.booking.customerName : widget.booking.provider.name,
                style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
            const Text("Online", style: TextStyle(color: Colors.green, fontSize: 12)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: StorageService.getChatStream(widget.booking.id),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final messages = snapshot.data!.reversed.toList();
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(15),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    bool isMe = msg.senderId == currentUserId;
                    return _buildMessageBubble(msg, isMe);
                  },
                );
              },
            ),
          ),
          _buildChatInput(),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    String name = widget.isProvider ? widget.booking.customerName : widget.booking.provider.name;
    String initial = name.isNotEmpty ? name[0].toUpperCase() : "?";

    // Agar provider hai aur image hai toh image dikhao, warna initial
    if (!widget.isProvider && widget.booking.provider.imageUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 16,
        backgroundImage: widget.booking.provider.imageUrl.startsWith('http')
            ? NetworkImage(widget.booking.provider.imageUrl)
            : FileImage(File(widget.booking.provider.imageUrl)) as ImageProvider,
      );
    }

    return CircleAvatar(
      radius: 16,
      backgroundColor: Colors.blue,
      child: Text(initial, style: const TextStyle(color: Colors.white, fontSize: 12)),
    );
  }

  Widget _buildMessageBubble(MessageModel msg, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: isMe ? Colors.blue : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(15),
            topRight: const Radius.circular(15),
            bottomLeft: Radius.circular(isMe ? 15 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 15),
          ),
        ),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: _buildMessageContent(msg, isMe),
        ),
      ),
    );
  }

  Widget _buildMessageContent(MessageModel msg, bool isMe) {
    final timeStr = DateFormat('hh:mm a').format(msg.timestamp);
    final color = isMe ? Colors.white : Colors.black87;
    final timeColor = isMe ? Colors.white.withOpacity(0.8) : Colors.grey[600];

    if (msg.type == MessageType.audio) {
      List<String> parts = msg.content.split('|');
      String path = parts[0];
      String duration = parts.length > 1 ? parts[1] : "00:00";
      bool isPlaying = _currentlyPlayingPath == path;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill, color: color, size: 35),
                onPressed: () async {
                  if (isPlaying) {
                    await _audioPlayer.stop();
                    setState(() => _currentlyPlayingPath = null);
                  } else {
                    await _audioPlayer.play(DeviceFileSource(path));
                    setState(() => _currentlyPlayingPath = path);
                    _audioPlayer.onPlayerComplete.listen((_) => setState(() => _currentlyPlayingPath = null));
                  }
                },
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: List.generate(10, (i) => Container(width: 2, height: i % 2 == 0 ? 12 : 6, margin: const EdgeInsets.symmetric(horizontal: 1), color: isMe ? Colors.white70 : Colors.blueGrey))),
                  Text(duration, style: TextStyle(color: timeColor, fontSize: 11)),
                ],
              ),
            ],
          ),
          _buildTimeRow(timeStr, timeColor!, isMe, msg.isSeen),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(msg.content, style: TextStyle(color: color, fontSize: 15)),
          const SizedBox(height: 4),
          _buildTimeRow(timeStr, timeColor!, isMe, msg.isSeen),
        ],
      );
    }
  }

  Widget _buildTimeRow(String time, Color color, bool isMe, bool isSeen) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(time, style: TextStyle(color: color, fontSize: 10)),
        if (isMe) ...[
          const SizedBox(width: 4),
          Icon(Icons.done_all, size: 14, color: isSeen ? Colors.cyanAccent : Colors.white70),
        ]
      ],
    );
  }

  Widget _buildChatInput() {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.white,
      child: SafeArea(
        child: Row(
          children: [
            IconButton(icon: const Icon(Icons.camera_alt_outlined, color: Colors.blue), onPressed: () => _pickImage(ImageSource.camera)),
            IconButton(icon: const Icon(Icons.add_circle_outline, color: Colors.blue), onPressed: _showAttachmentMenu),
            IconButton(
              icon: Icon(_isRecording ? Icons.stop_circle : Icons.mic, color: _isRecording ? Colors.red : Colors.blue),
              onPressed: () => _isRecording ? _handleSend() : _startRecording(),
            ),
            Expanded(
              child: TextField(
                controller: _messageController,
                enabled: !_isRecording,
                decoration: InputDecoration(
                  hintText: _isRecording ? "Recording ${_formatDuration(_recordDuration)}..." : "Type a message...",
                  filled: true,
                  fillColor: const Color(0xFFF0F2F5),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
                ),
              ),
            ),
            IconButton(icon: const Icon(Icons.send, color: Colors.blue), onPressed: _handleSend),
          ],
        ),
      ),
    );
  }

  Future<void> _startRecording() async {
    if (await _audioRecorder.hasPermission()) {
      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _audioRecorder.start(const RecordConfig(), path: path);
      setState(() => _isRecording = true);
      _startTimer();
    }
  }
}