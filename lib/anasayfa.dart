import 'package:downloadsfolder/downloadsfolder.dart';
import 'package:path/path.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_downloader/video.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class Anasayfa extends StatefulWidget {
  const Anasayfa({super.key});

  @override
  State<Anasayfa> createState() => _AnasayfaState();
}

class _AnasayfaState extends State<Anasayfa> {
  var tfController = TextEditingController();
  var flp = FlutterLocalNotificationsPlugin();

  Future<void> bilKurulum() async{
    var androidAyar = const AndroidInitializationSettings("@mipmap/ic_launcher");
    var kurulumAyar = InitializationSettings(android: androidAyar);
    await flp.initialize(kurulumAyar, onDidReceiveNotificationResponse: bildirimSecildi);
  }

  /*-----------------------------------------------------------------------------------*/

  Future<void> bildirimGoster(String title, String progress, bool sessiz) async{
    var androidBildirimDetay = AndroidNotificationDetails(
        "channelId",
        "channelName",
        channelDescription: "channelDescription",
      priority: Priority.high,
      importance: Importance.max,
      silent: sessiz,

    );

    var bildirimDetay = NotificationDetails(android: androidBildirimDetay);
    flp.show(0, title, progress, bildirimDetay,payload: "$title");
  }

  /*-----------------------------------------------------------------------------------*/

  Future<void> bildirimSecildi(NotificationResponse notificationResponse) async{
    var payload = notificationResponse.payload;
    var id = notificationResponse.id;
    var title = notificationResponse.input;
    var path = '/storage/emulated/0/Download/$payload.mp4';
    var uri = toUri(path);

    if(payload != null){
      openDownloadFolder();

    }
  }

  /*-----------------------------------------------------------------------------------*/

  Future<String> uft8Convert(String url) async {


    String yanKontrol = url.replaceAll("/", "_");
    String duzKontrol = yanKontrol.replaceAll("|", "_");
    String ikiKontrol = duzKontrol.replaceAll(":", "_");
    String pipeKontrol = ikiKontrol.replaceAll("|", "_");
    String asteriksKontrol = pipeKontrol.replaceAll("*", "_");
    String soruKontrol = asteriksKontrol.replaceAll("?", "_");
    String boslukKontrol = soruKontrol.replaceAll(" ", "_");
    String kucukKontrol = asteriksKontrol.replaceAll("<", "_");
    String buyukKontrol = asteriksKontrol.replaceAll(">", "_");
    return buyukKontrol;
  }

  Future<Video1?> VideoBilgi(String url) async {
    var yt = YoutubeExplode();
    var path = '/storage/emulated/0/Download';
    var video = await yt.videos.get(url);
    var title = video.title;
    var id = video.id;
    String duzgunTitle = await uft8Convert(title);
    var manifest = await yt.videos.streamsClient.getManifest(id);
    var streamInfoMp3 = await manifest.audioOnly.withHighestBitrate();
    var streamInfoMp4 = await manifest.muxed.withHighestBitrate();
    var sizeMp3 = streamInfoMp3.size.totalMegaBytes.toInt();
    var sizeMp4 = streamInfoMp4.size.totalMegaBytes.toInt();
    Video1 videoBilgi = Video1(url: url, title: duzgunTitle, id: id,mp3Size: sizeMp3, mp4Size: sizeMp4);
    print("id = $id -- title = $duzgunTitle -- url = $url");
    return videoBilgi;
  }

  /*-----------------------------------------------------------------------------------*/

  Future<void> indirMp4(VideoId id, String title) async {
    bildirimGoster("indirme basliyor", "$title", false);
    String duzgunTitle = await uft8Convert(title);
    print(duzgunTitle);
    var yt = YoutubeExplode();
    var manifest = await yt.videos.streamsClient.getManifest(id);
    var streamInfo = await manifest.muxed.withHighestBitrate();

    var stream = await yt.videos.streamsClient.get(streamInfo);
    var file = File('/storage/emulated/0/Download/$duzgunTitle.mp4');
    var fileStream = await file.openWrite();

    var totalMegaBytes = streamInfo.size.totalBytes; // toplam byte sayisi
    var bytesWritten = 0;
    var newProgress = -1;
    tfController.text = "";

    print(totalMegaBytes);

    stream.listen(
      (data) async{
        bytesWritten += data.length;
        int inenMgBytes = ((bytesWritten/totalMegaBytes) * 100).ceil();



        if(inenMgBytes != newProgress){
          newProgress = inenMgBytes;
          bildirimGoster(title, "%$newProgress", true).then((value) => (value) {
             flp.cancelAll();
          });
        }

        print("data : $inenMgBytes% --- inen : $inenMgBytes");
        fileStream.add(data);
        /*bildirimGoster(title, "$progress%","surec").then((value) => (value) {
          //flp.cancel(0,tag: "surec");
        }); */

      },
      onDone: () async {
        await fileStream.flush();
        await fileStream.close();
        print("toplam : $totalMegaBytes");
        print("Video Baslik : $title -- id $id");

        flp.cancelAll();
        await bildirimGoster("$title", "Indirme Tamamlandi", false);

      },
      onError: (error) {
        bildirimGoster("$duzgunTitle", "Hata olustu", false);
        print("Error : $error");
      },
      cancelOnError: true,
    );

    print("Video Baslik : $title -- id $id");
  }

