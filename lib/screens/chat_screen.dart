import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  final supabase = Supabase.instance.client;

  bool _isRecording = false;
  bool _isUploading = false;
  String? _currentlyPlayingPath;
  int _recordDuration = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _markMessagesSeen();
  }

  void _markMessagesSeen() {
    String currentUserId = widget.isProvider ? widget.booking.provider.id : widget.booking.customerId;
    supabase.from('messages')
        .update({'is_seen': true})
        .eq('booking_id', widget.booking.id)
        .neq('sender_id', currentUserId)
        .then((_) => debugPrint("Messages marked as seen"));
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

  void _startTimer() {
    setState(() => _recordDuration = 0);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) => setState(() => _recordDuration++));
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  // --- SENDING LOGIC (Synced with Model) ---
  void _handleSend() async {
    // 1. IDs ko nikaalein aur String mein convert karke trim karein safety ke liye
    String sId = (widget.isProvider
        ? widget.booking.provider.id
        : widget.booking.customerId)
        .toString()
        .trim();

    String rId = (widget.isProvider
        ? widget.booking.customerId
        : widget.booking.provider.id)
        .toString()
        .trim();

    // 2. Debugging: Console mein lazmi check karein ke IDs different hain ya nahi
    debugPrint("--- CHAT DEBUG ---");
    debugPrint("I am Provider: ${widget.isProvider}");
    debugPrint("Sender ID (sId): '$sId'");
    debugPrint("Receiver ID (rId): '$rId'");
    debugPrint("------------------");

    // 3. Logic Check: Agar IDs same hain toh message bhejney ka faida nahi
    if (sId == rId) {
      debugPrint("CRITICAL ERROR: Sender and Receiver IDs are the SAME!");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error: Sender and Receiver are identical.")),
      );
      return;
    }

    // 4. Message Sending Process
    if (_isRecording) {
      // Audio recording handle karein
      _timer?.cancel();
      final path = await _audioRecorder.stop();
      setState(() => _isRecording = false);

      if (path != null) {
        _uploadAndSendMedia(File(path), MessageType.audio, sId, rId);
      }
    } else if (_messageController.text.trim().isNotEmpty) {
      // Text message handle karein
      String content = _messageController.text.trim();

      // UI foran clear karein taake user ko speed mehsoos ho
      _messageController.clear();
      setState(() {}); // UI update for mic icon change

      _sendMessageToSupabase(content, MessageType.text, sId, rId);
    }
  }

  Future<void> _uploadAndSendMedia(File file, MessageType type, String sId, String rId) async {
    setState(() => _isUploading = true);
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      final path = 'chats/${widget.booking.id}/$fileName';

      await supabase.storage.from('chat_media').upload(path, file);
      final String publicUrl = supabase.storage.from('chat_media').getPublicUrl(path);

      String content = publicUrl;
      if (type == MessageType.audio) {
        content = "$publicUrl|${_formatDuration(_recordDuration)}";
      }

      _sendMessageToSupabase(content, type, sId, rId);
    } catch (e) {
      debugPrint("Upload Error: $e");
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void _sendMessageToSupabase(String content, MessageType type, String sId, String rId) async {
    // Sync with MessageModel.toMap()
    final messageData = {
      'booking_id': widget.booking.id,
      'sender_id': sId,
      'receiver_id': rId,
      'content': content,
      'message_type': type.index, // Sending int as per model
      'created_at': DateTime.now().toIso8601String(), // Correct column name
      'is_seen': false,
    };

    try {
      await supabase.from('messages').insert(messageData);
      _scrollDown();
    } catch (e) {
      debugPrint("ERROR sending message: $e");
    }
  }

  void _scrollDown() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    String currentUserId = widget.isProvider ? widget.booking.provider.id : widget.booking.customerId;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          if (_isUploading) const LinearProgressIndicator(minHeight: 2, backgroundColor: Colors.white, color: Colors.blue),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: supabase
                  .from('messages')
                  .stream(primaryKey: ['id'])
                  .eq('booking_id', widget.booking.id)
                  .order('created_at', ascending: false), // Using created_at for order
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(fontSize: 10)));
                }
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final messages = snapshot.data!
                    .map((map) => MessageModel.fromMap(map))
                    .toList();

                if (messages.isEmpty) {
                  return Center(child: Text("No messages yet", style: GoogleFonts.poppins(color: Colors.grey)));
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    return _buildMessageBubble(msg, msg.senderId == currentUserId);
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

  // ... [Baaki saara UI code jo aapne bheja tha wo same rahega]
  // _buildAppBar, _buildMessageBubble, _buildMessageContent, _buildTimeRow, _buildChatInput, _showPickerMenu, _pickMedia, _startRecording ko end tak paste kar lein.

  AppBar _buildAppBar() {
    String name = widget.isProvider ? widget.booking.customerName : widget.booking.provider.name;
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black), onPressed: () => Navigator.pop(context)),
      titleSpacing: 0,
      title: Row(
        children: [
          CircleAvatar(
              radius: 18,
              backgroundColor: Colors.blue.shade100,
              child: Text(name[0].toUpperCase(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue))
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: GoogleFonts.poppins(color: Colors.black, fontSize: 15, fontWeight: FontWeight.w600)),
              const Text("Active Chat", style: TextStyle(color: Colors.green, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel msg, bool isMe) {
    bool isImage = msg.type == MessageType.image ||
        (msg.type == MessageType.text && msg.content.startsWith('http') &&
            (msg.content.toLowerCase().contains('.jpg') || msg.content.toLowerCase().contains('.png')));

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: isImage ? const EdgeInsets.all(4) : const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe ? Colors.blueAccent : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 16),
          ),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
        ),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        child: _buildMessageContent(msg, isMe, isImage),
      ),
    );
  }

  Widget _buildMessageContent(MessageModel msg, bool isMe, bool isImage) {
    final time = DateFormat('hh:mm a').format(msg.timestamp);
    final color = isMe ? Colors.white : Colors.black87;

    if (isImage) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(msg.content, fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) =>
                loadingProgress == null ? child : const Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(strokeWidth: 2))),
          ),
          Padding(
            padding: const EdgeInsets.all(4),
            child: _buildTimeRow(time, isMe, msg.isSeen),
          ),
        ],
      );
    } else if (msg.type == MessageType.audio) {
      String audioUrl = msg.content.split('|')[0];
      String duration = msg.content.contains('|') ? msg.content.split('|')[1] : "00:00";
      bool isPlaying = _currentlyPlayingPath == audioUrl;

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
                    await _audioPlayer.pause();
                    setState(() => _currentlyPlayingPath = null);
                  } else {
                    await _audioPlayer.play(UrlSource(audioUrl));
                    setState(() => _currentlyPlayingPath = audioUrl);
                    _audioPlayer.onPlayerComplete.listen((event) => setState(() => _currentlyPlayingPath = null));
                  }
                },
              ),
              Text(duration, style: TextStyle(color: color, fontSize: 12)),
            ],
          ),
          _buildTimeRow(time, isMe, msg.isSeen),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(msg.content, style: GoogleFonts.inter(color: color, fontSize: 14.5)),
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
            IconButton(icon: const Icon(Icons.add_circle_outline, color: Colors.blueAccent), onPressed: _showPickerMenu),
            Expanded(
              child: Container(
                decoration: BoxDecoration(color: const Color(0xFFF0F2F5), borderRadius: BorderRadius.circular(24)),
                child: TextField(
                  controller: _messageController,
                  onChanged: (val) => setState(() {}),
                  decoration: const InputDecoration(hintText: "Type a message...", border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 16)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                if (_messageController.text.trim().isNotEmpty && !_isRecording) {
                  _handleSend();
                }
              },
              onLongPress: _messageController.text.isEmpty ? _startRecording : null,
              onLongPressUp: () {
                if (_isRecording) _handleSend();
              },
              child: CircleAvatar(
                radius: 24,
                backgroundColor: _isRecording ? Colors.red : Colors.blueAccent,
                child: Icon(
                  _isRecording ? Icons.mic : (_messageController.text.isEmpty ? Icons.mic : Icons.send),
                  color: Colors.white,
                ),
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(leading: const Icon(Icons.camera_alt, color: Colors.blue), title: const Text("Camera"), onTap: () { Navigator.pop(context); _pickMedia(ImageSource.camera); }),
          ListTile(leading: const Icon(Icons.image, color: Colors.purple), title: const Text("Gallery"), onTap: () { Navigator.pop(context); _pickMedia(ImageSource.gallery); }),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Future<void> _pickMedia(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source, imageQuality: 70);
    if (image != null) {
      String sId = widget.isProvider ? widget.booking.provider.id : widget.booking.customerId;
      String rId = widget.isProvider ? widget.booking.customerId : widget.booking.provider.id;
      _uploadAndSendMedia(File(image.path), MessageType.image, sId, rId);
    }
  }

  Future<void> _startRecording() async {
    if (await _audioRecorder.hasPermission()) {
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _audioRecorder.start(const RecordConfig(), path: path);
      setState(() => _isRecording = true);
      _startTimer();
    }
  }
}