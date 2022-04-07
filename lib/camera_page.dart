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

  void _switchOpenMenu() {
    setState(() {
      _openMenu = _openMenu ? false : true;
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

  // FIXME: フラッシュモードの切り替え不可
  Future<void> _switchFlashMode() async {
    FlashMode mode;
    switch (_cameraController.value.flashMode) {
      case FlashMode.off:
        mode = FlashMode.auto;
        break;
      case FlashMode.auto:
        mode = FlashMode.always;
        break;
      case FlashMode.always:
        mode = FlashMode.torch;
        break;
      default:
        mode = FlashMode.off;
        break;
    }

    try {
      await _cameraController.setFlashMode(mode);
    } catch (e) {
      rethrow;
    }

    setState(() {});
  }

  String _resolutionText = '480p';
  // FIXME: 画質の切り替え不可
  Future<void> _switchResolutionPreset() async {
    switch (_resolutionPreset) {
      case ResolutionPreset.low:
        _resolutionPreset = ResolutionPreset.medium;
        _resolutionText = '480p';
        break;
      case ResolutionPreset.medium:
        _resolutionPreset = ResolutionPreset.high;
        _resolutionText = '720p';
        break;
      case ResolutionPreset.high:
        _resolutionPreset = ResolutionPreset.veryHigh;
        _resolutionText = '1080p';
        break;
      case ResolutionPreset.veryHigh:
        _resolutionPreset = ResolutionPreset.ultraHigh;
        _resolutionText = '2160p';
        break;
      case ResolutionPreset.ultraHigh:
        _resolutionPreset = ResolutionPreset.max;
        _resolutionText = 'max';
        break;
      default:
        _resolutionPreset = ResolutionPreset.low;
        _resolutionText = '240p';
        break;
    }
    await _initCameraController();
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

  Future<void> _startVideoRecording() async {
    if (_cameraController.value.isRecordingVideo) {
      return;
    }

    try {
      await _cameraController.startVideoRecording();
      setState(() {});
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _stopVideoRecording() async {
    try {
      final movieFile = await _cameraController.stopVideoRecording();
      GallerySaver.saveVideo(movieFile.path);
      setState(() {});
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _recordVideo() async {
    if (_cameraController.value.isRecordingVideo) {
      await _stopVideoRecording();
      return;
    }
    await _startVideoRecording();
  }

  Future<void> _openGallery() async {
    final ImagePicker picker = ImagePicker();
    await picker.pickImage(source: ImageSource.gallery);
  }

  Widget _flashModeIcon() {
    switch (_cameraController.value.flashMode) {
      case FlashMode.off:
        return const Icon(Icons.flash_off);
      case FlashMode.auto:
        return const Icon(Icons.flash_auto);
      case FlashMode.always:
        return const Icon(Icons.flash_on);
      default:
        return const Icon(Icons.highlight_outlined);
    }
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
      width: double.infinity,
      color: const Color(0x77000000),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _menuItem(
              _switchBetweenInnerAndOuterCameras,
              const Icon(Icons.sync_outlined),
              _cameraIdx == 0 ? '内カメラ' : '外カメラ',
            ),
            _menuItem(
              _switchShootingMode,
              Icon(
                _videoMode
                    ? Icons.camera_enhance_outlined
                    : Icons.videocam_outlined,
              ),
              _videoMode ? 'カメラ' : 'ビデオ',
            ),
            _menuItem(
              _switchFlashMode,
              _flashModeIcon(),
              'フラッシュ',
            ),
            _menuItem(
              _switchResolutionPreset,
              const Icon(Icons.control_camera_outlined),
              _resolutionText,
            ),
            _menuItem(
              () {},
              const Icon(Icons.qr_code_2),
              'QRコード',
            ),
            _menuItem(
              () {},
              const Icon(CupertinoIcons.barcode),
              'バーコード',
            ),
            _menuItem(
              () {},
              const Icon(Icons.keyboard_control),
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
                  GestureDetector(
                    onTap: _switchOpenMenu,
                    child: Icon(
                      _openMenu
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                    ),
                  ),
                  GestureDetector(
                    onTap: _videoMode ? _recordVideo : _takePicture,
                    child: _videoMode
                        ? Stack(
                            alignment: Alignment.center,
                            children: [
                              const Icon(
                                Icons.fiber_manual_record_outlined,
                                size: 72.0,
                              ),
                              const Icon(
                                Icons.fiber_manual_record_outlined,
                                color: Colors.black,
                                size: 64.0,
                              ),
                              _cameraController.value.isRecordingVideo
                                  ? const Icon(
                                      Icons.square,
                                      color: Colors.red,
                                      size: 32.0,
                                    )
                                  : const Icon(
                                      Icons.fiber_manual_record,
                                      color: Colors.red,
                                      size: 48.0,
                                    ),
                            ],
                          )
                        : const Icon(
                            Icons.camera,
                            size: 64.0,
                          ),
                  ),
                  GestureDetector(
                    onTap: _openGallery,
                    child: const Icon(
                      Icons.insert_photo_outlined,
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
