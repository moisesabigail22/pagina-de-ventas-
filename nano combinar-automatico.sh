#!/bin/bash

# ============================================
# COMBINADOR AUTOMÁTICO DE TODAS LAS BRANCHES
# ============================================

echo "🤖 INICIANDO COMBINADOR AUTOMÁTICO"
echo "=================================="
echo ""

# Colores para mensajes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuración
ARCHIVO_FINAL="index-combinado.html"
CARPETA_TEMP=".temp_branches_$(date +%s)"
BRANCHES_PROCESADAS=0
BRANCHES_SALTADAS=0

# Función para limpiar al salir
cleanup() {
    echo -e "\n${YELLOW}🧹 Limpiando archivos temporales...${NC}"
    rm -rf "$CARPETA_TEMP"
    echo -e "${GREEN}✅ Limpieza completada${NC}"
}

# Capturar Ctrl+C
trap cleanup EXIT INT TERM

# 1. Sincronizar con GitHub
echo -e "${BLUE}🔄 Sincronizando con GitHub...${NC}"
git fetch --all --quiet
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Error al sincronizar con GitHub${NC}"
    exit 1
fi

# 2. Obtener TODAS las branches remotas
echo -e "\n${BLUE}📋 Buscando todas las branches en GitHub...${NC}"
BRANCHES_REMOTAS=$(git branch -r | grep -v "HEAD" | sed 's/origin\///' | tr -d ' ')

if [ -z "$BRANCHES_REMOTAS" ]; then
    echo -e "${RED}❌ No se encontraron branches remotas${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Encontradas $(echo "$BRANCHES_REMOTAS" | wc -l) branches remotas${NC}"

# 3. Crear carpeta temporal
mkdir -p "$CARPETA_TEMP"
mkdir -p "$CARPETA_TEMP/branches"

# 4. Guardar branch actual
BRANCH_ACTUAL=$(git branch --show-current)
echo -e "\n${YELLOW}📌 Branch actual: $BRANCH_ACTUAL${NC}"

# 5. Array para controlar contenido único (evitar duplicados)
declare -A CONTENIDO_HASHES
declare -A BRANCHES_YA_PROCESADAS

# 6. Procesar cada branch
echo -e "\n${BLUE}🧩 Procesando branches...${NC}"
echo "=================================="

for BRANCH in $BRANCHES_REMOTAS; do
    echo -e "\n${YELLOW}🔄 Procesando: $BRANCH${NC}"
    
    # Verificar si ya procesamos esta branch (por nombre)
    if [[ -n "${BRANCHES_YA_PROCESADAS[$BRANCH]}" ]]; then
        echo -e "   ⏭️  Ya procesada anteriormente, saltando..."
        BRANCHES_SALTADAS=$((BRANCHES_SALTADAS + 1))
        continue
    fi
    
    # Intentar cambiar a la branch
    if git checkout "$BRANCH" --quiet 2>/dev/null; then
        echo -e "   ✅ Branch local encontrada"
    else
        # Crear branch local desde remoto
        echo -e "   📥 Descargando desde GitHub..."
        if git checkout -b "$BRANCH" "origin/$BRANCH" --quiet 2>/dev/null; then
            echo -e "   ✅ Descargada exitosamente"
        else
            echo -e "   ❌ No se pudo acceder"
            continue
        fi
    fi
    
    # Marcar como procesada
    BRANCHES_YA_PROCESADAS[$BRANCH]=1
    
    # Buscar archivo principal (index.html o similar)
    ARCHIVO_PRINCIPAL=""
    for ARCHIVO in "index.html" "Index.html" "INDEX.html" "main.html" "home.html"; do
        if [ -f "$ARCHIVO" ]; then
            ARCHIVO_PRINCIPAL="$ARCHIVO"
            break
        fi
    done
    
    if [ -z "$ARCHIVO_PRINCIPAL" ]; then
        echo -e "   ⚠️  No se encontró archivo HTML principal"
        continue
    fi
    
    echo -e "   📄 Archivo encontrado: $ARCHIVO_PRINCIPAL"
    
    # Calcular hash del contenido para detectar duplicados
    CONTENIDO_HASH=$(sha1sum "$ARCHIVO_PRINCIPAL" | cut -d' ' -f1)
    
    # Verificar si este contenido ya existe
    if [[ -n "${CONTENIDO_HASHES[$CONTENIDO_HASH]}" ]]; then
        echo -e "   ⚠️  Contenido duplicado (igual a ${CONTENIDO_HASHES[$CONTENIDO_HASH]}), saltando..."
        BRANCHES_SALTADAS=$((BRANCHES_SALTADAS + 1))
        continue
    fi
    
    # Guardar hash y branch de origen
    CONTENIDO_HASHES[$CONTENIDO_HASH]="$BRANCH"
    
    # Copiar archivo
    cp "$ARCHIVO_PRINCIPAL" "$CARPETA_TEMP/branches/${BRANCH//\//_}.html"
    
    # Copiar también CSS y JS si existen
    if [ -d "css" ]; then
        cp -r css "$CARPETA_TEMP/css_${BRANCH//\//_}" 2>/dev/null || true
    fi
    if [ -d "js" ]; then
        cp -r js "$CARPETA_TEMP/js_${BRANCH//\//_}" 2>/dev/null || true
    fi
    
    BRANCHES_PROCESADAS=$((BRANCHES_PROCESADAS + 1))
    echo -e "   ✅ Procesada correctamente"
