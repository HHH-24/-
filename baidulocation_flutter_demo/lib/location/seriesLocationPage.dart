import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_baidu_mapapi_map/flutter_baidu_mapapi_map.dart';
import 'package:flutter_bmflocation/flutter_bmflocation.dart';
import 'package:baidulocation_flutter_demo/widgets/loc_appbar.dart';
import 'package:flutter_baidu_mapapi_base/flutter_baidu_mapapi_base.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

class ResBody {

  double? latitude;
  double? longitude;

  ResBody(this.latitude, this.longitude);

}

class SeriesLocationPage extends StatefulWidget {
  const SeriesLocationPage({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<SeriesLocationPage> {
  BaiduLocation _loationResult = BaiduLocation();
  BaiduLocation _loationResultResponse = BaiduLocation();
  late BMFMapController _myMapController;
  final LocationFlutterPlugin _myLocPlugin = LocationFlutterPlugin();
  bool _suc = false;

  @override
  void initState() {
    super.initState();

    //接受定位回调
    _myLocPlugin.seriesLocationCallback(callback: (BaiduLocation result) {
      setState(() {
        _loationResult = result;
        _locationFinish();
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    _stopLocation();
  }

  Future<void> handleRequests(HttpServer server) async {
    await for (HttpRequest request in server) {
    //   {"latitude" : _loationResult.getMap()["latitude"],
    // "longitude": _loationResult.getMap()["longitude"],}
      request.response.write({"latitude" : _loationResult.getMap()["latitude"],
    "longitude": _loationResult.getMap()["longitude"],});
      await request.response.close();
    }
  }

  Future<void> serverMain() async {
    final server = await createServer();
    print('Server started: ${server.address} port ${server.port}');
    await handleRequests(server);
  }

  Future<HttpServer> createServer() async {
    /**
     * 114 X21
     * 79 X21A
     * 97 P40PRO
     */
    final address = InternetAddress.tryParse("192.168.101.79");
    const port = 40401;
    return await HttpServer.bind(address, port);
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> resultWidgets = [];

    if (_loationResult.callbackTime != null) {
      _loationResult.getMap().forEach((key, value) {
        //resultWidgets.add(_resultWidget(key, value));
      });
    }

    return MaterialApp(
        home: Scaffold(
      appBar: BMFAppBar(
        title: '位置共享',
        isBack: true,
        onBack: () {
          Navigator.pop(context);
        },
      ),
      body: Column(children: [
        _createMapContainer(),
        Container(height: 30),
        SizedBox(
          height: MediaQuery.of(context).size.height - 750,
          child: ListView(
            children: resultWidgets,
          ),
        ),
        _createButtonContainer()
      ]),
    ));
  }

  Widget _createMapContainer() {
    return SizedBox(
        height: 570,
        child: BMFMapWidget(
          onBMFMapCreated: (controller) {
            _onBMFMapCreated(controller);
          },
          mapOptions: _initMapOptions(),
        ));
  }

  Container _createButtonContainer() {
    return Container(
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
                onPressed: () {
                  ///设置定位参数
                  _locationAction();
                  serverMain();
                  _startLocation();
                },
                child: const Text('开始定位'),
                style: ElevatedButton.styleFrom(
                  primary: Colors.blueAccent, //change background color of button
                  onPrimary: Colors.yellow, //change text color of button
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                )),
            Container(width: 60),
            ElevatedButton(
                onPressed: () {
                  _stopLocation();
                },
                child: const Text('点击共享'),
                style: ElevatedButton.styleFrom(
                  primary: Colors.blueAccent, //change background color of button
                  onPrimary: Colors.yellow, //change text color of button
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ))
          ],
        ));
  }

  //回调定位信息输出
  // Widget _resultWidget(key, value) {
  //   return Center(
  //     child: Column(
  //         mainAxisAlignment: MainAxisAlignment.center,
  //         children: <Widget>[
  //           Text('$key:' ' $value'),
  //         ]),
  //   );
  // }

  void _locationAction() async {
    /// 设置android端和ios端定位参数
    /// android 端设置定位参数
    /// ios 端设置定位参数
    Map iosMap = _initIOSOptions().getMap();
    Map androidMap = _initAndroidOptions().getMap();

    _suc = await _myLocPlugin.prepareLoc(androidMap, iosMap);
    print('设置定位参数：$iosMap');
  }

  /// 设置地图参数
  BaiduLocationAndroidOption _initAndroidOptions() {
    BaiduLocationAndroidOption options = BaiduLocationAndroidOption(
        coorType: 'bd09ll',
        locationMode: BMFLocationMode.hightAccuracy,
        isNeedAddress: true,
        isNeedAltitude: true,
        isNeedLocationPoiList: true,
        isNeedNewVersionRgc: true,
        isNeedLocationDescribe: true,
        openGps: true,
        scanspan: 4000,
        coordType: BMFLocationCoordType.bd09ll);
    return options;
  }

  BaiduLocationIOSOption _initIOSOptions() {
    BaiduLocationIOSOption options = BaiduLocationIOSOption(
        coordType: BMFLocationCoordType.bd09ll,
        BMKLocationCoordinateType: 'BMKLocationCoordinateTypeBMK09LL',
        desiredAccuracy: BMFDesiredAccuracy.best,
        allowsBackgroundLocationUpdates: true,
        pausesLocationUpdatesAutomatically: false);
    return options;
  }

  // /// 启动定位
  Future<void> _startLocation() async {
    _suc = await _myLocPlugin.startLocation();
    print('开始连续定位：$_suc');
  }

  //请求对方数据
  get() async {
    //X21A get1
    var uri = Uri.http('192.168.101.14:15553', '/get1');
    await http.post(uri, headers: {"content-type": "application/json"}, body: json.encode({"latitude" : _loationResult.getMap()["latitude"].toString(),
      "longitude": _loationResult.getMap()["longitude"].toString()}))
        .then((response) {
      print("post方式->status: ${response.statusCode}");
      print("post方式->body: ${response.body}");
      _loationResultResponse.latitude = double.parse(response.body.split("\"")[3]);
      _loationResultResponse.longitude = double.parse(response.body.split("\"")[7]);
      print(_loationResult.getMap()["latitude"].toString());
      print(_loationResult.getMap()["longitude"].toString());
      print(_loationResultResponse.latitude);
      print(_loationResultResponse.longitude);
    });
    //_loationResultResponse = responseBody;//获取到的数据
  }

  /// 停止定位(开始共享)
  void _stopLocation() async {
    get();

    //_suc = await _myLocPlugin.stopLocation();
    //print('停止连续定位：$_suc');
    print('开始共享');
  }

  ///定位完成添加mark
  void _locationFinish() {
    /// 创建BMFMarker
    BMFMarker marker1 = BMFMarker(
        position: BMFCoordinate(_loationResult.latitude ?? 0.0, _loationResult.longitude ?? 0.0),
        title: 'flutterMaker',
        identifier: 'flutter_marker',
        icon: 'resources/icon_mark.png');
    print(_loationResult.latitude.toString() + _loationResult.longitude.toString());
    BMFMarker marker2 = BMFMarker(
        position: BMFCoordinate(_loationResultResponse.latitude ?? 0.0, _loationResultResponse.longitude ?? 0.0),
        title: 'flutterMaker',
        identifier: 'flutter_marker',
        icon: 'resources/icon_mark_blue.png');
    print(_loationResultResponse.latitude.toString() + _loationResultResponse.longitude.toString());

    /// 添加Marker
    _myMapController.cleanAllMarkers();
    _myMapController.addMarker(marker1);
    _myMapController.addMarker(marker2);

    ///设置中心点
    _myMapController.setCenterCoordinate(
        BMFCoordinate(_loationResult.latitude ?? 0.0, _loationResult.longitude ?? 0.0), false);
  }

  /// 设置地图参数
  BMFMapOptions _initMapOptions() {
    BMFMapOptions mapOptions = BMFMapOptions(
        center: BMFCoordinate(39.917215, 116.380341),
        zoomLevel: 19, //越大缩放等级越高
        mapPadding: BMFEdgeInsets(top: 0, left: 0, right: 0, bottom: 0));
    return mapOptions;
  }

  /// 创建完成回调
  void _onBMFMapCreated(BMFMapController controller) {
    _myMapController = controller;

    /// 地图加载回调
    _myMapController.setMapDidLoadCallback(callback: () {
      print('mapDidLoad-地图加载完成');
    });
  }
}
