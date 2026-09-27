import 'dart:io';
import 'dart:ui' as ui;

import 'package:cwc_health_app/data/content_catalog.dart';
import 'package:cwc_health_app/features/learn/learn_screen.dart';
import 'package:cwc_health_app/theme/cwc_theme.dart';
import 'package:cwc_health_app/widgets/help_now_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Paper Fig.1(c): full Learn grid from bundled [kLearnAssetPath].
///
/// Regenerates `docs/paper/fig1c-learn-grid.png` when UPDATE_GOLDENS=1:
/// `UPDATE_GOLDENS=1 flutter test test/paper/fig1c_learn_grid_test.dart`
const _kFig1cLogicalSize = Size(360, 1000);
const _kFig1cPixelRatio = 2.0;
const _kFig1cCaptureKey = ValueKey<String>('fig1c-learn-grid');
const _kRequiredTiles = <String>[
  'Physical Health',
  'Mental Health',
  'Stress Management',
  'Nutrition',
  'Preventive Care',
  'Sleep',
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await _loadAndroidScreenshotFonts();
    await loadLearnTopics();
  });

  testWidgets('Learn grid shows all top-level tiles for paper Fig.1(c)', (
    tester,
  ) async {
    tester.view.devicePixelRatio = _kFig1cPixelRatio;
    tester.view.physicalSize = Size(
      _kFig1cLogicalSize.width * _kFig1cPixelRatio,
      _kFig1cLogicalSize.height * _kFig1cPixelRatio,
    );
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      RepaintBoundary(
        key: _kFig1cCaptureKey,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: _paperTheme(),
          home: Scaffold(
            appBar: AppBar(
              toolbarHeight: 64,
              title: const Text('Learn'),
              actions: const [HelpNowButton()],
            ),
            body: const LearnScreen(),
            bottomNavigationBar: NavigationBar(
              selectedIndex: 2,
              onDestinationSelected: (_) {},
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.place_outlined),
                  selectedIcon: Icon(Icons.place),
                  label: 'Nearby',
                ),
                NavigationDestination(
                  icon: Icon(Icons.favorite_border),
                  selectedIcon: Icon(Icons.favorite),
                  label: 'My Health',
                ),
                NavigationDestination(
                  key: ValueKey('tab-learn'),
                  icon: Icon(Icons.menu_book_outlined),
                  selectedIcon: Icon(Icons.menu_book),
                  label: 'Learn',
                ),
                NavigationDestination(
                  icon: Icon(Icons.more_horiz),
                  selectedIcon: Icon(Icons.more_horiz),
                  label: 'More',
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (final title in _kRequiredTiles) {
      expect(find.text(title), findsOneWidget);
    }
    expect(find.text('Medications'), findsNothing);
    expect(find.text('Exercise'), findsNothing);
    expect(find.text('Stress management'), findsNothing);

    final png = await tester.runAsync(() => _capturePng(tester));
    expect(png, isNotNull);
    expect(png, isNotEmpty);

    final outFile = File('docs/paper/fig1c-learn-grid.png');
    if (Platform.environment['UPDATE_GOLDENS'] == '1') {
      outFile.parent.createSync(recursive: true);
      outFile.writeAsBytesSync(png!);
    } else {
      expect(
        outFile.existsSync(),
        isTrue,
        reason:
            'docs/paper/fig1c-learn-grid.png is missing. '
            'Regenerate with UPDATE_GOLDENS=1 flutter test '
            'test/paper/fig1c_learn_grid_test.dart',
      );
    }
  });
}

ThemeData _paperTheme() {
  final base = buildCwcTheme();
  TextStyle withRoboto(TextStyle? style) {
    return (style ?? const TextStyle()).copyWith(fontFamily: 'Roboto');
  }

  return base.copyWith(
    platform: TargetPlatform.android,
    textTheme: base.textTheme.apply(fontFamily: 'Roboto'),
    primaryTextTheme: base.primaryTextTheme.apply(fontFamily: 'Roboto'),
    appBarTheme: base.appBarTheme.copyWith(
      titleTextStyle: withRoboto(base.appBarTheme.titleTextStyle),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: (base.filledButtonTheme.style ?? const ButtonStyle()).copyWith(
        textStyle: WidgetStatePropertyAll(
          withRoboto(
            const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    ),
    navigationBarTheme: base.navigationBarTheme.copyWith(
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontFamily: 'Roboto',
          fontSize: 14,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          color: selected ? CwcColors.primary : CwcColors.sub,
        );
      }),
    ),
  );
}

Future<Uint8List> _capturePng(WidgetTester tester) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_kFig1cCaptureKey),
  );
  final image = await boundary.toImage(pixelRatio: _kFig1cPixelRatio);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  if (bytes == null) {
    throw StateError('PNG encode failed');
  }
  return Uint8List.sublistView(bytes);
}

/// Load Roboto + MaterialIcons so the paper PNG is not Ahem squares.
Future<void> _loadAndroidScreenshotFonts() async {
  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  if (flutterRoot == null || flutterRoot.isEmpty) {
    throw StateError('FLUTTER_ROOT is not set');
  }
  final fontsDir = Directory('$flutterRoot/bin/cache/artifacts/material_fonts');
  if (!fontsDir.existsSync()) {
    throw StateError('Missing Flutter material fonts at ${fontsDir.path}');
  }

  Future<ByteData> bytesFor(String name) async {
    final file = File('${fontsDir.path}/$name');
    if (!file.existsSync()) {
      throw StateError('Missing font ${file.path}');
    }
    return ByteData.sublistView(await file.readAsBytes());
  }

  const robotoFiles = <String>[
    'Roboto-Thin.ttf',
    'Roboto-Light.ttf',
    'Roboto-Regular.ttf',
    'Roboto-Medium.ttf',
    'Roboto-Bold.ttf',
    'Roboto-Black.ttf',
    'Roboto-ThinItalic.ttf',
    'Roboto-LightItalic.ttf',
    'Roboto-Italic.ttf',
    'Roboto-MediumItalic.ttf',
    'Roboto-BoldItalic.ttf',
    'Roboto-BlackItalic.ttf',
  ];
  final roboto = FontLoader('Roboto');
  for (final name in robotoFiles) {
    if (File('${fontsDir.path}/$name').existsSync()) {
      roboto.addFont(bytesFor(name));
    }
  }
  await roboto.load();

  final iconsFile = File('${fontsDir.path}/MaterialIcons-Regular.otf');
  if (iconsFile.existsSync()) {
    final icons = FontLoader('MaterialIcons')
      ..addFont(bytesFor('MaterialIcons-Regular.otf'));
    await icons.load();
  }
}