done

# 7. Volver a la branch original
echo -e "\n${BLUE}↩️  Volviendo a branch original ($BRANCH_ACTUAL)...${NC}"
git checkout "$BRANCH_ACTUAL" --quiet

# 8. Crear archivo combinado
echo -e "\n${BLUE}📦 Creando archivo combinado...${NC}"

cat > "$ARCHIVO_FINAL" << 'EOF'
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>🏗️ PROYECTO COMBINADO AUTOMÁTICO</title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <style>
        :root {
            --primary: #667eea;
            --secondary: #764ba2;
            --success: #48bb78;
            --warning: #ed8936;
        }
        
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Segoe UI', system-ui, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding: 20px;
        }
        
        .container {
            max-width: 1400px;
            margin: 0 auto;
            background: white;
            border-radius: 20px;
            padding: 40px;
            box-shadow: 0 25px 50px rgba(0,0,0,0.2);
        }
        
        header {
            text-align: center;
            margin-bottom: 40px;
            padding-bottom: 20px;
            border-bottom: 3px solid #f0f0f0;
        }
        
        h1 {
            color: #333;
            font-size: 2.8em;
            margin-bottom: 10px;
        }
        
        .subtitle {
            color: #666;
            font-size: 1.2em;
        }
        
        .stats-card {
            background: linear-gradient(135deg, var(--primary), var(--secondary));
            color: white;
            padding: 25px;
            border-radius: 15px;
            margin-bottom: 30px;
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
        }
        
        .stat-item {
            text-align: center;
        }
        
        .stat-number {
            font-size: 2.5em;
            font-weight: bold;
            display: block;
        }
        
        .stat-label {
            font-size: 0.9em;
            opacity: 0.9;
        }
        
        .branch-section {
            background: #f8fafc;
            border-radius: 15px;
            margin: 25px 0;
            overflow: hidden;
            border: 2px solid #e2e8f0;
            transition: transform 0.3s, box-shadow 0.3s;
        }
        
        .branch-section:hover {
            transform: translateY(-5px);
            box-shadow: 0 15px 30px rgba(0,0,0,0.1);
        }
        
        .branch-header {
            background: linear-gradient(90deg, var(--primary), var(--secondary));
            color: white;
            padding: 20px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            cursor: pointer;
        }
        
        .branch-name {
            font-size: 1.4em;
            font-weight: 600;
        }
        
        .branch-meta {
            display: flex;
            gap: 15px;
            align-items: center;
        }
        
        .branch-number {
            background: white;
            color: var(--primary);
            width: 40px;
            height: 40px;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            font-weight: bold;
        }
        
        .branch-content {
            padding: 30px;
            display: none;
            background: white;
        }
        
        .branch-content.active {
            display: block;
            animation: fadeIn 0.5s ease;
        }
        
        .branch-actions {
            margin-top: 20px;
            padding-top: 20px;
            border-top: 1px solid #e2e8f0;
            text-align: right;
        }
        
        .btn {
            padding: 10px 20px;
            border-radius: 8px;
            border: none;
            cursor: pointer;
            font-weight: 600;
            transition: all 0.3s;
        }
        
        .btn-copy {
            background: var(--success);
            color: white;
        }
        
        .btn-copy:hover {
            background: #38a169;
        }
        
        @keyframes fadeIn {
            from { opacity: 0; }
            to { opacity: 1; }
        }
        
        footer {
            text-align: center;
            margin-top: 50px;
            color: #666;
            padding-top: 20px;
            border-top: 2px solid #f0f0f0;
        }
        
        .toggle-all {
            background: var(--warning);
            color: white;
            border: none;
            padding: 12px 24px;
            border-radius: 8px;
            cursor: pointer;
            font-weight: 600;
            margin: 20px 0;
        }
    </style>
