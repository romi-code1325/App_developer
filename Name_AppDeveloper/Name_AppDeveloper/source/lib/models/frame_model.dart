import 'package:flutter/material.dart';

enum FrameShape { round, wayfarer, aviator, catEye }

/// A selectable spectacle frame. Frames are drawn as vector graphics
/// (see SpectaclePainter), so no bitmap assets are needed and they stay
/// sharp at any distance from the camera.
@immutable
class FrameModel {
  const FrameModel({
    required this.id,
    required this.name,
    required this.shape,
    required this.color,
    required this.lensTint,
  });

  final String id;
  final String name;
  final FrameShape shape;
  final Color color;
  final Color lensTint;
}

const List<FrameModel> kFrames = [
  FrameModel(
    id: 'round',
    name: 'Classic Round',
    shape: FrameShape.round,
    color: Color(0xFFC9A24B),
    lensTint: Color(0x33A6D8FF),
  ),
  FrameModel(
    id: 'wayfarer',
    name: 'Bold Wayfarer',
    shape: FrameShape.wayfarer,
    color: Color(0xFF1B1B1F),
    lensTint: Color(0x59000000),
  ),
  FrameModel(
    id: 'aviator',
    name: 'Sky Aviator',
    shape: FrameShape.aviator,
    color: Color(0xFFB8BDC7),
    lensTint: Color(0x80335B45),
  ),
  FrameModel(
    id: 'cat_eye',
    name: 'Rose Cat-Eye',
    shape: FrameShape.catEye,
    color: Color(0xFF8E2C48),
    lensTint: Color(0x40FFB6C9),
  ),
];
