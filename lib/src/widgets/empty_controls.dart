// This file is a part of dart_vlc (https://github.com/alexmercerind/dart_vlc)
//
// Copyright (C) 2021-2022 Hitesh Kumar Saini <saini123hitesh@gmail.com>
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU Lesser General Public
// License as published by the Free Software Foundation; either
// version 3 of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public License
// along with this program; if not, write to the Free Software Foundation,
// Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

// ignore_for_file: implementation_imports
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:dart_vlc_ffi/src/device.dart';
import 'package:dart_vlc_ffi/src/player.dart';
import 'package:dart_vlc_ffi/src/player_state/player_state.dart';

class EmptyControl extends StatefulWidget {
  EmptyControl({
    Key? key,
    required this.child,
    required this.player,
    required this.showTimeLeft,
    required this.volumeActiveColor,
    required this.volumeInactiveColor,
    required this.volumeBackgroundColor,
    required this.volumeThumbColor,
  }) : super(key: key);

  final Widget child;
  final Player player;
  final bool? showTimeLeft;
  final Color? volumeActiveColor;
  final Color? volumeInactiveColor;
  final Color? volumeBackgroundColor;
  final Color? volumeThumbColor;

  @override
  EmptyControlState createState() => EmptyControlState();
}

class EmptyControlState extends State<EmptyControl>
    with SingleTickerProviderStateMixin {
  bool _hideControls = true;
  bool _displayTapped = false;
  Timer? _hideTimer;
  late StreamSubscription<PlaybackState> playPauseStream;
  late AnimationController playPauseController;

  Player get player => widget.player;

  @override
  void initState() {
    super.initState();
    playPauseController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 400));
    playPauseStream = player.playbackStream
        .listen((event) => setPlaybackMode(event.isPlaying));
    if (player.playback.isPlaying) playPauseController.forward();
  }

  @override
  void dispose() {
    playPauseStream.cancel();
    playPauseController.dispose();
    super.dispose();
  }

  void setPlaybackMode(bool isPlaying) {
    if (isPlaying) {
      playPauseController.forward();
    } else {
      playPauseController.reverse();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (player.playback.isPlaying) {
          if (_displayTapped) {
            setState(() {
              _hideControls = true;
              _displayTapped = false;
            });
          } else {
            _cancelAndRestartTimer();
          }
        } else {
          setState(() => _hideControls = true);
        }
      },
      child: MouseRegion(
        onHover: (_) => _cancelAndRestartTimer(),
        child: AbsorbPointer(
          absorbing: _hideControls,
          child: Stack(
            children: [
              widget.child,
              AnimatedOpacity(
                duration: Duration(milliseconds: 300),
                opacity: _hideControls ? 0.0 : 1.0,
                child: Stack(
                  children: [
                    Positioned(
                      right: 15,
                      bottom: 12.5,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          VolumeControl(
                            player: player,
                            thumbColor: widget.volumeThumbColor,
                            inactiveColor: widget.volumeInactiveColor,
                            activeColor: widget.volumeActiveColor,
                            backgroundColor: widget.volumeBackgroundColor,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _cancelAndRestartTimer() {
    _hideTimer?.cancel();

    if (mounted) {
      _startHideTimer();

      setState(() {
        _hideControls = false;
        _displayTapped = true;
      });
    }
  }

  void _startHideTimer() {
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _hideControls = true;
          _displayTapped = false;
        });
      }
    });
  }
}

class VolumeControl extends StatefulWidget {
  final Player player;
  final Color? activeColor;
  final Color? inactiveColor;
  final Color? backgroundColor;
  final Color? thumbColor;

  const VolumeControl({
    required this.player,
    required this.activeColor,
    required this.inactiveColor,
    required this.backgroundColor,
    required this.thumbColor,
    Key? key,
  }) : super(key: key);

  @override
  VolumeControlState createState() => VolumeControlState();
}

class VolumeControlState extends State<VolumeControl> {
  double volume = 0.5;
  bool _showVolume = false;
  double unmutedVolume = 0.5;

  Player get player => widget.player;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedOpacity(
          duration: Duration(milliseconds: 250),
          opacity: _showVolume ? 1 : 0,
          child: AbsorbPointer(
            absorbing: !_showVolume,
            child: MouseRegion(
              onEnter: (_) {
                setState(() => _showVolume = true);
              },
              onExit: (_) {
                setState(() => _showVolume = false);
              },
              child: Container(
                width: 60,
                height: 250,
                child: Card(
                  color: widget.backgroundColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100)),
                  child: RotatedBox(
                    quarterTurns: -1,
                    child: SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: widget.activeColor,
                        inactiveTrackColor: widget.inactiveColor,
                        thumbColor: widget.thumbColor,
                      ),
                      child: Slider(
                        min: 0.0,
                        max: 1.0,
                        value: player.general.volume,
                        onChanged: (volume) {
                          player.setVolume(volume);
                          setState(() {});
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        MouseRegion(
          onEnter: (_) {
            // setState(() => _showVolume = true);
          },
          onExit: (_) {
            // setState(() => _showVolume = false);
          },
          child: Container(),
        ),
      ],
    );
  }

  IconData getIcon() {
    if (player.general.volume > .5) {
      return Icons.volume_up_sharp;
    } else if (player.general.volume > 0) {
      return Icons.volume_down_sharp;
    } else {
      return Icons.volume_off_sharp;
    }
  }

  void muteUnmute() {
    if (player.general.volume > 0) {
      unmutedVolume = player.general.volume;
      player.setVolume(0);
    } else {
      player.setVolume(unmutedVolume);
    }
    setState(() {});
  }
}
