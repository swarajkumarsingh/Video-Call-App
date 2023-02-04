// ignore_for_file: use_build_context_synchronously

import 'dart:developer';

import 'package:agora_flutter/src/pages/call.dart';
import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class IndexPage extends StatefulWidget {
  const IndexPage({super.key});

  @override
  State<IndexPage> createState() => _IndexPageState();
}

class _IndexPageState extends State<IndexPage> {
  final channelController = TextEditingController();
  bool validateError = false;

  ClientRole? role = ClientRole.Broadcaster;

  @override
  void dispose() {
    channelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Agora"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Image.network(
                  "https://avatars.githubusercontent.com/u/89764448?v=4"),
              const SizedBox(height: 20),
              TextField(
                controller: channelController,
                decoration: InputDecoration(
                    errorText:
                        validateError ? "Channel Name is mandatory" : null,
                    border: const UnderlineInputBorder(
                      borderSide: BorderSide(width: 1),
                    ),
                    hintText: "Channel Name"),
              ),
              RadioListTile(
                value: ClientRole.Broadcaster,
                groupValue: role,
                onChanged: (value) {
                  setState(() {
                    role = value;
                  });
                },
                title: const Text("BroadCast"),
              ),
              RadioListTile(
                value: ClientRole.Audience,
                groupValue: role,
                onChanged: (value) {
                  setState(() {
                    role = value;
                  });
                },
                title: const Text("Audience"),
              ),
              ElevatedButton(
                onPressed: onJoin,
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 40)),
                child: const Text("Join"),
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> onJoin() async {
    setState(() {
      channelController.text.isEmpty
          ? validateError = true
          : validateError = false;
    });

    if (channelController.text.isNotEmpty) {
      await handleCameraAndMic(Permission.camera);
      await handleCameraAndMic(Permission.microphone);
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CallPage(
            channelName: channelController.text,
            role: role,
          ),
        ),
      );
    }
  }

  Future<void> handleCameraAndMic(Permission permission) async {
    final status = await permission.request();
    log(status.toString());
  }
}
