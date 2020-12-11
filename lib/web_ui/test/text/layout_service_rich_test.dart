// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.12

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

import 'layout_service_helper.dart';

const ui.Color white = ui.Color(0xFFFFFFFF);
const ui.Color black = ui.Color(0xFF000000);
const ui.Color red = ui.Color(0xFFFF0000);
const ui.Color green = ui.Color(0xFF00FF00);
const ui.Color blue = ui.Color(0xFF0000FF);

final EngineParagraphStyle ahemStyle = EngineParagraphStyle(
  fontFamily: 'ahem',
  fontSize: 10,
);

ui.ParagraphConstraints constrain(double width) {
  return ui.ParagraphConstraints(width: width);
}

CanvasParagraph rich(
  EngineParagraphStyle style,
  void Function(CanvasParagraphBuilder) callback,
) {
  final CanvasParagraphBuilder builder = CanvasParagraphBuilder(style);
  callback(builder);
  return builder.build();
}

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() async {
  await ui.webOnlyInitializeTestDomRenderer();

  test('measures spans in the same line correctly', () {
    final CanvasParagraph paragraph = rich(ahemStyle, (builder) {
      builder.pushStyle(EngineTextStyle.only(fontSize: 12.0));
      // 12.0 * 6 = 72.0 (with spaces)
      // 12.0 * 5 = 60.0 (without spaces)
      builder.addText('Lorem ');

      builder.pushStyle(EngineTextStyle.only(fontSize: 13.0));
      // 13.0 * 6 = 78.0 (with spaces)
      // 13.0 * 5 = 65.0 (without spaces)
      builder.addText('ipsum ');

      builder.pushStyle(EngineTextStyle.only(fontSize: 11.0));
      // 11.0 * 5 = 55.0
      builder.addText('dolor');
    })..layout(constrain(double.infinity));

    expect(paragraph.maxIntrinsicWidth, 205.0);
    expect(paragraph.minIntrinsicWidth, 65.0); // "ipsum"
    expect(paragraph.width, double.infinity);
    expectLines(paragraph, [
      l('Lorem ipsum dolor', 0, 17, hardBreak: true, width: 205.0, left: 0.0),
    ]);
  });

  test('breaks lines correctly at the end of spans', () {
    final CanvasParagraph paragraph = rich(ahemStyle, (builder) {
      builder.addText('Lorem ');
      builder.pushStyle(EngineTextStyle.only(fontSize: 15.0));
      builder.addText('sit ');
      builder.pop();
      builder.addText('.');
    })..layout(constrain(60.0));

    expect(paragraph.maxIntrinsicWidth, 130.0);
    expect(paragraph.minIntrinsicWidth, 50.0); // "Lorem"
    expect(paragraph.width, 60.0);
    expectLines(paragraph, [
      l('Lorem ', 0, 6, hardBreak: false, width: 50.0, left: 0.0),
      l('sit ', 6, 10, hardBreak: false, width: 45.0, left: 0.0),
      l('.', 10, 11, hardBreak: true, width: 10.0, left: 0.0),
    ]);
  });

  test('breaks lines correctly in the middle of spans', () {
    final CanvasParagraph paragraph = rich(ahemStyle, (builder) {
      builder.addText('Lorem ipsum ');
      builder.pushStyle(EngineTextStyle.only(fontSize: 11.0));
      builder.addText('sit dolor');
    })..layout(constrain(100.0));

    expect(paragraph.maxIntrinsicWidth, 219.0);
    expect(paragraph.minIntrinsicWidth, 55.0); // "dolor"
    expect(paragraph.width, 100.0);
    expectLines(paragraph, [
      l('Lorem ', 0, 6, hardBreak: false, width: 50.0, left: 0.0),
      l('ipsum sit ', 6, 16, hardBreak: false, width: 93.0, left: 0.0),
      l('dolor', 16, 21, hardBreak: true, width: 55.0, left: 0.0),
    ]);
  });

  test('handles space-only spans', () {
    final CanvasParagraph paragraph = rich(ahemStyle, (builder) {
      builder.pushStyle(EngineTextStyle.only(color: red));
      builder.addText('Lorem ');
      builder.pop();
      builder.pushStyle(EngineTextStyle.only(color: blue));
      builder.addText('   ');
      builder.pushStyle(EngineTextStyle.only(color: green));
      builder.addText('  ');
      builder.pushStyle(EngineTextStyle.only(color: black));
      builder.addText('ipsum');
    });
    paragraph.layout(constrain(80.0));

    expect(paragraph.maxIntrinsicWidth, 160.0);
    expect(paragraph.minIntrinsicWidth, 50.0); // "Lorem" or "ipsum"
    expect(paragraph.width, 80.0);
    expectLines(paragraph, [
      l('Lorem      ', 0, 11, hardBreak: false, width: 50.0, widthWithTrailingSpaces: 110.0, left: 0.0),
      l('ipsum', 11, 16, hardBreak: true, width: 50.0, left: 0.0),
    ]);
  });

  test('should not break at span end if it is not a line break', () {
    final CanvasParagraph paragraph = rich(ahemStyle, (builder) {
      builder.pushStyle(EngineTextStyle.only(color: red));
      builder.addText('Lorem');
      builder.pop();
      builder.pushStyle(EngineTextStyle.only(color: blue));
      builder.addText(' ');
      builder.pushStyle(EngineTextStyle.only(color: black));
      builder.addText('ip');
      builder.pushStyle(EngineTextStyle.only(color: green));
      builder.addText('su');
      builder.pushStyle(EngineTextStyle.only(color: white));
      builder.addText('m');
    })..layout(constrain(50.0));

    expect(paragraph.maxIntrinsicWidth, 110.0);
    expect(paragraph.minIntrinsicWidth, 50.0); // "Lorem" or "ipsum"
    expect(paragraph.width, 50.0);
    expectLines(paragraph, [
      l('Lorem ', 0, 6, hardBreak: false, width: 50.0, left: 0.0),
      l('ipsum', 6, 11, hardBreak: true, width: 50.0, left: 0.0),
    ]);
  });
}
