extends PanelContainer
# Se asigna a la raiz "BBG" de cada fondo importado desde un .bbg (ver scene_importer.gd).
#
# Al importar sin pantalla (por ejemplo, compilando en un servidor), Godot no guarda los
# parametros de los ShaderMaterial, asi que las capas llegaban al juego con los valores por
# defecto del shader (sin movimiento ni efectos). Aqui se vuelven a aplicar al cargar.

func _ready():
	for child in get_children():
		if child is CanvasItem and child.has_meta("bbg_params") and child.material is ShaderMaterial:
			var params = child.get_meta("bbg_params")
			for key in params.keys():
				child.material.set_shader_param(key, params[key])
