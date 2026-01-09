class PlaybackModel {
  final String? playbackId;
  final String? videoUrl;

  PlaybackModel({this.playbackId, this.videoUrl});

  factory PlaybackModel.fromJson(Map<String, dynamic> json) {

    final data = json['data'] as Map<String, dynamic>?;

    return PlaybackModel(
      playbackId: data?['playbackId'],
      videoUrl: data?['videoUrl'],
    );
  }
}