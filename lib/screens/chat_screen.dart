import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:handyman_app/models/booking_model.dart';
import 'package:handyman_app/models/message_model.dart';
import 'package:handyman_app/services/storage_service.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  final BookingModel booking;
  const ChatScreen({super.key,required this.booking});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _sendMessage() async{
    if(_messageController.text.trim().isEmpty) return;
    final newMessage = MessageModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        bookingId: widget.booking.id,
        senderId: widget.booking.customerId,
        receiverId: widget.booking.provider.id,
        content: _messageController.text.trim(),
        type: MessageType.text,
        timestamp: DateTime.now()
    );
    await StorageService.sendMessage(newMessage);
    _messageController.clear();
    _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut
    );
  }
  @override
  Widget build(BuildContext context) {
    StorageService.markAsSeen(widget.booking.id,widget.booking.customerId);
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leadingWidth: 70,
        leading: InkWell(
          onTap: ()=> Navigator.pop(context),
          child: Row(
            children: [
              const SizedBox(width: 8,),
              const Icon(Icons.arrow_back,color: Colors.black,),
              const SizedBox(width: 4,),
              CircleAvatar(
                radius: 16,
                backgroundImage: NetworkImage(widget.booking.provider.imageUrl),
              )
            ],
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.booking.provider.name,style: const TextStyle(color: Colors.black,fontSize: 16,fontWeight: FontWeight.bold),),
            const Text("Online",style: TextStyle(color: Colors.green,fontSize: 12),)
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
              child: StreamBuilder<List<MessageModel>>(
                stream: StorageService.getChatStream(widget.booking.id),
                builder: (context, snapshot) {
                  if(!snapshot.hasData)return const Center(child: CircularProgressIndicator(),);
                  final messages = snapshot.data!.reversed.toList();

                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.all(15),
                    itemCount: messages.length,
                    itemBuilder: (constext,index) {
                      final msg = messages[index];
                      bool isMe = msg.senderId == widget.booking.customerId;
                      return _buildMessageBubble(msg, isMe);
                    },
                  );
                },
              )
          ),
          _buildChatInput(),
        ],
      ),
    );
  }
  Widget _buildMessageBubble(MessageModel msg,bool isMe){
    return Align(
      alignment: isMe? Alignment.centerRight: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14,vertical: 10),
        decoration:BoxDecoration(
          color: isMe? Colors.blue: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(15),
            topRight: const Radius.circular(15),
            bottomLeft: Radius.circular(isMe ? 15:0),
            bottomRight: Radius.circular(isMe ? 0:15),
          )
        ),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width*0.75),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              msg.content,
              style: TextStyle(color: isMe? Colors.white: Colors.black87,fontSize: 15),
            ),
            const SizedBox(height: 4,),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat('hh:mm a').format(msg.timestamp),
                  style: TextStyle(color: isMe? Colors.white70: Colors.grey,fontSize: 10),
                ),
                if(isMe)...[
                  const SizedBox(width: 4),
                  Icon(Icons.done_all,size: 14, color: msg.isSeen?  Colors.cyanAccent:Colors.white70),
                ]
              ],
            )
          ],
        ),
      ),
    );
  }
  Widget _buildChatInput(){
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8,vertical:  8),
      decoration: const BoxDecoration(color: Colors. white),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(icon: const Icon(Icons.add_circle_outline,color: Colors.blue),onPressed: (){},),
            IconButton(icon: const Icon(Icons.mic_none_rounded,color: Colors.blue,),onPressed:(){}),
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: "Type a message ...",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                  fillColor: const Color(0xFFF0F2F5),
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20,vertical: 10)
                ),
              ),
            ),
            const SizedBox(width: 5,),
            FloatingActionButton.small(
              onPressed: _sendMessage,
              backgroundColor: Colors.blue,
              elevation: 0,
              child: const Icon(Icons.send,color: Colors.white,size: 18,),
            )
          ],
        ),
      ),
    );
  }
}
