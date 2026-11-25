import 'package:material_ui/material_ui.dart';

import '../data/models/user_profile.dart';
import '../data/repositories/profile_repository.dart';

/// Estado del perfil y ajustes.
class ProfileProvider extends ChangeNotifier {
  /// Crea el provider con su [repository].
  ProfileProvider(this._repository);

  final ProfileRepository _repository;
  UserProfile _profile = const UserProfile();
  bool _isLoading = false;
  String? _error;

  /// Perfil actual.
  UserProfile get profile => _profile;

  /// Modo de tema.
  ThemeMode get themeMode => _profile.themeMode;

  /// Indica si está cargando.
  bool get isLoading => _isLoading;

  /// Último error.
  String? get error => _error;

  /// Carga el perfil.
  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _profile = await _repository.load();
    } catch (e) {
      _error = 'No se pudo cargar el perfil: $e';
    }
    _isLoading = false;
    notifyListeners();
  }

  /// Guarda y aplica un nuevo perfil.
  Future<void> update(UserProfile profile) async {
    _profile = profile;
    _error = null;
    notifyListeners();
    try {
      await _repository.save(profile);
    } catch (e) {
      _error = 'Error al guardar el perfil: $e';
      notifyListeners();
    }
  }
}