</head>
<body>
    <div class="container">
        <header>
            <h1><i class="fas fa-code-branch"></i> COMBINADOR AUTOMÁTICO</h1>
            <p class="subtitle">Todas las branches en un solo archivo</p>
        </header>
        
        <div class="stats-card">
            <div class="stat-item">
                <span class="stat-number" id="total-branches">0</span>
                <span class="stat-label">Total Branches</span>
            </div>
            <div class="stat-item">
                <span class="stat-number" id="processed-branches">0</span>
                <span class="stat-label">Procesadas</span>
            </div>
            <div class="stat-item">
                <span class="stat-number" id="skipped-branches">0</span>
                <span class="stat-label">Saltadas</span>
            </div>
            <div class="stat-item">
                <span class="stat-number" id="unique-files">0</span>
                <span class="stat-label">Archivos Únicos</span>
            </div>
        </div>
        
        <button class="toggle-all" onclick="toggleAll()">
            <i class="fas fa-expand"></i> Expandir/Contraer Todo
        </button>
        
        <div id="branches-container">
            <!-- Aquí se insertarán las branches automáticamente -->
        </div>
        
        <footer>
            <p>🔄 Generado automáticamente el <span id="current-date"></span></p>
            <p><i class="fas fa-code"></i> Comando usado: <code>./combinar-automatico.sh</code></p>
        </footer>
    </div>
    
    <script>
        // Datos desde el script Bash (se insertarán aquí)
        const branchesData = [];
EOF

