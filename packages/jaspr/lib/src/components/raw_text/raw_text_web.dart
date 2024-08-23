import 'dart:js_interop';

import 'package:web/web.dart' as web;

import '../../../browser.dart';
import '../../browser/utils.dart';

/// Renders its input as raw HTML.
///
/// **WARNING**: This component does not escape any
/// user input and is vulnerable to [cross-site scripting (XSS) attacks](https://owasp.org/www-community/attacks/xss/).
/// Make sure to sanitize any user input when using this component.
class RawText extends StatelessComponent {
  const RawText(this.text, {super.key});

  final String text;

  @override
  Iterable<Component> build(BuildContext context) sync* {
    var fragment = web.document.createElement('template');
    fragment.innerHTML = text.toJS;
    for (var node in fragment.childNodes.toIterable()) {
      yield RawNode.withKey(node);
    }
  }
}

class RawNode extends Component {
  RawNode(this.node, {super.key});

  factory RawNode.withKey(web.Node node) {
    return RawNode(
      node,
      key: switch (node) {
        web.Text() when node.instanceOfString("Text") => ValueKey('text'),
        web.Element() when node.instanceOfString("Element") => ValueKey('element:${node.tagName}'),
        _ => null,
      },
    );
  }

  final web.Node node;

  @override
  Element createElement() => RawNodeElement(this);
}

class RawNodeElement extends BuildableRenderObjectElement {
  RawNodeElement(RawNode super.component);

  @override
  RawNode get component => super.component as RawNode;

  @override
  Iterable<Component> build() sync* {
    for (var node in component.node.childNodes.toIterable()) {
      yield RawNode.withKey(node);
    }
  }

  @override
  void updateRenderObject() {
    var next = component.node;
    if (next.instanceOfString("Text") && next is web.Text) {
      renderObject.updateText(next.textContent ?? '');
    } else if (next.instanceOfString("Element") && next is web.Element) {
      renderObject.updateElement(
          next.tagName.toLowerCase(), next.id, next.className, null, next.attributes.toMap(), null);
    } else {
      var curr = (renderObject as DomRenderObject).node;
      if (curr != null) {
        curr.parentNode?.replaceChild(next, curr);
      }
      (renderObject as DomRenderObject).node = next;
    }
  }
}
