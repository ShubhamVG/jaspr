// ignore_for_file: file_names

import 'package:jaspr/jaspr.dart';

class Features extends StatelessComponent {
  const Features({super.key});

  @override
  Iterable<Component> build(BuildContext context) sync* {
    yield section(id: 'features', [
      span(classes: 'caption text-gradient', [text('Features')]),
      h2([text('Comes with '), br(), text('Everything You Need')]),
    ]);
  }

  @css
  static final List<StyleRule> styles = [
    css('#features', [
      css('&')
          .box(padding: EdgeInsets.only(top: 2.rem))
          .flexbox(direction: FlexDirection.column, alignItems: AlignItems.center)
          .text(align: TextAlign.center),
    ]),
  ];
}
