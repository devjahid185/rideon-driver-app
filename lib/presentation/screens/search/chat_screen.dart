import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ride_on_driver/core/services/data_store.dart';
import 'package:ride_on_driver/core/utils/common_widget.dart';
import 'package:ride_on_driver/core/utils/theme/project_color.dart';
import 'package:ride_on_driver/core/utils/theme/theme_style.dart';
import 'package:ride_on_driver/core/utils/translate.dart';
import 'package:ride_on_driver/domain/entities/realtime_ride_request.dart';
import 'package:ride_on_driver/presentation/cubits/realtime/listen_ride_request_cubit.dart';
import 'package:ride_on_driver/presentation/screens/bottom_bar/home_main.dart';

class DriverChatScreen extends StatefulWidget {
  final RealTimeRideRequest rideRequest;
  final String driverId;

  const DriverChatScreen({
    super.key,
    required this.rideRequest,
    required this.driverId,
  });

  @override
  State<DriverChatScreen> createState() => _DriverChatScreenState();
}

class _DriverChatScreenState extends State<DriverChatScreen> {
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final FocusNode focusNode = FocusNode();
  bool _showSuggestions = true;

  final List<String> _messageSuggestions = [
    "I'm on my way",
    "I've reached your pickup",
    "Please wait, 5 mins",
    "Stuck in traffic",
    "Share exact location?",
    "I can see you",
  
  ];

  @override
  void initState() {
    super.initState();
    _markSeen();

    focusNode.addListener(() {
      if (focusNode.hasFocus) {
        if (_showSuggestions) {
          setState(() => _showSuggestions = false);
        }
        Future.delayed(const Duration(milliseconds: 250), () {
          if (scrollController.hasClients) {
            scrollController.jumpTo(scrollController.position.maxScrollExtent);
          }
        });
      }
    });
  }

  

  void _markSeen() {
    final ref = FirebaseDatabase.instance
        .ref("ride_requests/${widget.rideRequest.rideId}/chat/messages");

    ref.once().then((snap) {
      if (!snap.snapshot.exists) return;

      Map msgData = snap.snapshot.value as Map;
      msgData.forEach((key, value) {
        if (value["senderId"] != widget.driverId) {
          ref.child(key).update({"seen": true});
        }
      });
    });
  }



  void sendMessage() {
    final text = messageController.text.trim();
    if (text.isEmpty) return;

    // _send(text);
    messageController.clear();
    _scrollToBottom();
  }

  void sendSuggestion(String msg) {
    // _send(msg);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (!scrollController.hasClients) return;
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }
  bool isShowPopUp = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
          scrolledUnderElevation: 0,
        backgroundColor: Colors.white,
        elevation: 0.3,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: greentext,
              child: ClipOval(
                child: myNetworkImage(
                    widget.rideRequest.customer?.userPhoto ?? ""),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${widget.rideRequest.customer?.userName}",
                    style: heading3Grey1(context)),
                Text(
                  "Active Ride".translate(context),
                  style: regular(context).copyWith(
                    fontSize: 11,
                    color: greentext,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body:  BlocListener<GetRideRequestStatusCubit, String>(
                      listener: (context, status) {
                        if (status == "cancelled") {
                           WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  if (ModalRoute.of(context)?.isCurrent == true && !isShowPopUp) {
                    isShowPopUp = true;
                      box.delete("ride_id");
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => PopScope(
                        canPop: false,
                        child: AlertDialog(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          backgroundColor: Colors.white,
                          title: Column(
                            children: [
                              const Icon(Icons.cancel,
                                  color: Colors.redAccent, size: 48),
                              const SizedBox(height: 10),
                              Text(
                                "Ride Cancelled".translate(context),
                                textAlign: TextAlign.center,
                                style: heading2Grey1(context),
                              ),
                            ],
                          ),
                          content: Text(
                            "The rider has cancelled the ride request.\n\nYou can head back to the home screen and wait for another ride."
                                .translate(context),
                            textAlign: TextAlign.center,
                            style: regular2(context),
                          ),
                          actionsAlignment: MainAxisAlignment.center,
                          actions: [
                            InkWell(
                              onTap: () {
                                box.delete("ride_id");
                                goToWithClear(const HomeMain(initialIndex: 0));

                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
                                decoration: BoxDecoration(
                                  color: themeColor,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.home, color: Colors.white),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Go Home".translate(context),
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  }
                });
                          return;
                        }
                        
                      },
        child: Column(
          children: [
            Expanded(
              child: Container(
                color: grey5,
                child: StreamBuilder(
                  stream: FirebaseDatabase.instance
                      .ref(
                          "ride_requests/${widget.rideRequest.rideId}/chat/messages")
                      .orderByChild("timestamp")
                      .onValue,
                  builder: (context, snap) {
                    if (!snap.hasData || snap.data!.snapshot.value == null) {
                      return _emptyChatUI();
                    }
        
                    Map raw = snap.data!.snapshot.value as Map;
                    List chat = raw.entries
                        .map((e) => {"id": e.key, ...e.value})
                        .toList()
                      ..sort((a, b) => a["timestamp"].compareTo(b["timestamp"]));
        
                   
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (scrollController.hasClients) {
                        scrollController.animateTo(
                          scrollController.position.maxScrollExtent,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        );
                      }
                    });
        
                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      itemCount: chat.length,
                      itemBuilder: (context, i) {
                        bool isMe = chat[i]["senderId"] == widget.driverId;
                        return _chatBubble(chat[i], isMe, i == chat.length - 1);
                      },
                    );
                  },
                ),
              ),
            ),
        
            
            AnimatedCrossFade(
              firstChild: _quickReplies(),
              secondChild: const SizedBox(height: 0),
              crossFadeState:
             
             CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
            ),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _quickReplies() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flash_on, color: Colors.orange.shade600, size: 16),
              const SizedBox(width: 6),
              Text(
                "Quick Messages",
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  setState(() => _showSuggestions = false);
                },
                child: Icon(Icons.close, size: 16, color: Colors.grey.shade500),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _messageSuggestions.map((msg) {
                return GestureDetector(
                  onTap: () => sendSuggestion(msg),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.green.shade300.withValues(alpha: .3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      msg,
                      style: TextStyle(
                          fontSize: 11.5,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }


  Widget _emptyChatUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline,
              size: 60, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            "Start the conversation".translate(context),
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _chatBubble(dynamic msg, bool isMe, bool isLast) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFFDCF8C6) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft:
                isMe ? const Radius.circular(16) : const Radius.circular(5),
            bottomRight:
                isMe ? const Radius.circular(5) : const Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .04),
              blurRadius: 2,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              msg["message"],
              style: const TextStyle(
                fontSize: 13.5,
                color: Colors.black87,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(msg["timestamp"]),
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                ),
                if (isMe && isLast)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Icon(
                      msg["seen"] == true ? Icons.done_all : Icons.done,
                      size: 12,
                      color: msg["seen"] == true
                          ? Colors.blue.shade400
                          : Colors.grey.shade400,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.only(left: 20,right: 20,bottom: 30,top: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade300, width: 0.5),
        ),
      ),
      child: Row(
        children: [
        
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(25),
              ),
              child: TextField(
                controller: messageController,
                focusNode: focusNode,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: "Type a message...",
                  hintStyle:
                      TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                onSubmitted: (_) => sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: sendMessage,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: greentext,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return "";
    try {
      final date = DateTime.fromMillisecondsSinceEpoch(timestamp as int);
      return "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
    } catch (_) {
      return "";
    }
  }
}
