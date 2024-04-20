

import 'dart:io';

import 'package:video_downloader/video.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class Fonksiyonlar {

  var path = '/storage/emulated/0/Download';
  var yt = YoutubeExplode();

  Future<void> Indir(String url) async{


    var video = await yt.videos.get(url);
    var title = video.title;
    var author = video.author;
    var duration = video.duration;
    var id = video.id;

    var manifest = await yt.videos.streamsClient.getManifest(id);
    var streamInfo = await manifest.muxed.bestQuality;

    var stream = await yt.videos.streamsClient.get(streamInfo);
    var file = File(path + '/$title.mp4');
    var fileStream = file.openWrite();
    await stream.pipe(fileStream);
    await fileStream.flush();
    await fileStream.close();

    print("Video Baslik : $title -- Sahibi : $author -- Uzunluk $duration -- id $id");
  }

  Future<Video1?> VideoBilgi(String url) async{
    var video = await yt.videos.get(url);
    var title = video.title;
    var author = video.author;
    var duration = video.duration;
    var id = video.id;
    var videoBilgi = Video1(url: url, title: title, id: id);
    return videoBilgi;
  }


}