  /*-----------------------------------------------------------------------------------*/

  Future<void> indirMp3(VideoId id, String title) async {
    bildirimGoster("indirme basliyor", "$title", false);
    String duzgunTitle = await uft8Convert(title);
    var yt = YoutubeExplode();
    var manifest = await yt.videos.streamsClient.getManifest(id);
    var streamInfo = await manifest.audioOnly.withHighestBitrate();

    var stream = await yt.videos.streamsClient.get(streamInfo);
    var file = File('/storage/emulated/0/Download/$duzgunTitle.mp3');
    var fileStream = await file.openWrite();

    var totalBytes = streamInfo.size.totalBytes; // toplam byte sayisi
    var totalMb = streamInfo.size.totalMegaBytes;
    var bytesWritten = 0;
    var newProgress = -1;
    tfController.text = "";

    print(totalMb);

    stream.listen(
      (data) {
        bytesWritten += data.length;
        int inenMgBytes = ((bytesWritten/totalBytes) * 100).ceil();

        if(inenMgBytes != newProgress){
          newProgress = inenMgBytes;
          bildirimGoster(title, "%$newProgress", true).then((value) => (value) {
            flp.cancelAll();
          });
        }
        fileStream.add(data);
      },
      onDone: () async {
        await fileStream.flush();
        await fileStream.close();
        print("Video Baslik : $title -- id $id");
        await flp.cancelAll();
        bildirimGoster("$title", "Indirme Tamamlandi", false);
      },
      onError: (error) {
        bildirimGoster("$duzgunTitle", "Hata olustu", false);
        print("Error : $error");
      },
      cancelOnError: true,
    );

    print("Video Baslik : $title -- id $id");
  }

  /*-----------------------------------------------------------------------------------*/

  List<Permission> statues = [
    Permission.manageExternalStorage,
    Permission.notification
  ];

  Future<void> izinler() async{
    try{
      for(var element in statues){
        if(await element.status.isDenied || await element.status.isPermanentlyDenied){
          await element.request();
        }
      }
    } catch(e){
      print(e);
    }

  }
  /*-----------------------------------------------------------------------------------*/

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    bilKurulum();
    izinler();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Youtube Downloader"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Container(
              width: 300,
              child: TextField(
                decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Enter Youtube url : ",

                ),
                controller: tfController,
                onChanged: (value) {
                  tfController.text = value;
                },
              ),
            ),
             SizedBox(height: 20),
            ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return FutureBuilder(
                        future: VideoBilgi(tfController.text),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            print(snapshot.data?.title);
                            return Center(
                                child: const CircularProgressIndicator());
                          } else if (snapshot.hasError) {
                            return Center(
                                child: Text('Error: ${snapshot.error}'));
                          } else {
                            return AlertDialog(
                              title: Text(snapshot.data!.title),
                              content: Text("Select the format to download :"),
                              actions: [
                                ElevatedButton(
                                    onPressed: () {
                                      indirMp4(snapshot.data!.id,
                                          snapshot.data!.title);
                                    },
                                    child: Text("MP4\n${snapshot.data?.mp4Size} mb")),
                                ElevatedButton(
                                    onPressed: () {
                                      indirMp3(snapshot.data!.id,
                                          snapshot.data!.title);
                                    },
                                    child: Text("MP3\n${snapshot.data?.mp3Size} mb"))
                              ],
                            );
                          }
                        },
                      );
                    },
                  );
                },
                child: const Text("Download Video"))
          ],
        ),
      ),
    );
  }
}
