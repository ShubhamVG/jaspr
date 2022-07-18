part of style;

class _BoxStyles implements Styles {
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Display? display;
  final Unit? width;
  final Unit? height;
  final Border? border;
  // final Outline? outline;
  // final Overflow? overflow;
  // final Visibility? visibility;
  // final Position? position;
  final double? opacity;

  const _BoxStyles({
    this.padding,
    this.margin,
    this.display,
    this.width,
    this.height,
    this.border,
    // this.outline,
    // this.overflow,
    // this.visibility,
    // this.position,
    this.opacity,
  });

  @override
  Map<String, String> get styles => {
        if (padding != null) ...padding!.styles._prefixed('padding'),
        if (margin != null) ...margin!.styles._prefixed('margin'),
        if (display != null) 'display': display!.value,
        if (width != null) 'width': width!.value,
        if (height != null) 'height': height!.value,
        if (border != null) ...border!.styles,
        if (opacity != null) 'opacity': opacity!.toString(),
      };
}

extension on Map<String, String> {
  Map<String, String> _prefixed(String prefix) {
    return map((k, v) => MapEntry(prefix + (k.isNotEmpty ? '-$k' : ''), v));
  }
}
