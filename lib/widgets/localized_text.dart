import 'dart:ui' as ui;

import 'package:flutter/material.dart' as flutter;

import '../services/app_language.dart';

class Text extends flutter.StatelessWidget {
  static String translate(flutter.BuildContext context, String text) =>
      AppText.translate(context, text);

  const Text(
    this.data, {
    super.key,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    @Deprecated('Use textScaler instead.') this.textScaleFactor,
    this.textScaler,
    this.maxLines,
    this.semanticsLabel,
    this.semanticsIdentifier,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
  }) : textSpan = null;

  const Text.rich(
    this.textSpan, {
    super.key,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    @Deprecated('Use textScaler instead.') this.textScaleFactor,
    this.textScaler,
    this.maxLines,
    this.semanticsLabel,
    this.semanticsIdentifier,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
  }) : data = null;

  final String? data;
  final flutter.InlineSpan? textSpan;
  final flutter.TextStyle? style;
  final flutter.StrutStyle? strutStyle;
  final flutter.TextAlign? textAlign;
  final flutter.TextDirection? textDirection;
  final flutter.Locale? locale;
  final bool? softWrap;
  final flutter.TextOverflow? overflow;
  final double? textScaleFactor;
  final flutter.TextScaler? textScaler;
  final int? maxLines;
  final String? semanticsLabel;
  final String? semanticsIdentifier;
  final flutter.TextWidthBasis? textWidthBasis;
  final ui.TextHeightBehavior? textHeightBehavior;
  final flutter.Color? selectionColor;

  @override
  flutter.Widget build(flutter.BuildContext context) {
    final localizedData = data == null ? null : AppText.translate(context, data!);
    final localizedSpan = textSpan == null ? null : _localizeSpan(context, textSpan!);

    if (localizedSpan != null) {
      return flutter.Text.rich(
        localizedSpan,
        key: key,
        style: style,
        strutStyle: strutStyle,
        textAlign: textAlign,
        textDirection: textDirection,
        locale: locale,
        softWrap: softWrap,
        overflow: overflow,
        textScaleFactor: textScaleFactor,
        textScaler: textScaler,
        maxLines: maxLines,
        semanticsLabel: semanticsLabel,
        semanticsIdentifier: semanticsIdentifier,
        textWidthBasis: textWidthBasis,
        textHeightBehavior: textHeightBehavior,
        selectionColor: selectionColor,
      );
    }

    return flutter.Text(
      localizedData ?? '',
      key: key,
      style: style,
      strutStyle: strutStyle,
      textAlign: textAlign,
      textDirection: textDirection,
      locale: locale,
      softWrap: softWrap,
      overflow: overflow,
      textScaleFactor: textScaleFactor,
      textScaler: textScaler,
      maxLines: maxLines,
      semanticsLabel: semanticsLabel,
      semanticsIdentifier: semanticsIdentifier,
      textWidthBasis: textWidthBasis,
      textHeightBehavior: textHeightBehavior,
      selectionColor: selectionColor,
    );
  }

  flutter.InlineSpan _localizeSpan(
    flutter.BuildContext context,
    flutter.InlineSpan span,
  ) {
    if (span is! flutter.TextSpan) return span;

    return flutter.TextSpan(
      text: span.text == null ? null : AppText.translate(context, span.text!),
      children: span.children
          ?.map((child) => _localizeSpan(context, child))
          .toList(),
      style: span.style,
      recognizer: span.recognizer,
      mouseCursor: span.mouseCursor,
      onEnter: span.onEnter,
      onExit: span.onExit,
      semanticsLabel: span.semanticsLabel,
      semanticsIdentifier: span.semanticsIdentifier,
      locale: span.locale,
      spellOut: span.spellOut,
    );
  }
}