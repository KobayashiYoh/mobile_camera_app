import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:image_picker/image_picker.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({required this.cameras, Key? key}) : super(key: key);

  final List<CameraDescription> cameras;

  @override
  _CameraPageState createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  late CameraController _cameraController;
  late ResolutionPreset _resolutionPreset;
  int _cameraIdx = 0;
  int _resolutionIdx = 1;
  String _resolutionText = '480p';

  bool _openMenu = false;
  bool _videoMode = false;

  Future<void> _initCameraController() async {
    _resolutionPreset = ResolutionPreset.medium;
    _cameraController = CameraController(
      widget.cameras[_cameraIdx], // 使用するカメラ
      _resolutionPreset, // カメラの解像度
    );
    await _cameraController.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    });
  }

  void _switchShootingMode() {
    setState(() {
      _videoMode = _videoMode ? false : true;
    });
  }

  void _switchBetweenInnerAndOuterCameras() {
    setState(() {
      _cameraIdx = (_cameraIdx == 0) ? 1 : 0;
    });
    _initCameraController();
  }

  void _switchResolution() {
    _resolutionIdx++;
    if (_resolutionIdx > 5) {
      _resolutionIdx = 0;
    }
    switch (_resolutionIdx) {
      case 0:
        _resolutionPreset = ResolutionPreset.low;
        _resolutionText = '240p';
        break;
      case 1:
        _resolutionPreset = ResolutionPreset.medium;
        _resolutionText = '480p';
        break;
      case 2:
        _resolutionPreset = ResolutionPreset.high;
        _resolutionText = '720p';
        break;
      case 3:
        _resolutionPreset = ResolutionPreset.veryHigh;
        _resolutionText = '1080p';
        break;
      case 4:
        _resolutionPreset = ResolutionPreset.ultraHigh;
        _resolutionText = '2160p';
        break;
      case 5:
        _resolutionPreset = ResolutionPreset.max;
        _resolutionText = 'max';
        break;
      default:
        _resolutionPreset = ResolutionPreset.medium;
        _resolutionText = '480p';
        break;
    }
    _initCameraController();
    setState(() {});
  }

  Future<void> _takePicture() async {
    try {
      final imageFile = await _cameraController.takePicture();
      GallerySaver.saveImage(imageFile.path);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _openGallery() async {
    final ImagePicker picker = ImagePicker();
    await picker.pickImage(source: ImageSource.gallery);
  }

  Widget _menuItemIcon(IconData iconData) {
    return Icon(
      iconData,
      color: const Color(0xCCFFFFFF),
      size: 40.0,
    );
  }

  Widget _menuItem(Function() onTap, Widget child, String text) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 96.0,
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Column(
          children: [
            child,
            Text(
              text,
              style: const TextStyle(color: Color(0xCCFFFFFF)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cameraMenuBar() {
    return Container(
      width: MediaQuery.of(context).size.width,
      color: const Color(0x77000000),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _menuItem(
              _switchShootingMode,
              _menuItemIcon(
                _videoMode
                    ? Icons.camera_enhance_outlined
                    : Icons.videocam_outlined,
              ),
              _videoMode ? 'カメラ' : 'ビデオ',
            ),
            _menuItem(
              _switchBetweenInnerAndOuterCameras,
              _menuItemIcon(Icons.sync_outlined),
              _cameraIdx == 0 ? '内カメラ' : '外カメラ',
            ),
            _menuItem(
              _switchResolution,
              _menuItemIcon(Icons.control_camera_outlined),
              _resolutionText,
            ),
            _menuItem(
              () {},
              _menuItemIcon(Icons.qr_code_2),
              'QRコード',
            ),
            _menuItem(
              () {},
              _menuItemIcon(CupertinoIcons.barcode),
              'バーコード',
            ),
            _menuItem(
              () {},
              _menuItemIcon(Icons.keyboard_control),
              'その他',
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _initCameraController();
  }

  @override
  void dispose() {
    // メモリに情報が取り残されて重くなるのを防ぐ
    _cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_cameraController.value.isInitialized) {
      return Container();
    }
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Stack(
            alignment: Alignment.bottomCenter,
            children: [
              CameraPreview(_cameraController),
              if (_openMenu) _cameraMenuBar(),
            ],
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              color: Colors.black,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Container(
                    decoration: BoxDecoration(
                      color: _openMenu
                          ? const Color(0x55FFFFFF)
                          : Colors.transparent,
                      borderRadius:
                          const BorderRadius.all(Radius.circular(24.0)),
                    ),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _openMenu = _openMenu ? false : true;
                        });
                      },
                      child: const Icon(
                        Icons.keyboard_control,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _takePicture,
                    child: _videoMode
                        ? Stack(
                            alignment: Alignment.center,
                            children: const [
                              Icon(
                                Icons.fiber_manual_record_outlined,
                                color: Colors.white,
                                size: 72.0,
                              ),
                              Icon(
                                Icons.fiber_manual_record_outlined,
                                color: Colors.black,
                                size: 64.0,
                              ),
                              Icon(
                                Icons.fiber_manual_record,
                                color: Colors.red,
                                size: 48.0,
                              )
                            ],
                          )
                        : const Icon(
                            Icons.camera,
                            color: Colors.white,
                            size: 64.0,
                          ),
                  ),
                  GestureDetector(
                    onTap: _openGallery,
                    child: const Icon(
                      Icons.insert_photo_outlined,
                      color: Colors.white,
                      size: 32.0,
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