# Insertar datos de las branches procesadas
INDEX=0
for ARCHIVO in "$CARPETA_TEMP"/branches/*.html; do
    if [ -f "$ARCHIVO" ]; then
        INDEX=$((INDEX + 1))
        BRANCH_NAME=$(basename "$ARCHIVO" .html | sed 's/_/\//g')
        CONTENT=$(cat "$ARCHIVO" | sed ':a;N;$!ba;s/\n/\\n/g' | sed 's/"/\\"/g')
        
        cat >> "$ARCHIVO_FINAL" << EOF
        branchesData.push({
            id: $INDEX,
            name: "$BRANCH_NAME",
            content: \`$CONTENT\`
        });
EOF
    fi
done

# Continuar con el HTML
cat >> "$ARCHIVO_FINAL" << 'EOF'
        
        // Actualizar estadísticas
        document.getElementById('total-branches').textContent = branchesData.length;
        document.getElementById('processed-branches').textContent = branchesData.length;
        document.getElementById('unique-files').textContent = branchesData.length;
        
        // Insertar branches en el contenedor
        const container = document.getElementById('branches-container');
        
        branchesData.forEach(branch => {
            const branchElement = document.createElement('div');
            branchElement.className = 'branch-section';
            branchElement.innerHTML = `
                <div class="branch-header" onclick="toggleBranch(${branch.id})">
                    <div class="branch-name">
                        <i class="fas fa-code-branch"></i> ${branch.name}
                    </div>
                    <div class="branch-meta">
                        <span class="branch-number">${branch.id}</span>
                        <i class="fas fa-chevron-down" id="icon-${branch.id}"></i>
                    </div>
                </div>
                <div class="branch-content" id="content-${branch.id}">
                    <pre><code>${branch.content}</code></pre>
                    <div class="branch-actions">
                        <button class="btn btn-copy" onclick="copyCode(${branch.id})">
                            <i class="fas fa-copy"></i> Copiar Código
                        </button>
                    </div>
                </div>
            `;
            container.appendChild(branchElement);
        });
        
        // Fecha actual
        document.getElementById('current-date').textContent = new Date().toLocaleString();
        
        // Funciones JavaScript
        function toggleBranch(id) {
            const content = document.getElementById('content-' + id);
            const icon = document.getElementById('icon-' + id);
            
            content.classList.toggle('active');
            icon.classList.toggle('fa-chevron-down');
            icon.classList.toggle('fa-chevron-up');
        }
        
        function toggleAll() {
            const allContents = document.querySelectorAll('.branch-content');
            const allIcons = document.querySelectorAll('.branch-header .fa-chevron-down, .branch-header .fa-chevron-up');
            const allAreOpen = Array.from(allContents).every(c => c.classList.contains('active'));
            
            allContents.forEach(content => {
                if (allAreOpen) {
                    content.classList.remove('active');
                } else {
                    content.classList.add('active');
                }
            });
            
            allIcons.forEach(icon => {
                if (allAreOpen) {
                    icon.classList.remove('fa-chevron-up');
                    icon.classList.add('fa-chevron-down');
                } else {
                    icon.classList.remove('fa-chevron-down');
                    icon.classList.add('fa-chevron-up');
                }
            });
        }
        
        async function copyCode(id) {
            const content = document.querySelector(`#content-${id} pre code`).textContent;
            
            try {
                await navigator.clipboard.writeText(content);
                alert('✅ Código copiado al portapapeles!');
            } catch (err) {
                alert('❌ Error al copiar: ' + err);
            }
        }
        
        // Inicializar: abrir primera branch
        if (branchesData.length > 0) {
            toggleBranch(1);
        }
        
        console.log(`✅ Combinación completada. Total branches: ${branchesData.length}`);
    </script>
</body>
</html>
EOF

# 9. Mostrar resumen final
echo -e "\n${GREEN}===========================================${NC}"
echo -e "${GREEN}✅ ¡COMBINACIÓN COMPLETADA EXITOSAMENTE!${NC}"
echo -e "${GREEN}===========================================${NC}"
echo ""
echo -e "${BLUE}📊 RESUMEN FINAL:${NC}"
echo -e "   • ${GREEN}Archivo creado:${NC} $ARCHIVO_FINAL"
echo -e "   • ${GREEN}Branches procesadas:${NC} $BRANCHES_PROCESADAS"
echo -e "   • ${YELLOW}Branches saltadas (duplicadas):${NC} $BRANCHES_SALTADAS"
echo -e "   • ${BLUE}Tamaño del archivo:${NC} $(du -h "$ARCHIVO_FINAL" | cut -f1)"
echo ""
echo -e "${BLUE}🚀 COMANDOS PARA VER RESULTADO:${NC}"
echo -e "   Ver archivo:    ${GREEN}cat $ARCHIVO_FINAL | head -20${NC}"
echo -e "   Abrir navegador: ${GREEN}open $ARCHIVO_FINAL${NC}"
echo -e "   Ver en terminal: ${GREEN}ls -la $ARCHIVO_FINAL${NC}"
echo ""
echo -e "${YELLOW}📁 Archivos temporales:${NC} $CARPETA_TEMP"
echo -e "${YELLOW}🗑️  Se limpiarán automáticamente al salir${NC}"
