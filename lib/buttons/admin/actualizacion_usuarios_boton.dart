import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:isste/services/api_service.dart';

class ActualizacionUsuariosBoton extends StatefulWidget {
  const ActualizacionUsuariosBoton({super.key});

  @override
  State<ActualizacionUsuariosBoton> createState() => _ActualizacionUsuariosBotonState();
}

class _ActualizacionUsuariosBotonState extends State<ActualizacionUsuariosBoton> {
  List<dynamic> usuarios = [];
  String query = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    cargarUsuarios();
  }

  bool _toBool(dynamic v) {
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) {
      final s = v.toLowerCase().trim();
      return s == 'true' || s == 't' || s == '1' || s == 'si' || s == 'sí' || s == 'yes' || s == 'y';
    }
    return false;
  }

  Future<void> cargarUsuarios() async {
    setState(() => isLoading = true);
    try {
      final respuesta = await ApiService.getJson(ApiService.usuarios);
      if (respuesta.statusCode == 200) {
        final data = json.decode(respuesta.body);
        if (mounted) {
          setState(() {
            usuarios = List<dynamic>.from(data);
            isLoading = false;
          });
        }
      } else {
        _toast('Error al cargar usuarios (${respuesta.statusCode})');
        setState(() => isLoading = false);
      }
    } catch (_) {
      _toast('No se pudo conectar con el servidor');
      setState(() => isLoading = false);
    }
  }

  Future<void> _cambiarActivo(int userId, bool activo) async {
    try {
      final respuesta = await ApiService.putJson(
        ApiService.usuarioDetailUrl(userId),
        {'activo': activo},
      );

      if (respuesta.statusCode == 200) {
        _toast('Estado actualizado');
        await cargarUsuarios();
      } else {
        _toast('No se pudo actualizar (${respuesta.statusCode})');
      }
    } catch (_) {
      _toast('Error de conexión al actualizar');
    }
  }

  Future<void> _actualizarRol(int userId, int rolId) async {
    try {
      final respuesta = await ApiService.putJson(
        ApiService.usuarioDetailUrl(userId),
        {'rol_id': rolId},
      );

      if (respuesta.statusCode == 200) {
        _toast('Rol actualizado');
        await cargarUsuarios();
      } else {
        _toast('No se pudo actualizar rol (${respuesta.statusCode})');
      }
    } catch (_) {
      _toast('Error de conexión al actualizar rol');
    }
  }

  Future<void> _actualizarUsuario({
    required int id,
    required String nombre,
    required String usuario,
    String? contrasena,
    required int rolId,
    required bool activo,
  }) async {
    final payload = {
      'nombre': nombre,
      'usuario': usuario,
      'rol_id': rolId,
      'activo': activo,
      if (contrasena != null && contrasena.trim().isNotEmpty) 'contrasena': contrasena,
    };

    try {
      final respuesta = await ApiService.putJson(
        ApiService.usuarioDetailUrl(id),
        payload,
      );

      if (respuesta.statusCode == 200) {
        _toast('Usuario actualizado');
        await cargarUsuarios();
      } else {
        _toast('No se pudo actualizar (${respuesta.statusCode})');
      }
    } catch (_) {
      _toast('Error de conexión al actualizar');
    }
  }

  Future<void> _crearUsuario({
    required String nombre,
    required String usuario,
    required String contrasena,
    required int rolId,
    required bool activo,
  }) async {
    final payload = {
      'nombre': nombre,
      'usuario': usuario,
      'contrasena': contrasena,
      'rol_id': rolId,
      'activo': activo,
    };

    try {
      final respuesta = await ApiService.postJson(
        ApiService.usuarios,
        payload,
      );

      if (respuesta.statusCode == 201 || respuesta.statusCode == 200) {
        _toast('Usuario creado');
        await cargarUsuarios();
      } else {
        _toast('No se pudo crear (${respuesta.statusCode})');
      }
    } catch (_) {
      _toast('Error de conexión al crear');
    }
  }

  void _mostrarContrasenaDialog(String nombre, String? contrasena) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Contraseña — $nombre'),
        content: SelectableText(contrasena?.isNotEmpty == true ? contrasena! : 'No disponible'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
        ],
      ),
    );
  }

  String _rolNombre(dynamic rolId) {
    final id = (rolId is int) ? rolId : int.tryParse('${rolId ?? ''}') ?? -1;
    switch (id) {
      case 1:
        return 'Administrador';
      case 2:
        return 'Ventanilla';
      case 3:
        return 'Preregistro';
      default:
        return 'Desconocido';
    }
  }

  List<dynamic> _filtrados() {
    if (query.trim().isEmpty) return usuarios;
    final q = query.toLowerCase();
    return usuarios.where((u) {
      final nombre = (u['nombre'] ?? '').toString().toLowerCase();
      final user = (u['usuario'] ?? '').toString().toLowerCase();
      return nombre.contains(q) || user.contains(q);
    }).toList();
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ========= PERMISOS DE VENTANILLA =========

  // 1) Localizar ventanilla por usuario (maneja 404 y hace fallback a /admin/ventanillas)
  Future<int?> _fetchVentanillaIdPorUsuario(int userId) async {
    int? _toInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v.trim());
      return null;
    }

    Future<int?> _buscarEn(String url, {String nombreFuente = ''}) async {
      try {
        final respuesta = await ApiService.getJson(url);
        
        // Si el endpoint no existe, devolvemos null para continuar con el fallback
        if (respuesta.statusCode == 404) {
          debugPrint('⚠️ Endpoint $url no encontrado, saltando...');
          return null;
        }

        if (respuesta.statusCode != 200) {
          _toast('GET $url → ${respuesta.statusCode}');
          return null;
        }

        final data = json.decode(respuesta.body);
        if (data is! List) return null;

        for (final raw in data) {
          if (raw is! Map) continue;
          final uid = _toInt(raw['usuario_id']);
          final vid = _toInt(raw['ventanilla_id'] ?? raw['id']);
          if (uid != null && uid == userId && vid != null) {
            return vid;
          }
        }
        return null;
      } catch (e) {
        debugPrint('❌ Error leyendo $url: $e');
        return null;
      }
    }

    // Intento 1: activas (si existe)
    final a = await _buscarEn(ApiService.ventanillas, nombreFuente: 'activas');
    if (a != null) return a;

    // Intento 2: todas (seguro existe)
    final b = await _buscarEn(ApiService.ventanillas, nombreFuente: 'todas');
    return b;
  }

  // 2) Fusiona trámites asignados con todos los activos para generar checkboxes con "asignado"
  Future<List<Map<String, dynamic>>> _fetchTramitesDeVentanilla(int ventanillaId) async {
    // Asignados
    final respuestaAsig = await ApiService.getJson(ApiService.ventanillaTramitesUrl(ventanillaId));
    if (respuestaAsig.statusCode != 200) {
      throw Exception('HTTP ${respuestaAsig.statusCode} al cargar trámites asignados');
    }
    final parsedAsig = json.decode(respuestaAsig.body);
    final List asigList = (parsedAsig is Map && parsedAsig['tramites'] is List)
        ? parsedAsig['tramites'] as List
        : <dynamic>[];
    final Set<int> asignadosIds = asigList
        .map((e) => (e is Map && e['tramite_id'] != null) ? int.tryParse('${e['tramite_id']}') ?? -1 : -1)
        .where((id) => id > 0)
        .toSet();

    // Todos activos
    final respuestaAll = await ApiService.getJson(ApiService.tramitesAdmin);
    if (respuestaAll.statusCode != 200) {
      throw Exception('HTTP ${respuestaAll.statusCode} al cargar todos los trámites');
    }
    final List allList = List<Map<String, dynamic>>.from(json.decode(respuestaAll.body));

    // Unificar
    final merged = allList.map<Map<String, dynamic>>((t) {
      final id = (t['id'] is int) ? t['id'] as int : int.tryParse('${t['id']}') ?? 0;
      return {
        'id': id,
        'nombre': t['nombre'],
        'letra': t['letra'],
        'asignado': asignadosIds.contains(id),
      };
    }).toList();

    return merged;
  }

  void _abrirPermisosVentanilla(Map<String, dynamic> usuario) async {
    final int userId = usuario['id'] as int;

    // 1) Buscar ventanilla asignada a este usuario
    final ventanillaId = await _fetchVentanillaIdPorUsuario(userId);
    if (ventanillaId == null) {
      _toast('Este usuario no tiene ventanilla activa asignada');
      return;
    }
    _toast('Ventanilla encontrada: ID $ventanillaId');

    // 2) Cargar trámites con flag "asignado"
    List<Map<String, dynamic>> tramites = [];
    try {
      tramites = await _fetchTramitesDeVentanilla(ventanillaId);
    } catch (e) {
      _toast('No se pudieron cargar trámites: $e');
      return;
    }

    // 3) Mostrar diálogo de checkboxes y guardar
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (context, setLocalState) {
          return AlertDialog(
            title: Text('Trámites para ventanilla (ID $ventanillaId)'),
            content: SizedBox(
              width: 420,
              height: 420,
              child: ListView(
                children: tramites.map((t) {
                  final asignado = t['asignado'] == true;
                  return CheckboxListTile(
                    title: Text(t['nombre'].toString()),
                    value: asignado,
                    onChanged: (v) => setLocalState(() => t['asignado'] = v == true),
                  );
                }).toList(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
              FilledButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('Guardar'),
                onPressed: () async {
                  final seleccionados = tramites
                      .where((t) => t['asignado'] == true)
                      .map<int>((t) => t['id'] as int)
                      .toList();

                  try {
                    final respuesta = await ApiService.postJson(
                      ApiService.ventanillaTramitesUrl(ventanillaId),
                      {'tramites': seleccionados},
                    );

                    if (respuesta.statusCode == 200 || respuesta.statusCode == 201) {
                      _toast('Trámites actualizados');
                      if (!mounted) return;
                      Navigator.pop(context);
                    } else {
                      final body = respuesta.body.isNotEmpty ? respuesta.body : '';
                      _toast('Error al guardar (${respuesta.statusCode}) $body');
                    }
                  } catch (e) {
                    _toast('Error de conexión al guardar: $e');
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  // ---------- Diálogos de usuario ----------

  void _abrirDialogoCrear() {
    _abrirDialogoUsuario(
      titulo: 'Nuevo usuario',
      onSubmit: (form) async {
        await _crearUsuario(
          nombre: form.nombre,
          usuario: form.usuario,
          contrasena: form.contrasena!,
          rolId: form.rolId,
          activo: form.activo,
        );
      },
      esCreacion: true,
    );
  }

  void _abrirDialogoEditar(Map<String, dynamic> u) {
    final id = u['id'] as int;
    _abrirDialogoUsuario(
      titulo: 'Actualizar usuario',
      datosIniciales: UsuarioFormData(
        nombre: (u['nombre'] ?? '') as String,
        usuario: (u['usuario'] ?? '') as String,
        contrasena: '',
        rolId: (u['rol_id'] is int) ? u['rol_id'] as int : int.tryParse('${u['rol_id']}') ?? 0,
        activo: _toBool(u['activo']),
      ),
      onSubmit: (form) async {
        await _actualizarUsuario(
          id: id,
          nombre: form.nombre,
          usuario: form.usuario,
          contrasena: form.contrasena?.trim().isEmpty == true ? null : form.contrasena,
          rolId: form.rolId,
          activo: form.activo,
        );
      },
      esCreacion: false,
    );
  }

  void _abrirDialogoUsuario({
    required String titulo,
    UsuarioFormData? datosIniciales,
    required Future<void> Function(UsuarioFormData) onSubmit,
    required bool esCreacion,
  }) {
    final formKey = GlobalKey<FormState>();
    final data = UsuarioFormData.from(datosIniciales);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(titulo),
        content: SizedBox(
          width: 420,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: data.nombre,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                  onChanged: (v) => data.nombre = v,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  initialValue: data.usuario,
                  decoration: const InputDecoration(labelText: 'Usuario'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                  onChanged: (v) => data.usuario = v,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  initialValue: '',
                  decoration: InputDecoration(
                    labelText: esCreacion ? 'Contraseña' : 'Nueva contraseña (opcional)',
                  ),
                  obscureText: true,
                  validator: (v) {
                    if (esCreacion && (v == null || v.trim().isEmpty)) return 'Requerida';
                    return null;
                  },
                  onChanged: (v) => data.contrasena = v,
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<int>(
                  value: (data.rolId >= 1 && data.rolId <= 3) ? data.rolId : null,
                  decoration: const InputDecoration(labelText: 'Rol'),
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('Administrador')),
                    DropdownMenuItem(value: 2, child: Text('Ventanilla')),
                    DropdownMenuItem(value: 3, child: Text('Preregistro')),
                  ],
                  validator: (v) => (v == null) ? 'Selecciona un rol' : null,
                  onChanged: (v) => data.rolId = v ?? 0,
                ),
                const SizedBox(height: 10),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Activo'),
                  value: data.activo,
                  onChanged: (v) => setState(() => data.activo = v),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton.icon(
            icon: Icon(esCreacion ? Icons.person_add : Icons.save),
            label: Text(esCreacion ? 'Crear' : 'Guardar'),
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(context);
              await onSubmit(data);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final data = _filtrados();

    return Column(
      children: [
        // Buscador + Botón "Nuevo usuario"
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Buscar por nombre o usuario…',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onChanged: (v) => setState(() => query = v),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                icon: const Icon(Icons.person_add_alt_1),
                label: const Text('Nuevo usuario'),
                onPressed: _abrirDialogoCrear,
              ),
            ],
          ),
        ),

        Expanded(
          child: RefreshIndicator(
            onRefresh: cargarUsuarios,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              itemCount: data.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final u = data[index] as Map<String, dynamic>;
                final id = u['id'] as int;
                final nombre = (u['nombre'] ?? '') as String;
                final usuario = (u['usuario'] ?? '') as String;
                final rolIdRaw = u['rol_id'];
                final rolId = (rolIdRaw is int) ? rolIdRaw : int.tryParse('${rolIdRaw ?? ''}') ?? 0;

                final tieneActivo = u.containsKey('activo');
                final activo = tieneActivo ? _toBool(u['activo']) : false;

                final tieneContrasena = u.containsKey('contrasena');
                final contrasena = tieneContrasena ? (u['contrasena']?.toString()) : null;

                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Encabezado: Nombre + ID + Switch Activo
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 18,
                              child: Text(
                                nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(nombre, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 10,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    children: [
                                      Tooltip(
                                        message: 'ID del usuario',
                                        child: Text('ID: $id', style: TextStyle(color: Colors.grey[700])),
                                      ),
                                      _RolBadge(nombre: _rolNombre(rolId)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              children: [
                                const Text('Activo', style: TextStyle(fontWeight: FontWeight.w600)),
                                Switch(
                                  value: activo,
                                  onChanged: tieneActivo ? (val) => _cambiarActivo(id, val) : null,
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Usuario + Selector de Rol
                        Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  const Icon(Icons.person_outline, size: 18),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      'Usuario: $usuario',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            DropdownButton<int>(
                              value: (rolId >= 1 && rolId <= 3) ? rolId : null,
                              hint: const Text('Rol'),
                              items: const [
                                DropdownMenuItem(value: 1, child: Text('Administrador')),
                                DropdownMenuItem(value: 2, child: Text('Ventanilla')),
                                DropdownMenuItem(value: 3, child: Text('Preregistro')),
                              ],
                              onChanged: (nuevo) {
                                if (nuevo != null) {
                                  _actualizarRol(id, nuevo);
                                }
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // Acciones
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton.icon(
                              onPressed: () => _mostrarContrasenaDialog(nombre, contrasena),
                              icon: const Icon(Icons.lock_open),
                              label: const Text('Ver contraseña'),
                            ),
                            Row(
                              children: [
                                if (rolId == 2) // SOLO para usuarios con rol Ventanilla
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: OutlinedButton.icon(
                                      icon: const Icon(Icons.rule),
                                      label: const Text('Definir trámites'),
                                      onPressed: () => _abrirPermisosVentanilla(u),
                                    ),
                                  ),
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.edit),
                                  label: const Text('Actualizar'),
                                  onPressed: () => _abrirDialogoEditar(u),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _RolBadge extends StatelessWidget {
  final String nombre;
  const _RolBadge({required this.nombre});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blueGrey.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blueGrey),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified_user, size: 16),
          const SizedBox(width: 6),
          Text(nombre),
        ],
      ),
    );
  }
}

// ------- Modelo simple para el formulario de usuario -------
class UsuarioFormData {
  String nombre;
  String usuario;
  String? contrasena; // opcional en edición
  int rolId;
  bool activo;

  UsuarioFormData({
    required this.nombre,
    required this.usuario,
    this.contrasena,
    required this.rolId,
    required this.activo,
  });

  factory UsuarioFormData.from(UsuarioFormData? d) => UsuarioFormData(
        nombre: d?.nombre ?? '',
        usuario: d?.usuario ?? '',
        contrasena: d?.contrasena ?? '',
        rolId: d?.rolId ?? 0,
        activo: d?.activo ?? true,
      );
}