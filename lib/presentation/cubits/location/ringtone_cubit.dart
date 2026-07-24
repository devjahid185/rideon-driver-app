import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/extensions/workspace.dart';
import '../general_cubit.dart';


class RingtoneHelper with WidgetsBindingObserver {
  static final RingtoneHelper _instance = RingtoneHelper._internal();
  factory RingtoneHelper() => _instance;

  RingtoneHelper._internal() {
    WidgetsBinding.instance.addObserver(this);
  }

  static const MethodChannel _ringtoneChannel =
  MethodChannel('com.sizh.rideon.driver.taxiapp/ringtone');
  final AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _autoCloseTimer;
  int _remainingSeconds = 50;
  Function(int)? onTimeChanged;


  void playRingtone() {
    stopRingtone(); // Ensure old tone stops
    _remainingSeconds = 50;

    if(Platform.isIOS){
      _ringtoneChannel.invokeMethod('playRingtone').then((_) {
        startTimer();
      }).catchError((e) {
        debugPrint("Error playing ringtone via native: $e");
      });
    }else{
      _audioPlayer
          .setAudioSource(
        AudioSource.asset(
          'assets/tunes/call_tune.mp3',
          tag: const MediaItem(
            id: 'ringtone',
            title: 'Incoming Call',
            artUri: null,
          ),
        ),
      )
          .then((_) {
        _audioPlayer.setLoopMode(LoopMode.one);
        _audioPlayer.play();
        startTimer();

      })
          .catchError((e) {
        debugPrint("Error playing ringtone: $e");
      });
    }


  }


  void stopRingtone() {

    if(Platform.isIOS){
      _ringtoneChannel.invokeMethod('stopRingtone').then((_) {

      }).catchError((e) {

      });
    }else{
      _audioPlayer.stop().catchError((e) {
        debugPrint("Error stopping ringtone: $e");
      });
    }

    _autoCloseTimer?.cancel();
    _remainingSeconds = 0;
  }

  void startTimer() {
    _autoCloseTimer?.cancel();
    _autoCloseTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _remainingSeconds--;
      onTimeChanged?.call(_remainingSeconds);
      if (_remainingSeconds <= 0) {
        stopRingtone();
      }
    });
  }

  int get remainingSeconds => _remainingSeconds;

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoCloseTimer?.cancel();
  }
}


int popupDuration({double percentage = 20}) {
  final context = navigatorKey.currentContext!;
  final intervalStr = context.read<DriverSearchIntervalCubit>().state.value;
  final seconds = int.tryParse(intervalStr ?? "0") ?? 0;



  final reducedValue = seconds - (seconds * (percentage / 100));
  return reducedValue.round();
}
