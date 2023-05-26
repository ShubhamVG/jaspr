import 'package:jaspr/jaspr.dart';

import 'path_utils.dart';
import 'typedefs.dart';

abstract class RouteBase {
  const RouteBase._({
    this.routes = const <RouteBase>[],
  });

  final List<RouteBase> routes;
}

class Route extends RouteBase {
  Route({
    required this.path,
    this.name,
    this.title,
    this.builder,
    this.redirect,
    super.routes = const <RouteBase>[],
  })  : assert(path.isNotEmpty, 'Route path cannot be empty'),
        assert(name == null || name.isNotEmpty, 'Route name cannot be empty'),
        assert(builder != null || redirect != null, 'builder or redirect must be provided'),
        super._() {
    // cache the path regexp and parameters
    _pathRE = patternToRegExp(path, pathParams);
  }

  factory Route.lazy({
    required String path,
    String? name,
    RouterComponentBuilder? builder,
    RouterRedirect? redirect,
    required AsyncCallback load,
    List<RouteBase> routes,
  }) = LazyRoute;

  final String? name;

  final String path;

  final String? title;

  final RouterComponentBuilder? builder;

  final RouterRedirect? redirect;

  //@internal
  final List<String> pathParams = <String>[];

  RegExp get pathRegex => _pathRE;

  late final RegExp _pathRE;
}

class LazyRoute extends Route with LazyRouteMixin {
  LazyRoute({
    required super.path,
    super.name,
    super.title,
    super.builder,
    super.redirect,
    required this.load,
    super.routes = const <RouteBase>[],
  });

  @override
  final AsyncCallback load;
}

class ShellRoute extends RouteBase {
  /// Constructs a [ShellRoute].
  ShellRoute({
    required this.builder,
    super.routes,
  })  : assert(routes.isNotEmpty),
        super._();

  factory ShellRoute.lazy({
    required ShellRouteBuilder builder,
    required AsyncCallback load,
    List<RouteBase> routes,
  }) = LazyShellRoute;

  final ShellRouteBuilder builder;
}

class LazyShellRoute extends ShellRoute with LazyRouteMixin {
  LazyShellRoute({
    required super.builder,
    required this.load,
    super.routes,
  });

  @override
  final AsyncCallback load;
}

mixin LazyRouteMixin {
  AsyncCallback get load;
}

// /// Interface for any Route
// /// Do not subclass this, always subclass either LazyRoute or ResolvedRoute
// abstract class Route {
//   factory Route.lazy(String path, ComponentBuilder builder, AsyncCallback loader) = LazyRoute;
//
//   const factory Route(String path, ComponentBuilder builder) = ResolvedRoute;
//
//   bool matches(Uri uri);
// }
//
// /// Interface for a resolved route that does not require any loading
// abstract class ResolvedRoute implements Route {
//   const factory ResolvedRoute(String path, ComponentBuilder builder) = _ResolvedRoute;
//
//   Iterable<Component> build(BuildContext context);
// }
//
// /// Lazy loaded route. Should be used with deferred imports
// class LazyRoute implements Route {
//   final String _path;
//   final AsyncCallback _loader;
//   final ComponentBuilder _builder;
//
//   LazyRoute(this._path, this._builder, this._loader);
//
//   Future<ResolvedRoute>? _resolved;
//
//   Future<ResolvedRoute> load({bool eager = true, bool preload = false}) {
//     if (_resolved == null) {
//       List<Future> loading = [_loader()];
//       if (preload) {
//         var preloaded = SyncBinding.instance!.loadState(_path);
//         if (!eager) loading.add(preloaded);
//       }
//       _resolved = Future.wait(loading).then((_) {
//         return ResolvedRoute(_path, _builder);
//       });
//     }
//     return _resolved!;
//   }
//
//   @override
//   bool matches(Uri uri) => _path == uri.path;
//
//   @override
//   bool operator ==(Object other) =>
//       identical(this, other) ||
//       other is LazyRoute && runtimeType == other.runtimeType && _path == other._path;
//
//   @override
//   int get hashCode => _path.hashCode;
// }
//
// class _ResolvedRoute implements ResolvedRoute {
//   final String _path;
//   final ComponentBuilder _builder;
//
//   const _ResolvedRoute(this._path, this._builder);
//
//   @override
//   Iterable<Component> build(BuildContext context) => _builder(context);
//
//   @override
//   bool matches(Uri uri) => _path == uri.path;
//
//   @override
//   String toString() {
//     return '_ResolvedRoute{_path: $_path}';
//   }
// }
