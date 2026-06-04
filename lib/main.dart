import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Syriazzle',
      debugShowCheckedModeBanner: false,
      // تعديل السمة الأساسية لتطابق هوية التطبيق (البرتقالي)
      theme: ThemeData(
        primarySwatch: Colors.orange,
        primaryColor: Colors.orange,
        useMaterial3: true,
      ),
      home: const WebViewScreen(),
    );
  }
}

class WebViewScreen extends StatefulWidget {
  const WebViewScreen({super.key});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  InAppWebViewController? webViewController;
  final String targetUrl = "https://syriazle.com";
  bool hasError = false;

  // دالة إظهار رسالة الخروج الشيك (تم تعديل الألوان والنص)
  Future<void> _showExitDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Row(
          children: [
            Icon(Icons.exit_to_app_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 10),
            Text(
              'خروج من التطبيق',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.orange,
              ),
            ),
          ],
        ),
        content: const Text(
          'هل تريد الخروج من التطبيق',
          style: TextStyle(fontSize: 16, color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text(
              'إلغاء',
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            onPressed: () {
              SystemNavigator.pop();
            },
            child: const Text(
              'نعم',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        if (hasError) {
          if (context.mounted) _showExitDialog(context);
          return;
        }

        if (webViewController != null && await webViewController!.canGoBack()) {
          webViewController!.goBack();
        } else {
          if (context.mounted) {
            _showExitDialog(context);
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Stack(
            children: [
              InAppWebView(
                initialUrlRequest: URLRequest(url: WebUri(targetUrl)),
                initialSettings: InAppWebViewSettings(
                  mediaPlaybackRequiresUserGesture: false,
                  javaScriptEnabled: true,
                  javaScriptCanOpenWindowsAutomatically: true,
                  cacheEnabled: true,
                  domStorageEnabled: true,
                  databaseEnabled: true,
                  supportZoom: false,
                  allowFileAccessFromFileURLs:
                      false, // تم الإغلاق لحل تحذير جوجل
                  allowUniversalAccessFromFileURLs:
                      false, // تم الإغلاق لحل تحذير جوجل
                  verticalScrollBarEnabled: false,
                  horizontalScrollBarEnabled: false,
                  supportMultipleWindows: true,
                  mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
                  thirdPartyCookiesEnabled: true,
                  allowContentAccess: true,
                  disableDefaultErrorPage: true,
                ),
                onWebViewCreated: (controller) {
                  webViewController = controller;
                },
                onReceivedError: (controller, request, error) {
                  if (request.isForMainFrame == true) {
                    setState(() {
                      hasError = true;
                    });
                  }
                },
                onCreateWindow: (controller, createWindowAction) async {
                  if (createWindowAction.request.url != null) {
                    await controller.loadUrl(
                      urlRequest: createWindowAction.request,
                    );
                  }
                  return true;
                },
                onLoadStop: (controller, url) async {
                  await controller.injectCSSCode(
                    source: """
                    * {
                      -webkit-user-select: none !important;
                      -khtml-user-select: none !important;
                      -moz-user-select: none !important;
                      -ms-user-select: none !important;
                      user-select: none !important;
                      -webkit-touch-callout: none !important;
                    }
                    img {
                      -webkit-user-drag: none !important;
                    }
                  """,
                  );
                },
                onReceivedServerTrustAuthRequest:
                    (controller, challenge) async {
                      return ServerTrustAuthResponse(
                        action: ServerTrustAuthResponseAction.PROCEED,
                      );
                    },
                onPermissionRequest: (controller, request) async {
                  List<Permission> permissionsToRequest = [];

                  for (var resource in request.resources) {
                    if (resource == PermissionResourceType.CAMERA) {
                      permissionsToRequest.add(Permission.camera);
                    } else if (resource == PermissionResourceType.MICROPHONE) {
                      permissionsToRequest.add(Permission.microphone);
                    }
                  }

                  if (permissionsToRequest.isNotEmpty) {
                    Map<Permission, PermissionStatus> statuses =
                        await permissionsToRequest.request();
                    bool allGranted = statuses.values.every(
                      (status) => status.isGranted,
                    );

                    if (allGranted) {
                      return PermissionResponse(
                        resources: request.resources,
                        action: PermissionResponseAction.GRANT,
                      );
                    } else {
                      return PermissionResponse(
                        resources: request.resources,
                        action: PermissionResponseAction.DENY,
                      );
                    }
                  }

                  return PermissionResponse(
                    resources: request.resources,
                    action: PermissionResponseAction.GRANT,
                  );
                },
              ),

              if (hasError)
                Container(
                  color: Colors.white,
                  width: double.infinity,
                  height: double.infinity,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.wifi_off_rounded,
                        size: 100,
                        color: Colors.grey, // لون الأيقونة
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'عفواً، لا يوجد اتصال بالإنترنت',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'يرجى التحقق من اتصالك والمحاولة مرة أخرى',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange, // تعديل للبرتقالي
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            hasError = false;
                          });
                          webViewController?.reload();
                        },
                        child: const Text(
                          'إعادة المحاولة',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
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
}
