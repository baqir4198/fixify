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
import 'package:google_fonts/google_fonts.dart';

class ChatScreen extends StatefulWidget {
  final BookingModel booking;
  final bool isProvider;

  const ChatScreen({super.key, required this.booking, this.isProvider = false});

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
  void initState() {
    super.initState();
    // Screen khulne par messages ko "seen" mark karein
    String currentUserId = widget.isProvider ? widget.booking.provider.id : widget.booking.customerId;
    StorageService.markAsSeen(widget.booking.id, currentUserId);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // --- Utility Functions ---
  void _startTimer() {
    setState(() => _recordDuration = 0);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) => setState(() => _recordDuration++));
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  // --- Sending Logic ---
  void _handleSend() async {
    String senderId = widget.isProvider ? widget.booking.provider.id : widget.booking.customerId;
    String receiverId = widget.isProvider ? widget.booking.customerId : widget.booking.provider.id;

    if (_isRecording) {
      String durationStr = _formatDuration(_recordDuration);
      _timer?.cancel();
      final path = await _audioRecorder.stop();
      setState(() => _isRecording = false);
      if (path != null) _sendToFirebase(path, MessageType.audio, duration: durationStr, sId: senderId, rId: receiverId);
    } else if (_messageController.text.trim().isNotEmpty) {
      _sendToFirebase(_messageController.text.trim(), MessageType.text, sId: senderId, rId: receiverId);
      _messageController.clear();
    }
  }

  void _sendToFirebase(String content, MessageType type, {String? duration, required String sId, required String rId}) async {
    // Agar audio hai toh path aur duration merge karein
    String finalContent = type == MessageType.audio ? "$content|$duration" : content;

    final newMessage = MessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      bookingId: widget.booking.id,
      senderId: sId,
      receiverId: rId,
      content: finalContent,
      type: type,
      timestamp: DateTime.now(),
      isSeen: false,
    );

    // Firebase Service Call
    await StorageService.sendMessage(newMessage);
  }

  // --- Media Pickers ---
  Future<void> _pickMedia(ImageSource source, {bool isVideo = false}) async {
    final XFile? file = isVideo
        ? await _picker.pickVideo(source: source)
        : await _picker.pickImage(source: source);

    if (file != null) {
      String sId = widget.isProvider ? widget.booking.provider.id : widget.booking.customerId;
      String rId = widget.isProvider ? widget.booking.customerId : widget.booking.provider.id;
      _sendToFirebase(file.path, MessageType.text, sId: sId, rId: rId);
    }
  }

  @override
  Widget build(BuildContext context) {
    String currentUserId = widget.isProvider ? widget.booking.provider.id : widget.booking.customerId;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: _buildAppBar(),
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
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) => _buildMessageBubble(messages[index], messages[index].senderId == currentUserId),
                );
              },
            ),
          ),
          _buildChatInput(),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    String name = widget.isProvider ? widget.booking.customerName : widget.booking.provider.name;
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black), onPressed: () => Navigator.pop(context)),
      titleSpacing: 0,
      title: Row(
        children: [
          CircleAvatar(radius: 18, backgroundColor: Colors.blue.shade100, child: Text(name[0], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold))),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: GoogleFonts.poppins(color: Colors.black, fontSize: 15, fontWeight: FontWeight.w600)),
              const Text("Active Session", style: TextStyle(color: Colors.green, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel msg, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe ? Colors.blue : Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 16),
          ),
        ),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        child: _buildMessageContent(msg, isMe),
      ),
    );
  }

  Widget _buildMessageContent(MessageModel msg, bool isMe) {
    final time = DateFormat('hh:mm a').format(msg.timestamp);
    final color = isMe ? Colors.white : Colors.black87;

    // Check if it's an image path
    if (msg.content.contains('.jpg') || msg.content.contains('.png')) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: msg.content.startsWith('http')
                ? Image.network(msg.content)
                : Image.file(File(msg.content)),
          ),
          const SizedBox(height: 4),
          _buildTimeRow(time, isMe, msg.isSeen),
        ],
      );
    }
    // Audio Message
    else if (msg.type == MessageType.audio) {
      bool isPlaying = _currentlyPlayingPath == msg.content.split('|')[0];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill, color: color, size: 32),
                onPressed: () async {
                  String path = msg.content.split('|')[0];
                  if (isPlaying) { await _audioPlayer.pause(); setState(() => _currentlyPlayingPath = null); }
                  else { await _audioPlayer.play(DeviceFileSource(path)); setState(() => _currentlyPlayingPath = path); }
                },
              ),
              Text(msg.content.split('|')[1], style: TextStyle(color: color, fontSize: 12)),
            ],
          ),
          _buildTimeRow(time, isMe, msg.isSeen),
        ],
      );
    }
    // Text Message
    else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(msg.content, style: GoogleFonts.inter(color: color, fontSize: 14)),
          const SizedBox(height: 4),
          _buildTimeRow(time, isMe, msg.isSeen),
        ],
      );
    }
  }

  Widget _buildTimeRow(String time, bool isMe, bool isSeen) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(time, style: TextStyle(color: isMe ? Colors.white70 : Colors.grey, fontSize: 10)),
        if (isMe) ...[
          const SizedBox(width: 4),
          Icon(Icons.done_all, size: 14, color: isSeen ? Colors.cyanAccent : Colors.white60),
        ]
      ],
    );
  }

  Widget _buildChatInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFEEEEEE)))),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(icon: const Icon(Icons.add_circle_outline, color: Colors.blue), onPressed: () => _showPickerMenu()),
            Expanded(
              child: Container(
                decoration: BoxDecoration(color: const Color(0xFFF0F2F5), borderRadius: BorderRadius.circular(24)),
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(hintText: "Type a message...", border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 16)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onLongPress: _startRecording,
              onLongPressUp: _handleSend,
              child: CircleAvatar(
                backgroundColor: _isRecording ? Colors.red : Colors.blue,
                child: Icon(_isRecording ? Icons.mic : (_messageController.text.isEmpty ? Icons.mic : Icons.send), color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPickerMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(leading: const Icon(Icons.camera_alt), title: const Text("Camera"), onTap: () => _pickMedia(ImageSource.camera)),
          ListTile(leading: const Icon(Icons.image), title: const Text("Gallery"), onTap: () => _pickMedia(ImageSource.gallery)),
          ListTile(leading: const Icon(Icons.videocam), title: const Text("Video"), onTap: () => _pickMedia(ImageSource.gallery, isVideo: true)),
        ],
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